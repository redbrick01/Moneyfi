import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/components/forms/market_search_field.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/portfolio/screens/asset_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';
import 'package:moneyfy/features/portfolio/widgets/portfolio_instrument_search.dart';

void main() {
  testWidgets('coin search is available with only cash and on coin details', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'moneyfy_coin_search_',
    );
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => directory.path);
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final path = const StringCodec().decodeMessage(message);
      if (path == 'assets/config.json') {
        return const StringCodec().encodeMessage('{}');
      }
      if (path == 'assets/market_catalog.json') {
        return ByteData.sublistView(File(path!).readAsBytesSync());
      }
      return null;
    });
    final db = AppDatabase.instance;
    addTearDown(() async {
      await db.close();
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMessageHandler('flutter/assets', null);
      directory.deleteSync(recursive: true);
    });
    final assetId = (await tester.runAsync(() async {
      final id = await db.createAsset(
        assetType: '코인',
        title: '코인 지갑',
        alias: '',
        hidden: false,
        currencyCode: 'KRW',
        value: '0',
        change: '',
        icon: Icons.wallet,
        quantityLabel: '',
        quantityValue: '',
        averageLabel: '',
        averageValue: '',
        note: '',
      );
      await db.createCashAccount(
        assetId: id,
        currencyCode: 'KRW',
        name: '원화',
        note: '',
        balance: 1000,
      );
      return id;
    }))!;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AssetDetailPage(assetId: assetId),
        ),
      );
      for (var i = 0; i < 100 && find.text('종목 검색').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    expect(find.text('종목 검색'), findsOneWidget);
    expect(find.text('현금 계좌'), findsOneWidget);
    final search = tester.widget<MarketSearchField<MarketSearchResult>>(
      find.byType(MarketSearchField<MarketSearchResult>),
    );
    final results = (await tester.runAsync(
      () async => search.localSearch('BTC'),
    ))!;
    expect(results.any((result) => result.symbol == 'BTC'), isTrue);
    final bitcoin = results.firstWhere((result) => result.symbol == 'BTC');
    search.onSelected(bitcoin);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final details = find.byType(HoldingDetailPage);
    expect(tester.widget<HoldingDetailPage>(details).preferredAssetId, assetId);
    final detailSearch = find.descendant(
      of: details,
      matching: find.byType(PortfolioInstrumentSearch),
    );
    expect(
      tester.widget<PortfolioInstrumentSearch>(detailSearch).assetType,
      '코인',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
