import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../formatters/number_format.dart';

enum DeltaChipMode { currency, percent, both }

class DeltaChip extends StatelessWidget {
  const DeltaChip({
    super.key,
    required this.value,
    this.percent,
    this.mode = DeltaChipMode.percent,
    this.showIcon = true,
    this.vivid = false,
    this.compact = false,
  });

  final num value;
  final num? percent;
  final DeltaChipMode mode;
  final bool showIcon;
  final bool vivid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isNegative = value < 0;
    final isNeutral = !isPositive && !isNegative;
    final colors = context.colors;
    final statusColor = isPositive
        ? colors.positiveOn
        : isNegative
        ? colors.negativeOn
        : colors.neutralTextMuted;
    final statusContainer = isPositive
        ? colors.positiveContainer
        : isNegative
        ? colors.negativeContainer
        : colors.neutralSurfaceBase;
    final backgroundColor = vivid && !isNeutral
        ? statusContainer
        : colors.neutralSurfaceBase;
    final borderColor = vivid && !isNeutral
        ? statusContainer
        : colors.neutralOutline.withValues(alpha: 0.72);

    final label = switch (mode) {
      DeltaChipMode.currency => formatSigned(value),
      DeltaChipMode.percent => formatSignedPercent(percent ?? value),
      DeltaChipMode.both =>
        '${formatSigned(value)} (${formatSignedPercent(percent ?? 0)})',
    };

    return Container(
      constraints: BoxConstraints(
        minHeight: compact
            ? context.spacing.sm + context.spacing.xs
            : context.spacing.lg,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? context.spacing.xs - 2 : context.spacing.xs,
        vertical: compact ? context.spacing.xs / 4 : context.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? context.typography.caption
                          : context.typography.meta)
                      .copyWith(
                        color: statusColor,
                        fontWeight: AppFontWeights.semibold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
