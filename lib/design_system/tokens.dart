import 'package:flutter/material.dart';

import 'spec.dart';

class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.pageTop,
    required this.pageBottomInset,
  });

  AppSpacing.standard()
    : xs = 8,
      sm = 12,
      md = VisualSpec.surface.paddingCard,
      lg = 24,
      xl = VisualSpec.surface.sectionGap,
      xxl = 48,
      xxxl = 80,
      pageTop = 24,
      pageBottomInset = 132;

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double pageTop;
  final double pageBottomInset;

  double responsiveHorizontal(double widthDp) {
    if (widthDp <= 360) return 14;
    if (widthDp <= 430) return 16;
    return lg;
  }

  double get sectionGap => xl;
  double cardPadding({bool dense = false, double? widthDp}) {
    if (dense) return VisualSpec.surface.paddingCardDense;
    if (widthDp != null && widthDp <= 430) return 16;
    return VisualSpec.surface.paddingCard;
  }

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? pageTop,
    double? pageBottomInset,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      pageTop: pageTop ?? this.pageTop,
      pageBottomInset: pageBottomInset ?? this.pageBottomInset,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
      xxxl: lerpDouble(xxxl, other.xxxl, t),
      pageTop: lerpDouble(pageTop, other.pageTop, t),
      pageBottomInset: lerpDouble(pageBottomInset, other.pageBottomInset, t),
    );
  }
}

class AppFontSizes extends ThemeExtension<AppFontSizes> {
  const AppFontSizes({
    required this.s10,
    required this.s12,
    required this.s14,
    required this.s16,
    required this.s18,
    required this.s20,
    required this.s22,
    required this.s24,
  });

  const AppFontSizes.standard()
    : s10 = 10,
      s12 = 12,
      s14 = 14,
      s16 = 16,
      s18 = 18,
      s20 = 20,
      s22 = 22,
      s24 = 24;

  final double s10;
  final double s12;
  final double s14;
  final double s16;
  final double s18;
  final double s20;
  final double s22;
  final double s24;

  @override
  AppFontSizes copyWith({
    double? s10,
    double? s12,
    double? s14,
    double? s16,
    double? s18,
    double? s20,
    double? s22,
    double? s24,
  }) {
    return AppFontSizes(
      s10: s10 ?? this.s10,
      s12: s12 ?? this.s12,
      s14: s14 ?? this.s14,
      s16: s16 ?? this.s16,
      s18: s18 ?? this.s18,
      s20: s20 ?? this.s20,
      s22: s22 ?? this.s22,
      s24: s24 ?? this.s24,
    );
  }

  @override
  AppFontSizes lerp(ThemeExtension<AppFontSizes>? other, double t) {
    if (other is! AppFontSizes) return this;
    return AppFontSizes(
      s10: lerpDouble(s10, other.s10, t),
      s12: lerpDouble(s12, other.s12, t),
      s14: lerpDouble(s14, other.s14, t),
      s16: lerpDouble(s16, other.s16, t),
      s18: lerpDouble(s18, other.s18, t),
      s20: lerpDouble(s20, other.s20, t),
      s22: lerpDouble(s22, other.s22, t),
      s24: lerpDouble(s24, other.s24, t),
    );
  }
}

class AppCardWidths extends ThemeExtension<AppCardWidths> {
  const AppCardWidths({
    required this.level1Factor,
    required this.level2Factor,
    required this.level3Factor,
  });

  const AppCardWidths.standard()
    : level1Factor = 1.0,
      level2Factor = 1.0,
      level3Factor = 1.0;

  const AppCardWidths.level1Only()
    : level1Factor = 1.0,
      level2Factor = 1.0,
      level3Factor = 1.0;

  final double level1Factor;
  final double level2Factor;
  final double level3Factor;

  double apply(double availableWidth, {required int level}) {
    final factor = switch (level) {
      1 => level1Factor,
      2 => level2Factor,
      3 => level3Factor,
      _ => level1Factor,
    };
    return availableWidth * factor;
  }

  @override
  AppCardWidths copyWith({
    double? level1Factor,
    double? level2Factor,
    double? level3Factor,
  }) {
    return AppCardWidths(
      level1Factor: level1Factor ?? this.level1Factor,
      level2Factor: level2Factor ?? this.level2Factor,
      level3Factor: level3Factor ?? this.level3Factor,
    );
  }

  @override
  AppCardWidths lerp(ThemeExtension<AppCardWidths>? other, double t) {
    if (other is! AppCardWidths) return this;
    return AppCardWidths(
      level1Factor: lerpDouble(level1Factor, other.level1Factor, t),
      level2Factor: lerpDouble(level2Factor, other.level2Factor, t),
      level3Factor: lerpDouble(level3Factor, other.level3Factor, t),
    );
  }
}

class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    required this.rSm,
    required this.rMd,
    required this.rLg,
    required this.rPill,
  });

  const AppRadius.standard() : rSm = 8, rMd = 11, rLg = 18, rPill = 9999;

  final double rSm;
  final double rMd;
  final double rLg;
  final double rPill;

  @override
  AppRadius copyWith({double? rSm, double? rMd, double? rLg, double? rPill}) {
    return AppRadius(
      rSm: rSm ?? this.rSm,
      rMd: rMd ?? this.rMd,
      rLg: rLg ?? this.rLg,
      rPill: rPill ?? this.rPill,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      rSm: lerpDouble(rSm, other.rSm, t),
      rMd: lerpDouble(rMd, other.rMd, t),
      rLg: lerpDouble(rLg, other.rLg, t),
      rPill: lerpDouble(rPill, other.rPill, t),
    );
  }
}

class AppElevation extends ThemeExtension<AppElevation> {
  const AppElevation({
    required this.base,
    required this.emphasis,
    required this.hero,
  });

  const AppElevation.standard() : base = 0, emphasis = 0, hero = 0;

  final double base;
  final double emphasis;
  final double hero;

  @override
  AppElevation copyWith({double? base, double? emphasis, double? hero}) {
    return AppElevation(
      base: base ?? this.base,
      emphasis: emphasis ?? this.emphasis,
      hero: hero ?? this.hero,
    );
  }

  @override
  AppElevation lerp(ThemeExtension<AppElevation>? other, double t) {
    if (other is! AppElevation) return this;
    return AppElevation(
      base: lerpDouble(base, other.base, t),
      emphasis: lerpDouble(emphasis, other.emphasis, t),
      hero: lerpDouble(hero, other.hero, t),
    );
  }
}

class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.level1,
    required this.level2,
    required this.level3,
  });

  factory AppShadows.standard(ColorScheme colorScheme) {
    return const AppShadows(
      level1: <BoxShadow>[],
      level2: <BoxShadow>[],
      level3: <BoxShadow>[],
    );
  }

  final List<BoxShadow> level1;
  final List<BoxShadow> level2;
  final List<BoxShadow> level3;

  @override
  AppShadows copyWith({
    List<BoxShadow>? level1,
    List<BoxShadow>? level2,
    List<BoxShadow>? level3,
  }) {
    return AppShadows(
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      level1: BoxShadow.lerpList(level1, other.level1, t) ?? level1,
      level2: BoxShadow.lerpList(level2, other.level2, t) ?? level2,
      level3: BoxShadow.lerpList(level3, other.level3, t) ?? level3,
    );
  }
}

class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.fast,
    required this.normal,
    required this.slow,
  });

  AppMotion.standard()
    : fast = VisualSpec.motion.durationFast,
      normal = VisualSpec.motion.durationNormal,
      slow = VisualSpec.motion.durationSlow;

  final Duration fast;
  final Duration normal;
  final Duration slow;

  @override
  AppMotion copyWith({Duration? fast, Duration? normal, Duration? slow}) {
    return AppMotion(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    return AppMotion(
      fast: lerpDuration(fast, other.fast, t),
      normal: lerpDuration(normal, other.normal, t),
      slow: lerpDuration(slow, other.slow, t),
    );
  }
}

class AppSurfaceRoles extends ThemeExtension<AppSurfaceRoles> {
  const AppSurfaceRoles({
    required this.appBackground,
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceOverlay,
  });

  final Color appBackground;
  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceOverlay;

  @override
  AppSurfaceRoles copyWith({
    Color? appBackground,
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceOverlay,
  }) {
    return AppSurfaceRoles(
      appBackground: appBackground ?? this.appBackground,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
    );
  }

  @override
  AppSurfaceRoles lerp(ThemeExtension<AppSurfaceRoles>? other, double t) {
    if (other is! AppSurfaceRoles) return this;
    return AppSurfaceRoles(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
        .round(),
  );
}
