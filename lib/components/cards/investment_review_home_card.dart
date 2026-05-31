import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../services/investment_review/daily_investment_review_models.dart';
import '../../services/investment_review/investment_review_models.dart';
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
    final actions = report.narrative.nextActions.take(2).toList();
    final statusText = switch (reviewStatus) {
      DailyInvestmentReviewComposerStatus.draft => '오늘 회고 초안이 준비됐어요',
      DailyInvestmentReviewComposerStatus.inProgress => '작성 중인 회고가 있어요',
      DailyInvestmentReviewComposerStatus.completed => '오늘 회고 완료',
    };
    final ctaText = switch (reviewStatus) {
      DailyInvestmentReviewComposerStatus.draft => '작성하기',
      DailyInvestmentReviewComposerStatus.inProgress => '이어쓰기',
      DailyInvestmentReviewComposerStatus.completed => '보기',
    };

    return SectionCard(
      title: '오늘의 투자 회고',
      headerTrailing: TextButton(onPressed: onOpen, child: Text(ctaText)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText, style: context.typography.cardTitle),
          if (actions.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            for (var index = 0; index < actions.length; index++) ...[
              _InvestmentReviewAction(text: actions[index]),
              if (index != actions.length - 1)
                SizedBox(height: context.spacing.xs),
            ],
          ],
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        SizedBox(width: context.spacing.xs),
        Expanded(
          child: Text(
            text,
            style: context.typography.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
