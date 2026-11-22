import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/components/charts/value_history_card.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/account/widgets/total_asset_history_card.dart';

void main() {
  testWidgets('total history loads period data and scrubs snapshot values', (
    tester,
  ) async {
    final snapshots = [
      _snapshot(1, '2018-11-22'),
      _snapshot(2, '2026-08-22'),
      _snapshot(3, '2026-11-16'),
      _snapshot(4, '2026-11-22'),
    ];
    final requests = <List<String>>[];
    final items = [
      _item(1, 1, 40),
      _item(2, 2, 100),
      _item(3, 3, 150, assetId: 2, assetTitle: '주식'),
      _item(4, 4, 120),
      _item(5, 4, 80, assetId: 2, assetTitle: '주식'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TotalAssetHistoryCard(
            snapshots: snapshots,
            loadItems: (dates) async {
              requests.add(dates);
              final ids = snapshots
                  .where((snapshot) => dates.contains(snapshot.snapshotDate))
                  .map((snapshot) => snapshot.id)
                  .toSet();
              return items
                  .where((item) => ids.contains(item.snapshotId))
                  .toList();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('총자산 변화'), findsOneWidget);
    expect(requests.single, ['2026-08-22', '2026-11-16', '2026-11-22']);
    expect(find.text('₩200'), findsOneWidget);
    expect(find.text('기간 등락률 +100.00%'), findsOneWidget);
    expect(find.text('기간 평균 자산  150원'), findsOneWidget);
    for (final period in HistoryPeriod.values) {
      expect(find.widgetWithText(ChoiceChip, period.label), findsOneWidget);
    }

    final chart = find.bySemanticsLabel('날짜별 총자산 차트');
    final chartRect = tester.getRect(chart);
    final plot = find
        .descendant(of: chart, matching: find.byType(CustomPaint))
        .first;
    expect(
      plot,
      paints..circle(
        y: tester.getSize(plot).height / 2,
        color: tester.element(chart).colors.neutralTextMuted,
      ),
    );
    final stockChip = find.widgetWithText(FilterChip, '주식');
    expect(tester.widget<FilterChip>(stockChip).selected, isFalse);
    expect(
      (tester.widget<FilterChip>(stockChip).avatar as Icon).color,
      isNot(VisualSpec.brand.seedColor),
    );
    await tester.tap(stockChip);
    await tester.pumpAndSettle();
    expect(find.text('주식 · ₩80'), findsOneWidget);
    expect(plot, paintsExactlyCountTimes(#drawPath, 3));
    await tester.tap(find.widgetWithText(FilterChip, '현금'));
    await tester.pumpAndSettle();
    expect(find.text('현금 · ₩120'), findsOneWidget);
    await tester.tapAt(chartRect.centerLeft + const Offset(2, 0));
    await tester.pump();
    expect(find.text('2026-08-22 총자산'), findsOneWidget);
    expect(find.text('₩100'), findsOneWidget);
    expect(find.text('주식 · —'), findsOneWidget);
    expect(find.text('현금 · ₩100'), findsOneWidget);
    await tester.dragFrom(
      chartRect.centerLeft + const Offset(2, 0),
      Offset(chartRect.width / 2, 0),
    );
    await tester.pump();
    expect(find.text('₩150'), findsOneWidget);
    expect(find.text('주식 · ₩150'), findsOneWidget);
    expect(find.text('기간 평균 자산  150원'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '1주'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(find.text('기간 등락률 +33.33%'), findsOneWidget);
    expect(find.text('기간 평균 자산  175원'), findsOneWidget);
    expect(find.text('₩200'), findsOneWidget);
    expect(find.text('주식 · ₩80'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '10년'));
    await tester.pumpAndSettle();
    expect(requests.last, ['2018-11-22']);
    expect(find.text('기간 등락률 +400.00%'), findsOneWidget);
    expect(find.text('기간 평균 자산  123원'), findsOneWidget);
    expect(find.textContaining('10년 중 제공 구간'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '주식 · ₩80'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(stockChip).selected, isFalse);
    expect(plot, paintsExactlyCountTimes(#drawPath, 3));
  });

  testWidgets('a zero total remains selectable and has no undefined return', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TotalAssetHistoryCard(
            snapshots: [_snapshot(1, '2026-11-21'), _snapshot(2, '2026-11-22')],
            loadItems: (_) async => [_item(1, 1, 0), _item(2, 2, 0)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chart = find.bySemanticsLabel('날짜별 총자산 차트');
    await tester.tapAt(tester.getRect(chart).centerLeft + const Offset(2, 0));
    await tester.pumpAndSettle();
    expect(find.text('₩0'), findsOneWidget);
    expect(find.text('기간 평균 자산  0원'), findsOneWidget);
    expect(find.text('2026-11-21 총자산'), findsOneWidget);
    expect(find.textContaining('기간 등락률'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

DailyPortfolioSnapshot _snapshot(int id, String date) => DailyPortfolioSnapshot(
  id: id,
  snapshotDate: date,
  totalPurchaseAmount: 0,
  totalValuationAmount: 900,
  profitAmount: 0,
  profitRate: 0,
  exchangeRate: 1,
  createdAt: date,
);

DailyPortfolioSnapshotItem _item(
  int id,
  int snapshot,
  double amount, {
  int assetId = 1,
  String assetTitle = '현금',
}) => DailyPortfolioSnapshotItem(
  id: id,
  snapshotId: snapshot,
  assetId: assetId,
  assetTitle: assetTitle,
  totalPurchaseAmount: 0,
  totalValuationAmount: amount,
  profitAmount: 0,
  profitRate: 0,
  holdingCount: 1,
);
