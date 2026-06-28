import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/analysis/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_models.dart';
import '../chips/moneyfy_pill.dart';
import '../panels/app_inner_panel.dart';
import '../section_card.dart';

class InvestmentReviewHomeCard extends StatelessWidget {
  const InvestmentReviewHomeCard({
    super.key,
    required this.report,
    required this.reviewStatus,
    required this.onOpen,
  });

  final InvestmentReviewReport report;
  final DailyInvestmentReviewComposerStatus reviewStatus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final actions = report.narrative.nextActions.take(1).toList();
    final statusText = switch (reviewStatus) {
      DailyInvestmentReviewComposerStatus.draft => '오늘 회고 초안이 준비됐어요',
      DailyInvestmentReviewComposerStatus.inProgress => '작성 중인 회고가 있어요',
      DailyInvestmentReviewComposerStatus.completed => '오늘 회고 완료',
    };
    final statusLabel = switch (reviewStatus) {
      DailyInvestmentReviewComposerStatus.draft => '초안',
      DailyInvestmentReviewComposerStatus.inProgress => '작성 중',
      DailyInvestmentReviewComposerStatus.completed => '완료',
    };
    final statusTone = switch (reviewStatus) {
      DailyInvestmentReviewComposerStatus.draft => MoneyfyPillTone.primary,
      DailyInvestmentReviewComposerStatus.inProgress => MoneyfyPillTone.warning,
      DailyInvestmentReviewComposerStatus.completed => MoneyfyPillTone.success,
    };
    return SectionCard(
      title: '오늘의 투자 회고',
      child: AppInnerPanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radius.rMd),
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(
              context.spacing.sm + context.spacing.xs / 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MoneyfyBadge(
                            label: statusLabel,
                            tone: statusTone,
                            variant: MoneyfyPillVariant.outline,
                          ),
                          SizedBox(width: context.spacing.sm),
                          Expanded(
                            child: Text(
                              statusText,
                              style: context.typography.meta.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (actions.isNotEmpty) ...[
                        SizedBox(height: context.spacing.md),
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...[
                          _InvestmentReviewAction(text: actions[index]),
                          if (index != actions.length - 1)
                            SizedBox(height: context.spacing.xs),
                        ],
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvestmentReviewAction extends StatelessWidget {
  const _InvestmentReviewAction({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.typography.body.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
