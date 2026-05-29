import 'package:flutter/material.dart';

import '../utils/display_currency.dart';
import '../utils/number_formatters.dart';

class TransactionFlowCategory {
  const TransactionFlowCategory._();

  static const String internal = 'internal';
  static const String externalDeposit = 'external_deposit';
  static const String externalWithdrawal = 'external_withdrawal';

  static String normalize(String? value) {
    return switch (value?.trim()) {
      externalDeposit => externalDeposit,
      externalWithdrawal => externalWithdrawal,
      _ => internal,
    };
  }
}

class TransactionItem {
  const TransactionItem({
    this.id,
    this.clientId,
    this.assetId,
    this.holdingId,
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
    required this.quantity,
    this.unitPrice,
    this.quantityValue,
    this.grossAmount,
    this.cashFlowAmount,
    this.realizedProfitAmount,
    this.realizedProfitSource = 'auto',
    this.fxRate,
    this.ledgerEventId,
    this.ledgerLineId,
    this.ledgerKind,
    this.ledgerAction,
    this.legacySourceTable,
    this.legacySourceId,
    this.counterpartyHoldingId,
    this.includeInCalculations = true,
    this.flowCategory = TransactionFlowCategory.internal,
  });

  final int? id;
  final String? clientId;
  final int? assetId;
  final int? holdingId;
  final String date;
  final String type;
  final String name;
  final String amount;
  final String quantity;
  final double? unitPrice;
  final double? quantityValue;
  final double? grossAmount;
  final double? cashFlowAmount;
  final double? realizedProfitAmount;
  final String realizedProfitSource;
  final double? fxRate;
  final int? ledgerEventId;
  final int? ledgerLineId;
  final String? ledgerKind;
  final String? ledgerAction;
  final String? legacySourceTable;
  final int? legacySourceId;
  final int? counterpartyHoldingId;
  final bool includeInCalculations;
  final String flowCategory;

  bool get isLedgerBacked => ledgerEventId != null || ledgerLineId != null;

  bool get isInvestmentLedgerAction {
    return switch (ledgerAction) {
      'opening_quantity' ||
      'buy' ||
      'sell' ||
      'dividend' ||
      'interest' ||
      'fee' ||
      'tax' ||
      'adjustment' => true,
      _ => false,
    };
  }

  bool get isStandaloneCashLedgerAction {
    return switch (ledgerAction) {
      'deposit' ||
      'withdrawal' ||
      'transfer_out' ||
      'transfer_in' ||
      'fx_out' ||
      'fx_in' ||
      'opening_cash' ||
      'adjustment' => true,
      _ => false,
    };
  }

  bool get canOpenCashFormFromLedger {
    return isStandaloneCashLedgerAction;
  }

  bool get canOpenInvestmentFormFromLedger {
    return switch (ledgerAction) {
      'buy' || 'sell' || 'dividend' || 'interest' => true,
      _ => false,
    };
  }
}

class HoldingItem {
  const HoldingItem({
    this.id,
    this.clientId,
    this.assetId,
    this.assetTitle,
    this.assetType,
    this.isHidden = false,
    this.currencyCode = 'KRW',
    this.exchangeRate = 1,
    this.marketUpdatedAt,
    this.exchangeCode = '',
    required this.name,
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.note,
    required this.transactions,
  });

  final int? id;
  final String? clientId;
  final int? assetId;
  final String? assetTitle;
  final String? assetType;
  final bool isHidden;
  final String currencyCode;
  final double exchangeRate;
  final String? marketUpdatedAt;
  final String exchangeCode;
  final String name;
  final String symbol;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final String note;
  final List<TransactionItem> transactions;

  double get currencyMultiplier => currencyCode == 'USD' ? exchangeRate : 1;

  // USD holdings store averagePrice in KRW, while currentPrice is fetched in USD.
  double get purchaseAmount => quantity * averagePrice;

  double get valuationAmount => quantity * currentPrice * currencyMultiplier;

  double get profitAmount => valuationAmount - purchaseAmount;

  double get profitRate {
    if (purchaseAmount == 0) return 0;
    return (profitAmount / purchaseAmount) * 100;
  }

  String get quantityText => formatPlainQuantity(quantity);

  String get subtitle =>
      symbol.isEmpty ? quantityText : '$symbol • $quantityText';

  String get value =>
      MoneyfyDisplayCurrencySettings.formatAmountFromKrw(valuationAmount);

  String get change =>
      '${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(1)}%';

  String get primaryMetricLabel => '시세';

  String get primaryMetricValue =>
      MoneyfyDisplayCurrencySettings.formatAmountFromSource(
        currentPrice,
        sourceCurrency: currencyCode,
        exchangeRate: exchangeRate,
      );

  String get secondaryMetricLabel => '평단';

  String get secondaryMetricValue => currencyCode == 'USD'
      ? MoneyfyDisplayCurrencySettings.formatAmountFromKrw(averagePrice)
      : MoneyfyDisplayCurrencySettings.formatAmountFromSource(
          averagePrice,
          sourceCurrency: currencyCode,
          exchangeRate: exchangeRate,
        );

  bool get isCashLike {
    if (assetType == '현금') return true;
    return id != null && id! < 0;
  }

  bool get isClosedInvestmentPosition => !isCashLike && quantity <= 0;

  String get quantityMetricLabel => isCashLike ? '잔액' : '수량';

  String get quantityMetricValue => isCashLike
      ? MoneyfyDisplayCurrencySettings.formatAmountFromSource(
          quantity,
          sourceCurrency: currencyCode,
          exchangeRate: exchangeRate,
        )
      : quantityText;

  String get purchaseMetricLabel => '매수금액';

  String get purchaseMetricValue =>
      MoneyfyDisplayCurrencySettings.formatAmountFromKrw(purchaseAmount);
}

class AssetItem {
  const AssetItem({
    this.id,
    this.clientId,
    required this.assetType,
    required this.title,
    required this.alias,
    this.isHidden = false,
    this.currencyCode = 'KRW',
    required this.value,
    required this.change,
    required this.icon,
    required this.quantityLabel,
    required this.quantityValue,
    required this.averageLabel,
    required this.averageValue,
    required this.note,
    required this.holdings,
    required this.transactions,
  });

  final int? id;
  final String? clientId;
  final String assetType;
  final String title;
  final String alias;
  final bool isHidden;
  final String currencyCode;
  final String value;
  final String change;
  final IconData icon;
  final String quantityLabel;
  final String quantityValue;
  final String averageLabel;
  final String averageValue;
  final String note;
  final List<HoldingItem> holdings;
  final List<TransactionItem> transactions;

  String get displayName => alias.isEmpty ? title : alias;

  List<HoldingItem> get visibleHoldings {
    return holdings
        .where(
          (holding) => !holding.isHidden && !holding.isClosedInvestmentPosition,
        )
        .toList(growable: false);
  }

  double get totalValuationAmount {
    if (holdings.isNotEmpty) {
      return visibleHoldings.fold<double>(
        0,
        (sum, holding) => sum + holding.valuationAmount,
      );
    }
    return _parseDisplayAmount(value);
  }

  double get totalPurchaseAmount {
    if (holdings.isNotEmpty) {
      return visibleHoldings.fold<double>(
        0,
        (sum, holding) => sum + holding.purchaseAmount,
      );
    }
    return totalValuationAmount;
  }

  double get backendValuationAmount {
    if (holdings.isNotEmpty) {
      return holdings.fold<double>(
        0,
        (sum, holding) => sum + holding.valuationAmount,
      );
    }
    return _parseDisplayAmount(value);
  }

  double get backendPurchaseAmount {
    if (holdings.isNotEmpty) {
      return holdings.fold<double>(
        0,
        (sum, holding) => sum + holding.purchaseAmount,
      );
    }
    return backendValuationAmount;
  }

  double get totalProfitAmount => totalValuationAmount - totalPurchaseAmount;

  double get totalProfitRate {
    if (totalPurchaseAmount == 0) return 0;
    return (totalProfitAmount / totalPurchaseAmount) * 100;
  }

  double _parseDisplayAmount(String text) {
    final normalized = text.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }
}
