part of 'app_database.dart';

class SnapshotCashAccountRecord {
  const SnapshotCashAccountRecord({
    required this.id,
    required this.snapshotId,
    required this.assetId,
    required this.assetTitle,
    required this.cashAccountId,
    required this.cashAccountName,
    required this.currencyCode,
    required this.balance,
    required this.note,
  });

  final int id;
  final int snapshotId;
  final int? assetId;
  final String assetTitle;
  final int? cashAccountId;
  final String cashAccountName;
  final String currencyCode;
  final double balance;
  final String note;
}

class _ExternalCashFlowRow {
  const _ExternalCashFlowRow({
    required this.returnDate,
    required this.currencyCode,
    required this.fxRate,
    required this.cashDelta,
  });

  final String returnDate;
  final String currencyCode;
  final double? fxRate;
  final double cashDelta;
}

class BenchmarkComparisonResult {
  const BenchmarkComparisonResult({
    required this.benchmarkCode,
    required this.commonObservationCount,
    required this.portfolioCumulativeReturn,
    required this.benchmarkCumulativeReturn,
    required this.excessReturn,
  });

  final String benchmarkCode;
  final int commonObservationCount;
  final double portfolioCumulativeReturn;
  final double benchmarkCumulativeReturn;
  final double excessReturn;
}

class BenchmarkPeriodComparisonResult {
  const BenchmarkPeriodComparisonResult({
    required this.benchmarkCode,
    required this.portfolioCumulativeReturn,
    required this.benchmarkPeriodReturn,
    required this.excessReturn,
    required this.benchmarkStartDate,
    required this.benchmarkEndDate,
    required this.benchmarkStartValue,
    required this.benchmarkEndValue,
  });

  final String benchmarkCode;
  final double portfolioCumulativeReturn;
  final double benchmarkPeriodReturn;
  final double excessReturn;
  final String benchmarkStartDate;
  final String benchmarkEndDate;
  final double benchmarkStartValue;
  final double benchmarkEndValue;
}

class _BenchmarkBoundary {
  const _BenchmarkBoundary({required this.start, required this.end});

  final BenchmarkPrice start;
  final BenchmarkPrice end;
}

class SyncSafetySnapshot {
  const SyncSafetySnapshot({
    required this.assetRowCount,
    required this.holdingRowCount,
    required this.holdingQuantitySum,
    required this.holdingValuationSum,
    required this.holdingPurchaseAmountSum,
    required this.zeroQuantityCount,
    required this.zeroAveragePriceCount,
    required this.zeroValuationCount,
    required this.nullOrZeroSourceAverageCount,
    required this.nullOrZeroAverageFxCount,
  });

  final int assetRowCount;
  final int holdingRowCount;
  final double holdingQuantitySum;
  final double holdingValuationSum;
  final double holdingPurchaseAmountSum;
  final int zeroQuantityCount;
  final int zeroAveragePriceCount;
  final int zeroValuationCount;
  final int nullOrZeroSourceAverageCount;
  final int nullOrZeroAverageFxCount;

  Map<String, Object> toJson() => {
    'asset_row_count': assetRowCount,
    'holding_row_count': holdingRowCount,
    'holding_quantity_sum': holdingQuantitySum,
    'holding_valuation_sum': holdingValuationSum,
    'holding_purchase_amount_sum': holdingPurchaseAmountSum,
    'zero_quantity_count': zeroQuantityCount,
    'zero_average_price_count': zeroAveragePriceCount,
    'zero_valuation_count': zeroValuationCount,
    'null_or_zero_source_average_count': nullOrZeroSourceAverageCount,
    'null_or_zero_average_fx_count': nullOrZeroAverageFxCount,
  };
}

class SyncSafetyIssue {
  const SyncSafetyIssue({
    required this.metric,
    required this.beforeValue,
    required this.afterValue,
  });

  final String metric;
  final Object beforeValue;
  final Object afterValue;
}

class SnapshotTransactionRecord {
  const SnapshotTransactionRecord({
    required this.id,
    required this.snapshotId,
    required this.assetId,
    required this.assetTitle,
    required this.holdingId,
    required this.holdingName,
    required this.transactionId,
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
    required this.quantity,
    required this.sortOrder,
  });

  final int id;
  final int snapshotId;
  final int? assetId;
  final String assetTitle;
  final int? holdingId;
  final String holdingName;
  final int? transactionId;
  final String date;
  final String type;
  final String name;
  final String amount;
  final String quantity;
  final int sortOrder;
}

class SnapshotCashTransactionRecord {
  const SnapshotCashTransactionRecord({
    required this.id,
    required this.snapshotId,
    required this.assetId,
    required this.assetTitle,
    required this.cashAccountId,
    required this.cashAccountName,
    required this.currencyCode,
    required this.transactionId,
    required this.linkedTransactionId,
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
    required this.sortOrder,
  });

  final int id;
  final int snapshotId;
  final int? assetId;
  final String assetTitle;
  final int? cashAccountId;
  final String cashAccountName;
  final String currencyCode;
  final int? transactionId;
  final int? linkedTransactionId;
  final String date;
  final String type;
  final String name;
  final String amount;
  final int sortOrder;
}

class _NormalizedTransactionValues {
  const _NormalizedTransactionValues({
    required this.unitPrice,
    required this.quantityValue,
    required this.grossAmount,
    required this.cashFlowAmount,
    required this.realizedProfitAmount,
    required this.realizedProfitSource,
  });

  final double unitPrice;
  final double quantityValue;
  final double grossAmount;
  final double cashFlowAmount;
  final double realizedProfitAmount;
  final String realizedProfitSource;
}

class LedgerHoldingPerformanceRecord {
  const LedgerHoldingPerformanceRecord({
    required this.holdingId,
    required this.quantity,
    required this.remainingCost,
    required this.realizedPnl,
    required this.incomeAmount,
    required this.buyAmount,
    required this.sellAmount,
  });

  final int holdingId;
  final double quantity;
  final double remainingCost;
  final double realizedPnl;
  final double incomeAmount;
  final double buyAmount;
  final double sellAmount;
}

class LedgerPortfolioPerformanceRecord {
  const LedgerPortfolioPerformanceRecord({
    this.currencyCode,
    required this.realizedPnl,
    required this.incomeAmount,
    required this.feeAmount,
    required this.taxAmount,
    required this.externalCashFlowAmount,
    this.externalDepositAmount = 0,
    this.externalWithdrawalAmount = 0,
    required this.tradeSettlementCashFlowAmount,
    required this.internalCashMovementAmount,
    required this.buyAmount,
    required this.sellAmount,
  });

  final String? currencyCode;
  final double realizedPnl;
  final double incomeAmount;
  final double feeAmount;
  final double taxAmount;
  final double externalCashFlowAmount;
  final double externalDepositAmount;
  final double externalWithdrawalAmount;
  final double tradeSettlementCashFlowAmount;
  final double internalCashMovementAmount;
  final double buyAmount;
  final double sellAmount;

  double get pureRealizedPerformance =>
      realizedPnl + incomeAmount - feeAmount - taxAmount;
}

class LedgerMonthlyPerformanceRecord {
  const LedgerMonthlyPerformanceRecord({
    required this.month,
    required this.currencyCode,
    required this.realizedPnl,
    required this.incomeAmount,
    required this.feeAmount,
    required this.taxAmount,
    required this.buyAmount,
    required this.sellAmount,
  });

  final String month;
  final String currencyCode;
  final double realizedPnl;
  final double incomeAmount;
  final double feeAmount;
  final double taxAmount;
  final double buyAmount;
  final double sellAmount;

  double get pureRealizedPerformance =>
      realizedPnl + incomeAmount - feeAmount - taxAmount;
}

class LedgerStateParityIssue {
  const LedgerStateParityIssue({
    required this.kind,
    required this.id,
    required this.expectedValue,
    required this.ledgerValue,
  });

  final String kind;
  final int id;
  final double expectedValue;
  final double ledgerValue;

  double get difference => ledgerValue - expectedValue;
}

class LedgerIncomeTransactionRecord {
  const LedgerIncomeTransactionRecord({
    required this.date,
    required this.action,
    required this.assetName,
    required this.holdingName,
    required this.symbol,
    required this.currencyCode,
    required this.amount,
  });

  final String date;
  final String action;
  final String assetName;
  final String holdingName;
  final String symbol;
  final String currencyCode;
  final double amount;
}

class LedgerPerformanceEventRecord {
  const LedgerPerformanceEventRecord({
    required this.eventId,
    required this.lineId,
    required this.date,
    required this.kind,
    required this.action,
    required this.title,
    required this.assetName,
    required this.holdingName,
    required this.cashAccountName,
    required this.currencyCode,
    required this.amount,
  });

  final int eventId;
  final int lineId;
  final String date;
  final String kind;
  final String action;
  final String title;
  final String assetName;
  final String holdingName;
  final String cashAccountName;
  final String currencyCode;
  final double amount;
}

String? _ledgerDateText(DateTime? date) {
  if (date == null) return null;
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _ledgerDateWhereClause({
  String eventAlias = 'te',
  DateTime? from,
  DateTime? to,
}) {
  final conditions = <String>[];
  if (from != null) {
    conditions.add(
      "SUBSTR(REPLACE($eventAlias.occurred_at, '.', '-'), 1, 10) >= ?",
    );
  }
  if (to != null) {
    conditions.add(
      "SUBSTR(REPLACE($eventAlias.occurred_at, '.', '-'), 1, 10) <= ?",
    );
  }
  if (conditions.isEmpty) return '';
  return ' AND ${conditions.join(' AND ')}';
}

List<Variable<String>> _ledgerDateVariables({DateTime? from, DateTime? to}) {
  return [
    if (_ledgerDateText(from) case final fromText?)
      Variable.withString(fromText),
    if (_ledgerDateText(to) case final toText?) Variable.withString(toText),
  ];
}
