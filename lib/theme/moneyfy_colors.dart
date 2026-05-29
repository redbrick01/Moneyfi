import 'package:flutter/material.dart';

import '../design_system/spec.dart';

class MoneyfyPalette {
  // Core
  static const Color primary = Color(0xFF0052FF);
  static const Color primarySoft = Color(0xFFEEF0F3);
  static const Color primaryActive = Color(0xFF003ECC);
  static const Color primaryDisabled = Color(0xFFA8B8CC);
  static const Color link = Color(0xFF0052FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF05B169);
  static const Color successStrong = Color(0xFF05B169);
  static const Color successBg = Color(0xFFEEF0F3);
  static const Color warning = Color(0xFFF4B000);
  static const Color warningStrong = Color(0xFFF4B000);
  static const Color error = Color(0xFFCF202F);
  static const Color errorStrong = Color(0xFFCF202F);
  static const Color errorSoft = Color(0xFFCF202F);
  static const Color errorBg = Color(0xFFEEF0F3);
  static const Color info = Color(0xFF0052FF);
  static const Color infoBg = Color(0xFFEEF0F3);
  static const Color accentPurple = Color(0xFF0052FF);
  static const Color accentPurpleBg = Color(0xFFEEF0F3);

  // Text
  static const Color textPrimary = Color(0xFF0A0B0D);
  static const Color textSecondary = Color(0xFF5B616E);
  static const Color textTertiary = Color(0xFF7C828A);
  static const Color textMuted = Color(0xFF7C828A);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF0A0B0D);

  // Surface / Border
  static const Color bgApp = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSurfaceMuted = Color(0xFFF7F7F7);
  static const Color bgNeutralSoft = Color(0xFFEEF0F3);
  static const Color border = Color(0xFFDEE1E6);
  static const Color borderNeutral = Color(0xFFEEF0F3);
  static const Color borderSuccess = Color(0xFFEEF0F3);
  static const Color borderError = Color(0xFFEEF0F3);
  static const Color borderInfo = Color(0xFFEEF0F3);
  static const Color borderPurple = Color(0xFFEEF0F3);

  // Overlay / Shadow / Glass
  static const Color transparent = Color(0x00000000);
  static const Color black28 = Color(0x470A0B0D);
  static const Color shadowMenu = Color(0x00000000);
  static const Color shadowCard = Color(0x00000000);
  static const Color shadowFloating = Color(0x00000000);
  static const Color glowFloating = Color(0x33FFFFFF);
  static const Color glassTop = Color(0xCCFFFFFF);
  static const Color glassBottom = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x80FFFFFF);
  static const Color glassHighlight = Color(0xCCFFFFFF);
  static const Color glassSelected = Color(0x33FFFFFF);

  // Brand / Asset
  static const Color brandManifest = Color(0xFF0052FF);
  static const Color iconInk = Color(0xFF0A0B0D);
  static const Color iconPositive = Color(0xFF05B169);
  static const Color iconBgLight = Color(0xFFFFFFFF);
  static const Color iconGray = Color(0xFFEEF0F3);

  // Backward-compatible aliases
  static const Color ink = textPrimary;
  static const Color secondaryText = textSecondary;
  static const Color tertiaryText = textTertiary;
  static const Color background = bgApp;
  static const Color surface = bgSurface;
  static const Color surfaceMuted = bgSurfaceMuted;
  static const Color accent = primary;
  static const Color accentSoft = primarySoft;
  static const Color positive = success;
  static const Color negative = error;
  static const Color white = onPrimary;
  static const Color menuShadow = shadowMenu;
  static const Color cardShadow = shadowCard;
  static const Color floatingBarGlow = glowFloating;
  static const Color floatingBarShadow = shadowFloating;
  static const Color floatingBarTop = glassTop;
  static const Color floatingBarBottom = glassBottom;
  static const Color floatingBarBorder = glassBorder;
  static const Color floatingBarHighlight = glassHighlight;
  static const Color floatingBarSelectedBackground = glassSelected;
}

class MoneyfyChartPalette {
  static final Map<String, Color> assetColors =
      VisualSpec.brand.assetTypeChartColors;
  static final List<Color> palette = <Color>[
    VisualSpec.brand.chart01,
    VisualSpec.brand.chart02,
    VisualSpec.brand.chart03,
    VisualSpec.brand.chart04,
    VisualSpec.brand.chart05,
    VisualSpec.brand.chart06,
    VisualSpec.brand.chart07,
    VisualSpec.brand.chart08,
  ];

  static final Map<String, Color> _assetKeyColorCache = <String, Color>{};

  static Color colorForAsset(
    String assetTitle, {
    String? assetType,
    int? assetId,
    Color fallback = MoneyfyPalette.secondaryText,
  }) {
    final normalizedType = (assetType ?? '').trim();
    final normalizedTitle = assetTitle.trim();
    if (normalizedType.isEmpty && normalizedTitle.isEmpty) return fallback;

    // Aggregated/group labels should keep semantic type colors.
    if (normalizedTitle.isEmpty) {
      final grouped = _resolveTypeColor(normalizedType);
      if (grouped != null) return grouped;
    }
    if (_isGroupedLabel(normalizedTitle)) {
      final grouped = _resolveTypeColor(normalizedTitle);
      if (grouped != null) return grouped;
    }

    final keyParts = <String>[
      if (assetId != null) 'id:${assetId.abs()}',
      if (normalizedType.isNotEmpty) 'type:${normalizedType.toLowerCase()}',
      if (normalizedTitle.isNotEmpty) 'title:${normalizedTitle.toLowerCase()}',
    ];
    final key = keyParts.join('|');

    return _assetKeyColorCache.putIfAbsent(key, () => _colorFromSeed(key));
  }

  static Color _colorFromSeed(String key) {
    final seed = key.codeUnits.fold<int>(
      0,
      (sum, unit) => (sum * 31 + unit) & 0x7fffffff,
    );
    return palette[seed % palette.length];
  }

  static bool _isGroupedLabel(String label) {
    return label == '주식' || label == '현금' || label == '펀드' || label == '코인';
  }

  static Color? _resolveTypeColor(String value) {
    if (assetColors.containsKey(value)) return assetColors[value]!;
    if (value.contains('주식')) return assetColors['주식'];
    if (value.contains('현금')) return assetColors['현금'];
    if (value.contains('펀드')) return assetColors['펀드'];
    if (value.contains('코인')) return assetColors['코인'];
    return null;
  }
}
