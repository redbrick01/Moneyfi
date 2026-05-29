import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import 'icons/app_icon.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actions,
    this.useSectionTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool useSectionTitle;

  @override
  Widget build(BuildContext context) {
    final resolvedActions = actions ?? const <Widget>[];
    final overflowActions = resolvedActions.skip(2).toList();
    final overflowCallbacks = overflowActions
        .map((action) => action is IconButton ? action.onPressed : null)
        .toList();
    final overflowLabels = overflowActions.asMap().entries.map((entry) {
      final action = entry.value;
      if (action is IconButton && action.tooltip != null) {
        return action.tooltip!;
      }
      return '동작 ${entry.key + 1}';
    }).toList();

    return SizedBox(
      height: VisualSpec.icon.minTapTarget,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: useSectionTitle
                  ? context.typography.sectionTitle
                  : context.typography.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (resolvedActions.length <= 2) ...resolvedActions,
          if (resolvedActions.length > 2) ...[
            ...resolvedActions.take(2),
            PopupMenuButton<int>(
              tooltip: '더보기',
              icon: AppIcon(AppIconName.more),
              itemBuilder: (context) => [
                for (var i = 0; i < overflowLabels.length; i++)
                  PopupMenuItem<int>(value: i, child: Text(overflowLabels[i])),
              ],
              onSelected: (index) => overflowCallbacks[index]?.call(),
            ),
          ],
        ],
      ),
    );
  }
}
