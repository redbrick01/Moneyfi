import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../icons/app_icon.dart';
import '../buttons/app_buttons.dart';
import '../section_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.meta,
    this.iconBackgroundColor,
    this.iconColor,
  });

  final AppIconName icon;
  final String title;
  final String description;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? meta;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.spacing.xl + context.spacing.sm,
            height: context.spacing.xl + context.spacing.sm,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(context.radius.rMd),
            ),
            child: AppIcon(
              icon,
              color: iconColor ?? colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(title, style: context.typography.sectionTitle),
          SizedBox(height: context.spacing.xs),
          Text(description, style: context.typography.meta),
          if ((meta ?? '').trim().isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Text(meta!, style: context.typography.caption),
          ],
          if ((primaryLabel ?? '').trim().isNotEmpty ||
              (secondaryLabel ?? '').trim().isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            Row(
              children: [
                if ((primaryLabel ?? '').trim().isNotEmpty)
                  Expanded(
                    child: AppPrimaryButton(
                      label: primaryLabel!,
                      onPressed: onPrimary,
                    ),
                  ),
                if ((primaryLabel ?? '').trim().isNotEmpty &&
                    (secondaryLabel ?? '').trim().isNotEmpty)
                  SizedBox(width: context.spacing.sm),
                if ((secondaryLabel ?? '').trim().isNotEmpty)
                  Expanded(
                    child: AppGhostButton(
                      label: secondaryLabel!,
                      onPressed: onSecondary,
                      expand: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
