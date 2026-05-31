import 'daily_investment_review_models.dart';
import 'investment_review_models.dart';

abstract final class DailyInvestmentReviewPresenter {
  static DailyInvestmentReviewComposerState buildState({
    required InvestmentReviewReport report,
    required DailyInvestmentReviewEntry? savedReview,
  }) {
    final mode = _modeFrom(report);
    if (savedReview == null) {
      return DailyInvestmentReviewComposerState(
        status: DailyInvestmentReviewComposerStatus.draft,
        mode: mode,
        draft: DailyInvestmentReviewDraft.empty(
          reviewDate: report.period.from,
          mode: mode,
        ),
      );
    }

    final status = switch (savedReview.status) {
      DailyInvestmentReviewStatus.inProgress =>
        DailyInvestmentReviewComposerStatus.inProgress,
      DailyInvestmentReviewStatus.completed =>
        DailyInvestmentReviewComposerStatus.completed,
    };

    return DailyInvestmentReviewComposerState(
      status: status,
      mode: mode,
      savedReview: savedReview,
      draft: DailyInvestmentReviewDraft(
        reviewDate: savedReview.reviewDate,
        mode: mode,
        performanceNote: savedReview.performanceNote,
        tradeReviewNote: savedReview.tradeReviewNote,
        selectedDecisionTags: savedReview.selectedDecisionTags,
        selectedNoTradeReasons: savedReview.selectedNoTradeReasons,
        selectedEmotions: savedReview.selectedEmotions,
        principleCheck: savedReview.principleCheck,
        riskNote: savedReview.riskNote,
        insightGood: savedReview.insightGood,
        insightWeak: savedReview.insightWeak,
        insightRepeatOrAvoid: savedReview.insightRepeatOrAvoid,
        nextPlan: savedReview.nextPlan,
      ),
    );
  }

  static DailyInvestmentReviewMode _modeFrom(InvestmentReviewReport report) {
    return report.activity.tradeCount > 0
        ? DailyInvestmentReviewMode.tradingDay
        : DailyInvestmentReviewMode.noTradeDay;
  }
}
