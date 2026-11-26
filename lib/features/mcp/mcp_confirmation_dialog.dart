import 'dart:async';

import 'package:flutter/material.dart';

Future<bool> confirmMcpTransaction(
  NavigatorState? navigator,
  Map<String, dynamic> preview,
) async {
  if (navigator == null || !navigator.mounted) return false;

  final deleting = preview['operation'] == 'delete_transaction';
  final route = DialogRoute<bool>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(deleting ? 'MCP 거래 삭제 확인' : 'MCP 거래 수정 확인'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TransactionDetails('기존 거래', preview['original'] as Map),
          if (preview['proposed'] case final Map transaction)
            _TransactionDetails('변경 후', transaction),
          if ((preview['balance_changes'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('예상 잔액 및 수량'),
            for (final change in preview['balance_changes'] as List)
              Text(
                '${change['name']}  ${change['before']} → ${change['after']}'
                ' ${change['is_cash'] == true ? change['currency'] : '단위'}',
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          style: deleting
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(deleting ? '거래 삭제' : '변경 적용'),
        ),
      ],
    ),
  );

  final timer = Timer(const Duration(seconds: 60), () {
    if (navigator.mounted && route.isActive) {
      navigator.removeRoute(route, false);
    }
  });
  try {
    return await navigator.push(route) ?? false;
  } finally {
    timer.cancel();
  }
}

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails(this.label, this.transaction);

  final String label;
  final Map transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(
            '${transaction['date']}  ${transaction['type']}  ${transaction['name']}',
          ),
          for (final line in transaction['lines'] as List)
            Text(_lineDescription(line as Map)),
        ],
      ),
    );
  }

  String _lineDescription(Map line) {
    final action = switch (line['action']) {
      'transfer_out' || 'fx_out' => '출금',
      'transfer_in' || 'fx_in' => '입금',
      'settlement' => '결제',
      _ => '',
    };
    final details = [
      if (action.isNotEmpty) action,
      if (line['quantity_delta'] != 0) '수량 ${line['quantity_delta']}',
      if (line['unit_price'] != 0)
        '단가 ${line['unit_price']} ${line['currency']}',
      if (line['cash_delta'] != 0 || line['gross_amount'] != 0)
        '${line['cash_delta'] != 0 ? line['cash_delta'] : line['gross_amount']} ${line['currency']}',
      if (line['fx_rate'] != null) '환율 ${line['fx_rate']}',
    ];
    final name = [
      line['asset_name'],
      line['holding_name'],
    ].whereType<String>().join(' · ');
    return [if (name.isNotEmpty) name, ...details].join('  ');
  }
}
