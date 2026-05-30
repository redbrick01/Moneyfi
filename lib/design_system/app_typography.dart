import 'package:flutter/material.dart';

import 'font_families.dart';
import 'font_weights.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.pageTitle,
    required this.heroNumber,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.meta,
    required this.caption,
    required this.button,
  });

  factory AppTypography.fromColorScheme(ColorScheme colorScheme) {
    const numberFeatures = [FontFeature.tabularFigures()];
    return AppTypography(
      pageTitle: TextStyle(
        fontFamily: AppFontFamilies.display,
        fontSize: 32,
        fontWeight: AppFontWeights.regular,
        height: 1.12,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      heroNumber: TextStyle(
        fontFamily: AppFontFamilies.mono,
        fontSize: 36,
        fontWeight: AppFontWeights.medium,
        height: 1.1,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFeatures: numberFeatures,
      ),
      sectionTitle: TextStyle(
        fontFamily: AppFontFamilies.display,
        fontSize: 18,
        fontWeight: AppFontWeights.semibold,
        height: 1.3,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      cardTitle: TextStyle(
        fontFamily: AppFontFamilies.sans,
        fontSize: 16,
        fontWeight: AppFontWeights.semibold,
        height: 1.35,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFeatures: numberFeatures,
      ),
      body: TextStyle(
        fontFamily: AppFontFamilies.sans,
        fontSize: 16,
        fontWeight: AppFontWeights.regular,
        height: 1.5,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      meta: TextStyle(
        fontFamily: AppFontFamilies.sans,
        fontSize: 14,
        fontWeight: AppFontWeights.regular,
        height: 1.43,
        letterSpacing: 0,
        color: colorScheme.onSurfaceVariant,
        fontFeatures: numberFeatures,
      ),
      caption: TextStyle(
        fontFamily: AppFontFamilies.sans,
        fontSize: 13,
        fontWeight: AppFontWeights.regular,
        height: 1.3,
        letterSpacing: 0,
        color: colorScheme.onSurfaceVariant,
        fontFeatures: numberFeatures,
      ),
      button: TextStyle(
        fontFamily: AppFontFamilies.sans,
        fontSize: 16,
        fontWeight: AppFontWeights.semibold,
        height: 1.0,
        letterSpacing: 0,
        color: colorScheme.onPrimary,
      ),
    );
  }

  final TextStyle pageTitle;
  final TextStyle heroNumber;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle meta;
  final TextStyle caption;
  final TextStyle button;

  TextTheme toTextTheme() {
    return TextTheme(
      headlineLarge: pageTitle,
      headlineSmall: heroNumber,
      titleLarge: sectionTitle,
      titleMedium: cardTitle,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: meta,
      labelLarge: button,
      labelMedium: meta,
      labelSmall: caption,
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? pageTitle,
    TextStyle? heroNumber,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? meta,
    TextStyle? caption,
    TextStyle? button,
  }) {
    return AppTypography(
      pageTitle: pageTitle ?? this.pageTitle,
      heroNumber: heroNumber ?? this.heroNumber,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      meta: meta ?? this.meta,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t) ?? pageTitle,
      heroNumber: TextStyle.lerp(heroNumber, other.heroNumber, t) ?? heroNumber,
      sectionTitle:
          TextStyle.lerp(sectionTitle, other.sectionTitle, t) ?? sectionTitle,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t) ?? cardTitle,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      meta: TextStyle.lerp(meta, other.meta, t) ?? meta,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      button: TextStyle.lerp(button, other.button, t) ?? button,
    );
  }
}
