import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'brand/brand_palette.dart';
import 'spec.dart';
import 'tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _buildColorScheme(brightness);

    final spacing = AppSpacing.standard();
    const fontSizes = AppFontSizes.standard();
    const cardWidths = AppCardWidths.standard();
    const radius = AppRadius.standard();
    const elevation = AppElevation.standard();
    final shadows = AppShadows.standard(colorScheme);
    final motion = AppMotion.standard();
    final brandColors = BrandColors.fromScheme(colorScheme);
    final surfaces = AppSurfaceRoles(
      appBackground: _appBackgroundFor(brightness),
      surfaceBase: VisualSpec.surface.cardBase(brightness),
      surfaceRaised: VisualSpec.surface.cardRaised(brightness),
      surfaceOverlay: VisualSpec.surface.overlay(brightness),
    );
    final typography = AppTypography.fromColorScheme(colorScheme);

    final outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius.rMd),
      borderSide: BorderSide(
        color: brightness == Brightness.dark
            ? colorScheme.outline
            : colorScheme.outlineVariant,
        width: brightness == Brightness.dark ? 1.15 : 1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _appBackgroundFor(brightness),
      textTheme: typography.toTextTheme(),
      extensions: <ThemeExtension<dynamic>>[
        spacing,
        fontSizes,
        cardWidths,
        radius,
        elevation,
        shadows,
        motion,
        surfaces,
        brandColors,
        typography,
      ],
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: VisualSpec.surface.dividerThickness,
        space: 1,
      ),
      cardTheme: CardThemeData(
        // Variant background is controlled by SectionCard (SSOT).
        elevation: VisualSpec.surface.elevationBase,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: typography.meta.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: typography.caption,
        elevation: elevation.emphasis,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: VisualSpec.icon.sizeDefault,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: VisualSpec.icon.sizeDefault,
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        labelStyle: typography.meta.copyWith(
          color: brightness == Brightness.dark
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
        ),
        hintStyle: typography.body.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: brightness == Brightness.dark ? 0.92 : 1,
          ),
        ),
        errorStyle: typography.caption.copyWith(color: colorScheme.error),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        disabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.35),
        ),
        errorBorder: outlineInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        focusedErrorBorder: outlineInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.35),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colorScheme.outlineVariant),
        selectedColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surfaceContainer,
        labelStyle: typography.meta,
        secondaryLabelStyle: typography.meta.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VisualSpec.surface.overlay(brightness),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VisualSpec.surface.radiusSheet),
        ),
        titleTextStyle: typography.sectionTitle,
        contentTextStyle: typography.body,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VisualSpec.surface.overlay(brightness),
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VisualSpec.surface.radiusSheet),
          ),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        // Actual visual spec is locked in AppSnackBar component.
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.rMd),
          ),
          textStyle: typography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(48),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.rMd),
          ),
          textStyle: typography.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(VisualSpec.icon.minTapTarget, VisualSpec.icon.minTapTarget),
          ),
          iconSize: WidgetStatePropertyAll(VisualSpec.icon.sizeDefault),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurfaceVariant),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            final pressedAlpha = _pressedOverlayAlpha(brightness);
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: pressedAlpha);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: pressedAlpha * 0.75);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withValues(alpha: pressedAlpha * 0.85);
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.rMd),
            ),
          ),
        ),
      ),
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: VisualSpec.brand.seedColor,
      brightness: brightness,
    );
    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: VisualSpec.brand.seed,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFEAF2FF),
        onPrimaryContainer: const Color(0xFF0A84FF),
        secondary: const Color(0xFF5E5CE6),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFF0EEFF),
        onSecondaryContainer: const Color(0xFF5E5CE6),
        tertiary: const Color(0xFFFF9F0A),
        onTertiary: const Color(0xFF111111),
        tertiaryContainer: const Color(0xFFFFF3E0),
        onTertiaryContainer: const Color(0xFFFF9F0A),
        surface: VisualSpec.brand.lightSurface,
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: VisualSpec.brand.lightSurfaceLow,
        surfaceContainer: VisualSpec.brand.lightSurfaceContainer,
        surfaceContainerHigh: VisualSpec.brand.lightSurfaceHigh,
        surfaceContainerHighest: VisualSpec.brand.lightSurfaceHighest,
        onSurface: VisualSpec.brand.lightTextPrimary,
        onSurfaceVariant: VisualSpec.brand.lightTextSecondary,
        outline: const Color(0xFFE5E5EA),
        outlineVariant: VisualSpec.brand.lightOutlineVariant,
        error: VisualSpec.brand.lightNegative,
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFDECEC),
        onErrorContainer: const Color(0xFFC83C3C),
      );
    }

    return base.copyWith(
      primary: VisualSpec.brand.seed,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFF0E355C),
      onPrimaryContainer: const Color(0xFFD9EAFF),
      secondary: const Color(0xFFB8C2FF),
      onSecondary: const Color(0xFF1B2250),
      secondaryContainer: const Color(0xFF2B336A),
      onSecondaryContainer: const Color(0xFFE3E7FF),
      tertiary: const Color(0xFFFBC66B),
      onTertiary: const Color(0xFF3B2800),
      tertiaryContainer: const Color(0xFF5C4300),
      onTertiaryContainer: const Color(0xFFFFE9BF),
      surface: VisualSpec.brand.darkSurface,
      surfaceContainerLowest: const Color(0xFF121317),
      surfaceContainerLow: VisualSpec.brand.darkSurfaceLow,
      surfaceContainer: VisualSpec.brand.darkSurfaceContainer,
      surfaceContainerHigh: VisualSpec.brand.darkSurfaceHigh,
      surfaceContainerHighest: VisualSpec.brand.darkSurfaceHighest,
      onSurface: VisualSpec.brand.darkTextPrimary,
      onSurfaceVariant: VisualSpec.brand.darkTextSecondary,
      outline: const Color(0xFF676B76),
      outlineVariant: VisualSpec.brand.darkOutlineVariant,
      error: VisualSpec.brand.darkNegative,
      onError: const Color(0xFF2A0A0E),
      errorContainer: const Color(0xFF5B1D23),
      onErrorContainer: const Color(0xFFFFE0E3),
    );
  }

  static Color _appBackgroundFor(Brightness brightness) {
    return VisualSpec.brand.background(brightness);
  }

  static double _pressedOverlayAlpha(Brightness brightness) {
    return brightness == Brightness.dark
        ? VisualSpec.brand.darkOverlayPressedAlpha
        : VisualSpec.brand.lightOverlayPressedAlpha;
  }
}
