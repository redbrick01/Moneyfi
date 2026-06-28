import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/analysis/services/gpt_db_summary_builder.dart';

void main() {
  TransactionItem transaction({
    required String date,
    required String type,
    required String name,
  }) {
    return TransactionItem(
      date: date,
      type: type,
      name: name,
      amount: '1000',
      quantity: '1',
    );
  }

  HoldingItem holding({
    required String name,
    bool isHidden = false,
    List<TransactionItem> transactions = const [],
  }) {
    return HoldingItem(
      assetTitle: 'Visible asset',
      assetType: '주식',
      isHidden: isHidden,
      name: name,
      symbol: name.toUpperCase(),
      quantity: 1,
      averagePrice: 1000,
      currentPrice: 1200,
      note: '',
      transactions: transactions,
    );
  }

  AssetItem asset({
    required String title,
    bool isHidden = false,
    required List<HoldingItem> holdings,
  }) {
    return AssetItem(
      assetType: '주식',
      title: title,
      alias: title,
      isHidden: isHidden,
      value: '0',
      change: '0%',
      icon: Icons.pie_chart_outline_rounded,
      quantityLabel: '항목',
      quantityValue: '${holdings.length}개',
      averageLabel: '평균',
      averageValue: '0',
      note: '',
      holdings: holdings,
      transactions: const [],
    );
  }

  test('GPT DB summary excludes hidden assets and hidden holdings', () {
    final payload = buildGptDbSummaryPayload(
      assets: [
        asset(
          title: 'Visible asset',
          holdings: [
            holding(name: 'Visible holding'),
            holding(name: 'Hidden holding', isHidden: true),
          ],
        ),
        asset(
          title: 'Hidden asset',
          isHidden: true,
          holdings: [holding(name: 'Hidden asset holding')],
        ),
      ],
      targetRatios: const {},
      transactionDates: const [],
      snapshots: const [],
      generatedAt: DateTime(2026, 6, 5, 12),
    );

    final encoded = jsonEncode(payload);
    expect(encoded, contains('Visible asset'));
    expect(encoded, contains('Visible holding'));
    expect(encoded, isNot(contains('Hidden asset')));
    expect(encoded, isNot(contains('Hidden holding')));
    expect(payload['summary'], isNot(contains('hidden_asset_count')));
    expect(payload['summary'], isNot(contains('hidden_holding_count')));
    expect(payload['summary'], isNot(contains('hidden_valuation_krw')));
  });

  test('GPT DB summary includes visible transactions from the last week', () {
    final payload = buildGptDbSummaryPayload(
      assets: [
        asset(
          title: 'Visible asset',
          holdings: [
            holding(
              name: 'Visible holding',
              transactions: [
                transaction(date: '2026.06.05', type: '매수', name: '최근 매수'),
                transaction(date: '2026.05.20', type: '매도', name: '오래된 매도'),
              ],
            ),
            holding(
              name: 'Hidden holding',
              isHidden: true,
              transactions: [
                transaction(date: '2026.06.04', type: '매수', name: '숨김 최근 매수'),
              ],
            ),
          ],
        ),
      ],
      targetRatios: const {},
      transactionDates: const [],
      snapshots: const [],
      generatedAt: DateTime(2026, 6, 5, 12),
    );

    final recentTransactions = payload['recent_transactions'] as List<Object?>;
    expect(recentTransactions, hasLength(1));
    expect(recentTransactions.single, containsPair('name', '최근 매수'));

    final encoded = jsonEncode(payload);
    expect(encoded, isNot(contains('오래된 매도')));
    expect(encoded, isNot(contains('숨김 최근 매수')));
  });
}
