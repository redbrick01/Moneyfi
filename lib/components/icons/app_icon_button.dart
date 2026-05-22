import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import 'app_icon.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
  });

  final String tooltip;
  final AppIconName icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: BoxConstraints(
        minWidth: VisualSpec.icon.minTapTarget,
        minHeight: VisualSpec.icon.minTapTarget,
      ),
      visualDensity: VisualDensity.standard,
      icon: AppIcon(
        icon,
        size: size ?? VisualSpec.icon.sizeDefault,
        color: color,
      ),
    );
  }
}
