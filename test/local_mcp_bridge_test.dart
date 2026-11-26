import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/mcp/local_mcp_bridge.dart';
import 'package:moneyfy/features/mcp/mcp_confirmation_dialog.dart';

void main() {
  late AppDatabase db;
  late LocalMcpBridge bridge;
  late int asset;
  late int source;
  late int target;
  bool cloudAvailable = true;
  String? user = 'owner';
  int syncCalls = 0;
  Future<bool> acknowledge(String user) async {
    if (!cloudAvailable) return false;
    await db.markDirtySyncPayloadAsSynced(
      await db.buildDirtySyncPayload(),
      null,
    );
    return true;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cloudAvailable = true;
    user = 'owner';
    syncCalls = 0;
    bridge = LocalMcpBridge(
      db: db,
      userId: () => user,
      confirmChange: (_) async => true,
      sync: (user) async {
        syncCalls++;
        return acknowledge(user);
      },
    );
    await db.assignLocalDataOwner(user!);
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
    'transaction preview uses the ledger and rolls everything back',
    () async {
      final args = transfer('preview_test_01', 500)..remove('request_id');
      final result = await bridge.execute('preview_transaction', {
        'operation': 'transfer_cash',
        'arguments': args,
      });
      final changes = (result['balance_changes'] as List).cast<Map>();
      expect(changes.map((row) => row['after']), [9500, 500]);
      expect((result['proposed'] as Map)['event_id'], isNull);
      expect(await balance(source), 10000);
      expect(await balance(target), 0);
      final search = await bridge.execute('search_transactions', {
        'transaction_type': '이체',
      });
      expect(search['transactions'], isEmpty);
      expect(syncCalls, 0);
    },
  );

  test(
    'an approval is required and a stale preview cannot be applied',
    () async {
      final original = await bridge.execute(
        'transfer_cash',
        transfer('approval_event', 500),
      );
      final deletion = {
        'request_id': 'approval_delete',
        'event_id': original['event_id'],
      };
      bridge = LocalMcpBridge(
        db: db,
        userId: () => user,
        sync: acknowledge,
        confirmChange: (_) async => false,
      );
      await expectLater(
        bridge.execute('delete_transaction', deletion),
        throwsStateError,
      );
      expect(await balance(source), 9500);
      bridge = LocalMcpBridge(
        db: db,
        userId: () => user,
        sync: acknowledge,
        confirmChange: (_) async {
          await db.createCashTransfer(
            assetId: asset,
            sourceHoldingId: source,
            targetHoldingId: target,
            date: '2026-11-14',
            name: '동시 변경',
            amount: '25',
          );
          return true;
        },
      );
      await expectLater(
        bridge.execute('delete_transaction', deletion),
        throwsStateError,
      );
      expect(await balance(source), 9475);
      final detail = await bridge.execute('get_transaction', {
        'event_id': original['event_id'],
      });
      expect(detail['found'], true);
    },
  );

  testWidgets('the MONEYFY approval dialog returns the user’s choice', (
    tester,
  ) async {
    final navigation = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: navigation,
        home: const Scaffold(),
      ),
    );
    final pending = confirmMcpTransaction(navigation.currentState, {
      'operation': 'delete_transaction',
      'original': {
        'date': '2026-11-14',
        'type': '이체',
        'name': '테스트 이체',
        'lines': <Map<String, dynamic>>[],
      },
      'balance_changes': <Map<String, dynamic>>[],
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('테스트 이체'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(await pending, false);
  });

  test(
    'data issues distinguish repeated transactions and unsynced rows',
    () async {
      cloudAvailable = false;
      final first = await bridge.execute(
        'transfer_cash',
        transfer('duplicate_001', 500),
      );
      final second = await bridge.execute(
        'transfer_cash',
        transfer('duplicate_002', 500),
      );
      await bridge.execute('transfer_cash', transfer('different_003', 501));
      await db.createCashAccount(
        assetId: asset,
        currencyCode: 'USD',
        name: '달러',
        note: '',
        balance: 10,
      );
      final result = await bridge.execute('get_data_issues', {
        'from_date': '2026-11-14',
        'to_date': '2026-11-14',
      });
      final duplicate = (result['duplicate_candidates'] as List).single as Map;
      expect(
        duplicate['event_ids'],
        unorderedEquals([first['event_id'], second['event_id']]),
      );
      expect(result['pending_transactions'], hasLength(3));
      expect((result['fx_issue'] as Map)['status'], 'missing');
      expect(syncCalls, 3);
    },
  );

  test(
    'cash account creation is idempotent and checks duplicate names',
    () async {
      final args = {
        'request_id': 'cash_setup_01',
        'asset_id': asset,
        'name': 'New Cash',
        'currency': 'USD',
      };
      final first = await bridge.execute('create_cash_account', args);
      expect(first['supabase_synced'], true);
      final id = first['holding_id'] as int;
      expect(id, lessThan(0));
      expect(await balance(id), 0);
      expect(
        (await bridge.execute('create_cash_account', args))['holding_id'],
        id,
      );
      await expectLater(
        bridge.execute('create_cash_account', {
          ...args,
          'request_id': 'cash_setup_02',
          'name': 'new cash',
        }),
        throwsStateError,
      );
      expect(syncCalls, 1);
    },
  );

  test(
    'status reports readiness without exposing another owner’s data',
    () async {
      final ready = await bridge.execute('get_status', {});
      expect(ready['bridge_connected'], true);
      expect(ready['data_ready'], true);
      expect(ready['pending_local_changes'], true);
      user = 'another-owner';
      final blocked = await bridge.execute('get_status', {});
      expect(blocked['data_ready'], false);
      expect(blocked['pending_local_changes'], isNull);
      expect(syncCalls, 0);
    },
  );

  test(
    'request status reads receipt and acknowledgement without syncing',
    () async {
      const args = {'request_id': 'status_check_01'};
      final missing = await bridge.execute('get_request_status', args);
      expect(missing['status'], 'not_found');
      cloudAvailable = false;
      await bridge.execute('transfer_cash', transfer('status_check_01', 500));
      final pending = await bridge.execute('get_request_status', args);
      expect(pending['status'], 'pending');
      expect(pending['local_saved'], true);
      cloudAvailable = true;
      await acknowledge(user!);
      expect(
        (await bridge.execute('get_request_status', args))['status'],
        'synced',
      );
      expect(syncCalls, 1);
      await db.clearAllLocalUserData();
      await db.assignLocalDataOwner(user!);
      expect(
        (await bridge.execute('get_request_status', args))['status'],
        'invalidated',
      );
    },
  );

  test(
    'transaction search paginates events and keeps both cash-transfer legs',
    () async {
      final first = await bridge.execute(
        'transfer_cash',
        transfer('search_first', 100),
      );
      final second = await bridge.execute(
        'transfer_cash',
        transfer('search_second', 200),
      );
      final filters = {
        'holding_id': target,
        'asset_id': asset,
        'from_date': '2026-11-14',
        'to_date': '2026-11-14',
        'transaction_type': '이체',
        'limit': 1,
      };
      final page = await bridge.execute('search_transactions', filters);
      final event = (page['transactions'] as List).single as Map;
      expect(event['event_id'], second['event_id']);
      final lines = (event['lines'] as List).cast<Map>();
      expect(lines.map((line) => line['holding_id']), [source, target]);
      expect(lines.map((line) => line['cash_delta']), [-200, 200]);
      expect(page['next_offset'], 1);
      final next = await bridge.execute('search_transactions', {
        ...filters,
        'offset': page['next_offset'],
      });
      expect(
        ((next['transactions'] as List).single as Map)['event_id'],
        first['event_id'],
      );
      expect(next['next_offset'], isNull);
      final detail = await bridge.execute('get_transaction', {
        'event_id': second['event_id'],
      });
      expect(detail['transaction'], event);
      final empty = await bridge.execute('search_transactions', {
        ...filters,
        'to_date': '2026-11-15',
        'from_date': '2026-11-15',
      });
      expect(empty['transactions'], isEmpty);
    },
  );

  test(
    'portfolio summary uses snapshot valuation and tracks missing returns',
    () async {
      await db.importRemotePortfolioSnapshots([
        {'snapshot_date': '2026-11-10', 'total_valuation_amount': 10000},
        {
          'snapshot_date': '2026-11-11',
          'total_valuation_amount': 11000,
          'exchange_rate': 1000,
          'created_at': '2026-11-11T09:30:00Z',
          'items': [
            {
              'asset_id': asset,
              'asset_title': '현금',
              'total_valuation_amount': 11000,
            },
          ],
          'cash_accounts': [
            {
              'asset_id': asset,
              'asset_title': '현금',
              'cash_account_id': source.abs(),
              'cash_account_name': '달러',
              'currency_code': 'USD',
              'balance': 1,
            },
          ],
          'holding_items': [
            {
              'asset_id': asset,
              'asset_title': '현금',
              'holding_name': '국내 종목',
              'holding_symbol': 'TEST',
              'currency_code': 'KRW',
              'quantity': 2,
              'total_valuation_amount': 10000,
            },
          ],
        },
      ]);
      final latest = await bridge.execute('get_portfolio_summary', {
        'from_date': '2026-11-11',
      });
      expect(latest['as_of'], '2026-11-11');
      expect(latest['snapshot_created_at'], '2026-11-11T09:30:00Z');
      expect(latest['total_valuation_krw'], 11000);
      expect(latest['usd_krw_rate'], 1000);
      expect(
        ((latest['asset_groups'] as List).single as Map)['valuation_krw'],
        11000,
      );
      expect(
        ((latest['cash_accounts'] as List).single as Map)['valuation_krw'],
        1000,
      );
      expect(
        ((latest['holdings'] as List).single as Map)['allocation_ratio'],
        closeTo(10 / 11, 0.000001),
      );
      final performance = latest['period_return'] as Map;
      expect(performance['return_ratio'], closeTo(0.1, 0.000001));
      expect(performance['complete'], true);
      expect(await db.fetchPortfolioDailyReturns(), isEmpty);
      final partial = await bridge.execute('get_portfolio_summary', {
        'from_date': '2026-11-10',
      });
      expect((partial['period_return'] as Map)['missing_days'], 1);
      expect((partial['period_return'] as Map)['complete'], false);
      final missing = await bridge.execute('get_portfolio_summary', {
        'as_of': '2026-11-12',
      });
      expect(missing['found'], false);
      expect(missing['latest_available_date'], '2026-11-11');
    },
  );
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
        sync: acknowledge,
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
    expect(updated['event_id'], nextEvent);
    expect(nextEvent, isNot(event));
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

  test('reads and writes require a matching, ready local owner', () async {
    user = 'different-user';
    await expectLater(bridge.execute('list_assets', {}), throwsStateError);
    await expectLater(
      bridge.execute('transfer_cash', transfer('other_owner_01', 500)),
      throwsStateError,
    );
    expect(await balance(source), 10000);
    expect(syncCalls, 0);
  });

  test('an unsupported edit keeps the original cash transfer', () async {
    final result = await bridge.execute(
      'transfer_cash',
      transfer('transfer_007', 500),
    );
    await expectLater(
      bridge.execute('update_transaction', {
        'request_id': 'bad_quantity',
        'event_id': result['event_id'],
        'quantity': 2,
      }),
      throwsArgumentError,
    );
    final rows = await bridge.execute('list_recent_transactions', {});
    expect(
      (rows['transactions'] as List).cast<Map>().map((row) => row['event_id']),
      everyElement(result['event_id']),
    );
    expect(await balance(source), 9500);
    expect(syncCalls, 1);
  });

  test(
    'reset invalidates receipts without permitting duplicate writes',
    () async {
      cloudAvailable = false;
      final args = transfer('before_reset', 500);
      await bridge.execute('transfer_cash', args);
      await db.clearAllLocalUserData();
      await db.assignLocalDataOwner(user!);
      cloudAvailable = true;
      await expectLater(
        bridge.execute('retry_sync', {'request_id': args['request_id']}),
        throwsStateError,
      );
      await expectLater(
        bridge.execute('transfer_cash', args),
        throwsStateError,
      );
      expect(syncCalls, 1);
    },
  );

  test(
    'a sync success requires acknowledgement of both transfer lines',
    () async {
      bridge = LocalMcpBridge(
        db: db,
        userId: () => user,
        sync: (user) async => true,
      );
      final result = await bridge.execute(
        'transfer_cash',
        transfer('missing_ack_01', 500),
      );
      expect(result['local_saved'], true);
      expect(result['supabase_synced'], false);
      expect(await balance(source), 9500);
    },
  );
  test(
    'acknowledging a replacement cannot confirm an unsynced original',
    () async {
      cloudAvailable = false;
      final original = await bridge.execute(
        'transfer_cash',
        transfer('superseded_01', 500),
      );
      cloudAvailable = true;
      final replacement = await bridge.execute('update_transaction', {
        'request_id': 'superseded_02',
        'event_id': original['event_id'],
        'amount': 750,
      });
      expect(replacement['supabase_synced'], true);
      final retried = await bridge.execute('retry_sync', {
        'request_id': 'superseded_01',
      });
      expect(retried['supabase_synced'], false);
      expect(await balance(source), 9250);
    },
  );

  test(
    'cash deposit and withdrawal use application ledger and sync payload',
    () async {
      cloudAvailable = false;
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
      final added = await bridge.execute('create_holding', {
        'request_id': 'add_holding_01',
        'asset_id': stockAsset,
        'name': '추가 종목',
        'symbol': 'NEW',
        'currency': 'USD',
        'exchange_code': 'NAS',
      });
      expect(added['supabase_synced'], true);
      final addedHolding = await db.fetchHoldingById(
        added['holding_id'] as int,
      );
      expect(addedHolding?.quantity, 0);
      expect(addedHolding?.exchangeCode, 'NAS');
      await expectLater(
        bridge.execute('create_holding', {
          'request_id': 'add_holding_02',
          'asset_id': stockAsset,
          'name': '별칭',
          'symbol': 'new',
          'currency': 'USD',
        }),
        throwsStateError,
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
      final audit = await bridge.execute('get_data_issues', {});
      expect(((audit['stale_quotes'] as List).single as Map)['symbol'], 'TEST');
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
      final matching = await bridge.execute('search_transactions', {
        'symbol': 'test',
        'holding_id': cash,
        'transaction_type': '매수',
      });
      final purchase = (matching['transactions'] as List).single as Map;
      expect(purchase['event_id'], buy['event_id']);
      expect(
        (purchase['lines'] as List).cast<Map>().map((line) => line['action']),
        ['buy', 'settlement'],
      );
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
