import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'brand/brand_palette.dart';
import 'tokens.dart';

extension AppBuildContextX on BuildContext {
  AppSpacing get spacing {
    final value = Theme.of(this).extension<AppSpacing>();
    if (value == null) {
      throw StateError('AppSpacing extension is not registered on ThemeData.');
    }
    return value;
  }

  AppRadius get radius {
    final value = Theme.of(this).extension<AppRadius>();
    if (value == null) {
      throw StateError('AppRadius extension is not registered on ThemeData.');
    }
    return value;
  }

  AppFontSizes get fontSizes {
    final value = Theme.of(this).extension<AppFontSizes>();
    if (value == null) {
      throw StateError(
        'AppFontSizes extension is not registered on ThemeData.',
      );
    }
    return value;
  }

  AppCardWidths get cardWidths {
    final value = Theme.of(this).extension<AppCardWidths>();
    if (value == null) {
      throw StateError(
        'AppCardWidths extension is not registered on ThemeData.',
      );
    }
    return value;
  }

  AppElevation get elevation {
    final value = Theme.of(this).extension<AppElevation>();
    if (value == null) {
      throw StateError(
        'AppElevation extension is not registered on ThemeData.',
      );
    }
    return value;
  }

  AppShadows get shadows {
    final value = Theme.of(this).extension<AppShadows>();
    if (value == null) {
      throw StateError('AppShadows extension is not registered on ThemeData.');
    }
    return value;
  }

  AppMotion get motion {
    final value = Theme.of(this).extension<AppMotion>();
    if (value == null) {
      throw StateError('AppMotion extension is not registered on ThemeData.');
    }
    return value;
  }

  AppTypography get typography {
    final value = Theme.of(this).extension<AppTypography>();
    if (value == null) {
      throw StateError(
        'AppTypography extension is not registered on ThemeData.',
      );
    }
    return value;
  }

  AppSurfaceRoles get surfaces {
    final value = Theme.of(this).extension<AppSurfaceRoles>();
    if (value == null) {
      throw StateError(
        'AppSurfaceRoles extension is not registered on ThemeData.',
      );
    }
    return value;
  }

  BrandColors get colors {
    final value = Theme.of(this).extension<BrandColors>();
    if (value == null) {
      throw StateError('BrandColors extension is not registered on ThemeData.');
    }
    return value;
  }

  double get contentHorizontalPadding {
    return spacing.responsiveHorizontal(MediaQuery.sizeOf(this).width);
  }

  double cardPadding({bool dense = false}) {
    return spacing.cardPadding(
      dense: dense,
      widthDp: MediaQuery.sizeOf(this).width,
    );
  }
}
