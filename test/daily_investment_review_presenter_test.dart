import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_presenter.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  InvestmentReviewReport report({
    InvestmentReviewPeriodType type = InvestmentReviewPeriodType.today,
    int buyCount = 0,
    int sellCount = 0,
  }) {
    final period = InvestmentReviewPeriodResolver.resolve(
      type,
      now: DateTime(2026, 6, 1, 12),
    );
    return InvestmentReviewReport(
      period: period,
      metrics: const [],
      signals: const [],
      narrative: const InvestmentReviewNarrative(
        headline: '오늘 회고 초안',
        summary: '자동 초안입니다.',
        nextActions: ['내일 조건을 정리하세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: buyCount + sellCount > 0,
      activity: InvestmentReviewActivitySummary(
        buyCount: buyCount,
        sellCount: sellCount,
      ),
      generatedAt: DateTime(2026, 6, 1, 12),
    );
  }

  test('uses draft status and no-trade mode without a saved row', () {
    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(),
      savedReview: null,
    );

    expect(state.status, DailyInvestmentReviewComposerStatus.draft);
    expect(state.mode, DailyInvestmentReviewMode.noTradeDay);
    expect(state.isCompleted, isFalse);
    expect(state.draft.reviewDate, DateTime(2026, 6, 1));
    expect(state.draft.mode, DailyInvestmentReviewMode.noTradeDay);
    expect(state.draft.tradeReviewNote, isEmpty);
  });

  test('uses trading mode when buy or sell activity exists', () {
    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(buyCount: 1),
      savedReview: null,
    );

    expect(state.mode, DailyInvestmentReviewMode.tradingDay);
  });

  test('preserves saved fields even when report mode changes', () {
    final saved = DailyInvestmentReviewEntry(
      id: 1,
      reviewDate: DateTime(2026, 6, 1),
      status: DailyInvestmentReviewStatus.inProgress,
      mode: DailyInvestmentReviewMode.noTradeDay,
      performanceNote: '기존 메모',
      tradeReviewNote: '관망 이유',
      selectedDecisionTags: const [],
      selectedNoTradeReasons: const ['기다림'],
      selectedEmotions: const ['차분함'],
      principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
      riskNote: '',
      insightGood: '',
      insightWeak: '',
      insightRepeatOrAvoid: '',
      nextPlan: '',
      createdAt: DateTime(2026, 6, 1, 10),
      updatedAt: DateTime(2026, 6, 1, 11),
    );

    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(sellCount: 1),
      savedReview: saved,
    );

    expect(state.status, DailyInvestmentReviewComposerStatus.inProgress);
    expect(state.mode, DailyInvestmentReviewMode.tradingDay);
    expect(state.draft.reviewDate, DateTime(2026, 6, 1));
    expect(state.draft.mode, DailyInvestmentReviewMode.tradingDay);
    expect(state.draft.performanceNote, '기존 메모');
    expect(state.draft.tradeReviewNote, '관망 이유');
    expect(state.draft.selectedNoTradeReasons, ['기다림']);
    expect(state.draft.selectedEmotions, ['차분함']);
    expect(
      state.draft.principleCheck,
      DailyInvestmentReviewPrincipleCheck.followedRules,
    );
  });

  test('maps completed saved review to completed composer state', () {
    final saved = DailyInvestmentReviewEntry(
      id: 1,
      reviewDate: DateTime(2026, 6, 1),
      status: DailyInvestmentReviewStatus.completed,
      mode: DailyInvestmentReviewMode.tradingDay,
      performanceNote: '완료 메모',
      tradeReviewNote: '',
      selectedDecisionTags: const ['계획 매매'],
      selectedNoTradeReasons: const [],
      selectedEmotions: const ['차분함'],
      principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
      riskNote: '',
      insightGood: '',
      insightWeak: '',
      insightRepeatOrAvoid: '',
      nextPlan: '',
      createdAt: DateTime(2026, 6, 1, 10),
      updatedAt: DateTime(2026, 6, 1, 11),
      completedAt: DateTime(2026, 6, 1, 12),
    );

    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(buyCount: 1),
      savedReview: saved,
    );

    expect(state.status, DailyInvestmentReviewComposerStatus.completed);
    expect(state.isCompleted, isTrue);
    expect(state.savedReview, same(saved));
    expect(state.draft.selectedDecisionTags, ['계획 매매']);
  });

  test('throws when building daily state from non-today report', () {
    expect(
      () => DailyInvestmentReviewPresenter.buildState(
        report: report(type: InvestmentReviewPeriodType.weekly),
        savedReview: null,
      ),
      throwsArgumentError,
    );
  });
}
