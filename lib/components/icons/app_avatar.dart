import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VisualSpec.icon.avatarBox,
      height: VisualSpec.icon.avatarBox,
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.icon.avatarBox / 2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
