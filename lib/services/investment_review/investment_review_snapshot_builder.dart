import '../../db/app_database.dart';
import '../../utils/display_currency.dart';
import 'investment_review_models.dart';
import 'investment_review_narrative_builder.dart';
import 'investment_review_periods.dart';

class InvestmentReviewSnapshotBuilder {
  const InvestmentReviewSnapshotBuilder({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<InvestmentReviewReport> build(
    InvestmentReviewPeriodType type, {
    DateTime? now,
  }) async {
    final generatedAt = now ?? DateTime.now();
    final period = InvestmentReviewPeriodResolver.resolve(
      type,
      now: generatedAt,
    );
    final performance = await _database.fetchLedgerPortfolioPerformance(
      from: period.from,
      to: period.to,
    );
    final activity = _activityFrom(performance);
    final hasEnoughData =
        activity.totalCount > 0 || performance.pureRealizedPerformance != 0;
    final metrics = hasEnoughData
        ? _metricsFrom(performance, activity)
        : const <InvestmentReviewMetric>[];
    final signals = hasEnoughData
        ? _signalsFrom(performance, activity)
        : const <InvestmentReviewSignal>[];
    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: metrics,
      signals: signals,
      hasEnoughData: hasEnoughData,
    );

    return InvestmentReviewReport(
      period: period,
      activity: activity,
      metrics: metrics,
      signals: signals,
      narrative: narrative,
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: hasEnoughData,
      generatedAt: generatedAt,
    );
  }

  InvestmentReviewActivitySummary _activityFrom(
    LedgerPortfolioPerformanceRecord performance,
  ) {
    return InvestmentReviewActivitySummary(
      buyCount: performance.buyCount,
      sellCount: performance.sellCount,
      incomeCount: performance.incomeCount,
      cashFlowCount: performance.cashFlowCount,
    );
  }

  List<InvestmentReviewMetric> _metricsFrom(
    LedgerPortfolioPerformanceRecord performance,
    InvestmentReviewActivitySummary activity,
  ) {
    return [
      InvestmentReviewMetric(
        label: '순 투자성과',
        value: _formatSigned(performance.pureRealizedPerformance),
        isPositive: performance.pureRealizedPerformance >= 0,
      ),
      InvestmentReviewMetric(
        label: '실현손익',
        value: _formatSigned(performance.realizedPnl),
        isPositive: performance.realizedPnl >= 0,
      ),
      InvestmentReviewMetric(
        label: '배당/이자',
        value: _formatSigned(performance.incomeAmount),
        detail: '${activity.incomeCount}건',
        isPositive: performance.incomeAmount >= 0,
      ),
      InvestmentReviewMetric(
        label: '거래 활동',
        value: '${activity.tradeCount}건',
        detail: '매수 ${activity.buyCount}건 · 매도 ${activity.sellCount}건',
      ),
    ];
  }

  List<InvestmentReviewSignal> _signalsFrom(
    LedgerPortfolioPerformanceRecord performance,
    InvestmentReviewActivitySummary activity,
  ) {
    final signals = <InvestmentReviewSignal>[];

    if (performance.pureRealizedPerformance > 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '성과 개선',
          description:
              '순 투자성과가 ${_formatSigned(performance.pureRealizedPerformance)}입니다.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
      );
    } else if (performance.pureRealizedPerformance < 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '손실 점검',
          description:
              '순 투자성과가 ${_formatSigned(performance.pureRealizedPerformance)}입니다.',
          severity: InvestmentReviewSignalSeverity.warning,
        ),
      );
    }

    if (activity.tradeCount > 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '거래 판단 복기',
          description:
              '매수 ${activity.buyCount}건, 매도 ${activity.sellCount}건의 판단을 돌아볼 수 있어요.',
        ),
      );
    }

    if (activity.incomeCount > 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '현금흐름 확인',
          description:
              '배당/이자 ${activity.incomeCount}건으로 ${_formatSigned(performance.incomeAmount)}이 반영됐어요.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
      );
    }

    return signals;
  }

  String _formatSigned(double amount) {
    return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
  }
}
