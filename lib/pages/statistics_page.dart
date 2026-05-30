import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/buttons/app_buttons.dart';
import '../components/chips/delta_chip.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/icons/app_icon.dart';
import '../components/icons/app_icon_button.dart';
import '../components/section_card.dart';
import '../components/states/empty_state.dart';
import '../components/states/inline_error.dart';
import '../components/states/retry_row.dart';
import '../components/states/skeletons.dart';
import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../services/auth_service.dart';
import '../services/market_data_service.dart';
import '../theme/moneyfy_theme.dart';
import '../ui_scaffold/app_page_scaffold.dart';
import '../utils/display_currency.dart';
import 'analysis_page.dart';
import 'annual_asset_analysis_page.dart';
import 'snapshot_detail_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    this.scrollController,
    this.dataRefreshTick = 0,
  });

  final ScrollController? scrollController;
  final int dataRefreshTick;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime? _focusedMonth;
  String? _selectedCalendarDateKey;
  late Future<_StatisticsSnapshotBundle> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadStatisticsSnapshotBundle();
  }

  @override
  void didUpdateWidget(covariant StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      setState(() {
        _pageFuture = _loadStatisticsSnapshotBundle();
      });
    }
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    if (!mounted) return;
    setState(() {
      _pageFuture = _loadStatisticsSnapshotBundle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StatisticsSnapshotBundle>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppPageScaffold(
            title: '통계',
            enablePullToRefresh: true,
            onRefresh: _refreshPage,
            hasFloatingNavInset: true,
            scrollController: widget.scrollController,
            body: const _StatisticsLoadingBody(),
          );
        }

        if (snapshot.hasError) {
          return AppPageScaffold(
            title: '통계',
            enablePullToRefresh: true,
            onRefresh: _refreshPage,
            hasFloatingNavInset: true,
            scrollController: widget.scrollController,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InlineError(
                  message: '통계 데이터를 불러오지 못했어요.',
                  detail: '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
                ),
                SizedBox(height: context.spacing.sm),
                RetryRow(
                  message: '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
                  onRetry: _refreshPage,
                ),
              ],
            ),
          );
        }

        final bundle = snapshot.data ?? const _StatisticsSnapshotBundle.empty();
        final data = _buildStatisticsData(bundle.snapshots, bundle.items);
        final closingAssets = buildMonthlyClosingAssets(
          bundle.recentSnapshots,
          bundle.recentItems,
        );
        final focusedMonth =
            _focusedMonth ??
            (bundle.allSnapshots.isEmpty
                ? DateTime(DateTime.now().year, DateTime.now().month)
                : DateTime(
                    DateTime.parse(bundle.allSnapshots.last.snapshotDate).year,
                    DateTime.parse(bundle.allSnapshots.last.snapshotDate).month,
                  ));

        return AppPageScaffold(
          title: '통계',
          enablePullToRefresh: true,
          onRefresh: _refreshPage,
          hasFloatingNavInset: true,
          scrollController: widget.scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatisticsSectionBasePlate(
                child: _MonthlyTrendSection(
                  months: data.months,
                  monthKeys: data.monthKeys,
                  series: data.series,
                  totalSeries: data.totalSeries,
                  sectionError: bundle.trendError,
                  onRetry: _refreshPage,
                ),
              ),
              SizedBox(height: context.spacing.sectionGap),
              _StatisticsSectionBasePlate(
                child: _MonthEndSnapshotsSection(
                  items: closingAssets,
                  sectionError: bundle.monthEndError,
                  onRetry: _refreshPage,
                ),
              ),
              SizedBox(height: context.spacing.sectionGap),
              _StatisticsSectionBasePlate(
                child: _YearAnalysisEntrySection(
                  snapshots: bundle.allSnapshots,
                  items: bundle.annualItems,
                  sectionError: bundle.yearAnalysisError,
                  onRetry: _refreshPage,
                ),
              ),
              SizedBox(height: context.spacing.sectionGap),
              _StatisticsSectionBasePlate(
                child: _SnapshotCalendarSection(
                  focusedMonth: focusedMonth,
                  snapshots: bundle.allSnapshots,
                  items: bundle.allItems,
                  transactionDates: bundle.transactionDates,
                  sectionError: bundle.calendarError,
                  selectedDateKey: _selectedCalendarDateKey,
                  onMonthChanged: (value) {
                    setState(() {
                      _focusedMonth = DateTime(value.year, value.month);
                    });
                  },
                  onDateSelected: (dateKey) {
                    setState(() {
                      _selectedCalendarDateKey = dateKey;
                    });
                  },
                  onShowNoSnapshotHint: () {
                    AppSnackBar.showInfo(
                      context,
                      '선택한 날짜에 스냅샷이 없어요.',
                      hasFloatingNavInset: true,
                    );
                  },
                  onRetry: _refreshPage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatisticsSectionBasePlate extends StatelessWidget {
  const _StatisticsSectionBasePlate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
        boxShadow: context.shadows.level3,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding()),
        child: child,
      ),
    );
  }
}

class _StatisticsLoadingBody extends StatelessWidget {
  const _StatisticsLoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonPresetCard(preset: SkeletonCardPreset.chartCard),
        SizedBox(height: context.spacing.sectionGap),
        const SkeletonList(rows: 6, rowHeight: 64, hasLeading: true),
        SizedBox(height: context.spacing.sectionGap),
        const SkeletonCard(height: 120),
        SizedBox(height: context.spacing.sectionGap),
        const SkeletonPresetCard(preset: SkeletonCardPreset.calendarCard),
      ],
    );
  }
}

Future<_StatisticsSnapshotBundle> _loadStatisticsSnapshotBundle() async {
  List<DailyPortfolioSnapshot> allSnapshots = const [];
  Object? baseError;

  try {
    allSnapshots = await AppDatabase.instance.fetchRecentPortfolioSnapshots(
      maxDates: 240,
    );
  } catch (error) {
    baseError = error;
  }

  if (baseError != null) {
    return _StatisticsSnapshotBundle(
      snapshots: const [],
      items: const [],
      recentSnapshots: const [],
      recentItems: const [],
      annualItems: const [],
      allSnapshots: const [],
      allItems: const [],
      transactionDates: const {},
      trendError: baseError,
      monthEndError: baseError,
      yearAnalysisError: baseError,
      calendarError: baseError,
    );
  }

  final recentSnapshots = selectMonthlyClosingSnapshots(allSnapshots);

  List<DailyPortfolioSnapshotItem> recentItems = const [];
  Object? trendError;
  try {
    recentItems = await fetchVisibleSnapshotSummaryItemsByDates(
      recentSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
    );
  } catch (error) {
    trendError = error;
  }

  List<DailyPortfolioSnapshotItem> allItems = const [];
  Object? allItemsError;
  try {
    allItems = await AppDatabase.instance
        .fetchDisplayPortfolioSnapshotItemsByDates(
          allSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
        );
  } catch (error) {
    allItemsError = error;
  }

  List<DailyPortfolioSnapshotItem> annualItems = const [];
  Object? annualItemsError;
  try {
    annualItems = await fetchVisibleSnapshotSummaryItemsByDates(
      allSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
    );
  } catch (error) {
    annualItemsError = error;
  }

  Set<String> transactionDates = const {};
  Object? transactionError;
  try {
    transactionDates = await AppDatabase.instance.fetchTransactionDates();
  } catch (error) {
    transactionError = error;
  }

  return _StatisticsSnapshotBundle(
    snapshots: recentSnapshots,
    items: recentItems,
    recentSnapshots: recentSnapshots,
    recentItems: recentItems,
    annualItems: annualItems,
    allSnapshots: allSnapshots,
    allItems: allItems,
    transactionDates: transactionDates,
    trendError: trendError,
    monthEndError: trendError,
    yearAnalysisError: annualItemsError,
    calendarError: allItemsError ?? transactionError,
  );
}

_StatisticsData _buildStatisticsData(
  List<DailyPortfolioSnapshot> snapshots,
  List<DailyPortfolioSnapshotItem> items,
) {
  final dateKeys = snapshots.map((item) => item.snapshotDate).toList()..sort();
  final months = dateKeys.map(_monthLabelFromKey).toList();
  final snapshotIdByDate = {
    for (final snapshot in snapshots) snapshot.snapshotDate: snapshot.id,
  };
  final assetKeys = items.map(_statisticsAssetKey).toSet().toList()
    ..sort((a, b) => a.compareTo(b));
  final assetLabelByKey = {
    for (final item in items) _statisticsAssetKey(item): item.assetTitle,
  };
  final assetIdByKey = {
    for (final item in items) _statisticsAssetKey(item): item.assetId,
  };

  final series = assetKeys.map((assetKey) {
    final values = dateKeys.map((dateKey) {
      final snapshotId = snapshotIdByDate[dateKey];
      final row = items.cast<DailyPortfolioSnapshotItem?>().firstWhere(
        (item) =>
            item?.snapshotId == snapshotId &&
            _statisticsAssetKey(item!) == assetKey,
        orElse: () => null,
      );
      return (row?.totalValuationAmount ?? 0) / 1000000;
    }).toList();
    final label = assetLabelByKey[assetKey] ?? '-';

    return _MonthlyAssetSeries(
      label: label,
      color: MoneyfyChartPalette.colorForAsset(
        label,
        assetId: assetIdByKey[assetKey],
        fallback: ThemeData.light().colorScheme.outline,
      ),
      values: values,
    );
  }).toList();

  final totalSeries = _MonthlyAssetSeries(
    label: '총자산',
    color: ThemeData.light().colorScheme.onSurface,
    values: dateKeys.map((dateKey) {
      final snapshotId = snapshotIdByDate[dateKey];
      final total = items
          .where((item) => item.snapshotId == snapshotId)
          .fold<double>(0, (sum, item) => sum + item.totalValuationAmount);
      return total / 1000000;
    }).toList(),
  );

  return _StatisticsData(
    monthKeys: dateKeys,
    months: months,
    series: series,
    totalSeries: totalSeries,
  );
}

String _monthLabelFromKey(String key) {
  final date = DateTime.parse(key);
  return '${date.month}월';
}

String _statisticsAssetKey(DailyPortfolioSnapshotItem item) {
  return 'id:${item.assetId}';
}

class _MonthlyTrendSection extends StatefulWidget {
  const _MonthlyTrendSection({
    required this.months,
    required this.monthKeys,
    required this.series,
    required this.totalSeries,
    this.sectionError,
    required this.onRetry,
  });

  final List<String> months;
  final List<String> monthKeys;
  final List<_MonthlyAssetSeries> series;
  final _MonthlyAssetSeries totalSeries;
  final Object? sectionError;
  final Future<void> Function() onRetry;

  @override
  State<_MonthlyTrendSection> createState() => _MonthlyTrendSectionState();
}

class _MonthlyTrendSectionState extends State<_MonthlyTrendSection> {
  int? _selectedIndex;
  bool _legendExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant _MonthlyTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.months != widget.months ||
        oldWidget.totalSeries.values != widget.totalSeries.values) {
      _syncSelection();
    }
  }

  void _syncSelection() {
    if (widget.months.isEmpty) {
      _selectedIndex = null;
      return;
    }
    _selectedIndex ??= widget.months.length - 1;
    if (_selectedIndex! >= widget.months.length) {
      _selectedIndex = widget.months.length - 1;
    }
  }

  void _handleSelection(Offset localPosition, double chartWidth) {
    if (widget.months.isEmpty || chartWidth <= 0) return;

    final safeDx = localPosition.dx.clamp(0.0, chartWidth);
    final denominator = math.max(widget.months.length - 1, 1);
    final index = ((safeDx / chartWidth) * denominator).round().clamp(
      0,
      widget.months.length - 1,
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.sectionError != null) {
      return SectionCard(
        title: '월별 총자산 변화',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InlineError(
              message: '차트 데이터를 불러오지 못했어요.',
              detail: '다시 시도해 주세요.',
            ),
            SizedBox(height: context.spacing.sm),
            RetryRow(message: '다시 시도해 주세요.', onRetry: widget.onRetry),
          ],
        ),
      );
    }

    final chartSeries = [widget.totalSeries, ...widget.series];
    final yAxisLabels = _buildYAxisLabels(chartSeries);
    final hasData =
        widget.months.isNotEmpty &&
        chartSeries.any((item) => item.values.any((value) => value != 0));

    if (!hasData) {
      final isLoggedIn = AuthService.currentUser != null;
      if (!isLoggedIn) {
        return _buildCenteredLevel1EmptyCard(
          context,
          title: '차트 데이터가 없어요',
          description: '스냅샷이 쌓이면 월별 총자산 변화를 확인할 수 있어요.',
          actionLabel: CopySpec.refresh,
          onAction: widget.onRetry,
        );
      }
      return EmptyStateCard(
        title: '차트 데이터가 없어요',
        description: '스냅샷이 쌓이면 월별 총자산 변화를 확인할 수 있어요.',
        actionLabel: CopySpec.refresh,
        onAction: widget.onRetry,
      );
    }

    final selected = _selectedIndex ?? (widget.months.length - 1);
    final legendItems = [
      _LegendTextItem(
        color: widget.totalSeries.color,
        label: widget.totalSeries.label,
      ),
      for (final item in widget.series)
        _LegendTextItem(color: item.color, label: item.label),
    ];
    final visibleLegendCount = _legendExpanded
        ? legendItems.length
        : math.min(6, legendItems.length);

    return SectionCard(
      title: '월별 총자산 변화',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedMonthStrip(
            monthKey: widget.monthKeys[selected],
            totalValueInMillion: widget.totalSeries.values[selected],
            previousValueInMillion: selected > 0
                ? widget.totalSeries.values[selected - 1]
                : null,
          ),
          SizedBox(height: context.spacing.md),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      VisualSpec.chart.chartPadding,
                      0,
                      VisualSpec.icon.progressIndicatorSizeLarge,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final label in yAxisLabels)
                          Text(
                            label,
                            style: context.typography.caption.copyWith(
                              fontSize: context.fontSizes.s12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _handleSelection(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        onHorizontalDragUpdate: (details) => _handleSelection(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        child: CustomPaint(
                          painter: _MonthlyTrendPainter(
                            series: chartSeries,
                            selectedIndex: _selectedIndex,
                            gridColor: colorScheme.outlineVariant.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? VisualSpec.chart.gridAlphaDark
                                  : VisualSpec.chart.gridAlphaLight,
                            ),
                            pointStrokeColor: colorScheme.surface,
                            indicatorColor: colorScheme.onSurfaceVariant
                                .withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? VisualSpec.chart.crosshairAlphaDark
                                      : VisualSpec.chart.crosshairAlphaLight,
                                ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.spacing.xs,
                              VisualSpec.chart.chartPadding,
                              context.spacing.xs,
                              context.spacing.xs,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < widget.months.length; i++)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Text(
                                        widget.months[i],
                                        style: context.typography.caption
                                            .copyWith(
                                              fontSize: context.fontSizes.s12,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontWeight: _selectedIndex == i
                                                  ? AppFontWeights.semibold
                                                  : AppFontWeights.regular,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.md),
          _LegendTextRow(items: legendItems.take(visibleLegendCount).toList()),
          if (legendItems.length > 6)
            AppGhostButton(
              label: _legendExpanded ? '범례 접기' : '범례 더보기',
              onPressed: () =>
                  setState(() => _legendExpanded = !_legendExpanded),
            ),
        ],
      ),
    );
  }
}

class _SelectedMonthStrip extends StatelessWidget {
  const _SelectedMonthStrip({
    required this.monthKey,
    required this.totalValueInMillion,
    this.previousValueInMillion,
  });

  final String monthKey;
  final double totalValueInMillion;
  final double? previousValueInMillion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValueKrw = totalValueInMillion * 1000000;
    final deltaKrw = previousValueInMillion == null
        ? null
        : (totalValueInMillion - previousValueInMillion!) * 1000000;
    final deltaRate =
        previousValueInMillion == null || previousValueInMillion == 0
        ? null
        : ((totalValueInMillion - previousValueInMillion!) /
                  previousValueInMillion!) *
              100;

    final deltaText = deltaKrw == null
        ? null
        : MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(deltaKrw);
    final deltaColor = deltaText == null
        ? context.colors.neutralTextMuted
        : deltaText.startsWith('+')
        ? context.colors.positiveOn
        : deltaText.startsWith('-')
        ? context.colors.negativeOn
        : context.colors.neutralTextMuted;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: VisualSpec.chart.selectionHeaderHeight,
      ),
      padding: EdgeInsets.all(VisualSpec.chart.selectionHeaderPadding),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.chart.tooltipRadius),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: VisualSpec.chart.tooltipBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatYearMonth(monthKey),
                style: context.typography.meta.copyWith(
                  fontSize: context.fontSizes.s14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyfyDisplayCurrencySettings.formatAmountFromKrw(
                  currentValueKrw,
                ),
                textAlign: TextAlign.right,
                style: context.typography.cardTitle.copyWith(
                  fontSize: context.fontSizes.s16,
                  color: colorScheme.onSurface,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              if (deltaText != null) ...[
                SizedBox(height: context.spacing.xs / 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deltaText,
                      textAlign: TextAlign.right,
                      style: context.typography.caption.copyWith(
                        fontSize: context.fontSizes.s14,
                        color: deltaColor,
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    if (deltaRate != null) ...[
                      SizedBox(width: context.spacing.xs),
                      DeltaChip(
                        value: deltaKrw!,
                        percent: deltaRate,
                        mode: DeltaChipMode.percent,
                        vivid: true,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthEndSnapshotsSection extends StatefulWidget {
  const _MonthEndSnapshotsSection({
    required this.items,
    this.sectionError,
    required this.onRetry,
  });

  final List<MonthlyClosingAsset> items;
  final Object? sectionError;
  final Future<void> Function() onRetry;

  @override
  State<_MonthEndSnapshotsSection> createState() =>
      _MonthEndSnapshotsSectionState();
}

class _MonthEndSnapshotsSectionState extends State<_MonthEndSnapshotsSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.sectionError != null) {
      return SectionCard(
        title: '월말 스냅샷',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InlineError(
              message: '월말 스냅샷을 불러오지 못했어요.',
              detail: '다시 시도해 주세요.',
            ),
            SizedBox(height: context.spacing.sm),
            RetryRow(message: '다시 시도해 주세요.', onRetry: widget.onRetry),
          ],
        ),
      );
    }

    if (widget.items.isEmpty) {
      final isLoggedIn = AuthService.currentUser != null;
      if (!isLoggedIn) {
        return _buildCenteredLevel1EmptyCard(
          context,
          title: '아직 스냅샷이 없어요',
          description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
          actionLabel: CopySpec.refresh,
          onAction: widget.onRetry,
        );
      }
      return EmptyStateCard(
        title: '아직 스냅샷이 없어요',
        description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
        actionLabel: CopySpec.refresh,
        onAction: widget.onRetry,
      );
    }

    return MonthlyClosingAssetsCard(items: widget.items);
  }
}

class _YearAnalysisEntrySection extends StatelessWidget {
  const _YearAnalysisEntrySection({
    required this.snapshots,
    required this.items,
    this.sectionError,
    required this.onRetry,
  });

  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> items;
  final Object? sectionError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (sectionError != null) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InlineError(
              message: '연도 분석 데이터를 불러오지 못했어요.',
              detail: '다시 시도해 주세요.',
            ),
            SizedBox(height: context.spacing.sm),
            RetryRow(message: '다시 시도해 주세요.', onRetry: onRetry),
          ],
        ),
      );
    }

    final enabled = snapshots.isNotEmpty;

    return SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radius.rMd),
        onTap: !enabled
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnnualAssetAnalysisPage(
                      snapshots: snapshots,
                      items: items,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.xs,
            vertical: context.spacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: context.spacing.xl + context.spacing.xs,
                height: context.spacing.xl + context.spacing.xs,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(context.radius.rMd),
                ),
                child: AppIcon(
                  AppIconName.insights,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('연도별 자산 분석', style: context.typography.cardTitle),
                    SizedBox(height: context.spacing.xs / 2),
                    Text(
                      enabled
                          ? '월별 트렌드와 요약을 연도 단위로 확인하세요.'
                          : '분석할 스냅샷 데이터가 아직 없어요.',
                      style: context.typography.meta,
                    ),
                  ],
                ),
              ),
              AppIcon(
                AppIconName.chevronRight,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotCalendarSection extends StatelessWidget {
  const _SnapshotCalendarSection({
    required this.focusedMonth,
    required this.snapshots,
    required this.items,
    required this.transactionDates,
    required this.selectedDateKey,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onShowNoSnapshotHint,
    this.sectionError,
    required this.onRetry,
  });

  final DateTime focusedMonth;
  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> items;
  final Set<String> transactionDates;
  final String? selectedDateKey;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String> onDateSelected;
  final VoidCallback onShowNoSnapshotHint;
  final Object? sectionError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (sectionError != null) {
      return SectionCard(
        title: '스냅샷 캘린더',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InlineError(
              message: '캘린더 데이터를 불러오지 못했어요.',
              detail: '다시 시도해 주세요.',
            ),
            SizedBox(height: context.spacing.sm),
            RetryRow(message: '다시 시도해 주세요.', onRetry: onRetry),
          ],
        ),
      );
    }

    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final leadingEmpty = firstDay.weekday % 7;
    final totalCells = leadingEmpty + lastDay.day;
    final trailingEmpty = (7 - (totalCells % 7)) % 7;
    final snapshotByDate = <String, DailyPortfolioSnapshot>{};
    for (final snapshot in snapshots) {
      final normalized = _normalizeDateKey(snapshot.snapshotDate);
      if (normalized == null) continue;
      snapshotByDate[normalized] = snapshot;
    }
    final normalizedTransactionDates = transactionDates
        .map(_normalizeDateKey)
        .whereType<String>()
        .toSet();
    final itemsBySnapshotId = <int, List<DailyPortfolioSnapshotItem>>{};
    for (final item in items) {
      itemsBySnapshotId.putIfAbsent(item.snapshotId, () => []).add(item);
    }

    if (snapshots.isEmpty) {
      final isLoggedIn = AuthService.currentUser != null;
      if (!isLoggedIn) {
        return _buildCenteredLevel1EmptyCard(
          context,
          title: '아직 스냅샷이 없어요',
          description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
          actionLabel: CopySpec.refresh,
          onAction: onRetry,
        );
      }
      return EmptyStateCard(
        title: '아직 스냅샷이 없어요',
        description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
        actionLabel: CopySpec.refresh,
        onAction: onRetry,
      );
    }

    return SectionCard(
      title: '스냅샷 캘린더',
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
              children: [
                _MonthControlButton(
                  icon: AppIconName.chevronLeft,
                  tooltip: '이전 달',
                  onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month - 1),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${focusedMonth.year}년 ${focusedMonth.month}월',
                      style: context.typography.cardTitle,
                    ),
                  ),
                ),
                _MonthControlButton(
                  icon: AppIconName.chevronRight,
                  tooltip: '다음 달',
                  onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month + 1),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.xs),
            _CalendarLegendRow(),
            SizedBox(height: context.spacing.sm),
            Row(
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(label, style: context.typography.caption),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.spacing.xs),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells + trailingEmpty,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
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
                final hasTransaction = normalizedTransactionDates.contains(
                  dateKey,
                );
                final isPivotDay = day == 20;
                final isSelected = selectedDateKey == dateKey;
                final isToday = _dateKey(DateTime.now()) == dateKey;
                final snapshotItems = snapshot == null
                    ? const <DailyPortfolioSnapshotItem>[]
                    : (itemsBySnapshotId[snapshot.id] ??
                          const <DailyPortfolioSnapshotItem>[]);

                return _CalendarDayCell(
                  day: day,
                  hasSnapshot: hasSnapshot,
                  hasTransaction: hasTransaction,
                  isPivotDay: isPivotDay,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () {
                    onDateSelected(dateKey);
                    if (!hasSnapshot) {
                      onShowNoSnapshotHint();
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SnapshotDetailPage(
                          snapshot: snapshot,
                          items: snapshotItems,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthControlButton extends StatelessWidget {
  const _MonthControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final AppIconName icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(tooltip: tooltip, onPressed: onPressed, icon: icon);
  }
}

class _CalendarLegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pivotColor = Color.lerp(
      colorScheme.primary,
      colorScheme.error,
      0.58,
    )!;
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                ),
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('스냅샷 있음', style: context.typography.caption),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('거래 있음', style: context.typography.caption),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '20',
              style: context.typography.caption.copyWith(
                color: pivotColor,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('월 분기점(20일)', style: context.typography.caption),
          ],
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.hasSnapshot,
    required this.hasTransaction,
    required this.isPivotDay,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool hasSnapshot;
  final bool hasTransaction;
  final bool isPivotDay;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = isSelected
        ? context.surfaces.surfaceRaised
        : context.surfaces.surfaceBase;
    final pivotColor = Color.lerp(
      colorScheme.primary,
      colorScheme.error,
      0.58,
    )!;
    final dayColor = isPivotDay
        ? pivotColor
        : hasSnapshot
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderColor = isPivotDay
        ? pivotColor.withValues(alpha: 0.34)
        : hasSnapshot
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.outlineVariant.withValues(alpha: 0.85);

    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rSm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion.fast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.radius.rSm),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: context.typography.meta.copyWith(
                color: dayColor,
                fontWeight: hasSnapshot || isSelected || isPivotDay
                    ? AppFontWeights.semibold
                    : AppFontWeights.semibold,
              ),
            ),
            SizedBox(height: context.spacing.xs / 2),
            if (hasTransaction)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 6, height: 6),
          ],
        ),
      ),
    );
  }
}

class _LegendTextRow extends StatelessWidget {
  const _LegendTextRow({required this.items});

  final List<_LegendTextItem> items;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '●',
                  style: context.typography.meta.copyWith(
                    color: item.color,
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                SizedBox(width: context.spacing.xs / 2),
                Text(item.label, style: context.typography.meta),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendTextItem {
  const _LegendTextItem({required this.color, required this.label});

  final Color color;
  final String label;
}

class _MonthlyTrendPainter extends CustomPainter {
  _MonthlyTrendPainter({
    required this.series,
    required this.selectedIndex,
    required this.gridColor,
    required this.pointStrokeColor,
    required this.indicatorColor,
  });

  final List<_MonthlyAssetSeries> series;
  final int? selectedIndex;
  final Color gridColor;
  final Color pointStrokeColor;
  final Color indicatorColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series.first.values.isEmpty) {
      return;
    }

    const leftPadding = 12.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 28.0;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final allValues = series.expand((item) => item.values).toList();
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    final range = math.max(maxValue - minValue, 1.0);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = VisualSpec.chart.gridThickness;

    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (selectedIndex != null && series.first.values.length > 1) {
      final selectedDx =
          chartRect.left +
          (chartRect.width / (series.first.values.length - 1)) * selectedIndex!;
      final indicatorPaint = Paint()
        ..color = indicatorColor
        ..strokeWidth = VisualSpec.chart.crosshairThickness;
      canvas.drawLine(
        Offset(selectedDx, chartRect.top),
        Offset(selectedDx, chartRect.bottom),
        indicatorPaint,
      );
    }

    for (final item in series) {
      final path = Path();
      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = VisualSpec.chart.lineStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final pointPaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      final pointStrokePaint = Paint()
        ..color = pointStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (var i = 0; i < item.values.length; i++) {
        final dx =
            chartRect.left + (chartRect.width / (item.values.length - 1)) * i;
        final normalized = (item.values[i] - minValue) / range;
        final dy = chartRect.bottom - (chartRect.height * normalized);
        final point = Offset(dx, dy);

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }

        if (VisualSpec.chart.pointRadius > 0) {
          canvas.drawCircle(point, VisualSpec.chart.pointRadius, pointPaint);
          canvas.drawCircle(
            point,
            VisualSpec.chart.pointRadius,
            pointStrokePaint,
          );
        }

        if (selectedIndex == i) {
          final fillPaint = Paint()..color = item.color;
          canvas.drawCircle(
            point,
            VisualSpec.chart.pointRadiusSelected,
            fillPaint,
          );
          final strokePaint = Paint()
            ..color = pointStrokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = VisualSpec.chart.pointStrokeSelected;
          canvas.drawCircle(
            point,
            VisualSpec.chart.pointRadiusSelected,
            strokePaint,
          );
        }
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.pointStrokeColor != pointStrokeColor ||
        oldDelegate.indicatorColor != indicatorColor;
  }
}

class _MonthlyAssetSeries {
  const _MonthlyAssetSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

class _StatisticsData {
  const _StatisticsData({
    required this.monthKeys,
    required this.months,
    required this.series,
    required this.totalSeries,
  });

  final List<String> monthKeys;
  final List<String> months;
  final List<_MonthlyAssetSeries> series;
  final _MonthlyAssetSeries totalSeries;
}

class _StatisticsSnapshotBundle {
  const _StatisticsSnapshotBundle({
    required this.snapshots,
    required this.items,
    required this.recentSnapshots,
    required this.recentItems,
    required this.annualItems,
    required this.allSnapshots,
    required this.allItems,
    required this.transactionDates,
    required this.trendError,
    required this.monthEndError,
    required this.yearAnalysisError,
    required this.calendarError,
  });

  const _StatisticsSnapshotBundle.empty()
    : snapshots = const [],
      items = const [],
      recentSnapshots = const [],
      recentItems = const [],
      annualItems = const [],
      allSnapshots = const [],
      allItems = const [],
      transactionDates = const {},
      trendError = null,
      monthEndError = null,
      yearAnalysisError = null,
      calendarError = null;

  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> items;
  final List<DailyPortfolioSnapshot> recentSnapshots;
  final List<DailyPortfolioSnapshotItem> recentItems;
  final List<DailyPortfolioSnapshotItem> annualItems;
  final List<DailyPortfolioSnapshot> allSnapshots;
  final List<DailyPortfolioSnapshotItem> allItems;
  final Set<String> transactionDates;
  final Object? trendError;
  final Object? monthEndError;
  final Object? yearAnalysisError;
  final Object? calendarError;
}

List<String> _buildYAxisLabels(List<_MonthlyAssetSeries> series) {
  if (series.isEmpty || series.first.values.isEmpty) {
    return const ['0', '0', '0', '0'];
  }

  final allValues = series.expand((item) => item.values).toList();
  final minValue = allValues.reduce(math.min);
  final maxValue = allValues.reduce(math.max);

  if (maxValue == minValue) {
    final label = _formatYAxisLabel(maxValue);
    return [label, label, label, label];
  }

  return [
    _formatYAxisLabel(maxValue),
    _formatYAxisLabel(minValue + ((maxValue - minValue) * 2 / 3)),
    _formatYAxisLabel(minValue + ((maxValue - minValue) * 1 / 3)),
    _formatYAxisLabel(minValue),
  ];
}

String _formatYAxisLabel(double value) {
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}B';
  }
  return '${value.toStringAsFixed(0)}M';
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _normalizeDateKey(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return _dateKey(DateTime(parsed.year, parsed.month, parsed.day));
  }
  if (value.length >= 10) {
    final head = value.substring(0, 10);
    final headParsed = DateTime.tryParse(head);
    if (headParsed != null) {
      return _dateKey(
        DateTime(headParsed.year, headParsed.month, headParsed.day),
      );
    }
  }
  return null;
}

String _formatYearMonth(String key) {
  final date = DateTime.tryParse(key);
  if (date == null) return key;
  return '${date.year}년 ${date.month}월';
}

Widget _buildCenteredLevel1EmptyCard(
  BuildContext context, {
  required String title,
  required String description,
  String? actionLabel,
  Future<void> Function()? onAction,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = context.cardWidths.apply(
        constraints.maxWidth,
        level: 1,
      );
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          child: SectionCard(
            variant: SectionCardVariant.raised,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 188),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIcon(
                      AppIconName.insights,
                      size: VisualSpec.icon.iconSizeLarge,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.66),
                    ),
                    SizedBox(height: context.spacing.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.typography.cardTitle.copyWith(
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: context.typography.meta,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      SizedBox(height: context.spacing.md),
                      AppPrimaryButton(
                        label: actionLabel,
                        onPressed: () => onAction(),
                        expand: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
