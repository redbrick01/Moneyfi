import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';

enum AppInnerPanelTone { base, raised }

class AppInnerPanel extends StatelessWidget {
  const AppInnerPanel({
    super.key,
    required this.child,
    this.padding,
    this.dense = false,
    this.tone = AppInnerPanelTone.base,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool dense;
  final AppInnerPanelTone tone;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedPadding =
        padding ??
        EdgeInsets.all(
          dense
              ? context.spacing.sm
              : context.spacing.sm + context.spacing.xs / 4,
        );
    final background = switch (tone) {
      AppInnerPanelTone.base => context.colors.neutralSurfaceBase,
      AppInnerPanelTone.raised => context.colors.neutralSurfaceRaised,
    };
    final borderRadius = BorderRadius.circular(context.radius.rMd);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                width: VisualSpec.surface.borderWidth,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
