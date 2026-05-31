import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/sync_service.dart';
import '../../utils/display_currency.dart';
import '../../utils/input_validators.dart';
import 'form_design.dart';

const _cashTransactionTypes = ['입금', '출금', '환전', '이체'];

class _CashLedgerCopy {
  const _CashLedgerCopy({required this.amountLabel});

  final String amountLabel;
}

class CashTransactionFormPage extends StatefulWidget {
  const CashTransactionFormPage({
    super.key,
    required this.assetId,
    required this.holdingId,
    this.holdingClientId,
    this.item,
    this.defaultName,
    this.assetsFutureForTesting,
  });

  final int assetId;
  final int holdingId;
  final String? holdingClientId;
  final TransactionItem? item;
  final String? defaultName;
  final Future<List<AssetItem>>? assetsFutureForTesting;

  @override
  State<CashTransactionFormPage> createState() =>
      _CashTransactionFormPageState();
}

class _CashTransactionFormPageState extends State<CashTransactionFormPage> {
  late final TextEditingController dateController;
  late final TextEditingController typeController;
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController exchangeRateController;
  List<_CashAccountOption> cashAccountOptions = const [];
  late int selectedSourceHoldingId;
  int? selectedTransferTargetHoldingId;
  String sourceCurrencyCode = 'KRW';
  double sourceExchangeRate = 1;
  late bool includeInCalculations;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    dateController = TextEditingController(text: item?.date ?? _todayText());
    typeController = TextEditingController(text: item?.type ?? '입금');
    nameController = TextEditingController(
      text: item?.name ?? widget.defaultName ?? '',
    );
    amountController = TextEditingController(text: item?.amount ?? '');
    exchangeRateController = TextEditingController();
    amountController.addListener(_handlePreviewInputChanged);
    selectedSourceHoldingId = item?.holdingId ?? widget.holdingId;
    includeInCalculations = item?.includeInCalculations ?? true;
    _loadCashAccountOptions();
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
    amountController.dispose();
    exchangeRateController.dispose();
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
      fieldName: '금액',
      allowZero: false,
    );
    if (!amountValidation.isValid) {
      _showValidationMessage(amountValidation.message!);
      return;
    }

    if (includeInCalculations &&
        transactionType == '이체' &&
        selectedTransferTargetHoldingId == null) {
      _showValidationMessage('이체할 현금 계좌를 선택해 주세요.');
      return;
    }

    InputValidationResult<double>? exchangeRateValidation;
    if (includeInCalculations && transactionType == '환전') {
      exchangeRateValidation = MoneyfyInputValidators.decimal(
        exchangeRateController.text,
        fieldName: '환율',
        allowZero: false,
      );
      if (!exchangeRateValidation.isValid) {
        _showValidationMessage(exchangeRateValidation.message!);
        return;
      }
    }

    final amountText = _numberText(amountValidation.value!);
    final exchangeRateText = exchangeRateValidation == null
        ? ''
        : _numberText(exchangeRateValidation.value!);

    if (dateController.text.trim() != dateValidation.value ||
        nameController.text.trim() != nameValidation.value ||
        amountController.text.trim() != amountText ||
        (exchangeRateValidation != null &&
            exchangeRateController.text.trim() != exchangeRateText)) {
      setState(() {
        dateController.text = dateValidation.value!;
        nameController.text = nameValidation.value!;
        amountController.text = amountText;
        if (exchangeRateValidation != null) {
          exchangeRateController.text = exchangeRateText;
        }
      });
    }

    setState(() {
      isSaving = true;
    });

    try {
      final currentSourceOption = _selectedSourceOption;
      final currentHoldingId = await _resolveCurrentHoldingId();
      final currentAssetId = currentSourceOption?.assetId ?? widget.assetId;
      final item = widget.item;
      if (!includeInCalculations && item == null) {
        await AppDatabase.instance.createTransaction(
          assetId: currentAssetId,
          holdingId: currentHoldingId,
          date: dateValidation.value!,
          type: transactionType,
          name: nameValidation.value!,
          amount: amountText,
          quantity: '',
          includeInCalculations: false,
        );
      } else if (item == null && transactionType == '이체') {
        await AppDatabase.instance.createCashTransfer(
          assetId: currentAssetId,
          sourceHoldingId: currentHoldingId,
          targetHoldingId: selectedTransferTargetHoldingId!,
          date: dateValidation.value!,
          name: nameValidation.value!,
          amount: amountText,
        );
      } else if (item == null && transactionType == '환전') {
        await AppDatabase.instance.createCashExchange(
          assetId: currentAssetId,
          sourceHoldingId: currentHoldingId,
          date: dateValidation.value!,
          name: nameValidation.value!,
          amount: amountText,
          exchangeRate: exchangeRateValidation!.value!,
        );
      } else if (item == null) {
        await AppDatabase.instance.createTransaction(
          assetId: currentAssetId,
          holdingId: currentHoldingId,
          date: dateValidation.value!,
          type: transactionType,
          name: nameValidation.value!,
          amount: amountText,
          quantity: '',
          includeInCalculations: includeInCalculations,
        );
      } else {
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
            quantity: transactionType == '환전' ? exchangeRateText : '',
            counterpartyHoldingId: transactionType == '이체'
                ? selectedTransferTargetHoldingId
                : null,
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
        await SyncService.instance.syncNow(
          reason: 'cash_transaction_form_save',
        );
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

  String _numberText(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  String _amountShortcutText(double value) {
    final safeValue = value <= 0 ? 0.0 : (value * 1000).floorToDouble() / 1000;
    return _numberText(safeValue);
  }

  String _cashTransactionAmountPreview() {
    final amount = _parseFormNumber(amountController.text);
    if (amount == null || amount <= 0) return '-';
    return MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      amount,
      sourceCurrency: sourceCurrencyCode,
      exchangeRate: sourceExchangeRate,
    );
  }

  double? _parseFormNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  double _cashShortcutAvailableBalance() {
    final sourceOption = _selectedSourceOption;
    if (sourceOption == null) return 0;
    var balance = sourceOption.balance;
    final item = widget.item;
    if (item == null || !item.includeInCalculations) {
      return balance <= 0 ? 0 : balance;
    }
    if (item.holdingId != sourceOption.holdingId) {
      return balance <= 0 ? 0 : balance;
    }
    final existingAmount = _parseFormNumber(item.amount)?.abs() ?? 0;
    switch (item.type.trim()) {
      case '출금':
      case 'withdraw':
      case 'withdrawal':
      case '이체':
      case 'transfer':
      case '환전':
      case 'exchange':
        balance += existingAmount;
        break;
      case '입금':
      case 'deposit':
        balance -= existingAmount;
        break;
    }
    return balance <= 0 ? 0 : balance;
  }

  void _applyCashAmountRatio(double availableBalance, double ratio) {
    final selectedAmount = ratio >= 1
        ? availableBalance
        : availableBalance * ratio;
    setState(() {
      amountController.text = _amountShortcutText(selectedAmount);
    });
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<int> _resolveCurrentHoldingId() async {
    final selectedById = await AppDatabase.instance.fetchHoldingById(
      selectedSourceHoldingId,
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

    throw StateError('현금 계좌를 찾을 수 없습니다.');
  }

  Future<void> _loadCashAccountOptions() async {
    HoldingItem? loadedSourceHolding;
    final clientId = widget.holdingClientId;
    if (widget.assetsFutureForTesting == null) {
      loadedSourceHolding = await AppDatabase.instance.fetchHoldingById(
        widget.holdingId,
      );
      if (loadedSourceHolding == null &&
          clientId != null &&
          clientId.trim().isNotEmpty) {
        loadedSourceHolding = await AppDatabase.instance.fetchHoldingByClientId(
          clientId,
        );
      }
    }
    final assets = widget.assetsFutureForTesting == null
        ? await AppDatabase.instance.fetchAssets()
        : await widget.assetsFutureForTesting!;
    final options = assets
        .expand(
          (asset) => asset.holdings
              .where((holding) => (holding.id ?? 0) < 0)
              .map(
                (holding) => _CashAccountOption(
                  assetId: holding.assetId ?? asset.id ?? widget.assetId,
                  holdingId: holding.id!,
                  title: '${asset.alias} · ${holding.name}',
                  subtitle: holding.currencyCode,
                  currencyCode: holding.currencyCode,
                  exchangeRate: holding.exchangeRate,
                  balance: holding.quantity,
                ),
              ),
        )
        .toList(growable: false);

    var initialSourceSelection = loadedSourceHolding?.id ?? widget.holdingId;
    int? initialSelection;
    if (widget.item != null && widget.item!.id != null) {
      if (widget.item!.type.trim() == '이체') {
        initialSourceSelection =
            await AppDatabase.instance.fetchLinkedCashTransferSourceHoldingId(
              widget.item!.id!.abs(),
            ) ??
            initialSourceSelection;
        initialSelection = await AppDatabase.instance
            .fetchLinkedCashTransferCounterpartyHoldingId(
              widget.item!.id!.abs(),
            );
      }
      if (widget.item!.type.trim() == '환전') {
        final exchangeRate = await AppDatabase.instance
            .fetchLinkedCashExchangeRate(widget.item!.id!.abs());
        if (exchangeRate != null && exchangeRate > 0) {
          exchangeRateController.text = exchangeRate.toString();
        }
      }
    }
    final sourceOption = options.where(
      (option) => option.holdingId == initialSourceSelection,
    );
    final sourceCurrencyCodeFromOption = sourceOption.isEmpty
        ? loadedSourceHolding?.currencyCode ?? 'KRW'
        : sourceOption.first.currencyCode;
    final sourceExchangeRateFromOption = sourceOption.isEmpty
        ? loadedSourceHolding?.exchangeRate ?? 1
        : sourceOption.first.exchangeRate;

    if (!mounted) return;
    setState(() {
      cashAccountOptions = options;
      selectedSourceHoldingId = initialSourceSelection;
      selectedTransferTargetHoldingId = initialSelection;
      sourceCurrencyCode = sourceCurrencyCodeFromOption;
      sourceExchangeRate = sourceExchangeRateFromOption;
      if (initialSelection != null) {
        typeController.text = '이체';
      }
    });
  }

  _CashAccountOption? get _selectedSourceOption {
    for (final option in cashAccountOptions) {
      if (option.holdingId == selectedSourceHoldingId) return option;
    }
    return null;
  }

  List<MoneyfySelectionOption<int>> _sourceAccountOptions() {
    return cashAccountOptions
        .map(
          (option) => MoneyfySelectionOption<int>(
            value: option.holdingId,
            title: option.title,
            subtitle: _formatCashAccountSubtitle(option),
            meta: option.currencyCode,
          ),
        )
        .toList(growable: false);
  }

  List<MoneyfySelectionOption<int>> _transferTargetOptions() {
    final sourceOption = _selectedSourceOption;
    return cashAccountOptions
        .where(
          (option) =>
              option.holdingId != selectedSourceHoldingId &&
              (sourceOption == null ||
                  option.currencyCode == sourceOption.currencyCode),
        )
        .map(
          (option) => MoneyfySelectionOption<int>(
            value: option.holdingId,
            title: option.title,
            subtitle: _formatCashAccountSubtitle(option),
            meta: option.currencyCode,
          ),
        )
        .toList(growable: false);
  }

  String _formatCashAccountSubtitle(_CashAccountOption option) {
    final balanceText = MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      option.balance,
      sourceCurrency: option.currencyCode,
      exchangeRate: option.exchangeRate,
    );
    return '${option.currencyCode} · $balanceText';
  }

  void _selectSourceHolding(int value) {
    final selectedOption = cashAccountOptions.firstWhere(
      (option) => option.holdingId == value,
      orElse: () => _CashAccountOption.empty(value),
    );
    final nextTargets = cashAccountOptions
        .where(
          (option) =>
              option.holdingId != value &&
              option.currencyCode == selectedOption.currencyCode,
        )
        .map((option) => option.holdingId)
        .toSet();
    setState(() {
      selectedSourceHoldingId = value;
      sourceCurrencyCode = selectedOption.currencyCode;
      sourceExchangeRate = selectedOption.exchangeRate;
      if (!nextTargets.contains(selectedTransferTargetHoldingId)) {
        selectedTransferTargetHoldingId = null;
      }
    });
  }

  String _cashLineActionLabel(String type) {
    return switch (type) {
      '입금' => 'deposit',
      '출금' => 'withdrawal',
      '이체' => 'transfer_out / transfer_in',
      '환전' => 'fx_out / fx_in',
      _ => 'adjustment',
    };
  }

  String _cashEventKindLabel(String type) {
    return switch (type) {
      '입금' || '출금' => 'cash_flow',
      '이체' => 'cash_transfer',
      '환전' => 'fx_exchange',
      _ => 'adjustment',
    };
  }

  _CashLedgerCopy _ledgerCopyFor(String type) {
    return switch (type) {
      '입금' => const _CashLedgerCopy(amountLabel: '입금 금액'),
      '출금' => const _CashLedgerCopy(amountLabel: '출금 금액'),
      '이체' => const _CashLedgerCopy(amountLabel: '이체 금액'),
      '환전' => const _CashLedgerCopy(amountLabel: '환전할 원천 금액'),
      _ => const _CashLedgerCopy(amountLabel: '금액'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = typeController.text.trim();
    final ledgerCopy = _ledgerCopyFor(transactionType);
    final sourceOptions = _sourceAccountOptions();
    final targetOptions = _transferTargetOptions();
    final sourceOption = _selectedSourceOption;
    final shortcutBalance = switch (transactionType) {
      '출금' || '이체' || '환전' => _cashShortcutAvailableBalance(),
      _ => 0.0,
    };

    return MoneyfyFormScaffold(
      title: widget.item == null ? '현금 거래 추가' : '현금 거래 수정',
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
                  color: context.colors.neutralTextMuted,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
              MoneyfyChoiceWrap<String>(
                options: _cashTransactionTypes,
                value: typeController.text.trim(),
                labelBuilder: (type) => type,
                onChanged: (value) {
                  setState(() {
                    typeController.text = value;
                    if (value != '이체') {
                      selectedTransferTargetHoldingId = null;
                    }
                  });
                },
              ),
              SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
              _CashCalculationToggle(
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
          title: '대상 계좌',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '입금, 출금, 이체, 환전을 기록할 현금 계좌를 선택해 주세요.',
                style: context.typography.meta,
              ),
              SizedBox(height: context.spacing.sm),
              MoneyfySelectionField<int>(
                label: transactionType == '이체' || transactionType == '환전'
                    ? '원천 현금 계좌'
                    : '현금 계좌',
                options: sourceOptions,
                value: selectedSourceHoldingId,
                placeholder: '현금 계좌 선택',
                onChanged: _selectSourceHolding,
              ),
              if (transactionType == '이체')
                MoneyfySelectionField<int>(
                  label: '대상 현금 계좌',
                  options: targetOptions,
                  value: selectedTransferTargetHoldingId,
                  placeholder: '이체 대상 선택',
                  onChanged: (value) {
                    setState(() {
                      selectedTransferTargetHoldingId = value;
                    });
                  },
                ),
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
              if (shortcutBalance > 0)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: context.spacing.sm + context.spacing.xs / 4,
                  ),
                  child: MoneyfyPercentageShortcutButtons(
                    keyPrefix: 'cash-amount-shortcut',
                    onSelected: (ratio) =>
                        _applyCashAmountRatio(shortcutBalance, ratio),
                  ),
                ),
              MoneyfyLedgerPreview(
                rows: [
                  MoneyfyLedgerPreviewRow(
                    label: 'event.kind',
                    value: _cashEventKindLabel(transactionType),
                  ),
                  MoneyfyLedgerPreviewRow(
                    label: 'line.action',
                    value: _cashLineActionLabel(transactionType),
                  ),
                  MoneyfyLedgerPreviewRow(
                    label: 'source',
                    value: sourceOption?.title ?? '현금 계좌 선택',
                  ),
                  MoneyfyLedgerPreviewRow(
                    label: '거래금액',
                    value: _cashTransactionAmountPreview(),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
              if (includeInCalculations && transactionType == '환전') ...[
                MoneyfyFormField(
                  label: '환율',
                  controller: exchangeRateController,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CashCalculationToggle extends StatelessWidget {
  const _CashCalculationToggle({required this.value, required this.onChanged});

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
        value ? '현금 잔액과 연결 거래에 반영됩니다.' : '거래 내역에만 기록되고 현금 잔액은 변하지 않습니다.',
      ),
    );
  }
}

class _CashAccountOption {
  const _CashAccountOption({
    required this.assetId,
    required this.holdingId,
    required this.title,
    required this.subtitle,
    required this.currencyCode,
    required this.exchangeRate,
    required this.balance,
  });

  factory _CashAccountOption.empty(int holdingId) {
    return _CashAccountOption(
      assetId: 0,
      holdingId: holdingId,
      title: '현금 계좌',
      subtitle: '',
      currencyCode: 'KRW',
      exchangeRate: 1,
      balance: 0,
    );
  }

  final int assetId;
  final int holdingId;
  final String title;
  final String subtitle;
  final String currencyCode;
  final double exchangeRate;
  final double balance;
}
