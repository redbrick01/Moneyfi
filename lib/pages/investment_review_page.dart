import 'package:flutter/material.dart';

import '../components/buttons/app_buttons.dart';
import '../components/chips/moneyfy_pill.dart';
import '../components/section_card.dart';
import '../db/app_database.dart';
import '../design_system/context_extensions.dart';
import '../services/investment_review/daily_investment_review_models.dart';
import '../services/investment_review/daily_investment_review_presenter.dart';
import '../services/investment_review/daily_investment_review_repository.dart';
import '../services/investment_review/investment_review_models.dart';
import '../services/investment_review/investment_review_snapshot_builder.dart';
import '../widgets/moneyfy_ui.dart';

typedef InvestmentReviewReportLoader =
    Future<InvestmentReviewReport> Function(InvestmentReviewPeriodType type);
typedef DailyInvestmentReviewLoader =
    Future<DailyInvestmentReviewEntry?> Function(DateTime date);
typedef DailyInvestmentReviewDraftSaver =
    Future<void> Function(DailyInvestmentReviewDraft draft);
typedef DailyInvestmentReviewCompleter = Future<void> Function(DateTime date);

class InvestmentReviewPage extends StatefulWidget {
  const InvestmentReviewPage({
    super.key,
    this.reportBuilderForTesting,
    this.dailyReviewLoaderForTesting,
    this.dailyReviewSaveForTesting,
    this.dailyReviewCompleteForTesting,
  });

  final InvestmentReviewReportLoader? reportBuilderForTesting;
  final DailyInvestmentReviewLoader? dailyReviewLoaderForTesting;
  final DailyInvestmentReviewDraftSaver? dailyReviewSaveForTesting;
  final DailyInvestmentReviewCompleter? dailyReviewCompleteForTesting;

  @override
  State<InvestmentReviewPage> createState() => _InvestmentReviewPageState();
}

class _InvestmentReviewPageState extends State<InvestmentReviewPage> {
  var _selected = InvestmentReviewPeriodType.today;
  late Future<_InvestmentReviewTabData> _tabFuture;
  final _todayComposerKey = GlobalKey<_DailyInvestmentReviewComposerState>();

  @override
  void initState() {
    super.initState();
    _tabFuture = _loadTabData(_selected);
  }

  Future<InvestmentReviewReport> _loadReport(InvestmentReviewPeriodType type) {
    final testingLoader = widget.reportBuilderForTesting;
    if (testingLoader != null) {
      return testingLoader(type);
    }
    return InvestmentReviewSnapshotBuilder(
      database: AppDatabase.instance,
    ).build(type);
  }

  Future<DailyInvestmentReviewEntry?> _loadDailyReview(DateTime date) {
    final testingLoader = widget.dailyReviewLoaderForTesting;
    if (testingLoader != null) {
      return testingLoader(date);
    }
    if (widget.reportBuilderForTesting != null) {
      return Future.value(null);
    }
    return DailyInvestmentReviewRepository(
      database: AppDatabase.instance,
    ).loadByDate(date);
  }

  Future<_InvestmentReviewTabData> _loadTabData(
    InvestmentReviewPeriodType type,
  ) async {
    final report = await _loadReport(type);
    if (type != InvestmentReviewPeriodType.today) {
      return _InvestmentReviewTabData(report: report);
    }

    return _InvestmentReviewTabData(
      report: report,
      dailyReview: await _loadDailyReview(report.period.from),
    );
  }

  Future<void> _selectPeriod(InvestmentReviewPeriodType type) async {
    if (type == _selected) return;
    if (_selected == InvestmentReviewPeriodType.today) {
      final canLeave =
          await _todayComposerKey.currentState?.confirmDiscardIfNeeded() ??
          true;
      if (!canLeave || !mounted) return;
    }
    setState(() {
      _selected = type;
      _tabFuture = _loadTabData(type);
    });
  }

  Future<void> _saveDailyReview(DailyInvestmentReviewDraft draft) async {
    final testingSaver = widget.dailyReviewSaveForTesting;
    if (testingSaver != null) {
      await testingSaver(draft);
    } else {
      await DailyInvestmentReviewRepository(
        database: AppDatabase.instance,
      ).saveDraft(draft);
    }
  }

  Future<void> _completeDailyReview(DateTime date) async {
    final testingCompleter = widget.dailyReviewCompleteForTesting;
    if (testingCompleter != null) {
      await testingCompleter(date);
    } else {
      await DailyInvestmentReviewRepository(
        database: AppDatabase.instance,
      ).markCompleted(date);
    }
  }

  void _reloadSelectedPeriod() {
    if (!mounted) return;
    setState(() {
      _tabFuture = _loadTabData(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MoneyfyPage(
        title: '투자 회고',
        children: [
          _PeriodSegments(
            selected: _selected,
            onSelected: (type) {
              _selectPeriod(type);
            },
          ),
          SizedBox(height: context.spacing.sectionGap),
          FutureBuilder<_InvestmentReviewTabData>(
            future: _tabFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _InvestmentReviewLoadingCard();
              }
              final tabData = snapshot.data;
              if (tabData != null) {
                final report = tabData.report;
                if (_selected == InvestmentReviewPeriodType.today) {
                  return _DailyInvestmentReviewComposer(
                    key: _todayComposerKey,
                    report: report,
                    composerState: DailyInvestmentReviewPresenter.buildState(
                      report: report,
                      savedReview: tabData.dailyReview,
                    ),
                    onSaveDraft: _saveDailyReview,
                    onComplete: _completeDailyReview,
                    onReload: _reloadSelectedPeriod,
                  );
                }
                return _InvestmentReviewReportView(report: report);
              }
              if (snapshot.hasError) {
                return _InvestmentReviewErrorCard(
                  onRetry: () {
                    setState(() {
                      _tabFuture = _loadTabData(_selected);
                    });
                  },
                );
              }
              return const _InvestmentReviewLoadingCard();
            },
          ),
        ],
      ),
    );
  }
}

class _InvestmentReviewTabData {
  const _InvestmentReviewTabData({required this.report, this.dailyReview});

  final InvestmentReviewReport report;
  final DailyInvestmentReviewEntry? dailyReview;
}

class _PeriodSegments extends StatelessWidget {
  const _PeriodSegments({required this.selected, required this.onSelected});

  final InvestmentReviewPeriodType selected;
  final ValueChanged<InvestmentReviewPeriodType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InvestmentReviewPeriodType>(
      segments: const [
        ButtonSegment(
          value: InvestmentReviewPeriodType.today,
          label: Text('오늘'),
        ),
        ButtonSegment(
          value: InvestmentReviewPeriodType.weekly,
          label: Text('주간'),
        ),
        ButtonSegment(
          value: InvestmentReviewPeriodType.monthly,
          label: Text('월간'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.single),
    );
  }
}

class _InvestmentReviewReportView extends StatelessWidget {
  const _InvestmentReviewReportView({required this.report});

  final InvestmentReviewReport report;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _NarrativeCard(report: report),
      if (report.metrics.isNotEmpty) ...[
        SizedBox(height: context.spacing.sectionGap),
        _MetricsCard(metrics: report.metrics),
      ],
      if (report.signals.isNotEmpty) ...[
        SizedBox(height: context.spacing.sectionGap),
        _SignalsCard(signals: report.signals),
      ],
      SizedBox(height: context.spacing.sectionGap),
      _NextActionsCard(actions: report.narrative.nextActions),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _DailyInvestmentReviewComposer extends StatefulWidget {
  const _DailyInvestmentReviewComposer({
    super.key,
    required this.report,
    required this.composerState,
    required this.onSaveDraft,
    required this.onComplete,
    required this.onReload,
  });

  final InvestmentReviewReport report;
  final DailyInvestmentReviewComposerState composerState;
  final DailyInvestmentReviewDraftSaver onSaveDraft;
  final DailyInvestmentReviewCompleter onComplete;
  final VoidCallback onReload;

  @override
  State<_DailyInvestmentReviewComposer> createState() =>
      _DailyInvestmentReviewComposerState();
}

class _DailyInvestmentReviewComposerState
    extends State<_DailyInvestmentReviewComposer> {
  late final TextEditingController _performanceController;
  late final TextEditingController _tradeReviewController;
  late final TextEditingController _riskController;
  late final TextEditingController _insightGoodController;
  late final TextEditingController _insightWeakController;
  late final TextEditingController _insightRepeatController;
  late final TextEditingController _nextPlanController;
  late Set<String> _selectedDecisionTags;
  late Set<String> _selectedNoTradeReasons;
  late Set<String> _selectedEmotions;
  late DailyInvestmentReviewPrincipleCheck _principleCheck;
  late DailyInvestmentReviewDraft _initialDraft;
  late bool _isEditing;
  var _isSubmitting = false;

  static const _decisionTags = [
    '계획 매매',
    '리밸런싱',
    '손절/익절 원칙',
    'FOMO',
    '소문/추천',
    '충동 매매',
  ];

  static const _noTradeReasons = [
    '원칙에 맞는 기회가 없었음',
    '목표 가격 대기',
    '현금 비중 유지',
    '추가 분석 필요',
    '변동성이 커서 관망',
    '충동 매매를 참음',
    '특별히 기록할 변화 없음',
  ];

  static const _emotionTags = ['차분함', '불안함', '조급함', '후회', '자신감'];

  @override
  void initState() {
    super.initState();
    final draft = widget.composerState.draft;
    _performanceController = TextEditingController(text: draft.performanceNote);
    _tradeReviewController = TextEditingController(text: draft.tradeReviewNote);
    _riskController = TextEditingController(text: draft.riskNote);
    _insightGoodController = TextEditingController(text: draft.insightGood);
    _insightWeakController = TextEditingController(text: draft.insightWeak);
    _insightRepeatController = TextEditingController(
      text: draft.insightRepeatOrAvoid,
    );
    _nextPlanController = TextEditingController(text: draft.nextPlan);
    _selectedDecisionTags = {...draft.selectedDecisionTags};
    _selectedNoTradeReasons = {...draft.selectedNoTradeReasons};
    _selectedEmotions = {...draft.selectedEmotions};
    _principleCheck = draft.principleCheck;
    _initialDraft = draft;
    _isEditing = !widget.composerState.isCompleted;
    for (final controller in _textControllers) {
      controller.addListener(_handleFormChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller.removeListener(_handleFormChanged);
    }
    _performanceController.dispose();
    _tradeReviewController.dispose();
    _riskController.dispose();
    _insightGoodController.dispose();
    _insightWeakController.dispose();
    _insightRepeatController.dispose();
    _nextPlanController.dispose();
    super.dispose();
  }

  bool get _canEdit => _isEditing && !_isSubmitting;

  bool get _hasUnsavedChanges =>
      _isEditing && !_draftEquals(_initialDraft, _draftFromForm());

  List<TextEditingController> get _textControllers => [
    _performanceController,
    _tradeReviewController,
    _riskController,
    _insightGoodController,
    _insightWeakController,
    _insightRepeatController,
    _nextPlanController,
  ];

  void _handleFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      final draft = _draftFromForm();
      await widget.onSaveDraft(draft);
      if (!mounted) return;
      _initialDraft = draft;
      _showSnackBar('오늘 회고를 저장했어요.');
      widget.onReload();
    } catch (_) {
      if (mounted) {
        _showSnackBar('회고를 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeReview() async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      final draft = _draftFromForm();
      await widget.onSaveDraft(draft);
      if (!mounted) return;
      _initialDraft = draft;
      await widget.onComplete(draft.reviewDate);
      if (!mounted) return;
      _showSnackBar('오늘 회고를 저장했어요.');
      widget.onReload();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('저장하지 않은 회고가 있어요'),
          content: const Text('저장하지 않고 나가면 작성 중인 내용이 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('계속 작성'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );

    return shouldLeave == true;
  }

  Future<void> _confirmDiscardAndPop(Object? result) async {
    final shouldLeave = await confirmDiscardIfNeeded();
    if (shouldLeave && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  bool _draftEquals(
    DailyInvestmentReviewDraft left,
    DailyInvestmentReviewDraft right,
  ) {
    return left.reviewDate == right.reviewDate &&
        left.mode == right.mode &&
        left.performanceNote == right.performanceNote &&
        left.tradeReviewNote == right.tradeReviewNote &&
        _sameStringSet(left.selectedDecisionTags, right.selectedDecisionTags) &&
        _sameStringSet(
          left.selectedNoTradeReasons,
          right.selectedNoTradeReasons,
        ) &&
        _sameStringSet(left.selectedEmotions, right.selectedEmotions) &&
        left.principleCheck == right.principleCheck &&
        left.riskNote == right.riskNote &&
        left.insightGood == right.insightGood &&
        left.insightWeak == right.insightWeak &&
        left.insightRepeatOrAvoid == right.insightRepeatOrAvoid &&
        left.nextPlan == right.nextPlan;
  }

  bool _sameStringSet(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    return left.toSet().containsAll(right);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop || !_hasUnsavedChanges) return;
    await _confirmDiscardAndPop(result);
  }

  Future<void> _handleCompleteFailure() async {
    if (mounted) {
      _showSnackBar('회고를 저장하지 못했어요. 다시 시도해 주세요.');
    }
  }

  DailyInvestmentReviewDraft _draftFromForm() {
    return DailyInvestmentReviewDraft(
      reviewDate: widget.composerState.draft.reviewDate,
      mode: widget.composerState.mode,
      performanceNote: _performanceController.text,
      tradeReviewNote: _tradeReviewController.text,
      selectedDecisionTags: _selectedDecisionTags.toList(growable: false),
      selectedNoTradeReasons: _selectedNoTradeReasons.toList(growable: false),
      selectedEmotions: _selectedEmotions.toList(growable: false),
      principleCheck: _principleCheck,
      riskNote: _riskController.text,
      insightGood: _insightGoodController.text,
      insightWeak: _insightWeakController.text,
      insightRepeatOrAvoid: _insightRepeatController.text,
      nextPlan: _nextPlanController.text,
    );
  }

  void _toggleString(Set<String> values, String value, bool selected) {
    setState(() {
      if (selected) {
        values.add(value);
      } else {
        values.remove(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTradingDay =
        widget.composerState.mode == DailyInvestmentReviewMode.tradingDay;
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ComposerHeader(
            state: widget.composerState,
            generatedAt: widget.report.generatedAt,
          ),
          SizedBox(height: context.spacing.sectionGap),
          _AutomaticDraftContext(report: widget.report),
          SizedBox(height: context.spacing.sectionGap),
          _ComposerTextSection(
            title: '성과 분석',
            controller: _performanceController,
            enabled: _canEdit,
            hintText: '오늘 성과를 만든 원인을 적어보세요.',
          ),
          SizedBox(height: context.spacing.sectionGap),
          _ComposerModeSection(
            title: isTradingDay ? '매매 복기' : '관망 회고',
            controller: _tradeReviewController,
            enabled: _canEdit,
            chips: isTradingDay ? _decisionTags : _noTradeReasons,
            selected: isTradingDay
                ? _selectedDecisionTags
                : _selectedNoTradeReasons,
            onSelected: (chip, selected) {
              if (isTradingDay) {
                _toggleString(_selectedDecisionTags, chip, selected);
              } else {
                _toggleString(_selectedNoTradeReasons, chip, selected);
              }
            },
            hintText: isTradingDay
                ? '오늘의 매수/매도 판단과 과정을 복기하세요.'
                : '거래하지 않은 이유와 관찰한 변화를 기록하세요.',
          ),
          SizedBox(height: context.spacing.sectionGap),
          _RiskMentalSection(
            enabled: _canEdit,
            selectedEmotions: _selectedEmotions,
            emotionTags: _emotionTags,
            principleCheck: _principleCheck,
            controller: _riskController,
            onEmotionSelected: (chip, selected) =>
                _toggleString(_selectedEmotions, chip, selected),
            onPrincipleSelected: (value) {
              setState(() {
                _principleCheck = value;
              });
            },
          ),
          SizedBox(height: context.spacing.sectionGap),
          _InsightSection(
            enabled: _canEdit,
            goodController: _insightGoodController,
            weakController: _insightWeakController,
            repeatController: _insightRepeatController,
          ),
          SizedBox(height: context.spacing.sectionGap),
          _ComposerTextSection(
            title: '다음 투자 계획',
            controller: _nextPlanController,
            enabled: _canEdit,
            hintText: '내일 확인할 조건과 행동 기준을 적어보세요.',
          ),
          SizedBox(height: context.spacing.sectionGap),
          _ComposerActions(
            canEdit: _canEdit,
            isSubmitting: _isSubmitting,
            onSave: _saveDraft,
            onComplete: () async {
              try {
                await _completeReview();
              } catch (_) {
                await _handleCompleteFailure();
              }
            },
            onEdit: widget.composerState.isCompleted
                ? () {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ComposerHeader extends StatelessWidget {
  const _ComposerHeader({required this.state, required this.generatedAt});

  final DailyInvestmentReviewComposerState state;
  final DateTime? generatedAt;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (state.status) {
      DailyInvestmentReviewComposerStatus.draft => '초안 생성됨',
      DailyInvestmentReviewComposerStatus.inProgress => '작성 중',
      DailyInvestmentReviewComposerStatus.completed => '완료',
    };
    return SectionCard(
      variant: SectionCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘의 투자 회고', style: context.typography.cardTitle),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _StatusBadge(
                label: '초안 생성됨',
                selected:
                    state.status == DailyInvestmentReviewComposerStatus.draft,
              ),
              _StatusBadge(
                label: '작성 중',
                selected:
                    state.status ==
                    DailyInvestmentReviewComposerStatus.inProgress,
              ),
              _StatusBadge(
                label: '완료',
                selected:
                    state.status ==
                    DailyInvestmentReviewComposerStatus.completed,
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            generatedAt == null
                ? '$statusText · 자동 초안을 바탕으로 회고를 작성하세요.'
                : '$statusText · 자동 초안 ${_timeLabel(generatedAt!)} 생성',
            style: context.typography.meta,
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return MoneyfyBadge(
      label: label,
      tone: selected ? MoneyfyPillTone.primary : MoneyfyPillTone.neutral,
      variant: selected ? MoneyfyPillVariant.selected : MoneyfyPillVariant.soft,
    );
  }
}

class _AutomaticDraftContext extends StatelessWidget {
  const _AutomaticDraftContext({required this.report});

  final InvestmentReviewReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      title: '자동 초안',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.narrative.headline, style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          Text(
            report.narrative.summary,
            style: context.typography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _InfoPill(label: report.period.label),
              _InfoPill(label: '매수 ${report.activity.buyCount}건'),
              _InfoPill(label: '매도 ${report.activity.sellCount}건'),
              if (!report.hasEnoughData) const _InfoPill(label: '데이터 부족'),
            ],
          ),
          if (report.metrics.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _DraftMetricLines(metrics: report.metrics),
          ],
          if (report.signals.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            for (var index = 0; index < report.signals.length; index++)
              _DraftSignalLine(
                signal: report.signals[index],
                showDivider: index != report.signals.length - 1,
              ),
          ],
          SizedBox(height: context.spacing.md),
          for (final action in report.narrative.nextActions)
            _ActionRow(text: action),
        ],
      ),
    );
  }
}

class _DraftMetricLines extends StatelessWidget {
  const _DraftMetricLines({required this.metrics});

  final List<InvestmentReviewMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.58);

    return Column(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    metrics[index].label,
                    style: context.typography.meta,
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Flexible(
                  child: Text(
                    metrics[index].value,
                    textAlign: TextAlign.end,
                    style: context.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index != metrics.length - 1)
            Divider(height: 1, thickness: 1, color: dividerColor),
        ],
      ],
    );
  }
}

class _DraftSignalLine extends StatelessWidget {
  const _DraftSignalLine({required this.signal, required this.showDivider});

  final InvestmentReviewSignal signal;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.58);

    return Padding(
      padding: EdgeInsets.only(bottom: showDivider ? context.spacing.sm : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(signal.title, style: context.typography.meta),
          SizedBox(height: context.spacing.xs / 2),
          Text(signal.description, style: context.typography.body),
          if (showDivider) ...[
            SizedBox(height: context.spacing.sm),
            Divider(height: 1, thickness: 1, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

class _ComposerTextSection extends StatelessWidget {
  const _ComposerTextSection({
    required this.title,
    required this.controller,
    required this.enabled,
    required this.hintText,
  });

  final String title;
  final TextEditingController controller;
  final bool enabled;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ComposerModeSection extends StatelessWidget {
  const _ComposerModeSection({
    required this.title,
    required this.controller,
    required this.enabled,
    required this.chips,
    required this.selected,
    required this.onSelected,
    required this.hintText,
  });

  final String title;
  final TextEditingController controller;
  final bool enabled;
  final List<String> chips;
  final Set<String> selected;
  final void Function(String chip, bool selected) onSelected;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipWrap(
            chips: chips,
            selected: selected,
            enabled: enabled,
            onSelected: onSelected,
          ),
          SizedBox(height: context.spacing.md),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskMentalSection extends StatelessWidget {
  const _RiskMentalSection({
    required this.enabled,
    required this.selectedEmotions,
    required this.emotionTags,
    required this.principleCheck,
    required this.controller,
    required this.onEmotionSelected,
    required this.onPrincipleSelected,
  });

  final bool enabled;
  final Set<String> selectedEmotions;
  final List<String> emotionTags;
  final DailyInvestmentReviewPrincipleCheck principleCheck;
  final TextEditingController controller;
  final void Function(String chip, bool selected) onEmotionSelected;
  final ValueChanged<DailyInvestmentReviewPrincipleCheck> onPrincipleSelected;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '리스크/멘탈 점검',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipWrap(
            chips: emotionTags,
            selected: selectedEmotions,
            enabled: enabled,
            onSelected: onEmotionSelected,
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _PrincipleChip(
                label: '원칙 준수',
                value: DailyInvestmentReviewPrincipleCheck.followedRules,
                groupValue: principleCheck,
                enabled: enabled,
                onSelected: onPrincipleSelected,
              ),
              _PrincipleChip(
                label: '원칙 이탈',
                value: DailyInvestmentReviewPrincipleCheck.brokeRules,
                groupValue: principleCheck,
                enabled: enabled,
                onSelected: onPrincipleSelected,
              ),
              _PrincipleChip(
                label: '해당 없음',
                value: DailyInvestmentReviewPrincipleCheck.notApplicable,
                groupValue: principleCheck,
                enabled: enabled,
                onSelected: onPrincipleSelected,
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '리스크, 감정, 원칙 준수 여부를 적어보세요.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.enabled,
    required this.goodController,
    required this.weakController,
    required this.repeatController,
  });

  final bool enabled;
  final TextEditingController goodController;
  final TextEditingController weakController;
  final TextEditingController repeatController;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '핵심 인사이트',
      child: Column(
        children: [
          _SingleLineComposerField(
            controller: goodController,
            enabled: enabled,
            label: '잘한 점',
          ),
          SizedBox(height: context.spacing.sm),
          _SingleLineComposerField(
            controller: weakController,
            enabled: enabled,
            label: '아쉬운 점',
          ),
          SizedBox(height: context.spacing.sm),
          _SingleLineComposerField(
            controller: repeatController,
            enabled: enabled,
            label: '반복/피할 점',
          ),
        ],
      ),
    );
  }
}

class _SingleLineComposerField extends StatelessWidget {
  const _SingleLineComposerField({
    required this.controller,
    required this.enabled,
    required this.label,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ComposerActions extends StatelessWidget {
  const _ComposerActions({
    required this.canEdit,
    required this.isSubmitting,
    required this.onSave,
    required this.onComplete,
    required this.onEdit,
  });

  final bool canEdit;
  final bool isSubmitting;
  final VoidCallback onSave;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: context.spacing.sm,
        runSpacing: context.spacing.sm,
        children: [
          AppSecondaryButton(
            label: '임시 저장',
            icon: Icons.save_outlined,
            expand: false,
            onPressed: canEdit ? onSave : null,
          ),
          AppPrimaryButton(
            label: '회고 완료',
            icon: Icons.check_circle_outline_rounded,
            expand: false,
            isLoading: isSubmitting,
            onPressed: canEdit ? onComplete : null,
          ),
          AppGhostButton(
            label: '수정하기',
            icon: Icons.edit_outlined,
            expand: false,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.chips,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> chips;
  final Set<String> selected;
  final bool enabled;
  final void Function(String chip, bool selected) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs,
      children: [
        for (final chip in chips)
          FilterChip(
            label: Text(chip),
            selected: selected.contains(chip),
            onSelected: enabled ? (value) => onSelected(chip, value) : null,
          ),
      ],
    );
  }
}

class _PrincipleChip extends StatelessWidget {
  const _PrincipleChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final DailyInvestmentReviewPrincipleCheck value;
  final DailyInvestmentReviewPrincipleCheck groupValue;
  final bool enabled;
  final ValueChanged<DailyInvestmentReviewPrincipleCheck> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: value == groupValue,
      onSelected: enabled ? (_) => onSelected(value) : null,
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({required this.report});

  final InvestmentReviewReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      variant: SectionCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.narrative.headline, style: context.typography.cardTitle),
          SizedBox(height: context.spacing.sm),
          Text(
            report.narrative.summary,
            style: context.typography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _InfoPill(label: report.period.label),
              _InfoPill(label: _activityLabel(report.activity)),
              if (!report.hasEnoughData) const _InfoPill(label: '데이터 부족'),
            ],
          ),
        ],
      ),
    );
  }

  String _activityLabel(InvestmentReviewActivitySummary activity) {
    if (activity.totalCount == 0) {
      return '활동 0건';
    }
    return '활동 ${activity.totalCount}건';
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final List<InvestmentReviewMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '주요 지표',
      child: Column(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            _MetricRow(metric: metrics[index]),
            if (index != metrics.length - 1)
              SizedBox(height: context.spacing.md),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final InvestmentReviewMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = switch (metric.isPositive) {
      true => context.colors.positiveOn,
      false => Theme.of(context).colorScheme.error,
      null => Theme.of(context).colorScheme.onSurface,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label, style: context.typography.cardTitle),
              if (metric.detail != null) ...[
                SizedBox(height: context.spacing.xs / 2),
                Text(metric.detail!, style: context.typography.meta),
              ],
            ],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Text(
          metric.value,
          textAlign: TextAlign.end,
          style: context.typography.cardTitle.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SignalsCard extends StatelessWidget {
  const _SignalsCard({required this.signals});

  final List<InvestmentReviewSignal> signals;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '리뷰 신호',
      child: Column(
        children: [
          for (var index = 0; index < signals.length; index++) ...[
            _SignalTile(signal: signals[index]),
            if (index != signals.length - 1)
              SizedBox(height: context.spacing.md),
          ],
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final InvestmentReviewSignal signal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = switch (signal.severity) {
      InvestmentReviewSignalSeverity.positive => context.colors.positiveOn,
      InvestmentReviewSignalSeverity.warning => colorScheme.error,
      InvestmentReviewSignalSeverity.info => colorScheme.primary,
    };
    final icon = switch (signal.severity) {
      InvestmentReviewSignalSeverity.positive => Icons.trending_up_rounded,
      InvestmentReviewSignalSeverity.warning => Icons.warning_rounded,
      InvestmentReviewSignalSeverity.info => Icons.info_rounded,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(signal.title, style: context.typography.cardTitle),
              SizedBox(height: context.spacing.xs / 2),
              Text(signal.description, style: context.typography.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextActionsCard extends StatelessWidget {
  const _NextActionsCard({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final items = actions.isEmpty ? const ['다음 회고를 위한 기록을 이어가세요.'] : actions;
    return SectionCard(
      title: '다음 액션',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ActionRow(text: items[index]),
            if (index != items.length - 1) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(child: Text(text, style: context.typography.body)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.xs / 2,
        ),
        child: Text(label, style: context.typography.meta),
      ),
    );
  }
}

class _InvestmentReviewLoadingCard extends StatelessWidget {
  const _InvestmentReviewLoadingCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: context.spacing.sm),
              Text('투자 회고를 불러오는 중이에요.', style: context.typography.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestmentReviewErrorCard extends StatelessWidget {
  const _InvestmentReviewErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('회고를 불러오지 못했어요.', style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          Text(
            '잠시 후 다시 시도해 주세요.',
            style: context.typography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.md),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
