import 'package:flutter/material.dart';

class VisualSpec {
  const VisualSpec._();

  static const brand = _BrandSpec();
  static const surface = _SurfaceSpec();
  static const chart = _ChartSpec();
  static const icon = _IconSpec();
  static const motion = _MotionSpec();
}

class _BrandSpec {
  const _BrandSpec();

  // Seed
  final Color seedColor = const Color(0xFF0052FF);
  Color get seed => seedColor;

  // Light neutrals
  final Color lightBg = const Color(0xFFFFFFFF);
  final Color lightSurface = const Color(0xFFFFFFFF);
  final Color lightSurfaceLow = const Color(0xFFFFFFFF);
  final Color lightSurfaceContainer = const Color(0xFFF7F7F7);
  final Color lightSurfaceHigh = const Color(0xFFEEF0F3);
  final Color lightSurfaceHighest = const Color(0xFFEEF0F3);
  final Color lightTextPrimary = const Color(0xFF0A0B0D);
  final Color lightTextSecondary = const Color(0xFF5B616E);
  final Color lightOutlineVariant = const Color(0xFFDEE1E6);

  // Dark neutrals
  final Color darkBg = const Color(0xFF0A0B0D);
  final Color darkSurface = const Color(0xFF0A0B0D);
  final Color darkSurfaceLow = const Color(0xFF16181C);
  final Color darkSurfaceContainer = const Color(0xFF16181C);
  final Color darkSurfaceHigh = const Color(0xFF16181C);
  final Color darkSurfaceHighest = const Color(0xFF16181C);
  final Color darkTextPrimary = const Color(0xFFFFFFFF);
  final Color darkTextSecondary = const Color(0xFFA8ACB3);
  final Color darkOutlineVariant = const Color(0xFF16181C);

  // Status - Positive
  final Color lightPositive = const Color(0xFF05B169);
  final Color lightPositiveContainer = const Color(0xFFEEF0F3);
  final Color lightOnPositiveContainer = const Color(0xFF05B169);
  final Color darkPositive = const Color(0xFF05B169);
  final Color darkPositiveContainer = const Color(0xFF16181C);
  final Color darkOnPositiveContainer = const Color(0xFF05B169);

  // Status - Negative
  final Color lightNegative = const Color(0xFFCF202F);
  final Color lightNegativeContainer = const Color(0xFFEEF0F3);
  final Color lightOnNegativeContainer = const Color(0xFFCF202F);
  final Color darkNegative = const Color(0xFFCF202F);
  final Color darkNegativeContainer = const Color(0xFF16181C);
  final Color darkOnNegativeContainer = const Color(0xFFCF202F);

  // Status - Warning
  final Color lightWarning = const Color(0xFFF4B000);
  final Color lightWarningContainer = const Color(0xFFEEF0F3);
  final Color lightOnWarningContainer = const Color(0xFFF4B000);
  final Color darkWarning = const Color(0xFFF4B000);
  final Color darkWarningContainer = const Color(0xFF16181C);
  final Color darkOnWarningContainer = const Color(0xFFF4B000);

  // Interaction overlay alpha
  final double lightOverlayPressedAlpha = 0.08;
  final double darkOverlayPressedAlpha = 0.16;

  // Chart palette (8)
  final Color chart01 = const Color(0xFF0052FF);
  final Color chart02 = const Color(0xFF05B169);
  final Color chart03 = const Color(0xFFCF202F);
  final Color chart04 = const Color(0xFF0A0B0D);
  final Color chart05 = const Color(0xFF5B616E);
  final Color chart06 = const Color(0xFFA8ACB3);
  final Color chart07 = const Color(0xFFDEE1E6);
  final Color chart08 = const Color(0xFFEEF0F3);

  List<Color> get chartPalette => <Color>[
    chart01,
    chart02,
    chart03,
    chart04,
    chart05,
    chart06,
    chart07,
    chart08,
  ];

  Map<String, Color> get assetTypeChartColors => <String, Color>{
    '주식': chart01,
    '현금': chart04,
    '펀드': chart02,
    '코인': chart05,
  };

  Color background(Brightness brightness) {
    return brightness == Brightness.dark ? darkBg : lightBg;
  }

  Color positiveContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkPositiveContainer
        : lightPositiveContainer;
  }

  Color onPositiveContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkOnPositiveContainer
        : lightOnPositiveContainer;
  }

  Color negativeContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkNegativeContainer
        : lightNegativeContainer;
  }

  Color onNegativeContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkOnNegativeContainer
        : lightOnNegativeContainer;
  }

  Color warningContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkWarningContainer
        : lightWarningContainer;
  }

  Color onWarningContainer(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkOnWarningContainer
        : lightOnWarningContainer;
  }

  double pressedOverlayAlpha(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkOverlayPressedAlpha
        : lightOverlayPressedAlpha;
  }
}

class _SurfaceSpec {
  const _SurfaceSpec();

  final double radiusCard = 16;
  final double radiusSheet = 24;
  final double borderWidth = 1;
  final double elevationBase = 0;
  final double elevationHero = 1;
  final double shadowBlurMax = 10;
  final double paddingCard = 20;
  final double paddingDense = 12;
  final double sectionGap = 32;
  final double rowHeight = 56;
  final double rowHeightDense = 64;
  final double dividerThickness = 1;
  final double dividerInset = 16;
  final double modalBarrierAlpha = 0.62;
  final Color transparent = const Color(0x00000000);
  double get radiusSheetDialog => radiusSheet;
  double get paddingCardDense => paddingDense;

  Color get lightBg => VisualSpec.brand.lightBg;
  Color get darkBg => VisualSpec.brand.darkBg;

  Color cardBase(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF16181C)
        : const Color(0xFFFFFFFF);
  }

  Color cardRaised(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF16181C)
        : const Color(0xFFF7F7F7);
  }

  Color overlay(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF16181C)
        : const Color(0xFFFFFFFF);
  }
}

class _ChartSpec {
  const _ChartSpec();

  final double chartRadius = 12;
  final double chartPadding = 12;
  final double legendRowHeight = 44;
  final double legendDot = 8;
  final double legendDotRadius = 4;
  final double legendGap = 8;
  final double tooltipRadius = 12;
  final double tooltipPaddingH = 12;
  final double tooltipPaddingV = 10;
  final double tooltipBorder = 1;
  final int animFastMs = 150;
  final Curve animCurve = Curves.easeOut;
  final double donutSize = 132;
  final double donutMin = 120;
  final double donutMax = 140;
  final double donutStroke = 16;
  final double donutStrokeSelected = 18;
  final double donutInnerHoleRatio = 0.62;
  final double donutSliceGap = 2.0;
  final double donutUnselectedAlpha = 0.55;
  final double lineStroke = 2.0;
  final double lineStrokeSelected = 3.0;
  final double pointRadius = 2.6;
  final double pointRadiusSelected = 4.0;
  final double pointStrokeSelected = 2.0;
  final double gridThickness = 1.0;
  final double gridAlphaLight = 0.10;
  final double gridAlphaDark = 0.18;
  final double crosshairThickness = 1.0;
  final double crosshairAlphaLight = 0.18;
  final double crosshairAlphaDark = 0.26;
  final double selectionHeaderHeight = 44;
  final double selectionHeaderPadding = 12;

  List<Color> get palette => VisualSpec.brand.chartPalette;
  Map<String, Color> get assetTypeColors =>
      VisualSpec.brand.assetTypeChartColors;
}

class _IconSpec {
  const _IconSpec();

  final double sizeDefault = 24;
  final double sizeSmall = 20;
  final double sizeLarge = 56;
  final double sizeBadge = 20;
  final double progressSize = 20;
  final double progressSizeLarge = 28;
  final double progressStroke = 2.2;
  final double progressStrokeLarge = 2.4;
  final double minTapTarget = 48;
  final double badgeBox = 36;
  final double badgeRadius = 12;
  final double avatarBox = 40;
  final double chipIcon = 16;
  final double emptyAlphaLight = 0.85;
  final double emptyAlphaDark = 0.90;
  double get iconSize => sizeDefault;
  double get iconSizeSmall => sizeSmall;
  double get iconSizeLarge => sizeLarge;
  double get iconSizeBadge => sizeBadge;
  double get progressIndicatorSize => progressSize;
  double get progressIndicatorSizeLarge => progressSizeLarge;
  double get progressIndicatorStroke => progressStroke;
  double get progressIndicatorStrokeLarge => progressStrokeLarge;
  double get iconButtonMinTap => minTapTarget;
  double get emptyIconAlphaLight => emptyAlphaLight;
  double get emptyIconAlphaDark => emptyAlphaDark;

  final IconData sort = Icons.keyboard_arrow_down_rounded;
  final IconData add = Icons.add_rounded;
  final IconData edit = Icons.edit_outlined;
  final IconData visibilityOn = Icons.visibility_rounded;
  final IconData visibilityOff = Icons.visibility_off_rounded;
  final IconData chevronRight = Icons.chevron_right_rounded;
  final IconData chevronLeft = Icons.chevron_left_rounded;
  final IconData chevronUp = Icons.keyboard_arrow_up_rounded;
  final IconData refresh = Icons.refresh_rounded;
  final IconData sync = Icons.sync_rounded;
  final IconData logout = Icons.logout_rounded;
  final IconData close = Icons.close_rounded;
  final IconData info = Icons.info_outline_rounded;
  final IconData expandMore = Icons.keyboard_arrow_down_rounded;
  final IconData expandLess = Icons.keyboard_arrow_up_rounded;
  final IconData delete = Icons.delete_outline_rounded;
  final IconData more = Icons.more_horiz_rounded;
  final IconData calendar = Icons.calendar_month_rounded;
  final IconData person = Icons.person_outline_rounded;
  final IconData settings = Icons.settings_suggest_rounded;
  final IconData wallet = Icons.account_balance_wallet_outlined;
  final IconData insights = Icons.insights_rounded;
  final IconData lightbulb = Icons.lightbulb_outline_rounded;
  final IconData error = Icons.error_outline_rounded;
  final IconData inbox = Icons.inbox_rounded;
  final IconData check = Icons.check_rounded;
  final IconData checkCircle = Icons.check_circle_rounded;
  final IconData circle = Icons.circle_outlined;
  final IconData dragHandle = Icons.drag_handle_rounded;
  final IconData cloudUpload = Icons.cloud_upload_rounded;
  final IconData pieChart = Icons.pie_chart_outline_rounded;
  final IconData newspaper = Icons.newspaper_rounded;
  final IconData trendingUp = Icons.trending_up_rounded;
  final IconData trendingDown = Icons.trending_down_rounded;
  final IconData accountBalance = Icons.account_balance_rounded;
  final IconData currencyExchange = Icons.currency_exchange_rounded;
  final IconData bitcoin = Icons.currency_bitcoin_rounded;
  final IconData showChart = Icons.show_chart_rounded;
}

class _MotionSpec {
  const _MotionSpec();

  final Duration durationFast = const Duration(milliseconds: 140);
  final Duration durationNormal = const Duration(milliseconds: 200);
  final Duration durationSlow = const Duration(milliseconds: 260);
  final Curve easeOut = Curves.easeOutCubic;
  final Curve easeInOut = Curves.easeInOutCubic;
}
