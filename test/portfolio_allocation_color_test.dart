import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_page.dart';

void main() {
  test('portfolio allocation colors are fixed by allocation rank', () {
    final source = File('lib/features/portfolio/screens/portfolio_page.dart').readAsStringSync();
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

  testWidgets('allocation groups the tail and keeps individual rows', (
    tester,
  ) async {
    expect(VisualSpec.brand.allocationRankPalette.toSet(), hasLength(6));
    String? selected;
    final assets = [
      for (var value = 1; value <= 8; value++)
        AssetItem(
          id: value,
          assetType: '주식',
          title: '자산 $value',
          alias: '',
          value: '',
          change: '',
          icon: Icons.show_chart,
          quantityLabel: '',
          quantityValue: '',
          averageLabel: '',
          averageValue: '',
          note: '',
          holdings: [
            HoldingItem(
              name: '종목 $value',
              symbol: '',
              quantity: 1,
              averagePrice: 1,
              currentPrice: value.toDouble(),
              note: '',
              transactions: const [],
            ),
          ],
          transactions: const [],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: buildAllocationSectionForTesting(
              assets,
              onSelectAsset: (label) => selected = label,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('기타 8.3%'), findsOneWidget);
    final donut = find.ancestor(
      of: find.text('₩36').first,
      matching: find.byType(Stack),
    ).first;
    final painter = find.descendant(
      of: donut,
      matching: find.byType(CustomPaint),
    ).first;
    expect(painter, paintsExactlyCountTimes(#drawArc, 7));
    final last = find.text('자산 1');
    await tester.ensureVisible(last);
    await tester.tap(last);
    expect(selected, '자산 1');
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
    final source = File('lib/features/portfolio/screens/portfolio_page.dart').readAsStringSync();
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

  test('holding allocation ratios use the total portfolio value', () {
    final source = File(
      'lib/features/portfolio/screens/portfolio_page.dart',
    ).readAsStringSync();
    final allocationCardSource = _classSource(
      source,
      'class _AllocationSectionCard',
    );
    final holdingAllocations = _functionSource(
      source,
      'List<_AllocationItem> _buildHoldingAllocationItems',
    );

    expect(
      allocationCardSource,
      contains('final totalPortfolioValue = items.fold<double>'),
    );
    expect(allocationCardSource, contains('_buildHoldingAllocationItems('));
    expect(allocationCardSource, contains('totalPortfolioValue'));
    expect(holdingAllocations, contains('double totalPortfolioValue'));
    expect(
      holdingAllocations,
      contains('entry.value.amount / totalPortfolioValue'),
    );
    expect(holdingAllocations, isNot(contains('entries.fold<double>')));
  });

  test('portfolio allocation card grows with expanded detail', () {
    final source = File('lib/features/portfolio/screens/portfolio_page.dart').readAsStringSync();
    final allocationCardSource = _classSource(
      source,
      'class _AllocationSectionCard',
    );

    expect(allocationCardSource, isNot(contains('maxHeight: 240')));
    expect(allocationCardSource, isNot(contains('SingleChildScrollView')));
  });

  test('dashboard asset rows reserve room for asset names', () {
    final source = File(
      'lib/features/portfolio/screens/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final assetRowSource = _classSource(source, 'class _AssetRow');

    expect(assetRowSource, contains('titleMinWidthFraction'));
    expect(assetRowSource, contains('0.30'));
  });

  test('asset and holding row profit rates are text, not pills', () {
    final dashboardSource = File(
      'lib/features/portfolio/screens/portfolio_dashboard_page.dart',
    ).readAsStringSync();
    final assetDetailSource = File(
      'lib/features/portfolio/screens/asset_detail_page.dart',
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
    final source = File('lib/features/portfolio/screens/asset_detail_page.dart').readAsStringSync();
    final holdingRow = _classSource(source, 'class _HoldingRow');

    expect(holdingRow, contains('holding.quantityText'));
    expect(holdingRow, contains('_kHoldingQuantitySlotWidth'));
    expect(holdingRow, isNot(contains('holding.symbol.trim()')));
    expect(holdingRow, isNot(contains("join(' · ')")));
    expect(holdingRow, isNot(contains('titleMinWidthFraction')));
  });

  test('asset detail holding rows can toggle from profit to market quote', () {
    final source = File('lib/features/portfolio/screens/asset_detail_page.dart').readAsStringSync();
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
      'lib/features/portfolio/screens/portfolio_dashboard_page.dart',
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
      'lib/features/portfolio/screens/portfolio_dashboard_page.dart',
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
