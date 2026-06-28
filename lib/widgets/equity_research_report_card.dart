import 'package:flutter/material.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/features/analysis/services/equity_research_service.dart';

class EquityResearchReportCard extends StatelessWidget {
  const EquityResearchReportCard({
    super.key,
    required this.reports,
    this.title = '최신 리서치',
    this.emptyMessage = '표시할 리서치 리포트가 없습니다.',
  });

  final List<EquityResearchReportSummary> reports;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: context.typography.sectionTitle),
              ),
              MoneyfyBadge(
                label: 'research',
                size: MoneyfyPillSize.sm,
                variant: MoneyfyPillVariant.outline,
                backgroundColor: context.colors.neutralSurfaceBase,
                textColor: context.colors.neutralTextMuted,
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          if (reports.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
            )
          else
            for (var index = 0; index < reports.length; index++) ...[
              _EquityResearchReportTile(report: reports[index]),
              if (index != reports.length - 1)
                SizedBox(height: context.spacing.sm),
            ],
        ],
      ),
    );
  }
}

class _EquityResearchReportTile extends StatelessWidget {
  const _EquityResearchReportTile({required this.report});

  final EquityResearchReportSummary report;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radius.rMd),
        onTap: () => context.openEquityResearch(ticker: report.ticker),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: context.spacing.xs,
                runSpacing: context.spacing.xs,
                children: [
                  if (report.ticker.isNotEmpty)
                    _Badge(report.ticker, tone: MoneyfyPillTone.primary),
                  if (report.reportDate != null)
                    _Badge(_formatDate(report.reportDate!)),
                  if (report.confidenceLevel.isNotEmpty)
                    _Badge('신뢰도 ${report.confidenceLevel}'),
                ],
              ),
              SizedBox(height: context.spacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.cardTitle,
                    ),
                  ),
                  SizedBox(width: context.spacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: VisualSpec.icon.sizeDefault,
                    color: context.colors.neutralTextMuted,
                  ),
                ],
              ),
              if (report.oneLineConclusion.isNotEmpty) ...[
                SizedBox(height: context.spacing.xs),
                Text(
                  report.oneLineConclusion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.body.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.tone = MoneyfyPillTone.neutral});

  final String label;
  final MoneyfyPillTone tone;

  @override
  Widget build(BuildContext context) {
    return MoneyfyBadge(
      label: label,
      size: MoneyfyPillSize.sm,
      tone: tone,
      variant: tone == MoneyfyPillTone.neutral
          ? MoneyfyPillVariant.outline
          : MoneyfyPillVariant.tonal,
      backgroundColor: tone == MoneyfyPillTone.neutral
          ? context.colors.neutralSurfaceBase
          : null,
      textColor: tone == MoneyfyPillTone.neutral
          ? context.colors.neutralTextMuted
          : null,
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
