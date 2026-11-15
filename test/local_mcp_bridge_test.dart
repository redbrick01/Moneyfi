import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/mcp/local_mcp_bridge.dart';

void main() {
  late AppDatabase db;
  late LocalMcpBridge bridge;
  late int asset;
  late int source;
  late int target;
  bool cloudAvailable = true;
  String? user = 'owner';
  int syncCalls = 0;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cloudAvailable = true;
    user = 'owner';
    syncCalls = 0;
    bridge = LocalMcpBridge(
      db: db,
      userId: () => user,
      sync: () async {
        syncCalls++;
        return cloudAvailable;
      },
    );
    asset = await db.createAsset(
      assetType: '현금',
      title: '현금',
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
    source = await db.createCashAccount(
      assetId: asset,
      currencyCode: 'KRW',
      name: '출금',
      note: '',
      balance: 10000,
    );
    target = await db.createCashAccount(
      assetId: asset,
      currencyCode: 'KRW',
      name: '입금',
      note: '',
      balance: 0,
    );
  });
  tearDown(() async {
    await bridge.close();
    await db.close();
  });
  Future<double> balance(int id) async =>
      (await db.fetchHoldingById(id))!.quantity;
  Map<String, dynamic> transfer(String id, double amount) => {
    'request_id': id,
    'source_holding_id': source,
    'target_holding_id': target,
    'date': '2026-11-14',
    'name': '저축',
    'amount': amount,
  };
  test(
    'transfer commits both legs and retry never duplicates the transfer',
    () async {
      final args = transfer('transfer_001', 500);
      final result = await bridge.execute('transfer_cash', args);
      expect(result['supabase_synced'], true);
      expect(await balance(source), 9500);
      expect(await balance(target), 500);
      await bridge.execute('transfer_cash', args);
      expect(await balance(source), 9500);
      expect(syncCalls, 1);
      await expectLater(
        bridge.execute('transfer_cash', transfer('transfer_001', 600)),
        throwsStateError,
      );
    },
  );
  test(
    'failed cloud sync can resume after bridge recreation without new money movement',
    () async {
      cloudAvailable = false;
      final result = await bridge.execute(
        'transfer_cash',
        transfer('transfer_002', 500),
      );
      expect(result['local_saved'], true);
      expect(result['supabase_synced'], false);
      cloudAvailable = true;
      final restarted = LocalMcpBridge(
        db: db,
        userId: () => user,
        sync: () async => cloudAvailable,
      );
      final retry = await restarted.execute('retry_sync', {
        'request_id': 'transfer_002',
      });
      expect(retry['supabase_synced'], true);
      expect(await balance(source), 9500);
      expect(await balance(target), 500);
    },
  );
  test('update and delete whole transfer recalculate both accounts', () async {
    final result = await bridge.execute(
      'transfer_cash',
      transfer('transfer_003', 500),
    );
    final event = result['event_id'];
    final updated = await bridge.execute('update_transaction', {
      'request_id': 'update_0001',
      'event_id': event,
      'amount': 700,
    });
    expect(updated['supabase_synced'], true);
    expect(await balance(source), 9300);
    expect(await balance(target), 700);
    final rows = await bridge.execute('list_recent_transactions', {});
    final nextEvent = (rows['transactions'] as List).cast<Map>().firstWhere(
      (t) => t['type'] == '이체',
    )['event_id'];
    await bridge.execute('delete_transaction', {
      'request_id': 'delete_0001',
      'event_id': nextEvent,
    });
    expect(await balance(source), 10000);
    expect(await balance(target), 0);
  });
  test('insufficient funds and invalid dates do not change balances', () async {
    await expectLater(
      bridge.execute('transfer_cash', transfer('transfer_004', 20000)),
      throwsStateError,
    );
    final bad = transfer('transfer_005', 500)..['date'] = '2026-02-30';
    await expectLater(
      bridge.execute('transfer_cash', bad),
      throwsArgumentError,
    );
    expect(await balance(source), 10000);
    expect(await balance(target), 0);
    expect(syncCalls, 0);
  });
  test('logged out user cannot read or mutate', () async {
    user = null;
    await expectLater(bridge.execute('list_assets', {}), throwsStateError);
    await expectLater(
      bridge.execute('transfer_cash', transfer('transfer_006', 500)),
      throwsStateError,
    );
  });
  test(
    'cash deposit and withdrawal use application ledger and sync payload',
    () async {
      var index = 0;
      for (final type in ['입금', '출금', '배당', '이자']) {
        index++;
        await bridge.execute('create_transaction', {
          'request_id': 'cash_event_$index',
          'holding_id': target,
          'date': '2026-11-14',
          'type': type,
          'name': type,
          'amount': 100,
        });
      }
      expect(await balance(target), 200);
      final payload = await db.buildDirtySyncPayload();
      expect(
        (payload['transaction_events'] as List).length,
        greaterThanOrEqualTo(4),
      );
      expect(
        (payload['transaction_lines'] as List).length,
        greaterThanOrEqualTo(4),
      );
    },
  );
  test(
    'buy sell edit and delete preserve stock quantity and settlement cash',
    () async {
      final stockAsset = await db.createAsset(
        assetType: '주식',
        title: '주식',
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
      final holding = await db.createHolding(
        assetId: stockAsset,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '테스트',
        symbol: 'TEST',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 100,
        note: '',
      );
      final cash = await db.createCashAccount(
        assetId: stockAsset,
        currencyCode: 'KRW',
        name: '결제',
        note: '',
        balance: 10000,
      );
      final buy = await bridge.execute('create_transaction', {
        'request_id': 'stock_buy_001',
        'holding_id': holding,
        'date': '2026-11-14',
        'type': '매수',
        'name': '매수',
        'amount': 100,
        'quantity': 10,
      });
      expect(await balance(holding), 10);
      expect(await balance(cash), 9000);
      final sell = await bridge.execute('create_transaction', {
        'request_id': 'stock_sell_001',
        'holding_id': holding,
        'date': '2026-11-14',
        'type': '매도',
        'name': '매도',
        'amount': 120,
        'quantity': 2,
      });
      expect(await balance(holding), 8);
      expect(await balance(cash), 9240);
      await bridge.execute('update_transaction', {
        'request_id': 'stock_edit_001',
        'event_id': sell['event_id'],
        'quantity': 3,
      });
      expect(await balance(holding), 7);
      expect(await balance(cash), 9360);
      // Removing the funding buy would make the remaining sell impossible.
      await expectLater(
        bridge.execute('delete_transaction', {
          'request_id': 'stock_delete_bad',
          'event_id': buy['event_id'],
        }),
        throwsStateError,
      );
      expect(await balance(holding), 7);
      expect(await balance(cash), 9360);
      final rows =
          (await bridge.execute('list_recent_transactions', {}))['transactions']
              as List;
      final sellId = rows.cast<Map>().firstWhere(
        (t) => t['type'] == '매도',
      )['event_id'];
      await bridge.execute('delete_transaction', {
        'request_id': 'stock_delete_sell',
        'event_id': sellId,
      });
      await bridge.execute('delete_transaction', {
        'request_id': 'stock_delete_buy',
        'event_id': buy['event_id'],
      });
      expect(await balance(holding), 0);
      expect(await balance(cash), 10000);
    },
  );
  test(
    'exchange rate edit updates both currencies and deletion reverses it',
    () async {
      final exchange = await bridge.execute('exchange_cash', {
        'request_id': 'exchange_001',
        'source_holding_id': source,
        'date': '2026-11-14',
        'name': '환전',
        'amount': 3000,
        'fx_rate': 1500,
      });
      final usd = (await db.fetchAssets())
          .expand((a) => a.holdings)
          .firstWhere((h) => h.currencyCode == 'USD')
          .id!;
      expect(await balance(source), 7000);
      expect(await balance(usd), 2);
      await bridge.execute('update_transaction', {
        'request_id': 'exchange_edit_001',
        'event_id': exchange['event_id'],
        'fx_rate': 1000,
      });
      expect(await balance(usd), 3);
      final rows =
          (await bridge.execute('list_recent_transactions', {}))['transactions']
              as List;
      final event = rows.cast<Map>().firstWhere(
        (t) => t['type'] == '환전',
      )['event_id'];
      await bridge.execute('delete_transaction', {
        'request_id': 'exchange_delete_001',
        'event_id': event,
      });
      expect(await balance(source), 10000);
      expect(await balance(usd), 0);
    },
  );
}
