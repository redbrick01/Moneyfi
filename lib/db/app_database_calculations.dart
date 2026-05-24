part of 'app_database.dart';

bool _shouldSyncHoldingTransactionWithCash(String type) {
  final normalized = _normalizeTransactionType(type);
  return normalized == '매수' || normalized == '매도';
}

String _normalizeTransactionType(String type) {
  final normalized = type.trim();
  switch (normalized.toLowerCase()) {
    case 'buy':
      return '매수';
    case 'sell':
      return '매도';
    case 'deposit':
      return '입금';
    case 'withdraw':
    case 'withdrawal':
      return '출금';
    case 'transfer':
      return '이체';
    case 'exchange':
      return '환전';
    case 'dividend':
      return '배당';
    case 'interest':
      return '이자';
    case 'initial':
      return '초기';
    default:
      return normalized;
  }
}

double _tradeSettlementAmount({
  required String amount,
  required String quantity,
}) {
  final parsedAmount = _parseTransactionNumber(amount).abs();
  final parsedQuantity = _parseTransactionNumber(quantity).abs();
  if (parsedQuantity <= 0) return parsedAmount;
  return parsedAmount * parsedQuantity;
}

_NormalizedTransactionValues _normalizedTransactionValues({
  required String type,
  required String amount,
  required String quantity,
  double averageCostBasis = 0,
}) {
  final normalizedType = _normalizeTransactionType(type);
  final unitPrice = _parseTransactionNumber(amount).abs();
  final quantityValue = _parseTransactionNumber(quantity).abs();
  final grossAmount = switch (normalizedType) {
    '매수' || '매도' => unitPrice * quantityValue,
    '배당' || '이자' => unitPrice,
    '초기' => unitPrice * quantityValue,
    _ => unitPrice,
  };
  final cashFlowAmount = switch (normalizedType) {
    '매수' => -grossAmount,
    '매도' || '배당' || '이자' => grossAmount,
    _ => 0.0,
  };
  final realizedProfitAmount = normalizedType == '매도'
      ? (unitPrice - averageCostBasis) * quantityValue
      : 0.0;

  return _NormalizedTransactionValues(
    unitPrice: unitPrice,
    quantityValue: quantityValue,
    grossAmount: grossAmount,
    cashFlowAmount: cashFlowAmount,
    realizedProfitAmount: realizedProfitAmount,
  );
}

_NormalizedTransactionValues _normalizedCashTransactionValues({
  required String type,
  required String amount,
}) {
  final amountValue = _parseTransactionNumber(amount).abs();
  final cashFlowAmount = _cashTransactionBalanceDelta(
    type: type,
    amount: amount,
  );
  return _NormalizedTransactionValues(
    unitPrice: amountValue,
    quantityValue: 0,
    grossAmount: amountValue,
    cashFlowAmount: cashFlowAmount,
    realizedProfitAmount: 0,
  );
}

double _cashTransactionBalanceDelta({
  required String type,
  required String amount,
}) {
  final normalizedType = _normalizeTransactionType(type);
  final parsedAmount = _parseTransactionNumber(amount);
  final absoluteAmount = parsedAmount.abs();
  switch (normalizedType) {
    case '입금':
    case '매도':
      return absoluteAmount;
    case '출금':
    case '매수':
      return -absoluteAmount;
    case '환전':
    case '이체':
      return parsedAmount;
    default:
      return parsedAmount;
  }
}

String _storedCashTransactionAmount({
  required String type,
  required String amount,
}) {
  final normalizedType = _normalizeTransactionType(type);
  final parsedAmount = _parseTransactionNumber(amount);
  final absoluteAmount = parsedAmount.abs();
  switch (normalizedType) {
    case '입금':
    case '출금':
    case '매수':
    case '매도':
      return _formatPlainNumber(absoluteAmount);
    case '환전':
    case '이체':
      return _formatPlainNumber(-absoluteAmount);
    default:
      return amount.trim();
  }
}

double _cashOutgoingAmount({required String type, required String amount}) {
  final normalizedType = _normalizeTransactionType(type);
  final parsedAmount = _parseTransactionNumber(amount);
  final absoluteAmount = parsedAmount.abs();
  switch (normalizedType) {
    case '출금':
    case '매수':
      return absoluteAmount;
    case '환전':
    case '이체':
      return parsedAmount < 0 ? absoluteAmount : 0;
    default:
      return 0;
  }
}

int _compareTransactions(Transaction a, Transaction b) {
  final dateCompare = _transactionSortKey(
    a.date,
  ).compareTo(_transactionSortKey(b.date));
  if (dateCompare != 0) return dateCompare;
  final orderCompare = a.sortOrder.compareTo(b.sortOrder);
  if (orderCompare != 0) return orderCompare;
  return a.id.compareTo(b.id);
}

String _transactionSortKey(String value) {
  final digits = RegExp(
    r'\d+',
  ).allMatches(value).map((match) => match.group(0)!).toList();
  if (digits.length >= 3) {
    final year = digits[0].padLeft(4, '0');
    final month = digits[1].padLeft(2, '0');
    final day = digits[2].padLeft(2, '0');
    return '$year$month$day';
  }
  return value;
}

double _parseTransactionNumber(String value) {
  final normalized = value
      .replaceAll(',', '')
      .replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(normalized) ?? 0.0;
}

String _ledgerInvestmentActionLabel(String action) {
  return switch (action) {
    'opening_quantity' => '초기',
    'buy' => '매수',
    'sell' => '매도',
    'dividend' => '배당',
    'interest' => '이자',
    'fee' => '수수료',
    'tax' => '세금',
    _ => '조정',
  };
}

double _ledgerInvestmentDisplayAmount({
  required String action,
  required double unitPrice,
  required double grossAmount,
}) {
  return switch (action) {
    'buy' || 'sell' || 'opening_quantity' => unitPrice,
    _ => grossAmount,
  };
}

String _ledgerCashActionLabel({
  required String action,
  required double cashDelta,
}) {
  return switch (action) {
    'opening_cash' || 'deposit' => '입금',
    'withdrawal' => '출금',
    'transfer_out' || 'transfer_in' => '이체',
    'fx_out' || 'fx_in' => '환전',
    'settlement' => cashDelta < 0 ? '매수' : '매도',
    'dividend' => '배당',
    'interest' => '이자',
    'fee' => '수수료',
    'tax' => '세금',
    _ => '조정',
  };
}

String _formatPlainNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(3);
}

String _formatPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}%';
}

IconData _materialIconFromCodePoint(int codePoint) {
  if (codePoint == Icons.show_chart_rounded.codePoint) {
    return Icons.show_chart_rounded;
  }
  if (codePoint == Icons.pie_chart_rounded.codePoint) {
    return Icons.pie_chart_rounded;
  }
  if (codePoint == Icons.currency_bitcoin_rounded.codePoint) {
    return Icons.currency_bitcoin_rounded;
  }
  if (codePoint == Icons.account_balance_wallet_rounded.codePoint) {
    return Icons.account_balance_wallet_rounded;
  }
  if (codePoint == Icons.widgets_outlined.codePoint) {
    return Icons.widgets_outlined;
  }
  return Icons.widgets_outlined;
}

String _normalizeStoredDateKey(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final digits = RegExp(
    r'\d+',
  ).allMatches(trimmed).map((match) => match.group(0)!).toList();
  if (digits.length < 3) {
    final firstToken = trimmed.split(' ').first;
    return firstToken.replaceAll('.', '-').replaceAll('/', '-');
  }

  late final String year;
  late final String month;
  late final String day;

  if (digits[0].length == 4) {
    year = digits[0];
    month = digits[1].padLeft(2, '0');
    day = digits[2].padLeft(2, '0');
  } else if (digits[2].length == 4) {
    year = digits[2];
    month = digits[0].padLeft(2, '0');
    day = digits[1].padLeft(2, '0');
  } else {
    year = digits[0].padLeft(4, '0');
    month = digits[1].padLeft(2, '0');
    day = digits[2].padLeft(2, '0');
  }

  return '$year-$month-$day';
}
