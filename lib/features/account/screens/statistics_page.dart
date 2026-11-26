import 'package:moneyfy/features/account/widgets/snapshot_calendar_section.dart';
import 'package:flutter/material.dart';

import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/components/states/skeletons.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';
import 'package:moneyfy/features/analysis/screens/analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/annual_asset_analysis_page.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppDataLifecycleState>(
      valueListenable: AppDataLifecycleService.state,
      builder: (context, state, _) {
        if (state.isReplacing) {
          return MoneyfyPage(
            title: '자산 추이·통계',
            children: [Text(state.message ?? '계정 정보를 불러오고 있어요.')],
          );
        }
        return _StatisticsContent(key: ValueKey(state.version));
      },
    );
  }
}

class _StatisticsContent extends StatefulWidget {
  const _StatisticsContent({super.key});

  @override
  State<_StatisticsContent> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<_StatisticsContent> {
  late Future<_StatisticsSnapshotBundle> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadStatisticsSnapshotBundle();
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
          return MoneyfyPage(
            title: '자산 추이·통계',
            onRefresh: _refreshPage,
            children: const [_StatisticsLoadingBody()],
          );
        }

        if (snapshot.hasError) {
          return MoneyfyPage(
            title: '자산 추이·통계',
            onRefresh: _refreshPage,
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
          );
        }

        final bundle = snapshot.data ?? const _StatisticsSnapshotBundle.empty();
        final closingAssets = buildMonthlyClosingAssets(
          bundle.recentSnapshots,
          bundle.recentItems,
        );
        return MoneyfyPage(
          title: '자산 추이·통계',
          subtitle: '스냅샷과 기록을 기준으로 자산 흐름을 확인합니다.',
          onRefresh: _refreshPage,
          children: [
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
            SnapshotCalendarSection(
              snapshots: bundle.allSnapshots,
              transactionDates: bundle.transactionDates,
              sectionError: bundle.calendarError,
              onRetry: _refreshPage,
            ),
          ],
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
  final allSnapshots = await AppDatabase.instance.fetchRecentPortfolioSnapshots(
    maxDates: 240,
  );
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
    recentSnapshots: recentSnapshots,
    recentItems: recentItems,
    annualItems: annualItems,
    allSnapshots: allSnapshots,
    transactionDates: transactionDates,
    monthEndError: monthEndError,
    yearAnalysisError: annualItemsError,
    calendarError: transactionError,
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
        return buildCenteredStatisticsEmptyCard(
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

class _StatisticsSnapshotBundle {
  const _StatisticsSnapshotBundle({
    required this.recentSnapshots,
    required this.recentItems,
    required this.annualItems,
    required this.allSnapshots,
    required this.transactionDates,
    required this.monthEndError,
    required this.yearAnalysisError,
    required this.calendarError,
  });

  const _StatisticsSnapshotBundle.empty()
    : recentSnapshots = const [],
      recentItems = const [],
      annualItems = const [],
      allSnapshots = const [],
      transactionDates = const {},
      monthEndError = null,
      yearAnalysisError = null,
      calendarError = null;

  final List<DailyPortfolioSnapshot> recentSnapshots;
  final List<DailyPortfolioSnapshotItem> recentItems;
  final List<DailyPortfolioSnapshotItem> annualItems;
  final List<DailyPortfolioSnapshot> allSnapshots;
  final Set<String> transactionDates;
  final Object? monthEndError;
  final Object? yearAnalysisError;
  final Object? calendarError;
}
