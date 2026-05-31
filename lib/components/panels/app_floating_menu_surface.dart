import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';

class AppFloatingMenuSurface extends StatelessWidget {
  const AppFloatingMenuSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(VisualSpec.surface.radiusCard);

    return Container(
      decoration: BoxDecoration(
        color: VisualSpec.surface.overlay(brightness),
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: VisualSpec.surface.borderWidth,
        ),
        boxShadow: context.shadows.level1,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: VisualSpec.surface.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
