import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/sync_service.dart';
import '../../theme/moneyfy_theme.dart';
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
    this.item,
    this.defaultName,
  });

  final int assetId;
  final int holdingId;
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
    amountController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving || typeController.text.trim().isEmpty) return;
    final transactionType = typeController.text.trim();
    final requiresQuantity = transactionType == '매수' || transactionType == '매도';
    final parsedAmount = _parsePositiveNumber(amountController.text);
    final parsedQuantity = _parsePositiveNumber(quantityController.text);
    if (parsedAmount == null || (requiresQuantity && parsedQuantity == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiresQuantity
                ? '단가와 수량을 0보다 큰 숫자로 입력해 주세요.'
                : '금액을 0보다 큰 숫자로 입력해 주세요.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final item = widget.item;
      if (item == null) {
        await AppDatabase.instance.createTransaction(
          assetId: widget.assetId,
          holdingId: widget.holdingId,
          date: dateController.text.trim(),
          type: transactionType,
          name: nameController.text.trim(),
          amount: amountController.text.trim(),
          quantity: requiresQuantity ? quantityController.text.trim() : '',
        );
      } else {
        await AppDatabase.instance.updateTransactionItem(
          TransactionItem(
            id: item.id,
            assetId: item.assetId,
            holdingId: item.holdingId,
            date: dateController.text.trim(),
            type: transactionType,
            name: nameController.text.trim(),
            amount: amountController.text.trim(),
            quantity: requiresQuantity ? quantityController.text.trim() : '',
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

  double? _parsePositiveNumber(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return value;
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

        return MoneyfyFormScaffold(
          title: widget.item == null ? '거래 추가' : '거래 수정',
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
                      fontWeight: FontWeight.w700,
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
                  if (!isCashAsset && requiresQuantity)
                    MoneyfyFormField(
                      label: ledgerCopy.quantityLabel,
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
