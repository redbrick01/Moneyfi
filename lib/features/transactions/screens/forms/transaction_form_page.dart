import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/components/forms/market_search_field.dart';

import 'package:flutter/material.dart';

import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/utils/input_validators.dart';
import 'package:moneyfy/utils/number_formatters.dart';
import 'package:moneyfy/components/forms/form_design.dart';

const _transactionTypes = ['매수', '매도', '배당', '이자'];

class _InvestmentLedgerCopy {
  const _InvestmentLedgerCopy({
    required this.amountLabel,
    required this.quantityLabel,
  });

  final String amountLabel;
  final String quantityLabel;
}

enum InstrumentTradeSide {
  buy('매수'),
  sell('매도');

  const InstrumentTradeSide(this.label);
  final String label;
}

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required int this.assetId,
    required this.holdingId,
    this.holdingClientId,
    this.item,
    this.defaultName,
    this.assetBuyMode = false,
    this.assetsFutureForTesting,
  }) : fixedInstrument = null,
       tradeSide = null;

  const TransactionFormPage.forInstrument({
    super.key,
    required MarketSearchResult instrument,
    required InstrumentTradeSide side,
    this.assetId,
    this.holdingId,
    this.holdingClientId,
    this.assetsFutureForTesting,
  }) : fixedInstrument = instrument,
       tradeSide = side,
       item = null,
       assetBuyMode = false,
       defaultName = null;

  final MarketSearchResult? fixedInstrument;
  final InstrumentTradeSide? tradeSide;
  final int? assetId;
  final int? holdingId;
  final String? holdingClientId;
  final TransactionItem? item;
  final String? defaultName;
  final bool assetBuyMode;
  final Future<List<AssetItem>>? assetsFutureForTesting;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  late Future<List<AssetItem>> _assetsFuture;
  late final TextEditingController dateController;
  late final TextEditingController typeController;
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController quantityController;
  late final TextEditingController buyFxRateController;
  late final TextEditingController realizedProfitController;
  late final TextEditingController searchController;
  int? selectedHoldingId;
  int? selectedIncomeAccount;
  late bool includeInCalculations;
  late bool useManualRealizedProfit;
  bool isSaving = false;
  String? searchMessage;
  MarketSearchResult? _selectedMarketResult;
  int? selectedMarketAssetId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _selectedMarketResult = widget.fixedInstrument;
    selectedMarketAssetId = widget.assetId;
    dateController = TextEditingController(text: item?.date ?? _todayText());
    typeController = TextEditingController(
      text:
          widget.tradeSide?.label ??
          (widget.assetBuyMode ? '매수' : item?.type ?? '매수'),
    );
    nameController = TextEditingController(
      text:
          item?.name ??
          widget.fixedInstrument?.name ??
          widget.defaultName ??
          '',
    );
    amountController = TextEditingController(text: item?.amount ?? '');
    quantityController = TextEditingController(text: item?.quantity ?? '');
    buyFxRateController = TextEditingController(
      text: item?.fxRate == null ? '' : _numberText(item!.fxRate!),
    );
    realizedProfitController = TextEditingController(
      text:
          item?.realizedProfitSource == 'manual' &&
              item?.realizedProfitAmount != null
          ? _numberText(item!.realizedProfitAmount!)
          : '',
    );
    searchController = TextEditingController();
    amountController.addListener(_handlePreviewInputChanged);
    quantityController.addListener(_handlePreviewInputChanged);
    buyFxRateController.addListener(_handlePreviewInputChanged);
    realizedProfitController.addListener(_handlePreviewInputChanged);
    selectedHoldingId = item?.holdingId ?? widget.holdingId;
    selectedIncomeAccount = item?.counterpartyHoldingId?.abs();
    includeInCalculations = item?.includeInCalculations ?? true;
    useManualRealizedProfit = item?.realizedProfitSource == 'manual';
    _assetsFuture =
        widget.assetsFutureForTesting ?? AppDatabase.instance.fetchAssets();
  }

  String _todayText() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  @override
  void dispose() {
    dateController.dispose();
    typeController.dispose();
    nameController.dispose();
    amountController.removeListener(_handlePreviewInputChanged);
    quantityController.removeListener(_handlePreviewInputChanged);
    buyFxRateController.removeListener(_handlePreviewInputChanged);
    realizedProfitController.removeListener(_handlePreviewInputChanged);
    amountController.dispose();
    quantityController.dispose();
    buyFxRateController.dispose();
    realizedProfitController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _handlePreviewInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (isSaving || typeController.text.trim().isEmpty) return;
    final transactionType = typeController.text.trim();
    final requiresQuantity = transactionType == '매수' || transactionType == '매도';
    final dateValidation = MoneyfyInputValidators.date(dateController.text);
    if (!dateValidation.isValid) {
      _showValidationMessage(dateValidation.message!);
      return;
    }

    final nameValidation = MoneyfyInputValidators.requiredText(
      nameController.text,
      fieldName: '이름',
    );
    if (!nameValidation.isValid) {
      _showValidationMessage(nameValidation.message!);
      return;
    }

    final amountValidation = MoneyfyInputValidators.decimal(
      amountController.text,
      fieldName: requiresQuantity ? '단가' : '금액',
      allowZero: false,
    );
    if (!amountValidation.isValid) {
      _showValidationMessage(amountValidation.message!);
      return;
    }

    final quantityValidation = MoneyfyInputValidators.decimal(
      quantityController.text,
      fieldName: '수량',
      allowZero: false,
    );
    if (requiresQuantity && !quantityValidation.isValid) {
      _showValidationMessage(quantityValidation.message!);
      return;
    }

    final amountText = _numberText(amountValidation.value!);
    final quantityText = requiresQuantity
        ? _numberText(quantityValidation.value!)
        : '';

    if (dateController.text.trim() != dateValidation.value ||
        amountController.text.trim() != amountText ||
        (requiresQuantity && quantityController.text.trim() != quantityText)) {
      setState(() {
        dateController.text = dateValidation.value!;
        amountController.text = amountText;
        if (requiresQuantity) {
          quantityController.text = quantityText;
        }
      });
    }

    if (nameController.text.trim() != nameValidation.value) {
      setState(() {
        nameController.text = nameValidation.value!;
      });
    }

    if (requiresQuantity &&
        (amountValidation.value! <= 0 || quantityValidation.value! <= 0)) {
      _showValidationMessage(
        requiresQuantity
            ? '단가와 수량을 0보다 큰 숫자로 입력해 주세요.'
            : '금액을 0보다 큰 숫자로 입력해 주세요.',
      );
      return;
    }

    double? manualRealizedProfitAmount;
    if (transactionType == '매도' && useManualRealizedProfit) {
      final realizedProfitValidation = MoneyfyInputValidators.decimal(
        realizedProfitController.text,
        fieldName: '실현손익',
        allowZero: true,
        allowNegative: true,
      );
      if (!realizedProfitValidation.isValid) {
        _showValidationMessage(realizedProfitValidation.message!);
        return;
      }
      manualRealizedProfitAmount = realizedProfitValidation.value!;
      final realizedProfitText = _numberText(manualRealizedProfitAmount);
      if (realizedProfitController.text.trim() != realizedProfitText) {
        setState(() {
          realizedProfitController.text = realizedProfitText;
        });
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final item = widget.item;
      final fixed = widget.fixedInstrument != null;
      final displayedAssets = await _assetsFuture;
      final assets = fixed
          ? await AppDatabase.instance.fetchAssets()
          : displayedAssets;
      if (fixed && widget.holdingId == null) {
        final displayed = _assetForMarketResult(
          displayedAssets,
          widget.fixedInstrument!,
        );
        final latest = _assetForMarketResult(assets, widget.fixedInstrument!);
        if (displayed?.id == null ||
            displayed!.id != latest?.id ||
            displayed.clientId != latest?.clientId) {
          throw StateError('거래할 자산군을 다시 확인해 주세요.');
        }
      }
      final currentHolding = await _resolveCurrentHolding(assets);
      final selectedMarketResult = _selectedMarketResult;
      final marketAsset = selectedMarketResult == null
          ? null
          : _assetForMarketResult(assets, selectedMarketResult);
      if (currentHolding == null &&
          selectedMarketResult != null &&
          transactionType != '매수') {
        _showValidationMessage('새 종목은 최초 매수로 추가해 주세요.');
        return;
      }
      final currentAssetId =
          currentHolding?.assetId ?? marketAsset?.id ?? widget.assetId;
      if (currentAssetId == null) throw StateError('거래할 자산군을 선택해 주세요.');
      int? savedHoldingId = currentHolding?.id;
      double? tradeFxRate;
      final requiresBuyFxRate = _requiresBuyFxRate(currentHolding);
      final hasBuyFxRateInput = buyFxRateController.text.trim().isNotEmpty;
      if (requiresBuyFxRate && (includeInCalculations || hasBuyFxRateInput)) {
        final fxRateValidation = MoneyfyInputValidators.decimal(
          buyFxRateController.text,
          fieldName: '매수 환율',
          allowZero: false,
        );
        if (!fxRateValidation.isValid || fxRateValidation.value! <= 0) {
          _showValidationMessage(
            fxRateValidation.message ?? '매수 환율을 0보다 크게 입력해 주세요.',
          );
          setState(() {
            isSaving = false;
          });
          return;
        }
        tradeFxRate = fxRateValidation.value!;
        final fxRateText = _numberText(tradeFxRate);
        if (buyFxRateController.text.trim() != fxRateText) {
          setState(() {
            buyFxRateController.text = fxRateText;
          });
        }
      }
      if (item == null) {
        if (currentHolding == null && selectedMarketResult != null) {
          savedHoldingId = await AppDatabase.instance
              .createHoldingWithInitialBuy(
                assetId: currentAssetId,
                currencyCode: selectedMarketResult.currencyCode,
                exchangeCode: selectedMarketResult.currencyCode == 'USD'
                    ? selectedMarketResult.exchangeCode
                    : '',
                holdingName: selectedMarketResult.name,
                symbol: selectedMarketResult.symbol,
                currentPrice: fixed && selectedMarketResult.currentPrice <= 0
                    ? amountValidation.value!
                    : selectedMarketResult.currentPrice,
                note: '',
                date: dateValidation.value!,
                transactionName: nameValidation.value!,
                amount: amountText,
                quantity: quantityText,
                includeInCalculations: includeInCalculations,
                tradeFxRate: tradeFxRate,
              );
        } else {
          final currentHoldingId = currentHolding?.id;
          if (currentHoldingId == null) {
            throw StateError('보유 종목 정보를 찾을 수 없습니다.');
          }
          await AppDatabase.instance.createTransaction(
            assetId: currentAssetId,
            holdingId: currentHoldingId,
            incomeCashAccountId:
                includeInCalculations &&
                    (transactionType == '배당' || transactionType == '이자') &&
                    (selectedIncomeAccount ?? 0) > 0
                ? selectedIncomeAccount
                : null,
            date: dateValidation.value!,
            type: transactionType,
            name: nameValidation.value!,
            amount: amountText,
            quantity: quantityText,
            includeInCalculations: includeInCalculations,
            manualRealizedProfitAmount: manualRealizedProfitAmount,
            tradeFxRate: tradeFxRate,
          );
        }
      } else {
        final currentHoldingId = currentHolding?.id;
        if (currentHoldingId == null) {
          throw StateError('보유 종목 정보를 찾을 수 없습니다.');
        }
        await AppDatabase.instance.updateTransactionItem(
          TransactionItem(
            id: item.id,
            clientId: item.clientId,
            assetId: currentAssetId,
            holdingId: currentHoldingId,
            date: dateValidation.value!,
            type: transactionType,
            name: nameValidation.value!,
            amount: amountText,
            quantity: quantityText,
            unitPrice: item.unitPrice,
            quantityValue: item.quantityValue,
            grossAmount: item.grossAmount,
            cashFlowAmount: item.cashFlowAmount,
            realizedProfitAmount:
                manualRealizedProfitAmount ?? item.realizedProfitAmount,
            realizedProfitSource: manualRealizedProfitAmount == null
                ? 'auto'
                : 'manual',
            fxRate: tradeFxRate,
            counterpartyHoldingId: -(selectedIncomeAccount ?? 0),
            ledgerEventId: item.ledgerEventId,
            ledgerLineId: item.ledgerLineId,
            ledgerKind: item.ledgerKind,
            ledgerAction: item.ledgerAction,
            legacySourceTable: item.legacySourceTable,
            legacySourceId: item.legacySourceId,
            includeInCalculations: includeInCalculations,
            flowCategory: item.flowCategory,
          ),
        );
      }

      final savedHolding = fixed
          ? await AppDatabase.instance.fetchHoldingById(savedHoldingId!)
          : null;
      if (SyncService.instance.canSync) {
        await SyncService.instance.syncNow(reason: 'transaction_form_save');
      }

      if (!mounted) return;
      if (fixed) {
        Navigator.of(context).pop(savedHolding);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $error')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  _InvestmentLedgerCopy _ledgerCopyFor(String type) {
    return switch (type) {
      '매수' => const _InvestmentLedgerCopy(
        amountLabel: '매수 단가',
        quantityLabel: '매수 수량',
      ),
      '매도' => const _InvestmentLedgerCopy(
        amountLabel: '매도 단가',
        quantityLabel: '매도 수량',
      ),
      '배당' => const _InvestmentLedgerCopy(
        amountLabel: '배당 금액',
        quantityLabel: '수량',
      ),
      '이자' => const _InvestmentLedgerCopy(
        amountLabel: '이자 금액',
        quantityLabel: '수량',
      ),
      _ => const _InvestmentLedgerCopy(amountLabel: '금액', quantityLabel: '수량'),
    };
  }

  String _numberText(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  String _transactionAmountPreview(List<AssetItem> assets) {
    final type = typeController.text.trim();
    final unitAmount = _parseFormNumber(amountController.text);
    if (unitAmount == null || unitAmount <= 0) return '-';

    final totalAmount = switch (type) {
      '매수' || '매도' => () {
        final quantity = _parseFormNumber(quantityController.text);
        if (quantity == null || quantity <= 0) return null;
        return unitAmount * quantity;
      }(),
      _ => unitAmount,
    };
    if (totalAmount == null || totalAmount <= 0) return '-';

    final holding = _currentHolding(assets);
    final selectedMarketResult = _selectedMarketResult;
    return MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      totalAmount,
      sourceCurrency:
          selectedMarketResult?.currencyCode ?? holding?.currencyCode ?? 'KRW',
      exchangeRate: holding?.exchangeRate ?? 1,
    );
  }

  double? _parseFormNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  bool _requiresBuyFxRate(HoldingItem? holding) {
    final currencyCode =
        holding?.currencyCode ?? _selectedMarketResult?.currencyCode;
    return typeController.text.trim() == '매수' && currencyCode == 'USD';
  }

  double _defaultUsdKrwRate(List<AssetItem> assets, HoldingItem? holding) {
    final holdingRate = holding?.exchangeRate ?? 0;
    if (holdingRate > 0) return holdingRate;
    for (final asset in assets) {
      for (final candidate in asset.holdings) {
        if (candidate.currencyCode == 'USD' && candidate.exchangeRate > 0) {
          return candidate.exchangeRate;
        }
      }
    }
    return 1;
  }

  void _ensureDefaultBuyFxRate(List<AssetItem> assets, HoldingItem? holding) {
    if (!_requiresBuyFxRate(holding)) return;
    if (buyFxRateController.text.trim().isNotEmpty) return;
    final rate = _defaultUsdKrwRate(assets, holding);
    if (rate <= 0) return;
    buyFxRateController.text = _numberText(rate);
  }

  HoldingItem? _settlementCashHoldingFor(
    List<AssetItem> assets,
    HoldingItem? holding,
  ) {
    if (holding == null) return null;
    for (final asset in assets) {
      if (asset.id != (holding.assetId ?? widget.assetId)) continue;
      final matches = asset.holdings.where(
        (candidate) =>
            candidate.isCashLike &&
            candidate.currencyCode == holding.currencyCode,
      );
      if (matches.isNotEmpty) return matches.first;
    }
    return null;
  }

  double _buyableCashFor(List<AssetItem> assets, HoldingItem? holding) {
    final settlementCash = _settlementCashHoldingFor(assets, holding);
    if (settlementCash == null) return 0;
    var balance = settlementCash.quantity;
    final item = widget.item;
    if (item == null || !item.includeInCalculations) {
      return balance <= 0 ? 0 : balance;
    }
    if (item.holdingId != holding?.id) {
      return balance <= 0 ? 0 : balance;
    }
    final existingAmount = _parseFormNumber(item.amount)?.abs() ?? 0;
    final existingQuantity = _parseFormNumber(item.quantity)?.abs() ?? 0;
    final existingTotal = existingQuantity > 0
        ? existingAmount * existingQuantity
        : existingAmount;
    switch (item.type.trim()) {
      case '매수':
      case 'buy':
        balance += existingTotal;
        break;
      case '매도':
      case 'sell':
        balance -= existingTotal;
        break;
    }
    return balance <= 0 ? 0 : balance;
  }

  double _sellableQuantityFor(HoldingItem? holding) {
    if (holding == null || holding.isCashLike) return 0;
    var quantity = holding.quantity;
    final item = widget.item;
    if (item == null || !item.includeInCalculations) {
      return isEffectivelyZeroQuantity(quantity) ? 0 : quantity;
    }
    if (item.holdingId != holding.id) {
      return isEffectivelyZeroQuantity(quantity) ? 0 : quantity;
    }

    final existingQuantity = _parseFormNumber(item.quantity)?.abs() ?? 0;
    switch (item.type.trim()) {
      case '매도':
      case 'sell':
      case '출금':
      case 'withdraw':
      case 'withdrawal':
        quantity += existingQuantity;
        break;
      case '초기':
      case 'initial':
      case '매수':
      case 'buy':
      case '입금':
      case 'deposit':
        quantity -= existingQuantity;
        break;
    }
    return isEffectivelyZeroQuantity(quantity) ? 0 : quantity;
  }

  void _applySellQuantityRatio(double availableQuantity, double ratio) {
    final selectedQuantity = ratio >= 1
        ? availableQuantity
        : availableQuantity * ratio;
    setState(() {
      quantityController.text = formatPlainQuantity(selectedQuantity);
    });
  }

  void _applyBuyCashRatio(double availableCash, double ratio) {
    final unitAmount = _parseFormNumber(amountController.text);
    if (unitAmount == null || unitAmount <= 0) return;
    final selectedAmount = ratio >= 1 ? availableCash : availableCash * ratio;
    final selectedQuantity = selectedAmount / unitAmount;
    setState(() {
      quantityController.text = formatPlainQuantity(selectedQuantity);
    });
  }

  HoldingItem? _currentHolding(List<AssetItem> assets) {
    final fixed = widget.fixedInstrument;
    if (fixed != null) {
      if (widget.holdingId != null) {
        for (final asset in assets) {
          for (final holding in asset.holdings) {
            final matches = widget.holdingClientId?.isNotEmpty == true
                ? holding.clientId == widget.holdingClientId
                : holding.id == widget.holdingId;
            if (matches &&
                !holding.isCashLike &&
                asset.assetType == fixed.assetType &&
                holding.symbol == fixed.symbol &&
                holding.currencyCode == fixed.currencyCode) {
              return holding;
            }
          }
        }
        return null;
      }
      final asset = _assetForMarketResult(assets, fixed);
      return asset?.id == null
          ? null
          : _existingHoldingForMarketResult(assets, fixed, assetId: asset!.id!);
    }
    if (_selectedMarketResult != null) return null;
    for (final asset in assets) {
      for (final holding in asset.holdings) {
        if (!holding.isCashLike && holding.id == selectedHoldingId) {
          return holding;
        }
      }
    }
    final clientId = widget.holdingClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      for (final asset in assets) {
        for (final holding in asset.holdings) {
          if (!holding.isCashLike && holding.clientId == clientId) {
            return holding;
          }
        }
      }
    }
    for (final asset in assets) {
      for (final holding in asset.holdings) {
        if (!holding.isCashLike) return holding;
      }
    }
    return null;
  }

  void _selectMarketResult(List<AssetItem> assets, MarketSearchResult result) {
    setState(() {
      _selectedMarketResult = result;
      selectedMarketAssetId = _defaultAssetIdForMarketResult(assets, result);
      searchController.text = '${result.name} (${result.symbol})';
      nameController.text = result.name;
      searchMessage = '선택됨: ${result.symbol}';
    });
    FocusScope.of(context).unfocus();
  }

  int? _defaultAssetIdForMarketResult(
    List<AssetItem> assets,
    MarketSearchResult result,
  ) {
    for (final asset in assets) {
      if (asset.id == widget.assetId && asset.assetType != '현금') {
        return asset.id;
      }
    }
    for (final asset in assets) {
      if (asset.assetType != '현금' && asset.id != null) {
        return asset.id;
      }
    }
    return null;
  }

  AssetItem? _assetForMarketSearch(List<AssetItem> assets) {
    for (final asset in assets) {
      if (asset.id == widget.assetId && asset.assetType != '현금') {
        return asset;
      }
    }
    for (final asset in assets) {
      for (final holding in asset.holdings) {
        if (holding.id == selectedHoldingId && asset.assetType != '현금') {
          return asset;
        }
      }
    }
    for (final asset in assets) {
      if (asset.assetType != '현금') return asset;
    }
    return null;
  }

  Set<String> _searchableAssetTypes(List<AssetItem> assets) {
    if (widget.assetBuyMode) {
      final asset = _assetForMarketSearch(assets);
      return asset == null ? const {} : {asset.assetType};
    }
    return {
      for (final asset in assets)
        if (asset.assetType != '현금') asset.assetType,
    };
  }

  AssetItem? _assetForMarketResult(
    List<AssetItem> assets,
    MarketSearchResult result,
  ) {
    if (widget.fixedInstrument != null) {
      final eligible = assets.where(
        (a) => a.assetType == result.assetType && a.id != null,
      );
      if (selectedMarketAssetId != null) {
        return eligible.where((a) => a.id == selectedMarketAssetId).firstOrNull;
      }
      return eligible.length == 1 ? eligible.single : null;
    }
    if (widget.assetBuyMode) {
      for (final asset in assets) {
        if (asset.id == widget.assetId && asset.assetType != '현금') {
          return asset;
        }
      }
      return null;
    }
    final selectedAssetId = selectedMarketAssetId;
    if (selectedAssetId != null) {
      for (final asset in assets) {
        if (asset.id == selectedAssetId && asset.assetType != '현금') {
          return asset;
        }
      }
    }
    for (final asset in assets) {
      if (asset.id == widget.assetId && asset.assetType != '현금') {
        return asset;
      }
    }
    for (final asset in assets) {
      if (asset.assetType != '현금') return asset;
    }
    return null;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<HoldingItem?> _resolveCurrentHolding(List<AssetItem> assets) async {
    if (widget.fixedInstrument != null) {
      final holding = _currentHolding(assets);
      if (widget.holdingId != null && holding == null) {
        throw StateError('선택한 보유 종목을 찾을 수 없습니다.');
      }
      return holding;
    }
    final selectedMarketResult = _selectedMarketResult;
    if (selectedMarketResult != null && widget.item == null) {
      final asset = _assetForMarketResult(assets, selectedMarketResult);
      if (asset?.id == null) {
        throw StateError('자산군을 선택해 주세요.');
      }
      final assetId = asset!.id!;
      final existingHolding = _existingHoldingForMarketResult(
        assets,
        selectedMarketResult,
        assetId: assetId,
      );
      if (existingHolding?.id != null) return existingHolding!;
      return null;
    }

    final selectedId = selectedHoldingId;
    if (selectedId != null) {
      final selectedById = await AppDatabase.instance.fetchHoldingById(
        selectedId,
      );
      if (selectedById?.id != null && !selectedById!.isCashLike) {
        return selectedById;
      }
    }

    final widgetHoldingId = widget.holdingId;
    if (widgetHoldingId != null) {
      final holdingById = await AppDatabase.instance.fetchHoldingById(
        widgetHoldingId,
      );
      if (holdingById?.id != null && !holdingById!.isCashLike) {
        return holdingById;
      }
    }

    final clientId = widget.holdingClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      final holdingByClientId = await AppDatabase.instance
          .fetchHoldingByClientId(clientId);
      if (holdingByClientId?.id != null && !holdingByClientId!.isCashLike) {
        return holdingByClientId;
      }
    }

    throw StateError('보유 종목 정보를 찾을 수 없습니다.');
  }

  HoldingItem? _existingHoldingForMarketResult(
    List<AssetItem> assets,
    MarketSearchResult result, {
    required int assetId,
  }) {
    final targetSymbol = result.symbol.trim().toUpperCase();
    for (final asset in assets) {
      if (asset.id != assetId) continue;
      for (final holding in asset.holdings) {
        if (holding.isCashLike || holding.id == null) continue;
        if (holding.currencyCode != result.currencyCode) continue;
        if (holding.currencyCode == 'USD' &&
            holding.exchangeCode.isNotEmpty &&
            result.exchangeCode.isNotEmpty &&
            holding.exchangeCode != result.exchangeCode) {
          continue;
        }
        if (holding.symbol.trim().toUpperCase() == targetSymbol) {
          return holding;
        }
      }
    }
    return null;
  }

  List<MoneyfySelectionOption<int>> _marketAssetOptions(
    List<AssetItem> assets,
    MarketSearchResult? result,
  ) {
    if (result == null) return const [];
    return [
      for (final asset in assets)
        if (asset.id != null &&
            asset.assetType != '현금' &&
            (widget.fixedInstrument == null ||
                asset.assetType == result.assetType))
          MoneyfySelectionOption<int>(
            value: asset.id!,
            title: asset.displayName,
            subtitle: [
              asset.assetType,
              asset.currencyCode,
              asset.quantityValue,
            ].join(' · '),
            meta: asset.currencyCode,
          ),
    ];
  }

  List<MoneyfySelectionOption<int>> _holdingOptions(List<AssetItem> assets) {
    return [
      for (final asset in assets)
        if (!widget.assetBuyMode || asset.id == widget.assetId)
          for (final holding in asset.holdings)
            if (!holding.isCashLike && holding.id != null)
              MoneyfySelectionOption<int>(
                value: holding.id!,
                title: holding.name,
                subtitle: [
                  asset.displayName,
                  if (holding.symbol.trim().isNotEmpty) holding.symbol,
                  holding.currencyCode,
                  holding.quantityMetricValue,
                ].join(' · '),
                meta: holding.currencyCode,
              ),
    ];
  }

  String _investmentLineActionLabel(String type) {
    return switch (type) {
      '매수' => 'buy',
      '매도' => 'sell',
      '배당' => 'dividend',
      '이자' => 'interest',
      _ => 'adjustment',
    };
  }

  String _investmentEventKindLabel(String type) {
    return switch (type) {
      '매수' || '매도' => 'trade',
      '배당' || '이자' => 'income',
      _ => 'adjustment',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetItem>>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data ?? const <AssetItem>[];
        final transactionType = typeController.text.trim();
        final requiresQuantity =
            transactionType == '매수' || transactionType == '매도';
        final ledgerCopy = _ledgerCopyFor(transactionType);
        final holdingOptions = _holdingOptions(assets);
        final marketAssetOptions = _marketAssetOptions(
          assets,
          _selectedMarketResult,
        );
        final currentHolding = _currentHolding(assets);
        if (_requiresBuyFxRate(currentHolding) &&
            buyFxRateController.text.trim().isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || buyFxRateController.text.trim().isNotEmpty) {
              return;
            }
            _ensureDefaultBuyFxRate(assets, currentHolding);
          });
        }
        final targetHoldingLabel =
            currentHolding?.name ?? _selectedMarketResult?.name ?? '보유 종목 선택';
        final sellableQuantity = transactionType == '매도'
            ? _sellableQuantityFor(currentHolding)
            : 0.0;
        final buyableCash = transactionType == '매수'
            ? _buyableCashFor(assets, currentHolding)
            : 0.0;
        final canUseBuyShortcuts =
            buyableCash > 0 &&
            (_parseFormNumber(amountController.text) ?? 0) > 0 &&
            (!_requiresBuyFxRate(currentHolding) ||
                (_parseFormNumber(buyFxRateController.text) ?? 0) > 0);

        final fixed = widget.fixedInstrument;
        final fixedAsset = fixed == null
            ? null
            : _assetForMarketResult(assets, fixed);
        return MoneyfyFormScaffold(
          title: fixed != null
              ? '종목 ${widget.tradeSide!.label}'
              : widget.assetBuyMode
              ? '종목 매수'
              : widget.item == null
              ? '거래 추가'
              : '거래 수정',
          actionLabel:
              widget.tradeSide?.label ?? (widget.assetBuyMode ? '매수' : '저장'),
          isSaving: isSaving,
          onSave: _save,
          actionEnabled: fixed != null
              ? (widget.holdingId != null
                        ? currentHolding != null
                        : fixedAsset != null) &&
                    (widget.tradeSide != InstrumentTradeSide.sell ||
                        sellableQuantity > 0)
              : holdingOptions.isNotEmpty || _selectedMarketResult != null,
          children: [
            if (!widget.assetBuyMode && fixed == null)
              MoneyfyFormSection(
                title: '원장 이벤트',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '거래 유형',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.neutralTextMuted,
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(
                      height: context.spacing.xs + context.spacing.xs / 4,
                    ),
                    MoneyfyChoiceWrap<String>(
                      options: _transactionTypes,
                      value: typeController.text.trim(),
                      labelBuilder: (type) => type,
                      onChanged: (value) {
                        setState(() {
                          typeController.text = value;
                        });
                      },
                    ),
                    SizedBox(
                      height: context.spacing.sm + context.spacing.xs / 4,
                    ),
                    _CalculationToggle(
                      value: includeInCalculations,
                      onChanged: (value) {
                        setState(() {
                          includeInCalculations = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (fixed != null)
              MoneyfyFormSection(
                title: '거래 종목',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fixed.name, style: context.typography.cardTitle),
                    Text(fixed.marketLabel, style: context.typography.meta),
                    if (widget.holdingId == null &&
                        snapshot.connectionState == ConnectionState.done) ...[
                      SizedBox(height: context.spacing.sm),
                      if (marketAssetOptions.isEmpty)
                        TextButton(
                          onPressed: () async {
                            if (await context.openAssetCreate() == true &&
                                mounted) {
                              setState(
                                () => _assetsFuture = AppDatabase.instance
                                    .fetchAssets(),
                              );
                            }
                          },
                          child: Text('${fixed.assetType} 자산군 추가'),
                        )
                      else
                        MoneyfySelectionField<int>(
                          label: '거래할 자산군',
                          options: marketAssetOptions,
                          value: fixedAsset?.id,
                          placeholder: '자산군 선택',
                          onChanged: (value) =>
                              setState(() => selectedMarketAssetId = value),
                        ),
                    ],
                  ],
                ),
              )
            else
              MoneyfyFormSection(
                title: '대상 보유',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assetBuyMode
                          ? '매수할 기존 종목을 선택하거나 새 종목을 검색해 주세요.'
                          : '매수, 매도, 배당, 이자를 기록할 보유 종목을 선택해 주세요.',
                      style: context.typography.meta,
                    ),
                    SizedBox(height: context.spacing.sm),
                    if (_selectedMarketResult == null)
                      MoneyfySelectionField<int>(
                        label: '보유 종목',
                        options: holdingOptions,
                        value: currentHolding?.id ?? selectedHoldingId,
                        placeholder: '보유 종목 선택',
                        onChanged: (value) {
                          setState(() {
                            _selectedMarketResult = null;
                            searchMessage = null;
                            selectedMarketAssetId = null;
                            selectedHoldingId = value;
                            selectedIncomeAccount = 0;
                            final selectedHolding = _currentHolding(assets);
                            if (selectedHolding != null) {
                              nameController.text = selectedHolding.name;
                            }
                          });
                        },
                      ),
                    if (includeInCalculations &&
                        (transactionType == '배당' || transactionType == '이자'))
                      MoneyfySelectionField<int>(
                        label: '수입 입금 계좌',
                        options: [
                          const MoneyfySelectionOption<int>(
                            value: 0,
                            title: '수입만 기록',
                          ),
                          for (final asset in assets)
                            for (final account in asset.holdings)
                              if ((account.id ?? 0) < 0 &&
                                  account.currencyCode ==
                                      currentHolding?.currencyCode)
                                MoneyfySelectionOption<int>(
                                  value: account.id!.abs(),
                                  title:
                                      '${asset.displayName} · ${account.name}',
                                  subtitle: account.currencyCode,
                                ),
                        ],
                        value: selectedIncomeAccount ?? 0,
                        placeholder: '수입만 기록',
                        onChanged: (value) =>
                            setState(() => selectedIncomeAccount = value),
                      ),
                    if (widget.item == null) ...[
                      if (_selectedMarketResult == null)
                        SizedBox(height: context.spacing.sm),
                      MarketSearchField<MarketSearchResult>(
                        label: '새 종목 검색',
                        controller: searchController,
                        message: searchMessage,
                        localSearch: (query) => searchMarketLocally(
                          assets,
                          _searchableAssetTypes(assets),
                          query,
                        ),
                        verify: (query, local) async {
                          final types = _searchableAssetTypes(assets);
                          final primary = _assetForMarketSearch(
                            assets,
                          )?.assetType;
                          if (primary == null || types.isEmpty) return local;
                          final result = await verifyMarketSymbol(
                            primaryAssetType: primary,
                            searchableAssetTypes: types,
                            query: query,
                            localResults: local,
                          );
                          return result == null
                              ? local
                              : mergeMarketResults(result, local);
                        },
                        itemBuilder: (_, item) =>
                            _SearchResultTile(result: item, onTap: null),
                        selected: _selectedMarketResult == null
                            ? null
                            : _SelectedTransactionMarketResultView(
                                result: _selectedMarketResult!,
                              ),
                        onEdited: () {
                          if (_selectedMarketResult == null) return;
                          setState(() {
                            _selectedMarketResult = null;
                            searchMessage = null;
                            selectedMarketAssetId = null;
                          });
                        },
                        onSelected: (result) =>
                            _selectMarketResult(assets, result),
                      ),
                      if (_selectedMarketResult != null &&
                          !widget.assetBuyMode) ...[
                        SizedBox(height: context.spacing.sm),
                        MoneyfySelectionField<int>(
                          label: '자산군',
                          options: marketAssetOptions,
                          value: selectedMarketAssetId,
                          placeholder: '자산군 선택',
                          onChanged: (value) {
                            setState(() {
                              selectedMarketAssetId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            MoneyfyFormSection(
              title: '거래 내용',
              child: Column(
                children: [
                  MoneyfyFormField(label: '날짜', controller: dateController),
                  if (fixed == null)
                    MoneyfyFormField(label: '이름', controller: nameController),
                  MoneyfyFormField(
                    label: ledgerCopy.amountLabel,
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  if (requiresQuantity) ...[
                    MoneyfyFormField(
                      label: ledgerCopy.quantityLabel,
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    if (_requiresBuyFxRate(currentHolding))
                      MoneyfyFormField(
                        label: '매수 환율',
                        controller: buyFxRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    if (transactionType == '매도' && sellableQuantity > 0)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: context.spacing.sm + context.spacing.xs / 4,
                        ),
                        child: MoneyfyPercentageShortcutButtons(
                          keyPrefix: 'sell-quantity-shortcut',
                          onSelected: (ratio) =>
                              _applySellQuantityRatio(sellableQuantity, ratio),
                        ),
                      ),
                    if (transactionType == '매수' && buyableCash > 0)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: context.spacing.sm + context.spacing.xs / 4,
                        ),
                        child: MoneyfyPercentageShortcutButtons(
                          keyPrefix: 'buy-cash-shortcut',
                          enabled: canUseBuyShortcuts,
                          onSelected: (ratio) =>
                              _applyBuyCashRatio(buyableCash, ratio),
                        ),
                      ),
                  ],
                  if (transactionType == '매도')
                    _RealizedProfitInput(
                      useManualValue: useManualRealizedProfit,
                      controller: realizedProfitController,
                      onModeChanged: (value) {
                        setState(() {
                          useManualRealizedProfit = value;
                        });
                      },
                    ),
                  MoneyfyLedgerPreview(
                    rows: [
                      MoneyfyLedgerPreviewRow(
                        label: 'event.kind',
                        value: _investmentEventKindLabel(transactionType),
                      ),
                      MoneyfyLedgerPreviewRow(
                        label: 'line.action',
                        value: _investmentLineActionLabel(transactionType),
                      ),
                      MoneyfyLedgerPreviewRow(
                        label: 'line.holding',
                        value: targetHoldingLabel,
                      ),
                      MoneyfyLedgerPreviewRow(
                        label: '거래금액',
                        value: _transactionAmountPreview(assets),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CalculationToggle extends StatelessWidget {
  const _CalculationToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(
        '포트폴리오 계산에 반영',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        value ? '보유 수량, 평단, 현금 흐름에 반영됩니다.' : '거래 내역에만 기록되고 현재 포트폴리오는 변하지 않습니다.',
      ),
    );
  }
}

class _RealizedProfitInput extends StatelessWidget {
  const _RealizedProfitInput({
    required this.useManualValue,
    required this.controller,
    required this.onModeChanged,
  });

  final bool useManualValue;
  final TextEditingController controller;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.spacing.sm + context.spacing.xs / 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실현손익',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          MoneyfyChoiceWrap<bool>(
            options: const [false, true],
            value: useManualValue,
            labelBuilder: (value) => value ? '직접 입력' : '자동 계산',
            onChanged: onModeChanged,
          ),
          if (useManualValue) ...[
            SizedBox(height: context.spacing.sm),
            MoneyfyFormField(
              label: '실현손익 금액',
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final MarketSearchResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.rMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm + context.spacing.xs / 4,
          vertical: context.spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.neutralText,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs / 2 - 1),
                  Text(
                    result.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.neutralTextMuted,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Text(
              result.priceLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.primary,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedTransactionMarketResultView extends StatelessWidget {
  const _SelectedTransactionMarketResultView({required this.result});

  final MarketSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.sm + context.spacing.xs / 4),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: _SearchResultTile(result: result, onTap: () {}),
    );
  }
}
