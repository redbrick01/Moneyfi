import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
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
    final leadingSlotWidth = context.spacing.xxxl + context.spacing.md;

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
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.sm,
              vertical: context.spacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: leadingSlotWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppIcon.raw(icon, size: 24, color: iconColor),
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: context.typography.cardTitle.copyWith(
                          color: titleColor,
                        ),
                      ),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: context.spacing.xs / 2),
                        Text(subtitle!, style: context.typography.meta),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                trailing ??
                    AppIcon(
                      AppIconName.chevronRight,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
