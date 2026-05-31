enum InvestmentReviewPeriodType { today, weekly, monthly }

class InvestmentReviewPeriodRange {
  const InvestmentReviewPeriodRange({
    required this.type,
    required this.from,
    required this.to,
    required this.label,
  });

  final InvestmentReviewPeriodType type;
  final DateTime from;
  final DateTime to;
  final String label;
}

class InvestmentReviewMetric {
  const InvestmentReviewMetric({
    required this.label,
    required this.value,
    this.detail,
    this.isPositive,
  });

  final String label;
  final String value;
  final String? detail;
  final bool? isPositive;
}

class InvestmentReviewSignal {
  const InvestmentReviewSignal({
    required this.title,
    required this.description,
    this.severity = InvestmentReviewSignalSeverity.info,
  });

  final String title;
  final String description;
  final InvestmentReviewSignalSeverity severity;
}

enum InvestmentReviewSignalSeverity { info, warning, positive }

class InvestmentReviewNarrative {
  const InvestmentReviewNarrative({
    required this.headline,
    required this.summary,
    required this.nextActions,
  });

  final String headline;
  final String summary;
  final List<String> nextActions;
}

class InvestmentReviewAiState {
  const InvestmentReviewAiState.off()
    : enabled = false,
      commentary = null,
      errorMessage = null;

  const InvestmentReviewAiState.ready(this.commentary)
    : enabled = true,
      errorMessage = null;

  const InvestmentReviewAiState.failed(this.errorMessage)
    : enabled = true,
      commentary = null;

  final bool enabled;
  final String? commentary;
  final String? errorMessage;
}

class InvestmentReviewReport {
  const InvestmentReviewReport({
    required this.period,
    required this.metrics,
    required this.signals,
    required this.narrative,
    required this.aiState,
    required this.hasEnoughData,
    this.generatedAt,
  });

  final InvestmentReviewPeriodRange period;
  final List<InvestmentReviewMetric> metrics;
  final List<InvestmentReviewSignal> signals;
  final InvestmentReviewNarrative narrative;
  final InvestmentReviewAiState aiState;
  final bool hasEnoughData;
  final DateTime? generatedAt;
}

class InvestmentReviewAiPayload {
  const InvestmentReviewAiPayload({
    required this.periodLabel,
    required this.metrics,
    required this.signals,
    required this.nextActions,
  });

  final String periodLabel;
  final Map<String, String> metrics;
  final List<String> signals;
  final List<String> nextActions;

  Map<String, Object> toJson() {
    return {
      'periodLabel': periodLabel,
      'metrics': metrics,
      'signals': signals,
      'nextActions': nextActions,
    };
  }
}
