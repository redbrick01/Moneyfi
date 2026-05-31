import 'investment_review_models.dart';

class InvestmentReviewAiCoach {
  const InvestmentReviewAiCoach({this.isEnabled = false});

  final bool isEnabled;

  static InvestmentReviewAiPayload buildPayload(InvestmentReviewReport report) {
    return InvestmentReviewAiPayload(
      periodLabel: report.period.label,
      metrics: {
        for (final metric in report.metrics) metric.label: metric.value,
      },
      signals: report.signals.map((signal) => signal.title).toList(),
      nextActions: List<String>.of(report.narrative.nextActions),
    );
  }

  Future<InvestmentReviewAiState> explain(InvestmentReviewReport report) async {
    if (!isEnabled) {
      return const InvestmentReviewAiState.off();
    }
    final payload = buildPayload(report);
    final metricCount = payload.metrics.length;
    return InvestmentReviewAiState.ready(
      'AI 코치가 켜져 있습니다. 현재는 ${report.period.label} 요약 지표 $metricCount개를 기준으로 보강할 준비가 되어 있어요.',
    );
  }
}
