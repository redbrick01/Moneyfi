import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moneyfy/data/asset_data.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
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

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.assetId,
    required this.holdingId,
    this.holdingClientId,
    this.item,
    this.defaultName,
    this.assetBuyMode = false,
    this.assetsFutureForTesting,
  });

  final int assetId;
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
  late final Future<List<AssetItem>> _assetsFuture;
  late final TextEditingController dateController;
  late final TextEditingController typeController;
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController quantityController;
  late final TextEditingController buyFxRateController;
  late final TextEditingController realizedProfitController;
  late final TextEditingController searchController;
  int? selectedHoldingId;
  late bool includeInCalculations;
  late bool useManualRealizedProfit;
  bool isSaving = false;
  bool isSearching = false;
  String? searchMessage;
  Timer? _searchDebounce;
  int _searchGeneration = 0;
  List<_TransactionMarketSearchResult> _searchResults = const [];
  _TransactionMarketSearchResult? _selectedMarketResult;
  int? selectedMarketAssetId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    dateController = TextEditingController(text: item?.date ?? _todayText());
    typeController = TextEditingController(
      text: widget.assetBuyMode ? '매수' : item?.type ?? '매수',
    );
    nameController = TextEditingController(
      text: item?.name ?? widget.defaultName ?? '',
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
    _searchDebounce?.cancel();
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
      final assets = await _assetsFuture;
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
          await AppDatabase.instance.createHoldingWithInitialBuy(
            assetId: currentAssetId,
            currencyCode: selectedMarketResult.currencyCode,
            exchangeCode: selectedMarketResult.currencyCode == 'USD'
                ? selectedMarketResult.exchangeCode
                : '',
            holdingName: selectedMarketResult.name,
            symbol: selectedMarketResult.symbol,
            currentPrice: selectedMarketResult.currentPrice,
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

      if (SyncService.instance.canSync) {
        await SyncService.instance.syncNow(reason: 'transaction_form_save');
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  void _queueMarketSearch(List<AssetItem> assets, String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchMarketItems(assets, query);
    });
  }

  Future<void> _searchMarketItems(
    List<AssetItem> assets,
    String rawQuery,
  ) async {
    final primaryAssetType = _assetForMarketSearch(assets)?.assetType;
    final searchableAssetTypes = _searchableAssetTypes(assets);
    final query = rawQuery.trim();
    if (primaryAssetType == null || searchableAssetTypes.isEmpty) return;
    if (query.isEmpty) {
      setState(() {
        _searchResults = const [];
        _selectedMarketResult = null;
        selectedMarketAssetId = null;
        searchMessage = null;
      });
      return;
    }

    final generation = ++_searchGeneration;
    final localResults = _localMarketSearch(
      assets,
      searchableAssetTypes,
      query,
    );
    setState(() {
      isSearching = true;
      searchMessage = null;
      _searchResults = localResults;
      _selectedMarketResult = null;
      selectedMarketAssetId = null;
    });

    try {
      final apiResult = await _fetchFirstVerifiedMarketResult(
        primaryAssetType: primaryAssetType,
        searchableAssetTypes: searchableAssetTypes,
        query: query,
        localResults: localResults,
      );

      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        if (apiResult != null) {
          _searchResults = _mergeSearchResults(apiResult, localResults);
          searchMessage = null;
        } else {
          searchMessage = localResults.isEmpty ? '연관 종목이 없습니다.' : null;
        }
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void _selectMarketResult(
    List<AssetItem> assets,
    _TransactionMarketSearchResult result,
  ) {
    setState(() {
      _selectedMarketResult = result;
      selectedMarketAssetId = _defaultAssetIdForMarketResult(assets, result);
      _searchResults = const [];
      searchController.text = '${result.name} (${result.symbol})';
      nameController.text = result.name;
      searchMessage = '선택됨: ${result.symbol}';
    });
    FocusScope.of(context).unfocus();
  }

  int? _defaultAssetIdForMarketResult(
    List<AssetItem> assets,
    _TransactionMarketSearchResult result,
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
    _TransactionMarketSearchResult result,
  ) {
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

  List<_TransactionMarketSearchResult> _localMarketSearch(
    List<AssetItem> assets,
    Set<String> assetTypes,
    String query,
  ) {
    final normalizedQuery = query.trim().toUpperCase();
    if (normalizedQuery.isEmpty) return const [];

    final results = <_TransactionMarketSearchResult>[];
    final seen = <String>{};

    for (final instrument in _knownTransactionMarketInstruments) {
      if (!assetTypes.contains(instrument.assetType)) continue;
      if (!instrument.matches(normalizedQuery)) continue;
      final key =
          '${instrument.assetType}:${instrument.currencyCode}:${instrument.symbol}';
      if (seen.add(key)) results.add(instrument);
    }

    for (final asset in assets) {
      if (!assetTypes.contains(asset.assetType)) continue;
      for (final holding in asset.holdings) {
        final result = _TransactionMarketSearchResult.fromHolding(
          holding,
          asset.assetType,
        );
        if (!result.matches(normalizedQuery)) continue;
        final key =
            '${result.assetType}:${result.currencyCode}:${result.symbol}';
        if (seen.add(key)) results.add(result);
      }
    }

    for (final asset in assetItems) {
      if (!assetTypes.contains(asset.assetType)) continue;
      for (final holding in asset.holdings) {
        final result = _TransactionMarketSearchResult.fromHolding(
          holding,
          asset.assetType,
        );
        if (!result.matches(normalizedQuery)) continue;
        final key =
            '${result.assetType}:${result.currencyCode}:${result.symbol}';
        if (seen.add(key)) results.add(result);
      }
    }

    return results.take(8).toList(growable: false);
  }

  List<_TransactionMarketSearchResult> _mergeSearchResults(
    _TransactionMarketSearchResult apiResult,
    List<_TransactionMarketSearchResult> localResults,
  ) {
    return [
      apiResult,
      ...localResults.where(
        (result) =>
            result.assetType != apiResult.assetType ||
            result.symbol != apiResult.symbol ||
            result.currencyCode != apiResult.currencyCode,
      ),
    ].take(8).toList(growable: false);
  }

  Future<_TransactionMarketSearchResult?> _fetchFirstVerifiedMarketResult({
    required String primaryAssetType,
    required Set<String> searchableAssetTypes,
    required String query,
    required List<_TransactionMarketSearchResult> localResults,
  }) async {
    for (final candidate in _marketLookupCandidates(
      primaryAssetType,
      searchableAssetTypes,
      query,
    )) {
      final lookupHolding = HoldingItem(
        assetTitle: query,
        assetType: candidate.assetType,
        currencyCode: candidate.currencyCode,
        exchangeCode: candidate.exchangeCode,
        name: query,
        symbol: candidate.symbol,
        quantity: 0,
        averagePrice: 0,
        currentPrice: -1,
        note: '',
        transactions: const [],
      );

      final snapshot = await MarketDataService.instance.fetchSnapshot(
        lookupHolding,
        includeFundComponents: false,
      );
      final currentPrice = snapshot.currentPriceValue;
      if (currentPrice == null || currentPrice < 0) continue;

      _TransactionMarketSearchResult? matchedLocal;
      for (final result in localResults) {
        if (result.assetType == candidate.assetType &&
            result.symbol == candidate.symbol &&
            result.currencyCode == candidate.currencyCode) {
          matchedLocal = result;
          break;
        }
      }
      return _TransactionMarketSearchResult(
        name: matchedLocal?.name ?? query,
        symbol: candidate.symbol,
        assetType: candidate.assetType,
        currencyCode: candidate.currencyCode,
        exchangeCode: candidate.exchangeCode,
        currentPrice: currentPrice,
        sourceLabel: 'API',
        aliases: matchedLocal?.aliases ?? const [],
      );
    }
    return null;
  }

  List<_TransactionMarketLookupCandidate> _marketLookupCandidates(
    String primaryAssetType,
    Set<String> searchableAssetTypes,
    String query,
  ) {
    final normalized = query.trim().toUpperCase();
    final candidates = <_TransactionMarketLookupCandidate>[];
    final seen = <String>{};

    void add(
      String assetType,
      String symbol,
      String currencyCode,
      String exchangeCode,
    ) {
      final key = '$assetType:$currencyCode:$exchangeCode:$symbol';
      if (seen.add(key)) {
        candidates.add(
          _TransactionMarketLookupCandidate(
            assetType: assetType,
            symbol: symbol,
            currencyCode: currencyCode,
            exchangeCode: exchangeCode,
          ),
        );
      }
    }

    final known = _knownTransactionMarketInstruments.where(
      (instrument) =>
          searchableAssetTypes.contains(instrument.assetType) &&
          instrument.matches(normalized),
    );
    for (final instrument in known) {
      add(
        instrument.assetType,
        instrument.symbol,
        instrument.currencyCode,
        instrument.exchangeCode,
      );
    }

    add('주식', normalized, 'KRW', '');
    add('주식', normalized, 'USD', 'NAS');
    if (primaryAssetType != '주식' && primaryAssetType != '코인') {
      add(primaryAssetType, normalized, 'KRW', '');
    }
    add('코인', normalized, 'KRW', '');
    return candidates;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<HoldingItem?> _resolveCurrentHolding(List<AssetItem> assets) async {
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
    _TransactionMarketSearchResult result, {
    required int assetId,
  }) {
    final targetSymbol = result.symbol.trim().toUpperCase();
    for (final asset in assets) {
      if (asset.id != assetId) continue;
      for (final holding in asset.holdings) {
        if (holding.isCashLike || holding.id == null) continue;
        if (holding.currencyCode != result.currencyCode) continue;
        if (holding.symbol.trim().toUpperCase() == targetSymbol) {
          return holding;
        }
      }
    }
    return null;
  }

  List<MoneyfySelectionOption<int>> _marketAssetOptions(
    List<AssetItem> assets,
    _TransactionMarketSearchResult? result,
  ) {
    if (result == null) return const [];
    return [
      for (final asset in assets)
        if (asset.id != null && asset.assetType != '현금')
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

        return MoneyfyFormScaffold(
          title: widget.assetBuyMode
              ? '종목 매수'
              : widget.item == null
              ? '거래 추가'
              : '거래 수정',
          actionLabel: widget.assetBuyMode ? '매수' : '저장',
          isSaving: isSaving,
          onSave: _save,
          actionEnabled:
              holdingOptions.isNotEmpty || _selectedMarketResult != null,
          children: [
            if (!widget.assetBuyMode)
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
                          _searchResults = const [];
                          selectedMarketAssetId = null;
                          selectedHoldingId = value;
                          final selectedHolding = _currentHolding(assets);
                          if (selectedHolding != null) {
                            nameController.text = selectedHolding.name;
                          }
                        });
                      },
                    ),
                  if (widget.item == null) ...[
                    if (_selectedMarketResult == null)
                      SizedBox(height: context.spacing.sm),
                    _TransactionMarketSearchField(
                      controller: searchController,
                      isSearching: isSearching,
                      results: _searchResults,
                      selectedResult: _selectedMarketResult,
                      message: searchMessage,
                      onChanged: (query) => _queueMarketSearch(assets, query),
                      onResultSelected: (result) =>
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

class _TransactionMarketSearchField extends StatelessWidget {
  const _TransactionMarketSearchField({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.selectedResult,
    required this.message,
    required this.onChanged,
    required this.onResultSelected,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<_TransactionMarketSearchResult> results;
  final _TransactionMarketSearchResult? selectedResult;
  final String? message;
  final ValueChanged<String> onChanged;
  final ValueChanged<_TransactionMarketSearchResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '새 종목 검색',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colors.neutralTextMuted,
            fontWeight: AppFontWeights.semibold,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onChanged,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: '예: 005930, AAPL, BTC',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                  filled: true,
                  fillColor: context.colors.neutralSurfaceRaised,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.spacing.md,
                    vertical: context.spacing.sm + context.spacing.xs / 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius.rLg),
                    borderSide: BorderSide(
                      color: context.colors.neutralOutline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius.rLg),
                    borderSide: BorderSide(
                      color: context.colors.neutralOutline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.radius.rLg),
                    borderSide: BorderSide(
                      color: context.colors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
            SizedBox(
              height: 50,
              child: IconButton.filled(
                onPressed: isSearching
                    ? null
                    : () => onChanged(controller.text),
                icon: isSearching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: context.colors.neutralSurfaceOverlay,
                  foregroundColor: context.colors.neutralText,
                  disabledBackgroundColor: context.colors.neutralSurfaceRaised,
                  disabledForegroundColor: context.colors.neutralTextMuted,
                  fixedSize: const Size(50, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.radius.rMd),
                    side: BorderSide(color: context.colors.neutralOutline),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (results.isNotEmpty) ...[
          SizedBox(height: context.spacing.xs),
          _TransactionMarketSearchDropdown(
            results: results,
            onSelected: onResultSelected,
          ),
        ] else if (selectedResult != null) ...[
          SizedBox(height: context.spacing.xs),
          _SelectedTransactionMarketResultView(result: selectedResult!),
        ],
        if (message != null) ...[
          SizedBox(height: context.spacing.xs),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: message!.startsWith('선택됨')
                  ? context.colors.primary
                  : context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionMarketSearchDropdown extends StatelessWidget {
  const _TransactionMarketSearchDropdown({
    required this.results,
    required this.onSelected,
  });

  final List<_TransactionMarketSearchResult> results;
  final ValueChanged<_TransactionMarketSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceRaised,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(color: context.colors.neutralOutline),
      ),
      child: Column(
        children: [
          for (var index = 0; index < results.length; index++) ...[
            _TransactionMarketSearchResultTile(
              result: results[index],
              onTap: () => onSelected(results[index]),
            ),
            if (index != results.length - 1)
              Divider(height: 1, color: context.colors.neutralOutline),
          ],
        ],
      ),
    );
  }
}

class _TransactionMarketSearchResultTile extends StatelessWidget {
  const _TransactionMarketSearchResultTile({
    required this.result,
    required this.onTap,
  });

  final _TransactionMarketSearchResult result;
  final VoidCallback onTap;

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

  final _TransactionMarketSearchResult result;

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
      child: _TransactionMarketSearchResultTile(result: result, onTap: () {}),
    );
  }
}

class _TransactionMarketSearchResult {
  const _TransactionMarketSearchResult({
    required this.name,
    required this.symbol,
    required this.assetType,
    required this.currencyCode,
    required this.exchangeCode,
    required this.currentPrice,
    required this.sourceLabel,
    this.aliases = const [],
  });

  factory _TransactionMarketSearchResult.fromHolding(
    HoldingItem holding,
    String assetType,
  ) {
    return _TransactionMarketSearchResult(
      name: holding.name,
      symbol: holding.symbol,
      assetType: assetType,
      currencyCode: holding.currencyCode,
      exchangeCode: holding.exchangeCode,
      currentPrice: holding.currentPrice,
      sourceLabel: '목록',
    );
  }

  final String name;
  final String symbol;
  final String assetType;
  final String currencyCode;
  final String exchangeCode;
  final double currentPrice;
  final String sourceLabel;
  final List<String> aliases;

  bool matches(String normalizedQuery) {
    return name.toUpperCase().contains(normalizedQuery) ||
        symbol.toUpperCase().contains(normalizedQuery) ||
        aliases.any((alias) => alias.toUpperCase().contains(normalizedQuery));
  }

  String get subtitle {
    final exchange = exchangeCode.isEmpty ? currencyCode : exchangeCode;
    return '$symbol · $exchange · $sourceLabel';
  }

  String get priceLabel {
    final rounded = currentPrice % 1 == 0
        ? currentPrice.toStringAsFixed(0)
        : currentPrice.toStringAsFixed(2);
    return currencyCode == 'USD' ? '\$$rounded' : '₩$rounded';
  }
}

class _TransactionMarketLookupCandidate {
  const _TransactionMarketLookupCandidate({
    required this.assetType,
    required this.symbol,
    required this.currencyCode,
    required this.exchangeCode,
  });

  final String assetType;
  final String symbol;
  final String currencyCode;
  final String exchangeCode;
}

const _knownTransactionMarketInstruments = <_TransactionMarketSearchResult>[
  _TransactionMarketSearchResult(
    name: '삼성전자',
    symbol: '005930',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['SAMSUNG'],
  ),
  _TransactionMarketSearchResult(
    name: 'SK하이닉스',
    symbol: '000660',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['HYNIX'],
  ),
  _TransactionMarketSearchResult(
    name: 'NAVER',
    symbol: '035420',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['네이버'],
  ),
  _TransactionMarketSearchResult(
    name: '카카오',
    symbol: '035720',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['KAKAO'],
  ),
  _TransactionMarketSearchResult(
    name: 'Apple',
    symbol: 'AAPL',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['애플'],
  ),
  _TransactionMarketSearchResult(
    name: 'Microsoft',
    symbol: 'MSFT',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['마이크로소프트'],
  ),
  _TransactionMarketSearchResult(
    name: 'NVIDIA',
    symbol: 'NVDA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['엔비디아'],
  ),
  _TransactionMarketSearchResult(
    name: 'Tesla',
    symbol: 'TSLA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['테슬라'],
  ),
  _TransactionMarketSearchResult(
    name: 'Bitcoin',
    symbol: 'BTC',
    assetType: '코인',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['비트코인'],
  ),
  _TransactionMarketSearchResult(
    name: 'Ethereum',
    symbol: 'ETH',
    assetType: '코인',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['이더리움'],
  ),
];
