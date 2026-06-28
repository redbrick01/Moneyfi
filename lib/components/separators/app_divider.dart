import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/spec.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.inset,
    this.thickness,
    this.space = 1,
    this.color,
  });

  final double? inset;
  final double? thickness;
  final double space;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: space,
      thickness: thickness ?? VisualSpec.surface.dividerThickness,
      indent: inset ?? VisualSpec.surface.dividerInset,
      endIndent: inset ?? VisualSpec.surface.dividerInset,
      color: color ?? Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Use divider for local grouping (inside cards/lists), not for splitting
/// whole pages into many hard sections.
