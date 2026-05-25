import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/models/asset_item.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createAsset(String type) {
    return db.createAsset(
      assetType: type,
      title: type,
      alias: type,
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

  Future<HoldingItem> findHolding(int holdingId) async {
    final holding = await db.fetchHoldingById(holdingId);
    expect(holding, isNotNull);
    return holding!;
  }

  test('normalized ledger tables are available beside legacy tables', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('transaction_events', 'transaction_lines')",
        )
        .get();
    final tableNames = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      tableNames,
      containsAll(['transaction_events', 'transaction_lines']),
    );
  });

  test(
    'old transaction event tables gain flow category before index creation',
    () async {
      await db.close();
      final tempDir = Directory.systemTemp.createTempSync(
        'moneyfy_migration_test_',
      );
      try {
        final file = File('${tempDir.path}/db.sqlite');
        db = AppDatabase.forTesting(
          NativeDatabase(
            file,
            setup: (sqlite) {
              sqlite.execute('''
              CREATE TABLE transaction_events (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                client_id TEXT,
                dirty INTEGER NOT NULL DEFAULT 0,
                last_modified_at TEXT,
                deleted_at TEXT,
                occurred_at TEXT NOT NULL,
                kind TEXT NOT NULL,
                title TEXT NOT NULL DEFAULT '',
                memo TEXT NOT NULL DEFAULT '',
                source TEXT NOT NULL DEFAULT 'manual',
                legacy_source_table TEXT,
                legacy_source_id INTEGER,
                sort_order INTEGER NOT NULL DEFAULT 0
              )
            ''');
              sqlite.execute('PRAGMA user_version = 31');
            },
          ),
        );
        final columnRows = await db
            .customSelect("PRAGMA table_info('transaction_events')")
            .get();
        final columnNames = columnRows.map((row) => row.read<String>('name'));
        expect(columnNames, contains('flow_category'));

        final indexRows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'transaction_events_flow_category_idx'",
            )
            .get();
        expect(indexRows, hasLength(1));
      } finally {
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        tempDir.deleteSync(recursive: true);
      }
    },
  );

  test('cash withdrawal normalizes signed input and blocks overdraft', () async {
    final assetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '생활비',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: cashHoldingId,
      date: '2026.05.21',
      type: '출금',
      name: '출금',
      amount: '-100',
      quantity: '',
    );

    final holding = await findHolding(cashHoldingId);
    expect(holding.quantity, 900);
    expect(holding.transactions.single.flowCategory, 'external_withdrawal');
    final eventRow = await db
        .customSelect(
          "SELECT flow_category FROM transaction_events WHERE kind = 'cash_flow' AND deleted_at IS NULL LIMIT 1",
        )
        .getSingle();
    expect(eventRow.read<String>('flow_category'), 'external_withdrawal');

    expect(
      () => db.createTransaction(
        assetId: assetId,
        holdingId: cashHoldingId,
        date: '2026.05.21',
        type: '출금',
        name: '초과 출금',
        amount: '901',
        quantity: '',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'cash deposit normalizes signed input and rejects zero amount',
    () async {
      final assetId = await createAsset('현금');
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '생활비',
        note: '',
        balance: 1000,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: cashHoldingId,
        date: '2026.05.21',
        type: '입금',
        name: '입금',
        amount: '-200',
        quantity: '',
      );

      expect((await findHolding(cashHoldingId)).quantity, 1200);
      final ledgerEvent = await db.customSelect('''
            SELECT source, flow_category, legacy_source_id
            FROM transaction_events
            WHERE kind = 'cash_flow' AND deleted_at IS NULL
            LIMIT 1
            ''').getSingle();
      final ledgerLine = await db.customSelect('''
            SELECT action, cash_delta
            FROM transaction_lines
            WHERE event_id = (
              SELECT id FROM transaction_events
              WHERE kind = 'cash_flow' AND deleted_at IS NULL
              LIMIT 1
            )
            AND deleted_at IS NULL
            ''').getSingle();

      expect(ledgerEvent.read<String>('source'), 'ledger');
      expect(ledgerEvent.read<String>('flow_category'), 'external_deposit');
      expect(ledgerEvent.read<int?>('legacy_source_id'), isNull);
      expect(ledgerLine.read<String>('action'), 'deposit');
      expect(ledgerLine.read<double>('cash_delta'), 200);
      expect(
        (await findHolding(cashHoldingId)).transactions.single.flowCategory,
        'external_deposit',
      );
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);

      expect(
        () => db.createTransaction(
          assetId: assetId,
          holdingId: cashHoldingId,
          date: '2026.05.21',
          type: '입금',
          name: '영원 입금',
          amount: '0',
          quantity: '',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('record-only cash transaction stays out of cash balance', () async {
    final assetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '생활비',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: cashHoldingId,
      date: '2026.05.21',
      type: '입금',
      name: '과거 기록',
      amount: '500',
      quantity: '',
      includeInCalculations: false,
    );

    final holding = await findHolding(cashHoldingId);
    expect(holding.quantity, 1000);
    expect(holding.transactions.single.name, '과거 기록');
    expect(holding.transactions.single.amount, '500');
    expect(holding.transactions.single.includeInCalculations, isFalse);

    final sourceRow = await db
        .customSelect(
          'SELECT source, flow_category FROM transaction_events WHERE title = ? AND deleted_at IS NULL',
          variables: [Variable.withString('과거 기록')],
        )
        .getSingle();
    expect(sourceRow.read<String>('source'), 'record_only');
    expect(sourceRow.read<String>('flow_category'), 'external_deposit');
  });

  test(
    'cash transfer updates both linked accounts and deletes as a pair',
    () async {
      final assetId = await createAsset('현금');
      final sourceHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '출금 계좌',
        note: '',
        balance: 1000,
      );
      final targetHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '입금 계좌',
        note: '',
        balance: 100,
      );

      final transactionId = await db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: sourceHoldingId,
        targetHoldingId: targetHoldingId,
        date: '2026.05.21',
        name: '계좌 이동',
        amount: '250',
      );

      expect((await findHolding(sourceHoldingId)).quantity, 750);
      expect((await findHolding(targetHoldingId)).quantity, 350);

      await db.updateTransactionItem(
        TransactionItem(
          id: transactionId,
          assetId: assetId,
          holdingId: sourceHoldingId,
          date: '2026.05.22',
          type: '이체',
          name: '계좌 이동 수정',
          amount: '400',
          quantity: '',
        ),
      );

      expect((await findHolding(sourceHoldingId)).quantity, 600);
      expect((await findHolding(targetHoldingId)).quantity, 500);
      final updateCounts = await db.customSelect('''
            SELECT
              SUM(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END) AS active_count,
              SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count,
              SUM(CASE WHEN flow_category = 'internal' THEN 1 ELSE 0 END) AS internal_count
            FROM transaction_events
            WHERE kind = 'cash_transfer'
            ''').getSingle();
      expect(updateCounts.read<int>('active_count'), 1);
      expect(updateCounts.read<int>('deleted_count'), 1);
      expect(updateCounts.read<int>('internal_count'), 2);

      await db.deleteTransactionItem(transactionId);

      expect((await findHolding(sourceHoldingId)).quantity, 1000);
      expect((await findHolding(targetHoldingId)).quantity, 100);
      final deleteCounts = await db.customSelect('''
            SELECT
              SUM(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END) AS active_count,
              SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count
            FROM transaction_events
            WHERE kind = 'cash_transfer'
            ''').getSingle();
      expect(deleteCounts.read<int?>('active_count') ?? 0, 0);
      expect(deleteCounts.read<int>('deleted_count'), 2);
    },
  );

  test('cash transfer blocks overdraft and same-account transfer', () async {
    final assetId = await createAsset('현금');
    final sourceHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '출금 계좌',
      note: '',
      balance: 100,
    );
    final targetHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '입금 계좌',
      note: '',
      balance: 0,
    );

    expect(
      () => db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: sourceHoldingId,
        targetHoldingId: targetHoldingId,
        date: '2026.05.21',
        name: '초과 이체',
        amount: '101',
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: sourceHoldingId,
        targetHoldingId: sourceHoldingId,
        date: '2026.05.21',
        name: '같은 계좌 이체',
        amount: '1',
      ),
      throwsA(isA<StateError>()),
    );

    expect((await findHolding(sourceHoldingId)).quantity, 100);
    expect((await findHolding(targetHoldingId)).quantity, 0);
  });

  test('cash transfer create writes one active paired ledger event', () async {
    final assetId = await createAsset('현금');
    final sourceHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '출금 계좌',
      note: '',
      balance: 1000,
    );
    final targetHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '입금 계좌',
      note: '',
      balance: 0,
    );

    await db.createCashTransfer(
      assetId: assetId,
      sourceHoldingId: sourceHoldingId,
      targetHoldingId: targetHoldingId,
      date: '2026.05.21',
      name: '계좌 이동',
      amount: '250',
    );

    final eventCount = await db
        .customSelect(
          "SELECT COUNT(*) AS count FROM transaction_events WHERE kind = 'cash_transfer' AND deleted_at IS NULL",
        )
        .getSingle();
    final eventRow = await db
        .customSelect(
          "SELECT source, legacy_source_id FROM transaction_events WHERE kind = 'cash_transfer' AND deleted_at IS NULL LIMIT 1",
        )
        .getSingle();
    final lineSummary = await db.customSelect('''
          SELECT
            SUM(CASE WHEN action = 'transfer_out' THEN cash_delta ELSE 0 END) AS out_amount,
            SUM(CASE WHEN action = 'transfer_in' THEN cash_delta ELSE 0 END) AS in_amount,
            SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count
          FROM transaction_lines
          ''').getSingle();

    expect(eventCount.read<int>('count'), 1);
    expect(eventRow.read<String>('source'), 'ledger');
    expect(eventRow.read<int?>('legacy_source_id'), isNull);
    expect(lineSummary.read<double>('out_amount'), -250);
    expect(lineSummary.read<double>('in_amount'), 250);
    expect(lineSummary.read<int>('deleted_count'), 0);
    expect(await db.fetchLedgerStateParityIssues(), isEmpty);
  });

  test('cash transfer edited to withdrawal removes linked deposit', () async {
    final assetId = await createAsset('현금');
    final sourceHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '출금 계좌',
      note: '',
      balance: 1000,
    );
    final targetHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '입금 계좌',
      note: '',
      balance: 100,
    );

    final transactionId = await db.createCashTransfer(
      assetId: assetId,
      sourceHoldingId: sourceHoldingId,
      targetHoldingId: targetHoldingId,
      date: '2026.05.21',
      name: '계좌 이동',
      amount: '250',
    );

    await db.updateTransactionItem(
      TransactionItem(
        id: transactionId,
        assetId: assetId,
        holdingId: sourceHoldingId,
        date: '2026.05.22',
        type: '출금',
        name: '출금으로 변경',
        amount: '100',
        quantity: '',
      ),
    );

    expect((await findHolding(sourceHoldingId)).quantity, 900);
    expect((await findHolding(targetHoldingId)).quantity, 100);
  });

  test(
    'cash transaction edit blocks overdraft while excluding old value',
    () async {
      final assetId = await createAsset('현금');
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '생활비',
        note: '',
        balance: 1000,
      );

      final transactionId = await db.createTransaction(
        assetId: assetId,
        holdingId: cashHoldingId,
        date: '2026.05.21',
        type: '출금',
        name: '출금',
        amount: '400',
        quantity: '',
      );

      await db.updateTransactionItem(
        TransactionItem(
          id: transactionId,
          assetId: assetId,
          holdingId: cashHoldingId,
          date: '2026.05.22',
          type: '출금',
          name: '출금 수정',
          amount: '900',
          quantity: '',
        ),
      );
      expect((await findHolding(cashHoldingId)).quantity, 100);

      expect(
        () => db.updateTransactionItem(
          TransactionItem(
            id: transactionId,
            assetId: assetId,
            holdingId: cashHoldingId,
            date: '2026.05.22',
            type: '출금',
            name: '초과 출금 수정',
            amount: '1001',
            quantity: '',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect((await findHolding(cashHoldingId)).quantity, 100);
    },
  );

  test('cash transfer edit can change source and target accounts', () async {
    final assetId = await createAsset('현금');
    final sourceHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '기존 출금',
      note: '',
      balance: 1000,
    );
    final targetHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '기존 입금',
      note: '',
      balance: 0,
    );
    final newSourceHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '새 출금',
      note: '',
      balance: 500,
    );
    final newTargetHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '새 입금',
      note: '',
      balance: 0,
    );

    final transactionId = await db.createCashTransfer(
      assetId: assetId,
      sourceHoldingId: sourceHoldingId,
      targetHoldingId: targetHoldingId,
      date: '2026.05.21',
      name: '계좌 이동',
      amount: '200',
    );

    await db.updateTransactionItem(
      TransactionItem(
        id: transactionId,
        assetId: assetId,
        holdingId: newSourceHoldingId,
        counterpartyHoldingId: newTargetHoldingId,
        date: '2026.05.22',
        type: '이체',
        name: '계좌 이동 수정',
        amount: '100',
        quantity: '',
      ),
    );

    expect((await findHolding(sourceHoldingId)).quantity, 1000);
    expect((await findHolding(targetHoldingId)).quantity, 0);
    expect((await findHolding(newSourceHoldingId)).quantity, 400);
    expect((await findHolding(newTargetHoldingId)).quantity, 100);
    expect(await db.fetchLedgerStateParityIssues(), isEmpty);
  });

  test(
    'cash account edits preserve transaction-adjusted base balance',
    () async {
      final assetId = await createAsset('현금');
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '생활비',
        note: '',
        balance: 1000,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: cashHoldingId,
        date: '2026.05.21',
        type: '출금',
        name: '출금',
        amount: '100',
        quantity: '',
      );
      final editedHolding = await findHolding(cashHoldingId);

      await db.updateHoldingItem(
        HoldingItem(
          id: editedHolding.id,
          clientId: editedHolding.clientId,
          assetId: editedHolding.assetId,
          assetTitle: editedHolding.assetTitle,
          assetType: editedHolding.assetType,
          isHidden: editedHolding.isHidden,
          currencyCode: editedHolding.currencyCode,
          exchangeRate: editedHolding.exchangeRate,
          marketUpdatedAt: editedHolding.marketUpdatedAt,
          exchangeCode: editedHolding.exchangeCode,
          name: '생활비 수정',
          symbol: editedHolding.symbol,
          quantity: editedHolding.quantity,
          averagePrice: editedHolding.averagePrice,
          currentPrice: editedHolding.currentPrice,
          note: editedHolding.note,
          transactions: editedHolding.transactions,
        ),
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: cashHoldingId,
        date: '2026.05.22',
        type: '입금',
        name: '입금',
        amount: '100',
        quantity: '',
      );

      expect((await findHolding(cashHoldingId)).quantity, 1000);
    },
  );

  test(
    'cash exchange updates linked deposit using edited exchange rate',
    () async {
      final assetId = await createAsset('현금');
      final krwHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '원화',
        note: '',
        balance: 3000,
      );

      final transactionId = await db.createCashExchange(
        assetId: assetId,
        sourceHoldingId: krwHoldingId,
        date: '2026.05.21',
        name: '달러 환전',
        amount: '1300',
        exchangeRate: 1300,
      );

      final usdHolding = (await db.fetchAssetById(
        assetId,
      ))!.holdings.singleWhere((holding) => holding.currencyCode == 'USD');
      expect((await findHolding(krwHoldingId)).quantity, 1700);
      expect(usdHolding.quantity, 1);

      await db.updateTransactionItem(
        TransactionItem(
          id: transactionId,
          assetId: assetId,
          holdingId: krwHoldingId,
          date: '2026.05.22',
          type: '환전',
          name: '달러 환전 수정',
          amount: '2600',
          quantity: '1300',
        ),
      );

      final updatedUsdHolding = (await db.fetchAssetById(
        assetId,
      ))!.holdings.singleWhere((holding) => holding.currencyCode == 'USD');
      expect((await findHolding(krwHoldingId)).quantity, 400);
      expect(updatedUsdHolding.quantity, 2);
    },
  );

  test(
    'cash exchange supports USD to KRW and exposes linked exchange rate',
    () async {
      final assetId = await createAsset('현금');
      final usdHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'USD',
        name: '달러',
        note: '',
        balance: 10,
      );

      final transactionId = await db.createCashExchange(
        assetId: assetId,
        sourceHoldingId: usdHoldingId,
        date: '2026.05.21',
        name: '원화 환전',
        amount: '2',
        exchangeRate: 1300,
      );

      final krwHolding = (await db.fetchAssetById(
        assetId,
      ))!.holdings.singleWhere((holding) => holding.currencyCode == 'KRW');
      expect((await findHolding(usdHoldingId)).quantity, 8);
      expect(krwHolding.quantity, 2600);
      expect(await db.fetchLinkedCashExchangeRate(transactionId.abs()), 1300);
    },
  );

  test('cash exchange create writes one active paired ledger event', () async {
    final assetId = await createAsset('현금');
    final krwHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '원화',
      note: '',
      balance: 3000,
    );

    await db.createCashExchange(
      assetId: assetId,
      sourceHoldingId: krwHoldingId,
      date: '2026.05.21',
      name: '달러 환전',
      amount: '1300',
      exchangeRate: 1300,
    );

    final eventCount = await db
        .customSelect(
          "SELECT COUNT(*) AS count FROM transaction_events WHERE kind = 'fx_exchange' AND deleted_at IS NULL",
        )
        .getSingle();
    final eventRow = await db
        .customSelect(
          "SELECT source, flow_category, legacy_source_id FROM transaction_events WHERE kind = 'fx_exchange' AND deleted_at IS NULL LIMIT 1",
        )
        .getSingle();
    final lineSummary = await db.customSelect('''
          SELECT
            SUM(CASE WHEN action = 'fx_out' THEN cash_delta ELSE 0 END) AS out_amount,
            SUM(CASE WHEN action = 'fx_in' THEN cash_delta ELSE 0 END) AS in_amount,
            SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count
          FROM transaction_lines
          ''').getSingle();

    expect(eventCount.read<int>('count'), 1);
    expect(eventRow.read<String>('source'), 'ledger');
    expect(eventRow.read<String>('flow_category'), 'internal');
    expect(eventRow.read<int?>('legacy_source_id'), isNull);
    expect(lineSummary.read<double>('out_amount'), -1300);
    expect(lineSummary.read<double>('in_amount'), 1);
    expect(lineSummary.read<int>('deleted_count'), 0);
    expect(await db.fetchLedgerStateParityIssues(), isEmpty);
  });

  test(
    'cash exchange blocks zero amount, invalid rate, and overdraft',
    () async {
      final assetId = await createAsset('현금');
      final krwHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '원화',
        note: '',
        balance: 100,
      );

      expect(
        () => db.createCashExchange(
          assetId: assetId,
          sourceHoldingId: krwHoldingId,
          date: '2026.05.21',
          name: '영원 환전',
          amount: '0',
          exchangeRate: 1300,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => db.createCashExchange(
          assetId: assetId,
          sourceHoldingId: krwHoldingId,
          date: '2026.05.21',
          name: '환율 오류',
          amount: '1',
          exchangeRate: 0,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => db.createCashExchange(
          assetId: assetId,
          sourceHoldingId: krwHoldingId,
          date: '2026.05.21',
          name: '초과 환전',
          amount: '101',
          exchangeRate: 1300,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await findHolding(krwHoldingId)).quantity, 100);
    },
  );

  test(
    'buy and sell synchronize settlement cash and holding quantity',
    () async {
      final assetId = await createAsset('주식');
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
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );

      expect((await findHolding(holdingId)).quantity, 5);
      expect((await findHolding(cashHoldingId)).quantity, 500);

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '매도',
        amount: '120',
        quantity: '2',
      );

      expect((await findHolding(holdingId)).quantity, 3);
      expect((await findHolding(cashHoldingId)).quantity, 740);

      expect(
        () => db.createTransaction(
          assetId: assetId,
          holdingId: holdingId,
          date: '2026.05.23',
          type: '매도',
          name: '초과 매도',
          amount: '100',
          quantity: '4',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('investment transaction edit can move to another holding', () async {
    final assetId = await createAsset('주식');
    final firstHoldingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '첫 보유',
      symbol: 'ONE',
      quantity: 0,
      averagePrice: 0,
      currentPrice: 100,
      note: '',
    );
    final secondHoldingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '둘째 보유',
      symbol: 'TWO',
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

    final transactionId = await db.createTransaction(
      assetId: assetId,
      holdingId: firstHoldingId,
      date: '2026.05.21',
      type: '매수',
      name: '보유 이동 매수',
      amount: '100',
      quantity: '5',
    );

    await db.updateTransactionItem(
      TransactionItem(
        id: transactionId,
        assetId: assetId,
        holdingId: secondHoldingId,
        date: '2026.05.22',
        type: '매수',
        name: '보유 이동 매수 수정',
        amount: '100',
        quantity: '5',
      ),
    );

    expect((await findHolding(firstHoldingId)).quantity, 0);
    expect((await findHolding(secondHoldingId)).quantity, 5);
    expect(await db.fetchLedgerStateParityIssues(), isEmpty);
  });

  test(
    'record-only buy is visible but does not change holding or cash',
    () async {
      final assetId = await createAsset('주식');
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
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '기록용 매수',
        amount: '100',
        quantity: '5',
        includeInCalculations: false,
      );

      final holding = await findHolding(holdingId);
      expect(holding.quantity, 0);
      expect(holding.transactions.single.name, '기록용 매수');
      expect(holding.transactions.single.quantity, '5');
      expect(holding.transactions.single.includeInCalculations, isFalse);
      expect((await findHolding(cashHoldingId)).quantity, 1000);
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);
    },
  );

  test(
    'buy and sell persist normalized cash flow and realized profit',
    () async {
      final assetId = await createAsset('주식');
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
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '매도',
        amount: '120',
        quantity: '2',
      );

      final holdingTransactions = (await findHolding(holdingId)).transactions;
      final buy = holdingTransactions.singleWhere((tx) => tx.type == '매수');
      final sell = holdingTransactions.singleWhere((tx) => tx.type == '매도');

      expect(buy.unitPrice, 100);
      expect(buy.quantityValue, 5);
      expect(buy.grossAmount, 500);
      expect(buy.cashFlowAmount, -500);
      expect(buy.realizedProfitAmount, 0);
      expect(sell.unitPrice, 120);
      expect(sell.quantityValue, 2);
      expect(sell.grossAmount, 240);
      expect(sell.cashFlowAmount, 240);
      expect(sell.realizedProfitAmount, 40);

      final cashTransactions = (await findHolding(cashHoldingId)).transactions;
      expect(cashTransactions.map((tx) => tx.cashFlowAmount), [-500, 240]);
    },
  );

  test('legacy investment transactions convert to normalized ledger lines', () async {
    final assetId = await createAsset('주식');
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
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '결제 현금',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.21',
      type: '매수',
      name: '매수',
      amount: '100',
      quantity: '5',
    );
    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.22',
      type: '매도',
      name: '매도',
      amount: '120',
      quantity: '2',
    );

    final holdingLine = await db
        .customSelect(
          'SELECT SUM(quantity_delta) AS quantity, SUM(realized_pnl) AS realized FROM transaction_lines WHERE holding_id = ? AND deleted_at IS NULL',
          variables: [Variable.withInt(holdingId)],
        )
        .getSingle();
    final cashLine = await db
        .customSelect(
          'SELECT SUM(cash_delta) AS cash_delta FROM transaction_lines WHERE cash_account_id = ? AND deleted_at IS NULL',
          variables: [Variable.withInt(cashHoldingId.abs())],
        )
        .getSingle();
    final eventCount = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM transaction_events WHERE deleted_at IS NULL',
        )
        .getSingle();

    expect(holdingLine.read<double>('quantity'), 3);
    expect(holdingLine.read<double>('realized'), 40);
    expect(cashLine.read<double>('cash_delta'), -260);
    expect(eventCount.read<int>('count'), 2);

    final performance = await db.fetchLedgerHoldingPerformanceByHoldingId();
    expect(performance[holdingId]?.quantity, 3);
    expect(performance[holdingId]?.remainingCost, 300);
    expect(performance[holdingId]?.realizedPnl, 40);
    expect(performance[holdingId]?.buyAmount, 500);
    expect(performance[holdingId]?.sellAmount, 240);

    final portfolioPerformance = await db.fetchLedgerPortfolioPerformance();
    expect(portfolioPerformance.realizedPnl, 40);
    expect(portfolioPerformance.pureRealizedPerformance, 40);
    expect(portfolioPerformance.tradeSettlementCashFlowAmount, -260);
    expect(portfolioPerformance.externalCashFlowAmount, 0);
    expect(portfolioPerformance.buyAmount, 500);
    expect(portfolioPerformance.sellAmount, 240);
  });

  test(
    'ledger state parity matches legacy holdings and cash balances',
    () async {
      final assetId = await createAsset('주식');
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
      final settlementCashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );
      final savingsCashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '저축 현금',
        note: '',
        balance: 100,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '매도',
        amount: '120',
        quantity: '2',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: settlementCashHoldingId,
        date: '2026.05.23',
        type: '입금',
        name: '추가입금',
        amount: '50',
        quantity: '',
      );
      await db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: settlementCashHoldingId,
        targetHoldingId: savingsCashHoldingId,
        date: '2026.05.24',
        name: '계좌 이동',
        amount: '25',
      );

      expect(await db.fetchLedgerStateParityIssues(), isEmpty);
    },
  );

  test('legacy writes mark replacement ledger events dirty for sync', () async {
    final assetId = await createAsset('주식');
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

    final transactionId = await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.21',
      type: '매수',
      name: '매수',
      amount: '100',
      quantity: '5',
    );
    final firstEvent = await db
        .customSelect(
          "SELECT id, client_id FROM transaction_events WHERE id = ? AND deleted_at IS NULL",
          variables: [Variable.withInt(transactionId)],
        )
        .getSingle();

    await db.updateTransactionItem(
      TransactionItem(
        id: transactionId,
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수 수정',
        amount: '120',
        quantity: '5',
      ),
    );

    final replacedEvent = await db
        .customSelect(
          'SELECT dirty, deleted_at FROM transaction_events WHERE id = ?',
          variables: [Variable.withInt(firstEvent.read<int>('id'))],
        )
        .getSingle();
    final activeEvent = await db
        .customSelect(
          "SELECT id, dirty FROM transaction_events WHERE legacy_source_table = 'transaction_events' AND legacy_source_id = ? AND deleted_at IS NULL",
          variables: [Variable.withInt(transactionId)],
        )
        .getSingle();
    final activeLine = await db
        .customSelect(
          "SELECT gross_amount FROM transaction_lines WHERE event_id = ? AND action = 'buy' AND deleted_at IS NULL",
          variables: [Variable.withInt(activeEvent.read<int>('id'))],
        )
        .getSingle();
    final payload = await db.buildDirtySyncPayload();
    final eventPayload = (payload['transaction_events'] as List)
        .whereType<Map<String, Object?>>()
        .toList(growable: false);

    expect(payload['payload_version'], 4);
    expect(payload['schema_mode'], 'ledger_only_delta');
    expect(payload.containsKey('transactions'), isFalse);
    expect(payload.containsKey('cash_transactions'), isFalse);
    expect(replacedEvent.read<bool>('dirty'), isTrue);
    expect(replacedEvent.read<String?>('deleted_at'), isNotNull);
    expect(activeEvent.read<bool>('dirty'), isTrue);
    expect(activeLine.read<double>('gross_amount'), 600);
    expect(
      eventPayload.map((row) => row['client_id']),
      contains(firstEvent.read<String>('client_id')),
    );
    expect(
      eventPayload,
      everyElement(containsPair('flow_category', 'internal')),
    );
    expect(await db.fetchLedgerStateParityIssues(), isEmpty);
  });

  test(
    'sync payload carries last_modified_at and clears accepted rows only',
    () async {
      final acceptedAssetId = await createAsset('주식');
      final conflictedAssetId = await createAsset('현금');
      final payload = await db.buildDirtySyncPayload();
      final assetPayload = (payload['assets'] as List)
          .whereType<Map>()
          .toList();

      expect(
        assetPayload,
        everyElement(containsPair('last_modified_at', isNotNull)),
      );

      final acceptedClientId =
          (await (db.select(db.assets)
                    ..where((table) => table.id.equals(acceptedAssetId)))
                  .getSingle())
              .clientId;
      final conflictedClientId =
          (await (db.select(db.assets)
                    ..where((table) => table.id.equals(conflictedAssetId)))
                  .getSingle())
              .clientId;

      await db.markDirtySyncPayloadAsSynced(payload, {
        'assets': [acceptedClientId],
        'holdings': const <String>[],
        'cash_accounts': const <String>[],
        'transaction_events': const <String>[],
        'transaction_lines': const <String>[],
      });

      final dirtyRows = await db
          .customSelect('SELECT client_id, dirty FROM assets ORDER BY title')
          .get();
      final dirtyByClientId = {
        for (final row in dirtyRows)
          row.read<String>('client_id'): row.read<bool>('dirty'),
      };

      expect(dirtyByClientId[acceptedClientId], isFalse);
      expect(dirtyByClientId[conflictedClientId], isTrue);
    },
  );

  test('sync payload omits frontend-only hidden state', () async {
    final assetId = await createAsset('주식');
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '테스트',
      symbol: 'TST',
      quantity: 1,
      averagePrice: 1000,
      currentPrice: 1000,
      note: '',
    );
    final cashAssetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: cashAssetId,
      currencyCode: 'KRW',
      name: '생활비',
      note: '',
      balance: 1000,
    );

    var payload = await db.buildDirtySyncPayload();
    final assetPayload = (payload['assets'] as List).whereType<Map>();
    final holdingPayload = (payload['holdings'] as List).whereType<Map>();
    final cashAccountPayload = (payload['cash_accounts'] as List)
        .whereType<Map>();

    expect(assetPayload, everyElement(isNot(containsPair('hidden', anything))));
    expect(
      holdingPayload,
      everyElement(isNot(containsPair('hidden', anything))),
    );
    expect(
      cashAccountPayload,
      everyElement(isNot(containsPair('hidden', anything))),
    );

    final assetClientId = (await (db.select(
      db.assets,
    )..where((row) => row.id.equals(assetId))).getSingle()).clientId!;
    final holdingClientId = (await (db.select(
      db.holdings,
    )..where((row) => row.id.equals(holdingId))).getSingle()).clientId!;
    final cashClientId =
        (await (db.select(
              db.cashAccounts,
            )..where((row) => row.id.equals(cashHoldingId.abs()))).getSingle())
            .clientId!;

    await db.markDirtySyncPayloadAsSynced(payload, null);
    await db.updateAssetHidden(assetId, true);
    await db.updateHoldingHidden(holdingId, true);
    await db.updateHoldingHidden(cashHoldingId, true);

    final cleanPayload = await db.buildDirtySyncPayload();
    expect(cleanPayload['assets'], isEmpty);
    expect(cleanPayload['holdings'], isEmpty);
    expect(cleanPayload['cash_accounts'], isEmpty);

    await db.replaceLocalSyncData(Map<String, dynamic>.from(payload));

    final hiddenAsset = await db.fetchAssetByClientId(assetClientId);
    expect(hiddenAsset?.isHidden, isTrue);
    final hiddenHolding = await db.fetchHoldingByClientId(holdingClientId);
    expect(hiddenHolding?.isHidden, isTrue);
    final hiddenCashHolding = await db.fetchHoldingByClientId(cashClientId);
    expect(hiddenCashHolding?.isHidden, isTrue);
  });

  test(
    'ledger investment edit survives sync restore remapped local ids',
    () async {
      final assetId = await createAsset('주식');
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '테스트',
        symbol: 'TST',
        quantity: 1,
        averagePrice: 1000,
        currentPrice: 1000,
        note: '',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '배당',
        name: '배당',
        amount: '100',
        quantity: '',
      );

      final staleTransaction = (await findHolding(
        holdingId,
      )).transactions.singleWhere((item) => item.type == '배당');
      expect(staleTransaction.clientId, isNotNull);
      final payload = await db.buildDirtySyncPayload();
      await db.close();

      final restoredDb = AppDatabase.forTesting(NativeDatabase.memory());
      db = restoredDb;
      final dummyAssetId = await restoredDb.createAsset(
        assetType: '주식',
        title: '더미',
        alias: '더미',
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
      final dummyHoldingId = await restoredDb.createHolding(
        assetId: dummyAssetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '더미',
        symbol: 'DMY',
        quantity: 1,
        averagePrice: 1,
        currentPrice: 1,
        note: '',
      );
      await restoredDb.createTransaction(
        assetId: dummyAssetId,
        holdingId: dummyHoldingId,
        date: '2026.05.20',
        type: '배당',
        name: '더미',
        amount: '1',
        quantity: '',
      );
      await restoredDb.replaceLocalSyncData(Map<String, dynamic>.from(payload));

      await restoredDb.updateTransactionItem(
        TransactionItem(
          id: staleTransaction.id,
          clientId: staleTransaction.clientId,
          assetId: staleTransaction.assetId,
          holdingId: staleTransaction.holdingId,
          date: staleTransaction.date,
          type: staleTransaction.type,
          name: '배당 수정',
          amount: '200',
          quantity: staleTransaction.quantity,
          ledgerEventId: staleTransaction.ledgerEventId,
          ledgerLineId: staleTransaction.ledgerLineId,
          ledgerKind: staleTransaction.ledgerKind,
          ledgerAction: staleTransaction.ledgerAction,
          legacySourceTable: staleTransaction.legacySourceTable,
          legacySourceId: staleTransaction.legacySourceId,
        ),
      );

      final restoredHolding = (await restoredDb.fetchAssets())
          .singleWhere((asset) => asset.assetType == '주식')
          .holdings
          .singleWhere((holding) => holding.name == '테스트');
      final updatedTransaction = restoredHolding.transactions.singleWhere(
        (item) => item.type == '배당',
      );
      expect(updatedTransaction.name, '배당 수정');
      expect(updatedTransaction.amount, '200');
    },
  );

  test('ledger cash edit survives sync restore remapped local ids', () async {
    final assetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '생활비',
      note: '',
      balance: 1000,
    );
    await db.createTransaction(
      assetId: assetId,
      holdingId: cashHoldingId,
      date: '2026.05.21',
      type: '입금',
      name: '입금',
      amount: '100',
      quantity: '',
    );

    final staleTransaction = (await findHolding(
      cashHoldingId,
    )).transactions.singleWhere((item) => item.type == '입금');
    expect(staleTransaction.clientId, isNotNull);
    final payload = await db.buildDirtySyncPayload();
    await db.close();

    final restoredDb = AppDatabase.forTesting(NativeDatabase.memory());
    db = restoredDb;
    final dummyAssetId = await restoredDb.createAsset(
      assetType: '현금',
      title: '더미 현금',
      alias: '더미 현금',
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
    final dummyCashHoldingId = await restoredDb.createCashAccount(
      assetId: dummyAssetId,
      currencyCode: 'KRW',
      name: '더미',
      note: '',
      balance: 0,
    );
    await restoredDb.createTransaction(
      assetId: dummyAssetId,
      holdingId: dummyCashHoldingId,
      date: '2026.05.20',
      type: '입금',
      name: '더미',
      amount: '1',
      quantity: '',
    );
    await restoredDb.replaceLocalSyncData(Map<String, dynamic>.from(payload));

    await restoredDb.updateTransactionItem(
      TransactionItem(
        id: staleTransaction.id,
        clientId: staleTransaction.clientId,
        assetId: staleTransaction.assetId,
        holdingId: staleTransaction.holdingId,
        date: staleTransaction.date,
        type: staleTransaction.type,
        name: '입금 수정',
        amount: '200',
        quantity: staleTransaction.quantity,
        ledgerEventId: staleTransaction.ledgerEventId,
        ledgerLineId: staleTransaction.ledgerLineId,
        ledgerKind: staleTransaction.ledgerKind,
        ledgerAction: staleTransaction.ledgerAction,
        legacySourceTable: staleTransaction.legacySourceTable,
        legacySourceId: staleTransaction.legacySourceId,
      ),
    );

    final restoredHolding = (await restoredDb.fetchAssets())
        .singleWhere((asset) => asset.assetType == '현금')
        .holdings
        .singleWhere((holding) => holding.name == '생활비');
    final updatedTransaction = restoredHolding.transactions.singleWhere(
      (item) => item.type == '입금',
    );
    expect(updatedTransaction.name, '입금 수정');
    expect(updatedTransaction.amount, '200');
    expect(restoredHolding.quantity, 1200);
  });

  test(
    'create writes active ledger events without replacement churn',
    () async {
      final assetId = await createAsset('주식');
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
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '매도',
        amount: '120',
        quantity: '2',
      );

      final counts = await db.customSelect('''
          SELECT
            SUM(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END) AS active_count,
            SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count,
            SUM(CASE WHEN source = 'ledger' THEN 1 ELSE 0 END) AS ledger_source_count
          FROM transaction_events
          WHERE kind = 'trade'
          ''').getSingle();

      expect(counts.read<int>('active_count'), 2);
      expect(counts.read<int>('deleted_count'), 0);
      expect(counts.read<int>('ledger_source_count'), 2);
      final legacyCounts = await db.customSelect('''
          SELECT
            (SELECT COUNT(*) FROM transactions WHERE deleted_at IS NULL) AS transactions_count,
            (SELECT COUNT(*) FROM cash_transactions WHERE deleted_at IS NULL) AS cash_transactions_count
          ''').getSingle();
      expect(legacyCounts.read<int>('transactions_count'), 0);
      expect(legacyCounts.read<int>('cash_transactions_count'), 0);
      final payload = await db.buildDirtySyncPayload();
      expect(payload['payload_version'], 4);
      expect(payload['schema_mode'], 'ledger_only_delta');
      expect(payload.containsKey('transactions'), isFalse);
      expect(payload.containsKey('cash_transactions'), isFalse);
      expect(payload['transaction_events'], isNotEmpty);
      expect(payload['transaction_lines'], isNotEmpty);
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);
    },
  );

  test('ledger state parity reports mismatched legacy state', () async {
    final assetId = await createAsset('주식');
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
      date: '2026.05.21',
      type: '매수',
      name: '매수',
      amount: '100',
      quantity: '5',
    );
    await db.customStatement('UPDATE holdings SET quantity = ? WHERE id = ?', [
      7.0,
      holdingId,
    ]);

    final issues = await db.fetchLedgerStateParityIssues();
    expect(issues, hasLength(1));
    expect(issues.single.kind, 'holding_quantity');
    expect(issues.single.id, holdingId);
    expect(issues.single.expectedValue, 7);
    expect(issues.single.ledgerValue, 5);
  });

  test(
    'cash ledger summary separates external and internal cash movement',
    () async {
      final assetId = await createAsset('현금');
      final sourceHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '원화 계좌',
        note: '',
        balance: 1000,
      );
      final targetHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '저축 계좌',
        note: '',
        balance: 0,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: sourceHoldingId,
        date: '2026.05.21',
        type: '입금',
        name: '추가입금',
        amount: '200',
        quantity: '',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: sourceHoldingId,
        date: '2026.05.22',
        type: '출금',
        name: '생활비 출금',
        amount: '50',
        quantity: '',
      );
      await db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: sourceHoldingId,
        targetHoldingId: targetHoldingId,
        date: '2026.05.23',
        name: '계좌 이동',
        amount: '25',
      );

      final performance = await db.fetchLedgerPortfolioPerformance();
      expect(performance.externalCashFlowAmount, 150);
      expect(performance.externalDepositAmount, 200);
      expect(performance.externalWithdrawalAmount, 50);
      expect(performance.internalCashMovementAmount, 50);
      expect(performance.tradeSettlementCashFlowAmount, 0);
      expect(performance.pureRealizedPerformance, 0);
    },
  );

  test(
    'ledger portfolio summary groups calculation amounts by currency',
    () async {
      final krwAssetId = await createAsset('주식');
      final krwHoldingId = await db.createHolding(
        assetId: krwAssetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '원화 주식',
        symbol: 'KRW',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 100,
        note: '',
      );
      await db.createCashAccount(
        assetId: krwAssetId,
        currencyCode: 'KRW',
        name: '원화 현금',
        note: '',
        balance: 1000,
      );

      final usdAssetId = await createAsset('주식');
      final usdHoldingId = await db.createHolding(
        assetId: usdAssetId,
        currencyCode: 'USD',
        exchangeCode: '',
        name: '달러 주식',
        symbol: 'USD',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 10,
        note: '',
      );
      await db.createCashAccount(
        assetId: usdAssetId,
        currencyCode: 'USD',
        name: '달러 현금',
        note: '',
        balance: 100,
      );

      await db.createTransaction(
        assetId: krwAssetId,
        holdingId: krwHoldingId,
        date: '2026.05.21',
        type: '매수',
        name: '원화 매수',
        amount: '100',
        quantity: '2',
      );
      await db.createTransaction(
        assetId: usdAssetId,
        holdingId: usdHoldingId,
        date: '2026.05.21',
        type: '매수',
        name: '달러 매수',
        amount: '10',
        quantity: '2',
      );

      final summaries = await db.fetchLedgerPortfolioPerformanceByCurrency();
      expect(summaries.keys, containsAll(['KRW', 'USD']));
      expect(summaries['KRW']?.buyAmount, 200);
      expect(summaries['KRW']?.tradeSettlementCashFlowAmount, -200);
      expect(summaries['USD']?.buyAmount, 20);
      expect(summaries['USD']?.tradeSettlementCashFlowAmount, -20);
    },
  );

  test(
    'mixed ledger cash fx and trades keep core numeric totals stable',
    () async {
      final assetId = await createAsset('주식');
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '복합 주식',
        symbol: 'MIX',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 140,
        note: '',
      );
      final settlementCashId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 3000,
      );
      final savingsCashId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '저축 현금',
        note: '',
        balance: 100,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '복합 매수',
        amount: '100',
        quantity: '5',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '복합 매도',
        amount: '130',
        quantity: '2',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: settlementCashId,
        date: '2026.05.23',
        type: '입금',
        name: '외부 입금',
        amount: '200',
        quantity: '',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: settlementCashId,
        date: '2026.05.24',
        type: '출금',
        name: '외부 출금',
        amount: '50',
        quantity: '',
      );
      await db.createCashTransfer(
        assetId: assetId,
        sourceHoldingId: settlementCashId,
        targetHoldingId: savingsCashId,
        date: '2026.05.25',
        name: '내부 이체',
        amount: '25',
      );
      await db.createCashExchange(
        assetId: assetId,
        sourceHoldingId: settlementCashId,
        date: '2026.05.26',
        name: '달러 환전',
        amount: '1300',
        exchangeRate: 1300,
      );

      final usdCash = (await db.fetchAssetById(
        assetId,
      ))!.holdings.singleWhere((holding) => holding.currencyCode == 'USD');
      final holdingPerformance = await db
          .fetchLedgerHoldingPerformanceByHoldingId();
      final portfolioPerformance = await db.fetchLedgerPortfolioPerformance();
      final byCurrency = await db.fetchLedgerPortfolioPerformanceByCurrency();
      final activeLineSummary = await db.customSelect('''
        SELECT
          SUM(CASE WHEN action = 'buy' THEN quantity_delta ELSE 0 END) AS bought_quantity,
          SUM(CASE WHEN action = 'sell' THEN quantity_delta ELSE 0 END) AS sold_quantity,
          SUM(CASE WHEN action = 'settlement' THEN cash_delta ELSE 0 END) AS settlement_cash,
          SUM(CASE WHEN action IN ('deposit', 'withdrawal') THEN cash_delta ELSE 0 END) AS external_cash,
          SUM(CASE WHEN action IN ('transfer_out', 'transfer_in', 'fx_out', 'fx_in') THEN ABS(cash_delta) ELSE 0 END) AS internal_activity
        FROM transaction_lines
        WHERE deleted_at IS NULL
      ''').getSingle();

      expect((await findHolding(holdingId)).quantity, 3);
      expect((await findHolding(holdingId)).averagePrice, 100);
      expect((await findHolding(settlementCashId)).quantity, 1585);
      expect((await findHolding(savingsCashId)).quantity, 125);
      expect(usdCash.quantity, 1);
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);

      expect(holdingPerformance[holdingId]?.quantity, 3);
      expect(holdingPerformance[holdingId]?.remainingCost, 300);
      expect(holdingPerformance[holdingId]?.realizedPnl, 60);
      expect(holdingPerformance[holdingId]?.buyAmount, 500);
      expect(holdingPerformance[holdingId]?.sellAmount, 260);

      expect(portfolioPerformance.realizedPnl, 60);
      expect(portfolioPerformance.pureRealizedPerformance, 60);
      expect(portfolioPerformance.externalCashFlowAmount, 150);
      expect(portfolioPerformance.externalDepositAmount, 200);
      expect(portfolioPerformance.externalWithdrawalAmount, 50);
      expect(portfolioPerformance.tradeSettlementCashFlowAmount, -240);
      expect(portfolioPerformance.internalCashMovementAmount, 1351);
      expect(portfolioPerformance.buyAmount, 500);
      expect(portfolioPerformance.sellAmount, 260);

      expect(byCurrency['KRW']?.realizedPnl, 60);
      expect(byCurrency['KRW']?.externalCashFlowAmount, 150);
      expect(byCurrency['KRW']?.tradeSettlementCashFlowAmount, -240);
      expect(byCurrency['KRW']?.internalCashMovementAmount, 1350);
      expect(byCurrency['USD']?.internalCashMovementAmount, 1);

      expect(activeLineSummary.read<double>('bought_quantity'), 5);
      expect(activeLineSummary.read<double>('sold_quantity'), -2);
      expect(activeLineSummary.read<double>('settlement_cash'), -240);
      expect(activeLineSummary.read<double>('external_cash'), 150);
      expect(activeLineSummary.read<double>('internal_activity'), 1351);
    },
  );

  test(
    'ledger performance subtracts fees and taxes from pure profit',
    () async {
      await db.customStatement('''
      INSERT INTO transaction_events (occurred_at, kind, title, source)
      VALUES ('2026-05-21', 'fee', '성과 비용', 'test')
    ''');
      final eventId =
          (await db
                  .customSelect(
                    "SELECT id FROM transaction_events WHERE title = '성과 비용'",
                  )
                  .getSingle())
              .read<int>('id');
      await db.customStatement(
        '''
      INSERT INTO transaction_lines
        (event_id, action, currency_code, cash_delta, gross_amount)
      VALUES
        (?, 'fee', 'KRW', -10, 10),
        (?, 'tax', 'KRW', -5, 5),
        (?, 'dividend', 'KRW', 20, 20)
    ''',
        [eventId, eventId, eventId],
      );

      final performance = await db.fetchLedgerPortfolioPerformance();

      expect(performance.incomeAmount, 20);
      expect(performance.feeAmount, 10);
      expect(performance.taxAmount, 5);
      expect(performance.pureRealizedPerformance, 5);
    },
  );

  test('ledger monthly performance groups pure realized profit', () async {
    await db.customStatement('''
      INSERT INTO transaction_events (occurred_at, kind, title, source)
      VALUES
        ('2026-05-21', 'income', '5월 성과', 'test'),
        ('2026-06-03', 'income', '6월 성과', 'test')
    ''');
    final rows = await db
        .customSelect('SELECT id, title FROM transaction_events')
        .get();
    final eventIdByTitle = {
      for (final row in rows) row.read<String>('title'): row.read<int>('id'),
    };

    await db.customStatement(
      '''
      INSERT INTO transaction_lines
        (event_id, action, currency_code, realized_pnl, cash_delta, gross_amount)
      VALUES
        (?, 'sell', 'KRW', 40, 0, 100),
        (?, 'dividend', 'KRW', 0, 20, 20),
        (?, 'fee', 'KRW', 0, -5, 5),
        (?, 'tax', 'KRW', 0, -2, 2),
        (?, 'sell', 'KRW', -10, 0, 50)
    ''',
      [
        eventIdByTitle['5월 성과'],
        eventIdByTitle['5월 성과'],
        eventIdByTitle['5월 성과'],
        eventIdByTitle['6월 성과'],
        eventIdByTitle['6월 성과'],
      ],
    );

    final monthly = await db.fetchLedgerMonthlyPerformanceByCurrency();
    final may = monthly.singleWhere((row) => row.month == '2026-05');
    final june = monthly.singleWhere((row) => row.month == '2026-06');

    expect(may.realizedPnl, 40);
    expect(may.incomeAmount, 20);
    expect(may.feeAmount, 5);
    expect(may.pureRealizedPerformance, 55);
    expect(june.realizedPnl, -10);
    expect(june.taxAmount, 2);
    expect(june.pureRealizedPerformance, -12);
  });

  test(
    'ledger performance filters by event date range across date formats',
    () async {
      await db.customStatement('''
        INSERT INTO transaction_events (occurred_at, kind, title, source)
        VALUES
          ('2026.04.30', 'income', '기간 이전', 'test'),
          ('2026-05-01', 'income', '기간 시작', 'test'),
          ('2026.05.15', 'income', '기간 중간', 'test'),
          ('2026-06-01', 'income', '기간 이후', 'test')
      ''');
      final rows = await db
          .customSelect('SELECT id, title FROM transaction_events')
          .get();
      final eventIdByTitle = {
        for (final row in rows) row.read<String>('title'): row.read<int>('id'),
      };

      await db.customStatement(
        '''
        INSERT INTO transaction_lines
          (event_id, action, holding_id, currency_code, realized_pnl, cash_delta, gross_amount)
        VALUES
          (?, 'sell', 10, 'KRW', 100, 0, 100),
          (?, 'sell', 10, 'KRW', 10, 0, 10),
          (?, 'dividend', 10, 'KRW', 0, 5, 5),
          (?, 'sell', 10, 'KRW', 999, 0, 999)
      ''',
        [
          eventIdByTitle['기간 이전'],
          eventIdByTitle['기간 시작'],
          eventIdByTitle['기간 중간'],
          eventIdByTitle['기간 이후'],
        ],
      );

      final from = DateTime(2026, 5);
      final to = DateTime(2026, 5, 31);
      final portfolio = await db.fetchLedgerPortfolioPerformance(
        from: from,
        to: to,
      );
      final byCurrency = await db.fetchLedgerPortfolioPerformanceByCurrency(
        from: from,
        to: to,
      );
      final byHolding = await db.fetchLedgerHoldingPerformanceByHoldingId(
        from: from,
        to: to,
      );
      final monthly = await db.fetchLedgerMonthlyPerformanceByCurrency(
        from: from,
        to: to,
      );

      expect(portfolio.realizedPnl, 10);
      expect(portfolio.incomeAmount, 5);
      expect(portfolio.pureRealizedPerformance, 15);
      expect(byCurrency['KRW']?.pureRealizedPerformance, 15);
      expect(byHolding[10]?.realizedPnl, 10);
      expect(byHolding[10]?.incomeAmount, 5);
      expect(monthly, hasLength(1));
      expect(monthly.single.month, '2026-05');
      expect(monthly.single.pureRealizedPerformance, 15);
    },
  );

  test('ledger performance events support drill-down filters', () async {
    await db.customStatement('''
      INSERT INTO transaction_events (occurred_at, kind, title, source)
      VALUES
        ('2026-05-10', 'trade', '5월 매도', 'test'),
        ('2026-06-10', 'income', '6월 배당', 'test')
    ''');
    final rows = await db
        .customSelect('SELECT id, title FROM transaction_events')
        .get();
    final eventIdByTitle = {
      for (final row in rows) row.read<String>('title'): row.read<int>('id'),
    };

    await db.customStatement(
      '''
      INSERT INTO transaction_lines
        (event_id, action, holding_id, currency_code, realized_pnl, cash_delta, gross_amount)
      VALUES
        (?, 'sell', 11, 'KRW', 40, 0, 100),
        (?, 'dividend', 11, 'KRW', 0, 20, 20)
    ''',
      [eventIdByTitle['5월 매도'], eventIdByTitle['6월 배당']],
    );

    final rowsForMay = await db.fetchLedgerPerformanceEvents(
      from: DateTime(2026, 5),
      to: DateTime(2026, 5, 31),
      action: 'sell',
      holdingId: 11,
    );

    expect(rowsForMay, hasLength(1));
    expect(rowsForMay.single.title, '5월 매도');
    expect(rowsForMay.single.action, 'sell');
    expect(rowsForMay.single.amount, 40);
  });

  test(
    'ledger performance ignores deleted events and reads gross-only amounts',
    () async {
      await db.customStatement('''
        INSERT INTO transaction_events (occurred_at, kind, title, source, deleted_at)
        VALUES
          ('2026-05-21', 'income', '활성 성과', 'test', NULL),
          ('2026-05-21', 'income', '삭제 성과', 'test', '2026-05-22T00:00:00'),
          ('2026-06-01', 'trade', '매수만 있는 달', 'test', NULL)
      ''');
      final rows = await db
          .customSelect('SELECT id, title FROM transaction_events')
          .get();
      final eventIdByTitle = {
        for (final row in rows) row.read<String>('title'): row.read<int>('id'),
      };

      await db.customStatement(
        '''
        INSERT INTO transaction_lines
          (event_id, action, currency_code, realized_pnl, cash_delta, gross_amount)
        VALUES
          (?, 'sell', 'KRW', 40, 0, 100),
          (?, 'dividend', 'KRW', 0, 0, 20),
          (?, 'interest', 'KRW', 0, 0, 7),
          (?, 'fee', 'KRW', 0, 0, 10),
          (?, 'tax', 'KRW', 0, 0, 5),
          (?, 'sell', 'KRW', 999, 0, 999),
          (?, 'dividend', 'KRW', 0, 0, 999),
          (?, 'buy', 'KRW', 0, -100, 100)
      ''',
        [
          eventIdByTitle['활성 성과'],
          eventIdByTitle['활성 성과'],
          eventIdByTitle['활성 성과'],
          eventIdByTitle['활성 성과'],
          eventIdByTitle['활성 성과'],
          eventIdByTitle['삭제 성과'],
          eventIdByTitle['삭제 성과'],
          eventIdByTitle['매수만 있는 달'],
        ],
      );

      final performance = await db.fetchLedgerPortfolioPerformance();
      expect(performance.realizedPnl, 40);
      expect(performance.incomeAmount, 27);
      expect(performance.feeAmount, 10);
      expect(performance.taxAmount, 5);
      expect(performance.pureRealizedPerformance, 52);
      expect(performance.buyAmount, 100);

      final byCurrency = await db.fetchLedgerPortfolioPerformanceByCurrency();
      expect(byCurrency['KRW']?.pureRealizedPerformance, 52);

      final incomeRows = await db.fetchLedgerIncomeTransactions();
      expect(incomeRows.fold<double>(0, (sum, row) => sum + row.amount), 27);

      final monthly = await db.fetchLedgerMonthlyPerformanceByCurrency();
      final may = monthly.singleWhere((row) => row.month == '2026-05');
      expect(may.pureRealizedPerformance, 52);
      expect(monthly.where((row) => row.month == '2026-06'), isEmpty);
    },
  );

  test(
    'buy blocks insufficient cash and edit respects restored old cash effect',
    () async {
      final assetId = await createAsset('주식');
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
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );

      expect(
        () => db.createTransaction(
          assetId: assetId,
          holdingId: holdingId,
          date: '2026.05.21',
          type: '매수',
          name: '초과 매수',
          amount: '1001',
          quantity: '1',
        ),
        throwsA(isA<StateError>()),
      );

      final transactionId = await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );

      await db.updateTransactionItem(
        TransactionItem(
          id: transactionId,
          assetId: assetId,
          holdingId: holdingId,
          date: '2026.05.22',
          type: '매수',
          name: '매수 수정',
          amount: '150',
          quantity: '5',
        ),
      );
      expect((await findHolding(holdingId)).quantity, 5);
      expect((await findHolding(cashHoldingId)).quantity, 250);

      expect(
        () => db.updateTransactionItem(
          TransactionItem(
            id: transactionId,
            assetId: assetId,
            holdingId: holdingId,
            date: '2026.05.23',
            type: '매수',
            name: '초과 매수 수정',
            amount: '1001',
            quantity: '1',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect((await findHolding(holdingId)).quantity, 5);
      expect((await findHolding(cashHoldingId)).quantity, 250);
    },
  );

  test(
    'deleting buy and sell restores linked cash and holding state',
    () async {
      final assetId = await createAsset('주식');
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
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 1000,
      );

      final buyId = await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '매수',
        name: '매수',
        amount: '100',
        quantity: '5',
      );
      final sellId = await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '매도',
        name: '매도',
        amount: '120',
        quantity: '2',
      );

      await db.deleteTransactionItem(sellId);
      expect((await findHolding(holdingId)).quantity, 5);
      expect((await findHolding(cashHoldingId)).quantity, 500);
      final afterSellDelete = await db.customSelect('''
            SELECT
              SUM(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END) AS active_count,
              SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count
            FROM transaction_events
            WHERE kind = 'trade'
            ''').getSingle();
      expect(afterSellDelete.read<int>('active_count'), 1);
      expect(afterSellDelete.read<int>('deleted_count'), 1);

      await db.deleteTransactionItem(buyId);
      expect((await findHolding(holdingId)).quantity, 0);
      expect((await findHolding(cashHoldingId)).quantity, 1000);
      final afterBuyDelete = await db.customSelect('''
            SELECT
              SUM(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END) AS active_count,
              SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_count
            FROM transaction_events
            WHERE kind = 'trade'
            ''').getSingle();
      expect(afterBuyDelete.read<int?>('active_count') ?? 0, 0);
      expect(afterBuyDelete.read<int>('deleted_count'), 2);
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);
    },
  );

  test(
    'dividend and interest do not change holding quantity or cash balance',
    () async {
      final assetId = await createAsset('주식');
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '배당 주식',
        symbol: 'DIV',
        quantity: 10,
        averagePrice: 100,
        currentPrice: 120,
        note: '',
      );
      final cashHoldingId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 현금',
        note: '',
        balance: 500,
      );

      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.21',
        type: '배당',
        name: '분기 배당',
        amount: '30',
        quantity: '',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.22',
        type: '이자',
        name: '예탁 이자',
        amount: '5',
        quantity: '',
      );

      expect((await findHolding(holdingId)).quantity, 10);
      expect((await findHolding(holdingId)).averagePrice, 100);
      expect((await findHolding(cashHoldingId)).quantity, 500);

      expect(
        () => db.createTransaction(
          assetId: assetId,
          holdingId: holdingId,
          date: '2026.05.23',
          type: '배당',
          name: '잘못된 배당',
          amount: '0',
          quantity: '',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('income analysis reads dividend and interest from ledger lines', () async {
    final assetId = await createAsset('주식');
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '배당 주식',
      symbol: 'DIV',
      quantity: 10,
      averagePrice: 100,
      currentPrice: 100,
      note: '',
    );
    await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '현금',
      note: '',
      balance: 500,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.21',
      type: '배당',
      name: '분기 배당',
      amount: '30',
      quantity: '',
    );
    await db.createTransaction(
      assetId: assetId,
      holdingId: holdingId,
      date: '2026.05.22',
      type: '이자',
      name: '예탁금 이자',
      amount: '5',
      quantity: '',
    );
    await db.customStatement(
      "UPDATE transactions SET type = '매수', amount = '999' WHERE type IN ('배당', '이자')",
    );

    final rows = await db.fetchLedgerIncomeTransactions();
    expect(
      rows.map((row) => row.action),
      containsAll(['dividend', 'interest']),
    );
    expect(rows.fold<double>(0, (sum, row) => sum + row.amount), 35);
    expect(rows.map((row) => row.holdingName).toSet(), {'배당 주식'});
  });

  test('transaction dates are read from ledger events', () async {
    final assetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '현금',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: cashHoldingId,
      date: '2026.05.21',
      type: '입금',
      name: '입금',
      amount: '100',
      quantity: '',
    );
    await db.customStatement(
      "UPDATE cash_transactions SET date = '1999.01.01'",
    );

    expect(await db.fetchTransactionDates(), {'2026-05-21'});
  });

  test('snapshot transaction lists are read from ledger events', () async {
    final assetId = await createAsset('주식');
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
      date: '2026.05.21',
      type: '매수',
      name: '스냅샷 매수',
      amount: '100',
      quantity: '5',
    );
    await db.customStatement("UPDATE transactions SET date = '1999.01.01'");
    await db.customStatement(
      "UPDATE cash_transactions SET date = '1999.01.01'",
    );

    final assetTransactions = await db.fetchTransactionsForDate('2026-05-21');
    final cashTransactions = await db.fetchCashTransactionsForDate(
      '2026-05-21',
    );

    expect(assetTransactions, hasLength(1));
    expect(assetTransactions.single.type, '매수');
    expect(assetTransactions.single.name, '스냅샷 매수');
    expect(assetTransactions.single.amount, '100');
    expect(assetTransactions.single.quantity, '5');
    expect(cashTransactions, hasLength(1));
    expect(cashTransactions.single.type, '매수');
    expect(cashTransactions.single.amount, '-500');
  });

  test('display snapshots remap remote snapshot client references', () async {
    final assetId = await createAsset('주식');
    final asset = await db.fetchAssetById(assetId);
    final holdingId = await db.createHolding(
      assetId: assetId,
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '테스트 주식',
      symbol: 'TEST',
      quantity: 5,
      averagePrice: 100,
      currentPrice: 120,
      note: '',
    );
    final holding = await db.fetchHoldingById(holdingId);
    expect(asset?.clientId, isNotNull);
    expect(holding?.clientId, isNotNull);

    await db.importRemotePortfolioSnapshots([
      {
        'snapshot_date': '2026-05-21',
        'total_purchase_amount': 500,
        'total_valuation_amount': 600,
        'profit_amount': 100,
        'profit_rate': 20,
        'items': [
          {
            'asset_id': 999,
            'asset_client_id': asset!.clientId,
            'asset_title': '주식',
            'total_purchase_amount': 500,
            'total_valuation_amount': 600,
            'profit_amount': 100,
            'profit_rate': 20,
            'holding_count': 1,
          },
        ],
        'holding_items': [
          {
            'asset_id': 999,
            'asset_client_id': asset.clientId,
            'asset_title': '주식',
            'holding_id': 999,
            'holding_client_id': holding!.clientId,
            'holding_name': '테스트 주식',
            'holding_symbol': '',
            'currency_code': 'KRW',
            'quantity': 5,
            'total_purchase_amount': 500,
            'total_valuation_amount': 600,
            'profit_amount': 100,
            'profit_rate': 20,
          },
        ],
      },
    ]);

    final holdings = await db.fetchDisplayPortfolioSnapshotHoldingItemsByDates([
      '2026-05-21',
    ]);
    final items = await db.fetchDisplayPortfolioSnapshotItemsByDates([
      '2026-05-21',
    ]);
    final rawHoldings = await db.fetchPortfolioSnapshotHoldingItemsByDates([
      '2026-05-21',
    ]);

    expect(holdings, hasLength(1));
    expect(holdings.single.holdingName, '테스트 주식');
    expect(rawHoldings.single.assetId, assetId);
    expect(rawHoldings.single.holdingId, holdingId);
    expect(items, hasLength(1));
    expect(items.single.assetId, assetId);
    expect(items.single.assetTitle, '주식');
    expect(items.single.holdingCount, 1);
    expect(items.single.totalValuationAmount, 600);
  });

  test(
    'imported snapshots preserve cash account balances and exchange rate',
    () async {
      final assetId = await createAsset('현금');
      final asset = await db.fetchAssetById(assetId);
      final krwCashId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '원화 현금',
        note: '생활비',
        balance: 1585,
      );
      final usdCashId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'USD',
        name: '달러 현금',
        note: '환전',
        balance: 1,
      );
      final cashRows =
          await (db.select(db.cashAccounts)..where(
                (table) => table.id.isIn([krwCashId.abs(), usdCashId.abs()]),
              ))
              .get();
      final cashClientIdById = {
        for (final row in cashRows) row.id: row.clientId,
      };

      await db.importRemotePortfolioSnapshots([
        {
          'snapshot_date': '2026-05-26T23:59:59Z',
          'total_purchase_amount': 300,
          'total_valuation_amount': 2885,
          'profit_amount': 2585,
          'profit_rate': 861.6667,
          'exchange_rate': 1300,
          'items': [
            {
              'asset_id': 999,
              'asset_client_id': asset!.clientId,
              'asset_title': '현금',
              'total_purchase_amount': 300,
              'total_valuation_amount': 2885,
              'profit_amount': 2585,
              'profit_rate': 861.6667,
              'holding_count': 2,
            },
          ],
          'holding_items': const [],
          'cash_accounts': [
            {
              'asset_id': 999,
              'asset_client_id': asset.clientId,
              'asset_title': '현금',
              'cash_account_id': 9991,
              'cash_account_client_id': cashClientIdById[krwCashId.abs()],
              'cash_account_name': '원화 현금',
              'currency_code': 'KRW',
              'balance': 1585,
              'note': '생활비',
            },
            {
              'asset_id': 999,
              'asset_client_id': asset.clientId,
              'asset_title': '현금',
              'cash_account_id': 9992,
              'cash_account_client_id': cashClientIdById[usdCashId.abs()],
              'cash_account_name': '달러 현금',
              'currency_code': 'USD',
              'balance': 1,
              'note': '환전',
            },
          ],
        },
      ]);

      final snapshot = await db.fetchPortfolioSnapshotByDate('2026-05-26');
      final items = await db.fetchPortfolioSnapshotItemsByDates(['2026-05-26']);
      final cashAccounts = await db.fetchPortfolioSnapshotCashAccountsByDates([
        '2026-05-26',
      ]);
      final krwSnapshotCash = cashAccounts.singleWhere(
        (row) => row.cashAccountName == '원화 현금',
      );
      final usdSnapshotCash = cashAccounts.singleWhere(
        (row) => row.cashAccountName == '달러 현금',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.exchangeRate, 1300);
      expect(snapshot.totalValuationAmount, 2885);
      expect(items, hasLength(1));
      expect(items.single.assetId, assetId);
      expect(items.single.totalValuationAmount, 2885);
      expect(items.single.holdingCount, 2);
      expect(cashAccounts, hasLength(2));
      expect(krwSnapshotCash.assetId, assetId);
      expect(krwSnapshotCash.cashAccountId, krwCashId.abs());
      expect(krwSnapshotCash.currencyCode, 'KRW');
      expect(krwSnapshotCash.balance, 1585);
      expect(usdSnapshotCash.assetId, assetId);
      expect(usdSnapshotCash.cashAccountId, usdCashId.abs());
      expect(usdSnapshotCash.currencyCode, 'USD');
      expect(usdSnapshotCash.balance, 1);
    },
  );

  test(
    'display snapshots keep asset summary rows with partial holding details',
    () async {
      final isaAssetId = await createAsset('ISA');
      final stockAssetId = await createAsset('주식');
      final coinAssetId = await createAsset('코인');
      final cashAssetId = await createAsset('현금');
      final isaHoldingId = await db.createHolding(
        assetId: isaAssetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: 'ISA 종목',
        symbol: 'ISA',
        quantity: 1,
        averagePrice: 100,
        currentPrice: 120,
        note: '',
      );

      await db.importRemotePortfolioSnapshots([
        {
          'snapshot_date': '2026-05-20',
          'total_purchase_amount': 1000,
          'total_valuation_amount': 1200,
          'profit_amount': 200,
          'profit_rate': 20,
          'items': [
            {
              'asset_id': isaAssetId,
              'asset_title': 'ISA',
              'total_purchase_amount': 100,
              'total_valuation_amount': 120,
              'profit_amount': 20,
              'profit_rate': 20,
              'holding_count': 1,
            },
            {
              'asset_id': stockAssetId,
              'asset_title': '주식',
              'total_purchase_amount': 300,
              'total_valuation_amount': 360,
              'profit_amount': 60,
              'profit_rate': 20,
              'holding_count': 2,
            },
            {
              'asset_id': coinAssetId,
              'asset_title': '코인',
              'total_purchase_amount': 400,
              'total_valuation_amount': 480,
              'profit_amount': 80,
              'profit_rate': 20,
              'holding_count': 3,
            },
            {
              'asset_id': cashAssetId,
              'asset_title': '현금',
              'total_purchase_amount': 200,
              'total_valuation_amount': 240,
              'profit_amount': 40,
              'profit_rate': 20,
              'holding_count': 2,
            },
          ],
          'holding_items': [
            {
              'asset_id': isaAssetId,
              'asset_title': 'ISA',
              'holding_id': isaHoldingId,
              'holding_name': 'ISA 종목',
              'holding_symbol': 'ISA',
              'currency_code': 'KRW',
              'quantity': 1,
              'total_purchase_amount': 100,
              'total_valuation_amount': 120,
              'profit_amount': 20,
              'profit_rate': 20,
            },
          ],
        },
      ]);

      final items = await db.fetchDisplayPortfolioSnapshotItemsByDates([
        '2026-05-20',
      ]);
      final itemTitles = items.map((item) => item.assetTitle).toSet();

      expect(itemTitles, {'ISA', '주식', '코인', '현금'});
      expect(
        items.singleWhere((item) => item.assetTitle == 'ISA').holdingCount,
        1,
      );
      expect(
        items
            .singleWhere((item) => item.assetTitle == 'ISA')
            .totalValuationAmount,
        120,
      );
      expect(
        items
            .singleWhere((item) => item.assetTitle == '주식')
            .totalValuationAmount,
        360,
      );
      expect(
        items
            .singleWhere((item) => item.assetTitle == '현금')
            .totalValuationAmount,
        240,
      );
    },
  );

  test(
    'display snapshots keep asset summary rows without holding details',
    () async {
      final isaAssetId = await createAsset('ISA');
      final stockAssetId = await createAsset('주식');
      final coinAssetId = await createAsset('코인');
      final cashAssetId = await createAsset('현금');

      await db.importRemotePortfolioSnapshots([
        {
          'snapshot_date': '2026-05-21',
          'total_purchase_amount': 1000,
          'total_valuation_amount': 1200,
          'profit_amount': 200,
          'profit_rate': 20,
          'items': [
            {
              'asset_id': isaAssetId,
              'asset_title': 'ISA',
              'total_purchase_amount': 100,
              'total_valuation_amount': 120,
              'profit_amount': 20,
              'profit_rate': 20,
              'holding_count': 1,
            },
            {
              'asset_id': stockAssetId,
              'asset_title': '주식',
              'total_purchase_amount': 300,
              'total_valuation_amount': 360,
              'profit_amount': 60,
              'profit_rate': 20,
              'holding_count': 2,
            },
            {
              'asset_id': coinAssetId,
              'asset_title': '코인',
              'total_purchase_amount': 400,
              'total_valuation_amount': 480,
              'profit_amount': 80,
              'profit_rate': 20,
              'holding_count': 3,
            },
            {
              'asset_id': cashAssetId,
              'asset_title': '현금',
              'total_purchase_amount': 200,
              'total_valuation_amount': 240,
              'profit_amount': 40,
              'profit_rate': 20,
              'holding_count': 2,
            },
          ],
          'holding_items': const [],
        },
      ]);

      final items = await db.fetchDisplayPortfolioSnapshotItemsByDates([
        '2026-05-21',
      ]);

      expect(items.map((item) => item.assetTitle).toSet(), {
        'ISA',
        '주식',
        '코인',
        '현금',
      });
      expect(
        items
            .singleWhere((item) => item.assetTitle == '코인')
            .totalValuationAmount,
        480,
      );
    },
  );

  test(
    'snapshot restore opening ledger rows are hidden from transaction views',
    () async {
      final assetId = await createAsset('주식');
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '복구 주식',
        symbol: 'RESTORE',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 100,
        note: '',
      );
      final cashAccountId = await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '복구 현금',
        note: '',
        balance: 0,
      );

      await db.customStatement('''
      INSERT INTO transaction_events
        (occurred_at, kind, title, source, sort_order)
      VALUES
        ('2026.05.21', 'opening_balance', '스냅샷 복구 - 복구 주식', 'snapshot_restore', 0)
    ''');
      final holdingEventId = await db
          .customSelect(
            "SELECT id FROM transaction_events WHERE title = '스냅샷 복구 - 복구 주식'",
          )
          .getSingle()
          .then((row) => row.read<int>('id'));
      await db.customStatement(
        '''
      INSERT INTO transaction_lines
        (event_id, asset_id, holding_id, action, currency_code, quantity_delta, cash_delta, unit_price, gross_amount, cost_basis_delta, sort_order)
      VALUES
        (?, ?, ?, 'opening_quantity', 'KRW', 5, 0, 100, 500, 500, 0)
      ''',
        [holdingEventId, assetId, holdingId],
      );

      await db.customStatement('''
      INSERT INTO transaction_events
        (occurred_at, kind, title, source, sort_order)
      VALUES
        ('2026.05.21', 'opening_balance', '스냅샷 복구 - 복구 현금', 'snapshot_restore', 1)
    ''');
      final cashEventId = await db
          .customSelect(
            "SELECT id FROM transaction_events WHERE title = '스냅샷 복구 - 복구 현금'",
          )
          .getSingle()
          .then((row) => row.read<int>('id'));
      await db.customStatement(
        '''
      INSERT INTO transaction_lines
        (event_id, asset_id, cash_account_id, action, currency_code, quantity_delta, cash_delta, unit_price, gross_amount, sort_order)
      VALUES
        (?, ?, ?, 'opening_cash', 'KRW', 0, 1000, 0, 1000, 0)
      ''',
        [cashEventId, assetId, cashAccountId],
      );

      expect(await db.fetchTransactionDates(), isEmpty);
      expect(await db.fetchTransactionsForDate('2026-05-21'), isEmpty);
      expect(await db.fetchCashTransactionsForDate('2026-05-21'), isEmpty);
    },
  );

  test(
    'history display ledger rows are shown in snapshots but ignored by state parity',
    () async {
      final assetId = await createAsset('주식');
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '표시 주식',
        symbol: 'HIST',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 100,
        note: '',
      );

      await db.customStatement('''
      INSERT INTO transaction_events
        (occurred_at, kind, title, source, sort_order)
      VALUES
        ('2026.05.21', 'trade', '과거 표시 매수', 'history_display', 0)
    ''');
      final eventId = await db
          .customSelect(
            "SELECT id FROM transaction_events WHERE title = '과거 표시 매수'",
          )
          .getSingle()
          .then((row) => row.read<int>('id'));
      await db.customStatement(
        '''
      INSERT INTO transaction_lines
        (event_id, asset_id, holding_id, action, currency_code, quantity_delta, cash_delta, unit_price, gross_amount, cost_basis_delta, sort_order)
      VALUES
        (?, ?, ?, 'buy', 'KRW', 5, 0, 100, 500, 500, 0)
      ''',
        [eventId, assetId, holdingId],
      );

      expect(await db.fetchTransactionDates(), {'2026-05-21'});
      final transactions = await db.fetchTransactionsForDate('2026-05-21');
      expect(transactions, hasLength(1));
      expect(transactions.single.name, '과거 표시 매수');
      expect(transactions.single.type, '매수');
      expect(await db.fetchLedgerStateParityIssues(), isEmpty);
    },
  );

  test('holding detail transactions are read from ledger events', () async {
    final assetId = await createAsset('주식');
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
      date: '2026.05.21',
      type: '매수',
      name: '상세 매수',
      amount: '100',
      quantity: '5',
    );
    await db.customStatement("UPDATE transactions SET date = '1999.01.01'");

    final holding = await db.fetchHoldingById(holdingId);

    expect(holding, isNotNull);
    expect(holding!.transactions, hasLength(1));
    expect(holding.transactions.single.date, '2026-05-21');
    expect(holding.transactions.single.type, '매수');
    expect(holding.transactions.single.name, '상세 매수');
    expect(holding.transactions.single.amount, '100');
    expect(holding.transactions.single.quantity, '5');
  });

  test('cash detail transactions are read from ledger lines', () async {
    final assetId = await createAsset('현금');
    final cashHoldingId = await db.createCashAccount(
      assetId: assetId,
      currencyCode: 'KRW',
      name: '생활비',
      note: '',
      balance: 1000,
    );

    await db.createTransaction(
      assetId: assetId,
      holdingId: cashHoldingId,
      date: '2026.05.21',
      type: '출금',
      name: '상세 출금',
      amount: '100',
      quantity: '',
    );
    await db.customStatement(
      "UPDATE cash_transactions SET date = '1999.01.01', name = '레거시 이름'",
    );

    final holding = await db.fetchHoldingById(cashHoldingId);

    expect(holding, isNotNull);
    expect(holding!.transactions, hasLength(1));
    expect(holding.transactions.single.id, isNegative);
    expect(holding.transactions.single.date, '2026-05-21');
    expect(holding.transactions.single.type, '출금');
    expect(holding.transactions.single.name, '상세 출금');
    expect(holding.transactions.single.amount, '-100');
    expect(holding.transactions.single.cashFlowAmount, -100);
    expect(holding.transactions.single.ledgerEventId, isNotNull);
    expect(holding.transactions.single.ledgerLineId, isNotNull);
    expect(holding.transactions.single.ledgerAction, 'withdrawal');
    expect(holding.transactions.single.canOpenCashFormFromLedger, isTrue);
  });

  test('ledger event delete updates legacy mirrors and ledger state', () async {
    final assetId = await createAsset('주식');
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
      date: '2026.05.21',
      type: '매수',
      name: '원장 삭제 매수',
      amount: '100',
      quantity: '5',
    );

    final beforeDelete = await db.fetchHoldingById(holdingId);
    expect(beforeDelete, isNotNull);
    final transaction = beforeDelete!.transactions.single;
    expect(transaction.ledgerEventId, isNotNull);
    expect(transaction.legacySourceTable, isNull);
    expect(transaction.canOpenInvestmentFormFromLedger, isTrue);

    await db.deleteLedgerTransactionItem(transaction);

    final afterDelete = await db.fetchHoldingById(holdingId);
    expect(afterDelete, isNotNull);
    expect(afterDelete!.quantity, 0);
    expect(afterDelete.transactions, isEmpty);

    final activeEventCount = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM transaction_events WHERE deleted_at IS NULL',
        )
        .getSingle();
    final deletedEventCount = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM transaction_events WHERE deleted_at IS NOT NULL',
        )
        .getSingle();

    expect(activeEventCount.read<int>('count'), 0);
    expect(deletedEventCount.read<int>('count'), 1);
  });
}
