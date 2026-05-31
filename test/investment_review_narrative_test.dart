import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_narrative_builder.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  test('builds low-data copy without forcing interpretation', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.weekly,
      now: DateTime(2026, 5, 31),
    );

    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: const [],
      signals: const [],
      hasEnoughData: false,
    );

    expect(narrative.headline, '이번 주 회고를 만들 기록이 더 필요해요.');
    expect(narrative.summary, contains('거래나 스냅샷 기록'));
    expect(narrative.nextActions, contains('거래와 스냅샷 기록을 먼저 쌓아보세요.'));
  });

  test('builds factual copy from positive and warning signals', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.monthly,
      now: DateTime(2026, 5, 31),
    );

    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: const [
        InvestmentReviewMetric(
          label: '순 투자성과',
          value: '+120,000원',
          isPositive: true,
        ),
      ],
      signals: const [
        InvestmentReviewSignal(
          title: '성과 개선',
          description: '순 투자성과가 플러스입니다.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
        InvestmentReviewSignal(
          title: '비중 점검',
          description: '한 자산군 비중이 목표보다 높습니다.',
          severity: InvestmentReviewSignalSeverity.warning,
        ),
      ],
      hasEnoughData: true,
    );

    expect(narrative.headline, '이번 달에는 성과 개선이 가장 먼저 보여요.');
    expect(narrative.summary, contains('순 투자성과 +120,000원'));
    expect(narrative.summary, contains('비중 점검'));
    expect(narrative.nextActions.first, '비중 점검 항목을 확인해 보세요.');
  });
}
