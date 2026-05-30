import 'package:flutter/material.dart';

import 'moneyfy_pill.dart';
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
    final tone = isPositive
        ? MoneyfyPillTone.success
        : isNegative
        ? MoneyfyPillTone.danger
        : MoneyfyPillTone.neutral;
    final style = MoneyfyPillStyle.resolve(
      context,
      size: compact ? MoneyfyPillSize.sm : MoneyfyPillSize.md,
      tone: tone,
      variant: vivid && !isNeutral
          ? MoneyfyPillVariant.tonal
          : MoneyfyPillVariant.outline,
    );

    final label = switch (mode) {
      DeltaChipMode.currency => formatSigned(value),
      DeltaChipMode.percent => formatSignedPercent(percent ?? value),
      DeltaChipMode.both =>
        '${formatSigned(value)} (${formatSignedPercent(percent ?? 0)})',
    };

    return Container(
      constraints: BoxConstraints(minHeight: style.height),
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border, width: style.borderWidth),
        borderRadius: BorderRadius.circular(style.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.textStyle.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
