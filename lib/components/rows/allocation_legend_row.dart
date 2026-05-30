import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import '../../design_system/context_extensions.dart';
import '../chips/moneyfy_pill.dart';
import '../icons/app_icon.dart';

class AllocationLegendRow extends StatelessWidget {
  const AllocationLegendRow({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.ratioText,
    this.amountText,
    this.isSelected = false,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String ratioText;
  final String? amountText;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    final borderColor = isSelected
        ? context.colors.primary.withValues(alpha: 0.24)
        : colorScheme.outlineVariant.withValues(alpha: 0.20);
    return AnimatedContainer(
      duration: Duration(milliseconds: VisualSpec.chart.animFastMs),
      curve: VisualSpec.chart.animCurve,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(color: borderColor),
      ),
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
        child: Container(
          constraints: BoxConstraints(
            minHeight: VisualSpec.chart.legendRowHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: VisualSpec.chart.legendDot,
                height: VisualSpec.chart.legendDot,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    VisualSpec.chart.legendDotRadius,
                  ),
                ),
              ),
              SizedBox(width: VisualSpec.chart.legendGap),
              Container(
                width: context.spacing.lg,
                height: context.spacing.lg,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.surfaces.surfaceOverlay
                      : context.surfaces.surfaceRaised,
                  borderRadius: BorderRadius.circular(context.radius.rSm),
                ),
                child: AppIcon.raw(
                  icon,
                  size: context.spacing.sm + 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.meta.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (amountText != null)
                    Text(
                      amountText!,
                      style: context.typography.meta.copyWith(
                        fontWeight: AppFontWeights.semibold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (amountText != null) SizedBox(width: context.spacing.xs),
                  MoneyfyBadge(
                    label: ratioText,
                    size: MoneyfyPillSize.sm,
                    variant: MoneyfyPillVariant.outline,
                    backgroundColor: colorScheme.surface,
                    borderColor: colorScheme.outlineVariant,
                    textColor: colorScheme.onSurface,
                  ),
                ],
              ),
              if (isSelected) ...[
                SizedBox(width: context.spacing.xs),
                AppIcon(
                  AppIconName.checkCircle,
                  size: context.spacing.md,
                  color: context.colors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
