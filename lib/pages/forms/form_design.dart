import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

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
      backgroundColor: context.colors.neutralBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: context.colors.neutralBackground,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              context.contentHorizontalPadding,
              context.spacing.md,
              context.contentHorizontalPadding,
              context.spacing.xxxl + context.spacing.xl + bottomInset,
            ),
            children: children,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.contentHorizontalPadding,
            context.spacing.sm,
            context.contentHorizontalPadding,
            context.spacing.md + context.spacing.xs / 2 + bottomInset,
          ),
          child: FilledButton(
            onPressed: actionEnabled && !isSaving
                ? () {
                    FocusScope.of(context).unfocus();
                    onSave();
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
              ),
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: AppFontWeights.regular,
              ),
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
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(height: context.spacing.sm),
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
      padding: EdgeInsets.all(context.spacing.sm + context.spacing.xs / 4),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(context.radius.rLg),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary, size: 20),
          SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.colors.neutralText,
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                SizedBox(height: context.spacing.xs / 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.neutralText,
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
      padding: EdgeInsets.all(context.spacing.sm + context.spacing.xs / 4),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceRaised,
        borderRadius: BorderRadius.circular(context.radius.rLg),
        border: Border.all(color: context.colors.neutralOutline),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _MoneyfyLedgerPreviewRowView(row: rows[index]),
            if (index != rows.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.spacing.xs + context.spacing.xs / 4,
                ),
                child: const Divider(height: 1),
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
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          flex: 2,
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.neutralText,
              fontWeight: AppFontWeights.semibold,
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
      padding: EdgeInsets.only(
        bottom: context.spacing.sm + context.spacing.xs / 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(height: context.spacing.xs),
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
              fillColor: context.colors.neutralSurfaceBase,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: maxLines == 1
                    ? context.spacing.sm + context.spacing.xs / 4
                    : context.spacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(color: context.colors.neutralOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(color: context.colors.neutralOutline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(
                  color: context.colors.primary,
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
      padding: EdgeInsets.only(
        bottom: context.spacing.sm + context.spacing.xs / 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          InkWell(
            borderRadius: BorderRadius.circular(context.radius.rPill),
            onTap: options.isEmpty
                ? null
                : () async {
                    final selectedValue = await showModalBottomSheet<T>(
                      context: context,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0),
                      builder: (context) => _MoneyfySelectionSheet<T>(
                        title: label,
                        options: options,
                        value: value,
                      ),
                    );
                    if (selectedValue != null) onChanged(selectedValue);
                  },
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md + context.spacing.xs / 4,
                vertical: context.spacing.sm + context.spacing.xs / 2 + 1,
              ),
              decoration: BoxDecoration(
                color: context.colors.neutralSurfaceBase,
                borderRadius: BorderRadius.circular(context.radius.rPill),
                border: Border.all(color: context.colors.neutralOutline),
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
                                ? context.colors.neutralTextMuted
                                : context.colors.neutralText,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                        if (selected?.subtitle case final subtitle?) ...[
                          SizedBox(height: context.spacing.xs / 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.neutralTextMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
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
        decoration: BoxDecoration(
          color: context.colors.neutralBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.radius.rLg),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.contentHorizontalPadding,
            context.spacing.sm,
            context.contentHorizontalPadding,
            context.spacing.lg + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.colors.neutralOutline,
                    borderRadius: BorderRadius.circular(context.radius.rPill),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.md + context.spacing.xs / 4),
              Text(title, style: theme.textTheme.titleLarge),
              SizedBox(height: context.spacing.md + context.spacing.xs / 4),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => SizedBox(
                    height: context.spacing.xs + context.spacing.xs / 4,
                  ),
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
      borderRadius: BorderRadius.circular(context.radius.rLg),
      onTap: () => Navigator.of(context).pop(option.value),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.md + context.spacing.xs / 4,
          vertical: context.spacing.sm + context.spacing.xs / 2 + 1,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primaryContainer
              : context.colors.neutralSurfaceBase,
          borderRadius: BorderRadius.circular(context.radius.rLg),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.neutralOutline,
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
                      color: context.colors.neutralText,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  if (option.subtitle case final subtitle?) ...[
                    SizedBox(height: context.spacing.xs / 2 - 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.neutralTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.meta case final meta?) ...[
              SizedBox(width: context.spacing.sm),
              Text(
                meta,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.neutralText,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ],
            SizedBox(width: context.spacing.sm),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? context.colors.primary
                  : context.colors.neutralTextMuted,
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
      spacing: context.spacing.xs + context.spacing.xs / 4,
      runSpacing: context.spacing.xs + context.spacing.xs / 4,
      children: [
        for (final option in options)
          InkWell(
            borderRadius: BorderRadius.circular(context.radius.rPill),
            onTap: () => onChanged(option),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.sm + context.spacing.xs / 4,
                vertical: context.spacing.xs + context.spacing.xs / 4,
              ),
              decoration: BoxDecoration(
                color: option == value
                    ? context.colors.primary
                    : context.colors.neutralSurfaceBase,
                borderRadius: BorderRadius.circular(context.radius.rPill),
                border: Border.all(
                  color: option == value
                      ? context.colors.primary
                      : context.colors.neutralOutline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconBuilder?.call(option) case final icon?) ...[
                    icon,
                    SizedBox(width: context.spacing.xs),
                  ],
                  Text(
                    labelBuilder(option),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: option == value
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.colors.neutralText,
                      fontWeight: AppFontWeights.regular,
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

class MoneyfyPercentageShortcutButtons extends StatelessWidget {
  const MoneyfyPercentageShortcutButtons({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.keyPrefix = 'percentage-shortcut',
  });

  final ValueChanged<double> onSelected;
  final bool enabled;
  final String keyPrefix;

  static const _options = <double>[0.25, 0.5, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: context.spacing.xs,
        runSpacing: context.spacing.xs,
        children: [
          for (final ratio in _options)
            OutlinedButton(
              key: ValueKey('$keyPrefix-${(ratio * 100).round()}'),
              onPressed: enabled ? () => onSelected(ratio) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.primary,
                side: BorderSide(color: context.colors.neutralOutline),
                minimumSize: const Size(56, 36),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm,
                  vertical: context.spacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              child: Text('${(ratio * 100).round()}%'),
            ),
        ],
      ),
    );
  }
}
