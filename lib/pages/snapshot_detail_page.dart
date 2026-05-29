import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/headers/detail_header_card.dart';
import '../components/icons/app_icon.dart';
import '../components/icons/app_icon_button.dart';
import '../components/chips/delta_chip.dart';
import '../components/rows/transaction_row.dart';
import '../components/separators/app_divider.dart';
import '../components/transaction_history_list.dart';
import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../services/market_data_service.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';

const String _kSnapshotSlidableGroupTag = 'snapshot_detail_slidable_group';

class SnapshotDetailPage extends StatefulWidget {
  const SnapshotDetailPage({
    super.key,
    required this.snapshot,
    required this.items,
  });

  final DailyPortfolioSnapshot snapshot;
  final List<DailyPortfolioSnapshotItem> items;

  @override
  State<SnapshotDetailPage> createState() => _SnapshotDetailPageState();
}

class _SnapshotDetailPageState extends State<SnapshotDetailPage> {
  DailyPortfolioSnapshot? _currentSnapshot;
  List<DailyPortfolioSnapshotItem> _currentItems = const [];
  List<DailyPortfolioSnapshotHoldingItem> _currentHoldingItems = const [];
  List<SnapshotCashAccountRecord> _currentCashAccounts = const [];
  List<SnapshotTransactionRecord> _currentTransactions = const [];
  List<SnapshotCashTransactionRecord> _currentCashTransactions = const [];
  String _note = '';
  DailyPortfolioSnapshot? _previousSnapshot;
  double? _previousDayTotalValue;
  Map<String, DailyPortfolioSnapshotItem> _previousItemByAssetKey = const {};
  final Set<String> _expandedAssetKeys = <String>{};
  bool _isNavigatingSnapshot = false;
  int _transitionDirection = 1;
  double _horizontalDragDx = 0;
  double _horizontalDragDy = 0;

  @override
  void initState() {
    super.initState();
    _currentSnapshot = widget.snapshot;
    _currentItems = widget.items;
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    final pageData = await _loadSnapshotAuxiliaryData(
      snapshotDate: (_currentSnapshot ?? widget.snapshot).snapshotDate,
    );
    if (!mounted) return;
    setState(() {
      _currentItems = pageData.currentItems;
      _currentHoldingItems = pageData.currentHoldingItems;
      _currentCashAccounts = pageData.currentCashAccounts;
      _currentTransactions = pageData.currentTransactions;
      _currentCashTransactions = pageData.currentCashTransactions;
      _note = pageData.note;
      _previousSnapshot = pageData.previousSnapshot;
      _previousDayTotalValue = pageData.previousDayTotalValue;
      _previousItemByAssetKey = pageData.previousItemByAssetKey;
    });
  }

  Future<_SnapshotAuxiliaryData> _loadSnapshotAuxiliaryData({
    required String snapshotDate,
  }) async {
    final note = await AppDatabase.instance.fetchSnapshotNote(snapshotDate);
    final assets = await AppDatabase.instance.fetchAssets();
    final visibleAssets = assets
        .where((asset) => !asset.isHidden)
        .toList(growable: false);
    final visibleAssetIds = visibleAssets
        .map((asset) => asset.id)
        .whereType<int>()
        .toSet();
    final visibleAssetTitles = visibleAssets
        .expand((asset) => [asset.title, asset.displayName])
        .map(_normalizeSnapshotAssetTitle)
        .where((value) => value.isNotEmpty)
        .toSet();
    bool isVisibleSnapshotAsset(int? assetId, String assetTitle) {
      if (assetId != null && visibleAssetIds.contains(assetId)) {
        return true;
      }
      return visibleAssetTitles.contains(
        _normalizeSnapshotAssetTitle(assetTitle),
      );
    }

    final currentItems =
        (await AppDatabase.instance.fetchDisplayPortfolioSnapshotItemsByDates([
              snapshotDate,
            ]))
            .where((item) {
              return isVisibleSnapshotAsset(item.assetId, item.assetTitle);
            })
            .toList(growable: false);
    final storedHoldingItems =
        (await AppDatabase.instance.fetchPortfolioSnapshotHoldingItemsByDates([
              snapshotDate,
            ]))
            .where((holding) {
              return isVisibleSnapshotAsset(
                holding.assetId,
                holding.assetTitle,
              );
            })
            .toList(growable: false);
    final currentHoldingItems = _withFallbackSnapshotHoldingItems(
      storedHoldingItems: storedHoldingItems,
      currentItems: currentItems,
      visibleAssets: visibleAssets,
    );
    final currentCashAccounts =
        (await AppDatabase.instance.fetchPortfolioSnapshotCashAccountsByDates([
              snapshotDate,
            ]))
            .where((account) {
              return isVisibleSnapshotAsset(
                account.assetId,
                account.assetTitle,
              );
            })
            .toList(growable: true);
    final currentTransactions =
        (await AppDatabase.instance.fetchTransactionsForDate(snapshotDate))
            .where((transaction) {
              final assetId = transaction.assetId;
              return assetId != null && visibleAssetIds.contains(assetId);
            })
            .toList(growable: false);
    final currentCashTransactions =
        (await AppDatabase.instance.fetchCashTransactionsForDate(snapshotDate))
            .where((transaction) {
              final assetId = transaction.assetId;
              return assetId != null && visibleAssetIds.contains(assetId);
            })
            .toList(growable: false);
    final previousSnapshotDate = _comparisonSnapshotDate(snapshotDate);
    final previousSnapshot = await AppDatabase.instance
        .fetchPortfolioSnapshotByDate(previousSnapshotDate);
    final previousItems = previousSnapshot == null
        ? const <DailyPortfolioSnapshotItem>[]
        : (await AppDatabase.instance.fetchDisplayPortfolioSnapshotItemsByDates(
                [previousSnapshotDate],
              ))
              .where((item) {
                return isVisibleSnapshotAsset(item.assetId, item.assetTitle);
              })
              .toList(growable: false);
    final previousDaySnapshotDate = _previousDaySnapshotDate(snapshotDate);
    final previousDaySnapshot = await AppDatabase.instance
        .fetchPortfolioSnapshotByDate(previousDaySnapshotDate);
    final previousDayItems = previousDaySnapshot == null
        ? const <DailyPortfolioSnapshotItem>[]
        : (await AppDatabase.instance.fetchDisplayPortfolioSnapshotItemsByDates(
                [previousDaySnapshotDate],
              ))
              .where((item) {
                return isVisibleSnapshotAsset(item.assetId, item.assetTitle);
              })
              .toList(growable: false);
    final previousDayItemByAssetKey = {
      for (final item in previousDayItems) _snapshotAssetKey(item): item,
    };
    final previousDayComparableTotalValue = currentItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (previousDayItemByAssetKey[_snapshotAssetKey(item)]
                  ?.totalValuationAmount ??
              0),
    );

    return _SnapshotAuxiliaryData(
      currentItems: currentItems,
      currentHoldingItems: currentHoldingItems,
      currentCashAccounts: currentCashAccounts,
      currentTransactions: currentTransactions,
      currentCashTransactions: currentCashTransactions,
      note: note,
      previousSnapshot: previousSnapshot,
      previousDayTotalValue: previousDaySnapshot == null
          ? null
          : previousDayComparableTotalValue,
      previousItemByAssetKey: {
        for (final item in previousItems) _snapshotAssetKey(item): item,
      },
    );
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    await _loadPageData();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _navigateToAdjacentSnapshot({required bool goPrevious}) async {
    if (_isNavigatingSnapshot) return;

    _isNavigatingSnapshot = true;
    try {
      final targetSnapshot = goPrevious
          ? await AppDatabase.instance.fetchPreviousPortfolioSnapshot(
              (_currentSnapshot ?? widget.snapshot).snapshotDate,
            )
          : await AppDatabase.instance.fetchNextPortfolioSnapshot(
              (_currentSnapshot ?? widget.snapshot).snapshotDate,
            );
      if (!mounted || targetSnapshot == null) return;

      final pageData = await _loadSnapshotAuxiliaryData(
        snapshotDate: targetSnapshot.snapshotDate,
      );
      if (!mounted) return;

      setState(() {
        _transitionDirection = goPrevious ? -1 : 1;
        _currentSnapshot = targetSnapshot;
        _currentItems = pageData.currentItems;
        _currentHoldingItems = pageData.currentHoldingItems;
        _currentCashAccounts = pageData.currentCashAccounts;
        _currentTransactions = pageData.currentTransactions;
        _currentCashTransactions = pageData.currentCashTransactions;
        _note = pageData.note;
        _previousSnapshot = pageData.previousSnapshot;
        _previousDayTotalValue = pageData.previousDayTotalValue;
        _previousItemByAssetKey = pageData.previousItemByAssetKey;
        _expandedAssetKeys.clear();
      });
    } finally {
      _isNavigatingSnapshot = false;
    }
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _note);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_note.trim().isEmpty ? '메모 작성' : '메모 수정'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(hintText: '스냅샷 메모를 입력하세요'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final note = controller.text.trim();
    await AppDatabase.instance.saveSnapshotNote(
      snapshotDate: (_currentSnapshot ?? widget.snapshot).snapshotDate,
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _note = note;
    });
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _deleteSnapshotItem(DailyPortfolioSnapshotItem item) async {
    final confirmed = await _confirmDelete(
      title: '자산군 삭제',
      message: '${item.assetTitle} 스냅샷 항목을 삭제할까요?',
    );
    if (!confirmed) return;

    await AppDatabase.instance.deletePortfolioSnapshotItem(
      snapshotItemId: item.id,
      snapshotId: item.snapshotId,
      assetId: item.assetId,
      assetTitle: item.assetTitle,
    );

    final key = _snapshotAssetKey(item);
    if (!mounted) return;
    setState(() {
      _expandedAssetKeys.remove(key);
    });
    await _loadPageData();
  }

  Future<void> _deleteSnapshotHoldingItem(
    DailyPortfolioSnapshotHoldingItem holding,
  ) async {
    final confirmed = await _confirmDelete(
      title: '종목 삭제',
      message: '${holding.holdingName} 스냅샷 항목을 삭제할까요?',
    );
    if (!confirmed) return;

    await AppDatabase.instance.deletePortfolioSnapshotHoldingItem(holding.id);
    await _loadPageData();
  }

  @override
  Widget build(BuildContext context) {
    final currentSnapshot = _currentSnapshot ?? widget.snapshot;
    final filteredItems = _currentItems.toList(growable: false);
    final holdingItemsByAssetKey =
        <String, List<DailyPortfolioSnapshotHoldingItem>>{};
    for (final holding in _currentHoldingItems) {
      for (final key in _snapshotHoldingAssetKeys(holding)) {
        holdingItemsByAssetKey.putIfAbsent(key, () => []).add(holding);
      }
    }
    final cashAccountsByAssetKey = <String, List<SnapshotCashAccountRecord>>{};
    for (final account in _currentCashAccounts) {
      final assetId = account.assetId;
      final keys = {
        if (assetId != null) 'asset:$assetId',
        _snapshotAssetTitleKey(account.assetTitle),
      };
      for (final key in keys) {
        cashAccountsByAssetKey.putIfAbsent(key, () => []).add(account);
      }
    }
    final filteredTotalValue = filteredItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValuationAmount,
    );
    final filteredTotalPurchase = filteredItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPurchaseAmount,
    );
    final filteredPreviousTotalValue = filteredItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (_previousItemByAssetKey[_snapshotAssetKey(item)]
                  ?.totalValuationAmount ??
              0),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${_formatSnapshotDate(currentSnapshot.snapshotDate)} 스냅샷'),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            _horizontalDragDx = 0;
            _horizontalDragDy = 0;
          },
          onHorizontalDragUpdate: (details) {
            _horizontalDragDx += details.delta.dx;
            _horizontalDragDy += details.delta.dy.abs();
          },
          onHorizontalDragEnd: (details) {
            if (_isNavigatingSnapshot) return;

            final velocity = details.primaryVelocity ?? 0;
            final absDx = _horizontalDragDx.abs();
            final absDy = _horizontalDragDy.abs();
            final isHorizontalIntent = absDx > absDy * 1.2;
            final byDistance = absDx >= 48 && isHorizontalIntent;
            final byVelocity = velocity.abs() >= 120;

            if (!byDistance && !byVelocity) return;

            final goPrevious = byDistance
                ? _horizontalDragDx > 0
                : velocity > 0;
            if (goPrevious) {
              _navigateToAdjacentSnapshot(goPrevious: true);
            } else {
              _navigateToAdjacentSnapshot(goPrevious: false);
            }
          },
          child: RefreshIndicator(
            onRefresh: _refreshPage,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                context.contentHorizontalPadding,
                context.spacing.md,
                context.contentHorizontalPadding,
                context.spacing.xxxl,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  final isIncoming =
                      child.key == ValueKey(currentSnapshot.snapshotDate);
                  final move = _transitionDirection * 0.12;
                  final offsetAnimation = isIncoming
                      // Incoming page enters from the opposite side.
                      ? Tween<Offset>(
                          begin: Offset(move, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        )
                      // Outgoing page exits toward the swipe direction.
                      : Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(-move, 0),
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInCubic,
                          ),
                        );
                  return ClipRect(
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: isIncoming
                              ? Curves.easeOutCubic
                              : Curves.easeInCubic,
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(currentSnapshot.snapshotDate),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(
                      snapshot: currentSnapshot,
                      currentTotalValue: filteredTotalValue,
                      currentTotalPurchase: filteredTotalPurchase,
                      previousTotalValue: _previousSnapshot == null
                          ? null
                          : filteredPreviousTotalValue,
                      previousDayTotalValue: _previousDayTotalValue,
                    ),
                    SizedBox(height: context.spacing.sectionGap),
                    MoneyfySectionCard(
                      title: '자산군별 구성',
                      headerBottomSpacing: 18,
                      child: SlidableAutoCloseBehavior(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in filteredItems) ...[
                              _ExpandableSnapshotItemRow(
                                item: item,
                                previousItem:
                                    _previousItemByAssetKey[_snapshotAssetKey(
                                      item,
                                    )],
                                totalValue: filteredTotalValue,
                                holdings: _snapshotRowsForAsset(
                                  holdingItemsByAssetKey,
                                  item,
                                ),
                                cashAccounts: _snapshotRowsForAsset(
                                  cashAccountsByAssetKey,
                                  item,
                                ),
                                renderCashAccountsAsPrimaryList:
                                    item.assetTitle == '현금',
                                isExpanded: _expandedAssetKeys.contains(
                                  _snapshotAssetKey(item),
                                ),
                                onDelete: () => _deleteSnapshotItem(item),
                                onDeleteHolding: _deleteSnapshotHoldingItem,
                                onTap: () {
                                  final key = _snapshotAssetKey(item);
                                  setState(() {
                                    if (_expandedAssetKeys.contains(key)) {
                                      _expandedAssetKeys.remove(key);
                                    } else {
                                      _expandedAssetKeys.add(key);
                                    }
                                  });
                                },
                              ),
                              if (item != filteredItems.last) ...[
                                const SizedBox(height: 14),
                                AppDivider(),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SnapshotTransactionsCard(
                      assetTransactions: _currentTransactions,
                      cashTransactions: _currentCashTransactions,
                    ),
                    const SizedBox(height: 16),
                    _SnapshotNoteCard(note: _note, onEdit: _editNote),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotAuxiliaryData {
  const _SnapshotAuxiliaryData({
    required this.currentItems,
    required this.currentHoldingItems,
    required this.currentCashAccounts,
    required this.currentTransactions,
    required this.currentCashTransactions,
    required this.note,
    required this.previousSnapshot,
    required this.previousDayTotalValue,
    required this.previousItemByAssetKey,
  });

  final List<DailyPortfolioSnapshotItem> currentItems;
  final List<DailyPortfolioSnapshotHoldingItem> currentHoldingItems;
  final List<SnapshotCashAccountRecord> currentCashAccounts;
  final List<SnapshotTransactionRecord> currentTransactions;
  final List<SnapshotCashTransactionRecord> currentCashTransactions;
  final String note;
  final DailyPortfolioSnapshot? previousSnapshot;
  final double? previousDayTotalValue;
  final Map<String, DailyPortfolioSnapshotItem> previousItemByAssetKey;
}

String _snapshotAssetKey(DailyPortfolioSnapshotItem item) {
  return 'asset:${item.assetId}';
}

Set<String> _snapshotAssetKeys(DailyPortfolioSnapshotItem item) {
  return {_snapshotAssetKey(item), _snapshotAssetTitleKey(item.assetTitle)};
}

List<T> _snapshotRowsForAsset<T>(
  Map<String, List<T>> rowsByAssetKey,
  DailyPortfolioSnapshotItem item,
) {
  final seen = <T>{};
  final rows = <T>[];
  for (final key in _snapshotAssetKeys(item)) {
    for (final row in rowsByAssetKey[key] ?? <T>[]) {
      if (seen.add(row)) rows.add(row);
    }
  }
  return rows;
}

List<DailyPortfolioSnapshotHoldingItem> _withFallbackSnapshotHoldingItems({
  required List<DailyPortfolioSnapshotHoldingItem> storedHoldingItems,
  required List<DailyPortfolioSnapshotItem> currentItems,
  required List<AssetItem> visibleAssets,
}) {
  final results = [...storedHoldingItems];
  final assetsById = {
    for (final asset in visibleAssets)
      if (asset.id != null) asset.id!: asset,
  };
  final assetsByTitle = {
    for (final asset in visibleAssets)
      _snapshotAssetTitleKey(asset.displayName): asset,
  };
  var syntheticId = -1;

  for (final item in currentItems) {
    if (_hasSnapshotHoldingRowsForAsset(results, item)) continue;

    final asset =
        assetsById[item.assetId] ??
        assetsByTitle[_snapshotAssetTitleKey(item.assetTitle)];
    if (asset == null) continue;

    for (final holding in asset.visibleHoldings.where(
      (holding) => !holding.isCashLike,
    )) {
      results.add(
        DailyPortfolioSnapshotHoldingItem(
          id: syntheticId--,
          snapshotId: item.snapshotId,
          assetId: asset.id ?? item.assetId,
          assetTitle: item.assetTitle,
          holdingId: holding.id,
          holdingName: holding.name,
          holdingSymbol: holding.symbol,
          currencyCode: holding.currencyCode,
          quantity: holding.quantity,
          totalPurchaseAmount: holding.purchaseAmount,
          totalValuationAmount: holding.valuationAmount,
          profitAmount: holding.profitAmount,
          profitRate: holding.profitRate,
        ),
      );
    }
  }

  return results;
}

bool _hasSnapshotHoldingRowsForAsset(
  List<DailyPortfolioSnapshotHoldingItem> rows,
  DailyPortfolioSnapshotItem item,
) {
  final itemKeys = _snapshotAssetKeys(item);
  return rows.any(
    (row) => _snapshotHoldingAssetKeys(row).any(itemKeys.contains),
  );
}

Set<String> _snapshotHoldingAssetKeys(DailyPortfolioSnapshotHoldingItem item) {
  final assetId = item.assetId;
  return {
    if (assetId != null) 'asset:$assetId',
    _snapshotAssetTitleKey(item.assetTitle),
  };
}

String _snapshotAssetTitleKey(String assetTitle) {
  return 'title:${_normalizeSnapshotAssetTitle(assetTitle)}';
}

String _normalizeSnapshotAssetTitle(String value) {
  return value.trim().toLowerCase();
}

class _SnapshotEmbeddedCashAccountRow extends StatelessWidget {
  const _SnapshotEmbeddedCashAccountRow({required this.account});

  final SnapshotCashAccountRecord account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceBase,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.cashAccountName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                _formatSnapshotMoney(account.balance, account.currencyCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            account.currencyCode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotSectionLabel extends StatelessWidget {
  const _SnapshotSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: context.colors.neutralTextMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SnapshotTransactionsCard extends StatelessWidget {
  const _SnapshotTransactionsCard({
    required this.assetTransactions,
    required this.cashTransactions,
  });

  final List<SnapshotTransactionRecord> assetTransactions;
  final List<SnapshotCashTransactionRecord> cashTransactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MoneyfySectionCard(
      title: '거래 스냅샷',
      headerBottomSpacing: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assetTransactions.isEmpty && cashTransactions.isEmpty)
            Text(
              '해당 날짜의 거래 스냅샷이 없습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            )
          else ...[
            if (assetTransactions.isNotEmpty) ...[
              Text('자산 거래', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              TransactionHistoryList(
                itemCount: assetTransactions.length,
                separator: AppDivider(),
                itemBuilder: (context, index) => _SnapshotAssetTransactionRow(
                  transaction: assetTransactions[index],
                ),
              ),
            ],
            if (assetTransactions.isNotEmpty &&
                cashTransactions.isNotEmpty) ...[
              const SizedBox(height: 18),
              AppDivider(),
              const SizedBox(height: 18),
            ],
            if (cashTransactions.isNotEmpty) ...[
              Text('현금 거래', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              TransactionHistoryList(
                itemCount: cashTransactions.length,
                separator: AppDivider(),
                itemBuilder: (context, index) => _SnapshotCashTransactionRow(
                  transaction: cashTransactions[index],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SnapshotAssetTransactionRow extends StatelessWidget {
  const _SnapshotAssetTransactionRow({required this.transaction});

  final SnapshotTransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    return TransactionRow(
      typeLabel: transaction.type,
      title: transaction.name,
      subtitle: '',
      showSubtitle: false,
      amountText: transaction.amount,
    );
  }
}

class _SnapshotCashTransactionRow extends StatelessWidget {
  const _SnapshotCashTransactionRow({required this.transaction});

  final SnapshotCashTransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    return TransactionRow(
      typeLabel: transaction.type,
      title: transaction.name,
      subtitle: '',
      showSubtitle: false,
      amountText: _formatSnapshotMoney(
        double.tryParse(transaction.amount) ?? 0,
        transaction.currencyCode,
      ),
    );
  }
}

class _SnapshotNoteCard extends StatelessWidget {
  const _SnapshotNoteCard({required this.note, required this.onEdit});

  final String note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = note.trim().isNotEmpty;

    return MoneyfySectionCard(
      title: '메모',
      trailing: AppIconButton(
        tooltip: hasNote ? '메모 수정' : '메모 추가',
        onPressed: onEdit,
        icon: hasNote ? AppIconName.edit : AppIconName.add,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      headerBottomSpacing: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasNote ? note : '메모를 추가해 보세요',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasNote
                  ? context.colors.neutralText
                  : context.colors.neutralTextMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.snapshot,
    required this.currentTotalValue,
    required this.currentTotalPurchase,
    required this.previousTotalValue,
    required this.previousDayTotalValue,
  });

  final DailyPortfolioSnapshot snapshot;
  final double currentTotalValue;
  final double currentTotalPurchase;
  final double? previousTotalValue;
  final double? previousDayTotalValue;

  @override
  Widget build(BuildContext context) {
    final evaluationProfitAmount = currentTotalValue - currentTotalPurchase;
    final evaluationProfitRate = currentTotalPurchase == 0
        ? null
        : _calculateChangeRate(
            currentValue: currentTotalValue,
            previousValue: currentTotalPurchase,
          );
    final previousMonthProfitAmount = previousTotalValue == null
        ? null
        : currentTotalValue - previousTotalValue!;
    final previousMonthProfitRate = previousTotalValue == null
        ? null
        : _calculateChangeRate(
            currentValue: currentTotalValue,
            previousValue: previousTotalValue!,
          );
    final previousDayProfitAmount = previousDayTotalValue == null
        ? null
        : currentTotalValue - previousDayTotalValue!;
    final previousDayProfitRate = previousDayTotalValue == null
        ? null
        : _calculateChangeRate(
            currentValue: currentTotalValue,
            previousValue: previousDayTotalValue!,
          );
    return DetailHeaderCard(
      title: '총 자산',
      chips: const [],
      primaryText: _formatCurrency(currentTotalValue),
      secondaryRows: [
        _SnapshotSummaryRow(
          label: '평가 손익',
          valueWidget: _ProfitValueWidget(
            amount: evaluationProfitAmount,
            rate: evaluationProfitRate,
          ),
        ),
        _SnapshotSummaryRow(
          label: '전월 대비 수익',
          valueWidget: _ProfitValueWidget(
            amount: previousMonthProfitAmount,
            rate: previousMonthProfitRate,
          ),
        ),
        if (previousDayProfitAmount != null)
          _SnapshotSummaryRow(
            label: '전일 대비 수익',
            valueWidget: _ProfitValueWidget(
              amount: previousDayProfitAmount,
              rate: previousDayProfitRate,
            ),
          ),
      ],
    );
  }
}

class _SnapshotSummaryRow extends StatelessWidget {
  const _SnapshotSummaryRow({required this.label, required this.valueWidget});

  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: context.typography.meta,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}

class _ProfitValueWidget extends StatelessWidget {
  const _ProfitValueWidget({required this.amount, required this.rate});

  final double? amount;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    if (amount == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          '-',
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Text(
              _formatSignedCurrency(amount!),
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _changeColor(context, amount!),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (rate != null) ...[
            const SizedBox(width: 8),
            DeltaChip(
              value: amount!,
              percent: rate,
              mode: DeltaChipMode.percent,
              vivid: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotItemRow extends StatelessWidget {
  const _SnapshotItemRow({
    required this.item,
    required this.previousItem,
    required this.totalValue,
  });

  final DailyPortfolioSnapshotItem item;
  final DailyPortfolioSnapshotItem? previousItem;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weight = totalValue == 0
        ? 0.0
        : (item.totalValuationAmount / totalValue) * 100;
    final previousProfitAmount = previousItem == null
        ? null
        : item.totalValuationAmount - previousItem!.totalValuationAmount;
    final previousProfitRate = previousItem == null
        ? null
        : _calculateChangeRate(
            currentValue: item.totalValuationAmount,
            previousValue: previousItem!.totalValuationAmount,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  item.assetTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${weight.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.neutralTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(item.totalValuationAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.colors.neutralText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  previousProfitAmount == null
                      ? '-'
                      : _formatSignedCurrency(previousProfitAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: previousProfitAmount == null
                        ? context.colors.neutralTextMuted
                        : _changeColor(context, previousProfitAmount),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (previousProfitRate != null) ...[
                  const SizedBox(width: 8),
                  DeltaChip(
                    value: previousProfitAmount ?? previousProfitRate,
                    percent: previousProfitRate,
                    mode: DeltaChipMode.percent,
                    vivid: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpandableSnapshotItemRow extends StatelessWidget {
  const _ExpandableSnapshotItemRow({
    required this.item,
    required this.previousItem,
    required this.totalValue,
    required this.holdings,
    required this.cashAccounts,
    required this.renderCashAccountsAsPrimaryList,
    required this.isExpanded,
    required this.onDelete,
    required this.onDeleteHolding,
    required this.onTap,
  });

  final DailyPortfolioSnapshotItem item;
  final DailyPortfolioSnapshotItem? previousItem;
  final double totalValue;
  final List<DailyPortfolioSnapshotHoldingItem> holdings;
  final List<SnapshotCashAccountRecord> cashAccounts;
  final bool renderCashAccountsAsPrimaryList;
  final bool isExpanded;
  final VoidCallback onDelete;
  final ValueChanged<DailyPortfolioSnapshotHoldingItem> onDeleteHolding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey('snapshot-item-${item.id}'),
      groupTag: _kSnapshotSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onDelete,
        icon: VisualSpec.icon.delete,
        iconColor: context.colors.negativeOn,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: holdings.isEmpty && cashAccounts.isEmpty ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SnapshotItemRow(
                      item: item,
                      previousItem: previousItem,
                      totalValue: totalValue,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            if (holdings.isNotEmpty) ...[
                              for (final holding in holdings) ...[
                                _SnapshotHoldingRow(
                                  holding: holding,
                                  onDelete: () => onDeleteHolding(holding),
                                ),
                                if (holding != holdings.last)
                                  const SizedBox(height: 10),
                              ],
                            ],
                            if (cashAccounts.isNotEmpty) ...[
                              if (!renderCashAccountsAsPrimaryList) ...[
                                if (holdings.isNotEmpty)
                                  const SizedBox(height: 14),
                                const _SnapshotSectionLabel(title: '현금 계좌'),
                                const SizedBox(height: 10),
                              ],
                              for (final account in cashAccounts) ...[
                                _SnapshotEmbeddedCashAccountRow(
                                  account: account,
                                ),
                                if (account != cashAccounts.last)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotHoldingRow extends StatelessWidget {
  const _SnapshotHoldingRow({required this.holding, required this.onDelete});

  final DailyPortfolioSnapshotHoldingItem holding;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey('snapshot-holding-${holding.id}'),
      groupTag: _kSnapshotSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onDelete,
        icon: VisualSpec.icon.delete,
        iconColor: context.colors.negativeOn,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaces.surfaceBase,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.holdingName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (holding.holdingSymbol.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaces.surfaceRaised,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: context.colors.neutralOutline,
                            ),
                          ),
                          child: Text(
                            holding.holdingSymbol,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.neutralTextMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        '${holding.quantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.neutralTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(holding.totalValuationAmount),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: context.colors.neutralText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatSignedCurrency(holding.profitAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _changeColor(context, holding.profitAmount),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DeltaChip(
                      value: holding.profitAmount,
                      percent: holding.profitRate,
                      mode: DeltaChipMode.percent,
                      vivid: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _changeColor(BuildContext context, double value) {
  if (value > 0) return context.colors.positiveOn;
  if (value < 0) return context.colors.negativeOn;
  return context.colors.neutralTextMuted;
}

double _calculateChangeRate({
  required double currentValue,
  required double previousValue,
}) {
  if (previousValue == 0) return 0;
  return ((currentValue - previousValue) / previousValue) * 100;
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedCurrency(double amount) {
  final prefix = amount > 0 ? '+' : '';
  return '$prefix${_formatCurrency(amount)}';
}

String _formatSnapshotMoney(double amount, String currencyCode) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromSource(
    amount,
    sourceCurrency: currencyCode,
    exchangeRate: 1,
  );
}

String _formatSnapshotDate(String value) {
  final date = DateTime.parse(value);
  return '${date.year}.${date.month}.${date.day}';
}

String _comparisonSnapshotDate(String value) {
  final date = DateTime.parse(value);
  final comparisonDate = date.day <= 20
      ? (date.month == 1
            ? DateTime(date.year - 1, 12, 20)
            : DateTime(date.year, date.month - 1, 20))
      : DateTime(date.year, date.month, 20);
  final month = comparisonDate.month.toString().padLeft(2, '0');
  final day = comparisonDate.day.toString().padLeft(2, '0');
  return '${comparisonDate.year}-$month-$day';
}

String _previousDaySnapshotDate(String value) {
  final date = DateTime.parse(value);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final previousDay = dateOnly.subtract(const Duration(days: 1));
  final month = previousDay.month.toString().padLeft(2, '0');
  final day = previousDay.day.toString().padLeft(2, '0');
  return '${previousDay.year}-$month-$day';
}
