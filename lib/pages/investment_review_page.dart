import 'package:flutter/material.dart';

import '../components/section_card.dart';
import '../db/app_database.dart';
import '../design_system/context_extensions.dart';
import '../services/investment_review/investment_review_models.dart';
import '../services/investment_review/investment_review_snapshot_builder.dart';
import '../widgets/moneyfy_ui.dart';

typedef InvestmentReviewReportLoader =
    Future<InvestmentReviewReport> Function(InvestmentReviewPeriodType type);

class InvestmentReviewPage extends StatefulWidget {
  const InvestmentReviewPage({super.key, this.reportBuilderForTesting});

  final InvestmentReviewReportLoader? reportBuilderForTesting;

  @override
  State<InvestmentReviewPage> createState() => _InvestmentReviewPageState();
}

class _InvestmentReviewPageState extends State<InvestmentReviewPage> {
  var _selected = InvestmentReviewPeriodType.today;
  late Future<InvestmentReviewReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<InvestmentReviewReport> _loadReport() {
    final testingLoader = widget.reportBuilderForTesting;
    if (testingLoader != null) {
      return testingLoader(_selected);
    }
    return InvestmentReviewSnapshotBuilder(
      AppDatabase.instance,
    ).build(_selected);
  }

  void _selectPeriod(InvestmentReviewPeriodType type) {
    if (type == _selected) return;
    setState(() {
      _selected = type;
      _reportFuture = _loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MoneyfyPage(
      title: '투자 회고',
      children: [
        _PeriodSegments(selected: _selected, onSelected: _selectPeriod),
        SizedBox(height: context.spacing.sectionGap),
        FutureBuilder<InvestmentReviewReport>(
          future: _reportFuture,
          builder: (context, snapshot) {
            final report = snapshot.data;
            if (report != null) {
              return _InvestmentReviewReportView(report: report);
            }
            if (snapshot.hasError) {
              return _InvestmentReviewErrorCard(
                onRetry: () {
                  setState(() {
                    _reportFuture = _loadReport();
                  });
                },
              );
            }
            return const _InvestmentReviewLoadingCard();
          },
        ),
      ],
    );
  }
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
      true => Colors.green.shade700,
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
      InvestmentReviewSignalSeverity.positive => Colors.green.shade700,
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
          child: const CircularProgressIndicator(),
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
