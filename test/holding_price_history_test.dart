import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneyfy/components/charts/value_history_card.dart';
import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/portfolio/widgets/holding_price_history_card.dart';

const _etf = HoldingItem(
  assetType: '펀드',
  name: '테스트 ETF',
  symbol: '379800',
  quantity: 1,
  averagePrice: 1,
  currentPrice: 1,
  note: '',
  transactions: [],
);

const _overseas = HoldingItem(
  assetType: '주식',
  currencyCode: 'USD',
  exchangeCode: 'NAS',
  name: '테스트 해외 주식',
  symbol: 'AAPL',
  quantity: 1,
  averagePrice: 230000,
  averagePriceSource: 180,
  currentPrice: 1,
  note: '',
  transactions: [],
);

void main() {
  test('periods follow calendar boundaries and clamp the end of a month', () {
    final end = DateTime.utc(2024, 5, 31);
    expect(HistoryPeriod.week.startAt(end), DateTime.utc(2024, 5, 25));
    expect(HistoryPeriod.quarter.startAt(end), DateTime.utc(2024, 2, 29));
    expect(HistoryPeriod.tenYears.startAt(end), DateTime.utc(2014, 5, 31));
  });

  test(
    'retries throttled KIS chart reads without reissuing the token',
    () async {
      var requests = 0;
      var tokenRequests = 0;
      final service = _service((request) async {
        expect(request.headers['authorization'], 'Bearer token');
        return switch (++requests) {
          1 => http.Response('{"rt_cd":"1","msg_cd":"EGW00201"}', 500),
          2 => http.Response('', 429),
          _ => _response([
            {'stck_bsop_date': '20260715', 'stck_clpr': '26000'},
          ]),
        };
      }, onTokenRequest: () => tokenRequests++);
      final closes = await service.fetchDailyCloses(
        _etf,
        from: DateTime.utc(2026, 7, 15),
        through: DateTime.utc(2026, 7, 15),
      );
      expect(requests, 3);
      expect(tokenRequests, 1);
      expect(closes.single.price, 26000);
    },
  );

  test('uses the last completed session cutoff in each market', () {
    final service = _service((_) async => throw StateError('No HTTP expected'));
    expect(
      service.latestDailyCloseDate(_etf, now: DateTime.utc(2026, 7, 15, 6, 29)),
      DateTime.utc(2026, 7, 14),
    );
    expect(
      service.latestDailyCloseDate(_etf, now: DateTime.utc(2026, 7, 15, 6, 30)),
      DateTime.utc(2026, 7, 15),
    );
    expect(
      service.latestDailyCloseDate(
        _overseas,
        now: DateTime.utc(2026, 7, 15, 20),
      ),
      DateTime.utc(2026, 7, 15),
    );
    expect(
      service.latestDailyCloseDate(
        _overseas,
        now: DateTime.utc(2026, 1, 15, 20),
      ),
      DateTime.utc(2026, 1, 14),
    );
  });

  testWidgets('plots only trades with a matching displayed close', (
    tester,
  ) async {
    final first = DateTime.now().toUtc().subtract(const Duration(days: 21));
    String date(int offset) {
      final point = first.add(Duration(days: offset));
      return point.toIso8601String().split('T').first;
    }

    TransactionItem trade(
      String day,
      String type, {
      String? action,
      String amount = '100',
      String quantity = '1',
      double? grossAmount,
    }) {
      return TransactionItem(
        date: day,
        type: type,
        name: '테스트 거래',
        amount: amount,
        quantity: quantity,
        grossAmount: grossAmount,
        ledgerAction: action,
      );
    }

    final service = _service(
      (_) async => _response([
        {'stck_bsop_date': date(0).replaceAll('-', ''), 'stck_clpr': '104'},
        {'stck_bsop_date': date(2).replaceAll('-', ''), 'stck_clpr': '110'},
        {'stck_bsop_date': date(4).replaceAll('-', ''), 'stck_clpr': '100'},
        {'stck_bsop_date': date(6).replaceAll('-', ''), 'stck_clpr': '108'},
      ]),
    );
    final holding = HoldingItem(
      assetType: '주식',
      name: '테스트 주식',
      symbol: '005930',
      quantity: 0,
      averagePrice: 0,
      currentPrice: 108,
      note: '',
      transactions: [
        trade(date(0), '매수', action: 'buy', quantity: '2', grossAmount: 260),
        trade(date(2).replaceAll('-', '.'), '매도'),
        trade('${date(4)}T14:30:00', '매수'),
        trade(date(4), '매도', action: 'sell'),
        trade(date(4), '매도', action: 'sell'),
        trade(date(4), '배당', action: 'dividend', amount: '20', quantity: '0'),
        trade(date(6), '배당', action: 'dividend', amount: '50', quantity: '0'),
        trade(date(1), '매수'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HoldingPriceHistoryCard(
              holding: holding,
              marketData: service,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = find.bySemanticsLabel('거래일별 종가 차트');
    final plot = find
        .descendant(of: chart, matching: find.byType(CustomPaint))
        .first;
    final size = tester.getSize(plot);
    final colors = tester.element(chart).colors;
    const inset = 4.0;
    double y(double price) =>
        inset + (110.8 - price) / (110.8 - 99.2) * (size.height - 2 * inset);
    expect(
      plot,
      paints
        ..something(
          (method, args) =>
              method == #drawPath && (args[1] as Paint).shader != null,
        )
        ..path(color: VisualSpec.brand.seedColor, style: PaintingStyle.stroke)
        ..path(includes: [Offset(inset, y(104))], color: colors.negativeOn)
        ..rect(
          rect: Rect.fromCircle(
            center: Offset(inset + (1 / 3) * (size.width - 2 * inset), y(110)),
            radius: 4,
          ),
          color: colors.positiveOn,
        )
        ..path(color: colors.negativeOn)
        ..rect(color: colors.positiveOn)
        ..circle(color: colors.neutralTextMuted)
        ..circle(color: colors.neutralTextMuted),
    );
    expect(plot, paintsExactlyCountTimes(#drawRect, 2));
    expect(plot, paintsExactlyCountTimes(#drawCircle, 2));
    expect(plot, paintsExactlyCountTimes(#drawArc, 0));
    expect(find.textContaining('매수'), findsNothing);
    expect(find.textContaining('매도'), findsNothing);
    expect(find.textContaining('배당'), findsNothing);

    Future<void> select(int index) async {
      final rect = tester.getRect(plot);
      final x = rect.left + inset + index / 3 * (rect.width - 2 * inset);
      await tester.tapAt(Offset(x, rect.center.dy));
      await tester.pump();
    }

    await select(0);
    expect(find.text('매수 2주 · ₩260'), findsOneWidget);
    await select(2);
    expect(find.text('매수 1주 · ₩100'), findsOneWidget);
    expect(find.text('매도 2주 · ₩200'), findsOneWidget);
    expect(find.text('배당 ₩20'), findsOneWidget);
    expect(find.text('매수 2주 · ₩260'), findsNothing);
    final dateLabel = find.text('${date(4)} 종가');
    for (final label in ['매수 1주 · ₩100', '매도 2주 · ₩200', '배당 ₩20']) {
      final badge = find.widgetWithText(MoneyfyBadge, label);
      final fill =
          tester
                  .widget<Container>(
                    find
                        .descendant(of: badge, matching: find.byType(Container))
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(fill.color, tester.element(badge).surfaces.surfaceRaised);
      expect(
        tester.getTopLeft(badge).dx,
        greaterThan(tester.getTopRight(dateLabel).dx),
      );
      expect(
        tester.getBottomLeft(badge).dy,
        lessThan(tester.getTopLeft(plot).dy),
      );
    }
    final buyBadge = find.widgetWithText(MoneyfyBadge, '매수 1주 · ₩100');
    expect(
      tester.getTopLeft(buyBadge).dy,
      closeTo(tester.getTopLeft(dateLabel).dy, 1),
    );
    tester.view.physicalSize = Size(
      tester.view.devicePixelRatio * 360,
      tester.view.physicalSize.height,
    );
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pump();
    expect(find.text('배당 ₩20'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await select(3);
    expect(find.text('배당 ₩50'), findsOneWidget);
    expect(find.textContaining('매수'), findsNothing);
    expect(find.textContaining('매도'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '1주'));
    await tester.pumpAndSettle();
    expect(chart, findsNothing);
  });

  test(
    'loads older KRX ETF pages and returns valid closes in date order',
    () async {
      final ends = <String>[];
      final service = _service((request) async {
        final query = request.url.queryParameters;
        ends.add(query['FID_INPUT_DATE_2']!);
        expect(request.headers['tr_id'], 'FHKST03010100');
        expect(query['FID_INPUT_ISCD'], '379800');
        expect(query['FID_PERIOD_DIV_CODE'], 'D');
        expect(query['FID_ORG_ADJ_PRC'], '1');
        expect(query['FID_INPUT_DATE_1'], '20160715');
        return ends.length == 1
            ? _response([
                {'stck_bsop_date': '20260715', 'stck_clpr': '26,000'},
                {'stck_bsop_date': '20260714', 'stck_clpr': '25500'},
                {'stck_bsop_date': '20260631', 'stck_clpr': '1'},
                ...List.generate(97, (_) => <String, String>{}),
              ])
            : _response([
                {'stck_bsop_date': '20260713', 'stck_clpr': 'NaN'},
                {'stck_bsop_date': '20160715', 'stck_clpr': '10,000'},
              ]);
      });

      final closes = await service.fetchDailyCloses(
        _etf,
        from: DateTime.utc(2016, 7, 15),
        through: DateTime.utc(2026, 7, 15),
      );
      expect(ends, ['20260715', '20260713']);
      expect(closes.map((item) => item.price), [10000, 25500, 26000]);
      expect(closes.first.date, DateTime.utc(2016, 7, 15));
    },
  );

  test(
    'moves the overseas date cursor even with a continuation header',
    () async {
      final requests = <(String?, String?)>[];
      final service = _service((request) async {
        final query = request.url.queryParameters;
        requests.add((query['BYMD'], request.headers['tr_cont']));
        expect(request.headers['tr_id'], 'HHDFS76240000');
        expect(query['EXCD'], 'NAS');
        expect(query['SYMB'], 'AAPL');
        expect(query['GUBN'], '0');
        return switch (requests.length) {
          1 => _response([
            {'xymd': '20260715', 'clos': '202.12'},
            {'xymd': '20260714', 'clos': '200.53'},
          ], continuation: 'M'),
          2 => _response([
            {'xymd': '20260714', 'clos': '200.53'},
            {'xymd': '20260713', 'clos': '199.01'},
          ]),
          _ => _response([
            {'xymd': '20260710', 'clos': '197.16'},
          ]),
        };
      });

      final closes = await service.fetchDailyCloses(
        _overseas,
        from: DateTime.utc(2026, 7, 10),
        through: DateTime.utc(2026, 7, 15),
      );
      expect(requests, [
        ('20260715', null),
        ('20260713', null),
        ('20260712', null),
      ]);
      expect(closes.map((item) => item.price), [
        197.16,
        199.01,
        200.53,
        202.12,
      ]);
    },
  );

  testWidgets(
    'overseas card retries, explores prices and reuses cached ranges',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final failing = Completer<http.Response>();
      final older = Completer<http.Response>();
      var transactionOpened = false;
      final dailyRequests = <http.Request>[];
      final service = _service((request) async {
        dailyRequests.add(request);
        if (dailyRequests.length == 1) return failing.future;
        if (dailyRequests.length == 2) {
          final through = DateTime.parse(request.url.queryParameters['BYMD']!);
          return _response([
            {'xymd': _key(through), 'clos': '150.25'},
            {
              'xymd': _key(through.subtract(const Duration(days: 2))),
              'clos': '125.50',
            },
          ]);
        }
        if (dailyRequests.length == 4) return older.future;
        return _response([]);
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HoldingPriceHistoryCard(
                    holding: _overseas,
                    marketData: service,
                  ),
                  TextButton(
                    onPressed: () => transactionOpened = true,
                    child: const Text('거래 내역'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('시세 불러오는 중'), findsOneWidget);
      await tester.tap(find.text('거래 내역'));
      expect(transactionOpened, isTrue);

      failing.complete(http.Response('server error', 500));
      await tester.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text(r'$150.25'), findsOneWidget);
      expect(find.text('기간 등락률 +19.72%'), findsOneWidget);
      for (final period in HistoryPeriod.values) {
        expect(find.widgetWithText(ChoiceChip, period.label), findsOneWidget);
      }
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '3개월'))
            .selected,
        isTrue,
      );
      final chart = find.bySemanticsLabel('거래일별 종가 차트');
      final averageLabel = find.text(r'평단  $180');
      expect(averageLabel, findsOneWidget);
      final plot = find
          .descendant(of: chart, matching: find.byType(CustomPaint))
          .first;
      final pad = (180 - 125.50) * 0.08;
      final chartContext = tester.element(chart);
      const inset = 0.0;
      final y =
          inset +
          ((180 + pad) - 180) /
              ((180 + pad) - (125.50 - pad)) *
              (tester.getSize(plot).height - 2 * inset);
      expect(
        tester.getBottomRight(averageLabel).dy,
        lessThan(tester.getTopLeft(plot).dy),
      );
      expect(
        plot,
        paints
          ..something(
            (method, args) =>
                method == #drawPath && (args[1] as Paint).shader != null,
          )
          ..path(style: PaintingStyle.stroke, color: VisualSpec.brand.seedColor)
          ..circle(y: y, color: chartContext.colors.neutralTextMuted),
      );
      await tester.tapAt(
        tester.getTopLeft(chart) + Offset(2, tester.getSize(chart).height / 2),
      );
      await tester.pump();
      expect(find.text(r'$125.50'), findsOneWidget);

      final requestsBefore = dailyRequests.length;
      await tester.tap(find.widgetWithText(ChoiceChip, '1주'));
      await tester.pumpAndSettle();
      expect(dailyRequests, hasLength(requestsBefore));
      await tester.tap(find.widgetWithText(ChoiceChip, '10년'));
      await tester.pump();
      expect(find.text('10년 시세 불러오는 중'), findsOneWidget);
      expect(find.text(r'$150.25'), findsOneWidget);
      expect(averageLabel, findsOneWidget);
      final olderDate = dailyRequests.last.url.queryParameters['BYMD']!;
      older.complete(
        _response([
          {'xymd': olderDate, 'clos': '95.00'},
        ]),
      );
      await tester.pumpAndSettle();
      expect(dailyRequests, hasLength(requestsBefore + 2));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10년'))
            .selected,
        isTrue,
      );
      expect(find.text(r'$150.25'), findsOneWidget);
      expect(find.textContaining('10년 중 제공 구간'), findsOneWidget);
      await tester.tapAt(
        tester.getTopLeft(chart) + Offset(2, tester.getSize(chart).height / 2),
      );
      await tester.pump();
      expect(find.text(r'$95'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

String _key(DateTime date) =>
    date.toIso8601String().split('T').first.replaceAll('-', '');

MarketDataService _service(
  Future<http.Response> Function(http.Request) dailyHandler, {
  VoidCallback? onTokenRequest,
}) {
  return MarketDataService.test(
    kisBaseUrl: 'https://kis.test',
    kisAppKey: 'app-key',
    kisAppSecret: 'app-secret',
    client: MockClient((request) async {
      if (request.url.path == '/oauth2/tokenP') {
        onTokenRequest?.call();
        return http.Response(
          jsonEncode({'access_token': 'token', 'expires_in': 3600}),
          200,
        );
      }
      return dailyHandler(request);
    }),
  );
}

http.Response _response(
  List<Map<String, String>> rows, {
  String? continuation,
}) {
  return http.Response(
    jsonEncode({'rt_cd': '0', 'output2': rows}),
    200,
    headers: {'tr_cont': ?continuation},
  );
}
