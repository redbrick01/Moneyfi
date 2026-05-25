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
              backgroundColor: MoneyfyPalette.primary,
              foregroundColor: MoneyfyPalette.onPrimary,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  MoneyfySpacing.controlRadius,
                ),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
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
              fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
              fillColor: MoneyfyPalette.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines == 1 ? 14 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
                borderSide: const BorderSide(color: MoneyfyPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
                borderSide: const BorderSide(color: MoneyfyPalette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
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

class MoneyfySelectionOption<T> {
  const MoneyfySelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.meta,
  });

  final T value;
  final String title;
  final String? subtitle;
  final String? meta;
}

class MoneyfySelectionField<T> extends StatelessWidget {
  const MoneyfySelectionField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = '선택',
  });

  final String label;
  final List<MoneyfySelectionOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedOption;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: options.isEmpty
                ? null
                : () async {
                    final selectedValue = await showModalBottomSheet<T>(
                      context: context,
                      backgroundColor: MoneyfyPalette.transparent,
                      builder: (context) => _MoneyfySelectionSheet<T>(
                        title: label,
                        options: options,
                        value: value,
                      ),
                    );
                    if (selectedValue != null) onChanged(selectedValue);
                  },
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: MoneyfyPalette.surface,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: MoneyfyPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.title ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: selected == null
                                ? MoneyfyPalette.tertiaryText
                                : MoneyfyPalette.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (selected?.subtitle case final subtitle?) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: MoneyfyPalette.tertiaryText,
                            ),
                          ),
                        ],
                      ],
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

  MoneyfySelectionOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }
}

class _MoneyfySelectionSheet<T> extends StatelessWidget {
  const _MoneyfySelectionSheet({
    required this.title,
    required this.options,
    required this.value,
  });

  final String title;
  final List<MoneyfySelectionOption<T>> options;
  final T? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: MoneyfyPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
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
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return _MoneyfySelectionOptionTile<T>(
                      option: option,
                      isSelected: option.value == value,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyfySelectionOptionTile<T> extends StatelessWidget {
  const _MoneyfySelectionOptionTile({
    required this.option,
    required this.isSelected,
  });

  final MoneyfySelectionOption<T> option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).pop(option.value),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: MoneyfyPalette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.subtitle case final subtitle?) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.meta case final meta?) ...[
              const SizedBox(width: 12),
              Text(
                meta,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                    ? MoneyfyPalette.primary
                    : MoneyfyPalette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: option == value
                      ? MoneyfyPalette.primary
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
                          ? MoneyfyPalette.onPrimary
                          : MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w400,
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
