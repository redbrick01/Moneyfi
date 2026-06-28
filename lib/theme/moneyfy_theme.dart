import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/font_families.dart';
import 'package:moneyfy/design_system/font_weights.dart';
import 'moneyfy_colors.dart';

export 'moneyfy_colors.dart';

class MoneyfyTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFontFamilies.sans,
      scaffoldBackgroundColor: MoneyfyPalette.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: MoneyfyPalette.accent,
            brightness: Brightness.light,
          ).copyWith(
            primary: MoneyfyPalette.primary,
            onPrimary: MoneyfyPalette.onPrimary,
            primaryContainer: MoneyfyPalette.softNeutral,
            onPrimaryContainer: MoneyfyPalette.primary,
            secondary: MoneyfyPalette.info,
            onSecondary: MoneyfyPalette.onPrimary,
            secondaryContainer: MoneyfyPalette.softNeutral,
            onSecondaryContainer: MoneyfyPalette.info,
            surface: MoneyfyPalette.surface,
            onSurface: MoneyfyPalette.ink,
            onSurfaceVariant: MoneyfyPalette.secondaryText,
            outline: MoneyfyPalette.border,
            outlineVariant: MoneyfyPalette.softNeutral,
            error: MoneyfyPalette.error,
            onError: MoneyfyPalette.onPrimary,
            errorContainer: MoneyfyPalette.softNeutral,
            onErrorContainer: MoneyfyPalette.error,
          ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFontFamilies.display,
          fontSize: 32,
          fontWeight: AppFontWeights.semibold,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.28,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFontFamilies.mono,
          fontSize: 36,
          fontWeight: AppFontWeights.semibold,
          color: MoneyfyPalette.ink,
          letterSpacing: 0.196,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: AppFontWeights.semibold,
          color: MoneyfyPalette.ink,
          letterSpacing: 0.231,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: AppFontWeights.semibold,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.374,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: MoneyfyPalette.secondaryText,
          height: 1.47,
          letterSpacing: -0.374,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          color: MoneyfyPalette.tertiaryText,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: AppFontWeights.regular,
          color: MoneyfyPalette.secondaryText,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 74,
        backgroundColor: MoneyfyPalette.surface,
        indicatorColor: MoneyfyPalette.softNeutral,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: AppFontWeights.semibold,
            color: MoneyfyPalette.secondaryText,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MoneyfyPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: MoneyfyPalette.ink,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: AppFontWeights.semibold,
          color: MoneyfyPalette.ink,
        ),
      ),
      iconTheme: const IconThemeData(
        color: MoneyfyPalette.tertiaryText,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: MoneyfyPalette.tertiaryText,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MoneyfyPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: MoneyfyPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: MoneyfyPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(
            color: MoneyfyPalette.accent,
            width: 1.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoneyfyPalette.primary,
          side: const BorderSide(color: MoneyfyPalette.border),
          backgroundColor: MoneyfyPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: AppFontWeights.semibold,
          ),
        ),
      ),
      dividerColor: MoneyfyPalette.border,
    );
  }
}
