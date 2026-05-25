import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

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
    final leadingSlotWidth = context.spacing.xxxl;
    final badgeWidth = context.spacing.xl;
    final trailingMinWidth = context.spacing.xxxl + context.spacing.xxxl;

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
                width: leadingSlotWidth,
                child: Container(
                  width: badgeWidth,
                  height: 28,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.xs / 2,
                    vertical: context.spacing.xs - 2,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(context.radius.rPill),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.meta.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              SizedBox(width: context.spacing.sm),
              SizedBox(
                width: trailingMinWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: context.typography.cardTitle.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
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
