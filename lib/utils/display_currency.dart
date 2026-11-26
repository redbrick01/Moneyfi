import 'package:moneyfy/components/formatters/number_format.dart';

enum MoneyfyDisplayCurrency { krw, usd }

class MoneyfyDisplayCurrencySettings {
  static MoneyfyDisplayCurrency current = MoneyfyDisplayCurrency.krw;
  static double usdKrwRate = 1300;

  static void update({MoneyfyDisplayCurrency? currency, double? rate}) {
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
    final prefix = amountKrw > 0
        ? '+'
        : amountKrw < 0
        ? '-'
        : '';
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
    final isDollar = currency == MoneyfyDisplayCurrency.usd;
    final symbol = isDollar ? r'$' : '₩';
    final cents = isDollar && !absolute.toStringAsFixed(2).endsWith('.00');
    final formatted = formatCurrency(absolute, fractionDigits: cents ? 2 : 0);
    return "${isNegative ? '-' : ''}$symbol$formatted";
  }
}
