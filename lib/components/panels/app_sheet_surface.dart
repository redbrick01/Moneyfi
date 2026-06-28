import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';

class AppSheetSurface extends StatelessWidget {
  const AppSheetSurface({
    super.key,
    required this.child,
    this.heightFactor,
    this.backgroundColor,
  });

  final Widget child;
  final double? heightFactor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radius.rLg),
        ),
      ),
      child: SafeArea(top: false, child: child),
    );

    if (heightFactor == null) return sheet;

    return FractionallySizedBox(
      heightFactor: heightFactor,
      alignment: Alignment.bottomCenter,
      child: sheet,
    );
  }
}

class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.spacing.xl + context.spacing.xs,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
    );
  }
}
