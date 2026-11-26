import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/rows/settings_action_row.dart';

class MonthlyPivotSetting extends StatefulWidget {
  const MonthlyPivotSetting({
    super.key,
    required this.day,
    required this.onSave,
  });

  final int day;
  final Future<void> Function(int) onSave;

  @override
  State<MonthlyPivotSetting> createState() => _MonthlyPivotSettingState();
}

class _MonthlyPivotSettingState extends State<MonthlyPivotSetting> {
  bool _saving = false;

  Future<void> _chooseDay() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _MonthlyPivotDialog(day: widget.day),
    );
    if (!mounted || selected == null || selected == widget.day) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(selected);
    } catch (_) {
      if (mounted)
        AppSnackBar.showError(context, '월 분기점을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsActionRow(
    icon: Icons.calendar_month_rounded,
    title: '월 분기점',
    subtitle: _saving ? '저장 중…' : '매월 ${widget.day}일',
    enabled: !_saving,
    onTap: _chooseDay,
  );
}

class _MonthlyPivotDialog extends StatefulWidget {
  const _MonthlyPivotDialog({required this.day});
  final int day;

  @override
  State<_MonthlyPivotDialog> createState() => _MonthlyPivotDialogState();
}

class _MonthlyPivotDialogState extends State<_MonthlyPivotDialog> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.day - 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemExtent = MediaQuery.textScalerOf(context).scale(22) + 24;
    return AlertDialog(
      title: const Text('월 분기점'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('선택한 날짜가 없는 달에는 말일을 적용해요.'),
          const SizedBox(height: 12),
          SizedBox(
            width: 256,
            height: itemExtent * 3,
            child: CupertinoPicker(
              scrollController: _controller,
              itemExtent: itemExtent,
              onSelectedItemChanged: null,
              children: [
                for (var day = 1; day <= 31; day++)
                  Center(
                    child: Text(
                      '$day일',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.selectedItem + 1),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
