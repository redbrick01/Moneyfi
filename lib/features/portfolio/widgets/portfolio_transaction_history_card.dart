import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:moneyfy/components/panels/app_detail_section.dart';
import 'package:moneyfy/components/rows/transaction_history_row.dart';
import 'package:moneyfy/components/transaction_history_list.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

class PortfolioTransactionHistoryCard extends StatelessWidget {
  const PortfolioTransactionHistoryCard({
    super.key,
    required this.transactions,
    required this.onAdd,
    required this.rowBuilder,
    this.showPriceDetailColumn = true,
  });

  final List<TransactionItem> transactions;
  final VoidCallback onAdd;
  final Widget Function(BuildContext, TransactionItem, bool showColumns)
  rowBuilder;
  final bool showPriceDetailColumn;

  @override
  Widget build(BuildContext context) {
    final sortedTransactions = _newestFirst(transactions);
    return AppDetailSection(
      title: '거래 내역',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: Icon(VisualSpec.icon.add),
        label: const Text('추가'),
        style: TextButton.styleFrom(
          foregroundColor: context.colors.neutralTextMuted,
          textStyle: context.typography.meta.copyWith(
            fontWeight: AppFontWeights.semibold,
          ),
        ),
      ),
      child: TransactionHistoryLayout(
        builder: (context, showColumns) {
          final divider = TransactionHistoryDivider(showColumns: showColumns);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showColumns && sortedTransactions.isNotEmpty) ...[
                TransactionHistoryHeader(
                  showPriceDetailColumn: showPriceDetailColumn,
                ),
                divider,
              ],
              SlidableAutoCloseBehavior(
                child: TransactionHistoryList(
                  itemCount: sortedTransactions.length,
                  separator: divider,
                  itemBuilder: (context, index) => rowBuilder(
                    context,
                    sortedTransactions[index],
                    showColumns,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<TransactionItem> _newestFirst(List<TransactionItem> transactions) {
  final unknownDate = DateTime.utc(0);
  final legacySeparator = RegExp(r'[./]');
  final datedTransactions = [
    for (final (index, transaction) in transactions.indexed)
      (
        index: index,
        date:
            DateTime.tryParse(transaction.date.trim()) ??
            DateTime.tryParse(
              transaction.date.trim().replaceAll(legacySeparator, '-'),
            ) ??
            unknownDate,
        transaction: transaction,
      ),
  ];
  datedTransactions.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate == 0 ? a.index.compareTo(b.index) : byDate;
  });
  return [for (final entry in datedTransactions) entry.transaction];
}
