import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/buttons/app_buttons.dart';
import '../components/chips/delta_chip.dart';
import '../components/rows/asset_row.dart';
import '../components/separators/app_divider.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';
import 'cash_account_detail_page.dart';
import 'forms/asset_form_page.dart';
import 'forms/cash_account_form_page.dart';
import 'forms/holding_form_page.dart';
import 'holding_detail_page.dart';

enum _HoldingSortOption {
  custom('기본순'),
  profitRateDesc('수익률 높은순'),
  profitRateAsc('수익률 낮은순'),
  profitDesc('수익 높은순'),
  profitAsc('수익 낮은순');

  const _HoldingSortOption(this.label);

  final String label;
}

Color _iconTone(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

class AssetDetailPage extends StatefulWidget {
  const AssetDetailPage({super.key, required this.assetId, this.assetClientId});

  final int assetId;
  final String? assetClientId;

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  static const String _kSlidableGroupTag = 'asset_detail_slidable_group';
  static const double _kAssetRowHeight = 80;
  static const double _kAssetDividerHeight = 1;
  static const double _kHiddenOverlap = _kAssetRowHeight;
  static const double _kHiddenLeadingSlot = _kAssetRowHeight;

  _HoldingSortOption _holdingSortOption = _HoldingSortOption.custom;
  bool _isHeroDetailExpanded = false;
  late Future<_AssetDetailData?> _detailFuture;
  int _missingAssetRetryCount = 0;
  static const int _kMaxMissingAssetRetries = 3;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadAssetDetailData();
  }

  void _reloadDetail({bool resetMissingRetry = true}) {
    if (!mounted) return;
    setState(() {
      if (resetMissingRetry) {
        _missingAssetRetryCount = 0;
      }
      _detailFuture = _loadAssetDetailData();
    });
  }

  void _scheduleMissingAssetRetry() {
    if (!mounted) return;
    _missingAssetRetryCount += 1;
    final delayMs = 180 * _missingAssetRetryCount;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _reloadDetail(resetMissingRetry: false);
    });
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    _reloadDetail();
  }

  Future<void> _editAsset(AssetItem item) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AssetFormPage(item: item)));

    if (changed == true && mounted) {
      _reloadDetail();
    }
  }

  Future<void> _deleteAsset(AssetItem item) async {
    final assetId = await _resolveCurrentAssetId(item);
    if (assetId == null) return;
    final confirmed = await _confirmDelete(
      title: '자산군 삭제',
      message: '${item.displayName} 자산군을 삭제하시겠습니까?',
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteAssetItem(assetId);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'delete_asset');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppGhostButton(
            expand: false,
            onPressed: () => Navigator.of(context).pop(false),
            label: '취소',
          ),
          AppDestructiveButton(
            expand: false,
            onPressed: () => Navigator.of(context).pop(true),
            label: '삭제',
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _openHoldingForm({
    int? assetId,
    HoldingItem? item,
    bool isCashAccount = false,
  }) async {
    final currentAssetId =
        assetId ?? (await _resolveCurrentAssetId(null)) ?? widget.assetId;
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => isCashAccount
            ? CashAccountFormPage(assetId: currentAssetId, item: item)
            : HoldingFormPage(assetId: currentAssetId, item: item),
      ),
    );

    if (changed == true && mounted) {
      _reloadDetail();
    }
  }

  Future<void> _toggleHoldingHidden(HoldingItem holding) async {
    final holdingId = await _resolveCurrentHoldingId(holding);
    if (holdingId == null) return;
    await AppDatabase.instance.updateHoldingHidden(
      holdingId,
      !holding.isHidden,
    );
    if (!mounted) return;
    _reloadDetail();
  }

  Future<int?> _resolveCurrentAssetId(AssetItem? item) async {
    final id = item?.id ?? widget.assetId;
    final byId = await AppDatabase.instance.fetchAssetById(id);
    if (byId?.id != null) return byId!.id;

    final clientId = item?.clientId ?? widget.assetClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      final byClientId = await AppDatabase.instance.fetchAssetByClientId(
        clientId,
      );
      if (byClientId?.id != null) return byClientId!.id;
    }
    return null;
  }

  Future<int?> _resolveCurrentHoldingId(HoldingItem holding) async {
    final id = holding.id;
    if (id != null) {
      final byId = await AppDatabase.instance.fetchHoldingById(id);
      if (byId?.id != null) return byId!.id;
    }

    final clientId = holding.clientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      final byClientId = await AppDatabase.instance.fetchHoldingByClientId(
        clientId,
      );
      if (byClientId?.id != null) return byClientId!.id;
    }
    return null;
  }

  Future<_AssetDetailData?> _loadAssetDetailData() async {
    final item = await _fetchAssetByIdWithRetry(
      assetId: widget.assetId,
      assetClientId: widget.assetClientId,
    );
    if (item == null) return null;
    final now = DateTime.now();

    final totalValuationAmount = item.visibleHoldings.fold<double>(
      0,
      (sum, holding) => sum + holding.valuationAmount,
    );

    final comparisonSnapshotDate = _previousMonthComparisonDate(now);
    final previousDayDate = _snapshotDate(
      now.subtract(const Duration(days: 1)),
    );
    final twoDaysAgoDate = _snapshotDate(now.subtract(const Duration(days: 2)));

    double previousSnapshotValue = totalValuationAmount;
    final comparisonValue = await _resolveAssetComparisonValueFromRawSnapshot(
      snapshotDate: comparisonSnapshotDate,
      asset: item,
    );

    if (comparisonValue != null) {
      previousSnapshotValue = comparisonValue;
    } else {
      final snapshots = await AppDatabase.instance
          .fetchRecentPortfolioSnapshots(maxDates: 2);
      if (snapshots.length >= 2) {
        final fallbackDate = snapshots[snapshots.length - 2].snapshotDate;
        previousSnapshotValue =
            await _resolveAssetComparisonValueFromRawSnapshot(
              snapshotDate: fallbackDate,
              asset: item,
            ) ??
            previousSnapshotValue;
      }
    }

    final monthlyProfit = totalValuationAmount - previousSnapshotValue;
    final monthlyProfitRate = previousSnapshotValue == 0
        ? 0.0
        : (monthlyProfit / previousSnapshotValue) * 100;
    final previousDaySnapshotValue =
        await _resolveAssetComparisonValueFromRawSnapshot(
          snapshotDate: previousDayDate,
          asset: item,
        );
    final twoDaysAgoValue = await _resolveAssetComparisonValueFromRawSnapshot(
      snapshotDate: twoDaysAgoDate,
      asset: item,
    );
    final previousDayComparison = _AssetDailyComparison(
      previousValue: previousDaySnapshotValue ?? twoDaysAgoValue,
    );
    final previousDayValue = previousDayComparison.previousValue ?? 0;
    final dailyProfit = totalValuationAmount - previousDayValue;
    final dailyProfitRate = previousDayValue == 0
        ? 0.0
        : (dailyProfit / previousDayValue) * 100;
    return _AssetDetailData(
      item: item,
      monthlyProfit: monthlyProfit,
      monthlyProfitRate: monthlyProfitRate,
      dailyProfit: dailyProfit,
      dailyProfitRate: dailyProfitRate,
      hasDailyComparison: previousDayComparison.previousValue != null,
    );
  }

  Future<AssetItem?> _fetchAssetByIdWithRetry({
    required int assetId,
    String? assetClientId,
  }) async {
    final normalizedClientId = assetClientId?.trim() ?? '';
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final item = await AppDatabase.instance.fetchAssetById(assetId);
        if (item != null) return item;
        if (normalizedClientId.isNotEmpty) {
          final byClientId = await AppDatabase.instance.fetchAssetByClientId(
            normalizedClientId,
          );
          if (byClientId != null) return byClientId;
        }
      } catch (_) {
        // Transient DB/read contention can happen around app startup/sync.
      }
      if (attempt < 7) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    }
    return null;
  }

  Future<double?> _resolveAssetComparisonValueFromRawSnapshot({
    required String snapshotDate,
    required AssetItem asset,
  }) async {
    final results = await Future.wait<Object?>([
      AppDatabase.instance.fetchPortfolioSnapshotByDate(snapshotDate),
      AppDatabase.instance.fetchPortfolioSnapshotHoldingItemsByDates([
        snapshotDate,
      ]),
      AppDatabase.instance.fetchPortfolioSnapshotCashAccountsByDates([
        snapshotDate,
      ]),
    ]);

    final snapshot = results[0] as DailyPortfolioSnapshot?;
    final holdingRows = results[1] as List<DailyPortfolioSnapshotHoldingItem>;
    final cashRows = results[2] as List<SnapshotCashAccountRecord>;
    final snapshotExchangeRate = snapshot?.exchangeRate ?? 1.0;

    return _sumRawSnapshotVisibleAssetValues(
      asset: asset,
      holdingRows: holdingRows,
      cashRows: cashRows,
      snapshotExchangeRate: snapshotExchangeRate,
    );
  }

  double? _sumRawSnapshotVisibleAssetValues({
    required AssetItem asset,
    required List<DailyPortfolioSnapshotHoldingItem> holdingRows,
    required List<SnapshotCashAccountRecord> cashRows,
    required double snapshotExchangeRate,
  }) {
    final targetAssetId = asset.id;
    final targetAssetTitle = _normalizeAssetTitle(asset.displayName);
    final hiddenInvestmentHoldings = asset.holdings
        .where((holding) => !_isCashLikeHolding(holding))
        .where((holding) => holding.isHidden)
        .toList(growable: false);
    final hiddenCashHoldings = asset.holdings
        .where((holding) => _isCashLikeHolding(holding))
        .where((holding) => holding.isHidden)
        .toList(growable: false);

    final hiddenHoldingIds = hiddenInvestmentHoldings
        .map((holding) => holding.id)
        .whereType<int>()
        .toSet();
    final hiddenHoldingKeys = hiddenInvestmentHoldings
        .map(
          (holding) =>
              '${_normalizeAssetTitle(holding.name)}|${_normalizeAssetTitle(holding.symbol)}',
        )
        .where((key) => key != '|')
        .toSet();
    final hiddenCashAccountIds = hiddenCashHoldings
        .map((holding) => holding.id)
        .whereType<int>()
        .where((id) => id < 0)
        .map((id) => id.abs())
        .toSet();
    final hiddenCashAccountKeys = hiddenCashHoldings
        .map(
          (holding) =>
              '${_normalizeAssetTitle(holding.name)}|${_normalizeAssetTitle(holding.currencyCode)}',
        )
        .where((key) => key != '|')
        .toSet();

    bool rowMatchesAsset({
      required int? rowAssetId,
      required String rowAssetTitle,
    }) {
      final normalizedTitle = _normalizeAssetTitle(rowAssetTitle);
      return targetAssetId != null && rowAssetId == targetAssetId ||
          (targetAssetTitle.isNotEmpty && normalizedTitle == targetAssetTitle);
    }

    var matchedAssetRows = false;
    var includedRows = false;
    var total = 0.0;

    for (final row in holdingRows) {
      if (!rowMatchesAsset(
        rowAssetId: row.assetId,
        rowAssetTitle: row.assetTitle,
      )) {
        continue;
      }
      matchedAssetRows = true;
      final holdingKey =
          '${_normalizeAssetTitle(row.holdingName)}|${_normalizeAssetTitle(row.holdingSymbol)}';
      final isHiddenHolding =
          row.holdingId != null && hiddenHoldingIds.contains(row.holdingId) ||
          (holdingKey != '|' && hiddenHoldingKeys.contains(holdingKey));
      if (isHiddenHolding) continue;
      includedRows = true;
      total += row.totalValuationAmount;
    }

    for (final row in cashRows) {
      if (!rowMatchesAsset(
        rowAssetId: row.assetId,
        rowAssetTitle: row.assetTitle,
      )) {
        continue;
      }
      matchedAssetRows = true;
      final cashKey =
          '${_normalizeAssetTitle(row.cashAccountName)}|${_normalizeAssetTitle(row.currencyCode)}';
      final isHiddenCash =
          row.cashAccountId != null &&
              hiddenCashAccountIds.contains(row.cashAccountId) ||
          (cashKey != '|' && hiddenCashAccountKeys.contains(cashKey));
      if (isHiddenCash) continue;
      includedRows = true;
      final isUsd = row.currencyCode.trim().toUpperCase() == 'USD';
      total += isUsd ? row.balance * snapshotExchangeRate : row.balance;
    }

    if (!matchedAssetRows) return null;
    return includedRows ? total : 0.0;
  }

  String _normalizeAssetTitle(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.neutralBackground,
      appBar: AppBar(
        backgroundColor: context.colors.neutralBackground,
        elevation: 0,
      ),
      body: FutureBuilder<_AssetDetailData?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (_missingAssetRetryCount < _kMaxMissingAssetRetries) {
              _scheduleMissingAssetRetry();
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('자산 정보를 불러오지 못했습니다.'),
                  SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
                  TextButton(
                    onPressed: () => _reloadDetail(resetMissingRetry: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            if (_missingAssetRetryCount < _kMaxMissingAssetRetries) {
              _scheduleMissingAssetRetry();
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('자산 정보를 찾을 수 없습니다.'),
                  SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
                  TextButton(
                    onPressed: () => _reloadDetail(resetMissingRetry: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final item = data.item;
          final holdings = _sortHoldings(item.holdings);
          final investmentHoldings = holdings
              .where((holding) => !_isCashLikeHolding(holding))
              .where((holding) => !holding.isClosedInvestmentPosition)
              .toList(growable: false);
          final visibleInvestmentHoldings = investmentHoldings
              .where((holding) => !holding.isHidden)
              .toList(growable: false);
          final hiddenInvestmentHoldings = investmentHoldings
              .where((holding) => holding.isHidden)
              .toList(growable: false);
          final cashLikeHoldings = holdings
              .where((holding) => _isCashLikeHolding(holding))
              .toList(growable: false);
          final visibleCashLikeHoldings = cashLikeHoldings
              .where((holding) => !holding.isHidden)
              .toList(growable: false);
          final hiddenCashLikeHoldings = cashLikeHoldings
              .where((holding) => holding.isHidden)
              .toList(growable: false);
          final visibleHoldings = item.visibleHoldings;
          final totalValuationAmount = visibleHoldings.fold<double>(
            0,
            (sum, holding) => sum + holding.valuationAmount,
          );
          final totalProfitAmount = visibleHoldings.fold<double>(
            0,
            (sum, holding) => sum + holding.profitAmount,
          );
          final totalPurchaseAmount = visibleHoldings.fold<double>(
            0,
            (sum, holding) => sum + holding.purchaseAmount,
          );
          final valuationProfitRate = totalPurchaseAmount == 0
              ? 0.0
              : ((totalProfitAmount / totalPurchaseAmount) * 100);
          final monthlyProfit = data.monthlyProfit;
          final monthlyProfitRate = data.monthlyProfitRate;
          final dailyProfit = data.dailyProfit;
          final dailyProfitRate = data.dailyProfitRate;
          final hasDailyComparison = data.hasDailyComparison;
          final valuationDisplayValue = _formatSignedCurrency(
            totalProfitAmount,
          );
          final monthlyDisplayValue = _formatSignedCurrency(monthlyProfit);
          final dailyDisplayValue = hasDailyComparison
              ? _formatSignedCurrency(dailyProfit)
              : '-';
          final isCashAssetGroup =
              item.displayName == '현금' ||
              (investmentHoldings.isEmpty && cashLikeHoldings.isNotEmpty);

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  context.contentHorizontalPadding,
                  context.spacing.sm,
                  context.contentHorizontalPadding,
                  context.spacing.sectionGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoneyfySurfaceCard(
                      variant: MoneyfySurfaceCardVariant.raised,
                      padding: EdgeInsets.all(context.cardPadding()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: context.colors.neutralSurfaceRaised,
                                  borderRadius: BorderRadius.circular(
                                    VisualSpec.surface.radiusCard,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: _iconTone(context),
                                ),
                              ),
                              SizedBox(width: context.spacing.sm),
                              Expanded(
                                child: Text(
                                  item.displayName,
                                  style: context.typography.cardTitle.copyWith(
                                    fontWeight: AppFontWeights.semibold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editAsset(item),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: VisualSpec.icon.sizeSmall,
                                ),
                                color: _iconTone(context),
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              SizedBox(
                                width:
                                    context.spacing.xs + context.spacing.xs / 4,
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.7),
                              ),
                              SizedBox(
                                width:
                                    context.spacing.xs + context.spacing.xs / 4,
                              ),
                              IconButton(
                                onPressed: () => _deleteAsset(item),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: VisualSpec.icon.sizeSmall,
                                ),
                                color: _iconTone(context),
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              if (item.isHidden)
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.visibility_off_rounded,
                                    size: 16,
                                    color: _iconTone(context),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.spacing.lg),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              totalValuationAmount == 0
                                  ? item.value
                                  : MoneyfyDisplayCurrencySettings.formatAmountFromKrw(
                                      totalValuationAmount,
                                    ),
                              style: context.typography.heroNumber.copyWith(
                                fontWeight: AppFontWeights.semibold,
                                height: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: context.spacing.md),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity > 120 && !_isHeroDetailExpanded) {
                                setState(() {
                                  _isHeroDetailExpanded = true;
                                });
                              } else if (velocity < -120 &&
                                  _isHeroDetailExpanded) {
                                setState(() {
                                  _isHeroDetailExpanded = false;
                                });
                              }
                            },
                            child: AnimatedSize(
                              duration: context.motion.fast,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: Container(
                                padding: EdgeInsets.all(context.cardPadding()),
                                decoration: BoxDecoration(
                                  color: context.surfaces.surfaceBase,
                                  borderRadius: BorderRadius.circular(
                                    VisualSpec.surface.radiusCard,
                                  ),
                                  boxShadow: context.shadows.level2,
                                ),
                                child: Column(
                                  children: [
                                    _HeroMetricRow(
                                      label: isCashAssetGroup
                                          ? '전월 대비 수익'
                                          : '평가 손익',
                                      value: isCashAssetGroup
                                          ? monthlyDisplayValue
                                          : valuationDisplayValue,
                                      rawValue: isCashAssetGroup
                                          ? monthlyProfit
                                          : totalProfitAmount,
                                      percentValue: isCashAssetGroup
                                          ? monthlyProfitRate
                                          : valuationProfitRate,
                                      showDeltaChip: true,
                                    ),
                                    AnimatedSwitcher(
                                      duration: context.motion.fast,
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SizeTransition(
                                            sizeFactor: animation,
                                            axisAlignment: -1,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _isHeroDetailExpanded
                                          ? Column(
                                              key: const ValueKey(
                                                'hero-expanded',
                                              ),
                                              children: [
                                                SizedBox(
                                                  height: context.spacing.md,
                                                ),
                                                if (!isCashAssetGroup)
                                                  _HeroMetricRow(
                                                    label: '전월 대비 수익',
                                                    value: monthlyDisplayValue,
                                                    rawValue: monthlyProfit,
                                                    percentValue:
                                                        monthlyProfitRate,
                                                  ),
                                                if (!isCashAssetGroup)
                                                  SizedBox(
                                                    height: context.spacing.md,
                                                  ),
                                                _HeroMetricRow(
                                                  label: '전일 대비 수익',
                                                  value: dailyDisplayValue,
                                                  rawValue: dailyProfit,
                                                  percentValue: dailyProfitRate,
                                                  showDeltaChip:
                                                      hasDailyComparison,
                                                ),
                                              ],
                                            )
                                          : const SizedBox(
                                              key: ValueKey('hero-collapsed'),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: context.spacing.md + context.spacing.xs / 2,
                    ),
                    if (!isCashAssetGroup) ...[
                      _DetailSection(
                        title: '보유 정보',
                        wrapBodyWithInnerCard: false,
                        showHeaderTrailingDivider: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<_HoldingSortOption>(
                              tooltip: '정렬',
                              initialValue: _holdingSortOption,
                              onSelected: (value) =>
                                  setState(() => _holdingSortOption = value),
                              padding: EdgeInsets.zero,
                              splashRadius: 18,
                              color: context.surfaces.surfaceBase,
                              surfaceTintColor: Theme.of(
                                context,
                              ).colorScheme.surfaceTint,
                              elevation: 0,
                              offset: const Offset(0, 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VisualSpec.surface.radiusCard,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              menuPadding: EdgeInsets.symmetric(
                                vertical: context.spacing.xs,
                              ),
                              constraints: const BoxConstraints(minWidth: 190),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: VisualSpec.icon.sizeSmall,
                                color: _iconTone(context),
                              ),
                              iconSize: VisualSpec.icon.sizeSmall,
                              itemBuilder: (context) => [
                                PopupMenuItem<_HoldingSortOption>(
                                  enabled: false,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.spacing.xs,
                                    vertical: context.spacing.xs / 2,
                                  ),
                                  child: _HoldingSortMenuCard(
                                    selected: _holdingSortOption,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.7),
                            ),
                            SizedBox(
                              width:
                                  context.spacing.xs + context.spacing.xs / 4,
                            ),
                            IconButton(
                              onPressed: () =>
                                  _openHoldingForm(assetId: item.id),
                              icon: const Icon(Icons.add_rounded),
                              color: _iconTone(context),
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        child: investmentHoldings.isEmpty
                            ? _buildEmptyDetailCard(context, '등록된 보유 종목이 없습니다.')
                            : _buildGroupedHoldingCards(
                                context: context,
                                visibleHoldings: visibleInvestmentHoldings,
                                hiddenHoldings: hiddenInvestmentHoldings,
                              ),
                      ),
                      SizedBox(height: context.spacing.md),
                    ],
                    _DetailSection(
                      title: '현금 계좌',
                      wrapBodyWithInnerCard: false,
                      trailing: IconButton(
                        onPressed: () => _openHoldingForm(
                          assetId: item.id,
                          isCashAccount: true,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        color: _iconTone(context),
                      ),
                      child: cashLikeHoldings.isEmpty
                          ? _buildEmptyDetailCard(context, '등록된 현금 계좌가 없습니다.')
                          : _buildGroupedCashAccountCards(
                              context: context,
                              visibleHoldings: visibleCashLikeHoldings,
                              hiddenHoldings: hiddenCashLikeHoldings,
                            ),
                    ),
                    if (true) ...[SizedBox(height: context.spacing.md)],
                    _DetailSection(
                      title: '메모',
                      trailing: IconButton(
                        onPressed: () => _editAsset(item),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: VisualSpec.icon.sizeSmall,
                        ),
                        color: _iconTone(context),
                      ),
                      child: Text(item.note, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<HoldingItem> _sortHoldings(List<HoldingItem> holdings) {
    final sorted = List<HoldingItem>.from(holdings);
    switch (_holdingSortOption) {
      case _HoldingSortOption.custom:
        return sorted;
      case _HoldingSortOption.profitRateDesc:
        sorted.sort((a, b) => b.profitRate.compareTo(a.profitRate));
      case _HoldingSortOption.profitRateAsc:
        sorted.sort((a, b) => a.profitRate.compareTo(b.profitRate));
      case _HoldingSortOption.profitDesc:
        sorted.sort((a, b) => b.profitAmount.compareTo(a.profitAmount));
      case _HoldingSortOption.profitAsc:
        sorted.sort((a, b) => a.profitAmount.compareTo(b.profitAmount));
    }
    return sorted;
  }

  Future<void> _reorderHoldings(
    List<HoldingItem> visibleItems,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final reordered = List<HoldingItem>.from(visibleItems);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final assetId = await _resolveCurrentAssetId(null);
    final holdingIds = <int>[];
    for (final item in reordered) {
      final holdingId = await _resolveCurrentHoldingId(item);
      if (holdingId != null) holdingIds.add(holdingId);
    }
    if (assetId == null) {
      _reloadDetail();
      return;
    }
    if (holdingIds.length != reordered.length) {
      _reloadDetail();
      return;
    }

    try {
      await AppDatabase.instance.reorderHoldings(
        assetId: assetId,
        holdingIds: holdingIds,
      );
    } finally {
      _reloadDetail();
    }
  }

  Future<void> _reorderCashAccounts(
    List<HoldingItem> visibleItems,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final reordered = List<HoldingItem>.from(visibleItems);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final assetId = await _resolveCurrentAssetId(null);
    final cashAccountIds = <int>[];
    for (final item in reordered) {
      final cashAccountId = await _resolveCurrentHoldingId(item);
      if (cashAccountId != null) cashAccountIds.add(cashAccountId);
    }
    if (assetId == null) {
      _reloadDetail();
      return;
    }
    if (cashAccountIds.length != reordered.length) {
      _reloadDetail();
      return;
    }

    try {
      await AppDatabase.instance.reorderCashAccounts(
        assetId: assetId,
        cashAccountIds: cashAccountIds,
      );
    } finally {
      _reloadDetail();
    }
  }

  Widget _buildGroupedHoldingCards({
    required BuildContext context,
    required List<HoldingItem> visibleHoldings,
    required List<HoldingItem> hiddenHoldings,
  }) {
    if (hiddenHoldings.isEmpty || visibleHoldings.isEmpty) {
      return _buildHoldingCard(
        context,
        hiddenHoldings.isEmpty ? visibleHoldings : hiddenHoldings,
        reorderable: true,
      );
    }
    final frontHeight = _assetCardHeight(
      rowCount: visibleHoldings.length,
      includeLeadingEmptySlot: false,
    );
    final hiddenHeight = _assetCardHeight(
      rowCount: hiddenHoldings.length,
      includeLeadingEmptySlot: true,
    );
    final hiddenTop = frontHeight - _kHiddenOverlap;
    final totalHeight = frontHeight + hiddenHeight - _kHiddenOverlap;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: hiddenTop,
            child: _buildHoldingCard(
              context,
              hiddenHoldings,
              leadingEmptySlot: true,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _buildHoldingCard(
              context,
              visibleHoldings,
              reorderable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingCard(
    BuildContext context,
    List<HoldingItem> items, {
    bool leadingEmptySlot = false,
    bool reorderable = false,
  }) {
    return MoneyfySurfaceCard(
      variant: MoneyfySurfaceCardVariant.base,
      padding: EdgeInsets.zero,
      child: SlidableAutoCloseBehavior(
        child: reorderable
            ? ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderHoldings(items, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final holding = items[index];
                  return Column(
                    key: ValueKey(
                      'holding-reorder-${holding.id ?? holding.name}-$index',
                    ),
                    children: [
                      ReorderableDelayedDragStartListener(
                        index: index,
                        child: _HoldingRow(
                          holding: holding,
                          onChanged: _reloadDetail,
                          onToggleHidden: () => _toggleHoldingHidden(holding),
                        ),
                      ),
                      if (index != items.length - 1) const AppDivider(inset: 0),
                    ],
                  );
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingEmptySlot) const _HiddenLeadingSlot(),
                  for (var index = 0; index < items.length; index++) ...[
                    _HoldingRow(
                      holding: items[index],
                      onChanged: _reloadDetail,
                      onToggleHidden: () => _toggleHoldingHidden(items[index]),
                    ),
                    if (index != items.length - 1) const AppDivider(inset: 0),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildGroupedCashAccountCards({
    required BuildContext context,
    required List<HoldingItem> visibleHoldings,
    required List<HoldingItem> hiddenHoldings,
  }) {
    if (hiddenHoldings.isEmpty || visibleHoldings.isEmpty) {
      return _buildCashAccountCardList(
        hiddenHoldings.isEmpty ? visibleHoldings : hiddenHoldings,
        reorderable: true,
      );
    }
    final frontHeight = _assetCardHeight(
      rowCount: visibleHoldings.length,
      includeLeadingEmptySlot: false,
    );
    final hiddenHeight = _assetCardHeight(
      rowCount: hiddenHoldings.length,
      includeLeadingEmptySlot: true,
    );
    final hiddenTop = frontHeight - _kHiddenOverlap;
    final totalHeight = frontHeight + hiddenHeight - _kHiddenOverlap;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: hiddenTop,
            child: _buildCashAccountCardList(
              hiddenHoldings,
              leadingEmptySlot: true,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _buildCashAccountCardList(
              visibleHoldings,
              reorderable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashAccountCardList(
    List<HoldingItem> items, {
    bool leadingEmptySlot = false,
    bool reorderable = false,
  }) {
    return MoneyfySurfaceCard(
      variant: MoneyfySurfaceCardVariant.base,
      padding: EdgeInsets.zero,
      child: SlidableAutoCloseBehavior(
        child: reorderable
            ? ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderCashAccounts(items, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final holding = items[index];
                  return Column(
                    key: ValueKey(
                      'cash-reorder-${holding.id ?? holding.name}-$index',
                    ),
                    children: [
                      ReorderableDelayedDragStartListener(
                        index: index,
                        child: _CashAccountCard(
                          holding: holding,
                          onChanged: _reloadDetail,
                          onToggleHidden: () => _toggleHoldingHidden(holding),
                        ),
                      ),
                      if (index != items.length - 1) const AppDivider(inset: 0),
                    ],
                  );
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingEmptySlot) const _HiddenLeadingSlot(),
                  for (var index = 0; index < items.length; index++) ...[
                    _CashAccountCard(
                      holding: items[index],
                      onChanged: _reloadDetail,
                      onToggleHidden: () => _toggleHoldingHidden(items[index]),
                    ),
                    if (index != items.length - 1) const AppDivider(inset: 0),
                  ],
                ],
              ),
      ),
    );
  }

  double _assetCardHeight({
    required int rowCount,
    required bool includeLeadingEmptySlot,
  }) {
    final totalRows = rowCount + (includeLeadingEmptySlot ? 1 : 0);
    if (totalRows <= 0) return 0;
    return (totalRows * _kAssetRowHeight) +
        ((totalRows - 1) * _kAssetDividerHeight);
  }

  Widget _buildEmptyDetailCard(BuildContext context, String message) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: MoneyfySurfaceCard(
        variant: MoneyfySurfaceCardVariant.base,
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
      ),
    );
  }
}

class _HiddenLeadingSlot extends StatelessWidget {
  const _HiddenLeadingSlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: _AssetDetailPageState._kHiddenLeadingSlot);
  }
}

bool _isCashLikeHolding(HoldingItem holding) {
  return holding.isCashLike;
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

String _previousMonthComparisonDate(DateTime date) {
  final comparisonDate = date.day <= 20
      ? (date.month == 1
            ? DateTime(date.year - 1, 12, 20)
            : DateTime(date.year, date.month - 1, 20))
      : DateTime(date.year, date.month, 20);
  final month = comparisonDate.month.toString().padLeft(2, '0');
  final day = comparisonDate.day.toString().padLeft(2, '0');
  return '${comparisonDate.year}-$month-$day';
}

String _snapshotDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _AssetDetailData {
  const _AssetDetailData({
    required this.item,
    required this.monthlyProfit,
    required this.monthlyProfitRate,
    required this.dailyProfit,
    required this.dailyProfitRate,
    required this.hasDailyComparison,
  });

  final AssetItem item;
  final double monthlyProfit;
  final double monthlyProfitRate;
  final double dailyProfit;
  final double dailyProfitRate;
  final bool hasDailyComparison;
}

class _AssetDailyComparison {
  const _AssetDailyComparison({required this.previousValue});

  final double? previousValue;
}

class _HeroMetricRow extends StatelessWidget {
  const _HeroMetricRow({
    required this.label,
    required this.value,
    required this.rawValue,
    required this.percentValue,
    this.showDeltaChip = true,
  });

  final String label;
  final String value;
  final double rawValue;
  final double percentValue;
  final bool showDeltaChip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.typography.meta.copyWith(
                fontWeight: AppFontWeights.semibold,
                color: context.colors.neutralText,
              ),
            ),
          ),
          Text(
            value,
            style: context.typography.meta.copyWith(
              color: _valueStringColor(context, value),
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
          if (showDeltaChip)
            DeltaChip(
              value: rawValue,
              percent: percentValue,
              mode: DeltaChipMode.percent,
              vivid: true,
            )
          else
            const _HeroDashChip(),
        ],
      ),
    );
  }
}

class _HeroDashChip extends StatelessWidget {
  const _HeroDashChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceBase,
        border: Border.all(color: context.colors.neutralOutline),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Text(
        '-',
        style: context.typography.meta.copyWith(
          color: context.colors.neutralText,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
    this.wrapBodyWithInnerCard = true,
    this.showHeaderTrailingDivider = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool wrapBodyWithInnerCard;
  final bool showHeaderTrailingDivider;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.7);
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
        boxShadow: context.shadows.level3,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: context.typography.sectionTitle),
                ),
                if (trailing != null) ...[
                  if (showHeaderTrailingDivider) ...[
                    SizedBox(
                      width: context.spacing.xs + context.spacing.xs / 4,
                    ),
                    Container(width: 1, height: 24, color: dividerColor),
                    SizedBox(
                      width: context.spacing.xs + context.spacing.xs / 4,
                    ),
                  ],
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
            if (wrapBodyWithInnerCard)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surfaces.surfaceBase,
                    borderRadius: BorderRadius.circular(
                      VisualSpec.surface.radiusCard,
                    ),
                    boxShadow: context.shadows.level2,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.cardPadding()),
                    child: child,
                  ),
                ),
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}

class _HoldingSortMenuCard extends StatelessWidget {
  const _HoldingSortMenuCard({required this.selected});

  final _HoldingSortOption selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: context.shadows.level1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (
            var index = 0;
            index < _HoldingSortOption.values.length;
            index++
          ) ...[
            _HoldingSortMenuRow(
              option: _HoldingSortOption.values[index],
              selected: selected,
            ),
            if (index != _HoldingSortOption.values.length - 1)
              const AppDivider(inset: 0),
          ],
        ],
      ),
    );
  }
}

class _HoldingSortMenuRow extends StatelessWidget {
  const _HoldingSortMenuRow({required this.option, required this.selected});

  final _HoldingSortOption option;
  final _HoldingSortOption selected;

  @override
  Widget build(BuildContext context) {
    final isSelected = option == selected;
    return InkWell(
      onTap: () => Navigator.of(context).pop<_HoldingSortOption>(option),
      borderRadius: BorderRadius.circular(context.radius.rMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.sm - 2,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.circle_outlined,
                  size: isSelected ? 18 : 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: context.spacing.xs + 2),
            Expanded(
              child: Text(
                option.label,
                style: context.typography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.holding,
    required this.onChanged,
    required this.onToggleHidden,
  });

  final HoldingItem holding;
  final VoidCallback onChanged;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (holding.symbol.trim().isNotEmpty) holding.symbol.trim(),
      holding.quantityText,
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    final rowChild = AssetRow(
      minHeight: 80,
      leading: const SizedBox.shrink(),
      showLeading: false,
      title: holding.name,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
      amountText: holding.value,
      deltaChip: _HoldingProfitLine(
        profitAmount: holding.profitAmount,
        profitRate: holding.profitRate,
      ),
      isHidden: holding.isHidden,
      showChevron: false,
      onTap: () async {
        if (holding.id == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HoldingDetailPage(
              holdingId: holding.id!,
              holdingClientId: holding.clientId,
            ),
          ),
        );
        onChanged();
      },
    );

    return Slidable(
      key: ValueKey('holding-slide-${holding.id ?? holding.name}'),
      groupTag: _AssetDetailPageState._kSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onToggleHidden,
        icon: holding.isHidden
            ? Icons.visibility_rounded
            : Icons.visibility_off_rounded,
        iconColor: _iconTone(context),
      ),
      child: Opacity(
        opacity: holding.isHidden ? 0.6 : 1,
        child: holding.isHidden
            ? ClipRRect(
                borderRadius: BorderRadius.circular(context.radius.rMd),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 3.6, sigmaY: 3.6),
                  child: rowChild,
                ),
              )
            : rowChild,
      ),
    );
  }
}

class _HoldingProfitLine extends StatelessWidget {
  const _HoldingProfitLine({
    required this.profitAmount,
    required this.profitRate,
  });

  final double profitAmount;
  final double profitRate;

  @override
  Widget build(BuildContext context) {
    final profitText = MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(
      profitAmount,
    );
    final amountColor = _valueStringColor(context, profitText);
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                profitText,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: context.typography.body.copyWith(
                  color: amountColor,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.spacing.xs),
        DeltaChip(
          value: profitAmount,
          percent: profitRate,
          mode: DeltaChipMode.percent,
          vivid: true,
        ),
      ],
    );
  }
}

Color _valueStringColor(BuildContext context, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return context.colors.neutralText;
  }
  if (normalized.startsWith('-') || normalized.startsWith('−')) {
    return context.colors.negativeOn;
  }
  if (normalized.startsWith('+')) return context.colors.positiveOn;
  if (normalized.startsWith('(') && normalized.endsWith(')')) {
    return context.colors.negativeOn;
  }
  if (normalized.contains('-') || normalized.contains('−')) {
    return context.colors.negativeOn;
  }
  if (normalized.contains('+')) return context.colors.positiveOn;
  return context.colors.neutralText;
}

class _CashAccountCard extends StatelessWidget {
  const _CashAccountCard({
    required this.holding,
    required this.onChanged,
    required this.onToggleHidden,
  });

  final HoldingItem holding;
  final VoidCallback onChanged;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final sourceAmount = MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      holding.quantity,
      sourceCurrency: holding.currencyCode,
      exchangeRate: holding.exchangeRate,
    );

    final rowChild = AssetRow(
      minHeight: 80,
      leading: const SizedBox.shrink(),
      showLeading: false,
      title: holding.name,
      subtitle: holding.currencyCode,
      amountText: sourceAmount,
      deltaChip: null,
      isHidden: holding.isHidden,
      showChevron: false,
      onTap: () async {
        if (holding.id == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CashAccountDetailPage(
              holdingId: holding.id!,
              holdingClientId: holding.clientId,
            ),
          ),
        );
        onChanged();
      },
    );

    return Slidable(
      key: ValueKey('cash-account-${holding.id ?? holding.name}'),
      groupTag: _AssetDetailPageState._kSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onToggleHidden,
        icon: holding.isHidden
            ? VisualSpec.icon.visibilityOn
            : VisualSpec.icon.visibilityOff,
        iconColor: _iconTone(context),
      ),
      child: Opacity(
        opacity: holding.isHidden ? 0.6 : 1,
        child: holding.isHidden
            ? ClipRRect(
                borderRadius: BorderRadius.circular(context.radius.rMd),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 3.6, sigmaY: 3.6),
                  child: rowChild,
                ),
              )
            : rowChild,
      ),
    );
  }
}
