import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/utils/risk_adjusted_performance_calculator.dart';

void main() {
  group('calculateCashFlowAdjustedDailyReturn', () {
    test('excludes deposit from daily return', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 1000000,
          endingValue: 1500000,
          externalCashFlow: 500000,
        ),
        0,
      );
    });

    test('excludes withdrawal from daily return', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 1000000,
          endingValue: 700000,
          externalCashFlow: -300000,
        ),
        0,
      );
    });

    test('includes market gain when there is no external cash flow', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 1000000,
          endingValue: 1100000,
          externalCashFlow: 0,
        ),
        closeTo(0.1, 0.000000001),
      );
    });

    test('excludes deposit and keeps market gain', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 1000000,
          endingValue: 1650000,
          externalCashFlow: 500000,
        ),
        closeTo(0.15, 0.000000001),
      );
    });

    test('excludes withdrawal and keeps market loss', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 1000000,
          endingValue: 600000,
          externalCashFlow: -300000,
        ),
        closeTo(-0.1, 0.000000001),
      );
    });

    test('returns null when beginning value is zero', () {
      expect(
        calculateCashFlowAdjustedDailyReturn(
          beginningValue: 0,
          endingValue: 100000,
          externalCashFlow: 100000,
        ),
        isNull,
      );
    });
  });

  group('return series metrics', () {
    test('compounds cumulative return', () {
      expect(calculateCumulativeReturn([0.1, -0.1]), closeTo(-0.01, 1e-12));
    });

    test('annualized return uses daily mean', () {
      expect(
        calculateAnnualizedReturn(List.filled(10, 0.001)),
        closeTo(0.252, 1e-12),
      );
    });

    test('annualized volatility uses sample standard deviation', () {
      final dailyReturns = [0.01, 0.02, -0.01, 0.0];
      final annualizedVolatility = calculateAnnualizedVolatility(dailyReturns);

      expect(annualizedVolatility, closeTo(0.20493901531919198, 1e-12));
    });

    test('sharpe ratio returns null for zero volatility', () {
      expect(
        calculateSharpeRatio(List.filled(60, 0.001), minimumObservations: 60),
        isNull,
      );
    });

    test('sharpe ratio requires minimum observations', () {
      expect(
        calculateSharpeRatio(
          List.generate(59, (index) => index.isEven ? 0.01 : -0.005),
          minimumObservations: 60,
        ),
        isNull,
      );
    });

    test('sharpe ratio uses annualized return and volatility', () {
      final dailyReturns = List.generate(
        60,
        (index) => index.isEven ? 0.01 : -0.002,
      );

      expect(
        calculateSharpeRatio(dailyReturns, minimumObservations: 60),
        closeTo(10.494442973942606, 1e-12),
      );
    });

    test('sharpe ratio subtracts annual risk-free rate', () {
      final dailyReturns = List.generate(
        60,
        (index) => index.isEven ? 0.01 : -0.002,
      );

      expect(
        calculateSharpeRatio(
          dailyReturns,
          riskFreeRate: 0.0525,
          minimumObservations: 60,
        ),
        closeTo(9.947857402383095, 1e-12),
      );
    });
  });

  group('calculateMaxDrawdown', () {
    test('uses running peak', () {
      final result = calculateMaxDrawdown([100, 120, 90, 130]);

      expect(result, isNotNull);
      expect(result!.maxDrawdown, closeTo(-0.25, 1e-12));
      expect(result.peakValue, 120);
      expect(result.troughValue, 90);
      expect(result.peakIndex, 1);
      expect(result.troughIndex, 2);
    });

    test('returns zero drawdown when portfolio never falls', () {
      final result = calculateMaxDrawdown([100, 110, 120]);

      expect(result, isNotNull);
      expect(result!.maxDrawdown, 0);
    });

    test('returns null when there are not enough values', () {
      expect(calculateMaxDrawdown([100]), isNull);
    });
  });
}
