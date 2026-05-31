import 'package:flutter/material.dart';

import '../components/chips/moneyfy_pill.dart';
import '../components/icons/app_icon.dart';
import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../navigation/moneyfy_navigation.dart';
import '../services/company_news_summary_service.dart';
import '../utils/display_currency.dart';
import '../widgets/company_news_summary_card.dart';
import '../widgets/market_news_summary_card.dart';
import '../widgets/moneyfy_ui.dart';
import 'annual_asset_analysis_page.dart';
import 'investment_review_page.dart';
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
            SizedBox(height: context.spacing.sectionGap),
            _Level1WidthCard(
              child: CompanyNewsSummaryCard(items: bundle.companyNewsSummaries),
            ),
            SizedBox(height: context.spacing.sectionGap),
            _AnalysisEntryCard(
              icon: Icons.rate_review_rounded,
              title: '투자 회고',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const InvestmentReviewPage(),
                  ),
                );
              },
            ),
            SizedBox(height: context.spacing.sm),
            _AnalysisEntryCard(
              icon: Icons.insights_rounded,
              title: '포트폴리오 진단',
              onTap: context.openPortfolioDiagnosis,
            ),
            SizedBox(height: context.spacing.sm),
            _AnalysisEntryCard(
              icon: Icons.query_stats_rounded,
              title: '투자성과 분석',
              onTap: context.openInvestmentPerformance,
            ),
            SizedBox(height: context.spacing.sm),
            _AnalysisEntryCard(
              icon: Icons.payments_rounded,
              title: '배당/이자 분석',
              onTap: context.openDividendInterest,
            ),
            SizedBox(height: context.spacing.sm),
            _AnalysisEntryCard(
              icon: Icons.insert_chart_outlined_rounded,
              title: '통계',
              onTap: context.openStatistics,
            ),
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

class _AnalysisEntryCard extends StatelessWidget {
  const _AnalysisEntryCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      dense: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radius.rMd),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
          child: Row(
            children: [
              Container(
                width: VisualSpec.icon.badgeBox,
                height: VisualSpec.icon.badgeBox,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(context.radius.rMd),
                ),
                child: AppIcon.raw(
                  icon,
                  color: colorScheme.primary,
                  size: VisualSpec.icon.sizeDefault,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(child: Text(title, style: context.typography.cardTitle)),
              SizedBox(width: context.spacing.sm),
              AppIcon(
                AppIconName.chevronRight,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
      title: '스냅샷 참고 캘린더',
      subtitle: '기록 기반 참고 지표 · ${focusedMonth.year}년 ${focusedMonth.month}월',
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
                          style: context.typography.meta.copyWith(
                            color: context.colors.neutralTextMuted,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.spacing.sm),
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
                  context.colors.primary,
                  context.colors.negativeOn,
                  0.58,
                )!;
                final dayColor = isPivotDay
                    ? pivotColor
                    : hasSnapshot
                    ? context.colors.primary
                    : context.colors.neutralTextMuted;
                final borderColor = isPivotDay
                    ? pivotColor.withValues(alpha: 0.34)
                    : hasSnapshot
                    ? context.colors.primary
                    : context.colors.neutralOutline;
                final snapshotItems = snapshot == null
                    ? const <DailyPortfolioSnapshotItem>[]
                    : (itemsBySnapshotId[snapshot.id] ??
                          const <DailyPortfolioSnapshotItem>[]);

                return InkWell(
                  borderRadius: BorderRadius.circular(context.radius.rMd),
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
                      color: context.colors.neutralSurfaceRaised,
                      borderRadius: BorderRadius.circular(context.radius.rMd),
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
                                ? AppFontWeights.semibold
                                : AppFontWeights.semibold,
                          ),
                        ),
                        SizedBox(
                          height: context.spacing.xs - context.spacing.xs / 4,
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasTransaction
                                ? context.colors.primary
                                : colorScheme.surface.withValues(alpha: 0),
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
      borderRadius: BorderRadius.circular(context.radius.rLg),
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
                  SizedBox(height: context.spacing.xs),
                  Text(
                    years.isEmpty
                        ? '스냅샷 기록이 쌓이면 통계 기준 연도별 비교를 볼 수 있어요.'
                        : '통계 기준 연도별 비교 · ${years.map((year) => '$year년').join(' · ')}',
                    style: context.typography.meta.copyWith(
                      color: context.colors.neutralTextMuted,
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
    final dividerColor = context.colors.neutralOutline;
    final fixedItems = widget.items.take(3).toList(growable: false);
    final expandedItems = widget.items.skip(3).take(9).toList(growable: false);
    final canExpand = widget.items.length > 3;

    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 최종 자산', style: theme.textTheme.titleLarge),
          if (widget.items.isEmpty) ...[
            SizedBox(height: context.spacing.md + context.spacing.xs / 4),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 140),
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md + context.spacing.xs / 2,
                vertical: context.spacing.lg,
              ),
              decoration: BoxDecoration(
                color: context.colors.neutralSurfaceRaised,
                borderRadius: BorderRadius.circular(context.radius.rLg),
                border: Border.all(color: context.colors.neutralOutline),
              ),
              child: Center(
                child: Text(
                  '표시할 스냅샷 데이터가 없습니다.',
                  textAlign: TextAlign.center,
                  style: context.typography.body.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: context.spacing.md + context.spacing.xs / 4),
            for (final item in fixedItems) ...[
              _MonthlyClosingAssetRow(item: item),
              if (item != fixedItems.last) ...[
                SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
                Divider(color: dividerColor, height: 1),
                SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
              ],
            ],
            if (canExpand) ...[
              AnimatedSize(
                duration: context.motion.normal,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: _expanded
                    ? Column(
                        children: [
                          SizedBox(
                            height: context.spacing.sm + context.spacing.xs / 4,
                          ),
                          Divider(color: dividerColor, height: 1),
                          SizedBox(
                            height: context.spacing.sm + context.spacing.xs / 4,
                          ),
                          for (final item in expandedItems) ...[
                            _MonthlyClosingAssetRow(item: item),
                            if (item != expandedItems.last) ...[
                              SizedBox(
                                height:
                                    context.spacing.sm + context.spacing.xs / 4,
                              ),
                              Divider(color: dividerColor, height: 1),
                              SizedBox(
                                height:
                                    context.spacing.sm + context.spacing.xs / 4,
                              ),
                            ],
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
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
    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rMd),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                SnapshotDetailPage(snapshot: item.snapshot, items: item.items),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.date,
                  textAlign: TextAlign.left,
                  style: context.typography.meta.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.totalAsset,
                  style: context.typography.cardTitle.copyWith(
                    color: context.colors.neutralText,
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                SizedBox(height: context.spacing.xs / 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.change,
                      style: context.typography.meta.copyWith(
                        color: _analysisValueColor(context, item.change),
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(width: context.spacing.xs),
                    MoneyfyBadge(
                      label: item.changeRate,
                      size: MoneyfyPillSize.sm,
                      variant: MoneyfyPillVariant.outline,
                      backgroundColor: context.colors.neutralSurfaceBase,
                      borderColor: context.colors.neutralOutline,
                      textColor: _analysisValueColor(context, item.changeRate),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: context.spacing.sm),
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

Color _analysisValueColor(BuildContext context, String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('+')) return context.colors.positiveOn;
  if (trimmed.startsWith('-') || trimmed.startsWith('−')) {
    return context.colors.negativeOn;
  }
  if (trimmed.contains('-') || trimmed.contains('−')) {
    return context.colors.negativeOn;
  }
  if (trimmed.contains('+')) return context.colors.positiveOn;
  return context.colors.neutralTextMuted;
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
