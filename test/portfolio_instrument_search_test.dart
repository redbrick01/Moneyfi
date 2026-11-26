import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneyfy/components/forms/market_search_field.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';
import 'package:moneyfy/features/portfolio/widgets/portfolio_instrument_search.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_page.dart';

void main() {
  testWidgets(
    'empty portfolio opens a market detail without creating records',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('moneyfy_search_');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => directory.path);
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final path = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (path == 'assets/market_catalog.json') {
          return ByteData.sublistView(File(path).readAsBytesSync());
        }
        if (path == 'assets/config.json') {
          return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
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
      Future<List<int>> counts() async => [
        for (final table in [
          'assets',
          'holdings',
          'transaction_events',
          'transaction_lines',
        ])
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n'),
      ];
      final before = await tester.runAsync(counts);
      expect(before, [0, 0, 0, 0]);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const PortfolioPage()),
        );
        for (var i = 0; i < 100 && find.text('종목 검색').evaluate().isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      final field = find.byType(TextField).first;
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '셀트리온');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final suggestion = find.widgetWithText(ListTile, '셀트리온');
      for (var i = 0; i < 20 && suggestion.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(suggestion);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('068270 · KOSPI · 주식'), findsWidgets);
      expect(find.text('시세 미제공'), findsOneWidget);
      expect(find.text('시장 정보'), findsOneWidget);
      expect(find.text('보유 정보'), findsNothing);
      expect(find.text('거래 내역'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(await tester.runAsync(counts), before);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'selecting a closed position in another account opens its existing history',
    (tester) async {
      final assets = [
        for (final id in [1, 2])
          AssetItem(
            assetType: '주식',
            title: '계좌 $id',
            alias: '',
            value: '',
            change: '',
            icon: Icons.wallet,
            quantityLabel: '',
            quantityValue: '',
            averageLabel: '',
            averageValue: '',
            note: '',
            transactions: const [],
            holdings: [
              HoldingItem(
                id: id,
                clientId: 'holding-$id',
                currencyCode: 'USD',
                exchangeCode: 'NAS',
                name: 'Apple',
                symbol: 'AAPL',
                quantity: id == 1 ? 1 : 0,
                averagePrice: 0,
                currentPrice: 0,
                note: '',
                transactions: const [],
              ),
            ],
          ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: PortfolioInstrumentSearch(
                assets: assets,
                onHoldingClosed: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/holdings/:id',
            builder: (_, state) => Text(state.uri.toString()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      final search = tester.widget<MarketSearchField<MarketSearchResult>>(
        find.byType(MarketSearchField<MarketSearchResult>),
      );
      search.onSelected(
        MarketSearchResult.fromHolding(assets.first.holdings.single, '주식'),
      );
      await tester.pumpAndSettle();
      expect(find.text('계좌 1'), findsOneWidget);
      await tester.tap(find.text('계좌 2'));
      await tester.pumpAndSettle();
      expect(
        find.text('/holdings/2?holdingClientId=holding-2'),
        findsOneWidget,
      );
    },
  );
}
