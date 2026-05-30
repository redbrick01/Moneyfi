import 'package:flutter/material.dart';

import '../chips/delta_chip.dart';
import '../../design_system/context_extensions.dart';
import '../icons/app_icon.dart';

class SnapshotRow extends StatelessWidget {
  const SnapshotRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.amountText,
    required this.deltaText,
    this.deltaPercent,
    this.singleLineDelta = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String amountText;
  final String deltaText;
  final double? deltaPercent;
  final bool singleLineDelta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deltaColor = _moneyfyValueColor(
      context,
      deltaText,
      defaultColor: context.colors.neutralTextMuted,
    );
    final trailingMinWidth = singleLineDelta
        ? 192.0
        : context.spacing.xxxl +
              context.spacing.xxxl +
              (deltaPercent == null ? 0 : 28);

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
                    if ((subtitle ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: context.spacing.xs / 2),
                      Text(
                        subtitle!,
                        style: context.typography.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      style: context.typography.cardTitle.copyWith(
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs / 2),
                    if (singleLineDelta)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              deltaText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typography.meta.copyWith(
                                color: deltaColor,
                                fontWeight: AppFontWeights.semibold,
                              ),
                            ),
                          ),
                          if (deltaPercent != null) ...[
                            SizedBox(width: context.spacing.xs / 2),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.spacing.xs,
                                vertical: context.spacing.xs / 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.neutralSurfaceBase,
                                borderRadius: BorderRadius.circular(
                                  context.radius.rPill,
                                ),
                                border: Border.all(
                                  color: context.colors.neutralOutline,
                                ),
                              ),
                              child: Text(
                                _formatPercent(deltaPercent!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: _moneyfyValueColor(
                                        context,
                                        _formatPercent(deltaPercent!),
                                        defaultColor:
                                            context.colors.neutralTextMuted,
                                      ),
                                      fontWeight: AppFontWeights.semibold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        deltaText,
                        style: context.typography.meta.copyWith(
                          color: deltaColor,
                          fontWeight: AppFontWeights.semibold,
                        ),
                      ),
                    if (!singleLineDelta && deltaPercent != null) ...[
                      SizedBox(height: context.spacing.xs / 2),
                      DeltaChip(
                        value: deltaPercent!,
                        percent: deltaPercent,
                        mode: DeltaChipMode.percent,
                        vivid: true,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.spacing.xs),
              AppIcon(
                AppIconName.chevronRight,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _moneyfyValueColor(
    BuildContext context,
    String value, {
    Color? defaultColor,
  }) {
    final trimmed = value.trimLeft();
    if (trimmed.startsWith('+')) return context.colors.positiveOn;
    if (trimmed.startsWith('-')) return context.colors.negativeOn;
    return defaultColor ?? context.colors.neutralText;
  }

  String _formatPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}
