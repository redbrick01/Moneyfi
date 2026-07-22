import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/rows/allocation_legend_row.dart';
import 'package:moneyfy/components/rows/rebalance_row.dart';
import 'package:moneyfy/components/separators/app_divider.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/components/states/skeletons.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/navigation/moneyfy_routes.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/portfolio/services/portfolio_diagnosis_service.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'forms/asset_form_page.dart';
import 'package:moneyfy/features/shell/screens/target_allocation_sheet.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({
    super.key,
    this.scrollController,
    this.dataRefreshTick = 0,
  });

  final ScrollController? scrollController;
  final int dataRefreshTick;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final Map<int, TextEditingController> _targetControllers = {};
  late Future<_PortfolioPageData> _pageFuture;
  String? _selectedAssetLabel;
  String? _selectedHoldingLabel;
  bool _isGeneratingDiagnosis = false;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPortfolioPageData();
  }

  @override
  void didUpdateWidget(covariant PortfolioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      setState(() {
        _pageFuture = _loadPortfolioPageData();
      });
    }
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    if (!mounted) return;
    setState(() {
      _pageFuture = _loadPortfolioPageData();
    });
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

    if (changed == true && mounted) {
      setState(() {
        _pageFuture = _loadPortfolioPageData();
      });
    }
  }

  Future<void> _openAssetDetail(int assetId) async {
    await context.openAssetDetail(AssetDetailRouteArgs(assetId: assetId));
    if (!mounted) return;
    setState(() {
      _pageFuture = _loadPortfolioPageData();
    });
  }

  void _openPortfolioDiagnosisDetail() {
    unawaited(context.openPortfolioDiagnosis());
  }

  @override
  void dispose() {
    for (final controller in _targetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PortfolioPageData>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppPageScaffold(
            title: '포트폴리오',
            enablePullToRefresh: true,
            onRefresh: _refreshPage,
            hasFloatingNavInset: true,
            scrollController: widget.scrollController,
            body: Column(
              children: [
                const SkeletonPresetCard(preset: SkeletonCardPreset.chartCard),
                SizedBox(height: context.spacing.sectionGap),
                const SkeletonList(
                  rows: 6,
                  rowHeight: 72,
                  hasLeading: true,
                  trailingLines: 2,
                ),
                SizedBox(height: context.spacing.sectionGap),
                const SkeletonCard(height: 190),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return AppPageScaffold(
            title: '포트폴리오',
            enablePullToRefresh: true,
            onRefresh: _refreshPage,
            hasFloatingNavInset: true,
            scrollController: widget.scrollController,
            body: Column(
              children: [
                const InlineError(
                  message: '네트워크 문제로 포트폴리오를 불러오지 못했어요.',
                  detail: '다시 시도해 주세요.',
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

        final data = snapshot.data ?? const _PortfolioPageData.empty();
        final items = _buildAllocations(data.assets);

        if (_selectedAssetLabel != null &&
            !items.any((element) => element.label == _selectedAssetLabel)) {
          _selectedAssetLabel = null;
          _selectedHoldingLabel = null;
        }

        _syncTargetControllers(items, data.targetRatios);
        final targetRatios = _readTargetRatios(items);
        final rebalanceEntries = _buildRebalanceEntries(
          items: items,
          targetRatios: targetRatios,
        );
        return AppPageScaffold(
          title: '포트폴리오',
          enablePullToRefresh: true,
          onRefresh: _refreshPage,
          hasFloatingNavInset: true,
          scrollController: widget.scrollController,
          body: items.isEmpty
              ? _PortfolioSectionBasePlate(
                  child: AppInnerPanel(
                    child: _PortfolioEmptyContent(
                      title: '자산을 추가하면 비중을 볼 수 있어요',
                      description:
                          '자산군을 만든 뒤 보유 종목이나 현금 계좌를 추가하면 비중과 리밸런싱을 확인할 수 있어요.',
                      icon: AppIconName.pieChart,
                      actionLabel: '자산 추가',
                      onAction: () => _openAssetForm(),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AllocationSectionCard(
                      items: items,
                      selectedAssetLabel: _selectedAssetLabel,
                      selectedHoldingLabel: _selectedHoldingLabel,
                      onSelectAsset: (label) {
                        setState(() {
                          if (_selectedAssetLabel == label) {
                            _selectedAssetLabel = null;
                          } else {
                            _selectedAssetLabel = label;
                          }
                          _selectedHoldingLabel = null;
                        });
                      },
                      onSelectHolding: (label) {
                        setState(() {
                          _selectedHoldingLabel = _selectedHoldingLabel == label
                              ? null
                              : label;
                        });
                      },
                      onOpenAssetDetail: _openAssetDetail,
                    ),
                    SizedBox(height: context.spacing.sectionGap),
                    _RebalancingSectionCard(
                      entries: rebalanceEntries,
                      onOpenTargetSheet: () =>
                          _openTargetAllocationSheet(items),
                    ),
                    SizedBox(height: context.spacing.sectionGap),
                    _PortfolioDiagnosisSectionCard(
                      diagnosis: data.diagnosis,
                      isGenerating: _isGeneratingDiagnosis,
                      generatedAt: data.diagnosisCachedAt,
                      onGenerate: data.diagnosisPayload == null
                          ? null
                          : () => _generatePortfolioDiagnosis(data),
                      onOpenDetail: _openPortfolioDiagnosisDetail,
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _syncTargetControllers(
    List<_AllocationItem> items,
    Map<int, double> targetRatios,
  ) {
    final assetIds = items.map((item) => item.assetId).toSet();

    final staleKeys = _targetControllers.keys
        .where((key) => !assetIds.contains(key))
        .toList();
    for (final key in staleKeys) {
      _targetControllers.remove(key)?.dispose();
    }

    for (final item in items) {
      _targetControllers.putIfAbsent(
        item.assetId,
        () => TextEditingController(
          text: (targetRatios[item.assetId] ?? item.ratio).toStringAsFixed(1),
        ),
      );
    }
  }

  Map<int, double> _readTargetRatios(List<_AllocationItem> items) {
    return {
      for (final item in items)
        item.assetId:
            double.tryParse(_targetControllers[item.assetId]?.text ?? '') ?? 0,
    };
  }

  Future<void> _openTargetAllocationSheet(List<_AllocationItem> items) async {
    final entries = items
        .map(
          (item) => TargetAllocationEntry(
            assetId: item.assetId,
            label: item.label,
            currentRatio: item.ratio,
          ),
        )
        .toList(growable: false);

    final saved = await showTargetAllocationSheet(
      context: context,
      entries: entries,
      controllers: _targetControllers,
      onSave: (ratios) async {
        await AppDatabase.instance.saveAssetAllocationTargets(ratios);
      },
    );

    if (saved == true && mounted) {
      setState(() {});
      AppSnackBar.showSuccess(
        context,
        '목표 비중이 저장됐어요.',
        hasFloatingNavInset: true,
      );
    }
  }

  Future<void> _generatePortfolioDiagnosis(_PortfolioPageData data) async {
    if (_isGeneratingDiagnosis) return;
    final payload = data.diagnosisPayload;
    if (payload == null) {
      AppSnackBar.showInfo(
        context,
        '진단 가능한 포트폴리오 데이터가 부족합니다.',
        hasFloatingNavInset: true,
      );
      return;
    }

    setState(() {
      _isGeneratingDiagnosis = true;
    });

    try {
      final result = await PortfolioDiagnosisService.instance.fetchDiagnosis(
        portfolioInput: payload,
        forceRefresh: true,
      );

      if (!mounted) return;
      setState(() {
        _pageFuture = _loadPortfolioPageData();
      });

      if (result == null) {
        AppSnackBar.showError(
          context,
          '진단 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.',
          hasFloatingNavInset: true,
        );
      } else {
        AppSnackBar.showSuccess(
          context,
          '포트폴리오 진단이 업데이트됐어요.',
          hasFloatingNavInset: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDiagnosis = false;
        });
      }
    }
  }
}

class _PortfolioSectionBasePlate extends StatelessWidget {
  const _PortfolioSectionBasePlate({required this.child});

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

class _PortfolioEmptyContent extends StatelessWidget {
  const _PortfolioEmptyContent({
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

Future<_PortfolioPageData> _loadPortfolioPageData() async {
  final assets = await AppDatabase.instance.fetchAssets();
  final targetRatios = await AppDatabase.instance.fetchAssetAllocationTargets();
  final diagnosisPayload = _buildPortfolioDiagnosisPayload(assets: assets);
  final cachedDiagnosisEntry = diagnosisPayload == null
      ? null
      : await PortfolioDiagnosisService.instance.fetchCachedDiagnosis();
  return _PortfolioPageData(
    assets: assets,
    targetRatios: targetRatios,
    diagnosisPayload: diagnosisPayload,
    diagnosis: cachedDiagnosisEntry?.diagnosis,
    diagnosisCachedAt: cachedDiagnosisEntry?.cachedAt,
  );
}

class _AllocationItem {
  const _AllocationItem({
    required this.assetId,
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
    required this.icon,
    required this.holdings,
  });

  final int assetId;
  final String label;
  final double amount;
  final double ratio;
  final Color color;
  final IconData icon;
  final List<HoldingItem> holdings;
}

List<_AllocationItem> _buildAllocations(List<AssetItem> assets) {
  final entries = assets
      .where((asset) => !asset.isHidden)
      .where((asset) => asset.id != null)
      .map((asset) => (asset: asset, amount: asset.totalValuationAmount))
      .where((entry) => entry.amount > 0)
      .toList();
  final totalValue = entries.fold<double>(
    0,
    (sum, entry) => sum + entry.amount,
  );
  entries.sort((a, b) {
    final amountCompare = b.amount.compareTo(a.amount);
    if (amountCompare != 0) return amountCompare;
    return a.asset.displayName.compareTo(b.asset.displayName);
  });

  return entries
      .asMap()
      .entries
      .map(
        (entry) => _AllocationItem(
          assetId: entry.value.asset.id!,
          label: entry.value.asset.displayName,
          amount: entry.value.amount,
          ratio: totalValue == 0 ? 0 : (entry.value.amount / totalValue) * 100,
          color: _rankedAllocationColor(entry.key),
          icon: entry.value.asset.icon,
          holdings: entry.value.asset.visibleHoldings,
        ),
      )
      .toList();
}

Color _rankedAllocationColor(int rank) {
  final colors = VisualSpec.brand.allocationRankPalette;
  return colors[rank % colors.length];
}

class _AllocationSectionCard extends StatelessWidget {
  const _AllocationSectionCard({
    required this.items,
    required this.selectedAssetLabel,
    required this.selectedHoldingLabel,
    required this.onSelectAsset,
    required this.onSelectHolding,
    required this.onOpenAssetDetail,
  });

  final List<_AllocationItem> items;
  final String? selectedAssetLabel;
  final String? selectedHoldingLabel;
  final ValueChanged<String> onSelectAsset;
  final ValueChanged<String> onSelectHolding;
  final ValueChanged<int> onOpenAssetDetail;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedAssetLabel == null
        ? null
        : items.indexWhere((item) => item.label == selectedAssetLabel);
    final selectedItem = selectedIndex == null || selectedIndex < 0
        ? null
        : items[selectedIndex];
    final selectedAssetItem = selectedItem;
    final totalPortfolioValue = items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final holdingItems = selectedAssetItem == null
        ? const <_AllocationItem>[]
        : _buildHoldingAllocationItems(selectedAssetItem, totalPortfolioValue);
    final showHoldingBreakdown = holdingItems.isNotEmpty;
    final selectedHoldingIndex = showHoldingBreakdown
        ? holdingItems.indexWhere((item) => item.label == selectedHoldingLabel)
        : -1;
    final selectedHoldingItem = selectedHoldingIndex < 0
        ? null
        : holdingItems[selectedHoldingIndex];
    final chartItems = showHoldingBreakdown ? holdingItems : items;
    final chartSelectedIndex = showHoldingBreakdown
        ? (selectedHoldingIndex < 0 ? null : selectedHoldingIndex)
        : selectedIndex;
    final sorted = [...items]..sort((a, b) => b.ratio.compareTo(a.ratio));
    final topOne = sorted.isEmpty ? null : sorted.first;
    final topThreeRatio = sorted
        .take(3)
        .fold<double>(0, (sum, item) => sum + item.ratio);

    return SectionCard(
      title: '자산 비중',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final baseSize = constraints.maxWidth < 380
                  ? VisualSpec.chart.donutSize
                  : constraints.maxWidth * 0.36;
              final chartSize = baseSize.clamp(
                VisualSpec.chart.donutMin,
                VisualSpec.chart.donutMax,
              );
              final legend = SlidableAutoCloseBehavior(
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == items.length - 1
                              ? 0
                              : context.spacing.xs,
                        ),
                        child: _SwipeToOpenAssetDetail(
                          label: items[i].label,
                          onOpen: () => onOpenAssetDetail(items[i].assetId),
                          child: Column(
                            children: [
                              AllocationLegendRow(
                                color: items[i].color,
                                icon: items[i].icon,
                                title: items[i].label,
                                ratioText:
                                    '${items[i].ratio.toStringAsFixed(1)}%',
                                amountText: _formatCurrency(items[i].amount),
                                isSelected: selectedIndex == i,
                                onTap: () => onSelectAsset(items[i].label),
                              ),
                              if (selectedIndex == i &&
                                  showHoldingBreakdown) ...[
                                SizedBox(height: context.spacing.xs),
                                _HoldingBreakdownList(
                                  items: holdingItems,
                                  selectedLabel: selectedHoldingLabel,
                                  onSelectHolding: onSelectHolding,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );

              final chart = _InteractiveDonutChart(
                size: chartSize,
                items: chartItems,
                selectedIndex: chartSelectedIndex,
                centerTitle: showHoldingBreakdown
                    ? selectedHoldingItem?.label ?? selectedAssetItem?.label
                    : selectedItem?.label,
                centerValue: showHoldingBreakdown
                    ? selectedHoldingItem == null
                          ? _formatCurrency(selectedAssetItem?.amount ?? 0)
                          : '${selectedHoldingItem.ratio.toStringAsFixed(1)}%'
                    : selectedItem == null
                    ? _formatCurrency(
                        items.fold<double>(0, (sum, item) => sum + item.amount),
                      )
                    : '${selectedItem.ratio.toStringAsFixed(1)}%',
                onTapSlice: (index) {
                  if (showHoldingBreakdown) {
                    onSelectHolding(holdingItems[index].label);
                  } else {
                    onSelectAsset(items[index].label);
                  }
                },
              );

              if (constraints.maxWidth < 380) {
                return Column(
                  children: [
                    chart,
                    SizedBox(height: context.spacing.md),
                    legend,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  chart,
                  SizedBox(width: context.spacing.md),
                  Expanded(child: legend),
                ],
              );
            },
          ),
          SizedBox(height: context.spacing.md),
          SizedBox(
            width: double.infinity,
            child: Text(
              topOne == null
                  ? '상위 비중 정보가 없습니다.'
                  : '상위 1개: ${topOne.label} ${topOne.ratio.toStringAsFixed(1)}% · 상위 3개 합계 ${topThreeRatio.toStringAsFixed(1)}%',
              style: context.typography.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

List<_AllocationItem> _buildHoldingAllocationItems(
  _AllocationItem assetItem,
  double totalPortfolioValue,
) {
  final entries = assetItem.holdings
      .map((holding) => (holding: holding, amount: holding.valuationAmount))
      .where((entry) => entry.amount > 0)
      .toList();
  entries.sort((a, b) {
    final amountCompare = b.amount.compareTo(a.amount);
    if (amountCompare != 0) return amountCompare;
    return a.holding.name.compareTo(b.holding.name);
  });

  return entries
      .asMap()
      .entries
      .map(
        (entry) => _AllocationItem(
          assetId: assetItem.assetId,
          label: entry.value.holding.name,
          amount: entry.value.amount,
          ratio: totalPortfolioValue == 0
              ? 0
              : (entry.value.amount / totalPortfolioValue) * 100,
          color: _rankedAllocationColor(entry.key),
          icon: assetItem.icon,
          holdings: const [],
        ),
      )
      .toList(growable: false);
}

class _HoldingBreakdownList extends StatelessWidget {
  const _HoldingBreakdownList({
    required this.items,
    required this.selectedLabel,
    required this.onSelectHolding,
  });

  final List<_AllocationItem> items;
  final String? selectedLabel;
  final ValueChanged<String> onSelectHolding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: context.spacing.md),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == items.length - 1 ? 0 : context.spacing.xs,
              ),
              child: _HoldingLegendRow(
                item: items[i],
                isSelected: selectedLabel == items[i].label,
                onTap: () => onSelectHolding(items[i].label),
              ),
            ),
        ],
      ),
    );
  }
}

class _HoldingLegendRow extends StatelessWidget {
  const _HoldingLegendRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _AllocationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: Duration(milliseconds: VisualSpec.chart.animFastMs),
      curve: VisualSpec.chart.animCurve,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(context.radius.rSm),
        border: Border.all(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.24)
              : colorScheme.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radius.rSm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: VisualSpec.chart.legendDot - 2,
                height: VisualSpec.chart.legendDot - 2,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(
                    VisualSpec.chart.legendDotRadius,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Text(
                _formatCurrency(item.amount),
                style: context.typography.caption.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              SizedBox(width: context.spacing.xs),
              MoneyfyBadge(
                label: '${item.ratio.toStringAsFixed(1)}%',
                size: MoneyfyPillSize.sm,
                variant: MoneyfyPillVariant.outline,
                backgroundColor: colorScheme.surface,
                borderColor: colorScheme.outlineVariant,
                textColor: colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeToOpenAssetDetail extends StatelessWidget {
  const _SwipeToOpenAssetDetail({
    required this.label,
    required this.onOpen,
    required this.child,
  });

  static const _groupTag = 'portfolio-allocation-detail-action';
  static const _extentRatio = 0.22;

  final String label;
  final VoidCallback onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: '$label 상세 열기'): onOpen,
      },
      child: Slidable(
        key: ValueKey('allocation-detail-$label'),
        groupTag: _groupTag,
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: _extentRatio,
          dismissible: DismissiblePane(onDismissed: onOpen),
          children: [
            CustomSlidableAction(
              onPressed: (_) => onOpen(),
              backgroundColor: VisualSpec.surface.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              borderRadius: BorderRadius.zero,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: context.colors.primary,
                  size: VisualSpec.icon.sizeDefault,
                ),
              ),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _InteractiveDonutChart extends StatelessWidget {
  const _InteractiveDonutChart({
    required this.size,
    required this.items,
    required this.selectedIndex,
    this.centerTitle,
    required this.centerValue,
    required this.onTapSlice,
  });

  final double size;
  final List<_AllocationItem> items;
  final int? selectedIndex;
  final String? centerTitle;
  final String centerValue;
  final ValueChanged<int> onTapSlice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTapUp: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.globalPosition);
          final index = _detectSliceIndex(local, Size.square(size), items);
          if (index != null) {
            onTapSlice(index);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _AllocationChartPainter(
                items: items,
                selectedIndex: selectedIndex,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(
                size * ((1 - VisualSpec.chart.donutInnerHoleRatio) / 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if ((centerTitle ?? '').trim().isNotEmpty) ...[
                    Text(
                      centerTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.meta.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.spacing.xs / 2),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        centerValue,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: context.typography.cardTitle.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: AppFontWeights.semibold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? _detectSliceIndex(Offset point, Size size, List<_AllocationItem> items) {
  if (items.isEmpty) return null;
  final center = size.center(Offset.zero);
  final vector = point - center;
  final distance = vector.distance;
  final outerRadius = (size.shortestSide / 2) - 1;
  final innerRadius = outerRadius - VisualSpec.chart.donutStrokeSelected;

  if (distance < innerRadius || distance > outerRadius) {
    return null;
  }

  const startAngle = -math.pi / 2;
  final gap = VisualSpec.chart.donutSliceGap / math.max(outerRadius, 1);
  var tapAngle = math.atan2(vector.dy, vector.dx);
  while (tapAngle < startAngle) {
    tapAngle += math.pi * 2;
  }

  var currentAngle = startAngle;
  for (var i = 0; i < items.length; i++) {
    final rawSweep = (items[i].ratio / 100) * math.pi * 2;
    final sweep = math.max(0.0, rawSweep - gap);
    final start = currentAngle;
    final end = currentAngle + sweep;
    if (tapAngle >= start && tapAngle <= end) {
      return i;
    }
    currentAngle += sweep + gap;
  }
  return null;
}

class _AllocationChartPainter extends CustomPainter {
  _AllocationChartPainter({required this.items, required this.selectedIndex});

  final List<_AllocationItem> items;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final rect = Offset.zero & size;
    const startAngle = -math.pi / 2;
    final gap =
        VisualSpec.chart.donutSliceGap / math.max(size.shortestSide / 2, 1);
    var currentAngle = startAngle;

    for (var i = 0; i < items.length; i++) {
      final rawSweep = (items[i].ratio / 100) * math.pi * 2;
      final sweep = math.max(0.0, rawSweep - gap);
      final isSelected = selectedIndex == i;
      final strokeWidth = isSelected
          ? VisualSpec.chart.donutStrokeSelected
          : VisualSpec.chart.donutStroke;
      final paint = Paint()
        ..color = selectedIndex == null || isSelected
            ? items[i].color
            : items[i].color.withValues(
                alpha: VisualSpec.chart.donutUnselectedAlpha,
              )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final arcRect = Rect.fromCircle(
        center: rect.center,
        radius: (size.shortestSide / 2) - (strokeWidth / 2),
      );
      canvas.drawArc(arcRect, currentAngle, sweep, false, paint);
      currentAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _AllocationChartPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _RebalancingEntry {
  const _RebalancingEntry({
    required this.icon,
    required this.label,
    required this.currentRatio,
    required this.targetRatio,
    required this.deltaRatioPp,
    required this.deltaAmount,
  });

  final IconData icon;
  final String label;
  final double currentRatio;
  final double targetRatio;
  final double deltaRatioPp;
  final double deltaAmount;
}

List<_RebalancingEntry> _buildRebalanceEntries({
  required List<_AllocationItem> items,
  required Map<int, double> targetRatios,
}) {
  if (items.isEmpty) return const [];

  final totalValue = items.fold<double>(0, (sum, item) => sum + item.amount);

  final entries = items.map((item) {
    final targetRatio = targetRatios[item.assetId] ?? item.ratio;
    final targetAmount = totalValue * (targetRatio / 100);
    final deltaAmount = targetAmount - item.amount;
    return _RebalancingEntry(
      icon: item.icon,
      label: item.label,
      currentRatio: item.ratio,
      targetRatio: targetRatio,
      deltaRatioPp: item.ratio - targetRatio,
      deltaAmount: deltaAmount,
    );
  }).toList();

  entries.sort((a, b) => b.deltaAmount.abs().compareTo(a.deltaAmount.abs()));
  return entries;
}

class _RebalancingSectionCard extends StatelessWidget {
  const _RebalancingSectionCard({
    required this.entries,
    required this.onOpenTargetSheet,
  });

  final List<_RebalancingEntry> entries;
  final VoidCallback onOpenTargetSheet;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '리밸런싱',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '목표 대비 차이를 기반으로 매수/매도 필요 금액을 계산합니다.',
            style: context.typography.meta,
          ),
          SizedBox(height: context.spacing.md),
          if (entries.isEmpty)
            Text('리밸런싱할 자산이 없습니다.', style: context.typography.meta),
          for (var i = 0; i < entries.length; i++) ...[
            RebalanceRow(
              icon: entries[i].icon,
              title: entries[i].label,
              helper:
                  '${entries[i].currentRatio.toStringAsFixed(1)}% → ${entries[i].targetRatio.toStringAsFixed(1)}%',
              value:
                  '${entries[i].deltaAmount >= 0 ? '+' : '-'}${_formatCurrency(entries[i].deltaAmount.abs())}',
              valueColor: entries[i].deltaAmount >= 0
                  ? context.colors.positiveOn
                  : context.colors.negativeOn,
              singleLine: true,
            ),
            if (i != entries.length - 1) AppDivider(),
          ],
          SizedBox(height: context.spacing.md),
          AppPrimaryButton(label: '목표 비중 설정', onPressed: onOpenTargetSheet),
          SizedBox(height: context.spacing.xs),
          SizedBox(
            width: double.infinity,
            child: Text(
              '목표 비중은 합계 100%여야 저장됩니다.',
              style: context.typography.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioDiagnosisSectionCard extends StatelessWidget {
  const _PortfolioDiagnosisSectionCard({
    required this.diagnosis,
    required this.isGenerating,
    required this.generatedAt,
    required this.onGenerate,
    required this.onOpenDetail,
  });

  final PortfolioDiagnosisResult? diagnosis;
  final bool isGenerating;
  final DateTime? generatedAt;
  final VoidCallback? onGenerate;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (diagnosis == null) {
      return SectionCard(
        title: '포트폴리오 진단',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('진단 결과가 아직 생성되지 않았어요.', style: context.typography.cardTitle),
            SizedBox(height: context.spacing.xs),
            Text(
              '버튼을 누르면 현재 포트폴리오 기준으로 진단을 생성합니다.',
              style: context.typography.meta,
            ),
            SizedBox(height: context.spacing.md),
            AppPrimaryButton(
              label: '포트폴리오 진단 생성',
              isLoading: isGenerating,
              onPressed: onGenerate,
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: '포트폴리오 진단',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosisBlockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '포트폴리오 진단 결과',
                        style: context.typography.cardTitle.copyWith(
                          fontWeight: AppFontWeights.semibold,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    _RiskBadge(riskLevel: diagnosis!.riskLevel),
                  ],
                ),
                SizedBox(height: context.spacing.sm),
                Text(diagnosis!.summary, style: context.typography.meta),
                SizedBox(height: context.spacing.xs),
                Text(
                  diagnosis!.analysisSource == 'fallback_rule_based'
                      ? '진단 출처: 규칙 기반'
                      : '진단 출처: AI 모델',
                  style: context.typography.caption,
                ),
                SizedBox(height: context.spacing.sm),
                Text(
                  generatedAt == null
                      ? '생성 시각 정보 없음'
                      : '생성일: ${_formatDateTime(generatedAt!)}',
                  style: context.typography.caption,
                ),
                SizedBox(height: context.spacing.sm),
                AppPrimaryButton(
                  label: '진단 새로 생성',
                  isLoading: isGenerating,
                  onPressed: onGenerate,
                ),
                SizedBox(height: context.spacing.xs),
                AppGhostButton(
                  label: '상세 진단 보기',
                  onPressed: onOpenDetail,
                  expand: true,
                  icon: Icons.open_in_new_rounded,
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.md),
          _DiagnosisBlockCard(
            title: '안정성 점수',
            child: _ScoreRow(label: '종합 점수', score: diagnosis!.score),
          ),
          if (diagnosis!.strengths.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _DiagnosisBlockCard(
              title: '구조적 장점',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < diagnosis!.strengths.length; i++) ...[
                    _DiagnosisBulletRow(text: diagnosis!.strengths[i]),
                    if (i != diagnosis!.strengths.length - 1)
                      SizedBox(height: context.spacing.xs),
                  ],
                ],
              ),
            ),
          ],
          if (diagnosis!.weaknesses.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _DiagnosisBlockCard(
              title: '구조적 약점',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < diagnosis!.weaknesses.length; i++) ...[
                    _DiagnosisBulletRow(text: diagnosis!.weaknesses[i]),
                    if (i != diagnosis!.weaknesses.length - 1)
                      SizedBox(height: context.spacing.xs),
                  ],
                ],
              ),
            ),
          ],
          if (diagnosis!.suggestions.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _DiagnosisBlockCard(
              title: '점검 제안',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < diagnosis!.suggestions.length; i++) ...[
                    Text(
                      '${i + 1}. ${diagnosis!.suggestions[i]}',
                      style: context.typography.meta,
                    ),
                    if (i != diagnosis!.suggestions.length - 1)
                      SizedBox(height: context.spacing.xs),
                  ],
                ],
              ),
            ),
          ],
          if (diagnosis!.uncertainty) ...[
            SizedBox(height: context.spacing.md),
            _DiagnosisBlockCard(
              child: Text(
                '입력 데이터 기준으로 판단 근거가 일부 제한되어 보수적으로 해석된 결과입니다.',
                style: context.typography.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosisBlockCard extends StatelessWidget {
  const _DiagnosisBlockCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: context.typography.cardTitle.copyWith(
                fontWeight: AppFontWeights.semibold,
              ),
            ),
            SizedBox(height: context.spacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}

class _DiagnosisBulletRow extends StatelessWidget {
  const _DiagnosisBulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: context.typography.meta),
        Expanded(child: Text(text, style: context.typography.meta)),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riskLevel});

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
      size: MoneyfyPillSize.sm,
      backgroundColor: color.withValues(alpha: 0.14),
      textColor: color,
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final normalized = (score / 100).clamp(0, 1).toDouble();
    final tone = score >= 70
        ? context.colors.positiveOn
        : score >= 50
        ? context.colors.warningOn
        : context.colors.negativeOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.typography.meta)),
            Text('$score', style: context.typography.meta),
          ],
        ),
        SizedBox(height: context.spacing.xs / 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radius.rPill),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            color: tone,
            backgroundColor: tone.withValues(alpha: 0.16),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic>? _buildPortfolioDiagnosisPayload({
  required List<AssetItem> assets,
}) {
  final visibleAssets = assets
      .where((asset) => !asset.isHidden)
      .toList(growable: false);
  if (visibleAssets.isEmpty) return null;

  final totalPurchase = visibleAssets.fold<double>(
    0,
    (sum, asset) => sum + asset.totalPurchaseAmount,
  );
  final totalValuation = visibleAssets.fold<double>(
    0,
    (sum, asset) => sum + asset.totalValuationAmount,
  );
  final totalProfit = totalValuation - totalPurchase;
  final totalProfitRate = totalPurchase == 0
      ? 0
      : (totalProfit / totalPurchase) * 100;

  if (totalValuation <= 0) return null;

  final assetClassAllocation =
      visibleAssets
          .fold<Map<String, double>>(<String, double>{}, (acc, asset) {
            final amount = asset.totalValuationAmount;
            final ratio = totalValuation == 0
                ? 0.0
                : (amount / totalValuation) * 100;
            final key = _assetClassForPayload(asset.assetType);
            acc.update(key, (value) => value + ratio, ifAbsent: () => ratio);
            return acc;
          })
          .entries
          .map(
            (entry) => {
              'asset_class': entry.key,
              'weight': double.parse(entry.value.toStringAsFixed(2)),
            },
          )
          .toList(growable: false)
        ..sort(
          (a, b) => (b['weight'] as double).compareTo(a['weight'] as double),
        );

  final topHoldings = visibleAssets
      .expand((asset) {
        return asset.visibleHoldings.map((holding) {
          final valuation = holding.valuationAmount;
          final ratio = totalValuation == 0
              ? 0
              : (valuation / totalValuation) * 100;
          final symbol = holding.symbol.trim().isNotEmpty
              ? holding.symbol.trim()
              : holding.name.trim();
          return {
            'symbol': symbol,
            'name': holding.name,
            'asset_type': _holdingTypeForPayload(asset.assetType),
            'market_value': valuation,
            'return_rate': holding.profitRate,
            'weight': ratio,
          };
        });
      })
      .toList(growable: false);
  topHoldings.sort(
    (a, b) =>
        (b['market_value'] as double).compareTo(a['market_value'] as double),
  );
  final fallbackTopHoldings =
      visibleAssets
          .map((asset) {
            final marketValue = asset.totalValuationAmount;
            final weight = totalValuation == 0
                ? 0.0
                : (marketValue / totalValuation) * 100;
            return {
              'symbol': asset.displayName.trim(),
              'name': asset.displayName,
              'asset_type': _holdingTypeForPayload(asset.assetType),
              'market_value': marketValue,
              'return_rate': asset.totalProfitRate,
              'weight': weight,
            };
          })
          .toList(growable: false)
        ..sort(
          (a, b) => (b['market_value'] as double).compareTo(
            a['market_value'] as double,
          ),
        );
  final holdingsForPayload = topHoldings.isNotEmpty
      ? topHoldings
      : fallbackTopHoldings;
  final trimmedTopHoldings = holdingsForPayload
      .take(12)
      .toList(growable: false);
  final cashRatio = assetClassAllocation
      .where((row) => row['asset_class'] == 'cash')
      .fold<double>(0, (sum, row) => sum + (row['weight'] as double));
  final cryptoRatio = assetClassAllocation
      .where((row) => row['asset_class'] == 'crypto')
      .fold<double>(0, (sum, row) => sum + (row['weight'] as double));
  final realHoldingCount = visibleAssets.fold<int>(
    0,
    (sum, asset) => sum + asset.visibleHoldings.length,
  );
  final holdingCount = realHoldingCount > 0
      ? realHoldingCount
      : trimmedTopHoldings.length;
  final top3Weight = trimmedTopHoldings
      .take(3)
      .fold<double>(0, (sum, row) => sum + (row['weight'] as double));
  final bestHolding = holdingsForPayload.isEmpty
      ? null
      : holdingsForPayload.reduce((a, b) {
          final aRate = a['return_rate'] as double;
          final bRate = b['return_rate'] as double;
          return aRate >= bRate ? a : b;
        });
  final worstHolding = holdingsForPayload.isEmpty
      ? null
      : holdingsForPayload.reduce((a, b) {
          final aRate = a['return_rate'] as double;
          final bRate = b['return_rate'] as double;
          return aRate <= bRate ? a : b;
        });
  final resolvedTop1Weight = trimmedTopHoldings.isEmpty
      ? 0.0
      : (trimmedTopHoldings.first['weight'] as double);

  return {
    'base_currency': 'KRW',
    'total_asset_value': totalValuation,
    'total_invested_amount': totalPurchase,
    'total_profit_loss': totalProfit,
    'total_return_rate': totalProfitRate,
    'cash_value': totalValuation * (cashRatio / 100),
    'cash_weight': cashRatio,
    'holding_count': holdingCount,
    'asset_class_allocation': assetClassAllocation,
    'top_holdings': trimmedTopHoldings,
    'risk_flags': {
      'high_crypto_weight': cryptoRatio > 20,
      'single_asset_concentration': resolvedTop1Weight >= 35,
      'low_cash_buffer': cashRatio < 10,
      'few_holdings': holdingCount < 5,
    },
    'concentration_metrics': {
      'top_1_weight': resolvedTop1Weight,
      'top_3_weight': top3Weight,
    },
    'performance_summary': {
      'best_holding': bestHolding == null
          ? null
          : {
              'symbol': '${bestHolding['symbol'] ?? bestHolding['name'] ?? ''}',
              'return_rate': bestHolding['return_rate'],
            },
      'worst_holding': worstHolding == null
          ? null
          : {
              'symbol':
                  '${worstHolding['symbol'] ?? worstHolding['name'] ?? ''}',
              'return_rate': worstHolding['return_rate'],
            },
    },
  };
}

String _assetClassForPayload(String assetType) {
  switch (assetType.trim()) {
    case '코인':
      return 'crypto';
    case '현금':
      return 'cash';
    case '주식':
      return 'domestic_stock';
    default:
      return assetType.trim().toLowerCase().replaceAll(' ', '_');
  }
}

String _holdingTypeForPayload(String assetType) {
  switch (assetType.trim()) {
    case '코인':
      return 'crypto';
    case '현금':
      return 'cash';
    case '주식':
      return 'stock';
    default:
      return assetType.trim().toLowerCase().replaceAll(' ', '_');
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

class _PortfolioPageData {
  const _PortfolioPageData({
    required this.assets,
    required this.targetRatios,
    required this.diagnosisPayload,
    this.diagnosis,
    this.diagnosisCachedAt,
  });

  const _PortfolioPageData.empty()
    : assets = const [],
      targetRatios = const {},
      diagnosisPayload = null,
      diagnosis = null,
      diagnosisCachedAt = null;

  final List<AssetItem> assets;
  final Map<int, double> targetRatios;
  final Map<String, dynamic>? diagnosisPayload;
  final PortfolioDiagnosisResult? diagnosis;
  final DateTime? diagnosisCachedAt;
}
