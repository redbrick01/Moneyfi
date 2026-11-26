import 'package:intl/intl.dart';

String formatCurrency(
  num value, {
  String? currencyCode,
  bool compact = false,
  int fractionDigits = 0,
}) {
  final abs = value.abs().toDouble();
  final formatted = compact
      ? _formatCompact(abs, fractionDigits: fractionDigits)
      : _grouped(abs, fractionDigits);

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
  final abs = _grouped(value.abs(), fractionDigits);
  return '$sign$abs';
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

String _grouped(num value, int fractionDigits) {
  final format = NumberFormat.decimalPattern('en_US')
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;
  return format.format(value);
}
