import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

enum AppSnackBarType { success, error, info }

class AppSnackBar {
  const AppSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool hasFloatingNavInset = false,
  }) {
    _show(
      context,
      type: AppSnackBarType.success,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      hasFloatingNavInset: hasFloatingNavInset,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool hasFloatingNavInset = false,
  }) {
    _show(
      context,
      type: AppSnackBarType.error,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      hasFloatingNavInset: hasFloatingNavInset,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool hasFloatingNavInset = false,
  }) {
    _show(
      context,
      type: AppSnackBarType.info,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      hasFloatingNavInset: hasFloatingNavInset,
    );
  }

  static void _show(
    BuildContext context, {
    required AppSnackBarType type,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    required bool hasFloatingNavInset,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = hasFloatingNavInset
        ? context.spacing.pageBottomInset - context.spacing.sm
        : context.spacing.lg + MediaQuery.paddingOf(context).bottom;

    final backgroundColor = switch (type) {
      AppSnackBarType.success => colorScheme.inverseSurface,
      AppSnackBarType.error => colorScheme.inverseSurface,
      AppSnackBarType.info => colorScheme.inverseSurface,
    };
    final contentColor = switch (type) {
      AppSnackBarType.success => colorScheme.onInverseSurface,
      AppSnackBarType.error => colorScheme.onInverseSurface,
      AppSnackBarType.info => colorScheme.onInverseSurface,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: context.typography.meta.copyWith(color: contentColor),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 3000),
          margin: EdgeInsets.fromLTRB(
            context.spacing.md,
            context.spacing.sm,
            context.spacing.md,
            bottomInset,
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }
}
