import 'package:flutter/material.dart';

import 'moneyfy_colors.dart';

export 'moneyfy_colors.dart';

class MoneyfyTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: '.SF Pro Text',
      scaffoldBackgroundColor: MoneyfyPalette.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: MoneyfyPalette.accent,
            brightness: Brightness.light,
          ).copyWith(
            primary: MoneyfyPalette.primary,
            onPrimary: MoneyfyPalette.onPrimary,
            primaryContainer: MoneyfyPalette.primarySoft,
            onPrimaryContainer: MoneyfyPalette.primary,
            secondary: MoneyfyPalette.info,
            onSecondary: MoneyfyPalette.onPrimary,
            secondaryContainer: MoneyfyPalette.infoBg,
            onSecondaryContainer: MoneyfyPalette.info,
            surface: MoneyfyPalette.surface,
            onSurface: MoneyfyPalette.ink,
            onSurfaceVariant: MoneyfyPalette.secondaryText,
            outline: MoneyfyPalette.border,
            outlineVariant: MoneyfyPalette.borderNeutral,
            error: MoneyfyPalette.error,
            onError: MoneyfyPalette.onPrimary,
            errorContainer: MoneyfyPalette.errorBg,
            onErrorContainer: MoneyfyPalette.errorStrong,
          ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.7,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: MoneyfyPalette.ink,
          letterSpacing: -0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: MoneyfyPalette.secondaryText,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: MoneyfyPalette.tertiaryText,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MoneyfyPalette.secondaryText,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 74,
        backgroundColor: MoneyfyPalette.surface,
        indicatorColor: MoneyfyPalette.accentSoft,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
        fillColor: MoneyfyPalette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MoneyfyPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MoneyfyPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: MoneyfyPalette.accent,
            width: 1.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoneyfyPalette.ink,
          side: const BorderSide(color: MoneyfyPalette.border),
          backgroundColor: MoneyfyPalette.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: MoneyfyPalette.border,
    );
  }
}
