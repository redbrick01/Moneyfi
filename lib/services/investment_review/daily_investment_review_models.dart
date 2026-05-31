enum DailyInvestmentReviewStatus { inProgress, completed }

enum DailyInvestmentReviewMode { tradingDay, noTradeDay }

enum DailyInvestmentReviewPrincipleCheck {
  followedRules,
  brokeRules,
  notApplicable,
}

class DailyInvestmentReviewDraft {
  const DailyInvestmentReviewDraft({
    required this.reviewDate,
    required this.mode,
    required this.performanceNote,
    required this.tradeReviewNote,
    required this.selectedDecisionTags,
    required this.selectedNoTradeReasons,
    required this.selectedEmotions,
    required this.principleCheck,
    required this.riskNote,
    required this.insightGood,
    required this.insightWeak,
    required this.insightRepeatOrAvoid,
    required this.nextPlan,
  });

  factory DailyInvestmentReviewDraft.empty({
    required DateTime reviewDate,
    required DailyInvestmentReviewMode mode,
  }) {
    return DailyInvestmentReviewDraft(
      reviewDate: reviewDate,
      mode: mode,
      performanceNote: '',
      tradeReviewNote: '',
      selectedDecisionTags: const [],
      selectedNoTradeReasons: const [],
      selectedEmotions: const [],
      principleCheck: DailyInvestmentReviewPrincipleCheck.notApplicable,
      riskNote: '',
      insightGood: '',
      insightWeak: '',
      insightRepeatOrAvoid: '',
      nextPlan: '',
    );
  }

  final DateTime reviewDate;
  final DailyInvestmentReviewMode mode;
  final String performanceNote;
  final String tradeReviewNote;
  final List<String> selectedDecisionTags;
  final List<String> selectedNoTradeReasons;
  final List<String> selectedEmotions;
  final DailyInvestmentReviewPrincipleCheck principleCheck;
  final String riskNote;
  final String insightGood;
  final String insightWeak;
  final String insightRepeatOrAvoid;
  final String nextPlan;

  DailyInvestmentReviewDraft copyWith({
    DateTime? reviewDate,
    DailyInvestmentReviewMode? mode,
    String? performanceNote,
    String? tradeReviewNote,
    List<String>? selectedDecisionTags,
    List<String>? selectedNoTradeReasons,
    List<String>? selectedEmotions,
    DailyInvestmentReviewPrincipleCheck? principleCheck,
    String? riskNote,
    String? insightGood,
    String? insightWeak,
    String? insightRepeatOrAvoid,
    String? nextPlan,
  }) {
    return DailyInvestmentReviewDraft(
      reviewDate: reviewDate ?? this.reviewDate,
      mode: mode ?? this.mode,
      performanceNote: performanceNote ?? this.performanceNote,
      tradeReviewNote: tradeReviewNote ?? this.tradeReviewNote,
      selectedDecisionTags: selectedDecisionTags ?? this.selectedDecisionTags,
      selectedNoTradeReasons:
          selectedNoTradeReasons ?? this.selectedNoTradeReasons,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      principleCheck: principleCheck ?? this.principleCheck,
      riskNote: riskNote ?? this.riskNote,
      insightGood: insightGood ?? this.insightGood,
      insightWeak: insightWeak ?? this.insightWeak,
      insightRepeatOrAvoid: insightRepeatOrAvoid ?? this.insightRepeatOrAvoid,
      nextPlan: nextPlan ?? this.nextPlan,
    );
  }
}

class DailyInvestmentReviewEntry {
  const DailyInvestmentReviewEntry({
    required this.id,
    required this.reviewDate,
    required this.status,
    required this.mode,
    required this.performanceNote,
    required this.tradeReviewNote,
    required this.selectedDecisionTags,
    required this.selectedNoTradeReasons,
    required this.selectedEmotions,
    required this.principleCheck,
    required this.riskNote,
    required this.insightGood,
    required this.insightWeak,
    required this.insightRepeatOrAvoid,
    required this.nextPlan,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final int id;
  final DateTime reviewDate;
  final DailyInvestmentReviewStatus status;
  final DailyInvestmentReviewMode mode;
  final String performanceNote;
  final String tradeReviewNote;
  final List<String> selectedDecisionTags;
  final List<String> selectedNoTradeReasons;
  final List<String> selectedEmotions;
  final DailyInvestmentReviewPrincipleCheck principleCheck;
  final String riskNote;
  final String insightGood;
  final String insightWeak;
  final String insightRepeatOrAvoid;
  final String nextPlan;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
}
