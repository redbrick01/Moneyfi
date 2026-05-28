import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/models/asset_item.dart';

void main() {
  HoldingItem holding({
    required String name,
    required double quantity,
    int? id,
    String assetType = '주식',
    String symbol = 'TEST',
    String exchangeCode = 'KRX',
    bool isHidden = false,
  }) {
    return HoldingItem(
      id: id,
      assetType: assetType,
      isHidden: isHidden,
      name: name,
      symbol: symbol,
      exchangeCode: exchangeCode,
      quantity: quantity,
      averagePrice: 1000,
      currentPrice: 1200,
      note: '',
      transactions: const [],
    );
  }

  AssetItem assetWithHoldings(List<HoldingItem> holdings) {
    return AssetItem(
      assetType: '주식',
      title: '국내 주식',
      alias: '국내 주식',
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

  test('visibleHoldings excludes closed investment positions', () {
    final asset = assetWithHoldings([
      holding(name: 'Open', quantity: 2),
      holding(name: 'Closed', quantity: 0),
      holding(
        name: 'Closed ETF Without Symbol',
        quantity: 0,
        assetType: '펀드',
        symbol: '',
        exchangeCode: '',
      ),
      holding(name: 'Hidden', quantity: 1, isHidden: true),
      holding(
        name: 'Cash',
        quantity: 0,
        id: -1,
        assetType: '현금',
        symbol: '',
        exchangeCode: '',
      ),
    ]);

    expect(asset.visibleHoldings.map((item) => item.name), ['Open', 'Cash']);
  });

  test('quantityText preserves crypto-scale fractional quantity', () {
    expect(
      holding(name: 'BTC', quantity: 0.12345678).quantityText,
      '0.12345678',
    );
    expect(holding(name: 'Whole', quantity: 2).quantityText, '2');
  });
}
