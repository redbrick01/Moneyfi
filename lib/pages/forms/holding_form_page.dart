import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/asset_data.dart';
import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/market_data_service.dart';
import '../../services/sync_service.dart';
import '../../theme/moneyfy_theme.dart';
import '../../utils/input_validators.dart';
import 'form_design.dart';

class HoldingFormPage extends StatefulWidget {
  const HoldingFormPage({super.key, required this.assetId, this.item});

  final int assetId;
  final HoldingItem? item;

  @override
  State<HoldingFormPage> createState() => _HoldingFormPageState();
}

class _HoldingFormPageState extends State<HoldingFormPage> {
  static const currencyOptions = <String>['KRW', 'USD'];
  static const exchangeOptions = <String, String>{
    'NAS': 'NASDAQ',
    'NYS': 'NYSE',
    'AMS': 'AMEX',
  };

  late final Future<AssetItem?> _assetFuture;
  late final TextEditingController nameController;
  late final TextEditingController symbolController;
  late final TextEditingController quantityController;
  late final TextEditingController averagePriceController;
  late final TextEditingController currentPriceController;
  late final TextEditingController noteController;
  late final TextEditingController searchController;
  late String selectedCurrencyCode;
  late String selectedExchangeCode;
  bool isSaving = false;
  bool isSearching = false;
  String? searchMessage;
  AssetItem? _asset;
  Timer? _searchDebounce;
  int _searchGeneration = 0;
  List<_MarketSearchResult> _searchResults = const [];
  _MarketSearchResult? _selectedMarketResult;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    nameController = TextEditingController(text: item?.name ?? '');
    symbolController = TextEditingController(text: item?.symbol ?? '');
    quantityController = TextEditingController(
      text: item == null ? '' : item.quantity.toString(),
    );
    averagePriceController = TextEditingController(
      text: item == null ? '' : item.averagePrice.toString(),
    );
    currentPriceController = TextEditingController(
      text: item == null ? '' : item.currentPrice.toString(),
    );
    noteController = TextEditingController(text: item?.note ?? '');
    searchController = TextEditingController();
    selectedCurrencyCode = item?.currencyCode ?? currencyOptions.first;
    selectedExchangeCode = item?.exchangeCode.isNotEmpty == true
        ? item!.exchangeCode
        : exchangeOptions.keys.first;
    _assetFuture = AppDatabase.instance.fetchAssetById(widget.assetId);
    _assetFuture.then((asset) {
      if (!mounted) return;
      setState(() {
        _asset = asset;
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    symbolController.dispose();
    quantityController.dispose();
    averagePriceController.dispose();
    currentPriceController.dispose();
    noteController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _queueMarketSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchMarketItems(query);
    });
  }

  Future<void> _searchMarketItems(String rawQuery) async {
    final assetType = widget.item?.assetType ?? _asset?.assetType;
    final query = rawQuery.trim();
    if (assetType == null || assetType == '현금') return;
    if (query.isEmpty) {
      setState(() {
        _searchResults = const [];
        _selectedMarketResult = null;
        searchMessage = null;
      });
      return;
    }

    final generation = ++_searchGeneration;
    final localResults = _localMarketSearch(assetType, query);
    setState(() {
      isSearching = true;
      searchMessage = null;
      _searchResults = localResults;
      _selectedMarketResult = null;
    });

    final inferredCurrency = _inferCurrencyCode(assetType, query);
    final inferredExchange = inferredCurrency == 'USD'
        ? _inferExchangeCode(query)
        : '';
    final symbol = _normalizeSymbol(query, assetType, inferredCurrency);
    final lookupHolding = HoldingItem(
      assetTitle: query,
      assetType: assetType,
      currencyCode: inferredCurrency,
      exchangeCode: inferredExchange,
      name: query,
      symbol: symbol,
      quantity: 0,
      averagePrice: 0,
      currentPrice: -1,
      note: '',
      transactions: const [],
    );

    try {
      final snapshot = await MarketDataService.instance.fetchSnapshot(
        lookupHolding,
        includeFundComponents: false,
      );
      final currentPrice = snapshot.currentPriceValue;
      final isVerified = currentPrice != null && currentPrice >= 0;

      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        if (isVerified) {
          _MarketSearchResult? matchedLocal;
          for (final result in localResults) {
            if (result.symbol == symbol &&
                result.currencyCode == inferredCurrency) {
              matchedLocal = result;
              break;
            }
          }
          final apiResult = _MarketSearchResult(
            name: matchedLocal?.name ?? query,
            symbol: symbol,
            assetType: assetType,
            currencyCode: inferredCurrency,
            exchangeCode: inferredExchange,
            currentPrice: currentPrice,
            sourceLabel: 'API',
            aliases: matchedLocal?.aliases ?? const [],
          );
          _searchResults = _mergeSearchResults(apiResult, localResults);
          searchMessage = null;
        } else {
          searchMessage = localResults.isEmpty ? '연관 종목이 없습니다.' : null;
        }
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        searchMessage = localResults.isEmpty ? '연관 종목이 없습니다.' : null;
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void _selectMarketResult(_MarketSearchResult result) {
    setState(() {
      _selectedMarketResult = result;
      _searchResults = const [];
      searchController.text = '${result.name} (${result.symbol})';
      nameController.text = result.name;
      symbolController.text = result.symbol;
      selectedCurrencyCode = result.currencyCode;
      selectedExchangeCode = result.exchangeCode.isNotEmpty
          ? result.exchangeCode
          : exchangeOptions.keys.first;
      currentPriceController.text = _numberInputText(result.currentPrice);
      searchMessage = '선택됨: ${result.symbol}';
    });
    FocusScope.of(context).unfocus();
  }

  List<_MarketSearchResult> _localMarketSearch(String assetType, String query) {
    final normalizedQuery = query.trim().toUpperCase();
    if (normalizedQuery.isEmpty) return const [];

    final results = <_MarketSearchResult>[];
    final seen = <String>{};

    for (final instrument in _knownMarketInstruments) {
      if (instrument.assetType != assetType) continue;
      if (!instrument.matches(normalizedQuery)) continue;
      final key = '${instrument.currencyCode}:${instrument.symbol}';
      if (seen.add(key)) results.add(instrument);
    }

    for (final asset in assetItems) {
      if (asset.assetType != assetType) continue;
      for (final holding in asset.holdings) {
        final result = _MarketSearchResult.fromHolding(holding, assetType);
        if (!result.matches(normalizedQuery)) continue;
        final key = '${result.currencyCode}:${result.symbol}';
        if (seen.add(key)) results.add(result);
      }
    }

    return results.take(8).toList(growable: false);
  }

  List<_MarketSearchResult> _mergeSearchResults(
    _MarketSearchResult apiResult,
    List<_MarketSearchResult> localResults,
  ) {
    return [
      apiResult,
      ...localResults.where(
        (result) =>
            result.symbol != apiResult.symbol ||
            result.currencyCode != apiResult.currencyCode,
      ),
    ].take(8).toList(growable: false);
  }

  String _inferCurrencyCode(String assetType, String query) {
    if (assetType == '코인') return 'KRW';
    final normalized = query.trim().toUpperCase();
    final known = _knownMarketInstruments.where(
      (instrument) =>
          instrument.assetType == assetType && instrument.matches(normalized),
    );
    if (known.isNotEmpty) return known.first.currencyCode;
    return RegExp(r'^\d+$').hasMatch(normalized) ? 'KRW' : 'USD';
  }

  String _inferExchangeCode(String query) {
    final normalized = query.trim().toUpperCase();
    final known = _knownMarketInstruments.where(
      (instrument) => instrument.matches(normalized),
    );
    if (known.isNotEmpty && known.first.exchangeCode.isNotEmpty) {
      return known.first.exchangeCode;
    }
    return exchangeOptions.keys.first;
  }

  String _normalizeSymbol(String query, String assetType, String currencyCode) {
    final normalized = query.trim().toUpperCase();
    final known = _knownMarketInstruments.where(
      (instrument) =>
          instrument.assetType == assetType && instrument.matches(normalized),
    );
    if (known.isNotEmpty) return known.first.symbol;
    if (currencyCode == 'KRW' && assetType != '코인') return query.trim();
    return normalized;
  }

  String _numberInputText(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  Future<void> _save() async {
    if (isSaving) return;
    if (widget.item == null &&
        _asset?.assetType != '현금' &&
        _selectedMarketResult == null) {
      setState(() {
        searchMessage = '드롭다운에서 종목을 선택해 주세요.';
      });
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

    final isCashAsset =
        _asset?.assetType == '현금' || widget.item?.assetType == '현금';
    final canSearchMarketItem = widget.item == null && !isCashAsset;
    InputValidationResult<String>? symbolValidation;
    if (!isCashAsset) {
      symbolValidation = MoneyfyInputValidators.symbol(symbolController.text);
      if (!symbolValidation.isValid) {
        _showValidationMessage(symbolValidation.message!);
        return;
      }
    }

    final quantityValidation = MoneyfyInputValidators.decimal(
      quantityController.text,
      fieldName: isCashAsset ? '잔액' : '수량',
      allowZero: isCashAsset,
    );
    if (!quantityValidation.isValid) {
      _showValidationMessage(quantityValidation.message!);
      return;
    }

    final averagePriceValidation = MoneyfyInputValidators.decimal(
      averagePriceController.text,
      fieldName: '평단',
      allowZero: true,
    );
    if (!isCashAsset && !averagePriceValidation.isValid) {
      _showValidationMessage(averagePriceValidation.message!);
      return;
    }

    final currentPriceValidation = MoneyfyInputValidators.decimal(
      currentPriceController.text,
      fieldName: '현재가',
      allowZero: true,
    );
    if (!isCashAsset &&
        !canSearchMarketItem &&
        !currentPriceValidation.isValid) {
      _showValidationMessage(currentPriceValidation.message!);
      return;
    }

    setState(() {
      isSaving = true;
    });

    final quantity = quantityValidation.value!;
    final averagePrice = isCashAsset ? quantity : averagePriceValidation.value!;
    final currentPrice = isCashAsset
        ? quantity
        : canSearchMarketItem
        ? (double.tryParse(currentPriceController.text.trim()) ?? averagePrice)
        : currentPriceValidation.value!;
    final item = widget.item;

    if (item == null) {
      await AppDatabase.instance.createHolding(
        assetId: widget.assetId,
        currencyCode: selectedCurrencyCode,
        exchangeCode: selectedCurrencyCode == 'USD' ? selectedExchangeCode : '',
        name: nameValidation.value!,
        symbol: symbolValidation?.value ?? symbolController.text.trim(),
        quantity: quantity,
        averagePrice: averagePrice,
        currentPrice: currentPrice,
        note: noteController.text.trim(),
      );
    } else {
      final currentItem = item.id == null
          ? null
          : await AppDatabase.instance.fetchHoldingById(item.id!);
      final fallbackItem =
          currentItem ??
          (item.clientId == null
              ? null
              : await AppDatabase.instance.fetchHoldingByClientId(
                  item.clientId!,
                ));
      final itemId = fallbackItem?.id ?? item.id;
      if (itemId == null) {
        throw StateError('보유 종목 정보를 찾을 수 없습니다.');
      }
      await AppDatabase.instance.updateHoldingItem(
        HoldingItem(
          id: itemId,
          clientId: fallbackItem?.clientId ?? item.clientId,
          assetId: fallbackItem?.assetId ?? item.assetId,
          assetTitle: fallbackItem?.assetTitle ?? item.assetTitle,
          assetType: fallbackItem?.assetType ?? item.assetType,
          isHidden: fallbackItem?.isHidden ?? item.isHidden,
          currencyCode: selectedCurrencyCode,
          exchangeCode: selectedCurrencyCode == 'USD'
              ? selectedExchangeCode
              : '',
          name: nameValidation.value!,
          symbol: symbolValidation?.value ?? symbolController.text.trim(),
          quantity: quantity,
          averagePrice: averagePrice,
          currentPrice: currentPrice,
          note: noteController.text.trim(),
          transactions: fallbackItem?.transactions ?? item.transactions,
        ),
      );
    }

    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'holding_form_save');
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetItem?>(
      future: _assetFuture,
      builder: (context, snapshot) {
        final isCashAsset =
            widget.item?.assetType == '현금' || snapshot.data?.assetType == '현금';
        final canSearchMarketItem = widget.item == null && !isCashAsset;

        return MoneyfyFormScaffold(
          title: widget.item == null ? '보유 항목 추가' : '보유 항목 수정',
          actionLabel: '저장',
          isSaving: isSaving,
          onSave: _save,
          children: [
            if (!canSearchMarketItem)
              MoneyfyFormSection(
                title: '시장 설정',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '통화',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    MoneyfyChoiceWrap<String>(
                      options: currencyOptions,
                      value: selectedCurrencyCode,
                      labelBuilder: (currencyCode) => currencyCode,
                      onChanged: (currencyCode) {
                        setState(() {
                          selectedCurrencyCode = currencyCode;
                        });
                      },
                    ),
                    if (!isCashAsset && selectedCurrencyCode == 'USD') ...[
                      const SizedBox(height: 16),
                      Text(
                        '거래소',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MoneyfyPalette.tertiaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MoneyfyChoiceWrap<String>(
                        options: exchangeOptions.keys.toList(growable: false),
                        value: selectedExchangeCode,
                        labelBuilder: (exchangeCode) =>
                            exchangeOptions[exchangeCode]!,
                        onChanged: (exchangeCode) {
                          setState(() {
                            selectedExchangeCode = exchangeCode;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            MoneyfyFormSection(
              title: canSearchMarketItem ? '종목 선택' : '기본 정보',
              child: Column(
                children: [
                  if (canSearchMarketItem) ...[
                    _MarketItemSearchField(
                      controller: searchController,
                      isSearching: isSearching,
                      results: _searchResults,
                      selectedResult: _selectedMarketResult,
                      message: searchMessage,
                      onChanged: _queueMarketSearch,
                      onResultSelected: _selectMarketResult,
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (!canSearchMarketItem)
                    MoneyfyFormField(label: '이름', controller: nameController),
                  if (canSearchMarketItem) ...[
                    MoneyfyFormField(
                      label: '수량',
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    MoneyfyFormField(
                      label: '평단',
                      controller: averagePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ] else if (!isCashAsset) ...[
                    MoneyfyFormField(
                      label: '종목 코드',
                      controller: symbolController,
                    ),
                    MoneyfyFormField(
                      label: '수량',
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    MoneyfyFormField(
                      label: '평단',
                      controller: averagePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    MoneyfyFormField(
                      label: '현재가',
                      controller: currentPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ] else
                    MoneyfyFormField(
                      label: '잔액',
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  if (!canSearchMarketItem)
                    MoneyfyFormField(
                      label: '메모',
                      controller: noteController,
                      maxLines: 4,
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

class _MarketItemSearchField extends StatelessWidget {
  const _MarketItemSearchField({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.onChanged,
    required this.onResultSelected,
    this.selectedResult,
    this.message,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<_MarketSearchResult> results;
  final _MarketSearchResult? selectedResult;
  final ValueChanged<String> onChanged;
  final ValueChanged<_MarketSearchResult> onResultSelected;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '종목 검색',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    onChanged(controller.text);
                  },
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: '예: 005930, AAPL, BTC',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                    filled: true,
                    fillColor: MoneyfyPalette.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: MoneyfyPalette.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: MoneyfyPalette.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: MoneyfyPalette.accent,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    backgroundColor: MoneyfyPalette.ink,
                    foregroundColor: MoneyfyPalette.background,
                    disabledBackgroundColor: MoneyfyPalette.surfaceMuted,
                    disabledForegroundColor: MoneyfyPalette.tertiaryText,
                    fixedSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MarketSearchDropdown(
              results: results,
              onSelected: onResultSelected,
            ),
          ] else if (selectedResult != null) ...[
            const SizedBox(height: 8),
            _SelectedMarketResultView(result: selectedResult!),
          ],
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: message!.startsWith('선택됨')
                    ? MoneyfyPalette.primary
                    : MoneyfyPalette.tertiaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarketSearchDropdown extends StatelessWidget {
  const _MarketSearchDropdown({
    required this.results,
    required this.onSelected,
  });

  final List<_MarketSearchResult> results;
  final ValueChanged<_MarketSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoneyfyPalette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < results.length; index++) ...[
            _MarketSearchResultTile(
              result: results[index],
              onTap: () => onSelected(results[index]),
            ),
            if (index != results.length - 1)
              const Divider(height: 1, color: MoneyfyPalette.border),
          ],
        ],
      ),
    );
  }
}

class _MarketSearchResultTile extends StatelessWidget {
  const _MarketSearchResultTile({required this.result, required this.onTap});

  final _MarketSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    result.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              result.priceLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MoneyfyPalette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMarketResultView extends StatelessWidget {
  const _SelectedMarketResultView({required this.result});

  final _MarketSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoneyfyPalette.accentSoft),
      ),
      child: _MarketSearchResultTile(result: result, onTap: () {}),
    );
  }
}

class _MarketSearchResult {
  const _MarketSearchResult({
    required this.name,
    required this.symbol,
    required this.assetType,
    required this.currencyCode,
    required this.exchangeCode,
    required this.currentPrice,
    required this.sourceLabel,
    this.aliases = const [],
  });

  factory _MarketSearchResult.fromHolding(
    HoldingItem holding,
    String assetType,
  ) {
    return _MarketSearchResult(
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

const _knownMarketInstruments = <_MarketSearchResult>[
  _MarketSearchResult(
    name: '삼성전자',
    symbol: '005930',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['SAMSUNG'],
  ),
  _MarketSearchResult(
    name: 'SK하이닉스',
    symbol: '000660',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['HYNIX'],
  ),
  _MarketSearchResult(
    name: 'NAVER',
    symbol: '035420',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['네이버'],
  ),
  _MarketSearchResult(
    name: '카카오',
    symbol: '035720',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['KAKAO'],
  ),
  _MarketSearchResult(
    name: 'Apple',
    symbol: 'AAPL',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['애플'],
  ),
  _MarketSearchResult(
    name: 'Microsoft',
    symbol: 'MSFT',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['마이크로소프트'],
  ),
  _MarketSearchResult(
    name: 'NVIDIA',
    symbol: 'NVDA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['엔비디아'],
  ),
  _MarketSearchResult(
    name: 'Tesla',
    symbol: 'TSLA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['테슬라'],
  ),
  _MarketSearchResult(
    name: 'Bitcoin',
    symbol: 'BTC',
    assetType: '코인',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['비트코인'],
  ),
  _MarketSearchResult(
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
