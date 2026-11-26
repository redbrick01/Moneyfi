import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';

class TransactionHistoryLayout extends StatelessWidget {
  const TransactionHistoryLayout({super.key, required this.builder});

  final Widget Function(BuildContext context, bool showColumns) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = context.typography.cardTitle.fontSize!;
        final textScale =
            MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
        return builder(context, constraints.maxWidth >= 640 * textScale);
      },
    );
  }
}

class TransactionHistoryDivider extends StatelessWidget {
  const TransactionHistoryDivider({super.key, required this.showColumns});

  final bool showColumns;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: showColumns ? context.spacing.xs : 20,
      color:
          (showColumns
                  ? context.colors.neutralOutline
                  : Theme.of(context).colorScheme.outlineVariant)
              .withValues(alpha: 0.65),
    );
  }
}

enum _TransactionAction { edit, delete }

class TransactionHistoryHeader extends StatelessWidget {
  const TransactionHistoryHeader({
    super.key,
    this.showPriceDetailColumn = true,
  });

  final bool showPriceDetailColumn;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.caption.copyWith(
      color: context.colors.neutralTextMuted,
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: context.spacing.xs / 2,
        end: VisualSpec.icon.minTapTarget,
      ),
      child: _TransactionHistoryColumns(
        showPriceDetailColumn: showPriceDetailColumn,
        cells: [
          Text('거래일', style: style),
          Text('유형', style: style),
          Text('거래명', style: style),
          if (showPriceDetailColumn)
            Text('수량 × 단가', style: style, textAlign: TextAlign.end),
          Text('거래 금액', style: style, textAlign: TextAlign.end),
        ],
      ),
    );
  }
}

class _TransactionHistoryColumns extends StatelessWidget {
  const _TransactionHistoryColumns({
    required this.cells,
    required this.showPriceDetailColumn,
  });

  final List<Widget> cells;
  final bool showPriceDetailColumn;

  @override
  Widget build(BuildContext context) {
    final widths = showPriceDetailColumn
        ? const [18, 10, 30, 23, 19]
        : const [18, 10, 53, 19];
    return Row(
      children: [
        for (final (index, cell) in cells.indexed) ...[
          if (index > 0) SizedBox(width: context.spacing.sm),
          Expanded(flex: widths[index], child: cell),
        ],
      ],
    );
  }
}

class TransactionHistoryRow extends StatelessWidget {
  const TransactionHistoryRow({
    super.key,
    required this.date,
    required this.typeLabel,
    required this.description,
    required this.amountText,
    required this.amountColor,
    required this.priceDetail,
    required this.showColumns,
    required this.groupTag,
    this.showPriceDetailColumn = true,
    this.isTrade = false,
    this.onEdit,
    required this.onDelete,
  });

  final String date;
  final String typeLabel;
  final String description;
  final String amountText;
  final Color amountColor;
  final String? priceDetail;
  final bool showColumns;
  final bool showPriceDetailColumn;
  final Object groupTag;
  final bool isTrade;
  final VoidCallback? onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final metaStyle = typography.caption.copyWith(
      color: colors.neutralTextMuted,
    );
    final dateText = Text(
      date,
      style: showColumns
          ? typography.cardTitle
          : typography.meta.copyWith(
              color: colors.neutralText,
              fontWeight: AppFontWeights.semibold,
            ),
    );
    final badge = MoneyfyBadge.transactionType(typeLabel);
    final amount = FittedBox(
      alignment: AlignmentDirectional.centerEnd,
      fit: BoxFit.scaleDown,
      child: Text(
        amountText,
        semanticsLabel: isTrade ? '총액 $amountText' : null,
        softWrap: false,
        style: typography.cardTitle.copyWith(
          color: amountColor,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
    );
    final detail = Text(
      priceDetail ?? '',
      style: metaStyle,
      textAlign: TextAlign.end,
    );

    return Slidable(
      groupTag: groupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onDelete,
        icon: VisualSpec.icon.delete,
        iconColor: colors.negativeOn,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(context.radius.rMd),
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.spacing.xs - context.spacing.xs / 4,
                ),
                child: showColumns
                    ? _TransactionHistoryColumns(
                        showPriceDetailColumn: showPriceDetailColumn,
                        cells: [
                          dateText,
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: badge,
                          ),
                          Text(description, style: metaStyle),
                          if (showPriceDetailColumn) detail,
                          amount,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: context.spacing.xs / 2,
                                  runSpacing: context.spacing.xs / 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    FittedBox(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      fit: BoxFit.scaleDown,
                                      child: dateText,
                                    ),
                                    badge,
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  SizedBox(height: context.spacing.xs / 2),
                                  Text(description, style: metaStyle),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: context.spacing.xs),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                amount,
                                if (priceDetail != null) ...[
                                  SizedBox(height: context.spacing.xs / 2),
                                  detail,
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          PopupMenuButton<_TransactionAction>(
            tooltip: '거래 옵션',
            icon: Icon(
              VisualSpec.icon.more,
              size: VisualSpec.icon.sizeSmall,
              color: colors.neutralTextMuted,
            ),
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: _TransactionAction.edit,
                  child: Text('수정'),
                ),
              const PopupMenuItem(
                value: _TransactionAction.delete,
                child: Text('삭제'),
              ),
            ],
            onSelected: (action) async {
              switch (action) {
                case _TransactionAction.edit:
                  onEdit?.call();
                case _TransactionAction.delete:
                  await onDelete();
              }
            },
          ),
        ],
      ),
    );
  }
}

bool isTransactionHistoryTrade(TransactionItem transaction) =>
    switch (transaction.ledgerAction ?? transaction.type.trim()) {
      'buy' || 'sell' || '매수' || '매도' => true,
      _ => false,
    };

String? transactionHistoryPriceDetail(
  TransactionItem transaction, {
  required String? assetType,
  required String Function(double) formatAmount,
}) {
  final rawQuantity = transaction.quantity.trim();
  final value = double.tryParse(rawQuantity.replaceAll(',', ''));
  final quantity = value == null || !value.isFinite || value == 0
      ? null
      : assetType == '주식' || assetType == '펀드'
      ? '$rawQuantity주'
      : '수량 $rawQuantity';
  final price = isTransactionHistoryTrade(transaction)
      ? transaction.unitPrice ??
            double.tryParse(transaction.amount.replaceAll(',', '').trim())
      : null;
  final unitPrice = price != null && price.isFinite && price > 0 ? price : null;
  return switch ((quantity, unitPrice)) {
    (final units?, final price?) => '$units × ${formatAmount(price)}',
    (final units?, null) => units,
    (null, final price?) => '단가 ${formatAmount(price)}',
    _ => null,
  };
}
