import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'brand/brand_palette.dart';
import 'font_families.dart';
import 'font_weights.dart';
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
      fontFamily: AppFontFamilies.sans,
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
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: typography.meta.copyWith(
          fontWeight: AppFontWeights.semibold,
        ),
        unselectedLabelStyle: typography.caption,
        elevation: 0,
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
        fillColor: colorScheme.surface,
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
          horizontal: 20,
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
        selectedColor: colorScheme.surface,
        backgroundColor: colorScheme.surface,
        labelStyle: typography.meta,
        secondaryLabelStyle: typography.meta.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VisualSpec.surface.overlay(brightness),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VisualSpec.surface.radiusSheet),
        ),
        titleTextStyle: typography.sectionTitle,
        contentTextStyle: typography.body,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VisualSpec.surface.overlay(brightness),
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
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
          minimumSize: Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.rPill),
          ),
          textStyle: typography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(44),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.rPill),
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
              borderRadius: BorderRadius.circular(radius.rPill),
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
        onPrimary: VisualSpec.brand.onPrimary,
        primaryContainer: VisualSpec.brand.primaryContainer(brightness),
        onPrimaryContainer: VisualSpec.brand.onPrimaryContainer(brightness),
        secondary: VisualSpec.brand.info,
        onSecondary: VisualSpec.brand.onPrimary,
        secondaryContainer: VisualSpec.brand.infoContainer(brightness),
        onSecondaryContainer: VisualSpec.brand.onInfoContainer(brightness),
        tertiary: VisualSpec.brand.lightWarning,
        onTertiary: VisualSpec.brand.lightTextPrimary,
        tertiaryContainer: VisualSpec.brand.warningContainer(brightness),
        onTertiaryContainer: VisualSpec.brand.onWarningContainer(brightness),
        surface: VisualSpec.brand.lightSurface,
        surfaceContainerLowest: VisualSpec.brand.surfaceLowest(brightness),
        surfaceContainerLow: VisualSpec.brand.lightSurfaceLow,
        surfaceContainer: VisualSpec.brand.lightSurfaceContainer,
        surfaceContainerHigh: VisualSpec.brand.lightSurfaceHigh,
        surfaceContainerHighest: VisualSpec.brand.lightSurfaceHighest,
        onSurface: VisualSpec.brand.lightTextPrimary,
        onSurfaceVariant: VisualSpec.brand.lightTextSecondary,
        outline: VisualSpec.brand.outline(brightness),
        outlineVariant: VisualSpec.brand.lightOutlineVariant,
        error: VisualSpec.brand.lightNegative,
        onError: VisualSpec.brand.onPrimary,
        errorContainer: VisualSpec.brand.negativeContainer(brightness),
        onErrorContainer: VisualSpec.brand.onNegativeContainer(brightness),
      );
    }

    return base.copyWith(
      primary: VisualSpec.brand.primary,
      onPrimary: VisualSpec.brand.onPrimary,
      primaryContainer: VisualSpec.brand.primaryContainer(brightness),
      onPrimaryContainer: VisualSpec.brand.onPrimaryContainer(brightness),
      secondary: VisualSpec.brand.info,
      onSecondary: VisualSpec.brand.onPrimary,
      secondaryContainer: VisualSpec.brand.infoContainer(brightness),
      onSecondaryContainer: VisualSpec.brand.onInfoContainer(brightness),
      tertiary: VisualSpec.brand.darkWarning,
      onTertiary: VisualSpec.brand.lightTextPrimary,
      tertiaryContainer: VisualSpec.brand.warningContainer(brightness),
      onTertiaryContainer: VisualSpec.brand.onWarningContainer(brightness),
      surface: VisualSpec.brand.darkSurface,
      surfaceContainerLowest: VisualSpec.brand.surfaceLowest(brightness),
      surfaceContainerLow: VisualSpec.brand.darkSurfaceLow,
      surfaceContainer: VisualSpec.brand.darkSurfaceContainer,
      surfaceContainerHigh: VisualSpec.brand.darkSurfaceHigh,
      surfaceContainerHighest: VisualSpec.brand.darkSurfaceHighest,
      onSurface: VisualSpec.brand.darkTextPrimary,
      onSurfaceVariant: VisualSpec.brand.darkTextSecondary,
      outline: VisualSpec.brand.outline(brightness),
      outlineVariant: VisualSpec.brand.darkOutlineVariant,
      error: VisualSpec.brand.darkNegative,
      onError: VisualSpec.brand.onPrimary,
      errorContainer: VisualSpec.brand.negativeContainer(brightness),
      onErrorContainer: VisualSpec.brand.onNegativeContainer(brightness),
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
