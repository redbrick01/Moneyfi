import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:moneyfy/design_system/context_extensions.dart';

/// Shows local matches while the quote service verifies the symbol.
class MarketSearchField<T> extends StatefulWidget {
  const MarketSearchField({
    super.key,
    required this.controller,
    required this.label,
    required this.localSearch,
    required this.verify,
    required this.itemBuilder,
    required this.onSelected,
    required this.onEdited,
    this.selected,
    this.message,
  });

  final TextEditingController controller;
  final String label;
  final FutureOr<List<T>> Function(String) localSearch;
  final Future<List<T>> Function(String, List<T>) verify;
  final Widget Function(BuildContext, T) itemBuilder;
  final ValueChanged<T> onSelected;
  final VoidCallback onEdited;
  final Widget? selected;
  final String? message;

  @override
  State<MarketSearchField<T>> createState() => _MarketSearchFieldState<T>();
}

class _MarketSearchFieldState<T> extends State<MarketSearchField<T>> {
  final suggestions = SuggestionsController<T>();
  int generation = 0;
  bool verifying = false;

  Future<List<T>> search(String raw) async {
    final ticket = ++generation;
    final query = raw.trim();
    if (query.isEmpty || widget.selected != null) return [];
    final local = await widget.localSearch(query);
    if (!mounted || ticket != generation || raw != widget.controller.text) {
      return [];
    }
    setState(() => verifying = true);
    // Let TypeAhead publish the local suggestions before applying the remote result.
    unawaited(
      Future<void>(() async {
        if (!mounted || ticket != generation) return;
        try {
          final matches = await widget.verify(query, local);
          if (mounted &&
              ticket == generation &&
              raw == widget.controller.text) {
            suggestions.suggestions = matches;
          }
        } catch (error) {
          if (mounted && ticket == generation && local.isEmpty) {
            suggestions.error = error;
          }
        } finally {
          if (mounted && ticket == generation) {
            setState(() => verifying = false);
          }
        }
      }),
    );
    return local;
  }

  void submit() {
    suggestions.open();
    suggestions.refresh();
  }

  @override
  void dispose() {
    suggestions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.typography.meta),
        SizedBox(height: context.spacing.xs),
        Row(
          children: [
            Expanded(
              child: TypeAheadField<T>(
                controller: widget.controller,
                suggestionsController: suggestions,
                debounceDuration: const Duration(milliseconds: 300),
                suggestionsCallback: search,
                retainOnLoading: false,
                hideOnEmpty:
                    verifying ||
                    widget.controller.text.trim().isEmpty ||
                    widget.selected != null,
                errorBuilder: (context, _) => Padding(
                  padding: EdgeInsets.all(context.spacing.sm),
                  child: const Text('종목을 검색하지 못했어요. 다시 시도해 주세요.'),
                ),
                emptyBuilder: (context) => Padding(
                  padding: EdgeInsets.all(context.spacing.sm),
                  child: const Text('연관 종목이 없습니다.'),
                ),
                itemBuilder: widget.itemBuilder,
                onSelected: (item) {
                  generation++;
                  setState(() => verifying = false);
                  widget.onSelected(item);
                },
                builder: (context, controller, focusNode) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    generation++;
                    suggestions.suggestions = [];
                    setState(() => verifying = false);
                    widget.onEdited();
                  },
                  onSubmitted: (_) => submit(),
                  decoration: const InputDecoration(
                    hintText: '종목명 또는 티커',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: '검색',
              onPressed: verifying ? null : submit,
              icon: verifying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
            ),
          ],
        ),
        ?widget.selected,
        if (widget.message case final message?)
          Text(message, style: context.typography.meta),
      ],
    );
  }
}
