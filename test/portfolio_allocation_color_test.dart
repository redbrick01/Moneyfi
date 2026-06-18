import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio allocation colors are fixed by allocation rank', () {
    final source = File('lib/pages/portfolio_page.dart').readAsStringSync();
    final buildAllocations = _functionSource(
      source,
      'List<_AllocationItem> _buildAllocations',
    );
    final rankedColor = _functionSource(source, 'Color _rankedAllocationColor');

    expect(buildAllocations, contains('_rankedAllocationColor'));
    expect(
      buildAllocations,
      isNot(contains('MoneyfyChartPalette.colorForAsset')),
    );
    expect(rankedColor, contains('VisualSpec.brand.allocationRankPalette'));
  });

  test('portfolio allocation rank palette has ten tokens', () {
    final source = File(
      'lib/design_system/spec/visual_spec.dart',
    ).readAsStringSync();
    final palette = _functionSource(
      source,
      'List<Color> get allocationRankPalette',
    );

    expect(palette, contains('allocationRank01'));
    expect(palette, contains('allocationRank10'));
  });

  test('shared chart palette uses allocation rank tokens', () {
    final source = File(
      'lib/design_system/spec/visual_spec.dart',
    ).readAsStringSync();
    final chartPalette = _functionSource(
      source,
      'List<Color> get chartPalette',
    );

    expect(chartPalette, contains('allocationRankPalette'));
  });

  test('portfolio allocation drills into holdings for selected asset', () {
    final source = File('lib/pages/portfolio_page.dart').readAsStringSync();
    final stateSource = _classSource(source, 'class _PortfolioPageState');
    final allocationCardSource = _classSource(
      source,
      'class _AllocationSectionCard',
    );

    expect(stateSource, contains('_selectedHoldingLabel'));
    expect(allocationCardSource, contains('_buildHoldingAllocationItems'));
    expect(allocationCardSource, contains('selectedAssetItem'));
    expect(allocationCardSource, contains('_HoldingBreakdownList'));
    expect(allocationCardSource, contains('onSelectHolding'));
  });

  test('portfolio allocation card grows with expanded detail', () {
    final source = File('lib/pages/portfolio_page.dart').readAsStringSync();
    final allocationCardSource = _classSource(
      source,
      'class _AllocationSectionCard',
    );

    expect(allocationCardSource, isNot(contains('maxHeight: 240')));
    expect(allocationCardSource, isNot(contains('SingleChildScrollView')));
  });

  test('dashboard asset rows reserve room for asset names', () {
    final source = File(
      'lib/pages/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final assetRowSource = _classSource(source, 'class _AssetRow');

    expect(assetRowSource, contains('titleMinWidthFraction'));
    expect(assetRowSource, contains('0.30'));
  });

  test('asset and holding row profit rates are text, not pills', () {
    final dashboardSource = File(
      'lib/pages/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final assetDetailSource = File(
      'lib/pages/asset_detail_page.dart',
    ).readAsStringSync();
    final assetProfitLine = _classSource(
      dashboardSource,
      'class _AssetProfitLine',
    );
    final holdingProfitLine = _classSource(
      assetDetailSource,
      'class _HoldingProfitLine',
    );

    expect(assetProfitLine, isNot(contains('DeltaChip')));
    expect(holdingProfitLine, isNot(contains('DeltaChip')));
    expect(assetProfitLine, contains('formatSignedPercent'));
    expect(holdingProfitLine, contains('formatSignedPercent'));
  });

  test('asset detail holding rows show quantity without symbol subtitle', () {
    final source = File('lib/pages/asset_detail_page.dart').readAsStringSync();
    final holdingRow = _classSource(source, 'class _HoldingRow');

    expect(holdingRow, contains('holding.quantityText'));
    expect(holdingRow, contains('_kHoldingQuantitySlotWidth'));
    expect(holdingRow, isNot(contains('holding.symbol.trim()')));
    expect(holdingRow, isNot(contains("join(' · ')")));
    expect(holdingRow, isNot(contains('titleMinWidthFraction')));
  });

  test('asset detail holding rows can toggle from profit to market quote', () {
    final source = File('lib/pages/asset_detail_page.dart').readAsStringSync();
    final stateSource = _classSource(source, 'class _AssetDetailPageState');
    final holdingRow = _classSource(source, 'class _HoldingRow');
    final quoteLine = _classSource(source, 'class _HoldingMarketQuoteLine');

    expect(stateSource, contains('_showHoldingMarketQuote'));
    expect(stateSource, contains('MarketDataService.instance.fetchSnapshot'));
    expect(stateSource, contains('_HoldingDisplayModeToggle'));
    expect(holdingRow, contains('marketSnapshotFuture'));
    expect(holdingRow, contains('currentPrice'));
    expect(holdingRow, contains('_HoldingMarketQuoteLine'));
    expect(quoteLine, contains('dayChange'));
    expect(quoteLine, contains('dayChangeRate'));
  });

  test('dashboard diagnosis risk badge uses pill tokens', () {
    final source = File(
      'lib/pages/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final badgeSource = _classSource(source, 'class _DashboardDiagnosisBadge');

    expect(badgeSource, contains('MoneyfyPillTone'));
    expect(badgeSource, contains('MoneyfyPillSize.sm'));
    expect(badgeSource, contains('MoneyfyPillVariant'));
    expect(badgeSource, contains('VisualSpec.pill.heightSm'));
    expect(badgeSource, isNot(contains('backgroundColor')));
    expect(badgeSource, isNot(contains('textColor')));
    expect(badgeSource, isNot(contains('borderColor')));
  });

  test('dashboard cards use shared section header spacing', () {
    final source = File(
      'lib/pages/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final assetBasePlate = _classSource(source, 'class _AssetSectionBasePlate');
    final analysisBasePlate = _classSource(
      source,
      'class _AnalysisSectionBasePlate',
    );

    for (final basePlate in [assetBasePlate, analysisBasePlate]) {
      expect(basePlate, contains('title:'));
      expect(basePlate, contains('headerTrailing:'));
      expect(basePlate, contains('useSectionTitle: false'));
      expect(basePlate, isNot(contains('headerHeight')));
      expect(
        basePlate,
        isNot(contains('SizedBox(height: context.cardPadding())')),
      );
    }
  });

  test('statistics total asset trend can switch monthly and weekly cards', () {
    final source = File('lib/pages/statistics_page.dart').readAsStringSync();
    final pageState = _classSource(source, 'class _StatisticsPageState');
    final monthlyTrend = _classSource(source, 'class _MonthlyTrendSection');
    final monthlyTrendState = _classSource(
      source,
      'class _MonthlyTrendSectionState',
    );
    final trendSwitcher = _classSource(source, 'class _TrendViewSwitcher');

    expect(pageState, contains('_buildRecentWeekStatisticsData'));
    expect(monthlyTrend, contains('_TotalAssetTrendView'));
    expect(monthlyTrendState, contains('_TrendViewSwitcher'));
    expect(monthlyTrendState, contains('headerTrailing'));
    expect(source, contains('최근 7일 총자산 변화'));
    expect(trendSwitcher, contains('AppIconName.chevronLeft'));
    expect(trendSwitcher, contains('AppIconName.chevronRight'));
  });

  test('statistics weekly trend hides asset groups and x axis dates', () {
    final source = File('lib/pages/statistics_page.dart').readAsStringSync();
    final weeklyBuilder = _functionSource(
      source,
      '_StatisticsData _buildRecentWeekStatisticsData',
    );
    final monthlyTrendState = _classSource(
      source,
      'class _MonthlyTrendSectionState',
    );

    expect(weeklyBuilder, contains('subtract(const Duration(days: 6))'));
    expect(weeklyBuilder, contains('series: const []'));
    expect(
      monthlyTrendState,
      contains(
        'if (_trendView == _TotalAssetTrendView.monthly) ...activeData.series',
      ),
    );
    expect(monthlyTrendState, contains('showXAxisLabels'));
    expect(monthlyTrendState, contains('_TotalAssetTrendView.monthly'));
  });
}

String _functionSource(String source, String signature) {
  final start = source.indexOf(signature);
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}

String _classSource(String source, String signature) {
  final start = source.indexOf(signature);
  if (start == -1) return '';
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}
