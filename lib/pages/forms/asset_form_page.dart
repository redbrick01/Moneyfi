import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import '../../db/app_database.dart';
import '../../models/asset_item.dart';
import '../../utils/display_currency.dart';
import '../../services/sync_service.dart';
import 'form_design.dart';

enum _AssetTypePreset {
  stock(
    label: '주식',
    icon: Icons.show_chart_rounded,
    currencyCode: 'KRW',
    quantityLabel: '보유 종목',
    averageLabel: '평균 수익률',
  ),
  fund(
    label: '펀드',
    icon: Icons.pie_chart_rounded,
    currencyCode: 'KRW',
    quantityLabel: '보유 펀드',
    averageLabel: '평균 수익률',
  ),
  coin(
    label: '코인',
    icon: Icons.currency_bitcoin_rounded,
    currencyCode: 'KRW',
    quantityLabel: '보유 코인',
    averageLabel: '평균 수익률',
  ),
  cash(
    label: '현금',
    icon: Icons.account_balance_wallet_rounded,
    currencyCode: 'KRW',
    quantityLabel: '예치 계좌',
    averageLabel: '가용 현금',
  ),
  custom(
    label: '기타',
    icon: Icons.widgets_outlined,
    currencyCode: 'KRW',
    quantityLabel: '보유 항목',
    averageLabel: '평균 수익률',
  );

  const _AssetTypePreset({
    required this.label,
    required this.icon,
    required this.currencyCode,
    required this.quantityLabel,
    required this.averageLabel,
  });

  final String label;
  final IconData icon;
  final String currencyCode;
  final String quantityLabel;
  final String averageLabel;

  static _AssetTypePreset fromAssetItem(AssetItem? item) {
    if (item == null) return _AssetTypePreset.stock;
    return _AssetTypePreset.values.firstWhere(
      (preset) => preset.label == item.assetType,
      orElse: () => _AssetTypePreset.custom,
    );
  }
}

class AssetFormPage extends StatefulWidget {
  const AssetFormPage({super.key, this.item});

  final AssetItem? item;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  late final TextEditingController aliasController;
  late final TextEditingController noteController;
  late _AssetTypePreset selectedType;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    noteController = TextEditingController(text: item?.note ?? '');
    selectedType = _AssetTypePreset.fromAssetItem(item);
    aliasController = TextEditingController(
      text: item?.displayName ?? selectedType.label,
    );
  }

  @override
  void dispose() {
    aliasController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    final item = widget.item;
    final valueText = MoneyfyDisplayCurrencySettings.formatAmountFromKrw(0);
    const changeText = '0.0%';
    final groupName = aliasController.text.trim().isEmpty
        ? selectedType.label
        : aliasController.text.trim();

    if (item == null) {
      await AppDatabase.instance.createAsset(
        assetType: selectedType.label,
        title: groupName,
        alias: groupName,
        hidden: item?.isHidden ?? false,
        currencyCode: selectedType.currencyCode,
        value: valueText,
        change: changeText,
        icon: selectedType.icon,
        quantityLabel: selectedType.quantityLabel,
        quantityValue: '',
        averageLabel: selectedType.averageLabel,
        averageValue: '',
        note: noteController.text.trim(),
      );
    } else {
      await AppDatabase.instance.updateAssetItem(
        AssetItem(
          id: item.id,
          assetType: selectedType.label,
          title: groupName,
          alias: groupName,
          isHidden: item.isHidden,
          currencyCode: selectedType.currencyCode,
          value: item.holdings.isEmpty ? valueText : item.value,
          change: item.holdings.isEmpty ? changeText : item.change,
          icon: selectedType.icon,
          quantityLabel: selectedType.quantityLabel,
          quantityValue: item.holdings.isEmpty ? '' : item.quantityValue,
          averageLabel: selectedType.averageLabel,
          averageValue: item.holdings.isEmpty ? '' : item.averageValue,
          note: noteController.text.trim(),
          holdings: item.holdings,
          transactions: item.transactions,
        ),
      );
    }

    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'asset_form_save');
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return MoneyfyFormScaffold(
      title: widget.item == null ? '자산 추가' : '자산 수정',
      actionLabel: '저장',
      isSaving: isSaving,
      onSave: _save,
      children: [
        MoneyfyFormSection(
          title: '자산군 타입',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MoneyfyChoiceWrap<_AssetTypePreset>(
                options: _AssetTypePreset.values,
                value: selectedType,
                labelBuilder: (type) => type.label,
                iconBuilder: (type) =>
                    Icon(type.icon, size: VisualSpec.icon.sizeSmall),
                onChanged: (type) {
                  setState(() {
                    selectedType = type;
                  });
                },
              ),
            ],
          ),
        ),
        MoneyfyFormSection(
          title: '기본 정보',
          child: Column(
            children: [
              MoneyfyFormField(label: '별명', controller: aliasController),
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
