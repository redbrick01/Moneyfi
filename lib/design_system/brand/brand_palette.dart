import 'package:flutter/material.dart';

import '../spec.dart';

/// Role-locked brand tokens.
///
/// Neutral roles:
/// - app background: `surface`
/// - section base/raised/overlay: `surfaceContainerLow/High/Highest`
/// - text: `onSurface` and `onSurfaceVariant`
/// - stroke: `outlineVariant`
///
/// Status roles:
/// - positive: `secondaryContainer` + `onSecondaryContainer`
/// - negative: `errorContainer` + `onErrorContainer`
/// - warning: `tertiaryContainer` + `onTertiaryContainer`
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.seedColor,
    required this.primary,
    required this.primaryContainer,
    required this.primaryOnContainer,
    required this.neutralBackground,
    required this.neutralSurfaceBase,
    required this.neutralSurfaceRaised,
    required this.neutralSurfaceOverlay,
    required this.neutralText,
    required this.neutralTextMuted,
    required this.neutralOutline,
    required this.positiveContainer,
    required this.positiveOn,
    required this.negativeContainer,
    required this.negativeOn,
    required this.warningContainer,
    required this.warningOn,
  });

  factory BrandColors.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return BrandColors(
      seedColor: VisualSpec.brand.seedColor,
      primary: scheme.primary,
      primaryContainer: scheme.primaryContainer,
      primaryOnContainer: scheme.onPrimaryContainer,
      neutralBackground: isDark
          ? VisualSpec.brand.darkBg
          : VisualSpec.brand.lightBg,
      neutralSurfaceBase: scheme.surfaceContainerLow,
      neutralSurfaceRaised: scheme.surfaceContainerHigh,
      neutralSurfaceOverlay: scheme.surfaceContainerHighest,
      neutralText: scheme.onSurface,
      neutralTextMuted: scheme.onSurfaceVariant,
      neutralOutline: scheme.outlineVariant,
      positiveContainer: isDark
          ? VisualSpec.brand.darkPositiveContainer
          : VisualSpec.brand.lightPositiveContainer,
      positiveOn: isDark
          ? VisualSpec.brand.darkOnPositiveContainer
          : VisualSpec.brand.lightOnPositiveContainer,
      negativeContainer: isDark
          ? VisualSpec.brand.darkNegativeContainer
          : VisualSpec.brand.lightNegativeContainer,
      negativeOn: isDark
          ? VisualSpec.brand.darkOnNegativeContainer
          : VisualSpec.brand.lightOnNegativeContainer,
      warningContainer: isDark
          ? VisualSpec.brand.darkWarningContainer
          : VisualSpec.brand.lightWarningContainer,
      warningOn: isDark
          ? VisualSpec.brand.darkOnWarningContainer
          : VisualSpec.brand.lightOnWarningContainer,
    );
  }

  final Color seedColor;
  final Color primary;
  final Color primaryContainer;
  final Color primaryOnContainer;
  final Color neutralBackground;
  final Color neutralSurfaceBase;
  final Color neutralSurfaceRaised;
  final Color neutralSurfaceOverlay;
  final Color neutralText;
  final Color neutralTextMuted;
  final Color neutralOutline;
  final Color positiveContainer;
  final Color positiveOn;
  final Color negativeContainer;
  final Color negativeOn;
  final Color warningContainer;
  final Color warningOn;

  @override
  BrandColors copyWith({
    Color? seedColor,
    Color? primary,
    Color? primaryContainer,
    Color? primaryOnContainer,
    Color? neutralBackground,
    Color? neutralSurfaceBase,
    Color? neutralSurfaceRaised,
    Color? neutralSurfaceOverlay,
    Color? neutralText,
    Color? neutralTextMuted,
    Color? neutralOutline,
    Color? positiveContainer,
    Color? positiveOn,
    Color? negativeContainer,
    Color? negativeOn,
    Color? warningContainer,
    Color? warningOn,
  }) {
    return BrandColors(
      seedColor: seedColor ?? this.seedColor,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      primaryOnContainer: primaryOnContainer ?? this.primaryOnContainer,
      neutralBackground: neutralBackground ?? this.neutralBackground,
      neutralSurfaceBase: neutralSurfaceBase ?? this.neutralSurfaceBase,
      neutralSurfaceRaised: neutralSurfaceRaised ?? this.neutralSurfaceRaised,
      neutralSurfaceOverlay:
          neutralSurfaceOverlay ?? this.neutralSurfaceOverlay,
      neutralText: neutralText ?? this.neutralText,
      neutralTextMuted: neutralTextMuted ?? this.neutralTextMuted,
      neutralOutline: neutralOutline ?? this.neutralOutline,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      positiveOn: positiveOn ?? this.positiveOn,
      negativeContainer: negativeContainer ?? this.negativeContainer,
      negativeOn: negativeOn ?? this.negativeOn,
      warningContainer: warningContainer ?? this.warningContainer,
      warningOn: warningOn ?? this.warningOn,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      seedColor: Color.lerp(seedColor, other.seedColor, t) ?? seedColor,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t) ??
          primaryContainer,
      primaryOnContainer:
          Color.lerp(primaryOnContainer, other.primaryOnContainer, t) ??
          primaryOnContainer,
      neutralBackground:
          Color.lerp(neutralBackground, other.neutralBackground, t) ??
          neutralBackground,
      neutralSurfaceBase:
          Color.lerp(neutralSurfaceBase, other.neutralSurfaceBase, t) ??
          neutralSurfaceBase,
      neutralSurfaceRaised:
          Color.lerp(neutralSurfaceRaised, other.neutralSurfaceRaised, t) ??
          neutralSurfaceRaised,
      neutralSurfaceOverlay:
          Color.lerp(neutralSurfaceOverlay, other.neutralSurfaceOverlay, t) ??
          neutralSurfaceOverlay,
      neutralText: Color.lerp(neutralText, other.neutralText, t) ?? neutralText,
      neutralTextMuted:
          Color.lerp(neutralTextMuted, other.neutralTextMuted, t) ??
          neutralTextMuted,
      neutralOutline:
          Color.lerp(neutralOutline, other.neutralOutline, t) ?? neutralOutline,
      positiveContainer:
          Color.lerp(positiveContainer, other.positiveContainer, t) ??
          positiveContainer,
      positiveOn: Color.lerp(positiveOn, other.positiveOn, t) ?? positiveOn,
      negativeContainer:
          Color.lerp(negativeContainer, other.negativeContainer, t) ??
          negativeContainer,
      negativeOn: Color.lerp(negativeOn, other.negativeOn, t) ?? negativeOn,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      warningOn: Color.lerp(warningOn, other.warningOn, t) ?? warningOn,
    );
  }
}
