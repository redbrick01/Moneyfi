import 'package:flutter/material.dart';

import '../chips/moneyfy_pill.dart';
import 'package:moneyfy/design_system/context_extensions.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.amountText,
    this.showSubtitle = true,
    this.metaText,
    this.onTap,
    this.typeColor,
    this.amountColor,
  });

  final String typeLabel;
  final String title;
  final String subtitle;
  final String amountText;
  final bool showSubtitle;
  final String? metaText;
  final VoidCallback? onTap;
  final Color? typeColor;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = typeColor ?? colorScheme.surfaceContainerHighest;
    final badgeWidth = context.spacing.xxl;
    final trailingWidth = context.spacing.xxxl + context.spacing.xl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.rMd),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onSurface.withValues(alpha: 0.05);
        }
        return null;
      }),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: badgeWidth,
                child: MoneyfyBadge(
                  label: typeLabel,
                  size: MoneyfyPillSize.sm,
                  backgroundColor: badgeColor,
                  textColor: colorScheme.onSurfaceVariant,
                  borderColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.cardTitle,
                    ),
                    if (showSubtitle && subtitle.trim().isNotEmpty) ...[
                      SizedBox(height: context.spacing.xs / 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.meta,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.spacing.xs),
              SizedBox(
                width: trailingWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          amountText,
                          maxLines: 1,
                          softWrap: false,
                          style: context.typography.cardTitle.copyWith(
                            color: amountColor,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ),
                    ),
                    if ((metaText ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: context.spacing.xs / 2),
                      Text(metaText!, style: context.typography.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
