import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../services/sync_service.dart';
import 'form_design.dart';

class CashAccountFormPage extends StatefulWidget {
  const CashAccountFormPage({super.key, required this.assetId, this.item});

  final int assetId;
  final HoldingItem? item;

  @override
  State<CashAccountFormPage> createState() => _CashAccountFormPageState();
}

class _CashAccountFormPageState extends State<CashAccountFormPage> {
  static const currencyOptions = <String>['KRW', 'USD'];

  late final TextEditingController nameController;
  late final TextEditingController balanceController;
  late final TextEditingController noteController;
  late String selectedCurrencyCode;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.name ?? '');
    balanceController = TextEditingController(
      text: widget.item == null ? '' : widget.item!.quantity.toString(),
    );
    noteController = TextEditingController(text: widget.item?.note ?? '');
    selectedCurrencyCode = widget.item?.currencyCode ?? currencyOptions.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving || nameController.text.trim().isEmpty) return;

    setState(() {
      isSaving = true;
    });

    try {
      final item = widget.item;
      final balance = double.tryParse(balanceController.text.trim()) ?? 0;
      if (item == null) {
        await AppDatabase.instance.createCashAccount(
          assetId: widget.assetId,
          currencyCode: selectedCurrencyCode,
          name: nameController.text.trim(),
          note: noteController.text.trim(),
          balance: balance,
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
          throw StateError('현금 계좌를 찾을 수 없습니다.');
        }
        await AppDatabase.instance.updateHoldingItem(
          HoldingItem(
            id: itemId,
            clientId: fallbackItem?.clientId ?? item.clientId,
            assetId: fallbackItem?.assetId ?? item.assetId,
            assetTitle: fallbackItem?.assetTitle ?? item.assetTitle,
            assetType: fallbackItem?.assetType ?? item.assetType,
            currencyCode: selectedCurrencyCode,
            exchangeCode: fallbackItem?.exchangeCode ?? item.exchangeCode,
            name: nameController.text.trim(),
            symbol: fallbackItem?.symbol ?? item.symbol,
            quantity: balance,
            averagePrice: balance,
            currentPrice: balance,
            note: noteController.text.trim(),
            transactions: fallbackItem?.transactions ?? item.transactions,
            isHidden: fallbackItem?.isHidden ?? item.isHidden,
          ),
        );
      }

      if (SyncService.instance.canSync) {
        await SyncService.instance.syncNow(reason: 'cash_account_form_save');
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

  @override
  Widget build(BuildContext context) {
    return MoneyfyFormScaffold(
      title: widget.item == null ? '현금 계좌 추가' : '현금 계좌 수정',
      actionLabel: '저장',
      isSaving: isSaving,
      onSave: _save,
      children: [
        MoneyfyFormSection(
          title: '통화 설정',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
        MoneyfyFormSection(
          title: '계좌 정보',
          child: Column(
            children: [
              MoneyfyFormField(label: '이름', controller: nameController),
              MoneyfyFormField(
                label: widget.item == null ? '초기 잔고' : '현재 잔고',
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
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
  }
}
