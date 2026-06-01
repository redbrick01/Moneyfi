enum PerformanceStatus { good, neutral, caution, unavailable }

enum BenchmarkDeltaStatus { outperforming, similar, lagging, unavailable }

enum RiskStatus { low, normal, elevated, unavailable }

class PerformanceJudgment {
  const PerformanceJudgment({
    required this.performanceStatus,
    required this.benchmarkDeltaStatus,
    required this.riskStatus,
    required this.headlineReason,
    required this.unavailableReasons,
  });

  final PerformanceStatus performanceStatus;
  final BenchmarkDeltaStatus benchmarkDeltaStatus;
  final RiskStatus riskStatus;
  final String headlineReason;
  final List<String> unavailableReasons;
}

PerformanceJudgment resolvePerformanceJudgment({
  required double netPerformance,
  required double? periodReturn,
  required double? benchmarkDelta,
  required double? volatility,
  required double? maxDrawdown,
  required int dailyReturnCount,
}) {
  final unavailableReasons = <String>[];
  final benchmarkDeltaStatus = _resolveBenchmarkDeltaStatus(
    benchmarkDelta,
    unavailableReasons,
  );
  final performanceStatus = _resolvePerformanceStatus(
    netPerformance: netPerformance,
    periodReturn: periodReturn,
    benchmarkDeltaStatus: benchmarkDeltaStatus,
    unavailableReasons: unavailableReasons,
  );
  final riskStatus = _resolveRiskStatus(
    volatility: volatility,
    maxDrawdown: maxDrawdown,
    dailyReturnCount: dailyReturnCount,
    unavailableReasons: unavailableReasons,
  );

  return PerformanceJudgment(
    performanceStatus: performanceStatus,
    benchmarkDeltaStatus: benchmarkDeltaStatus,
    riskStatus: riskStatus,
    headlineReason: _resolveHeadlineReason(
      performanceStatus,
      benchmarkDeltaStatus,
    ),
    unavailableReasons: List.unmodifiable(unavailableReasons),
  );
}

PerformanceStatus _resolvePerformanceStatus({
  required double netPerformance,
  required double? periodReturn,
  required BenchmarkDeltaStatus benchmarkDeltaStatus,
  required List<String> unavailableReasons,
}) {
  if (periodReturn == null) {
    unavailableReasons.add('performance');
    return PerformanceStatus.unavailable;
  }

  if (netPerformance < 0 || periodReturn < 0) {
    return PerformanceStatus.caution;
  }

  if (benchmarkDeltaStatus == BenchmarkDeltaStatus.lagging &&
      periodReturn < 0.02) {
    return PerformanceStatus.neutral;
  }

  if (periodReturn >= 0.01) {
    return PerformanceStatus.good;
  }

  return PerformanceStatus.neutral;
}

BenchmarkDeltaStatus _resolveBenchmarkDeltaStatus(
  double? benchmarkDelta,
  List<String> unavailableReasons,
) {
  if (benchmarkDelta == null) {
    unavailableReasons.add('benchmark');
    return BenchmarkDeltaStatus.unavailable;
  }

  if (benchmarkDelta >= 0.005) {
    return BenchmarkDeltaStatus.outperforming;
  }

  if (benchmarkDelta <= -0.005) {
    return BenchmarkDeltaStatus.lagging;
  }

  return BenchmarkDeltaStatus.similar;
}

RiskStatus _resolveRiskStatus({
  required double? volatility,
  required double? maxDrawdown,
  required int dailyReturnCount,
  required List<String> unavailableReasons,
}) {
  if (dailyReturnCount < 5 || volatility == null || maxDrawdown == null) {
    unavailableReasons.add('risk');
    return RiskStatus.unavailable;
  }

  if (volatility <= 0.08 && maxDrawdown >= -0.03) {
    return RiskStatus.low;
  }

  if (volatility >= 0.22 || maxDrawdown <= -0.12) {
    return RiskStatus.elevated;
  }

  return RiskStatus.normal;
}

String _resolveHeadlineReason(
  PerformanceStatus performanceStatus,
  BenchmarkDeltaStatus benchmarkDeltaStatus,
) {
  if (performanceStatus == PerformanceStatus.unavailable) {
    return '성과 데이터를 확인할 수 없습니다.';
  }

  if (performanceStatus == PerformanceStatus.caution) {
    return '손실이 발생해 성과 점검이 필요합니다.';
  }

  if (benchmarkDeltaStatus == BenchmarkDeltaStatus.outperforming) {
    return '벤치마크보다 양호한 성과입니다.';
  }

  if (benchmarkDeltaStatus == BenchmarkDeltaStatus.lagging) {
    return '수익은 났지만 시장 대비 성과는 낮습니다.';
  }

  if (performanceStatus == PerformanceStatus.good) {
    return '긍정적인 수익 흐름입니다.';
  }

  return '성과가 안정적인 범위에 있습니다.';
}
