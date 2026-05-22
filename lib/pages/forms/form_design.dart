import 'package:flutter/material.dart';

import '../../theme/moneyfy_theme.dart';
import '../../widgets/moneyfy_ui.dart';

class MoneyfyFormScaffold extends StatelessWidget {
  const MoneyfyFormScaffold({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.isSaving,
    required this.onSave,
    required this.children,
    this.actionEnabled = true,
  });

  final String title;
  final String actionLabel;
  final bool isSaving;
  final VoidCallback onSave;
  final bool actionEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: MoneyfyPalette.background,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              MoneyfySpacing.pageHorizontal,
              16,
              MoneyfySpacing.pageHorizontal,
              120 + bottomInset,
            ),
            children: children,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoneyfySpacing.pageHorizontal,
            12,
            MoneyfySpacing.pageHorizontal,
            20 + bottomInset,
          ),
          child: FilledButton(
            onPressed: actionEnabled && !isSaving
                ? () {
                    FocusScope.of(context).unfocus();
                    onSave();
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: MoneyfyPalette.ink,
              foregroundColor: MoneyfyPalette.background,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  MoneyfySpacing.controlRadius,
                ),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Text(isSaving ? '저장 중...' : actionLabel),
          ),
        ),
      ),
    );
  }
}

class MoneyfyFormSection extends StatelessWidget {
  const MoneyfyFormSection({
    super.key,
    required this.title,
    required this.child,
    this.caption,
  });

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class MoneyfyFormInfoPanel extends StatelessWidget {
  const MoneyfyFormInfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoneyfyPalette.accentSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MoneyfyPalette.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: MoneyfyPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MoneyfyPalette.secondaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyfyLedgerPreview extends StatelessWidget {
  const MoneyfyLedgerPreview({super.key, required this.rows});

  final List<MoneyfyLedgerPreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoneyfyPalette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _MoneyfyLedgerPreviewRowView(row: rows[index]),
            if (index != rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class MoneyfyLedgerPreviewRow {
  const MoneyfyLedgerPreviewRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _MoneyfyLedgerPreviewRowView extends StatelessWidget {
  const _MoneyfyLedgerPreviewRowView({required this.row});

  final MoneyfyLedgerPreviewRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class MoneyfyFormField extends StatelessWidget {
  const MoneyfyFormField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.helperText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? helperText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textInputAction: maxLines == 1
                ? TextInputAction.done
                : TextInputAction.newline,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: label,
              filled: true,
              fillColor: MoneyfyPalette.surfaceMuted,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines == 1 ? 14 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: MoneyfyPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: MoneyfyPalette.border),
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
        ],
      ),
    );
  }
}

class MoneyfyChoiceWrap<T> extends StatelessWidget {
  const MoneyfyChoiceWrap({
    super.key,
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    this.iconBuilder,
  });

  final List<T> options;
  final T value;
  final String Function(T option) labelBuilder;
  final Widget? Function(T option)? iconBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in options)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: option == value
                    ? MoneyfyPalette.ink
                    : MoneyfyPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: option == value
                      ? MoneyfyPalette.ink
                      : MoneyfyPalette.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconBuilder?.call(option) case final icon?) ...[
                    icon,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    labelBuilder(option),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: option == value
                          ? MoneyfyPalette.background
                          : MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
