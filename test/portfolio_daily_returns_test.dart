import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createAsset() {
    return db.createAsset(
      assetType: '주식',
      title: '주식',
      alias: '주식',
      hidden: false,
      currencyCode: 'KRW',
      value: '0',
      change: '+0.0%',
      icon: Icons.account_balance_wallet_rounded,
      quantityLabel: '항목',
      quantityValue: '0개',
      averageLabel: '수익률',
      averageValue: '+0.0%',
      note: '',
    );
  }

  Future<void> insertSnapshot({
    required String date,
    required double valuation,
  }) async {
    await db.customStatement(
      '''
        INSERT INTO daily_portfolio_snapshots (
          snapshot_date,
          total_purchase_amount,
          total_valuation_amount,
          profit_amount,
          profit_rate,
          exchange_rate,
          created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [date, valuation, valuation, 0, 0, 1, '${date}T00:00:00'],
    );
  }

  Future<void> insertExternalCashFlow({
    required String date,
    required String action,
    required String currencyCode,
    required double cashDelta,
    double? fxRate,
  }) async {
    await db.customStatement(
      '''
        INSERT INTO transaction_events (
          occurred_at,
          kind,
          title,
          source,
          flow_category
        ) VALUES (?, 'cash_flow', '외부 현금흐름', 'manual', ?)
      ''',
      [date, action == 'deposit' ? 'external_deposit' : 'external_withdrawal'],
    );
    final eventId =
        (await db.customSelect('SELECT last_insert_rowid() AS id').getSingle())
            .read<int>('id');
    await db.customStatement(
      '''
        INSERT INTO transaction_lines (
          event_id,
          action,
          currency_code,
          cash_delta,
          fx_rate,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, 0)
      ''',
      [eventId, action, currencyCode, cashDelta, fxRate],
    );
  }

  Future<Map<String, double>> holdingTotals() async {
    final row = await db.customSelect('''
      SELECT
        COALESCE(SUM(quantity), 0) AS quantity_sum,
        COALESCE(SUM(cost_basis_krw), 0) AS cost_basis_sum,
        COALESCE(SUM(quantity * current_price), 0) AS valuation_sum
      FROM holdings
      WHERE deleted_at IS NULL
    ''').getSingle();
    return {
      'quantity': row.read<double>('quantity_sum'),
      'costBasis': row.read<double>('cost_basis_sum'),
      'valuation': row.read<double>('valuation_sum'),
    };
  }

  test('portfolio daily returns table is available', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'portfolio_daily_returns'",
        )
        .get();

    expect(rows.map((row) => row.read<String>('name')), [
      'portfolio_daily_returns',
    ]);
  });

  test('rebuild derives cash-flow adjusted daily returns', () async {
    await insertSnapshot(date: '2026-05-01', valuation: 1000000);
    await insertSnapshot(date: '2026-05-02', valuation: 1650000);
    await insertSnapshot(date: '2026-05-03', valuation: 1600000);
    await insertExternalCashFlow(
      date: '2026-05-02',
      action: 'deposit',
      currencyCode: 'KRW',
      cashDelta: 500000,
    );

    final inserted = await db.rebuildPortfolioDailyReturns();
    final rows = await db.fetchPortfolioDailyReturns();

    expect(inserted, 3);
    expect(rows.map((row) => row.returnDate), [
      '2026-05-01',
      '2026-05-02',
      '2026-05-03',
    ]);
    expect(rows[0].beginningValueKrw, isNull);
    expect(rows[0].dailyReturn, isNull);
    expect(rows[0].dataQuality, 'missing_snapshot');
    expect(rows[1].beginningValueKrw, 1000000);
    expect(rows[1].endingValueKrw, 1650000);
    expect(rows[1].portfolioValueKrw, 1650000);
    expect(rows[1].externalCashFlowKrw, 500000);
    expect(rows[1].dailyReturn, closeTo(0.15, 1e-12));
    expect(rows[1].dataQuality, 'complete');
    expect(rows[2].dailyReturn, closeTo(-50000 / 1650000, 1e-12));
  });

  test('rebuild marks missing snapshots and missing fx fallback', () async {
    await db.saveExchangeRate(
      currencyPair: 'USD/KRW',
      rate: 1300,
      recordedAt: '2026-05-01T00:00:00',
    );
    await insertSnapshot(date: '2026-05-01', valuation: 1000000);
    await insertSnapshot(date: '2026-05-03', valuation: 2300000);
    await insertExternalCashFlow(
      date: '2026-05-03',
      action: 'deposit',
      currencyCode: 'USD',
      cashDelta: 1000,
    );

    await db.rebuildPortfolioDailyReturns();
    final rows = await db.fetchPortfolioDailyReturns();

    expect(rows, hasLength(2));
    expect(rows[1].returnDate, '2026-05-03');
    expect(rows[1].beginningValueKrw, isNull);
    expect(rows[1].dailyReturn, isNull);
    expect(rows[1].externalCashFlowKrw, 1300000);
    expect(rows[1].dataQuality, 'missing_snapshot');
  });

  test(
    'rebuild marks missing fx when USD cash flow uses fallback rate',
    () async {
      await db.saveExchangeRate(
        currencyPair: 'USD/KRW',
        rate: 1300,
        recordedAt: '2026-05-01T00:00:00',
      );
      await insertSnapshot(date: '2026-05-01', valuation: 1000000);
      await insertSnapshot(date: '2026-05-02', valuation: 2300000);
      await insertExternalCashFlow(
        date: '2026-05-02',
        action: 'deposit',
        currencyCode: 'USD',
        cashDelta: 1000,
      );

      await db.rebuildPortfolioDailyReturns();
      final rows = await db.fetchPortfolioDailyReturns();

      expect(rows, hasLength(2));
      expect(rows[1].externalCashFlowKrw, 1300000);
      expect(rows[1].dailyReturn, 0);
      expect(rows[1].dataQuality, 'missing_fx');
    },
  );

  test('rebuild does not mutate source portfolio tables', () async {
    final assetId = await createAsset();
    await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '테스트 주식',
      symbol: 'TEST',
      quantity: 10,
      averagePrice: 1000,
      currentPrice: 1200,
      note: '',
    );
    await insertSnapshot(date: '2026-05-01', valuation: 12000);
    await insertSnapshot(date: '2026-05-02', valuation: 13000);
    await insertExternalCashFlow(
      date: '2026-05-02',
      action: 'deposit',
      currencyCode: 'KRW',
      cashDelta: 1000,
    );
    final beforeHoldingTotals = await holdingTotals();
    final beforeLineCount =
        (await db
                .customSelect('SELECT COUNT(*) AS count FROM transaction_lines')
                .getSingle())
            .read<int>('count');

    await db.rebuildPortfolioDailyReturns();

    expect(await holdingTotals(), beforeHoldingTotals);
    final afterLineCount =
        (await db
                .customSelect('SELECT COUNT(*) AS count FROM transaction_lines')
                .getSingle())
            .read<int>('count');
    expect(afterLineCount, beforeLineCount);
  });
}
