import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../theme/moneyfy_theme.dart';
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
  });

  final num value;
  final num? percent;
  final DeltaChipMode mode;
  final bool showIcon;
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isNegative = value < 0;
    final isNeutral = !isPositive && !isNegative;

    final label = switch (mode) {
      DeltaChipMode.currency => formatSigned(value),
      DeltaChipMode.percent => formatSignedPercent(percent ?? value),
      DeltaChipMode.both =>
        '${formatSigned(value)} (${formatSignedPercent(percent ?? 0)})',
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surface,
        border: Border.all(color: MoneyfyPalette.border),
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
              style: context.typography.meta.copyWith(
                color: isPositive
                    ? MoneyfyPalette.positive
                    : isNegative
                    ? MoneyfyPalette.negative
                    : MoneyfyPalette.secondaryText,
                fontWeight: isNeutral ? FontWeight.w600 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
