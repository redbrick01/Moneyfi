import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../services/company_news_summary_service.dart';
import '../theme/moneyfy_theme.dart';
import '../utils/display_currency.dart';
import '../widgets/company_news_summary_card.dart';
import '../widgets/market_news_summary_card.dart';
import '../widgets/moneyfy_ui.dart';
import 'annual_asset_analysis_page.dart';
import 'dividend_interest_analysis_page.dart';
import 'investment_performance_page.dart';
import 'snapshot_detail_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    this.scrollController,
    this.reselectionTick = 0,
    this.dataRefreshTick = 0,
  });

  final ScrollController? scrollController;
  final int reselectionTick;
  final int dataRefreshTick;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late Future<_AnalysisSnapshotBundle> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadAnalysisSnapshotBundle();
  }

  @override
  void didUpdateWidget(covariant AnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      setState(() {
        _pageFuture = _loadAnalysisSnapshotBundle();
      });
    }
  }

  Future<void> _refreshPage() async {
    final refreshed = await Future.wait<Object?>([
      fetchMarketNewsSummary(forceRefresh: true),
      CompanyNewsSummaryService.instance.fetchUserSummaries(forceRefresh: true),
    ]);
    final refreshedMarketNews = refreshed[0] as MarketNewsSummary?;
    final refreshedCompanyNews = refreshed[1] as List<CompanyNewsSummaryItem>;
    if (!mounted) return;
    setState(() {
      _pageFuture = _loadAnalysisSnapshotBundle(
        prefetchedMarketNewsSummary: refreshedMarketNews,
        prefetchedCompanyNewsSummaries: refreshedCompanyNews,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AnalysisSnapshotBundle>(
      future: _pageFuture,
      builder: (context, snapshot) {
        final bundle = snapshot.data ?? const _AnalysisSnapshotBundle.empty();

        return MoneyfyPage(
          title: '분석',
          onRefresh: _refreshPage,
          scrollController: widget.scrollController,
          children: [
            MarketNewsSummaryCard(summary: bundle.marketNewsSummary),
            const SizedBox(height: MoneyfySpacing.sectionGap),
            _Level1WidthCard(
              child: CompanyNewsSummaryCard(items: bundle.companyNewsSummaries),
            ),
            const SizedBox(height: MoneyfySpacing.sectionGap),
            const _InvestmentPerformanceEntryCard(),
            const SizedBox(height: 12),
            const _DividendInterestEntryCard(),
          ],
        );
      },
    );
  }
}

class _Level1WidthCard extends StatelessWidget {
  const _Level1WidthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = context.cardWidths.apply(constraints.maxWidth, level: 1);
        return Align(
          alignment: Alignment.center,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

class _DividendInterestEntryCard extends StatelessWidget {
  const _DividendInterestEntryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const DividendInterestAnalysisPage(),
          ),
        );
      },
      child: MoneyfySurfaceCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MoneyfyPalette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.payments_rounded,
                color: MoneyfyPalette.accent,
                size: VisualSpec.icon.sizeDefault,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('배당/이자 분석', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '월별 추이 · 연 총합 · 종목별 수입',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _InvestmentPerformanceEntryCard extends StatelessWidget {
  const _InvestmentPerformanceEntryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const InvestmentPerformancePage(),
          ),
        );
      },
      child: MoneyfySurfaceCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MoneyfyPalette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.query_stats_rounded,
                color: MoneyfyPalette.accent,
                size: VisualSpec.icon.sizeDefault,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('투자성과 분석', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '실현손익 · 배당/이자 · 입출금 제외 성과',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class SnapshotCalendarCard extends StatelessWidget {
  const SnapshotCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.snapshots,
    required this.items,
    required this.transactionDates,
    required this.onMonthChanged,
  });

  final DateTime focusedMonth;
  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> items;
  final Set<String> transactionDates;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final leadingEmpty = firstDay.weekday % 7;
    final totalCells = leadingEmpty + lastDay.day;
    final trailingEmpty = (7 - (totalCells % 7)) % 7;
    final snapshotByDate = {
      for (final snapshot in snapshots) snapshot.snapshotDate: snapshot,
    };
    final itemsBySnapshotId = <int, List<DailyPortfolioSnapshotItem>>{};
    for (final item in items) {
      itemsBySnapshotId.putIfAbsent(item.snapshotId, () => []).add(item);
    }

    return MoneyfySectionCard(
      title: '스냅샷 캘린더',
      subtitle: '${focusedMonth.year}년 ${focusedMonth.month}월',
      headerBottomSpacing: 18,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onMonthChanged(
              DateTime(focusedMonth.year, focusedMonth.month - 1),
            ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: () => onMonthChanged(
              DateTime(focusedMonth.year, focusedMonth.month + 1),
            ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 250) {
            onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1));
          } else if (velocity < -250) {
            onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: MoneyfyPalette.tertiaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells + trailingEmpty,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 6,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmpty || index >= totalCells) {
                  return const SizedBox.shrink();
                }

                final day = index - leadingEmpty + 1;
                final date = DateTime(
                  focusedMonth.year,
                  focusedMonth.month,
                  day,
                );
                final dateKey = _dateKey(date);
                final snapshot = snapshotByDate[dateKey];
                final hasSnapshot = snapshot != null;
                final hasTransaction = transactionDates.contains(dateKey);
                final isPivotDay = day == 20;
                final pivotColor = Color.lerp(
                  MoneyfyPalette.accent,
                  MoneyfyPalette.negative,
                  0.58,
                )!;
                final dayColor = isPivotDay
                    ? pivotColor
                    : hasSnapshot
                    ? MoneyfyPalette.accent
                    : MoneyfyPalette.secondaryText;
                final borderColor = isPivotDay
                    ? pivotColor.withValues(alpha: 0.34)
                    : hasSnapshot
                    ? MoneyfyPalette.accent
                    : MoneyfyPalette.border;
                final snapshotItems = snapshot == null
                    ? const <DailyPortfolioSnapshotItem>[]
                    : (itemsBySnapshotId[snapshot.id] ??
                          const <DailyPortfolioSnapshotItem>[]);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: !hasSnapshot
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SnapshotDetailPage(
                                snapshot: snapshot,
                                items: snapshotItems,
                              ),
                            ),
                          );
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: MoneyfyPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: dayColor,
                            fontWeight: hasSnapshot || isPivotDay
                                ? FontWeight.w600
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasTransaction
                                ? MoneyfyPalette.accent
                                : MoneyfyPalette.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class YearlyAssetAnalysisCard extends StatelessWidget {
  const YearlyAssetAnalysisCard({
    super.key,
    required this.snapshots,
    required this.annualItems,
  });

  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> annualItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final years =
        snapshots
            .map((snapshot) => DateTime.parse(snapshot.snapshotDate).year)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnualAssetAnalysisPage(
              snapshots: snapshots,
              items: annualItems,
            ),
          ),
        );
      },
      child: MoneyfySurfaceCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('연도별 자산분석', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    years.isEmpty
                        ? '데이터 없음'
                        : years.map((year) => '$year년').join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

Future<_AnalysisSnapshotBundle> _loadAnalysisSnapshotBundle({
  MarketNewsSummary? prefetchedMarketNewsSummary,
  List<CompanyNewsSummaryItem>? prefetchedCompanyNewsSummaries,
}) async {
  final allSnapshotsFuture = AppDatabase.instance.fetchRecentPortfolioSnapshots(
    maxDates: 240,
  );
  final transactionDatesFuture = AppDatabase.instance.fetchTransactionDates();
  final marketNewsSummaryFuture = prefetchedMarketNewsSummary != null
      ? Future<MarketNewsSummary?>.value(prefetchedMarketNewsSummary)
      : fetchMarketNewsSummary();
  final companyNewsSummariesFuture = prefetchedCompanyNewsSummaries != null
      ? Future<List<CompanyNewsSummaryItem>>.value(
          prefetchedCompanyNewsSummaries,
        )
      : CompanyNewsSummaryService.instance.fetchUserSummaries();
  final allSnapshots = await allSnapshotsFuture;
  final recentSnapshots = selectMonthlyClosingSnapshots(allSnapshots);
  final recentItemsFuture = fetchVisibleSnapshotSummaryItemsByDates(
    recentSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
  );
  final annualItemsFuture = fetchVisibleSnapshotSummaryItemsByDates(
    allSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
  );
  final allItemsFuture = AppDatabase.instance
      .fetchDisplayPortfolioSnapshotItemsByDates(
        allSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
      );
  final recentItems = await recentItemsFuture;
  final annualItems = await annualItemsFuture;
  final allItems = await allItemsFuture;
  final transactionDates = await transactionDatesFuture;
  final marketNewsSummary = await marketNewsSummaryFuture;
  final companyNewsSummaries = await companyNewsSummariesFuture;

  return _AnalysisSnapshotBundle(
    recentSnapshots: recentSnapshots,
    recentItems: recentItems,
    annualItems: annualItems,
    allSnapshots: allSnapshots,
    allItems: allItems,
    transactionDates: transactionDates,
    marketNewsSummary: marketNewsSummary,
    companyNewsSummaries: companyNewsSummaries,
  );
}

List<DailyPortfolioSnapshot> selectMonthlyClosingSnapshots(
  List<DailyPortfolioSnapshot> snapshots, {
  int maxItems = 6,
}) {
  if (snapshots.isEmpty) return const [];

  final sorted = [...snapshots]
    ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
  final latest = sorted.last;
  final selected = <DailyPortfolioSnapshot>[latest];

  for (final snapshot in sorted.reversed.skip(1)) {
    if (selected.length >= maxItems) break;
    final date = DateTime.parse(snapshot.snapshotDate);
    if (date.day != 20) continue;
    if (selected.any((item) => item.snapshotDate == snapshot.snapshotDate)) {
      continue;
    }
    selected.add(snapshot);
  }

  return selected.reversed.toList();
}

Future<List<DailyPortfolioSnapshotItem>>
fetchVisibleSnapshotSummaryItemsByDates(List<String> snapshotDates) async {
  if (snapshotDates.isEmpty) return const [];

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
      .map(_normalizeVisibleSnapshotAssetTitle)
      .where((value) => value.isNotEmpty)
      .toSet();

  bool isVisibleSnapshotAsset(int? assetId, String assetTitle) {
    if (assetId != null && visibleAssetIds.contains(assetId)) {
      return true;
    }
    return visibleAssetTitles.contains(
      _normalizeVisibleSnapshotAssetTitle(assetTitle),
    );
  }

  return (await AppDatabase.instance.fetchPortfolioSnapshotItemsByDates(
        snapshotDates,
      ))
      .where((item) => isVisibleSnapshotAsset(item.assetId, item.assetTitle))
      .toList(growable: false);
}

String _normalizeVisibleSnapshotAssetTitle(String value) {
  return value.trim().toLowerCase();
}

List<MonthlyClosingAsset> buildMonthlyClosingAssets(
  List<DailyPortfolioSnapshot> snapshots,
  List<DailyPortfolioSnapshotItem> snapshotItems,
) {
  var previousTotal = 0.0;
  final items = List.generate(snapshots.length, (index) {
    final snapshot = snapshots[index];
    final filteredItems = snapshotItems
        .where((item) => item.snapshotId == snapshot.id)
        .toList();

    // Use only locally resolvable, visible asset rows for the displayed total.
    final total = filteredItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValuationAmount,
    );
    final change = index == 0 ? 0.0 : total - previousTotal;
    final changeRate = index == 0 || previousTotal == 0
        ? 0.0
        : (change / previousTotal) * 100;
    previousTotal = total;
    final date = DateTime.parse(snapshot.snapshotDate);
    return MonthlyClosingAsset(
      month: '${date.month}월',
      date: '${date.month}월 ${date.day}일',
      totalAsset: _formatCurrency(total),
      change: _formatSignedCurrency(change),
      changeRate: _formatSignedPercent(changeRate),
      snapshot: snapshot,
      items: filteredItems,
    );
  });

  return items.reversed.toList();
}

class MonthlyClosingAssetsCard extends StatefulWidget {
  const MonthlyClosingAssetsCard({super.key, required this.items});

  final List<MonthlyClosingAsset> items;

  @override
  State<MonthlyClosingAssetsCard> createState() =>
      _MonthlyClosingAssetsCardState();
}

class _MonthlyClosingAssetsCardState extends State<MonthlyClosingAssetsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fixedItems = widget.items.take(3).toList(growable: false);
    final expandedItems = widget.items.skip(3).take(9).toList(growable: false);
    final canExpand = widget.items.length > 3;

    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 최종 자산', style: theme.textTheme.titleLarge),
          if (widget.items.isEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 140),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: MoneyfyPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MoneyfyPalette.border),
              ),
              child: Center(
                child: Text(
                  '표시할 스냅샷 데이터가 없습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            for (final item in fixedItems) ...[
              _MonthlyClosingAssetRow(item: item),
              if (item != fixedItems.last) ...[
                const SizedBox(height: 14),
                Divider(color: MoneyfyPalette.border, height: 1),
                const SizedBox(height: 14),
              ],
            ],
            if (canExpand) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: _expanded
                    ? Column(
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: MoneyfyPalette.border, height: 1),
                          const SizedBox(height: 14),
                          for (final item in expandedItems) ...[
                            _MonthlyClosingAssetRow(item: item),
                            if (item != expandedItems.last) ...[
                              const SizedBox(height: 14),
                              Divider(color: MoneyfyPalette.border, height: 1),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              Center(
                child: IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  splashRadius: 20,
                  tooltip: _expanded ? '접기' : '더보기',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MonthlyClosingAssetRow extends StatelessWidget {
  const _MonthlyClosingAssetRow({required this.item});

  final MonthlyClosingAsset item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                SnapshotDetailPage(snapshot: item.snapshot, items: item.items),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.date,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.totalAsset,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: MoneyfyPalette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.change,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: moneyfyValueColor(
                          item.change,
                          defaultColor: MoneyfyPalette.secondaryText,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MoneyfyPalette.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: MoneyfyPalette.border),
                      ),
                      child: Text(
                        item.changeRate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: moneyfyValueColor(
                            item.changeRate,
                            defaultColor: MoneyfyPalette.secondaryText,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, size: VisualSpec.icon.sizeSmall),
          ],
        ),
      ),
    );
  }
}

class MonthlyClosingAsset {
  const MonthlyClosingAsset({
    required this.month,
    required this.date,
    required this.totalAsset,
    required this.change,
    required this.changeRate,
    required this.snapshot,
    required this.items,
  });

  final String month;
  final String date;
  final String totalAsset;
  final String change;
  final String changeRate;
  final DailyPortfolioSnapshot snapshot;
  final List<DailyPortfolioSnapshotItem> items;

  double get changeRateValue {
    final normalized = changeRate
        .replaceAll('%', '')
        .replaceAll('+', '')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

String _formatSignedPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}%';
}

class _AnalysisSnapshotBundle {
  const _AnalysisSnapshotBundle({
    required this.recentSnapshots,
    required this.recentItems,
    required this.annualItems,
    required this.allSnapshots,
    required this.allItems,
    required this.transactionDates,
    required this.marketNewsSummary,
    required this.companyNewsSummaries,
  });

  const _AnalysisSnapshotBundle.empty()
    : recentSnapshots = const [],
      recentItems = const [],
      annualItems = const [],
      allSnapshots = const [],
      allItems = const [],
      transactionDates = const {},
      marketNewsSummary = null,
      companyNewsSummaries = const [];

  final List<DailyPortfolioSnapshot> recentSnapshots;
  final List<DailyPortfolioSnapshotItem> recentItems;
  final List<DailyPortfolioSnapshotItem> annualItems;
  final List<DailyPortfolioSnapshot> allSnapshots;
  final List<DailyPortfolioSnapshotItem> allItems;
  final Set<String> transactionDates;
  final MarketNewsSummary? marketNewsSummary;
  final List<CompanyNewsSummaryItem> companyNewsSummaries;
}
