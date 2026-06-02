import 'package:drift/native.dart';
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

  Future<List<String>> tableColumns(String tableName) async {
    final rows = await db.customSelect('PRAGMA table_info($tableName)').get();
    return rows.map((row) => row.read<String>('name')).toList();
  }

  test('snapshot tables keep remote identity columns locally', () async {
    expect(
      await tableColumns('daily_portfolio_snapshot_items'),
      containsAll(['asset_client_id']),
    );
    expect(
      await tableColumns('daily_portfolio_snapshot_holding_items'),
      containsAll(['asset_client_id', 'holding_client_id']),
    );
    expect(
      await tableColumns('daily_portfolio_snapshot_cash_accounts'),
      containsAll(['asset_client_id', 'cash_account_client_id']),
    );
  });

  test('snapshot dates are locally unique', () async {
    final indexes = await db
        .customSelect("PRAGMA index_list('daily_portfolio_snapshots')")
        .get();
    final uniqueIndexes = indexes
        .where((row) => row.read<int>('unique') == 1)
        .map((row) => row.read<String>('name'))
        .toList();

    expect(uniqueIndexes, contains('daily_portfolio_snapshots_date_unique'));
  });

  test('snapshot note edits are included in dirty sync payload', () async {
    await db.saveSnapshotNote(
      snapshotDate: '2026-06-02',
      note: 'review rebalance',
    );

    final payload = await db.buildDirtySyncPayload();

    expect(payload['snapshot_notes'], [
      {
        'snapshot_date': '2026-06-02',
        'note': 'review rebalance',
        'last_modified_at': isA<String>(),
      },
    ]);
  });
}
