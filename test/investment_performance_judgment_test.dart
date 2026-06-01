import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_performance/performance_judgment.dart';

void main() {
  group('resolvePerformanceJudgment', () {
    test('marks positive return and positive benchmark delta as good', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 420000,
        periodReturn: 0.032,
        benchmarkDelta: 0.011,
        volatility: 0.12,
        maxDrawdown: -0.035,
        dailyReturnCount: 35,
      );

      expect(judgment.performanceStatus, PerformanceStatus.good);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.outperforming);
      expect(judgment.riskStatus, RiskStatus.normal);
      expect(judgment.headlineReason, contains('벤치마크'));
    });

    test('marks positive return with negative benchmark delta as neutral', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 120000,
        periodReturn: 0.018,
        benchmarkDelta: -0.012,
        volatility: 0.10,
        maxDrawdown: -0.025,
        dailyReturnCount: 30,
      );

      expect(judgment.performanceStatus, PerformanceStatus.neutral);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.lagging);
      expect(judgment.headlineReason, contains('시장 대비'));
    });

    test('marks negative return as caution', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: -80000,
        periodReturn: -0.015,
        benchmarkDelta: 0.004,
        volatility: 0.08,
        maxDrawdown: -0.02,
        dailyReturnCount: 28,
      );

      expect(judgment.performanceStatus, PerformanceStatus.caution);
      expect(judgment.headlineReason, contains('손실'));
    });

    test('keeps performance available when benchmark is missing', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: null,
        volatility: 0.09,
        maxDrawdown: -0.02,
        dailyReturnCount: 24,
      );

      expect(judgment.performanceStatus, PerformanceStatus.good);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.unavailable);
      expect(judgment.unavailableReasons, contains('benchmark'));
    });

    test('marks risk unavailable when daily returns are insufficient', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.001,
        volatility: 0.10,
        maxDrawdown: -0.02,
        dailyReturnCount: 19,
      );

      expect(judgment.riskStatus, RiskStatus.unavailable);
      expect(judgment.unavailableReasons, contains('risk'));
    });

    test('marks performance unavailable when period return is missing', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: null,
        benchmarkDelta: 0.001,
        volatility: 0.10,
        maxDrawdown: -0.02,
        dailyReturnCount: 20,
      );

      expect(judgment.performanceStatus, PerformanceStatus.unavailable);
      expect(judgment.unavailableReasons, contains('performance'));
    });

    test('marks risk low at low volatility and drawdown', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.001,
        volatility: 0.08,
        maxDrawdown: -0.03,
        dailyReturnCount: 20,
      );

      expect(judgment.riskStatus, RiskStatus.low);
    });

    test('marks risk elevated for high volatility', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.001,
        volatility: 0.22,
        maxDrawdown: -0.03,
        dailyReturnCount: 20,
      );

      expect(judgment.riskStatus, RiskStatus.elevated);
    });

    test('marks risk elevated for large drawdown', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.001,
        volatility: 0.08,
        maxDrawdown: -0.12,
        dailyReturnCount: 20,
      );

      expect(judgment.riskStatus, RiskStatus.elevated);
    });

    test('marks benchmark delta similar inside threshold band', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.004,
        volatility: 0.10,
        maxDrawdown: -0.02,
        dailyReturnCount: 20,
      );

      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.similar);
    });

    test('marks benchmark delta boundaries inclusively', () {
      final outperforming = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.005,
        volatility: 0.10,
        maxDrawdown: -0.02,
        dailyReturnCount: 20,
      );
      final lagging = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: -0.005,
        volatility: 0.10,
        maxDrawdown: -0.02,
        dailyReturnCount: 20,
      );

      expect(
        outperforming.benchmarkDeltaStatus,
        BenchmarkDeltaStatus.outperforming,
      );
      expect(lagging.benchmarkDeltaStatus, BenchmarkDeltaStatus.lagging);
    });
  });
}
