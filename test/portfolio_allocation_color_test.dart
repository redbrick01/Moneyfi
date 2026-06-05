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
