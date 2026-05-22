import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/chips/delta_chip.dart';
import '../components/transaction_history_list.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../models/market_snapshot.dart';
import '../services/company_news_summary_service.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';
import '../theme/moneyfy_theme.dart';
import '../utils/display_currency.dart';
import '../widgets/company_news_summary_card.dart';
import '../widgets/moneyfy_ui.dart';
import 'forms/cash_account_form_page.dart';
import 'forms/holding_form_page.dart';
import 'forms/transaction_form_page.dart';

class HoldingDetailPage extends StatefulWidget {
  const HoldingDetailPage({
    super.key,
    required this.holdingId,
    this.holdingClientId,
  });

  final int holdingId;
  final String? holdingClientId;

  @override
  State<HoldingDetailPage> createState() => _HoldingDetailPageState();
}

class _HoldingDetailPageState extends State<HoldingDetailPage> {
  static const String _kSlidableGroupTag = 'holding_detail_slidable_group';
  Future<CompanyNewsSummaryItem?>? _companyNewsFuture;
  String? _companyNewsSymbol;
  bool _isHeroDetailExpanded = false;
  late Future<HoldingItem?> _holdingFuture;
  Future<HoldingMarketSnapshot>? _marketSnapshotFuture;
  String? _marketSnapshotCacheKey;
  Future<_HoldingComparisonMetrics>? _comparisonMetricsFuture;
  String? _comparisonMetricsCacheKey;
  int _missingHoldingRetryCount = 0;
  static const int _kMaxMissingHoldingRetries = 3;

  @override
  void initState() {
    super.initState();
    _holdingFuture = _loadHoldingWithRetry();
  }

  Future<HoldingItem?> _loadHoldingWithRetry() async {
    final normalizedClientId = widget.holdingClientId?.trim() ?? '';
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final holding = await AppDatabase.instance.fetchHoldingById(
          widget.holdingId,
        );
        if (holding != null) return holding;
        if (normalizedClientId.isNotEmpty) {
          final byClientId = await AppDatabase.instance.fetchHoldingByClientId(
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

  void _reloadHolding({bool resetMissingRetry = true}) {
    if (!mounted) return;
    setState(() {
      if (resetMissingRetry) {
        _missingHoldingRetryCount = 0;
      }
      _holdingFuture = _loadHoldingWithRetry();
      _marketSnapshotFuture = null;
      _marketSnapshotCacheKey = null;
      _comparisonMetricsFuture = null;
      _comparisonMetricsCacheKey = null;
    });
  }

  void _scheduleMissingHoldingRetry() {
    if (!mounted) return;
    _missingHoldingRetryCount += 1;
    final delayMs = 180 * _missingHoldingRetryCount;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _reloadHolding(resetMissingRetry: false);
    });
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    _reloadHolding();
  }

  Future<CompanyNewsSummaryItem?> _companyNewsForSymbol(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    if (_companyNewsFuture == null || _companyNewsSymbol != normalized) {
      _companyNewsSymbol = normalized;
      _companyNewsFuture = CompanyNewsSummaryService.instance
          .fetchSummaryForSymbol(normalized);
    }
    return _companyNewsFuture!;
  }

  Future<HoldingMarketSnapshot> _marketSnapshotFor(HoldingItem holding) {
    final cacheKey =
        '${holding.id}|${holding.symbol}|${holding.exchangeCode}|${holding.currencyCode}|${holding.assetType ?? holding.assetTitle}';
    if (_marketSnapshotFuture == null || _marketSnapshotCacheKey != cacheKey) {
      _marketSnapshotCacheKey = cacheKey;
      _marketSnapshotFuture = MarketDataService.instance.fetchSnapshot(
        holding,
        includeFundComponents: false,
      );
    }
    return _marketSnapshotFuture!;
  }

  Future<_HoldingComparisonMetrics> _comparisonMetricsFor(HoldingItem holding) {
    final cacheKey =
        '${holding.id}|${holding.valuationAmount}|${holding.purchaseAmount}|${holding.quantity}|${holding.currentPrice}';
    if (_comparisonMetricsFuture == null ||
        _comparisonMetricsCacheKey != cacheKey) {
      _comparisonMetricsCacheKey = cacheKey;
      _comparisonMetricsFuture = _loadHoldingComparisonMetrics(holding);
    }
    return _comparisonMetricsFuture!;
  }

  Future<void> _editHolding(HoldingItem holding) async {
    final assetId = holding.assetId;
    if (assetId == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _isCashLikeHolding(holding)
            ? CashAccountFormPage(assetId: assetId, item: holding)
            : HoldingFormPage(assetId: assetId, item: holding),
      ),
    );

    if (changed == true && mounted) {
      _reloadHolding();
    }
  }

  Future<void> _deleteHolding(HoldingItem holding) async {
    if (holding.id == null) return;
    final confirmed = await _confirmDelete(
      title: '보유 종목 삭제',
      message: '${holding.name} 종목을 삭제하시겠습니까?',
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteHoldingItem(holding.id!);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'delete_holding');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openTransactionForm(
    HoldingItem holding, {
    TransactionItem? item,
  }) async {
    final assetId = holding.assetId;
    final holdingId = holding.id;
    if (assetId == null || holdingId == null) return;
    if (item != null &&
        item.isLedgerBacked &&
        !item.canOpenInvestmentFormFromLedger) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이 원장 라인은 직접 수정할 수 없습니다.')));
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          assetId: assetId,
          holdingId: holdingId,
          item: item,
          defaultName: holding.name,
        ),
      ),
    );

    if (changed == true && mounted) {
      _reloadHolding();
    }
  }

  Future<void> _deleteTransaction(TransactionItem item) async {
    if (item.id == null && item.ledgerEventId == null) return;
    final confirmed = await _confirmDelete(
      title: '거래 내역 삭제',
      message: '${item.date} ${item.type} 내역을 삭제하시겠습니까?',
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteLedgerTransactionItem(item);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'delete_transaction');
    }
    if (!mounted) return;
    _reloadHolding();
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<HoldingItem?>(
        future: _holdingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (_missingHoldingRetryCount < _kMaxMissingHoldingRetries) {
              _scheduleMissingHoldingRetry();
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('보유 정보를 불러오지 못했습니다.'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _reloadHolding(resetMissingRetry: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final holding = snapshot.data;
          if (holding == null) {
            if (_missingHoldingRetryCount < _kMaxMissingHoldingRetries) {
              _scheduleMissingHoldingRetry();
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('보유 정보를 찾을 수 없습니다.'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _reloadHolding(resetMissingRetry: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<HoldingMarketSnapshot>(
            future: _marketSnapshotFor(holding),
            initialData: HoldingMarketSnapshot.fallback(holding),
            builder: (context, marketSnapshot) {
              final market =
                  marketSnapshot.data ??
                  HoldingMarketSnapshot.fallback(holding);
              final displayHolding = _holdingWithMarketPrice(holding, market);
              final detailSections = _buildHoldingDetailSections(
                assetType:
                    displayHolding.assetType ?? displayHolding.assetTitle,
                holding: displayHolding,
                market: market,
              );

              return SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refreshPage,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _TopActionButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icons.arrow_back_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                                      color: MoneyfyPalette.surfaceMuted,
                                      borderRadius: BorderRadius.circular(
                                        VisualSpec.surface.radiusCard,
                                      ),
                                    ),
                                    child: Icon(
                                      _holdingIconForType(
                                        displayHolding.assetType,
                                      ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      size: VisualSpec.icon.sizeSmall,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      displayHolding.name,
                                      style: context.typography.body.copyWith(
                                        fontSize: context.fontSizes.s20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _TopActionButton(
                                    onPressed: () =>
                                        _editHolding(displayHolding),
                                    icon: Icons.edit_outlined,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 10),
                                  _TopActionButton(
                                    onPressed: () =>
                                        _deleteHolding(displayHolding),
                                    icon: Icons.delete_outline_rounded,
                                  ),
                                ],
                              ),
                              SizedBox(height: context.spacing.lg),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  displayHolding.value,
                                  style: context.typography.heroNumber.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(height: context.spacing.md),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragEnd: (details) {
                                  final velocity = details.primaryVelocity ?? 0;
                                  if (velocity > 120 &&
                                      !_isHeroDetailExpanded) {
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
                                child: FutureBuilder<_HoldingComparisonMetrics>(
                                  future: _comparisonMetricsFor(displayHolding),
                                  initialData:
                                      _HoldingComparisonMetrics.fromHolding(
                                        displayHolding,
                                      ),
                                  builder: (context, comparisonSnapshot) {
                                    final metrics =
                                        comparisonSnapshot.data ??
                                        _HoldingComparisonMetrics.fromHolding(
                                          displayHolding,
                                        );
                                    return AnimatedSize(
                                      duration: context.motion.fast,
                                      curve: Curves.easeOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(
                                          context.cardPadding(),
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.surfaces.surfaceBase,
                                          borderRadius: BorderRadius.circular(
                                            VisualSpec.surface.radiusCard,
                                          ),
                                          boxShadow: context.shadows.level2,
                                        ),
                                        child: Column(
                                          children: [
                                            _HoldingHeroDeltaMetricRow(
                                              label: '평가 손익',
                                              value: _formatSignedCurrency(
                                                metrics.valuationProfit,
                                              ),
                                              rawValue: metrics.valuationProfit,
                                              percentValue:
                                                  metrics.valuationProfitRate,
                                              showDeltaChip: true,
                                            ),
                                            AnimatedSwitcher(
                                              duration: context.motion.fast,
                                              switchInCurve:
                                                  Curves.easeOutCubic,
                                              switchOutCurve:
                                                  Curves.easeInCubic,
                                              transitionBuilder:
                                                  (child, animation) {
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
                                                        'holding-hero-expanded',
                                                      ),
                                                      children: [
                                                        SizedBox(
                                                          height: context
                                                              .spacing
                                                              .md,
                                                        ),
                                                        _HoldingHeroDeltaMetricRow(
                                                          label: '전월 대비 수익',
                                                          value:
                                                              metrics
                                                                  .hasMonthlyComparison
                                                              ? _formatSignedCurrency(
                                                                  metrics
                                                                      .monthlyProfit,
                                                                )
                                                              : '-',
                                                          rawValue: metrics
                                                              .monthlyProfit,
                                                          percentValue: metrics
                                                              .monthlyProfitRate,
                                                          showDeltaChip: metrics
                                                              .hasMonthlyComparison,
                                                        ),
                                                        SizedBox(
                                                          height: context
                                                              .spacing
                                                              .md,
                                                        ),
                                                        _HoldingHeroDeltaMetricRow(
                                                          label: '전일 대비 수익',
                                                          value:
                                                              metrics
                                                                  .hasDailyComparison
                                                              ? _formatSignedCurrency(
                                                                  metrics
                                                                      .dailyProfit,
                                                                )
                                                              : '-',
                                                          rawValue: metrics
                                                              .dailyProfit,
                                                          percentValue: metrics
                                                              .dailyProfitRate,
                                                          showDeltaChip: metrics
                                                              .hasDailyComparison,
                                                        ),
                                                      ],
                                                    )
                                                  : const SizedBox(
                                                      key: ValueKey(
                                                        'holding-hero-collapsed',
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (displayHolding.symbol.trim().isNotEmpty &&
                            displayHolding.quantity > 0) ...[
                          const SizedBox(height: 20),
                          FutureBuilder<CompanyNewsSummaryItem?>(
                            future: _companyNewsForSymbol(
                              displayHolding.symbol,
                            ),
                            builder: (context, companyNewsSnapshot) {
                              if (companyNewsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }

                              final item = companyNewsSnapshot.data;
                              if (item == null) {
                                return const SizedBox.shrink();
                              }

                              return CompanyNewsSummaryCard(
                                title: '종목 뉴스',
                                emptyMessage: '표시할 종목 뉴스가 없습니다.',
                                items: [item],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        for (
                          var index = 0;
                          index < detailSections.length;
                          index++
                        ) ...[
                          _CardSection(
                            title: detailSections[index].title,
                            child: detailSections[index].title == '구성 종목'
                                ? _FundComponentsList(
                                    items: market.etfTopComponents,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (detailSections[index].header !=
                                          null) ...[
                                        detailSections[index].header!,
                                        if (detailSections[index]
                                            .items
                                            .isNotEmpty)
                                          const SizedBox(height: 14),
                                      ],
                                      if (detailSections[index]
                                          .items
                                          .isNotEmpty)
                                        _MetricGrid(
                                          items: detailSections[index].items,
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _CardSection(
                          title: '거래 내역',
                          trailing: IconButton(
                            onPressed: () =>
                                _openTransactionForm(displayHolding),
                            icon: const Icon(Icons.add_rounded),
                            color: MoneyfyPalette.tertiaryText,
                          ),
                          child: SlidableAutoCloseBehavior(
                            child: TransactionHistoryList(
                              itemCount: displayHolding.transactions.length,
                              itemBuilder: (context, index) => _TransactionRow(
                                holding: displayHolding,
                                transaction: displayHolding.transactions[index],
                                onEdit: () => _openTransactionForm(
                                  displayHolding,
                                  item: displayHolding.transactions[index],
                                ),
                                onDelete: () => _deleteTransaction(
                                  displayHolding.transactions[index],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CardSection(
                          title: '메모',
                          trailing: IconButton(
                            onPressed: () => _editHolding(displayHolding),
                            icon: Icon(
                              Icons.edit_outlined,
                              size: VisualSpec.icon.sizeSmall,
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          child: Text(
                            displayHolding.note,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

HoldingItem _holdingWithMarketPrice(
  HoldingItem holding,
  HoldingMarketSnapshot market,
) {
  final currentPrice = market.currentPriceValue;
  if (currentPrice == null || currentPrice <= 0) return holding;
  if (currentPrice == holding.currentPrice) return holding;

  return HoldingItem(
    id: holding.id,
    clientId: holding.clientId,
    assetId: holding.assetId,
    assetTitle: holding.assetTitle,
    assetType: holding.assetType,
    isHidden: holding.isHidden,
    currencyCode: holding.currencyCode,
    exchangeRate: holding.exchangeRate,
    marketUpdatedAt: holding.marketUpdatedAt,
    exchangeCode: holding.exchangeCode,
    name: holding.name,
    symbol: holding.symbol,
    quantity: holding.quantity,
    averagePrice: holding.averagePrice,
    currentPrice: currentPrice,
    note: holding.note,
    transactions: holding.transactions,
  );
}

bool _isCashLikeHolding(HoldingItem holding) {
  return holding.isCashLike;
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

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
                  const SizedBox(width: 10),
                  Container(width: 1, height: 24, color: dividerColor),
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 14),
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
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

IconData _holdingIconForType(String? assetType) {
  switch (assetType) {
    case '주식':
      return Icons.show_chart_rounded;
    case '펀드':
      return Icons.pie_chart_rounded;
    case '코인':
      return Icons.currency_bitcoin_rounded;
    case '현금':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.account_balance_rounded;
  }
}

class _HoldingHeroDeltaMetricRow extends StatelessWidget {
  const _HoldingHeroDeltaMetricRow({
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.typography.caption.copyWith(
              fontSize: context.fontSizes.s16,
              fontWeight: FontWeight.w600,
              color: MoneyfyPalette.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: context.typography.caption.copyWith(
            fontSize: context.fontSizes.s16,
            fontWeight: FontWeight.w700,
            color: moneyfyValueColor(
              value,
              defaultColor: MoneyfyPalette.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (showDeltaChip)
          DeltaChip(
            value: rawValue,
            percent: percentValue,
            mode: DeltaChipMode.percent,
            vivid: true,
          )
        else
          const _HoldingHeroDashChip(),
      ],
    );
  }
}

class _HoldingHeroDashChip extends StatelessWidget {
  const _HoldingHeroDashChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surface,
        border: Border.all(color: MoneyfyPalette.border),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Text(
        '-',
        style: context.typography.meta.copyWith(
          color: MoneyfyPalette.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HoldingComparisonMetrics {
  const _HoldingComparisonMetrics({
    required this.valuationProfit,
    required this.valuationProfitRate,
    required this.monthlyProfit,
    required this.monthlyProfitRate,
    required this.dailyProfit,
    required this.dailyProfitRate,
    required this.hasMonthlyComparison,
    required this.hasDailyComparison,
  });

  factory _HoldingComparisonMetrics.fromHolding(HoldingItem holding) {
    return _HoldingComparisonMetrics(
      valuationProfit: holding.profitAmount,
      valuationProfitRate: holding.profitRate,
      monthlyProfit: 0,
      monthlyProfitRate: 0,
      dailyProfit: 0,
      dailyProfitRate: 0,
      hasMonthlyComparison: false,
      hasDailyComparison: false,
    );
  }

  final double valuationProfit;
  final double valuationProfitRate;
  final double monthlyProfit;
  final double monthlyProfitRate;
  final double dailyProfit;
  final double dailyProfitRate;
  final bool hasMonthlyComparison;
  final bool hasDailyComparison;
}

Future<_HoldingComparisonMetrics> _loadHoldingComparisonMetrics(
  HoldingItem holding,
) async {
  final currentValue = holding.valuationAmount;
  final valuationProfit = holding.profitAmount;
  final valuationProfitRate = holding.profitRate;

  final monthlyPrevious = await _resolveHoldingComparisonValue(
    holding: holding,
    dateCandidates: [_previousMonthComparisonDate(DateTime.now())],
    includeRecentFallback: true,
  );
  final dailyPrevious = await _resolveHoldingComparisonValue(
    holding: holding,
    dateCandidates: [
      _snapshotDate(DateTime.now().subtract(const Duration(days: 1))),
      _snapshotDate(DateTime.now().subtract(const Duration(days: 2))),
    ],
    includeRecentFallback: true,
  );

  final hasMonthly = monthlyPrevious != null;
  final hasDaily = dailyPrevious != null;
  final monthlyProfit = hasMonthly ? currentValue - monthlyPrevious : 0.0;
  final monthlyRate = !hasMonthly || monthlyPrevious == 0
      ? 0.0
      : (monthlyProfit / monthlyPrevious) * 100;
  final dailyProfit = hasDaily ? currentValue - dailyPrevious : 0.0;
  final dailyRate = !hasDaily || dailyPrevious == 0
      ? 0.0
      : (dailyProfit / dailyPrevious) * 100;

  return _HoldingComparisonMetrics(
    valuationProfit: valuationProfit,
    valuationProfitRate: valuationProfitRate,
    monthlyProfit: monthlyProfit,
    monthlyProfitRate: monthlyRate,
    dailyProfit: dailyProfit,
    dailyProfitRate: dailyRate,
    hasMonthlyComparison: hasMonthly,
    hasDailyComparison: hasDaily,
  );
}

Future<double?> _resolveHoldingComparisonValue({
  required HoldingItem holding,
  required List<String> dateCandidates,
  required bool includeRecentFallback,
}) async {
  for (final snapshotDate in dateCandidates) {
    final rows = await AppDatabase.instance
        .fetchPortfolioSnapshotHoldingItemsByDates([snapshotDate]);
    final value = _findHoldingSnapshotValue(rows: rows, holding: holding);
    if (value != null) {
      return value;
    }
  }

  if (!includeRecentFallback) return null;
  final snapshots = await AppDatabase.instance.fetchRecentPortfolioSnapshots(
    maxDates: 12,
  );
  if (snapshots.isEmpty) return null;

  final todaySnapshotDate = _snapshotDate(DateTime.now());
  final blockedDates = <String>{...dateCandidates, todaySnapshotDate};

  for (final snapshot in snapshots.reversed) {
    final fallbackDate = snapshot.snapshotDate;
    if (blockedDates.contains(fallbackDate)) continue;
    final fallbackRows = await AppDatabase.instance
        .fetchPortfolioSnapshotHoldingItemsByDates([fallbackDate]);
    final value = _findHoldingSnapshotValue(
      rows: fallbackRows,
      holding: holding,
    );
    if (value != null) {
      return value;
    }
  }
  return null;
}

double? _findHoldingSnapshotValue({
  required List<DailyPortfolioSnapshotHoldingItem> rows,
  required HoldingItem holding,
}) {
  final holdingId = holding.id;
  if (holdingId != null) {
    for (final row in rows) {
      if (row.holdingId == holdingId) {
        return row.totalValuationAmount;
      }
    }
  }

  final targetAssetId = holding.assetId;
  final targetAssetTitle = (holding.assetTitle ?? '').trim().toLowerCase();
  final targetCurrency = holding.currencyCode.trim().toLowerCase();
  final targetName = holding.name.trim().toLowerCase();
  final targetSymbol = holding.symbol.trim().toLowerCase();

  bool rowMatchesNameAndSymbol(DailyPortfolioSnapshotHoldingItem row) {
    final rowName = row.holdingName.trim().toLowerCase();
    final rowSymbol = row.holdingSymbol.trim().toLowerCase();
    if (rowName != targetName) return false;
    if (targetSymbol.isNotEmpty && rowSymbol != targetSymbol) return false;
    return true;
  }

  bool rowMatchesCurrency(DailyPortfolioSnapshotHoldingItem row) {
    if (targetCurrency.isEmpty) return true;
    final rowCurrency = row.currencyCode.trim().toLowerCase();
    if (rowCurrency.isEmpty) return true;
    return rowCurrency == targetCurrency;
  }

  // Prefer matching inside the same asset first to avoid cross-asset symbol collisions.
  for (final row in rows) {
    if (targetAssetId != null && row.assetId != targetAssetId) {
      continue;
    }
    if (!rowMatchesCurrency(row)) continue;
    if (rowMatchesNameAndSymbol(row)) {
      return row.totalValuationAmount;
    }
  }

  // Legacy fallback: if snapshot row has no asset id, allow name/symbol/currency match.
  if (targetAssetId != null) {
    for (final row in rows) {
      if (row.assetId != null) continue;
      final rowAssetTitle = row.assetTitle.trim().toLowerCase();
      if (targetAssetTitle.isNotEmpty &&
          rowAssetTitle.isNotEmpty &&
          rowAssetTitle != targetAssetTitle) {
        continue;
      }
      if (!rowMatchesCurrency(row)) continue;
      if (rowMatchesNameAndSymbol(row)) {
        return row.totalValuationAmount;
      }
    }
  }

  // Fallback for migrated/synced data where assetId changed across snapshots.
  for (final row in rows) {
    final rowAssetTitle = row.assetTitle.trim().toLowerCase();
    if (targetAssetTitle.isNotEmpty &&
        rowAssetTitle.isNotEmpty &&
        rowAssetTitle != targetAssetTitle) {
      continue;
    }
    if (!rowMatchesCurrency(row)) continue;
    if (rowMatchesNameAndSymbol(row)) {
      return row.totalValuationAmount;
    }
  }

  // Last resort: title also changed, keep name/symbol/currency only.
  for (final row in rows) {
    if (!rowMatchesCurrency(row)) continue;
    if (rowMatchesNameAndSymbol(row)) {
      return row.totalValuationAmount;
    }
  }
  return null;
}

class _MetricTileData {
  const _MetricTileData({required this.label, required this.value});

  final String label;
  final String value;
}

class _HoldingDetailSection {
  const _HoldingDetailSection({
    required this.title,
    required this.items,
    this.header,
  });

  final String title;
  final List<_MetricTileData> items;
  final Widget? header;
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        splashRadius: 20,
        icon: Icon(icon),
      ),
    );
  }
}

List<_HoldingDetailSection> _buildHoldingDetailSections({
  required String? assetType,
  required HoldingItem holding,
  required HoldingMarketSnapshot market,
}) {
  final portfolioSection = _HoldingDetailSection(
    title: '보유 정보',
    items: [
      _MetricTileData(
        label: holding.primaryMetricLabel,
        value: holding.primaryMetricValue,
      ),
      _MetricTileData(
        label: holding.secondaryMetricLabel,
        value: holding.secondaryMetricValue,
      ),
      _MetricTileData(
        label: holding.quantityMetricLabel,
        value: holding.quantityMetricValue,
      ),
      _MetricTileData(
        label: holding.purchaseMetricLabel,
        value: holding.purchaseMetricValue,
      ),
      _MetricTileData(
        label: '수익',
        value: _formatSignedCurrency(holding.profitAmount),
      ),
      _MetricTileData(label: '수익률', value: holding.change),
    ],
  );

  switch (assetType) {
    case '주식':
      return [
        portfolioSection,
        _HoldingDetailSection(
          title: '52주 범위',
          header: _WeekRangeBar(
            lowLabel: market.week52Low,
            highLabel: market.week52High,
            currentLabel: market.currentPrice,
          ),
          items: const [],
        ),
        _HoldingDetailSection(
          title: '시장 정보',
          items: [
            _MetricTileData(label: '현재가', value: market.currentPrice),
            _MetricTileData(label: '전일종가', value: market.previousClose),
            _MetricTileData(label: '등락액', value: market.dayChange),
            _MetricTileData(label: '등락률', value: market.dayChangeRate),
            _MetricTileData(label: '시가', value: market.openPrice),
            _MetricTileData(label: '고가', value: market.highPrice),
            _MetricTileData(label: '저가', value: market.lowPrice),
            _MetricTileData(label: '거래량', value: market.volume),
            _MetricTileData(label: '거래대금', value: market.turnover),
            _MetricTileData(label: '시장', value: market.marketName),
          ],
        ),
        _HoldingDetailSection(
          title: '밸류에이션',
          items: [
            _MetricTileData(label: 'PER', value: market.per),
            _MetricTileData(label: 'PBR', value: market.pbr),
            _MetricTileData(label: 'EPS', value: market.eps),
            _MetricTileData(label: 'BPS', value: market.bps),
          ],
        ),
      ];
    case '코인':
      return [
        _HoldingDetailSection(
          title: '보유 정보',
          items: [
            _MetricTileData(label: '현재가', value: holding.primaryMetricValue),
            _MetricTileData(label: '평단', value: holding.secondaryMetricValue),
            _MetricTileData(label: '수량', value: holding.quantityMetricValue),
            _MetricTileData(label: '매수금액', value: holding.purchaseMetricValue),
            _MetricTileData(
              label: '수익',
              value: _formatSignedCurrency(holding.profitAmount),
            ),
            _MetricTileData(label: '수익률', value: holding.change),
          ],
        ),
        _HoldingDetailSection(
          title: '시장 정보',
          items: [
            _MetricTileData(label: '현재가', value: market.currentPrice),
            _MetricTileData(label: '시가', value: market.openPrice),
            _MetricTileData(label: '고가', value: market.highPrice),
            _MetricTileData(label: '저가', value: market.lowPrice),
          ],
        ),
        _HoldingDetailSection(
          title: '거래 / 호가',
          items: [
            _MetricTileData(label: '24h 거래대금', value: market.quoteVolume24h),
            _MetricTileData(label: '24h 거래량', value: market.targetVolume24h),
            _MetricTileData(label: '매도 최저가', value: market.bestAskPrice),
            _MetricTileData(label: '매수 최고가', value: market.bestBidPrice),
            _MetricTileData(label: '매도 수량', value: market.bestAskQty),
            _MetricTileData(label: '매수 수량', value: market.bestBidQty),
            _MetricTileData(
              label: '거래쌍',
              value: '${market.targetCurrency}/${market.quoteCurrency}',
            ),
          ],
        ),
      ];
    case '펀드':
      return [
        _HoldingDetailSection(
          title: '보유 정보',
          items: [
            _MetricTileData(label: '현재가', value: market.currentPrice),
            _MetricTileData(
              label: '기준 단가',
              value: holding.secondaryMetricValue,
            ),
            _MetricTileData(label: '보유 수량', value: holding.quantityMetricValue),
            _MetricTileData(label: '매수금액', value: holding.purchaseMetricValue),
            _MetricTileData(
              label: '수익',
              value: _formatSignedCurrency(holding.profitAmount),
            ),
            _MetricTileData(label: '수익률', value: holding.change),
          ],
        ),
        _HoldingDetailSection(
          title: '52주 범위',
          header: _WeekRangeBar(
            lowLabel: market.week52Low,
            highLabel: market.week52High,
            currentLabel: market.currentPrice,
          ),
          items: const [],
        ),
        _HoldingDetailSection(
          title: '시장 정보',
          items: [
            _MetricTileData(label: '현재가', value: market.currentPrice),
            _MetricTileData(label: '전일종가', value: market.previousClose),
            _MetricTileData(label: '등락액', value: market.dayChange),
            _MetricTileData(label: '등락률', value: market.dayChangeRate),
            _MetricTileData(label: '시가', value: market.openPrice),
            _MetricTileData(label: '고가', value: market.highPrice),
            _MetricTileData(label: '저가', value: market.lowPrice),
            _MetricTileData(label: '거래량', value: market.volume),
            _MetricTileData(label: 'NAV', value: market.nav),
            _MetricTileData(label: 'NAV 등락률', value: market.navChangeRate),
            _MetricTileData(label: 'NAV 시가', value: market.etfNavOpen),
            _MetricTileData(label: 'NAV 고가', value: market.etfNavHigh),
            _MetricTileData(label: 'NAV 저가', value: market.etfNavLow),
          ],
        ),
        _HoldingDetailSection(
          title: '밸류에이션',
          items: [
            _MetricTileData(label: '괴리율', value: market.disparityRate),
            _MetricTileData(label: '추적 오차율', value: market.trackingError),
            _MetricTileData(label: '외국인 보유율', value: market.foreignHoldRate),
            _MetricTileData(label: '배당 주기', value: market.dividendCycle),
            _MetricTileData(label: '분류', value: market.etfCategory),
            _MetricTileData(label: '상장일', value: market.listingDate),
          ],
        ),
        _HoldingDetailSection(
          title: 'ETF / 펀드 정보',
          items: [
            _MetricTileData(label: '순자산총액', value: market.netAssets),
            _MetricTileData(
              label: 'ETF 순자산총액',
              value: market.etfNetAssetsTotal,
            ),
            _MetricTileData(label: '구성 종목 수', value: market.etfComponentCount),
            _MetricTileData(
              label: '구성종목 시가총액',
              value: market.etfComponentMarketCap,
            ),
            _MetricTileData(label: 'CU 단위 증권 수', value: market.etfCuUnitCount),
          ],
        ),
        if (market.etfTopComponents.isNotEmpty)
          const _HoldingDetailSection(title: '구성 종목', items: []),
      ];
    case '현금':
      return [
        _HoldingDetailSection(
          title: '잔고 정보',
          items: [
            _MetricTileData(label: '평가금액', value: holding.value),
            _MetricTileData(label: '잔액', value: holding.quantityMetricValue),
            _MetricTileData(
              label: '거래 건수',
              value: '${holding.transactions.length}건',
            ),
            _MetricTileData(label: '기준 통화', value: holding.currencyCode),
          ],
        ),
      ];
    default:
      return [portfolioSection];
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricTileData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: index == items.length - 1 && items.length.isOdd
                    ? constraints.maxWidth
                    : tileWidth,
                child: _MetricTile(
                  label: items[index].label,
                  value: items[index].value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WeekRangeBar extends StatelessWidget {
  const _WeekRangeBar({
    required this.lowLabel,
    required this.highLabel,
    required this.currentLabel,
  });

  final String lowLabel;
  final String highLabel;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = _parseDisplayNumber(lowLabel);
    final high = _parseDisplayNumber(highLabel);
    final current = _parseDisplayNumber(currentLabel);
    final hasRange =
        low != null && high != null && current != null && high > low;
    final position = hasRange
        ? ((current - low) / (high - low)).clamp(0.0, 1.0)
        : 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final markerWidth = 84.0;
              final markerLeft =
                  (constraints.maxWidth - markerWidth) * position;
              return SizedBox(
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 36,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: MoneyfyPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: MoneyfyPalette.secondaryText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: MoneyfyPalette.secondaryText,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: markerLeft,
                      top: 4,
                      child: SizedBox(
                        width: markerWidth,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MoneyfyPalette.ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                currentLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: MoneyfyPalette.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 30,
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: MoneyfyPalette.ink,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                highLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FundComponentsList extends StatelessWidget {
  const _FundComponentsList({required this.items});

  final List<FundComponentItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _FundComponentRow(item: items[index]),
          if (index != items.length - 1) const Divider(height: 20),
        ],
      ],
    );
  }
}

class _FundComponentRow extends StatelessWidget {
  const _FundComponentRow({required this.item});

  final FundComponentItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                item.code,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.weight,
              style: theme.textTheme.titleMedium?.copyWith(
                color: MoneyfyPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.changeRate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: moneyfyValueColor(item.changeRate),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.valuationAmount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MoneyfyPalette.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: moneyfyValueColor(value),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.holding,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final HoldingItem holding;
  final TransactionItem transaction;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeStyle = _holdingTransactionTypeStyle(transaction.type);
    final amountValue =
        double.tryParse(transaction.amount.replaceAll(',', '').trim()) ?? 0;
    final formattedAmount =
        MoneyfyDisplayCurrencySettings.formatAmountFromSource(
          amountValue,
          sourceCurrency: holding.currencyCode,
          exchangeRate: holding.exchangeRate,
        );

    return Slidable(
      key: ValueKey('holding-tx-${transaction.id ?? transaction.hashCode}'),
      groupTag: _HoldingDetailPageState._kSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: () => onDelete(),
        icon: Icons.delete_outline_rounded,
        iconColor: MoneyfyPalette.negative,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          transaction.date,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: MoneyfyPalette.tertiaryText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: typeStyle.borderColor),
                          ),
                          child: Text(
                            transaction.type,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: typeStyle.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedAmount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: moneyfyValueColor(
                        _holdingAmountSign(transaction, formattedAmount),
                        defaultColor: MoneyfyPalette.ink,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _holdingLedgerLineMeta(transaction),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _holdingAmountSign(TransactionItem transaction, String formattedAmount) {
  return switch (transaction.ledgerAction ?? transaction.type.trim()) {
    'sell' ||
    'dividend' ||
    'interest' ||
    '매도' ||
    '배당' ||
    '이자' => '+$formattedAmount',
    'fee' || 'tax' || '수수료' || '세금' => '-$formattedAmount',
    _ => '-$formattedAmount',
  };
}

String _holdingLedgerLineMeta(TransactionItem transaction) {
  final quantity = transaction.quantity.trim();
  final action = transaction.ledgerAction;
  final actionText = switch (action) {
    'buy' => '매수 라인',
    'sell' => '매도 라인',
    'dividend' => '배당 수입 라인',
    'interest' => '이자 수입 라인',
    'fee' => '비용 라인',
    'tax' => '세금 라인',
    'opening_quantity' => '초기 수량 라인',
    'adjustment' => '조정 라인',
    _ => '',
  };
  if (quantity.isEmpty) return actionText;
  if (actionText.isEmpty) return quantity;
  return '$quantity · $actionText';
}

class _HoldingTransactionTypeStyle {
  const _HoldingTransactionTypeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}

_HoldingTransactionTypeStyle _holdingTransactionTypeStyle(String type) {
  switch (type.trim()) {
    case '매수':
      return const _HoldingTransactionTypeStyle(
        backgroundColor: Color(0xFFFDECEC),
        borderColor: Color(0xFFF3C4C4),
        textColor: Color(0xFFC83C3C),
      );
    case '매도':
      return const _HoldingTransactionTypeStyle(
        backgroundColor: Color(0xFFE8F7EF),
        borderColor: Color(0xFFB7E4C7),
        textColor: Color(0xFF1E8E5A),
      );
    case '배당':
    case '이자':
      return const _HoldingTransactionTypeStyle(
        backgroundColor: Color(0xFFFFF3E0),
        borderColor: Color(0xFFFFD08A),
        textColor: Color(0xFFB56A00),
      );
    default:
      return const _HoldingTransactionTypeStyle(
        backgroundColor: Color(0xFFF3F4F6),
        borderColor: Color(0xFFE5E7EB),
        textColor: MoneyfyPalette.secondaryText,
      );
  }
}

double? _parseDisplayNumber(String text) {
  final normalized = text.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
