import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

void main() {
  late AppDatabase db;
  late int assetId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    assetId = await db.createAsset(
      assetType: '주식',
      title: '테스트 자산',
      alias: '',
      hidden: false,
      currencyCode: 'KRW',
      value: '0',
      change: '',
      icon: Icons.wallet,
      quantityLabel: '',
      quantityValue: '',
      averageLabel: '',
      averageValue: '',
      note: '',
    );
  });
  tearDown(() async => db.close());

  Future<int> cash(String name, double balance, {String currency = 'KRW'}) =>
      db.createCashAccount(
        assetId: assetId,
        currencyCode: currency,
        name: name,
        note: '',
        balance: balance,
      );

  Future<double> balance(int id) async =>
      (await db.fetchHoldingById(id))!.quantity;

  test('failed buy edit keeps the original trade and settlement cash', () async {
    final holding = await db.createHolding(
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
    final settlement = await cash('결제 현금', 1000);
    await db.createTransaction(
      assetId: assetId,
      holdingId: holding,
      date: '2026-11-15',
      type: '매수',
      name: '원래 매수',
      amount: '100',
      quantity: '5',
    );
    final original = (await db.fetchAssets())
        .expand((asset) => asset.holdings)
        .firstWhere((item) => item.id == holding)
        .transactions
        .firstWhere((item) => item.type == '매수');
    await expectLater(
      db.updateTransactionItem(
        TransactionItem(
          id: original.id,
          assetId: assetId,
          holdingId: holding,
          date: '2026-11-15',
          type: '매수',
          name: '초과 매수',
          amount: '1001',
          quantity: '1',
          ledgerEventId: original.ledgerEventId,
          ledgerLineId: original.ledgerLineId,
        ),
      ),
      throwsStateError,
    );
    expect(await balance(holding), 5);
    expect(await balance(settlement), 500);
    final events = await db
        .customSelect(
          'SELECT title FROM transaction_events WHERE deleted_at IS NULL AND kind = ?',
          variables: [Variable.withString('trade')],
        )
        .get();
    expect(events.single.read<String>('title'), '원래 매수');
  });

  test(
    'failed sell edit keeps the original sale and settlement cash',
    () async {
      final holding = await db.createHolding(
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
      final settlement = await cash('결제 현금', 1000);
      await db.createTransaction(
        assetId: assetId,
        holdingId: holding,
        date: '2026-11-15',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holding,
        date: '2026-11-15',
        type: '매도',
        name: '원래 매도',
        amount: '120',
        quantity: '2',
      );
      final original = (await db.fetchAssets())
          .expand((asset) => asset.holdings)
          .firstWhere((item) => item.id == holding)
          .transactions
          .firstWhere((item) => item.type == '매도');
      await expectLater(
        db.updateTransactionItem(
          TransactionItem(
            id: original.id,
            assetId: assetId,
            holdingId: holding,
            date: '2026-11-15',
            type: '매도',
            name: '초과 매도',
            amount: '120',
            quantity: '6',
            ledgerEventId: original.ledgerEventId,
            ledgerLineId: original.ledgerLineId,
          ),
        ),
        throwsStateError,
      );
      expect(await balance(holding), 3);
      expect(await balance(settlement), 740);
    },
  );

  test('two simultaneous transfers cannot overdraw one source', () async {
    final source = await cash('출금', 100);
    final first = await cash('첫째', 0);
    final second = await cash('둘째', 0);
    final results = await Future.wait(
      [first, second].map((target) async {
        try {
          await db.createCashTransfer(
            assetId: assetId,
            sourceHoldingId: source,
            targetHoldingId: target,
            date: '2026-11-15',
            name: '동시 이체',
            amount: '80',
          );
          return true;
        } on StateError {
          return false;
        }
      }),
    );
    expect(results.where((succeeded) => succeeded), hasLength(1));
    expect(await balance(source), 20);
    expect(await balance(first) + await balance(second), 80);
  });

  test(
    'cross-currency transfer is rejected without changing balances',
    () async {
      final krw = await cash('원화', 1000);
      final usd = await cash('달러', 0, currency: 'USD');
      await expectLater(
        db.createCashTransfer(
          assetId: assetId,
          sourceHoldingId: krw,
          targetHoldingId: usd,
          date: '2026-11-15',
          name: '잘못된 이체',
          amount: '100',
        ),
        throwsStateError,
      );
      expect(await balance(krw), 1000);
      expect(await balance(usd), 0);
    },
  );

  test('two simultaneous exchanges cannot overdraw one source', () async {
    final krw = await cash('원화', 100);
    final results = await Future.wait(
      List.generate(2, (_) async {
        try {
          await db.createCashExchange(
            assetId: assetId,
            sourceHoldingId: krw,
            date: '2026-11-15',
            name: '동시 환전',
            amount: '80',
            exchangeRate: 10,
          );
          return true;
        } on StateError {
          return false;
        }
      }),
    );
    expect(results.where((succeeded) => succeeded), hasLength(1));
    expect(await balance(krw), 20);
    final usd = (await db.fetchAssets())
        .expand((asset) => asset.holdings)
        .firstWhere((holding) => holding.currencyCode == 'USD');
    expect(usd.quantity, 8);
  });

  test('invalid exchange rate does not create an orphan USD account', () async {
    final krw = await cash('원화', 100);
    await expectLater(
      db.createCashExchange(
        assetId: assetId,
        sourceHoldingId: krw,
        date: '2026-11-15',
        name: '잘못된 환전',
        amount: '80',
        exchangeRate: double.nan,
      ),
      throwsStateError,
    );
    expect(await balance(krw), 100);
    expect(
      (await db.fetchAssets())
          .expand((asset) => asset.holdings)
          .where((holding) => holding.currencyCode == 'USD'),
      isEmpty,
    );
  });
}
