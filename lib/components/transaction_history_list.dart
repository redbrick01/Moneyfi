import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';

class TransactionHistoryList extends StatefulWidget {
  const TransactionHistoryList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.initialVisibleCount = 5,
    this.emptyText = '등록된 거래 내역이 없습니다.',
    this.separator,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialVisibleCount;
  final String emptyText;
  final Widget? separator;

  @override
  State<TransactionHistoryList> createState() => _TransactionHistoryListState();
}

class _TransactionHistoryListState extends State<TransactionHistoryList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return Text(widget.emptyText, style: context.typography.meta);
    }

    final visibleCount = _expanded
        ? widget.itemCount
        : widget.itemCount.clamp(0, widget.initialVisibleCount);
    final hasMore = widget.itemCount > widget.initialVisibleCount;
    final separator =
        widget.separator ??
        Divider(
          height: 20,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.65),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          widget.itemBuilder(context, index),
          if (index != visibleCount - 1) separator,
        ],
        if (hasMore) ...[
          SizedBox(height: context.spacing.xs),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(_expanded ? '접기' : '전체 ${widget.itemCount}건 보기'),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.neutralTextMuted,
                textStyle: context.typography.meta.copyWith(
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
