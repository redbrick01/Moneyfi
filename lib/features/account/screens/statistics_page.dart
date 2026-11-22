import 'package:flutter/material.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/icons/app_icon_button.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/components/states/skeletons.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/account/widgets/total_asset_history_card.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/features/analysis/screens/analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/annual_asset_analysis_page.dart';
import 'package:moneyfy/features/portfolio/screens/snapshot_detail_page.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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
          subtitle: '스냅샷과 기록을 기준으로 자산 흐름을 확인합니다.',
          enablePullToRefresh: true,
          onRefresh: _refreshPage,
          hasFloatingNavInset: true,
          scrollController: widget.scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TotalAssetHistoryCard(
                snapshots: bundle.historySnapshots,
                loadItems: fetchVisibleSnapshotSummaryItemsByDates,
              ),
              SizedBox(height: context.spacing.sectionGap),
              _MonthEndSnapshotsSection(
                items: closingAssets,
                sectionError: bundle.monthEndError,
                onRetry: _refreshPage,
              ),
              SizedBox(height: context.spacing.sectionGap),
              _YearAnalysisEntrySection(
                snapshots: bundle.allSnapshots,
                items: bundle.annualItems,
                sectionError: bundle.yearAnalysisError,
                onRetry: _refreshPage,
              ),
              SizedBox(height: context.spacing.sectionGap),
              _SnapshotCalendarSection(
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
            ],
          ),
        );
      },
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
  final historySnapshots = await AppDatabase.instance
      .fetchAllPortfolioSnapshots();
  final allSnapshots = historySnapshots.length > 240
      ? historySnapshots.sublist(historySnapshots.length - 240)
      : historySnapshots;
  final recentSnapshots = selectMonthlyClosingSnapshots(allSnapshots);

  List<DailyPortfolioSnapshotItem> recentItems = const [];
  Object? monthEndError;
  try {
    recentItems = await fetchVisibleSnapshotSummaryItemsByDates(
      recentSnapshots.map((snapshot) => snapshot.snapshotDate).toList(),
    );
  } catch (error) {
    monthEndError = error;
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
    historySnapshots: historySnapshots,
    recentSnapshots: recentSnapshots,
    recentItems: recentItems,
    annualItems: annualItems,
    allSnapshots: allSnapshots,
    allItems: allItems,
    transactionDates: transactionDates,
    monthEndError: monthEndError,
    yearAnalysisError: annualItemsError,
    calendarError: allItemsError ?? transactionError,
  );
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
                      enabled ? '스냅샷 기록을 연도 단위로 비교해요.' : '분석할 스냅샷 데이터가 아직 없어요.',
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
            Text('날짜별 저장 기록과 거래 흔적을 확인해요.', style: context.typography.meta),
            SizedBox(height: context.spacing.sm),
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
            SizedBox(height: context.spacing.md),
            Center(child: _CalendarLegendRow()),
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
    return Wrap(
      alignment: WrapAlignment.center,
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
                borderRadius: BorderRadius.circular(context.radius.rSm / 2),
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
                color: colorScheme.primary,
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
    final dayColor = isPivotDay || hasSnapshot
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderColor = isPivotDay
        ? colorScheme.primary.withValues(alpha: 0.34)
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
                fontWeight: isPivotDay
                    ? AppFontWeights.bold
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

class _StatisticsSnapshotBundle {
  const _StatisticsSnapshotBundle({
    required this.historySnapshots,
    required this.recentSnapshots,
    required this.recentItems,
    required this.annualItems,
    required this.allSnapshots,
    required this.allItems,
    required this.transactionDates,
    required this.monthEndError,
    required this.yearAnalysisError,
    required this.calendarError,
  });

  const _StatisticsSnapshotBundle.empty()
    : historySnapshots = const [],
      recentSnapshots = const [],
      recentItems = const [],
      annualItems = const [],
      allSnapshots = const [],
      allItems = const [],
      transactionDates = const {},
      monthEndError = null,
      yearAnalysisError = null,
      calendarError = null;

  final List<DailyPortfolioSnapshot> historySnapshots;
  final List<DailyPortfolioSnapshot> recentSnapshots;
  final List<DailyPortfolioSnapshotItem> recentItems;
  final List<DailyPortfolioSnapshotItem> annualItems;
  final List<DailyPortfolioSnapshot> allSnapshots;
  final List<DailyPortfolioSnapshotItem> allItems;
  final Set<String> transactionDates;
  final Object? monthEndError;
  final Object? yearAnalysisError;
  final Object? calendarError;
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
