import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/sync_service.dart';
import '../../theme/moneyfy_theme.dart';
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
  });

  final int assetId;
  final int holdingId;
  final String? holdingClientId;
  final TransactionItem? item;
  final String? defaultName;

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
  int? selectedTransferTargetHoldingId;
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
    amountController.dispose();
    exchangeRateController.dispose();
    super.dispose();
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

    if (transactionType == '이체' && selectedTransferTargetHoldingId == null) {
      _showValidationMessage('이체할 현금 계좌를 선택해 주세요.');
      return;
    }

    InputValidationResult<double>? exchangeRateValidation;
    if (transactionType == '환전') {
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
      final currentHoldingId = await _resolveCurrentHoldingId();
      final item = widget.item;
      if (item == null && transactionType == '이체') {
        await AppDatabase.instance.createCashTransfer(
          assetId: widget.assetId,
          sourceHoldingId: currentHoldingId,
          targetHoldingId: selectedTransferTargetHoldingId!,
          date: dateValidation.value!,
          name: nameValidation.value!,
          amount: amountText,
        );
      } else if (item == null && transactionType == '환전') {
        await AppDatabase.instance.createCashExchange(
          assetId: widget.assetId,
          sourceHoldingId: currentHoldingId,
          date: dateValidation.value!,
          name: nameValidation.value!,
          amount: amountText,
          exchangeRate: exchangeRateValidation!.value!,
        );
      } else if (item == null) {
        await AppDatabase.instance.createTransaction(
          assetId: widget.assetId,
          holdingId: currentHoldingId,
          date: dateValidation.value!,
          type: transactionType,
          name: nameValidation.value!,
          amount: amountText,
          quantity: '',
        );
      } else {
        await AppDatabase.instance.updateTransactionItem(
          TransactionItem(
            id: item.id,
            clientId: item.clientId,
            assetId: item.assetId,
            holdingId: item.holdingId,
            date: dateValidation.value!,
            type: transactionType,
            name: nameValidation.value!,
            amount: amountText,
            quantity: transactionType == '환전' ? exchangeRateText : '',
            ledgerEventId: item.ledgerEventId,
            ledgerLineId: item.ledgerLineId,
            ledgerKind: item.ledgerKind,
            ledgerAction: item.ledgerAction,
            legacySourceTable: item.legacySourceTable,
            legacySourceId: item.legacySourceId,
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

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<int> _resolveCurrentHoldingId() async {
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
    final sourceHoldingId = loadedSourceHolding?.id ?? widget.holdingId;
    final sourceCurrencyCode = loadedSourceHolding?.currencyCode;
    final assets = await AppDatabase.instance.fetchAssets();
    final options = assets
        .expand(
          (asset) => asset.holdings
              .where(
                (holding) =>
                    (holding.id ?? 0) < 0 &&
                    holding.id != sourceHoldingId &&
                    (sourceCurrencyCode == null ||
                        holding.currencyCode == sourceCurrencyCode),
              )
              .map(
                (holding) => _CashAccountOption(
                  holdingId: holding.id!,
                  title: '${asset.alias} · ${holding.name}',
                ),
              ),
        )
        .toList(growable: false);

    int? initialSelection;
    if (widget.item != null && widget.item!.id != null) {
      initialSelection = await AppDatabase.instance
          .fetchLinkedCashTransferCounterpartyHoldingId(widget.item!.id!.abs());
      if (widget.item!.type.trim() == '환전') {
        final exchangeRate = await AppDatabase.instance
            .fetchLinkedCashExchangeRate(widget.item!.id!.abs());
        if (exchangeRate != null && exchangeRate > 0) {
          exchangeRateController.text = exchangeRate.toString();
        }
      }
    }

    if (!mounted) return;
    setState(() {
      cashAccountOptions = options;
      selectedTransferTargetHoldingId = initialSelection;
      if (initialSelection != null) {
        typeController.text = '이체';
      }
    });
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

    return MoneyfyFormScaffold(
      title: widget.item == null ? '현금 거래 추가' : '현금 거래 수정',
      actionLabel: '저장',
      isSaving: isSaving,
      onSave: _save,
      children: [
        MoneyfyFormSection(
          title: '거래 설정',
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
                options: _cashTransactionTypes,
                value: typeController.text.trim(),
                labelBuilder: (type) => type,
                onChanged: (value) {
                  setState(() {
                    typeController.text = value;
                  });
                },
              ),
            ],
          ),
        ),
        MoneyfyFormSection(
          title: '입력 정보',
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
              if (transactionType == '환전') ...[
                MoneyfyFormField(
                  label: '환율',
                  controller: exchangeRateController,
                ),
              ],
              if (transactionType == '이체')
                _TransferTargetField(
                  options: cashAccountOptions,
                  value: selectedTransferTargetHoldingId,
                  onChanged: (value) {
                    setState(() {
                      selectedTransferTargetHoldingId = value;
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransferTargetField extends StatelessWidget {
  const _TransferTargetField({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<_CashAccountOption> options;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _CashAccountOption? selectedOption;
    if (value != null) {
      for (final option in options) {
        if (option.holdingId == value) {
          selectedOption = option;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이체 계좌',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () async {
              final selected = await showModalBottomSheet<int>(
                context: context,
                backgroundColor: MoneyfyPalette.transparent,
                builder: (context) => _TransferTargetSheet(
                  options: options,
                  selectedHoldingId: value,
                ),
              );
              if (selected != null || value != null) {
                onChanged(selected);
              }
            },
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: MoneyfyPalette.surface,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: MoneyfyPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedOption?.title ?? '계좌 선택',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selectedOption == null
                            ? MoneyfyPalette.tertiaryText
                            : MoneyfyPalette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferTargetSheet extends StatelessWidget {
  const _TransferTargetSheet({
    required this.options,
    required this.selectedHoldingId,
  });

  final List<_CashAccountOption> options;
  final int? selectedHoldingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: MoneyfyPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: MoneyfyPalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('이체 계좌 선택', style: theme.textTheme.titleLarge),
              const SizedBox(height: 18),
              for (var index = 0; index < options.length; index++) ...[
                _TransferTargetOptionTile(
                  option: options[index],
                  isSelected: options[index].holdingId == selectedHoldingId,
                  onTap: () =>
                      Navigator.of(context).pop(options[index].holdingId),
                ),
                if (index != options.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferTargetOptionTile extends StatelessWidget {
  const _TransferTargetOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _CashAccountOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? MoneyfyPalette.accentSoft
              : MoneyfyPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? MoneyfyPalette.accent : MoneyfyPalette.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: MoneyfyPalette.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? MoneyfyPalette.accent
                  : MoneyfyPalette.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashAccountOption {
  const _CashAccountOption({required this.holdingId, required this.title});

  final int holdingId;
  final String title;
}
