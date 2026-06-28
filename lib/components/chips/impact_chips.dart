import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import '../icons/app_icon.dart';
import 'moneyfy_pill.dart';

class ImpactChipData {
  const ImpactChipData({
    required this.label,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final bool emphasized;
}

class ImpactChips extends StatelessWidget {
  const ImpactChips({super.key, required this.items, this.maxVisible = 3});

  final List<ImpactChipData> items;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = items.take(maxVisible).toList(growable: false);
    final hiddenCount = items.length - visible.length;

    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs,
      children: [
        for (final item in visible) _ImpactChip(item: item),
        if (hiddenCount > 0)
          _ImpactChip(
            item: ImpactChipData(
              label: '+$hiddenCount',
              icon: VisualSpec.icon.more,
            ),
          ),
      ],
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.item});

  final ImpactChipData item;

  @override
  Widget build(BuildContext context) {
    final style = MoneyfyPillStyle.resolve(
      context,
      size: MoneyfyPillSize.md,
      tone: item.emphasized ? MoneyfyPillTone.primary : MoneyfyPillTone.neutral,
      variant: item.emphasized
          ? MoneyfyPillVariant.tonal
          : MoneyfyPillVariant.outline,
    );

    return Container(
      constraints: BoxConstraints(minHeight: style.height),
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(color: style.border, width: style.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.raw(
            item.icon,
            size: VisualSpec.icon.chipIcon,
            color: style.foreground,
          ),
          SizedBox(width: context.spacing.xs / 2),
          Text(item.label, style: style.textStyle),
        ],
      ),
    );
  }
}
