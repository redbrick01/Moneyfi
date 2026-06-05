import 'dart:convert';

import '../db/app_database.dart';
import '../models/asset_item.dart';

Map<String, Object?> buildGptDbSummaryPayload({
  required List<AssetItem> assets,
  required Map<int, double> targetRatios,
  required Iterable<String> transactionDates,
  required List<DailyPortfolioSnapshot> snapshots,
  DateTime? generatedAt,
}) {
  final now = generatedAt ?? DateTime.now();
  final visibleAssets = assets
      .where((asset) => !asset.isHidden)
      .toList(growable: false);
  final visibleHoldings = visibleAssets
      .expand((asset) => asset.visibleHoldings)
      .toList(growable: false);
  final visibleTransactions = visibleAssets
      .expand(
        (asset) => asset.visibleHoldings.expand(
          (holding) => holding.transactions.map(
            (transaction) => _SummaryTransaction(
              asset: asset,
              holding: holding,
              transaction: transaction,
            ),
          ),
        ),
      )
      .toList(growable: false);
  final recentTransactions = _recentTransactions(visibleTransactions, now: now);
  final totalValuation = visibleAssets.fold<double>(
    0,
    (sum, asset) => sum + asset.totalValuationAmount,
  );
  final totalPurchase = visibleAssets.fold<double>(
    0,
    (sum, asset) => sum + asset.totalPurchaseAmount,
  );
  final totalProfit = totalValuation - totalPurchase;
  final totalProfitRate = totalPurchase == 0
      ? 0.0
      : (totalProfit / totalPurchase) * 100;
  final sortedHoldingsByValue = [...visibleHoldings]
    ..sort((a, b) => b.valuationAmount.compareTo(a.valuationAmount));
  final visibleTransactionDates = transactionDates
      .where((date) => _hasTransactionOnDate(visibleTransactions, date))
      .toList(growable: false);
  final firstTransactionDate = visibleTransactionDates.isEmpty
      ? null
      : visibleTransactionDates.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final lastTransactionDate = visibleTransactionDates.isEmpty
      ? null
      : visibleTransactionDates.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);

  double ratioOfTotal(double amount) {
    if (totalValuation == 0) return 0;
    return (amount / totalValuation) * 100;
  }

  return <String, Object?>{
    'generated_at': now.toIso8601String(),
    'timezone': now.timeZoneName,
    'scope':
        'AI 진단용 핵심 데이터. 숨김 자산은 제외하고, 최근 7일 거래내역만 포함하며, 사용자 식별값/거래 원장/client_id/id/전체 스냅샷 상세는 제외.',
    'summary': <String, Object?>{
      'visible_asset_count': visibleAssets.length,
      'holding_count': visibleHoldings.length,
      'visible_holding_count': visibleHoldings.length,
      'transaction_count': visibleTransactions.length,
      'recent_transaction_count': recentTransactions.length,
      'target_ratio_count': targetRatios.length,
      'snapshot_count': snapshots.length,
      'transaction_date_count': visibleTransactionDates.length,
      'first_transaction_date': firstTransactionDate,
      'last_transaction_date': lastTransactionDate,
      'total_visible_valuation_krw': totalValuation,
      'total_visible_purchase_krw': totalPurchase,
      'total_visible_profit_krw': totalProfit,
      'total_visible_profit_rate': totalProfitRate,
    },
    'asset_allocation': visibleAssets
        .map((asset) {
          final targetRatio = asset.id == null ? null : targetRatios[asset.id!];
          final visibleAssetHoldings = asset.visibleHoldings;
          return <String, Object?>{
            'asset_type': asset.assetType,
            'name': asset.displayName,
            'currency_code': asset.currencyCode,
            'valuation_krw': asset.totalValuationAmount,
            'purchase_krw': asset.totalPurchaseAmount,
            'profit_krw': asset.totalProfitAmount,
            'profit_rate': asset.totalProfitRate,
            'allocation_rate': ratioOfTotal(asset.totalValuationAmount),
            'target_ratio': targetRatio,
            'target_gap': targetRatio == null
                ? null
                : ratioOfTotal(asset.totalValuationAmount) - targetRatio,
            'visible_holding_count': visibleAssetHoldings.length,
            'transaction_count': visibleAssetHoldings.fold<int>(
              0,
              (sum, holding) => sum + holding.transactions.length,
            ),
          };
        })
        .toList(growable: false),
    'asset_type_allocation': visibleAssets
        .fold<Map<String, double>>(<String, double>{}, (acc, asset) {
          acc.update(
            asset.assetType,
            (value) => value + asset.totalValuationAmount,
            ifAbsent: () => asset.totalValuationAmount,
          );
          return acc;
        })
        .entries
        .map(
          (entry) => <String, Object?>{
            'asset_type': entry.key,
            'valuation_krw': entry.value,
            'allocation_rate': ratioOfTotal(entry.value),
          },
        )
        .toList(growable: false),
    'holdings': sortedHoldingsByValue
        .map(
          (holding) => <String, Object?>{
            'asset_type': holding.assetType,
            'asset_name': holding.assetTitle,
            'name': holding.name,
            'symbol': holding.symbol,
            'currency_code': holding.currencyCode,
            'valuation_krw': holding.valuationAmount,
            'purchase_krw': holding.purchaseAmount,
            'profit_krw': holding.profitAmount,
            'profit_rate': holding.profitRate,
            'allocation_rate': ratioOfTotal(holding.valuationAmount),
            'transaction_count': holding.transactions.length,
          },
        )
        .toList(growable: false),
    'recent_transactions': recentTransactions
        .map(
          (item) => <String, Object?>{
            'date': item.transaction.date,
            'asset_type': item.asset.assetType,
            'asset_name': item.asset.displayName,
            'holding_name': item.holding.name,
            'symbol': item.holding.symbol,
            'currency_code': item.holding.currencyCode,
            'type': item.transaction.type,
            'name': item.transaction.name,
            'amount': item.transaction.amount,
            'quantity': item.transaction.quantity,
            'include_in_calculations': item.transaction.includeInCalculations,
            'flow_category': item.transaction.flowCategory,
          },
        )
        .toList(growable: false),
    'recent_snapshots': snapshots
        .take(12)
        .map(
          (snapshot) => <String, Object?>{
            'snapshot_date': snapshot.snapshotDate,
            'total_purchase_krw': snapshot.totalPurchaseAmount,
            'total_valuation_krw': snapshot.totalValuationAmount,
            'profit_krw': snapshot.profitAmount,
            'profit_rate': snapshot.profitRate,
            'exchange_rate': snapshot.exchangeRate,
          },
        )
        .toList(growable: false),
  };
}

String buildGptDbSummaryReportText(Map<String, Object?> payload) {
  final reportText = StringBuffer()
    ..writeln('아래는 MONEYFY 내부 DB 핵심 요약입니다.')
    ..writeln(
      '전체 원장이 아니라 진단에 필요한 요약값과 최근 7일 거래내역만 포함했어. 이 값을 바탕으로 포트폴리오를 분석해줘.',
    )
    ..writeln('')
    ..writeln(const JsonEncoder.withIndent('  ').convert(payload));
  return reportText.toString();
}

List<_SummaryTransaction> _recentTransactions(
  List<_SummaryTransaction> transactions, {
  required DateTime now,
}) {
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 7));
  final end = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  final recent = transactions
      .where((item) {
        final date = _parseTransactionDate(item.transaction.date);
        if (date == null) return false;
        return !date.isBefore(start) && date.isBefore(end);
      })
      .toList(growable: false);
  return recent..sort((a, b) => _compareTransactionDateDesc(a, b));
}

bool _hasTransactionOnDate(
  List<_SummaryTransaction> transactions,
  String date,
) {
  final normalizedDate = _parseTransactionDate(date);
  if (normalizedDate == null) return false;
  return transactions.any((item) {
    final transactionDate = _parseTransactionDate(item.transaction.date);
    if (transactionDate == null) return false;
    return transactionDate.year == normalizedDate.year &&
        transactionDate.month == normalizedDate.month &&
        transactionDate.day == normalizedDate.day;
  });
}

int _compareTransactionDateDesc(_SummaryTransaction a, _SummaryTransaction b) {
  final dateA = _parseTransactionDate(a.transaction.date);
  final dateB = _parseTransactionDate(b.transaction.date);
  if (dateA == null && dateB == null) return 0;
  if (dateA == null) return 1;
  if (dateB == null) return -1;
  return dateB.compareTo(dateA);
}

DateTime? _parseTransactionDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.replaceAll('.', '-');
  return DateTime.tryParse(normalized);
}

class _SummaryTransaction {
  const _SummaryTransaction({
    required this.asset,
    required this.holding,
    required this.transaction,
  });

  final AssetItem asset;
  final HoldingItem holding;
  final TransactionItem transaction;
}
