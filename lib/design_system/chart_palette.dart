import 'package:flutter/material.dart';

import 'spec.dart';

class MoneyfyChartPalette {
  static final Map<String, Color> assetColors = Map.unmodifiable(
    VisualSpec.chart.assetTypeColors,
  );
  static final List<Color> palette = List.unmodifiable(
    VisualSpec.chart.assetIdentityPalette,
  );

  static final Map<String, Color> _assetKeyColorCache = <String, Color>{};

  static Color colorForAsset(
    String assetTitle, {
    String? assetType,
    int? assetId,
    Color? fallback,
  }) {
    final normalizedType = (assetType ?? '').trim();
    final normalizedTitle = assetTitle.trim();
    if (normalizedType.isEmpty && normalizedTitle.isEmpty) {
      return fallback ?? VisualSpec.brand.lightTextSecondary;
    }

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
