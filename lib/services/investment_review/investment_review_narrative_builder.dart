import 'investment_review_models.dart';

abstract final class InvestmentReviewNarrativeBuilder {
  static InvestmentReviewNarrative build({
    required InvestmentReviewPeriodRange period,
    required List<InvestmentReviewMetric> metrics,
    required List<InvestmentReviewSignal> signals,
    required bool hasEnoughData,
  }) {
    if (!hasEnoughData) {
      return InvestmentReviewNarrative(
        headline: '${period.label} 회고를 만들 기록이 더 필요해요.',
        summary: '거래나 스냅샷 기록이 쌓이면 성과, 현금흐름, 판단 포인트를 함께 보여드릴게요.',
        nextActions: const ['거래와 스냅샷 기록을 먼저 쌓아보세요.'],
      );
    }

    final primarySignal = _primarySignal(signals);
    final primaryMetric = metrics.isEmpty ? null : metrics.first;
    final headline = primarySignal == null
        ? '${period.label} 회고에서 두드러진 변화는 아직 없어요.'
        : '${period.label}에는 ${primarySignal.title}이 가장 먼저 보여요.';

    final metricText = primaryMetric == null
        ? '대표 지표는 아직 계산되지 않았습니다.'
        : '${primaryMetric.label} ${primaryMetric.value}';
    final signalText = signals.isEmpty
        ? '추가 점검 신호는 없습니다.'
        : signals.map((signal) => signal.title).join(', ');

    return InvestmentReviewNarrative(
      headline: headline,
      summary: '$metricText 기준으로 확인했습니다. 주요 포인트는 $signalText입니다.',
      nextActions: _nextActions(signals),
    );
  }

  static InvestmentReviewSignal? _primarySignal(
    List<InvestmentReviewSignal> signals,
  ) {
    if (signals.isEmpty) return null;
    final positive = signals.where(
      (signal) => signal.severity == InvestmentReviewSignalSeverity.positive,
    );
    if (positive.isNotEmpty) return positive.first;
    return signals.first;
  }

  static List<String> _nextActions(List<InvestmentReviewSignal> signals) {
    final warning = signals.where(
      (signal) => signal.severity == InvestmentReviewSignalSeverity.warning,
    );
    if (warning.isNotEmpty) {
      return ['${warning.first.title} 항목을 확인해 보세요.'];
    }
    if (signals.isNotEmpty) {
      return ['${signals.first.title} 내용을 기준으로 다음 거래 전 한 번 더 점검해 보세요.'];
    }
    return const ['다음 거래 전 목표 비중과 현금흐름을 함께 확인해 보세요.'];
  }
}
