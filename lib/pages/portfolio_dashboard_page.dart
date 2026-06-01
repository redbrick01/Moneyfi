import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/buttons/app_buttons.dart';
import '../components/chips/delta_chip.dart';
import '../components/chips/moneyfy_pill.dart';
import '../components/cards/investment_review_home_card.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/formatters/number_format.dart' as app_number;
import '../components/icons/app_icon.dart';
import '../components/icons/app_icon_button.dart';
import '../components/panels/app_floating_menu_surface.dart';
import '../components/panels/app_inner_panel.dart';
import '../components/rows/asset_row.dart';
import '../components/section_card.dart';
import '../components/separators/app_divider.dart';
import '../components/states/inline_error.dart';
import '../components/states/retry_row.dart';
import '../components/states/skeletons.dart';
import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../navigation/moneyfy_navigation.dart';
import '../navigation/moneyfy_routes.dart';
import '../services/auth_service.dart';
import '../services/investment_review/daily_investment_review_models.dart';
import '../services/investment_review/daily_investment_review_repository.dart';
import '../services/investment_review/investment_review_models.dart';
import '../services/investment_review/investment_review_snapshot_builder.dart';
import '../services/market_data_service.dart';
import '../services/portfolio_diagnosis_service.dart';
import '../ui_scaffold/app_page_scaffold.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';
import 'forms/asset_form_page.dart';
import 'investment_review_page.dart';

enum _AssetSortOption {
  custom('기본순', '사용자 지정 순서'),
  profitRateDesc('수익률 높은순', '수익률 기준'),
  profitRateAsc('수익률 낮은순', '수익률 기준'),
  profitDesc('수익 높은순', '손익 금액 기준'),
  profitAsc('수익 낮은순', '손익 금액 기준');

  const _AssetSortOption(this.label, this.description);

  final String label;
  final String description;
}

_DashboardSharedData? _dashboardSharedDataCache;
Future<_DashboardSharedData>? _dashboardSharedDataInFlight;

void _invalidateDashboardSharedDataCache() {
  _dashboardSharedDataCache = null;
  _dashboardSharedDataInFlight = null;
}

Future<_DashboardSharedData> _loadDashboardSharedData() async {
  final cached = _dashboardSharedDataCache;
  if (cached != null) return cached;

  final inFlight = _dashboardSharedDataInFlight;
  if (inFlight != null) return inFlight;

  final future = _fetchDashboardSharedData();
  _dashboardSharedDataInFlight = future;
  try {
    final resolved = await future;
    _dashboardSharedDataCache = resolved;
    return resolved;
  } finally {
    if (identical(_dashboardSharedDataInFlight, future)) {
      _dashboardSharedDataInFlight = null;
    }
  }
}

Future<_DashboardSharedData> _fetchDashboardSharedData() async {
  final assetsFuture = AppDatabase.instance.fetchAssets();
  final diagnosisFuture = PortfolioDiagnosisService.instance
      .fetchCachedDiagnosis();
  final assets = await assetsFuture;
  final diagnosis = await diagnosisFuture;
  return _DashboardSharedData(assets: assets, diagnosis: diagnosis?.diagnosis);
}

class _DashboardSharedData {
  const _DashboardSharedData({required this.assets, required this.diagnosis});

  final List<AssetItem> assets;
  final PortfolioDiagnosisResult? diagnosis;
}

class _TodayInvestmentReviewHomeData {
  const _TodayInvestmentReviewHomeData({
    required this.report,
    required this.reviewStatus,
  });

  final InvestmentReviewReport report;
  final DailyInvestmentReviewComposerStatus reviewStatus;
}

typedef TodayInvestmentReviewReportBuilder =
    Future<InvestmentReviewReport> Function();
typedef TodayInvestmentReviewLoader =
    Future<DailyInvestmentReviewEntry?> Function(DateTime date);
typedef InvestmentReviewPageBuilder = WidgetBuilder;

class PortfolioDashboardPage extends StatefulWidget {
  const PortfolioDashboardPage({
    super.key,
    this.scrollController,
    this.onOpenPortfolioDiagnosis,
    this.dataRefreshTick = 0,
    this.todayReviewBuilderForTesting,
    this.todayReviewLoaderForTesting,
    this.investmentReviewPageBuilderForTesting,
  });

  final ScrollController? scrollController;
  final VoidCallback? onOpenPortfolioDiagnosis;
  final int dataRefreshTick;
  final TodayInvestmentReviewReportBuilder? todayReviewBuilderForTesting;
  final TodayInvestmentReviewLoader? todayReviewLoaderForTesting;
  final InvestmentReviewPageBuilder? investmentReviewPageBuilderForTesting;

  @override
  State<PortfolioDashboardPage> createState() => _PortfolioDashboardPageState();
}

class _PortfolioDashboardPageState extends State<PortfolioDashboardPage> {
  _AssetSortOption _assetSortOption = _AssetSortOption.custom;
  late Future<_TodayInvestmentReviewHomeData> _todayReviewFuture;
  int _refreshTick = 0;
  bool _isEditMode = false;
  bool _isRefreshing = false;
  bool _hasVisibleAssets = true;

  @override
  void initState() {
    super.initState();
    _todayReviewFuture = _loadTodayReview();
  }

  void _markChanged() {
    if (!mounted) return;
    _invalidateDashboardSharedDataCache();
    setState(() {
      _todayReviewFuture = _loadTodayReview();
      _refreshTick++;
    });
  }

  Future<_TodayInvestmentReviewHomeData> _loadTodayReview() async {
    final testingBuilder = widget.todayReviewBuilderForTesting;
    if (testingBuilder != null) {
      final report = await testingBuilder();
      return _TodayInvestmentReviewHomeData(
        report: report,
        reviewStatus: await _loadTodayReviewStatus(report.period.from),
      );
    }

    final report = await InvestmentReviewSnapshotBuilder(
      database: AppDatabase.instance,
    ).build(InvestmentReviewPeriodType.today);
    return _TodayInvestmentReviewHomeData(
      report: report,
      reviewStatus: await _loadTodayReviewStatus(report.period.from),
    );
  }

  Future<DailyInvestmentReviewComposerStatus> _loadTodayReviewStatus(
    DateTime date,
  ) async {
    try {
      return _statusFromSavedReview(await _loadSavedTodayReview(date));
    } catch (_) {
      return DailyInvestmentReviewComposerStatus.draft;
    }
  }

  Future<DailyInvestmentReviewEntry?> _loadSavedTodayReview(DateTime date) {
    final testingLoader = widget.todayReviewLoaderForTesting;
    if (testingLoader != null) {
      return testingLoader(date);
    }
    if (widget.todayReviewBuilderForTesting != null) {
      return Future.value(null);
    }
    return DailyInvestmentReviewRepository(
      database: AppDatabase.instance,
    ).loadByDate(date);
  }

  DailyInvestmentReviewComposerStatus _statusFromSavedReview(
    DailyInvestmentReviewEntry? savedReview,
  ) {
    if (savedReview == null) {
      return DailyInvestmentReviewComposerStatus.draft;
    }
    return switch (savedReview.status) {
      DailyInvestmentReviewStatus.inProgress =>
        DailyInvestmentReviewComposerStatus.inProgress,
      DailyInvestmentReviewStatus.completed =>
        DailyInvestmentReviewComposerStatus.completed,
    };
  }

  void _openInvestmentReview() {
    unawaited(_openInvestmentReviewAndRefresh());
  }

  Future<void> _openInvestmentReviewAndRefresh() async {
    final pageBuilder =
        widget.investmentReviewPageBuilderForTesting ??
        (_) => const InvestmentReviewPage();
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: pageBuilder));
    if (!mounted) return;
    setState(() {
      _todayReviewFuture = _loadTodayReview();
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      _markChanged();
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isRefreshing = true;
    });
    try {
      await MarketDataService.instance.refreshAllMarketData();
      _markChanged();
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          '시세 새로고침에 실패했어요. 잠시 후 다시 시도해 주세요.',
          hasFloatingNavInset: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openAssetForm([AssetItem? item]) async {
    final bool? changed;
    if (item == null) {
      changed = await context.openAssetCreate();
    } else {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AssetFormPage(item: item)),
      );
    }

    if (changed == true) {
      _markChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '홈',
      titleWidget: const _MoneyfyHomeWordmark(),
      enablePullToRefresh: true,
      onRefresh: _refreshPage,
      hasFloatingNavInset: true,
      scrollController: widget.scrollController,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(
            refreshTick: _refreshTick,
            isRefreshing: _isRefreshing,
            onCreateAsset: _openAssetForm,
          ),
          SizedBox(height: context.spacing.xl),
          _AssetSectionBasePlate(
            sortOption: _assetSortOption,
            onSortChanged: (value) => setState(() => _assetSortOption = value),
            onAddPressed: () => _openAssetForm(),
            child: _AssetListCard(
              refreshTick: _refreshTick,
              sortOption: _assetSortOption,
              onChanged: _markChanged,
              onCreateAsset: _openAssetForm,
              isEditMode: _isEditMode,
              onItemsResolved: (count) {
                if (_hasVisibleAssets == (count > 0)) return;
                setState(() {
                  _hasVisibleAssets = count > 0;
                  if (!_hasVisibleAssets) {
                    _isEditMode = false;
                  }
                });
              },
            ),
          ),
          SizedBox(height: context.spacing.xl),
          FutureBuilder<_TodayInvestmentReviewHomeData>(
            future: _todayReviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data;
              if (data == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InvestmentReviewHomeCard(
                    report: data.report,
                    reviewStatus: data.reviewStatus,
                    onOpen: _openInvestmentReview,
                  ),
                  SizedBox(height: context.spacing.xl),
                ],
              );
            },
          ),
          _AnalysisSectionBasePlate(
            refreshTick: _refreshTick,
            child: _InsightCard(
              refreshTick: _refreshTick,
              onOpenPortfolioDiagnosis: widget.onOpenPortfolioDiagnosis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSectionBasePlate extends StatelessWidget {
  const _AssetSectionBasePlate({
    required this.child,
    required this.sortOption,
    required this.onSortChanged,
    required this.onAddPressed,
  });

  final Widget child;
  final _AssetSortOption sortOption;
  final ValueChanged<_AssetSortOption> onSortChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    const headerHeight = 56.0;
    final horizontalPadding = context.cardPadding();
    return SectionCard(
      variant: SectionCardVariant.base,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.cardPadding()),
          SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '자산',
                    style: context.typography.cardTitle.copyWith(
                      fontSize: context.fontSizes.s18,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<_AssetSortOption>(
                    tooltip: '정렬',
                    initialValue: sortOption,
                    onSelected: onSortChanged,
                    color: context.surfaces.surfaceBase,
                    surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                    elevation: 0,
                    offset: const Offset(0, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        VisualSpec.surface.radiusCard,
                      ),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    menuPadding: EdgeInsets.symmetric(
                      vertical: context.spacing.xs,
                    ),
                    constraints: const BoxConstraints(minWidth: 190),
                    icon: AppIcon(AppIconName.sort),
                    itemBuilder: (context) => [
                      PopupMenuItem<_AssetSortOption>(
                        enabled: false,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs,
                          vertical: context.spacing.xs / 2,
                        ),
                        child: _AssetSortMenuCard(selected: sortOption),
                      ),
                    ],
                  ),
                  SizedBox(width: context.spacing.xs),
                  SizedBox(
                    height: 24,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(width: context.spacing.xs),
                  AppIconButton(
                    tooltip: '자산 추가',
                    onPressed: onAddPressed,
                    icon: AppIconName.add,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.cardPadding(),
              context.cardPadding(),
              context.cardPadding(),
              context.cardPadding(),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AssetSortMenuCard extends StatelessWidget {
  const _AssetSortMenuCard({required this.selected});

  final _AssetSortOption selected;

  @override
  Widget build(BuildContext context) {
    return AppFloatingMenuSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (
            var index = 0;
            index < _AssetSortOption.values.length;
            index++
          ) ...[
            _AssetSortMenuRow(
              option: _AssetSortOption.values[index],
              selected: selected,
            ),
            if (index != _AssetSortOption.values.length - 1)
              const AppDivider(inset: 0),
          ],
        ],
      ),
    );
  }
}

class _AssetSortMenuRow extends StatelessWidget {
  const _AssetSortMenuRow({required this.option, required this.selected});

  final _AssetSortOption option;
  final _AssetSortOption selected;

  @override
  Widget build(BuildContext context) {
    final isSelected = option == selected;
    return InkWell(
      onTap: () => Navigator.of(context).pop<_AssetSortOption>(option),
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
                child: AppIcon(
                  isSelected ? AppIconName.check : AppIconName.circle,
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

class _AnalysisSectionBasePlate extends StatelessWidget {
  const _AnalysisSectionBasePlate({
    required this.child,
    required this.refreshTick,
  });

  final Widget child;
  final int refreshTick;

  @override
  Widget build(BuildContext context) {
    const headerHeight = 56.0;
    final horizontalPadding = context.cardPadding();
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.cardPadding()),
          SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '포트폴리오 진단',
                    style: context.typography.cardTitle.copyWith(
                      fontSize: context.fontSizes.s18,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<PortfolioDiagnosisCacheEntry?>(
                    key: ValueKey('analysis-risk-$refreshTick'),
                    future: PortfolioDiagnosisService.instance
                        .fetchCachedDiagnosis(),
                    builder: (context, snapshot) {
                      final cached = snapshot.data;
                      if (cached == null) {
                        return const SizedBox.shrink();
                      }
                      return _DashboardDiagnosisBadge(
                        riskLevel: cached.diagnosis.riskLevel,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.cardPadding(),
              context.cardPadding(),
              context.cardPadding(),
              context.cardPadding(),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MoneyfyHomeWordmark extends StatelessWidget {
  const _MoneyfyHomeWordmark();

  @override
  Widget build(BuildContext context) {
    final style = context.typography.pageTitle.copyWith(
      fontWeight: AppFontWeights.medium,
      letterSpacing: -0.4,
    );
    final colors = context.colors;

    return Semantics(
      header: true,
      label: 'Moneyfy',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'M',
                style: style.copyWith(color: colors.primary),
              ),
              TextSpan(
                text: 'oney',
                style: style.copyWith(color: colors.neutralText),
              ),
              TextSpan(
                text: 'f',
                style: style.copyWith(color: colors.positiveOn),
              ),
              TextSpan(
                text: 'y',
                style: style.copyWith(color: colors.neutralText),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({
    required this.refreshTick,
    required this.isRefreshing,
    required this.onCreateAsset,
  });

  final int refreshTick;
  final bool isRefreshing;
  final Future<void> Function([AssetItem? item]) onCreateAsset;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _isSummaryDetailExpanded = false;
  late Future<_SummaryCardData> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummaryCardData();
  }

  @override
  void didUpdateWidget(covariant _SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _summaryFuture = _loadSummaryCardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SummaryCardData>(
      key: ValueKey('summary-${widget.refreshTick}'),
      future: _summaryFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _SummaryCardData.empty();
        final totalValue = data.totalValue;
        final valuationProfit = data.valuationProfit;
        final valuationProfitRate = data.valuationProfitRate;
        final monthlyProfit = data.monthlyProfit;
        final monthlyProfitRate = data.monthlyProfitRate;
        final dailyProfit = data.dailyProfit;
        final dailyProfitRate = data.dailyProfitRate;
        final hasDailyComparison = data.hasDailyComparison;
        final usdKrwRate = data.usdKrwRate;
        final latestUpdatedAt = data.latestUpdatedAt;
        final isEmptyPortfolio = data.visibleAssetCount == 0 || totalValue <= 0;

        final valuationDisplayValue = _formatSignedCurrency(valuationProfit);
        final monthlyDisplayValue = _formatSignedCurrency(monthlyProfit);
        final dailyDisplayValue = hasDailyComparison
            ? _formatSignedCurrency(dailyProfit)
            : '-';

        return LayoutBuilder(
          builder: (context, constraints) {
            final heroWidth = constraints.maxWidth;
            final outerPadding = context.cardPadding();

            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: heroWidth,
                child: MoneyfySurfaceCard(
                  padding: EdgeInsets.all(outerPadding),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.spacing.xl,
                          ),
                          child: const SkeletonPresetCard(
                            preset: SkeletonCardPreset.homeSummary,
                          ),
                        )
                      : snapshot.hasError
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InlineError(
                              message: '네트워크 문제로 요약 정보를 불러오지 못했어요.',
                              detail: '다시 시도해 주세요.',
                            ),
                            SizedBox(height: context.spacing.sm),
                            RetryRow(
                              message: '요약을 다시 불러오려면 재시도를 눌러주세요.',
                              onRetry: () {
                                setState(() {
                                  _summaryFuture = _loadSummaryCardData();
                                });
                              },
                            ),
                          ],
                        )
                      : isEmptyPortfolio
                      ? _DashboardEmptyInnerPanel(
                          title: '자산을 추가해 시작해요',
                          description: '주식/펀드/코인/현금을 등록하면 총자산과 비중을 자동으로 계산해요.',
                          icon: AppIconName.wallet,
                          actionLabel: '자산 추가',
                          onAction: () => widget.onCreateAsset(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '총 자산',
                                    style: context.typography.body.copyWith(
                                      fontSize: context.fontSizes.s18,
                                      fontWeight: AppFontWeights.semibold,
                                    ),
                                  ),
                                ),
                                MoneyfyBadge(
                                  label: usdKrwRate == null
                                      ? 'USD/KRW -'
                                      : 'USD/KRW ${app_number.formatCurrency(usdKrwRate, fractionDigits: 2)}',
                                  size: MoneyfyPillSize.md,
                                  backgroundColor: context.surfaces.surfaceBase,
                                  textColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            SizedBox(height: context.spacing.lg),
                            SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatCurrency(totalValue),
                                  textAlign: TextAlign.right,
                                  style: context.typography.heroNumber.copyWith(
                                    fontSize: context.fontSizes.s32,
                                    fontWeight: AppFontWeights.semibold,
                                    height: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: context.spacing.md),
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                final innerCardWidth =
                                    innerConstraints.maxWidth;
                                return Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: innerCardWidth,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragStart: (_) {},
                                      onVerticalDragEnd: (details) {
                                        final velocity =
                                            details.primaryVelocity ?? 0;
                                        if (velocity > 120 &&
                                            !_isSummaryDetailExpanded) {
                                          setState(() {
                                            _isSummaryDetailExpanded = true;
                                          });
                                        } else if (velocity < -120 &&
                                            _isSummaryDetailExpanded) {
                                          setState(() {
                                            _isSummaryDetailExpanded = false;
                                          });
                                        }
                                      },
                                      child: AnimatedSize(
                                        duration: context.motion.fast,
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topCenter,
                                        child: AppInnerPanel(
                                          padding: EdgeInsets.all(
                                            context.cardPadding(),
                                          ),
                                          child: Column(
                                            children: [
                                              _SummaryValueRow(
                                                label: '평가 손익',
                                                valueText:
                                                    valuationDisplayValue,
                                                valueColor: _signedDisplayColor(
                                                  context,
                                                  valuationDisplayValue,
                                                  defaultColor: context
                                                      .colors
                                                      .neutralTextMuted,
                                                ),
                                                chip: DeltaChip(
                                                  value: valuationProfit,
                                                  percent: valuationProfitRate,
                                                  mode: DeltaChipMode.percent,
                                                  vivid: true,
                                                ),
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
                                                child: _isSummaryDetailExpanded
                                                    ? Column(
                                                        key: const ValueKey(
                                                          'summary-expanded',
                                                        ),
                                                        children: [
                                                          SizedBox(
                                                            height: context
                                                                .spacing
                                                                .md,
                                                          ),
                                                          _SummaryValueRow(
                                                            label: '전월 대비 수익',
                                                            valueText:
                                                                monthlyDisplayValue,
                                                            valueColor: _signedDisplayColor(
                                                              context,
                                                              monthlyDisplayValue,
                                                              defaultColor: context
                                                                  .colors
                                                                  .neutralTextMuted,
                                                            ),
                                                            chip: DeltaChip(
                                                              value:
                                                                  monthlyProfit,
                                                              percent:
                                                                  monthlyProfitRate,
                                                              mode:
                                                                  DeltaChipMode
                                                                      .percent,
                                                              vivid: true,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: context
                                                                .spacing
                                                                .md,
                                                          ),
                                                          _SummaryValueRow(
                                                            label: '전일 대비 수익',
                                                            valueText:
                                                                dailyDisplayValue,
                                                            valueColor: _signedDisplayColor(
                                                              context,
                                                              dailyDisplayValue,
                                                              defaultColor: context
                                                                  .colors
                                                                  .neutralTextMuted,
                                                            ),
                                                            chip:
                                                                hasDailyComparison
                                                                ? DeltaChip(
                                                                    value:
                                                                        dailyProfit,
                                                                    percent:
                                                                        dailyProfitRate,
                                                                    mode: DeltaChipMode
                                                                        .percent,
                                                                    vivid: true,
                                                                  )
                                                                : const _SummaryDashChip(),
                                                          ),
                                                        ],
                                                      )
                                                    : const SizedBox(
                                                        key: ValueKey(
                                                          'summary-collapsed',
                                                        ),
                                                      ),
                                              ),
                                              SizedBox(
                                                height: context.spacing.sm,
                                              ),
                                              const AppDivider(inset: 0),
                                              SizedBox(
                                                height: context.spacing.sm,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    latestUpdatedAt == null
                                                        ? (widget.isRefreshing
                                                              ? '업데이트 중…'
                                                              : '-')
                                                        : widget.isRefreshing
                                                        ? '${_formatTimestamp(latestUpdatedAt)} · 업데이트 중…'
                                                        : _formatTimestamp(
                                                            latestUpdatedAt,
                                                          ),
                                                    style: context
                                                        .typography
                                                        .caption
                                                        .copyWith(
                                                          fontSize: context
                                                              .fontSizes
                                                              .s12,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow({
    required this.label,
    required this.valueText,
    required this.valueColor,
    required this.chip,
  });

  final String label;
  final String valueText;
  final Color valueColor;
  final Widget chip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.typography.caption.copyWith(
              fontSize: context.fontSizes.s16,
              fontWeight: AppFontWeights.semibold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          valueText,
          style: context.typography.caption.copyWith(
            fontSize: context.fontSizes.s16,
            fontWeight: AppFontWeights.semibold,
            color: valueColor,
          ),
        ),
        SizedBox(width: context.spacing.xs),
        chip,
      ],
    );
  }
}

class _SummaryDashChip extends StatelessWidget {
  const _SummaryDashChip();

  @override
  Widget build(BuildContext context) {
    return MoneyfyBadge(
      label: '-',
      size: MoneyfyPillSize.sm,
      variant: MoneyfyPillVariant.outline,
      backgroundColor: context.surfaces.surfaceBase,
      textColor: context.colors.neutralTextMuted,
    );
  }
}

Future<_SummaryCardData> _loadSummaryCardData() async {
  final sharedData = await _loadDashboardSharedData();
  final items = sharedData.assets
      .where((asset) => !asset.isHidden)
      .toList(growable: false);
  final visibleAssetIds = items
      .map((asset) => asset.id)
      .whereType<int>()
      .toSet();
  final visibleAssetTitles = items
      .expand((asset) => [asset.title, asset.displayName])
      .map(_normalizeVisibleSnapshotAssetTitle)
      .where((value) => value.isNotEmpty)
      .toSet();
  final usdKrwRate = await AppDatabase.instance.fetchLatestExchangeRate();
  final totalValue = items.fold<double>(
    0,
    (sum, asset) => sum + asset.totalValuationAmount,
  );
  final totalPurchase = items.fold<double>(
    0,
    (sum, asset) => sum + asset.totalPurchaseAmount,
  );
  final previousDayComparison = await _resolvePreviousDayComparison(
    DateTime.now(),
    visibleAssetIds: visibleAssetIds,
    visibleAssetTitles: visibleAssetTitles,
  );
  final previousDaySnapshotValue = previousDayComparison.previousValue ?? 0;

  double previousSnapshotValue = totalValue;
  String? resolvedMonthlyComparisonDate;
  final comparisonSnapshotDate = _previousMonthComparisonDate(DateTime.now());
  final comparisonItems = await _fetchVisibleSnapshotSummaryItemsByDates(
    [comparisonSnapshotDate],
    visibleAssetIds: visibleAssetIds,
    visibleAssetTitles: visibleAssetTitles,
  );
  if (comparisonItems.isNotEmpty) {
    resolvedMonthlyComparisonDate = comparisonSnapshotDate;
    previousSnapshotValue = comparisonItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValuationAmount,
    );
  } else {
    final latestSnapshot = await AppDatabase.instance
        .fetchPortfolioSnapshotByDate(_snapshotDate(DateTime.now()));
    final latestSnapshotDate = latestSnapshot?.snapshotDate;
    if (latestSnapshotDate != null) {
      final previousSnapshot = await AppDatabase.instance
          .fetchPreviousPortfolioSnapshot(latestSnapshotDate);
      if (previousSnapshot != null) {
        resolvedMonthlyComparisonDate = previousSnapshot.snapshotDate;
        final previousDisplayItems =
            await _fetchVisibleSnapshotSummaryItemsByDates(
              [previousSnapshot.snapshotDate],
              visibleAssetIds: visibleAssetIds,
              visibleAssetTitles: visibleAssetTitles,
            );
        previousSnapshotValue = previousDisplayItems.fold<double>(
          0,
          (sum, item) => sum + item.totalValuationAmount,
        );
      } else {
        previousSnapshotValue = previousDaySnapshotValue;
      }
    } else {
      previousSnapshotValue = previousDaySnapshotValue;
    }
  }
  DateTime? latestUpdatedAt;
  for (final asset in items) {
    for (final holding in asset.visibleHoldings) {
      final text = holding.marketUpdatedAt;
      if (text == null || text.isEmpty) continue;
      final parsed = DateTime.tryParse(text);
      if (parsed == null) continue;
      if (latestUpdatedAt == null || parsed.isAfter(latestUpdatedAt)) {
        latestUpdatedAt = parsed;
      }
    }
  }

  return _SummaryCardData(
    visibleAssetCount: items.length,
    totalValue: totalValue,
    valuationProfit: totalValue - totalPurchase,
    valuationProfitRate: totalPurchase == 0
        ? 0
        : ((totalValue - totalPurchase) / totalPurchase) * 100,
    monthlyProfit: totalValue - previousSnapshotValue,
    monthlyProfitRate: previousSnapshotValue == 0
        ? 0
        : ((totalValue - previousSnapshotValue) / previousSnapshotValue) * 100,
    monthlyComparisonDate: resolvedMonthlyComparisonDate,
    dailyProfit: totalValue - previousDaySnapshotValue,
    dailyProfitRate: previousDaySnapshotValue == 0
        ? 0
        : ((totalValue - previousDaySnapshotValue) / previousDaySnapshotValue) *
              100,
    hasDailyComparison: previousDayComparison.previousValue != null,
    dailyComparisonDate: previousDayComparison.snapshotDate,
    usdKrwRate: usdKrwRate,
    latestUpdatedAt: latestUpdatedAt,
  );
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

String _previousDaySnapshotDate(DateTime date) {
  final previousDay = date.subtract(const Duration(days: 1));
  return _snapshotDate(previousDay);
}

Future<_PreviousDayComparison> _resolvePreviousDayComparison(
  DateTime date, {
  required Set<int> visibleAssetIds,
  required Set<String> visibleAssetTitles,
}) async {
  final previousDayDate = _previousDaySnapshotDate(date);
  final previousDayItems = await _fetchVisibleSnapshotSummaryItemsByDates(
    [previousDayDate],
    visibleAssetIds: visibleAssetIds,
    visibleAssetTitles: visibleAssetTitles,
  );
  if (previousDayItems.isNotEmpty) {
    return _PreviousDayComparison(
      previousValue: previousDayItems.fold<double>(
        0,
        (sum, item) => sum + item.totalValuationAmount,
      ),
      snapshotDate: previousDayDate,
    );
  }

  final twoDaysAgoDate = _snapshotDate(date.subtract(const Duration(days: 2)));
  final twoDaysAgoItems = await _fetchVisibleSnapshotSummaryItemsByDates(
    [twoDaysAgoDate],
    visibleAssetIds: visibleAssetIds,
    visibleAssetTitles: visibleAssetTitles,
  );
  if (twoDaysAgoItems.isNotEmpty) {
    return _PreviousDayComparison(
      previousValue: twoDaysAgoItems.fold<double>(
        0,
        (sum, item) => sum + item.totalValuationAmount,
      ),
      snapshotDate: twoDaysAgoDate,
    );
  }

  return const _PreviousDayComparison(previousValue: null, snapshotDate: null);
}

Future<List<DailyPortfolioSnapshotItem>>
_fetchVisibleSnapshotSummaryItemsByDates(
  List<String> snapshotDates, {
  required Set<int> visibleAssetIds,
  required Set<String> visibleAssetTitles,
}) async {
  if (snapshotDates.isEmpty) return const [];
  final rows = await AppDatabase.instance.fetchPortfolioSnapshotItemsByDates(
    snapshotDates,
  );
  return rows
      .where(
        (item) =>
            visibleAssetIds.contains(item.assetId) ||
            visibleAssetTitles.contains(
              _normalizeVisibleSnapshotAssetTitle(item.assetTitle),
            ),
      )
      .toList(growable: false);
}

String _normalizeVisibleSnapshotAssetTitle(String value) {
  return value.trim().toLowerCase();
}

class _PreviousDayComparison {
  const _PreviousDayComparison({
    required this.previousValue,
    required this.snapshotDate,
  });

  final double? previousValue;
  final String? snapshotDate;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.visibleAssetCount,
    required this.totalValue,
    required this.valuationProfit,
    required this.valuationProfitRate,
    required this.monthlyProfit,
    required this.monthlyProfitRate,
    required this.monthlyComparisonDate,
    required this.dailyProfit,
    required this.dailyProfitRate,
    required this.hasDailyComparison,
    required this.dailyComparisonDate,
    required this.usdKrwRate,
    required this.latestUpdatedAt,
  });

  const _SummaryCardData.empty()
    : visibleAssetCount = 0,
      totalValue = 0,
      valuationProfit = 0,
      valuationProfitRate = 0,
      monthlyProfit = 0,
      monthlyProfitRate = 0,
      monthlyComparisonDate = null,
      dailyProfit = 0,
      dailyProfitRate = 0,
      hasDailyComparison = false,
      dailyComparisonDate = null,
      usdKrwRate = null,
      latestUpdatedAt = null;

  final int visibleAssetCount;
  final double totalValue;
  final double valuationProfit;
  final double valuationProfitRate;
  final double monthlyProfit;
  final double monthlyProfitRate;
  final String? monthlyComparisonDate;
  final double dailyProfit;
  final double dailyProfitRate;
  final bool hasDailyComparison;
  final String? dailyComparisonDate;
  final double? usdKrwRate;
  final DateTime? latestUpdatedAt;
}

String _formatTimestamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

class _AssetListCard extends StatefulWidget {
  static const double _kAssetRowHeight = 72;
  static const double _kAssetDividerHeight = 1;
  static const double _kAssetIconBoxSize = 34;
  static const double _kAssetIconSize = 20;
  static const double _kAssetLeadingSlotWidth = 46;
  static const String _kSlidableGroupTag = 'dashboard_asset_slidable_group';

  const _AssetListCard({
    required this.refreshTick,
    required this.sortOption,
    required this.onChanged,
    required this.onCreateAsset,
    required this.isEditMode,
    required this.onItemsResolved,
  });

  final int refreshTick;
  final _AssetSortOption sortOption;
  final VoidCallback onChanged;
  final Future<void> Function([AssetItem? item]) onCreateAsset;
  final bool isEditMode;
  final ValueChanged<int> onItemsResolved;

  @override
  State<_AssetListCard> createState() => _AssetListCardState();
}

class _AssetListCardState extends State<_AssetListCard> {
  List<AssetItem>? _items;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadItems(showLoading: true);
  }

  @override
  void didUpdateWidget(covariant _AssetListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadItems(showLoading: false);
    }
  }

  Future<void> _loadItems({required bool showLoading}) async {
    if (showLoading || _items == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final fetched = await AppDatabase.instance.fetchAssets();
      final filtered = fetched
          .where(
            (item) => item.holdings.isEmpty || item.visibleHoldings.isNotEmpty,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_items == null) {
          _error = error;
        }
      });
    }
  }

  AssetItem _copyAssetWithHidden(AssetItem item, bool isHidden) {
    return AssetItem(
      id: item.id,
      clientId: item.clientId,
      assetType: item.assetType,
      title: item.title,
      alias: item.alias,
      isHidden: isHidden,
      currencyCode: item.currencyCode,
      value: item.value,
      change: item.change,
      icon: item.icon,
      quantityLabel: item.quantityLabel,
      quantityValue: item.quantityValue,
      averageLabel: item.averageLabel,
      averageValue: item.averageValue,
      note: item.note,
      holdings: item.holdings,
      transactions: item.transactions,
    );
  }

  Future<void> _reorderAssets(
    List<AssetItem> visibleItems,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final previousItems = _items == null
        ? null
        : List<AssetItem>.from(_items!, growable: false);

    final reorderedVisible = List<AssetItem>.from(visibleItems);
    final moved = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(newIndex, moved);

    final hiddenItems = (_items ?? const <AssetItem>[])
        .where((item) => item.isHidden)
        .toList(growable: false);
    final optimisticItems = <AssetItem>[...reorderedVisible, ...hiddenItems];

    setState(() {
      _items = optimisticItems;
    });

    final assetIds = optimisticItems
        .map((item) => item.id)
        .whereType<int>()
        .toList(growable: false);
    if (assetIds.length != optimisticItems.length) {
      await _loadItems(showLoading: false);
      return;
    }

    try {
      final currentAssetIds = <int>[];
      for (final item in optimisticItems) {
        final currentId = await _resolveCurrentAssetId(item);
        if (currentId != null) currentAssetIds.add(currentId);
      }
      if (currentAssetIds.length != optimisticItems.length) {
        await _loadItems(showLoading: false);
        return;
      }
      await AppDatabase.instance.reorderAssets(currentAssetIds);
    } catch (_) {
      if (!mounted) return;
      if (previousItems != null) {
        setState(() {
          _items = previousItems;
        });
      } else {
        await _loadItems(showLoading: false);
      }
    }
  }

  Future<void> _toggleAssetHidden(AssetItem item) async {
    final id = await _resolveCurrentAssetId(item);
    if (id == null) return;
    final previousItems = _items == null
        ? null
        : List<AssetItem>.from(_items!, growable: false);
    setState(() {
      final current = _items ?? const <AssetItem>[];
      _items = current
          .map(
            (asset) => asset.id == id
                ? _copyAssetWithHidden(asset, !asset.isHidden)
                : asset,
          )
          .toList(growable: false);
    });
    try {
      await AppDatabase.instance.updateAssetHidden(id, !item.isHidden);
      widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      if (previousItems != null) {
        setState(() {
          _items = previousItems;
        });
      } else {
        await _loadItems(showLoading: false);
      }
    }
  }

  Future<int?> _resolveCurrentAssetId(AssetItem item) async {
    final id = item.id;
    if (id != null) {
      final byId = await AppDatabase.instance.fetchAssetById(id);
      if (byId?.id != null) return byId!.id;
    }

    final clientId = item.clientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      final byClientId = await AppDatabase.instance.fetchAssetByClientId(
        clientId,
      );
      if (byClientId?.id != null) return byClientId!.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortAssets(List<AssetItem>.from(_items ?? const []));
    final visibleItems = sortedItems
        .where((item) => !item.isHidden)
        .toList(growable: false);
    final hiddenItems = sortedItems
        .where((item) => item.isHidden)
        .toList(growable: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onItemsResolved(visibleItems.length);
    });

    if (_loading && _items == null) {
      return MoneyfySurfaceCard(
        variant: MoneyfySurfaceCardVariant.base,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding()),
          child: const SkeletonList(
            rows: 4,
            rowHeight: _AssetListCard._kAssetRowHeight,
            hasLeading: true,
            trailingLines: 2,
          ),
        ),
      );
    }

    if (_error != null && _items == null) {
      return MoneyfySurfaceCard(
        variant: MoneyfySurfaceCardVariant.base,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InlineError(
                message: '자산 목록을 불러오지 못했어요.',
                detail: '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
              ),
              SizedBox(height: context.spacing.sm),
              RetryRow(
                message: '목록을 다시 조회하려면 재시도를 눌러주세요.',
                onRetry: () => _loadItems(showLoading: true),
              ),
            ],
          ),
        ),
      );
    }

    if (sortedItems.isEmpty) {
      final isLoggedIn = AuthService.currentUser != null;
      if (!isLoggedIn) {
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
                child: AppInnerPanel(
                  padding: EdgeInsets.zero,
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.66),
                          ),
                          SizedBox(height: context.spacing.sm),
                          Text(
                            '자산이 아직 없어요',
                            textAlign: TextAlign.center,
                            style: context.typography.cardTitle.copyWith(
                              fontWeight: AppFontWeights.semibold,
                            ),
                          ),
                          SizedBox(height: context.spacing.xs),
                          Text(
                            '첫 자산군을 만들고 보유 종목이나 현금 계좌를 추가해 보세요.',
                            textAlign: TextAlign.center,
                            style: context.typography.meta,
                          ),
                          SizedBox(height: context.spacing.md),
                          AppPrimaryButton(
                            label: '자산 추가',
                            onPressed: () => widget.onCreateAsset(),
                            expand: true,
                          ),
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
      return AppInnerPanel(
        padding: EdgeInsets.zero,
        child: _DashboardEmptyContent(
          title: '자산이 아직 없어요',
          description: '첫 자산군을 만들고 보유 종목이나 현금 계좌를 추가해 보세요.',
          icon: AppIconName.insights,
          actionLabel: '자산 추가',
          onAction: () => widget.onCreateAsset(),
        ),
      );
    }

    final frontCard = visibleItems.isEmpty
        ? _buildAssetCard(context, hiddenItems, reorderable: true)
        : _buildAssetCard(context, visibleItems, reorderable: true);
    if (hiddenItems.isEmpty || visibleItems.isEmpty) {
      return frontCard;
    }

    final frontHeight = _assetCardHeight(
      rowCount: visibleItems.length,
      includeLeadingEmptySlot: false,
    );
    final hiddenHeight = _assetCardHeight(
      rowCount: hiddenItems.length,
      includeLeadingEmptySlot: true,
    );
    final overlapHeight = _AssetListCard._kAssetRowHeight;
    final hiddenTop = frontHeight - overlapHeight;
    final totalHeight = frontHeight + hiddenHeight - overlapHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: hiddenTop,
            child: _buildAssetCard(
              context,
              hiddenItems,
              leadingEmptySlot: true,
            ),
          ),
          Positioned(left: 0, right: 0, top: 0, child: frontCard),
        ],
      ),
    );
  }

  double _assetCardHeight({
    required int rowCount,
    required bool includeLeadingEmptySlot,
  }) {
    final totalRows = rowCount + (includeLeadingEmptySlot ? 1 : 0);
    if (totalRows <= 0) return 0;
    return (totalRows * _AssetListCard._kAssetRowHeight) +
        ((totalRows - 1) * _AssetListCard._kAssetDividerHeight);
  }

  Widget _buildAssetCard(
    BuildContext context,
    List<AssetItem> items, {
    bool reorderable = false,
    bool leadingEmptySlot = false,
  }) {
    return AppInnerPanel(
      padding: EdgeInsets.zero,
      child: SlidableAutoCloseBehavior(
        child: reorderable
            ? ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderAssets(items, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildListItem(context, items, item, index);
                },
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length + (leadingEmptySlot ? 1 : 0),
                itemBuilder: (context, index) {
                  if (leadingEmptySlot && index == 0) {
                    return const _HiddenAssetEmptySlot();
                  }
                  final item = items[index - (leadingEmptySlot ? 1 : 0)];
                  return _buildRow(
                    context,
                    item,
                    index,
                    isReorderTarget: false,
                  );
                },
                separatorBuilder: (_, _) => AppDivider(),
              ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    List<AssetItem> items,
    AssetItem item,
    int index,
  ) {
    return Column(
      key: ValueKey(item.id ?? '${item.displayName}-$index'),
      children: [
        _buildRow(context, item, index, isReorderTarget: true),
        if (index != items.length - 1) AppDivider(),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    AssetItem item,
    int index, {
    required bool isReorderTarget,
  }) {
    if (widget.isEditMode) {
      return _AssetRow(
        item: item,
        index: index,
        onChanged: widget.onChanged,
        isEditMode: true,
        onToggleHidden: () => _toggleAssetHidden(item),
      );
    }
    if (isReorderTarget) {
      return ReorderableDelayedDragStartListener(
        index: index,
        child: _AssetRow(
          item: item,
          index: index,
          onChanged: widget.onChanged,
          isEditMode: false,
          onToggleHidden: () => _toggleAssetHidden(item),
        ),
      );
    }
    return _AssetRow(
      item: item,
      index: index,
      onChanged: widget.onChanged,
      isEditMode: false,
      onToggleHidden: () => _toggleAssetHidden(item),
    );
  }

  List<AssetItem> _sortAssets(List<AssetItem> items) {
    final sorted = List<AssetItem>.from(items);
    switch (widget.sortOption) {
      case _AssetSortOption.custom:
        return sorted;
      case _AssetSortOption.profitRateDesc:
        sorted.sort(
          (a, b) => _assetProfitRate(b).compareTo(_assetProfitRate(a)),
        );
        return sorted;
      case _AssetSortOption.profitRateAsc:
        sorted.sort(
          (a, b) => _assetProfitRate(a).compareTo(_assetProfitRate(b)),
        );
        return sorted;
      case _AssetSortOption.profitDesc:
        sorted.sort(
          (a, b) => _assetProfitAmount(b).compareTo(_assetProfitAmount(a)),
        );
        return sorted;
      case _AssetSortOption.profitAsc:
        sorted.sort(
          (a, b) => _assetProfitAmount(a).compareTo(_assetProfitAmount(b)),
        );
        return sorted;
    }
  }

  double _assetProfitAmount(AssetItem item) {
    return item.totalProfitAmount;
  }

  double _assetProfitRate(AssetItem item) {
    final purchaseAmount = item.totalPurchaseAmount;
    if (purchaseAmount == 0) return 0;
    return (_assetProfitAmount(item) / purchaseAmount) * 100;
  }
}

class _HiddenAssetEmptySlot extends StatelessWidget {
  const _HiddenAssetEmptySlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: _AssetListCard._kAssetRowHeight);
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.isEditMode,
    required this.onToggleHidden,
  });

  final AssetItem item;
  final int index;
  final VoidCallback onChanged;
  final bool isEditMode;
  final Future<void> Function() onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final showSecondaryValue = item.assetType != '현금';
    final rowChild = AssetRow(
      minHeight: _AssetListCard._kAssetRowHeight,
      leadingSlotWidth: _AssetListCard._kAssetLeadingSlotWidth,
      leading: Container(
        width: _AssetListCard._kAssetIconBoxSize,
        height: _AssetListCard._kAssetIconBoxSize,
        decoration: BoxDecoration(
          color: context.surfaces.surfaceRaised,
          borderRadius: BorderRadius.circular(context.radius.rMd),
        ),
        child: AppIcon.raw(
          item.icon,
          size: _AssetListCard._kAssetIconSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: item.displayName,
      subtitle: null,
      amountText: item.value,
      deltaChip: showSecondaryValue
          ? _AssetProfitLine(
              profitAmount: item.totalProfitAmount,
              profitRate: item.totalProfitRate,
            )
          : null,
      isHidden: item.isHidden,
      showChevron: false,
      onTap: isEditMode
          ? null
          : () async {
              if (item.id == null) return;
              await context.openAssetDetail(
                AssetDetailRouteArgs(
                  assetId: item.id!,
                  assetClientId: item.clientId,
                ),
              );
              onChanged();
            },
      trailingAccessory: isEditMode
          ? AnimatedOpacity(
              duration: context.motion.fast,
              curve: Curves.easeOut,
              opacity: isEditMode ? 1 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    tooltip: item.isHidden ? '숨김 해제' : '숨김',
                    onPressed: onToggleHidden,
                    icon: item.isHidden
                        ? AppIconName.visibilityOn
                        : AppIconName.visibilityOff,
                    size: context.spacing.md + 2,
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: AppIcon(
                      AppIconName.dragHandle,
                      size: context.spacing.lg,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );

    final visibleRow = Opacity(
      opacity: item.isHidden ? 0.6 : 1,
      child: item.isHidden
          ? ClipRRect(
              borderRadius: BorderRadius.circular(context.radius.rMd),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 3.6, sigmaY: 3.6),
                child: rowChild,
              ),
            )
          : rowChild,
    );

    if (isEditMode) {
      return visibleRow;
    }

    return Slidable(
      key: ValueKey('asset-slide-${item.id ?? item.displayName}'),
      groupTag: _AssetListCard._kSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: () => onToggleHidden(),
        icon: item.isHidden
            ? VisualSpec.icon.visibilityOn
            : VisualSpec.icon.visibilityOff,
        iconColor: context.colors.neutralTextMuted,
      ),
      child: visibleRow,
    );
  }
}

class _AssetProfitLine extends StatelessWidget {
  const _AssetProfitLine({
    required this.profitAmount,
    required this.profitRate,
  });

  final double profitAmount;
  final double profitRate;

  @override
  Widget build(BuildContext context) {
    final profitText = _formatSignedCurrency(profitAmount);
    final amountColor = _signedDisplayColor(
      context,
      profitText,
      defaultColor: context.colors.neutralTextMuted,
    );

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
                style: context.typography.caption.copyWith(
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
          compact: true,
        ),
      ],
    );
  }
}

class _DashboardEmptyInnerPanel extends StatelessWidget {
  const _DashboardEmptyInnerPanel({
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final AppIconName icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      child: _DashboardEmptyContent(
        title: title,
        description: description,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

class _DashboardEmptyContent extends StatelessWidget {
  const _DashboardEmptyContent({
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final AppIconName icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIcon(
            icon,
            size: VisualSpec.icon.iconSizeLarge,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
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
              label: actionLabel!,
              onPressed: onAction,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.refreshTick,
    this.onOpenPortfolioDiagnosis,
  });

  final int refreshTick;
  final VoidCallback? onOpenPortfolioDiagnosis;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InsightCardData>(
      key: ValueKey('insight-$refreshTick'),
      future: _loadInsightCardData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _InsightCardData.empty();
        final items = data.assets
            .where((item) => !item.isHidden)
            .where((item) => item.visibleHoldings.isNotEmpty)
            .toList(growable: false);
        return snapshot.connectionState == ConnectionState.waiting
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
                child: const SkeletonCard(height: 120),
              )
            : _InsightCardContent(
                items: items,
                diagnosis: data.diagnosis,
                onOpenPortfolioDiagnosis: onOpenPortfolioDiagnosis,
              );
      },
    );
  }
}

class _InsightCardContent extends StatelessWidget {
  const _InsightCardContent({
    required this.items,
    required this.diagnosis,
    this.onOpenPortfolioDiagnosis,
  });

  final List<AssetItem> items;
  final PortfolioDiagnosisResult? diagnosis;
  final VoidCallback? onOpenPortfolioDiagnosis;

  @override
  Widget build(BuildContext context) {
    final totals = {
      for (final asset in items) asset.displayName: asset.totalValuationAmount,
    };
    final totalValue = totals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final dominant = totals.entries.isEmpty
        ? null
        : totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final ratio = dominant == null || totalValue == 0
        ? 0.0
        : (dominant.value / totalValue) * 100;

    if (dominant == null && diagnosis == null) {
      return AppInnerPanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIcon(
                AppIconName.lightbulb,
                size: VisualSpec.icon.iconSizeLarge,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                '인사이트를 준비 중이에요',
                textAlign: TextAlign.center,
                style: context.typography.cardTitle.copyWith(
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                '자산 데이터를 모으면 집중도와 리밸런싱 신호를 보여드릴게요.',
                textAlign: TextAlign.center,
                style: context.typography.meta,
              ),
            ],
          ),
        ),
      );
    }

    if (diagnosis != null) {
      final firstSentence = _firstSentence(diagnosis!.summary);

      return AppInnerPanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radius.rMd),
          onTap: onOpenPortfolioDiagnosis,
          child: Padding(
            padding: EdgeInsets.all(
              context.spacing.sm + context.spacing.xs / 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DiagnosisScoreDonut(
                  score: diagnosis!.score,
                  riskLevel: diagnosis!.riskLevel,
                ),
                SizedBox(width: context.spacing.lg),
                Expanded(
                  child: Text(
                    firstSentence,
                    style: context.typography.meta.copyWith(
                      fontSize: context.fontSizes.s16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppInnerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dominant != null) ...[
            Text(
              '${dominant.key} 비중이 가장 높습니다',
              style: context.typography.cardTitle.copyWith(
                fontWeight: AppFontWeights.semibold,
              ),
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              '현재 ${dominant.key} 비중은 ${ratio.toStringAsFixed(1)}%입니다. 리밸런싱 필요 여부를 점검하세요.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.typography.meta,
            ),
            SizedBox(height: context.spacing.sm),
          ],
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              if (dominant != null)
                const MoneyfyBadge(label: '집중도', size: MoneyfyPillSize.sm),
              if (dominant != null)
                const MoneyfyBadge(label: '리밸런싱', size: MoneyfyPillSize.sm),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Text('DB 기준 비중 분석', style: context.typography.caption),
        ],
      ),
    );
  }
}

class _DashboardDiagnosisBadge extends StatelessWidget {
  const _DashboardDiagnosisBadge({required this.riskLevel});

  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (riskLevel) {
      '낮음' => context.colors.positiveOn,
      '높음' => context.colors.negativeOn,
      _ => context.colors.warningOn,
    };
    return MoneyfyBadge(
      label: '리스크 $riskLevel',
      size: MoneyfyPillSize.md,
      backgroundColor: color.withValues(alpha: 0.14),
      textColor: color,
    );
  }
}

class _DiagnosisScoreDonut extends StatelessWidget {
  const _DiagnosisScoreDonut({required this.score, required this.riskLevel});

  final int score;
  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final normalizedScore = (score.clamp(0, 100)) / 100;
    final color = switch (riskLevel) {
      '낮음' => context.colors.positiveOn,
      '높음' => context.colors.negativeOn,
      _ => context.colors.warningOn,
    };

    return SizedBox(
      width: VisualSpec.icon.iconSizeLarge,
      height: VisualSpec.icon.iconSizeLarge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: VisualSpec.icon.iconSizeLarge,
            height: VisualSpec.icon.iconSizeLarge,
            child: CircularProgressIndicator(
              value: normalizedScore.toDouble(),
              strokeWidth: context.spacing.xs - 2,
              strokeCap: StrokeCap.round,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$score',
            style: context.typography.cardTitle.copyWith(
              fontSize: context.fontSizes.s16,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<_InsightCardData> _loadInsightCardData() async {
  final sharedData = await _loadDashboardSharedData();
  return _InsightCardData(
    assets: sharedData.assets,
    diagnosis: sharedData.diagnosis,
  );
}

class _InsightCardData {
  const _InsightCardData({required this.assets, this.diagnosis});

  const _InsightCardData.empty() : assets = const [], diagnosis = null;

  final List<AssetItem> assets;
  final PortfolioDiagnosisResult? diagnosis;
}

String _firstSentence(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;

  bool isDigit(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  for (var i = 0; i < trimmed.length; i++) {
    final ch = trimmed[i];
    if (ch == '\n' || ch == '!' || ch == '?') {
      return trimmed.substring(0, i + 1).trim();
    }
    if (ch == '.') {
      final prev = i > 0 ? trimmed[i - 1] : '';
      final next = i + 1 < trimmed.length ? trimmed[i + 1] : '';
      final isDecimalPoint = isDigit(prev) && isDigit(next);
      if (!isDecimalPoint) {
        return trimmed.substring(0, i + 1).trim();
      }
    }
  }

  return trimmed;
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

Color _signedDisplayColor(
  BuildContext context,
  String valueText, {
  required Color defaultColor,
}) {
  if (valueText.startsWith('+')) return context.colors.positiveOn;
  if (valueText.startsWith('-')) return context.colors.negativeOn;
  return defaultColor;
}
