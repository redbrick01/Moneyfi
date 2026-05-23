import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final IconData? icon;

  // Disabled reason pattern:
  // Place helper text below this button at page level (e.g. caption/meta style)
  // so users know why action is disabled.
  @override
  Widget build(BuildContext context) {
    final content = _ButtonContent(
      label: label,
      isLoading: isLoading,
      icon: icon,
    );
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: _buttonStyle(context, variant: _ButtonVariant.primary),
      child: content,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.tonal(
      onPressed: onPressed,
      style: _buttonStyle(context, variant: _ButtonVariant.secondary),
      child: _ButtonContent(label: label, isLoading: false, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppGhostButton extends StatelessWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed,
      style: _buttonStyle(context, variant: _ButtonVariant.ghost),
      child: _ButtonContent(label: label, isLoading: false, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed,
      style: _buttonStyle(context, variant: _ButtonVariant.destructive),
      child: _ButtonContent(label: label, isLoading: false, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = Theme.of(context).colorScheme.onPrimary;
    final hasIcon = icon != null;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: isLoading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon) ...[
                Icon(icon, size: VisualSpec.icon.sizeSmall),
                SizedBox(width: context.spacing.xs),
              ],
              Text(label),
            ],
          ),
        ),
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: spinnerColor,
            ),
          ),
      ],
    );
  }
}

enum _ButtonVariant { primary, secondary, ghost, destructive }

ButtonStyle _buttonStyle(
  BuildContext context, {
  required _ButtonVariant variant,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final isGhost = variant == _ButtonVariant.ghost;
  final isDestructive = variant == _ButtonVariant.destructive;
  final background = switch (variant) {
    _ButtonVariant.primary => colorScheme.primary,
    _ButtonVariant.secondary => colorScheme.surface,
    _ButtonVariant.ghost => Colors.transparent,
    _ButtonVariant.destructive => Colors.transparent,
  };
  final foreground = switch (variant) {
    _ButtonVariant.primary => colorScheme.onPrimary,
    _ButtonVariant.secondary => colorScheme.primary,
    _ButtonVariant.ghost => colorScheme.primary,
    _ButtonVariant.destructive => colorScheme.error,
  };
  final disabledForeground = isGhost || isDestructive
      ? colorScheme.onSurfaceVariant
      : foreground.withValues(alpha: 0.72);
  final disabledBackground = isGhost || isDestructive
      ? Colors.transparent
      : background.withValues(alpha: 0.55);
  final overlayBase = colorScheme.primary;
  final pressedAlpha = Theme.of(context).brightness == Brightness.dark
      ? VisualSpec.brand.darkOverlayPressedAlpha
      : VisualSpec.brand.lightOverlayPressedAlpha;

  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 22, vertical: 11),
    ),
    textStyle: WidgetStatePropertyAll(context.typography.button),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (variant != _ButtonVariant.secondary) return BorderSide.none;
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: colorScheme.outlineVariant);
      }
      return BorderSide(color: colorScheme.primary);
    }),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return disabledBackground;
      return background;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return disabledForeground;
      return foreground;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return overlayBase.withValues(alpha: pressedAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return overlayBase.withValues(alpha: pressedAlpha * 0.75);
      }
      if (states.contains(WidgetState.focused)) {
        return overlayBase.withValues(alpha: pressedAlpha * 0.85);
      }
      return null;
    }),
  );
}
