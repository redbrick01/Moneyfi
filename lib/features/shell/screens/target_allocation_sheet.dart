import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/icons/app_icon_button.dart';
import 'package:moneyfy/components/panels/app_sheet_surface.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/design_system/context_extensions.dart';

class TargetAllocationEntry {
  const TargetAllocationEntry({
    required this.assetId,
    required this.label,
    required this.currentRatio,
  });

  final int assetId;
  final String label;
  final double currentRatio;
}

Future<bool?> showTargetAllocationSheet({
  required BuildContext context,
  required List<TargetAllocationEntry> entries,
  required Map<int, TextEditingController> controllers,
  required Future<void> Function(Map<int, double> ratios) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _TargetAllocationSheet(
        entries: entries,
        controllers: controllers,
        onSave: onSave,
      );
    },
  );
}

class _TargetAllocationSheet extends StatefulWidget {
  const _TargetAllocationSheet({
    required this.entries,
    required this.controllers,
    required this.onSave,
  });

  final List<TargetAllocationEntry> entries;
  final Map<int, TextEditingController> controllers;
  final Future<void> Function(Map<int, double> ratios) onSave;

  @override
  State<_TargetAllocationSheet> createState() => _TargetAllocationSheetState();
}

class _TargetAllocationSheetState extends State<_TargetAllocationSheet> {
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final sum = _sumRatios();
    final hasInvalid = _hasInvalidValues();
    final isBalanced = (sum - 100).abs() < 0.001;
    final canSave = !hasInvalid && isBalanced && !_isSaving;
    final progress = (sum / 100).clamp(0, 1).toDouble();

    final statusText = hasInvalid
        ? '0~100 사이 숫자를 입력해 주세요.'
        : isBalanced
        ? '저장할 수 있어요.'
        : sum < 100
        ? '남은 ${(100 - sum).toStringAsFixed(1)}%를 배분해 주세요.'
        : '합계가 ${(sum - 100).toStringAsFixed(1)}% 초과했어요.';

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;
    return AppSheetSurface(
      heightFactor: isKeyboardOpen ? 0.96 : 0.82,
      child: AnimatedPadding(
        duration: context.motion.fast,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.lg,
                context.spacing.sm,
                context.spacing.lg,
                context.spacing.sm,
              ),
              child: Column(
                children: [
                  const AppSheetHandle(),
                  SizedBox(height: context.spacing.md),
                  Row(
                    children: [
                      Text('목표 비중 설정', style: context.typography.sectionTitle),
                      const Spacer(),
                      AppIconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: AppIconName.close,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '합계 ${sum.toStringAsFixed(1)}% / 100%',
                    style: context.typography.cardTitle,
                  ),
                  SizedBox(height: context.spacing.xs),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(context.radius.rPill),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(statusText, style: context.typography.meta),
                ],
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Expanded(
              child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.lg,
                  vertical: isKeyboardOpen
                      ? context.spacing.xs
                      : context.spacing.sm,
                ),
                itemBuilder: (context, index) {
                  final item = widget.entries[index];
                  return _TargetInputRow(
                    entry: item,
                    controller: widget.controllers[item.assetId]!,
                    onChanged: () => setState(() {}),
                  );
                },
                separatorBuilder: (context, index) =>
                    SizedBox(height: context.spacing.sm),
                itemCount: widget.entries.length,
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.lg,
                  0,
                  context.spacing.lg,
                  context.spacing.sm,
                ),
                child: InlineError(message: _errorMessage!),
              ),
            _TargetActionFooter(
              canSave: canSave,
              isCompact: isKeyboardOpen,
              isSaving: _isSaving,
              hasInvalid: hasInvalid,
              onCancel: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
              onSave: canSave ? _handleSave : null,
            ),
          ],
        ),
      ),
    );
  }

  Map<int, double> _buildSaveMap() {
    return {
      for (final item in widget.entries)
        item.assetId: _parseRatio(widget.controllers[item.assetId]?.text) ?? 0,
    };
  }

  double _sumRatios() {
    return widget.entries.fold<double>(0, (sum, item) {
      return sum + (_parseRatio(widget.controllers[item.assetId]?.text) ?? 0);
    });
  }

  bool _hasInvalidValues() {
    for (final item in widget.entries) {
      final value = _parseRatio(widget.controllers[item.assetId]?.text);
      if (value == null || value < 0 || value > 100) {
        return true;
      }
    }
    return false;
  }

  double? _parseRatio(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    return double.tryParse(text.trim());
  }

  Future<void> _handleSave() async {
    final navigator = Navigator.of(context);
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_buildSaveMap());
      if (!mounted) return;
      navigator.pop(true);
    } catch (error) {
      setState(() {
        _errorMessage = '저장에 실패했습니다. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _TargetActionFooter extends StatelessWidget {
  const _TargetActionFooter({
    required this.canSave,
    required this.isCompact,
    required this.isSaving,
    required this.hasInvalid,
    required this.onCancel,
    required this.onSave,
  });

  final bool canSave;
  final bool isCompact;
  final bool isSaving;
  final bool hasInvalid;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.spacing.lg,
          context.spacing.xs,
          context.spacing.lg,
          context.spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppGhostButton(
                label: '취소',
                expand: true,
                onPressed: onCancel,
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: AppPrimaryButton(
                label: '저장',
                isLoading: isSaving,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        context.spacing.sm,
        context.spacing.lg,
        context.spacing.lg,
      ),
      child: Column(
        children: [
          AppPrimaryButton(label: '저장', isLoading: isSaving, onPressed: onSave),
          SizedBox(height: context.spacing.xs),
          AppGhostButton(label: '취소', expand: true, onPressed: onCancel),
          if (!canSave)
            Padding(
              padding: EdgeInsets.only(top: context.spacing.xs),
              child: Text(
                hasInvalid ? '0~100 사이의 숫자를 입력해 주세요.' : '합계가 100%여야 저장할 수 있어요.',
                style: context.typography.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetInputRow extends StatelessWidget {
  const _TargetInputRow({
    required this.entry,
    required this.controller,
    required this.onChanged,
  });

  final TargetAllocationEntry entry;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.label,
                  style: context.typography.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '현재 ${entry.currentRatio.toStringAsFixed(1)}%',
                  style: context.typography.caption,
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.sm),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              onChanged: (_) => onChanged(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}(\.\d{0,1})?$'),
                ),
              ],
              decoration: const InputDecoration(suffixText: '%', isDense: true),
            ),
          ),
        ],
      ),
    );
  }
}
