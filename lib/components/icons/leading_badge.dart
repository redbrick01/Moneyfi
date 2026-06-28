import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'app_icon.dart';

class LeadingBadge extends StatelessWidget {
  const LeadingBadge({super.key, required this.icon, this.iconColor})
    : rawIcon = null;

  const LeadingBadge.raw({super.key, required this.rawIcon, this.iconColor})
    : icon = null;

  final AppIconName? icon;
  final IconData? rawIcon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: VisualSpec.icon.badgeBox,
      height: VisualSpec.icon.badgeBox,
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.icon.badgeRadius),
      ),
      child: Center(
        child: icon != null
            ? AppIcon(
                icon!,
                size: VisualSpec.icon.iconSizeBadge,
                color: iconColor ?? colorScheme.onSurfaceVariant,
              )
            : AppIcon.raw(
                rawIcon ?? VisualSpec.icon.circle,
                size: VisualSpec.icon.iconSizeBadge,
                color: iconColor ?? colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
