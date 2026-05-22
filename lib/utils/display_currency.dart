enum MoneyfyDisplayCurrency {
  krw,
  usd,
}

class MoneyfyDisplayCurrencySettings {
  static MoneyfyDisplayCurrency current = MoneyfyDisplayCurrency.krw;
  static double usdKrwRate = 1300;

  static void update({
    MoneyfyDisplayCurrency? currency,
    double? rate,
  }) {
    current = MoneyfyDisplayCurrency.krw;
    if (rate != null && rate > 0) {
      usdKrwRate = rate;
    }
  }

  static String get code => 'KRW';

  static double convertFromKrw(double amountKrw) => amountKrw;

  static String formatAmountFromKrw(double amountKrw) {
    return _formatAmount(amountKrw, currency: MoneyfyDisplayCurrency.krw);
  }

  static String formatSignedAmountFromKrw(double amountKrw) {
    final prefix = amountKrw > 0 ? '+' : amountKrw < 0 ? '-' : '';
    return '$prefix${_formatAmount(amountKrw.abs(), currency: MoneyfyDisplayCurrency.krw)}';
  }

  static String formatAmountFromSource(
    double amount, {
    required String sourceCurrency,
    required double exchangeRate,
  }) {
    final normalizedSource = sourceCurrency.toUpperCase();
    if (normalizedSource == 'USD') {
      return _formatAmount(amount, currency: MoneyfyDisplayCurrency.usd);
    }
    return _formatAmount(amount, currency: MoneyfyDisplayCurrency.krw);
  }

  static String _formatAmount(
    double amount, {
    required MoneyfyDisplayCurrency currency,
  }) {
    final isNegative = amount < 0;
    final absolute = amount.abs();
    final formatted = currency == MoneyfyDisplayCurrency.krw
        ? _formatKrwNumber(absolute)
        : _formatUsdNumber(absolute);
    return isNegative ? '-$formatted' : formatted;
  }

  static String _formatKrwNumber(double amount) {
    final rounded = amount.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final reverseIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '₩$buffer';
  }

  static String _formatUsdNumber(double amount) {
    final value = amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    final parts = value.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final reverseIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    if (parts.length == 1 || parts[1] == '00') {
      return '\$$buffer';
    }
    return '\$$buffer.${parts[1]}';
  }
}
