import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_ai_coach.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_periods.dart';

void main() {
  test('AI coach is disabled by default', () {
    const coach = InvestmentReviewAiCoach();

    expect(coach.isEnabled, isFalse);
  });

  test('builds compact payload without raw ledger or account identifiers', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.monthly,
      now: DateTime(2026, 5, 31),
    );
    final report = InvestmentReviewReport(
      period: period,
      metrics: const [
        InvestmentReviewMetric(label: '순 투자성과', value: '+120,000원'),
      ],
      signals: const [
        InvestmentReviewSignal(
          title: '거래 판단 복기',
          description: '매수 1건, 매도 1건이 반영됐습니다.',
        ),
      ],
      narrative: const InvestmentReviewNarrative(
        headline: '이번 달에는 성과 개선이 보입니다.',
        summary: '순 투자성과 +120,000원 기준으로 확인했습니다.',
        nextActions: ['비중 점검 항목을 확인해 보세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: const InvestmentReviewActivitySummary(
        buyCount: 1,
        sellCount: 1,
        incomeCount: 0,
        cashFlowCount: 0,
      ),
    );

    final payload = InvestmentReviewAiCoach.buildPayload(report);
    final json = payload.toJson();

    expect(
      json.keys.toSet(),
      {'periodLabel', 'metrics', 'signals', 'nextActions'},
    );
    expect(json.keys, isNot(contains('transactions')));
    expect(json.keys, isNot(contains('userId')));
    expect(json.keys, isNot(contains('email')));
    expect(json.keys, isNot(contains('accountId')));
    expect(json['periodLabel'], '이번 달');
    expect((json['metrics'] as Map<String, String>)['순 투자성과'], '+120,000원');
  });

  test('copies next actions when building payload', () {
    final nextActions = ['비중 점검 항목을 확인해 보세요.'];
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.monthly,
      now: DateTime(2026, 5, 31),
    );
    final report = InvestmentReviewReport(
      period: period,
      metrics: const [],
      signals: const [],
      narrative: InvestmentReviewNarrative(
        headline: '이번 달에는 성과 개선이 보입니다.',
        summary: '순 투자성과 기준으로 확인했습니다.',
        nextActions: nextActions,
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: const InvestmentReviewActivitySummary(
        buyCount: 1,
        sellCount: 1,
        incomeCount: 0,
        cashFlowCount: 0,
      ),
    );

    final payload = InvestmentReviewAiCoach.buildPayload(report);
    nextActions.add('외부 변경');

    expect(payload.nextActions, ['비중 점검 항목을 확인해 보세요.']);
  });
}
