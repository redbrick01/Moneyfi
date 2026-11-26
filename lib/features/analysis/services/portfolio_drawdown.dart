import 'dart:math' as math;

import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/utils/risk_adjusted_performance_calculator.dart';

class PortfolioDrawdown {
  const PortfolioDrawdown({
    required this.percent,
    required this.amount,
    this.dates,
  });

  final double percent;
  final double amount;
  final ({String peak, String trough})? dates;
}

const _calendarDaysPerYear = 365;
const minimumVolatilityObservations = 20;
const minimumSharpeObservations = 60;

class PortfolioPerformanceMetrics {
  const PortfolioPerformanceMetrics._({
    required this.cagr,
    required this.annualizedVolatility,
    required this.drawdown,
    required List<double> dailyReturns,
  }) : _dailyReturns = dailyReturns;

  final double? cagr;
  final double? annualizedVolatility;
  final PortfolioDrawdown? drawdown;
  final List<double> _dailyReturns;

  int get dailyReturnCount => _dailyReturns.length;

  double? sharpeRatio(double annualRiskFreeRate) => calculateSharpeRatio(
    _dailyReturns,
    riskFreeRate: annualRiskFreeRate,
    periodsPerYear: _calendarDaysPerYear,
    minimumObservations: minimumSharpeObservations,
  );
}

Future<PortfolioPerformanceMetrics> loadPortfolioPerformanceMetrics(
  AppDatabase db,
  List<DailyPortfolioSnapshot> snapshots,
) async {
  final cashFlows = snapshots.length < 2
      ? const <String, double>{}
      : await db.fetchExternalCashFlowKrwByDate(
          from: snapshots.first.snapshotDate,
          to: snapshots.last.snapshotDate,
        );
  return calculatePortfolioPerformanceMetrics(snapshots, cashFlows);
}

PortfolioPerformanceMetrics calculatePortfolioPerformanceMetrics(
  List<DailyPortfolioSnapshot> snapshots,
  Map<String, double> externalCashFlowByDate,
) {
  final intervals = _adjustedIntervals(
    snapshots,
    externalCashFlowByDate,
  ).toList();
  final dailyReturns = [
    for (final interval in intervals)
      if (interval.days == 1 && interval.rate != null) interval.rate!,
  ];
  final elapsedDays = intervals.fold<int>(
    0,
    (sum, interval) => sum + interval.days,
  );
  double? cagr;
  if (elapsedDays >= _calendarDaysPerYear &&
      intervals.every(
        (interval) => interval.rate != null && interval.rate! >= -1,
      )) {
    // Each interval includes the cash flows between its two snapshots, even
    // when one or more daily snapshots are missing.
    final cumulative = calculateCumulativeReturn(
      intervals.map((interval) => interval.rate!),
    );
    if (cumulative != null && cumulative.isFinite) {
      cagr =
          math
              .pow(1 + cumulative, _calendarDaysPerYear / elapsedDays)
              .toDouble() -
          1;
    }
  }

  return PortfolioPerformanceMetrics._(
    cagr: cagr,
    annualizedVolatility: dailyReturns.length < minimumVolatilityObservations
        ? null
        : calculateAnnualizedVolatility(
            dailyReturns,
            periodsPerYear: _calendarDaysPerYear,
          ),
    drawdown: _calculateDrawdown(intervals),
    dailyReturns: dailyReturns,
  );
}

PortfolioDrawdown? calculatePortfolioDrawdown(
  List<DailyPortfolioSnapshot> snapshots,
  Map<String, double> externalCashFlowByDate,
) => _calculateDrawdown(_adjustedIntervals(snapshots, externalCashFlowByDate));

typedef _AdjustedInterval = ({
  DailyPortfolioSnapshot previous,
  DailyPortfolioSnapshot current,
  int days,
  double? rate,
});

Iterable<_AdjustedInterval> _adjustedIntervals(
  List<DailyPortfolioSnapshot> snapshots,
  Map<String, double> externalCashFlowByDate,
) sync* {
  final ordered = [...snapshots]
    ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
  final cashFlows = externalCashFlowByDate.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  var cashFlowIndex = 0;

  for (var index = 1; index < ordered.length; index++) {
    final previous = ordered[index - 1];
    final current = ordered[index];
    var cashFlow = 0.0;
    // Include flows on days with no snapshot, excluding the starting date.
    while (cashFlowIndex < cashFlows.length &&
        cashFlows[cashFlowIndex].key.compareTo(current.snapshotDate) <= 0) {
      final entry = cashFlows[cashFlowIndex++];
      if (entry.key.compareTo(previous.snapshotDate) > 0) {
        cashFlow += entry.value;
      }
    }

    final beginningValue = previous.totalValuationAmount;
    final rate = beginningValue <= 0
        ? null
        : calculateCashFlowAdjustedDailyReturn(
            beginningValue: beginningValue,
            endingValue: current.totalValuationAmount,
            externalCashFlow: cashFlow,
          );
    final start = DateTime.tryParse('${previous.snapshotDate}T00:00:00Z');
    final end = DateTime.tryParse('${current.snapshotDate}T00:00:00Z');
    final days = start == null || end == null
        ? 0
        : end.difference(start).inDays;
    yield (
      previous: previous,
      current: current,
      days: days,
      rate: days <= 0 || rate == null || !rate.isFinite ? null : rate,
    );
  }
}

PortfolioDrawdown? _calculateDrawdown(Iterable<_AdjustedInterval> intervals) {
  DailyPortfolioSnapshot? peak;
  var valueRelativeToPeak = 1.0;
  PortfolioDrawdown? worst;

  for (final interval in intervals) {
    final current = interval.current;
    final intervalReturn = interval.rate;
    peak ??= interval.previous;

    if (intervalReturn == null) {
      peak = current;
      valueRelativeToPeak = 1;
      continue;
    }

    worst ??= const PortfolioDrawdown(percent: 0, amount: 0);
    valueRelativeToPeak *= 1 + intervalReturn;
    if (valueRelativeToPeak >= 1 - performanceCalculationTolerance) {
      if (valueRelativeToPeak > 1 + performanceCalculationTolerance) {
        peak = current;
      }
      valueRelativeToPeak = 1;
      continue;
    }

    final loss = valueRelativeToPeak - 1;
    // Keep floating-point noise from moving a loss across a risk threshold.
    final percent = double.parse((loss * 100).toStringAsFixed(9));
    if (percent < worst.percent) {
      worst = PortfolioDrawdown(
        percent: percent,
        amount: loss * peak.totalValuationAmount,
        dates: (peak: peak.snapshotDate, trough: current.snapshotDate),
      );
    }
    if (valueRelativeToPeak <= 0) {
      peak = current;
      valueRelativeToPeak = 1;
    }
  }

  return worst;
}
