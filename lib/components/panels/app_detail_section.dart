import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import '../section_card.dart';
import 'app_inner_panel.dart';

class AppDetailSection extends StatelessWidget {
  const AppDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.wrapBodyWithInnerPanel = true,
    this.showHeaderTrailingDivider = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool wrapBodyWithInnerPanel;
  final bool showHeaderTrailingDivider;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.7);

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
              if (trailing != null) ...[
                if (showHeaderTrailingDivider) ...[
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                  Container(width: 1, height: 24, color: dividerColor),
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                ],
                trailing!,
              ],
            ],
          ),
          SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
          if (wrapBodyWithInnerPanel)
            AppInnerPanel(
              padding: EdgeInsets.all(context.cardPadding()),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}
