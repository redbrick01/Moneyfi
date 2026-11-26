import 'package:moneyfy/widgets/app_refresh_indicator.dart';
import 'package:moneyfy/utils/monthly_pivot.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moneyfy/components/headers/detail_header_card.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/icons/app_icon_button.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/chips/delta_chip.dart';
import 'package:moneyfy/components/rows/transaction_row.dart';
import 'package:moneyfy/components/separators/app_divider.dart';
import 'package:moneyfy/components/transaction_history_list.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/portfolio/services/snapshot_visibility.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';

class SnapshotDetailPage extends StatefulWidget {
  const SnapshotDetailPage({super.key, required this.snapshot});

  final DailyPortfolioSnapshot snapshot;

  @override
  State<SnapshotDetailPage> createState() => _SnapshotDetailPageState();
}

class _SnapshotDetailPageState extends State<SnapshotDetailPage> {
  late DailyPortfolioSnapshot _currentSnapshot;
  List<SnapshotDisplayItem>? _currentItems;
  bool _loadFailed = false;
  List<SnapshotTransactionRecord> _currentTransactions = const [];
  List<SnapshotCashTransactionRecord> _currentCashTransactions = const [];
  String _note = '';
  DailyPortfolioSnapshot? _previousSnapshot;
  double? _previousDayTotalValue;
  Map<String, SnapshotDisplayItem> _previousItemByAssetKey = const {};
  final Set<String> _expandedAssetKeys = <String>{};
  bool _isNavigatingSnapshot = false;
  int _transitionDirection = 1;
  double _horizontalDragDx = 0;
  double _horizontalDragDy = 0;

  @override
  void initState() {
    super.initState();
    _currentSnapshot = widget.snapshot;
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    final snapshot = _currentSnapshot;
    try {
      final pageData = await _loadSnapshotAuxiliaryData(snapshot);
      if (!mounted || _currentSnapshot != snapshot) return;
      setState(() {
        _applyPageData(pageData);
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted || _currentSnapshot != snapshot) return;
      setState(() => _loadFailed = true);
    }
  }

  void _applyPageData(_SnapshotAuxiliaryData pageData) {
    _currentItems = pageData.currentItems;
    _currentTransactions = pageData.currentTransactions;
    _currentCashTransactions = pageData.currentCashTransactions;
    _note = pageData.note;
    _previousSnapshot = pageData.previousSnapshot;
    _previousDayTotalValue = pageData.previousDayTotalValue;
    _previousItemByAssetKey = pageData.previousItemByAssetKey;
  }

  Future<_SnapshotAuxiliaryData> _loadSnapshotAuxiliaryData(
    DailyPortfolioSnapshot snapshot,
  ) async {
    final db = AppDatabase.instance;
    final snapshotDate = snapshot.snapshotDate;
    final visibility = SnapshotVisibility(await db.fetchAssets());
    final currentSnapshot = await db.fetchPortfolioSnapshotByDate(snapshotDate);
    final comparisonDate = _comparisonSnapshotDate(snapshotDate);
    final previousDayDate = _previousDaySnapshotDate(snapshotDate);
    final previousSnapshot = await db.fetchPortfolioSnapshotByDate(
      comparisonDate,
    );
    final previousDaySnapshot = comparisonDate == previousDayDate
        ? previousSnapshot
        : await db.fetchPortfolioSnapshotByDate(previousDayDate);
    final dates = {
      snapshotDate,
      if (previousSnapshot != null) previousSnapshot.snapshotDate,
      if (previousDaySnapshot != null) previousDaySnapshot.snapshotDate,
    }.toList();

    final itemsFuture = db.fetchPortfolioSnapshotItemsByDates(dates);
    final holdingsFuture = db.fetchPortfolioSnapshotHoldingItemsByDates(dates);
    final cashFuture = db.fetchPortfolioSnapshotCashAccountsByDates(dates);
    final noteFuture = db.fetchSnapshotNote(snapshotDate);
    final transactionsFuture = db.fetchTransactionsForDate(snapshotDate);
    final cashTransactionsFuture = db.fetchCashTransactionsForDate(
      snapshotDate,
    );
    final (
      items,
      holdings,
      cash,
      note,
      transactions,
      cashTransactions,
    ) = await (
      itemsFuture,
      holdingsFuture,
      cashFuture,
      noteFuture,
      transactionsFuture,
      cashTransactionsFuture,
    ).wait;

    List<SnapshotDisplayItem> itemsFor(DailyPortfolioSnapshot? dateSnapshot) {
      if (dateSnapshot == null) return const [];
      final id = dateSnapshot.id;
      return visibility.buildItems(
        snapshot: dateSnapshot,
        items: items.where((item) => item.snapshotId == id).toList(),
        holdings: holdings.where((item) => item.snapshotId == id).toList(),
        cashAccounts: cash.where((item) => item.snapshotId == id).toList(),
      );
    }

    final currentItems = itemsFor(currentSnapshot);
    final previousItems = {
      for (final item in itemsFor(previousSnapshot)) item.assetKey: item,
    };
    final previousDayItems = previousDaySnapshot == previousSnapshot
        ? previousItems
        : {
            for (final item in itemsFor(previousDaySnapshot))
              item.assetKey: item,
          };
    final previousDayTotalValue = previousDaySnapshot == null
        ? null
        : currentItems.fold<double>(
            0,
            (sum, item) =>
                sum +
                (previousDayItems[item.assetKey]?.totalValuationAmount ?? 0),
          );
    return _SnapshotAuxiliaryData(
      currentItems: currentItems,
      currentTransactions: transactions
          .where(visibility.includesTransaction)
          .toList(),
      currentCashTransactions: cashTransactions
          .where(visibility.includesCashTransaction)
          .toList(),
      note: note,
      previousSnapshot: previousSnapshot,
      previousDayTotalValue: previousDayTotalValue,
      previousItemByAssetKey: previousItems,
    );
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    await _loadPageData();
  }

  Future<void> _navigateToAdjacentSnapshot({required bool goPrevious}) async {
    if (_isNavigatingSnapshot) return;

    _isNavigatingSnapshot = true;
    try {
      final targetSnapshot = goPrevious
          ? await AppDatabase.instance.fetchPreviousPortfolioSnapshot(
              _currentSnapshot.snapshotDate,
            )
          : await AppDatabase.instance.fetchNextPortfolioSnapshot(
              _currentSnapshot.snapshotDate,
            );
      if (!mounted || targetSnapshot == null) return;

      final pageData = await _loadSnapshotAuxiliaryData(targetSnapshot);
      if (!mounted) return;

      setState(() {
        _transitionDirection = goPrevious ? -1 : 1;
        _currentSnapshot = targetSnapshot;
        _applyPageData(pageData);
        _loadFailed = false;
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
      snapshotDate: _currentSnapshot.snapshotDate,
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _note = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSnapshot = _currentSnapshot;
    final visibleItems = _currentItems;
    if (_loadFailed || visibleItems == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${_formatSnapshotDate(currentSnapshot.snapshotDate)} 스냅샷',
          ),
        ),
        body: Center(
          child: _loadFailed
              ? TextButton(
                  onPressed: () {
                    setState(() => _loadFailed = false);
                    _loadPageData();
                  },
                  child: const Text('스냅샷을 불러오지 못했어요. 다시 시도'),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    final previousVisibleItemByAssetKey = _previousItemByAssetKey;
    final filteredTotalValue = visibleItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValuationAmount,
    );
    final filteredTotalPurchase = visibleItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPurchaseAmount,
    );
    final filteredPreviousTotalValue = visibleItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (previousVisibleItemByAssetKey[item.assetKey]?.totalValuationAmount ??
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
          child: AppRefreshIndicator(
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
                      child: visibleItems.isEmpty
                          ? Text(
                              '표시할 스냅샷 항목이 없습니다.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: context.colors.neutralTextMuted,
                                  ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final item in visibleItems) ...[
                                  _ExpandableSnapshotItemRow(
                                    item: item,
                                    previousItem:
                                        previousVisibleItemByAssetKey[item
                                            .assetKey],
                                    totalValue: filteredTotalValue,
                                    isExpanded: _expandedAssetKeys.contains(
                                      item.assetKey,
                                    ),
                                    onTap: () {
                                      final key = item.assetKey;
                                      setState(() {
                                        if (_expandedAssetKeys.contains(key)) {
                                          _expandedAssetKeys.remove(key);
                                        } else {
                                          _expandedAssetKeys.add(key);
                                        }
                                      });
                                    },
                                  ),
                                  if (item != visibleItems.last) ...[
                                    const SizedBox(height: 14),
                                    AppDivider(),
                                    const SizedBox(height: 14),
                                  ],
                                ],
                              ],
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
    required this.currentTransactions,
    required this.currentCashTransactions,
    required this.note,
    required this.previousSnapshot,
    required this.previousDayTotalValue,
    required this.previousItemByAssetKey,
  });

  final List<SnapshotDisplayItem> currentItems;
  final List<SnapshotTransactionRecord> currentTransactions;
  final List<SnapshotCashTransactionRecord> currentCashTransactions;
  final String note;
  final DailyPortfolioSnapshot? previousSnapshot;
  final double? previousDayTotalValue;
  final Map<String, SnapshotDisplayItem> previousItemByAssetKey;
}

class _SnapshotEmbeddedCashAccountRow extends StatelessWidget {
  const _SnapshotEmbeddedCashAccountRow({required this.account});

  final SnapshotCashAccountRecord account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppInnerPanel(
      tone: AppInnerPanelTone.raised,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: 10,
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
                  fontWeight: AppFontWeights.semibold,
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
          fontWeight: AppFontWeights.semibold,
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
              SizedBox(height: context.spacing.sm),
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
              SizedBox(height: context.spacing.sm),
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
    required this.currentTotalValue,
    required this.currentTotalPurchase,
    required this.previousTotalValue,
    required this.previousDayTotalValue,
  });

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
                fontWeight: AppFontWeights.semibold,
              ),
            ),
          ),
          if (rate != null) ...[
            SizedBox(width: context.spacing.xs),
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

  final SnapshotDisplayItem item;
  final SnapshotDisplayItem? previousItem;
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
              SizedBox(width: context.spacing.xs),
              Text(
                '${weight.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.neutralTextMuted,
                  fontWeight: AppFontWeights.semibold,
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
                fontWeight: AppFontWeights.semibold,
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
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                if (previousProfitRate != null) ...[
                  SizedBox(width: context.spacing.xs),
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
    required this.isExpanded,
    required this.onTap,
  });

  final SnapshotDisplayItem item;
  final SnapshotDisplayItem? previousItem;
  final double totalValue;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final holdings = item.holdings;
    final cashAccounts = item.cashAccounts;
    final renderCashAccountsAsPrimaryList = item.assetTitle == '현금';

    return InkWell(
      borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
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
                      padding: EdgeInsets.only(top: context.spacing.sm),
                      child: Column(
                        children: [
                          if (holdings.isNotEmpty) ...[
                            for (final holding in holdings) ...[
                              _SnapshotHoldingRow(holding: holding),
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
                              _SnapshotEmbeddedCashAccountRow(account: account),
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
    );
  }
}

class _SnapshotHoldingRow extends StatelessWidget {
  const _SnapshotHoldingRow({required this.holding});

  final DailyPortfolioSnapshotHoldingItem holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppInnerPanel(
      tone: AppInnerPanelTone.raised,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: 10,
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
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: context.spacing.xs,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (holding.holdingSymbol.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaces.surfaceRaised,
                          borderRadius: BorderRadius.circular(
                            context.radius.rPill,
                          ),
                          border: Border.all(
                            color: context.colors.neutralOutline,
                          ),
                        ),
                        child: Text(
                          holding.holdingSymbol,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.neutralTextMuted,
                            fontWeight: AppFontWeights.semibold,
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
                  fontWeight: AppFontWeights.semibold,
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
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  SizedBox(width: context.spacing.xs),
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
    );
  }
}

Color _changeColor(BuildContext context, double value) {
  if (value > 0) return context.colors.gainOn;
  if (value < 0) return context.colors.lossOn;
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
  final comparisonDate = MonthlyPivot.current.periodStart(
    date,
    includeToday: false,
  );
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
