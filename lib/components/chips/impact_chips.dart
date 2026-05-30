import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';
import '../icons/app_icon.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final background = item.emphasized
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainer;
    final foreground = item.emphasized
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      height: context.spacing.lg + context.spacing.xs / 2,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm - 2,
        vertical: context.spacing.xs - 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.radius.rPill),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.raw(
            item.icon,
            size: VisualSpec.icon.chipIcon,
            color: foreground,
          ),
          SizedBox(width: context.spacing.xs / 2),
          Text(
            item.label,
            style: context.typography.meta.copyWith(
              color: foreground,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ],
      ),
    );
  }
}
