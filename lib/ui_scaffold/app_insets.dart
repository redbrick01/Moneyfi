import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';

class AppInsets {
  const AppInsets._();

  // TODO: keep this aligned with the floating tab bar rendered in app_shell_page.dart.
  static const double floatingNavHeight = 72;

  static double bottomContentInset(
    BuildContext context, {
    bool hasFloatingNav = true,
    double? extraGap,
    double additional = 0,
  }) {
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final gap = extraGap ?? context.spacing.sm;
    final navInset = hasFloatingNav ? floatingNavHeight : 0;

    return safeAreaBottom + navInset + gap + additional;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    bool hasFloatingNav = true,
    double? top,
    double bottomAdditional = 0,
    double? extraBottomGap,
  }) {
    final horizontal = context.contentHorizontalPadding;
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? context.spacing.pageTop,
      horizontal,
      bottomContentInset(
        context,
        hasFloatingNav: hasFloatingNav,
        extraGap: extraBottomGap,
        additional: bottomAdditional,
      ),
    );
  }
}
