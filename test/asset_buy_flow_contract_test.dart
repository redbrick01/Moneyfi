import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/navigation/moneyfy_routes.dart';

void main() {
  test('asset buy route is scoped to the selected asset', () {
    expect(
      MoneyfyRoutePaths.assetBuyCreatePattern,
      '/assets/:assetId/buys/new',
    );
    expect(MoneyfyRoutePaths.assetBuyCreate(42), '/assets/42/buys/new');
  });

  test('asset detail replaces holding creation with an initial buy', () {
    final source = File(
      'lib/features/portfolio/screens/asset_detail_page.dart',
    ).readAsStringSync();

    expect(source, contains('openAssetBuyCreate'));
    expect(source, contains("actionLabel: '종목 매수'"));
    expect(
      source,
      contains('HoldingFormPage(assetId: currentAssetId, item: item)'),
    );
  });

  test('legacy holding creation route opens asset buy mode', () {
    final source = File(
      'lib/navigation/moneyfy_router.dart',
    ).readAsStringSync();

    expect(source, contains('MoneyfyRoutePaths.assetBuyCreatePattern'));
    expect(source, contains('MoneyfyRoutePaths.holdingCreatePattern'));
    expect(source, contains('assetBuyMode: true'));
  });
}
