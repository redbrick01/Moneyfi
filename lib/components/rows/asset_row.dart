import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import '../icons/app_icon.dart';

class AssetRow extends StatelessWidget {
  const AssetRow({
    super.key,
    required this.leading,
    required this.title,
    required this.amountText,
    this.subtitle,
    this.deltaChip,
    this.isHidden = false,
    this.onTap,
    this.showChevron = true,
    this.showLeading = true,
    this.trailingAccessory,
    this.minHeight = 76,
    this.leadingSlotWidth,
    this.titleMinWidthFraction,
  });

  final Widget leading;
  final String title;
  final String amountText;
  final String? subtitle;
  final Widget? deltaChip;
  final bool isHidden;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showLeading;
  final Widget? trailingAccessory;
  final double minHeight;
  final double? leadingSlotWidth;
  final double? titleMinWidthFraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = context.spacing.md * 2;
        final resolvedLeadingSlotWidth = showLeading
            ? leadingSlotWidth ?? context.spacing.xxxl + context.spacing.md
            : 0.0;
        final gapLeadingToTitle = showLeading ? context.spacing.sm : 0.0;
        final gapTitleToTrailing = context.spacing.sm;
        final chevronReserve = showChevron ? 24.0 + context.spacing.xs : 0.0;
        final accessoryReserve = trailingAccessory == null
            ? 0.0
            : (72.0 + context.spacing.xs);
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth -
              horizontalPadding -
              resolvedLeadingSlotWidth -
              gapLeadingToTitle -
              gapTitleToTrailing -
              chevronReserve -
              accessoryReserve,
        );
        final hasDeltaLine = deltaChip != null;
        final titleWidthFloor = titleMinWidthFraction == null
            ? 0.0
            : availableWidth * titleMinWidthFraction!.clamp(0.0, 1.0);
        final minTitleWidth = math.max(
          hasDeltaLine ? 40.0 : 48.0,
          titleWidthFloor,
        );
        final trailingWidthTarget =
            (availableWidth * (hasDeltaLine ? 0.72 : 0.42)).clamp(
              hasDeltaLine ? 148.0 : 80.0,
              hasDeltaLine ? 240.0 : 152.0,
            );
        final trailingWidthCap = math.max(72.0, availableWidth - minTitleWidth);
        final trailingWidth = math.min(trailingWidthTarget, trailingWidthCap);
        final titleWidth = math.max(0.0, availableWidth - trailingWidth);

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.sm,
            ),
            child: Row(
              children: [
                if (showLeading) ...[
                  SizedBox(
                    width: resolvedLeadingSlotWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: leading,
                    ),
                  ),
                  SizedBox(width: gapLeadingToTitle),
                ],
                SizedBox(
                  width: titleWidth > 0 ? titleWidth : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typography.cardTitle,
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: context.spacing.xs / 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.meta,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: gapTitleToTrailing),
                SizedBox(
                  width: trailingWidth,
                  child: deltaChip == null
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: _AssetAmountText(text: amountText),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _AssetAmountText(text: amountText),
                            SizedBox(height: context.spacing.xs / 2),
                            SizedBox(
                              height: 28,
                              width: trailingWidth,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ClipRect(child: deltaChip!),
                              ),
                            ),
                          ],
                        ),
                ),
                if (showChevron) ...[
                  SizedBox(width: context.spacing.xs),
                  AppIcon(
                    AppIconName.chevronRight,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
                if (trailingAccessory != null) ...[
                  SizedBox(width: context.spacing.xs),
                  SizedBox(
                    width: 72,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailingAccessory!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    return Material(
      color: VisualSpec.surface.transparent,
      child: InkWell(
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
        child: Opacity(opacity: isHidden ? 0.6 : 1, child: content),
      ),
    );
  }
}

class _AssetAmountText extends StatelessWidget {
  const _AssetAmountText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: context.typography.cardTitle.copyWith(
          fontWeight: AppFontWeights.semibold,
        ),
      ),
    );
  }
}

/// Keep this widget "pure row UI" only.
/// Dismissible/Reorderable/Slidable wrappers should remain at page level.
