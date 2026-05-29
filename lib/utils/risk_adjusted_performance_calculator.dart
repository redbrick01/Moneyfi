import 'dart:math' as math;

const int tradingDaysPerYear = 252;
const double performanceCalculationTolerance = 0.000000001;

double? calculateCashFlowAdjustedDailyReturn({
  required double beginningValue,
  required double endingValue,
  required double externalCashFlow,
}) {
  if (!_isFinite(beginningValue) ||
      !_isFinite(endingValue) ||
      !_isFinite(externalCashFlow)) {
    return null;
  }
  if (beginningValue.abs() <= performanceCalculationTolerance) return null;
  return (endingValue - beginningValue - externalCashFlow) / beginningValue;
}

double? calculateCumulativeReturn(Iterable<double> dailyReturns) {
  final returns = _validatedReturns(dailyReturns);
  if (returns == null || returns.isEmpty) return null;

  var compounded = 1.0;
  for (final dailyReturn in returns) {
    compounded *= 1 + dailyReturn;
  }
  return compounded - 1;
}

double? calculateAnnualizedReturn(
  Iterable<double> dailyReturns, {
  int periodsPerYear = tradingDaysPerYear,
}) {
  final returns = _validatedReturns(dailyReturns);
  if (returns == null || returns.isEmpty || periodsPerYear <= 0) return null;

  final meanReturn = returns.reduce((a, b) => a + b) / returns.length;
  return meanReturn * periodsPerYear;
}

double? calculateAnnualizedVolatility(
  Iterable<double> dailyReturns, {
  int periodsPerYear = tradingDaysPerYear,
}) {
  final returns = _validatedReturns(dailyReturns);
  if (returns == null || returns.length < 2 || periodsPerYear <= 0) {
    return null;
  }

  final meanReturn = returns.reduce((a, b) => a + b) / returns.length;
  final squaredDiffSum = returns.fold<double>(
    0,
    (sum, dailyReturn) =>
        sum + math.pow(dailyReturn - meanReturn, 2).toDouble(),
  );
  final sampleVariance = squaredDiffSum / (returns.length - 1);
  return math.sqrt(sampleVariance) * math.sqrt(periodsPerYear);
}

double? calculateSharpeRatio(
  Iterable<double> dailyReturns, {
  double riskFreeRate = 0,
  int periodsPerYear = tradingDaysPerYear,
  int minimumObservations = 60,
}) {
  final returns = _validatedReturns(dailyReturns);
  if (returns == null ||
      returns.length < minimumObservations ||
      !_isFinite(riskFreeRate)) {
    return null;
  }

  final annualizedReturn = calculateAnnualizedReturn(
    returns,
    periodsPerYear: periodsPerYear,
  );
  final annualizedVolatility = calculateAnnualizedVolatility(
    returns,
    periodsPerYear: periodsPerYear,
  );
  if (annualizedReturn == null ||
      annualizedVolatility == null ||
      annualizedVolatility.abs() <= performanceCalculationTolerance) {
    return null;
  }

  return (annualizedReturn - riskFreeRate) / annualizedVolatility;
}

MaxDrawdownResult? calculateMaxDrawdown(Iterable<double> portfolioValues) {
  final values = portfolioValues.toList(growable: false);
  if (values.length < 2 || values.any((value) => !_isFinite(value))) {
    return null;
  }

  var peakValue = values.first;
  var peakIndex = 0;
  var maxDrawdown = 0.0;
  var maxPeakValue = values.first;
  var troughValue = values.first;
  var troughIndex = 0;
  var maxPeakIndex = 0;

  for (var i = 1; i < values.length; i += 1) {
    final value = values[i];
    if (value > peakValue) {
      peakValue = value;
      peakIndex = i;
    }
    if (peakValue.abs() <= performanceCalculationTolerance) continue;

    final drawdown = value / peakValue - 1;
    if (drawdown < maxDrawdown) {
      maxDrawdown = drawdown;
      maxPeakValue = peakValue;
      maxPeakIndex = peakIndex;
      troughValue = value;
      troughIndex = i;
    }
  }

  return MaxDrawdownResult(
    maxDrawdown: maxDrawdown,
    peakValue: maxPeakValue,
    troughValue: troughValue,
    peakIndex: maxPeakIndex,
    troughIndex: troughIndex,
  );
}

class MaxDrawdownResult {
  const MaxDrawdownResult({
    required this.maxDrawdown,
    required this.peakValue,
    required this.troughValue,
    required this.peakIndex,
    required this.troughIndex,
  });

  final double maxDrawdown;
  final double peakValue;
  final double troughValue;
  final int peakIndex;
  final int troughIndex;
}

List<double>? _validatedReturns(Iterable<double> dailyReturns) {
  final returns = dailyReturns.toList(growable: false);
  if (returns.any((dailyReturn) => !_isFinite(dailyReturn))) return null;
  return returns;
}

bool _isFinite(double value) => value.isFinite;
