import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  String dateForDay(int day) => '2026-05-${day.toString().padLeft(2, '0')}';

  Future<void> insertPortfolioReturn({
    required int day,
    required double dailyReturn,
  }) {
    final date = dateForDay(day);
    return db.customStatement(
      '''
        INSERT INTO portfolio_daily_returns (
          local_user_id,
          return_date,
          beginning_value_krw,
          ending_value_krw,
          portfolio_value_krw,
          external_cash_flow_krw,
          daily_return,
          data_quality,
          calculation_version,
          created_at,
          updated_at
        ) VALUES ('local', ?, 1000000, 1000000, 1000000, 0, ?, 'complete', 1, ?, ?)
      ''',
      [date, dailyReturn, '${date}T00:00:00', '${date}T00:00:00'],
    );
  }

  Future<void> seedPortfolioReturns({
    required int fromDay,
    required int toDay,
    required double dailyReturn,
  }) async {
    for (var day = fromDay; day <= toDay; day += 1) {
      await insertPortfolioReturn(day: day, dailyReturn: dailyReturn);
    }
  }

  Future<void> seedBenchmarkPrices({
    required String benchmarkCode,
    required int fromDay,
    required int toDay,
    required double dailyReturn,
    double initialPrice = 100,
    String currencyCode = 'KRW',
    double? fxRateToKrw,
  }) async {
    var price = initialPrice;
    for (var day = fromDay; day <= toDay; day += 1) {
      await db.saveBenchmarkPrice(
        benchmarkCode: benchmarkCode,
        priceDate: dateForDay(day),
        closePrice: price,
        currencyCode: currencyCode,
        fxRateToKrw: fxRateToKrw,
        source: 'fixture',
      );
      price *= 1 + dailyReturn;
    }
  }

  test('benchmark prices table is available', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'benchmark_prices'",
        )
        .get();

    expect(rows.map((row) => row.read<String>('name')), ['benchmark_prices']);
  });

  test('benchmark comparison uses common dates only', () async {
    await seedPortfolioReturns(fromDay: 2, toDay: 22, dailyReturn: 0.01);
    await seedBenchmarkPrices(
      benchmarkCode: 'SP500',
      fromDay: 1,
      toDay: 21,
      dailyReturn: 0.005,
    );

    final result = await db.compareBenchmarkToPortfolioReturns(
      benchmarkCode: 'SP500',
    );

    expect(result, isNotNull);
    expect(result!.commonObservationCount, 20);
    expect(result.portfolioCumulativeReturn, closeTo(1.01.pow(20) - 1, 1e-12));
    expect(result.benchmarkCumulativeReturn, closeTo(1.005.pow(20) - 1, 1e-12));
    expect(
      result.excessReturn,
      closeTo(
        result.portfolioCumulativeReturn - result.benchmarkCumulativeReturn,
        1e-12,
      ),
    );
  });

  test('benchmark period comparison uses boundary prices only', () async {
    await seedPortfolioReturns(fromDay: 2, toDay: 3, dailyReturn: 0.10);
    await db.saveBenchmarkPrice(
      benchmarkCode: 'SP500',
      priceDate: '2026-05-01',
      closePrice: 100,
      currencyCode: 'POINTS',
    );
    await db.saveBenchmarkPrice(
      benchmarkCode: 'SP500',
      priceDate: '2026-05-31',
      closePrice: 105,
      currencyCode: 'POINTS',
    );

    final result = await db.compareBenchmarkPeriodReturn(
      benchmarkCode: 'SP500',
      from: '2026-05-01',
      to: '2026-05-31',
    );

    expect(result, isNotNull);
    expect(result!.benchmarkStartDate, '2026-05-01');
    expect(result.benchmarkEndDate, '2026-05-31');
    expect(result.portfolioCumulativeReturn, closeTo(1.1 * 1.1 - 1, 1e-12));
    expect(result.benchmarkPeriodReturn, closeTo(0.05, 1e-12));
    expect(
      result.excessReturn,
      closeTo(result.portfolioCumulativeReturn - 0.05, 1e-12),
    );
  });

  test(
    'benchmark period comparison works when daily series is insufficient',
    () async {
      await insertPortfolioReturn(day: 2, dailyReturn: 0.03);
      await db.saveBenchmarkPrice(
        benchmarkCode: 'SP500',
        priceDate: '2026-05-01',
        closePrice: 100,
        currencyCode: 'POINTS',
      );
      await db.saveBenchmarkPrice(
        benchmarkCode: 'SP500',
        priceDate: '2026-05-30',
        closePrice: 102,
        currencyCode: 'POINTS',
      );

      final periodResult = await db.compareBenchmarkPeriodReturn(
        benchmarkCode: 'SP500',
        from: '2026-05-01',
        to: '2026-05-31',
      );
      final seriesResult = await db.compareBenchmarkToPortfolioReturns(
        benchmarkCode: 'SP500',
        from: '2026-05-01',
        to: '2026-05-31',
      );

      expect(periodResult, isNotNull);
      expect(periodResult!.benchmarkPeriodReturn, closeTo(0.02, 1e-12));
      expect(seriesResult, isNull);
    },
  );

  test('benchmark comparison requires minimum common observations', () async {
    await seedPortfolioReturns(fromDay: 2, toDay: 20, dailyReturn: 0.01);
    await seedBenchmarkPrices(
      benchmarkCode: 'KOSPI',
      fromDay: 1,
      toDay: 20,
      dailyReturn: 0.01,
    );

    final result = await db.compareBenchmarkToPortfolioReturns(
      benchmarkCode: 'KOSPI',
    );

    expect(result, isNull);
  });

  test('benchmark comparison uses adjusted close when available', () async {
    await seedPortfolioReturns(fromDay: 2, toDay: 21, dailyReturn: 0.01);
    for (var day = 1; day <= 21; day += 1) {
      await db.saveBenchmarkPrice(
        benchmarkCode: 'ADJUSTED',
        priceDate: dateForDay(day),
        closePrice: 100 + day * 10,
        adjustedClosePrice: 100 * (1.01.pow(day - 1)),
      );
    }

    final result = await db.compareBenchmarkToPortfolioReturns(
      benchmarkCode: 'ADJUSTED',
    );

    expect(result, isNotNull);
    expect(result!.commonObservationCount, 20);
    expect(result.benchmarkCumulativeReturn, closeTo(1.01.pow(20) - 1, 1e-12));
    expect(result.excessReturn, closeTo(0, 1e-12));
  });

  test('foreign benchmark converts prices to KRW', () async {
    await insertPortfolioReturn(day: 2, dailyReturn: 0.21);
    await db.saveBenchmarkPrice(
      benchmarkCode: 'NASDAQ100',
      priceDate: '2026-05-01',
      closePrice: 100,
      currencyCode: 'USD',
      fxRateToKrw: 1000,
    );
    await db.saveBenchmarkPrice(
      benchmarkCode: 'NASDAQ100',
      priceDate: '2026-05-02',
      closePrice: 110,
      currencyCode: 'USD',
      fxRateToKrw: 1100,
    );

    final result = await db.compareBenchmarkToPortfolioReturns(
      benchmarkCode: 'NASDAQ100',
      minimumCommonObservations: 1,
    );

    expect(result, isNotNull);
    expect(result!.benchmarkCumulativeReturn, closeTo(0.21, 1e-12));
    expect(result.excessReturn, closeTo(0, 1e-12));
  });

  test('missing benchmark data is insufficient', () async {
    await seedPortfolioReturns(fromDay: 2, toDay: 22, dailyReturn: 0.01);

    final result = await db.compareBenchmarkToPortfolioReturns(
      benchmarkCode: 'MISSING',
    );

    expect(result, isNull);
  });
}

extension _PowDouble on double {
  double pow(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i += 1) {
      result *= this;
    }
    return result;
  }
}
