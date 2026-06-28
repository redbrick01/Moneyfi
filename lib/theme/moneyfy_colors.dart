import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/spec.dart';

class MoneyfyPalette {
  // Brand
  static const Color primary = Color(0xFF3A6DFF);
  static const Color primaryActive = Color(0xFF2DA4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF00D47E);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4554);
  static const Color info = primary;

  // Text
  static const Color textPrimary = Color(0xFF0A0B0D);
  static const Color textSecondary = Color(0xFF5B616E);
  static const Color textTertiary = Color(0xFF7C828A);

  // Surface / Border
  static const Color bgApp = onPrimary;
  static const Color bgSurface = onPrimary;
  static const Color bgSurfaceMuted = Color(0xFFF7F7F7);
  static const Color softNeutral = Color(0xFFEEF0F3);
  static const Color border = Color(0xFFDEE1E6);

  // Overlay
  static const Color transparent = Color(0x00000000);

  // Backward-compatible aliases
  static const Color ink = textPrimary;
  static const Color secondaryText = textSecondary;
  static const Color tertiaryText = textTertiary;
  static const Color background = bgApp;
  static const Color surface = bgSurface;
  static const Color surfaceMuted = bgSurfaceMuted;
  static const Color accent = primary;
  static const Color positive = success;
  static const Color negative = error;
  static const Color white = onPrimary;
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
