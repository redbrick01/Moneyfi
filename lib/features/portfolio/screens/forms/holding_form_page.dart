import 'package:moneyfy/components/forms/market_search_field.dart';

import 'package:flutter/material.dart';

import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/utils/input_validators.dart';
import 'package:moneyfy/components/forms/form_design.dart';

class HoldingFormPage extends StatefulWidget {
  const HoldingFormPage({super.key, required this.assetId, this.item});

  final int assetId;
  final HoldingItem? item;

  @override
  State<HoldingFormPage> createState() => _HoldingFormPageState();
}

InputValidationResult<double> validateHoldingQuantityInput(
  String raw, {
  required bool isCashAsset,
}) {
  return MoneyfyInputValidators.decimal(
    raw,
    fieldName: isCashAsset ? '잔액' : '수량',
    allowZero: true,
  );
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
  String? searchMessage;
  AssetItem? _asset;
  MarketSearchResult? _selectedMarketResult;

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
    super.dispose();
  }

  void _selectMarketResult(MarketSearchResult result) {
    setState(() {
      _selectedMarketResult = result;
      searchController.text = '${result.name} (${result.symbol})';
      nameController.text = result.name;
      symbolController.text = result.symbol;
      selectedCurrencyCode = result.currencyCode;
      selectedExchangeCode = result.exchangeCode.isNotEmpty
          ? result.exchangeCode
          : exchangeOptions.keys.first;
      currentPriceController.text = result.currentPrice > 0
          ? _numberInputText(result.currentPrice)
          : '';
      searchMessage = '선택됨: ${result.symbol}';
    });
    FocusScope.of(context).unfocus();
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

    final quantityValidation = validateHoldingQuantityInput(
      quantityController.text,
      isCashAsset: isCashAsset,
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
        final assetType = widget.item?.assetType ?? snapshot.data?.assetType;
        final isCashAsset = assetType == '현금';
        final canSearchMarketItem =
            widget.item == null && assetType != null && !isCashAsset;

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
                        color: context.colors.neutralTextMuted,
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(
                      height: context.spacing.xs + context.spacing.xs / 4,
                    ),
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
                      SizedBox(height: context.spacing.md),
                      Text(
                        '거래소',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.neutralTextMuted,
                          fontWeight: AppFontWeights.semibold,
                        ),
                      ),
                      SizedBox(
                        height: context.spacing.xs + context.spacing.xs / 4,
                      ),
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
                    MarketSearchField<MarketSearchResult>(
                      label: '종목 검색',
                      controller: searchController,
                      message: searchMessage,
                      localSearch: (query) =>
                          searchMarketLocally([?_asset], {assetType}, query),
                      verify: (query, local) async {
                        final result = await verifyMarketSymbol(
                          searchableAssetTypes: {assetType},
                          primaryAssetType: assetType,
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
                          : _SelectedMarketResultView(
                              result: _selectedMarketResult!,
                            ),
                      onEdited: () {
                        if (_selectedMarketResult == null) return;
                        setState(() {
                          _selectedMarketResult = null;
                          searchMessage = null;
                        });
                      },
                      onSelected: _selectMarketResult,
                    ),
                    SizedBox(height: context.spacing.xs / 2),
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

class _SelectedMarketResultView extends StatelessWidget {
  const _SelectedMarketResultView({required this.result});

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
