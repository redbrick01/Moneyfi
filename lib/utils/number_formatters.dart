const double moneyfyQuantityTolerance = 0.000000000001;

bool isEffectivelyZeroQuantity(double value) {
  return value.abs() <= moneyfyQuantityTolerance;
}

bool exceedsAvailableQuantity({
  required double requested,
  required double available,
}) {
  return requested > available + moneyfyQuantityTolerance;
}

String formatPlainQuantity(num value, {int fractionDigits = 12}) {
  final doubleValue = value.toDouble();
  if (!doubleValue.isFinite) return value.toString();
  if (isEffectivelyZeroQuantity(doubleValue)) return '0';

  final fixed = doubleValue.toStringAsFixed(fractionDigits);
  return _trimTrailingFractionZeros(fixed);
}

String _trimTrailingFractionZeros(String value) {
  if (!value.contains('.')) return value;
  var result = value;
  while (result.endsWith('0')) {
    result = result.substring(0, result.length - 1);
  }
  if (result.endsWith('.')) {
    result = result.substring(0, result.length - 1);
  }
  return result == '-0' ? '0' : result;
}
