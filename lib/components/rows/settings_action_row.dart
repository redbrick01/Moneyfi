import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import '../icons/app_icon.dart';

class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;
    final iconColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
          constraints: BoxConstraints(minHeight: VisualSpec.icon.minTapTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.sm,
              vertical: context.spacing.sm + context.spacing.xs / 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: VisualSpec.icon.minTapTarget,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppIcon.raw(
                      icon,
                      size: VisualSpec.icon.sizeDefault,
                      color: iconColor,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.cardTitle.copyWith(
                          color: titleColor,
                        ),
                      ),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: context.spacing.xs / 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.meta,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                SizedBox(
                  width: VisualSpec.icon.minTapTarget,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child:
                        trailing ??
                        AppIcon(
                          AppIconName.chevronRight,
                          size: VisualSpec.icon.sizeDefault,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
