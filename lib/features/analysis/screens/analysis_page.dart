import 'package:moneyfy/utils/monthly_pivot.dart';
import 'package:moneyfy/features/analysis/screens/reddit_chat_page.dart';
import 'package:flutter/material.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/features/account/widgets/total_asset_history_card.dart';
import 'package:moneyfy/features/account/widgets/snapshot_calendar_section.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/features/analysis/widgets/analysis_news_cards.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';
import 'package:moneyfy/features/analysis/screens/annual_asset_analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/investment_review_page.dart';
import 'package:moneyfy/features/portfolio/screens/snapshot_detail_page.dart';

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
  late Future<List<DailyPortfolioSnapshot>> _history;
  late Future<(List<DailyPortfolioSnapshot>, Set<String>)> _calendar;
  late Future<List<CompanyNewsSummaryItem>> _companyNews;
  late Future<MarketNewsSummary?> _marketNews;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataRefreshTick != oldWidget.dataRefreshTick) _load();
  }

  void _load({bool refresh = false}) {
    _history = AppDatabase.instance.fetchAllPortfolioSnapshots();
    _calendar = (_history, AppDatabase.instance.fetchTransactionDates()).wait;
    _companyNews = CompanyNewsSummaryService.instance.fetchUserSummaries(
      forceRefresh: refresh,
    );
    _marketNews = fetchMarketNewsSummary(forceRefresh: refresh);
  }

  Future<void> _refresh() async {
    setState(() => _load(refresh: true));
    // Each card presents its own error state.
    await Future.wait<void>(
      [_history, _calendar, _companyNews, _marketNews].map(
        (future) =>
            future.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ),
    );
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _link(String label, Widget icon, VoidCallback onTap) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: icon,
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.sectionGap);
    final smallGap = SizedBox(height: context.spacing.sm);
    return MoneyfyPage(
      title: '분석',
      scrollController: widget.scrollController,
      onRefresh: _refresh,
      children: [
        FutureBuilder<List<DailyPortfolioSnapshot>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SectionCard(
                title: '총자산 변화',
                child: Text('자산 기록을 불러오지 못했어요. 아래로 당겨 다시 시도해 주세요.'),
              );
            }
            if (!snapshot.hasData) {
              return const SectionCard(
                title: '총자산 변화',
                child: LinearProgressIndicator(),
              );
            }
            return TotalAssetHistoryCard(
              snapshots: snapshot.requireData,
              loadItems: fetchVisibleSnapshotSummaryItemsByDates,
            );
          },
        ),
        gap,
        Text('내 투자 분석', style: context.typography.sectionTitle),
        smallGap,
        SectionCard(
          title: '성과·수입',
          child: Column(
            children: [
              _link(
                '투자성과 분석',
                const Icon(Icons.query_stats_rounded),
                context.openInvestmentPerformance,
              ),
              _link(
                '배당/이자 분석',
                const Icon(Icons.payments_rounded),
                context.openDividendInterest,
              ),
            ],
          ),
        ),
        smallGap,
        SectionCard(
          title: '자산 구성·위험',
          child: Column(
            children: [
              _link(
                '포트폴리오 진단',
                const Icon(Icons.insights_rounded),
                context.openPortfolioDiagnosis,
              ),
              _link(
                '자산 추이·통계',
                const Icon(Icons.insert_chart_outlined_rounded),
                context.openStatistics,
              ),
            ],
          ),
        ),
        if (showInvestmentReviewEntryPoints) ...[
          smallGap,
          SectionCard(
            title: '투자 기록',
            child: _link(
              '투자 회고',
              const Icon(Icons.rate_review_rounded),
              () => _open(const InvestmentReviewPage()),
            ),
          ),
        ],
        smallGap,
        SectionCard(
          title: '리서치·채팅',
          child: Column(
            children: [
              _link(
                '기업 리서치',
                const Icon(Icons.manage_search_rounded),
                context.openEquityResearch,
              ),
              _link(
                'Reddit 요약',
                const ImageIcon(AssetImage('assets/reddit_snoo.png')),
                context.openRedditPostSummaries,
              ),
              _link(
                'RAG채팅',
                const Icon(Icons.chat_bubble_outline),
                () => _open(const RedditChatPage()),
              ),
            ],
          ),
        ),
        gap,
        AnalysisNewsCards(marketNews: _marketNews, companyNews: _companyNews),
        gap,
        FutureBuilder<(List<DailyPortfolioSnapshot>, Set<String>)>(
          future: _calendar,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const SectionCard(
                title: '스냅샷 캘린더',
                child: LinearProgressIndicator(),
              );
            }
            return SnapshotCalendarSection(
              snapshots: snapshot.data?.$1 ?? const [],
              transactionDates: snapshot.data?.$2 ?? const {},
              sectionError: snapshot.error,
              onRetry: _refresh,
            );
          },
        ),
      ],
    );
  }
}

class SnapshotCalendarCard extends StatelessWidget {
  const SnapshotCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.snapshots,
    required this.transactionDates,
    required this.onMonthChanged,
  });

  final DateTime focusedMonth;
  final List<DailyPortfolioSnapshot> snapshots;
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
                final isPivotDay = MonthlyPivot.current.matches(date);
                final dayColor = isPivotDay
                    ? VisualSpec.brand.brandRed
                    : hasSnapshot
                    ? context.colors.primary
                    : context.colors.neutralTextMuted;
                final borderColor = isPivotDay
                    ? VisualSpec.brand.brandRed.withValues(alpha: 0.34)
                    : hasSnapshot
                    ? context.colors.primary
                    : context.colors.neutralOutline;

                return InkWell(
                  borderRadius: BorderRadius.circular(context.radius.rMd),
                  onTap: !hasSnapshot
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  SnapshotDetailPage(snapshot: snapshot),
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
                            fontWeight: isPivotDay
                                ? AppFontWeights.bold
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
    if (!MonthlyPivot.current.matches(date)) continue;
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
            builder: (context) => SnapshotDetailPage(snapshot: item.snapshot),
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
  });

  final String month;
  final String date;
  final String totalAsset;
  final String change;
  final String changeRate;
  final DailyPortfolioSnapshot snapshot;

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
  if (trimmed.startsWith('+')) return context.colors.gainOn;
  if (trimmed.startsWith('-') || trimmed.startsWith('−')) {
    return context.colors.lossOn;
  }
  if (trimmed.contains('-') || trimmed.contains('−')) {
    return context.colors.lossOn;
  }
  if (trimmed.contains('+')) return context.colors.gainOn;
  return context.colors.neutralTextMuted;
}
