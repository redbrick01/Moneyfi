import 'package:flutter/foundation.dart';

/// App-wide numeric formatting helpers.
///
/// TODO: If intl is adopted later, replace internal grouping logic with
/// locale-aware NumberFormat.
String formatCurrency(
  num value, {
  String? currencyCode,
  bool compact = false,
  int fractionDigits = 0,
}) {
  final abs = value.abs().toDouble();
  final formatted = compact
      ? _formatCompact(abs, fractionDigits: fractionDigits)
      : _withGrouping(abs.toStringAsFixed(fractionDigits));

  if (currencyCode == null || currencyCode.isEmpty) {
    return formatted;
  }
  return '$currencyCode $formatted';
}

String formatPercent(num value, {int fractionDigits = 1}) {
  return '${value.toStringAsFixed(fractionDigits)}%';
}

String formatSigned(num value, {int fractionDigits = 0}) {
  final sign = value > 0
      ? '+'
      : value < 0
      ? '-'
      : '';
  final abs = value.abs().toStringAsFixed(fractionDigits);
  return '$sign${_withGrouping(abs)}';
}

String formatSignedPercent(num value, {int fractionDigits = 1}) {
  final sign = value > 0
      ? '+'
      : value < 0
      ? '-'
      : '';
  return '$sign${value.abs().toStringAsFixed(fractionDigits)}%';
}

String _formatCompact(double value, {int fractionDigits = 1}) {
  const thousand = 1000.0;
  const million = 1000000.0;
  const billion = 1000000000.0;

  if (value >= billion) {
    return '${(value / billion).toStringAsFixed(fractionDigits)}B';
  }
  if (value >= million) {
    return '${(value / million).toStringAsFixed(fractionDigits)}M';
  }
  if (value >= thousand) {
    return '${(value / thousand).toStringAsFixed(fractionDigits)}K';
  }
  return value.toStringAsFixed(0);
}

String _withGrouping(String raw) {
  final parts = raw.split('.');
  final integer = parts.first;
  final buffer = StringBuffer();

  for (var i = 0; i < integer.length; i++) {
    final positionFromEnd = integer.length - i;
    buffer.write(integer[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  if (parts.length == 1) return buffer.toString();
  return '${buffer.toString()}.${parts[1]}';
}

@visibleForTesting
Map<String, String> numberFormatterExamples() {
  return {
    'currency': formatCurrency(1234567, currencyCode: 'KRW'),
    'percent': formatPercent(12.345),
    'signed': formatSigned(-1234),
    'signedPercent': formatSignedPercent(3.21),
  };
}
