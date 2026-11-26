import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/snapshot_visibility.dart';

void main() {
  test(
    'hidden groups, holdings and cash are excluded at each snapshot rate',
    () {
      final visibility = SnapshotVisibility([
        _asset(
          1,
          '현재 이름',
          holdings: [
            _holding(11, '같은 이름', hidden: true),
            _holding(12, '같은 이름'),
            _holding(-13, '현재 계좌명', hidden: true),
          ],
        ),
        _asset(2, '숨긴 자산군', hidden: true),
        _asset(3, '모두 숨긴 자산군', holdings: [_holding(31, '숨긴 종목', hidden: true)]),
      ]);

      List<SnapshotDisplayItem> itemsAt(double rate, double visibleValue) =>
          visibility.buildItems(
            snapshot: _snapshot(rate),
            items: [
              _group(
                1,
                '이전 이름',
                clientId: 'group-1',
                count: 3,
                purchase: 300 + 10 * rate,
                value: visibleValue + 300 + 10 * rate,
              ),
              _group(2, '숨긴 자산군', count: 0, purchase: 999, value: 999),
              _group(3, '모두 숨긴 자산군', count: 1, purchase: 200, value: 300),
              _group(4, '과거 자산군', count: 0, purchase: 500, value: 500),
            ],
            holdings: [
              _position(1, 11, '같은 이름', purchase: 200, value: 300),
              _position(1, 12, '같은 이름', purchase: 100, value: visibleValue),
              _position(3, 31, '숨긴 종목', purchase: 200, value: 300),
            ],
            cashAccounts: const [
              SnapshotCashAccountRecord(
                id: 1,
                snapshotId: 1,
                assetId: null,
                assetClientId: 'group-1',
                assetTitle: '이전 이름',
                cashAccountId: null,
                cashAccountClientId: 'holding--13',
                cashAccountName: '이전 계좌명',
                currencyCode: 'USD',
                balance: 10,
                note: '',
              ),
            ],
          );

      final current = itemsAt(1400, 170);
      final previous = itemsAt(1200, 130);
      expect(current.map((item) => item.assetTitle), ['이전 이름', '과거 자산군']);
      expect(current.first.holdings.map((row) => row.holdingId), [12]);
      expect(current.first.cashAccounts, isEmpty);
      expect(current.first.totalPurchaseAmount, 100);
      expect(current.first.totalValuationAmount, 170);
      expect(current.first.profitAmount, 70);
      expect(previous.first.assetKey, current.first.assetKey);
      expect(previous.first.totalValuationAmount, 130);
      expect(current.last.totalValuationAmount, 500);
    },
  );

  test('legacy name matching is scoped and preserves unrecorded amounts', () {
    final visibility = SnapshotVisibility([
      _asset(1, '그룹', holdings: [_holding(11, '같은 이름', hidden: true)]),
      _asset(2, '다른 그룹', holdings: [_holding(21, '같은 이름')]),
    ]);
    final items = visibility.buildItems(
      snapshot: _snapshot(1),
      items: [
        _group(1, '그룹', count: 2, purchase: 250, value: 375),
        _group(2, '다른 그룹', count: 1, purchase: 200, value: 300),
      ],
      holdings: [
        _position(1, null, '같은 이름', purchase: 200, value: 300),
        _position(2, null, '같은 이름', purchase: 200, value: 300),
      ],
      cashAccounts: const [],
    );
    expect(items.first.totalValuationAmount, 75);
    expect(items.first.holdings, isEmpty);
    expect(items.last.totalValuationAmount, 300);
    expect(items.last.holdings, hasLength(1));
  });
}

AssetItem _asset(
  int id,
  String title, {
  bool hidden = false,
  List<HoldingItem> holdings = const [],
}) => AssetItem(
  id: id,
  clientId: 'group-$id',
  assetType: 'stock',
  title: title,
  alias: '',
  isHidden: hidden,
  value: '',
  change: '',
  icon: Icons.account_balance,
  quantityLabel: '',
  quantityValue: '',
  averageLabel: '',
  averageValue: '',
  note: '',
  holdings: holdings,
  transactions: const [],
);

HoldingItem _holding(int id, String name, {bool hidden = false}) => HoldingItem(
  id: id,
  clientId: 'holding-$id',
  name: name,
  symbol: '',
  quantity: 1,
  averagePrice: 1,
  currentPrice: 1,
  note: '',
  transactions: const [],
  isHidden: hidden,
  currencyCode: id < 0 ? 'USD' : 'KRW',
);

DailyPortfolioSnapshot _snapshot(double rate) => DailyPortfolioSnapshot(
  id: 1,
  snapshotDate: '2026-11-23',
  totalPurchaseAmount: 0,
  totalValuationAmount: 0,
  profitAmount: 0,
  profitRate: 0,
  exchangeRate: rate,
  createdAt: '',
);

DailyPortfolioSnapshotItem _group(
  int id,
  String title, {
  String? clientId,
  required int count,
  required double purchase,
  required double value,
}) => DailyPortfolioSnapshotItem(
  id: id,
  snapshotId: 1,
  assetId: id,
  assetClientId: clientId,
  assetTitle: title,
  totalPurchaseAmount: purchase,
  totalValuationAmount: value,
  profitAmount: value - purchase,
  profitRate: 0,
  holdingCount: count,
);

DailyPortfolioSnapshotHoldingItem _position(
  int groupId,
  int? id,
  String name, {
  required double purchase,
  required double value,
}) => DailyPortfolioSnapshotHoldingItem(
  id: id ?? groupId,
  snapshotId: 1,
  assetId: groupId,
  assetTitle: '',
  holdingId: id,
  holdingName: name,
  holdingSymbol: '',
  currencyCode: 'KRW',
  quantity: 1,
  totalPurchaseAmount: purchase,
  totalValuationAmount: value,
  profitAmount: value - purchase,
  profitRate: 0,
);
