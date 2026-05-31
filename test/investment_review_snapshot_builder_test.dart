import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_snapshot_builder.dart';

void main() {
  late AppDatabase db;
  late InvestmentReviewSnapshotBuilder builder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    builder = InvestmentReviewSnapshotBuilder(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createStockAsset() {
    return db.createAsset(
      assetType: '주식',
      title: '주식',
      alias: '주식',
      hidden: false,
      currencyCode: 'KRW',
      value: '0',
      change: '+0.0%',
      icon: Icons.show_chart_rounded,
      quantityLabel: '수량',
      quantityValue: '0주',
      averageLabel: '평균단가',
      averageValue: '0원',
      note: '',
    );
  }

  Future<int> createUsdStockAsset() {
    return db.createAsset(
      assetType: '주식',
      title: '미국 주식',
      alias: '미국 주식',
      hidden: false,
      currencyCode: 'USD',
      value: '0',
      change: '+0.0%',
      icon: Icons.show_chart_rounded,
      quantityLabel: '수량',
      quantityValue: '0주',
      averageLabel: '평균단가',
      averageValue: '0달러',
      note: '',
    );
  }

  test('no activity returns low-data report for today', () async {
    final report = await builder.build(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 5, 31, 10),
    );

    expect(report.period.type, InvestmentReviewPeriodType.today);
    expect(report.period.from, DateTime(2026, 5, 31));
    expect(report.period.to, DateTime(2026, 5, 31));
    expect(report.hasEnoughData, isFalse);
    expect(report.metrics, isEmpty);
    expect(report.narrative.headline, '오늘 회고를 만들 기록이 더 필요해요.');
    expect(report.aiState.enabled, isFalse);
  });

  test('buy and sell transactions in week produce weekly report', () async {
    final assetId = await createStockAsset();
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '테스트 주식',
      symbol: 'TEST',
      quantity: 0,
      averagePrice: 0,
      currentPrice: 100,
      note: '',
    );
    await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '결제 현금',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.26',
      type: '매수',
      name: '매수',
      amount: '100',
      quantity: '5',
    );
    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.27',
      type: '매도',
      name: '매도',
      amount: '120',
      quantity: '2',
      manualRealizedProfitAmount: 100,
    );

    final report = await builder.build(
      InvestmentReviewPeriodType.weekly,
      now: DateTime(2026, 5, 31, 10),
    );

    expect(report.period.type, InvestmentReviewPeriodType.weekly);
    expect(report.hasEnoughData, isTrue);
    expect(report.metrics.map((metric) => metric.label), contains('순 투자성과'));
    expect(report.metrics.map((metric) => metric.label), contains('거래 활동'));
    expect(report.signals.map((signal) => signal.title), contains('거래 판단 복기'));
    expect(report.aiState.enabled, isFalse);
  });

  test('USD realized performance is converted to KRW before formatting', () async {
    await db.saveExchangeRate(
      currencyPair: 'USD/KRW',
      rate: 1400,
      recordedAt: '2026-05-31T00:00:00',
    );
    final assetId = await createUsdStockAsset();
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'USD',
      exchangeCode: 'NAS',
      name: '테스트 미국 주식',
      symbol: 'TUSD',
      quantity: 0,
      averagePrice: 0,
      currentPrice: 100,
      note: '',
    );
    await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'USD',
      name: 'USD 현금',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.26',
      type: '매수',
      name: '매수',
      amount: '100',
      quantity: '5',
      tradeFxRate: 1400,
    );
    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.27',
      type: '매도',
      name: '매도',
      amount: '120',
      quantity: '2',
      manualRealizedProfitAmount: 100,
      tradeFxRate: 1400,
    );

    final report = await builder.build(
      InvestmentReviewPeriodType.weekly,
      now: DateTime(2026, 5, 31, 10),
    );

    final purePerformance = report.metrics.singleWhere(
      (metric) => metric.label == '순 투자성과',
    );
    expect(purePerformance.value, contains('140,000'));
  });

  test('weekly report excludes future-dated transactions', () async {
    final assetId = await createStockAsset();
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '테스트 주식',
      symbol: 'TEST',
      quantity: 0,
      averagePrice: 0,
      currentPrice: 100,
      note: '',
    );
    await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '결제 현금',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.30',
      type: '매수',
      name: '미래 매수',
      amount: '100',
      quantity: '5',
    );

    final report = await builder.build(
      InvestmentReviewPeriodType.weekly,
      now: DateTime(2026, 5, 27, 10),
    );

    expect(report.period.to, DateTime(2026, 5, 27));
    expect(report.hasEnoughData, isFalse);
    expect(report.activity.totalCount, 0);
  });
}
