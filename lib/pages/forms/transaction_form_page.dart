import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/sync_service.dart';
import '../../theme/moneyfy_theme.dart';
import '../../utils/display_currency.dart';
import '../../utils/input_validators.dart';
import 'form_design.dart';

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
  });

  final int assetId;
  final int holdingId;
  final String? holdingClientId;
  final TransactionItem? item;
  final String? defaultName;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  late final Future<AssetItem?> _assetFuture;
  late final TextEditingController dateController;
  late final TextEditingController typeController;
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController quantityController;
  late int selectedHoldingId;
  late bool includeInCalculations;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    dateController = TextEditingController(text: item?.date ?? _todayText());
    typeController = TextEditingController(text: item?.type ?? '매수');
    nameController = TextEditingController(
      text: item?.name ?? widget.defaultName ?? '',
    );
    amountController = TextEditingController(text: item?.amount ?? '');
    quantityController = TextEditingController(text: item?.quantity ?? '');
    amountController.addListener(_handlePreviewInputChanged);
    quantityController.addListener(_handlePreviewInputChanged);
    selectedHoldingId = item?.holdingId ?? widget.holdingId;
    includeInCalculations = item?.includeInCalculations ?? false;
    _assetFuture = AppDatabase.instance.fetchAssetById(widget.assetId);
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
    amountController.dispose();
    quantityController.dispose();
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

    setState(() {
      isSaving = true;
    });

    try {
      final item = widget.item;
      final currentHoldingId = await _resolveCurrentHoldingId();
      if (item == null) {
        await AppDatabase.instance.createTransaction(
          assetId: widget.assetId,
          holdingId: currentHoldingId,
          date: dateValidation.value!,
          type: transactionType,
          name: nameValidation.value!,
          amount: amountText,
          quantity: quantityText,
          includeInCalculations: includeInCalculations,
        );
      } else {
        await AppDatabase.instance.updateTransactionItem(
          TransactionItem(
            id: item.id,
            clientId: item.clientId,
            assetId: widget.assetId,
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
            realizedProfitAmount: item.realizedProfitAmount,
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

  String _transactionAmountPreview(AssetItem? asset) {
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

    final holding = _currentHolding(asset);
    return MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      totalAmount,
      sourceCurrency: holding?.currencyCode ?? asset?.currencyCode ?? 'KRW',
      exchangeRate: holding?.exchangeRate ?? 1,
    );
  }

  double? _parseFormNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  HoldingItem? _currentHolding(AssetItem? asset) {
    if (asset == null) return null;
    for (final holding in asset.holdings) {
      if (holding.id == selectedHoldingId) return holding;
    }
    final clientId = widget.holdingClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      for (final holding in asset.holdings) {
        if (holding.clientId == clientId) return holding;
      }
    }
    return asset.holdings.isEmpty ? null : asset.holdings.first;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<int> _resolveCurrentHoldingId() async {
    final selectedById = await AppDatabase.instance.fetchHoldingById(
      selectedHoldingId,
    );
    if (selectedById?.id != null) return selectedById!.id!;

    final holdingById = await AppDatabase.instance.fetchHoldingById(
      widget.holdingId,
    );
    if (holdingById?.id != null) return holdingById!.id!;

    final clientId = widget.holdingClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      final holdingByClientId = await AppDatabase.instance
          .fetchHoldingByClientId(clientId);
      if (holdingByClientId?.id != null) return holdingByClientId!.id!;
    }

    throw StateError('보유 종목 정보를 찾을 수 없습니다.');
  }

  List<MoneyfySelectionOption<int>> _holdingOptions(AssetItem? asset) {
    if (asset == null) return const [];
    return asset.holdings
        .where((holding) => !holding.isCashLike && holding.id != null)
        .map(
          (holding) => MoneyfySelectionOption<int>(
            value: holding.id!,
            title: holding.name,
            subtitle: [
              if (holding.symbol.trim().isNotEmpty) holding.symbol,
              holding.currencyCode,
              holding.quantityMetricValue,
            ].join(' · '),
            meta: holding.currencyCode,
          ),
        )
        .toList(growable: false);
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
    return FutureBuilder<AssetItem?>(
      future: _assetFuture,
      builder: (context, snapshot) {
        final isCashAsset = snapshot.data?.assetType == '현금';
        final transactionType = typeController.text.trim();
        final requiresQuantity =
            transactionType == '매수' || transactionType == '매도';
        final ledgerCopy = _ledgerCopyFor(transactionType);
        final holdingOptions = _holdingOptions(snapshot.data);
        final currentHolding = _currentHolding(snapshot.data);

        return MoneyfyFormScaffold(
          title: widget.item == null ? '거래 추가' : '거래 수정',
          actionLabel: '저장',
          isSaving: isSaving,
          onSave: _save,
          children: [
            MoneyfyFormSection(
              title: '원장 이벤트',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거래 유형',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 14),
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
              child: MoneyfySelectionField<int>(
                label: '보유 종목',
                options: holdingOptions,
                value: currentHolding?.id ?? selectedHoldingId,
                placeholder: '보유 종목 선택',
                onChanged: (value) {
                  setState(() {
                    selectedHoldingId = value;
                  });
                },
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
                  if (!isCashAsset && requiresQuantity)
                    MoneyfyFormField(
                      label: ledgerCopy.quantityLabel,
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        value: currentHolding?.name ?? '보유 종목 선택',
                      ),
                      MoneyfyLedgerPreviewRow(
                        label: '거래금액',
                        value: _transactionAmountPreview(snapshot.data),
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
