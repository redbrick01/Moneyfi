import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> asset(String title) => db.createAsset(
    assetType: '주식',
    title: title,
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

  test('server quote refresh updates only matching owned holdings', () async {
    await db.assignLocalDataOwner('first-user');
    final id = await db.createHolding(
      assetId: await asset('주식'),
      currencyCode: 'KRW',
      exchangeCode: '',
      name: '삼성전자',
      symbol: '005930',
      quantity: 2,
      averagePrice: 70,
      currentPrice: 75,
      note: 'local edit',
    );
    final before = (await db.select(db.holdings).get()).single;
    final quote = {
      'client_id': before.clientId,
      'symbol': '005930',
      'currency_code': 'KRW',
      'exchange_code': '',
      'current_price': 80,
      'market_updated_at': '2026-11-26T12:00:00Z',
    };

    Future<int> apply(
      Map<String, dynamic> row, {
      String owner = 'first-user',
    }) => db.applyServerHoldingPrices(
      [row],
      ownerId: owner,
      canApply: () => true,
    );

    expect(
      await db.applyServerHoldingPrices(
        [quote],
        ownerId: 'first-user',
        clientId: 'different-holding',
        canApply: () => true,
      ),
      0,
    );
    expect(await apply(quote, owner: 'second-user'), 0);
    expect(await apply({...quote, 'symbol': '000660'}), 0);
    expect(await apply(quote), 1);
    final updated = (await db.select(db.holdings).get()).single;
    expect(updated.id, id);
    expect(updated.currentPrice, 80);
    expect(updated.note, 'local edit');
    expect(updated.dirty, before.dirty);
    expect(updated.lastModifiedAt, before.lastModifiedAt);
    expect(
      await apply({...quote, 'market_updated_at': '2026-11-26T12:01:00Z'}),
      1,
    );
    expect(await apply({...quote, 'current_price': 60}), 0);
    final latest = (await db.select(db.holdings).get()).single;
    expect(latest.currentPrice, 80);
    expect(
      DateTime.parse(latest.marketUpdatedAt!),
      DateTime.utc(2026, 11, 26, 12, 1),
    );
  });

  test(
    'remote replacement refuses dirty local records without deleting them',
    () async {
      final id = await asset('보존할 자산');
      await expectLater(
        db.replaceLocalSyncData({
          'assets': <Map<String, Object?>>[],
        }, requireCleanLocal: true),
        throwsStateError,
      );
      expect((await db.select(db.assets).get()).single.id, id);
      expect(await db.hasPendingSyncChanges(), isTrue);
    },
  );

  test(
    'acknowledgement leaves edits made after payload creation dirty',
    () async {
      final id = await asset('처음');
      final sent = await db.buildDirtySyncPayload();
      final clientId = (sent['assets'] as List).single['client_id'] as String;
      await db.customStatement(
        'UPDATE assets SET title = ?, dirty = 1 WHERE id = ?',
        ['나중 수정', id],
      );
      await db.markDirtySyncPayloadAsSynced(sent, {
        'assets': [clientId],
        'holdings': <String>[],
        'cash_accounts': <String>[],
        'transaction_events': <String>[],
        'transaction_lines': <String>[],
        'snapshot_notes': <String>[],
      });
      expect(await db.hasPendingSyncChanges(), isTrue);
      expect((await db.select(db.assets).get()).single.title, '나중 수정');
    },
  );

  test(
    'legacy cleanup never deletes a user record by its display name',
    () async {
      final assetId = await asset('주식');
      final id = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '생활비 통장',
        symbol: 'CASH',
        quantity: 1,
        averagePrice: 1000,
        currentPrice: 1000,
        note: '',
      );
      await db.removeLegacySeededCashHoldings();
      expect((await db.select(db.holdings).get()).single.id, id);
    },
  );

  test('account change during a pull cannot replace existing data', () async {
    await db.assignLocalDataOwner('first-user');
    final id = await asset('기존 계정');
    await db.assignLocalDataOwner('second-user');
    await expectLater(
      db.replaceLocalSyncData(
        {'assets': <Map<String, Object?>>[]},
        enforceOwnerMatch: true,
        expectedOwnerId: 'first-user',
      ),
      throwsStateError,
    );
    expect((await db.select(db.assets).get()).single.id, id);
  });

  test('account switch isolates journal and restores it on return', () async {
    await db.assignLocalDataOwner('first-user');
    await db.customStatement(
      "INSERT INTO daily_investment_reviews (review_date, status, mode, created_at, updated_at) VALUES ('2026-11-15', 'draft', 'manual', 'now', 'now')",
    );
    expect(await db.hasLocalCoreData(), isTrue);
    await db.replaceLocalSyncData(
      {'assets': <Map<String, Object?>>[]},
      requireCleanLocal: true,
      ownerId: 'second-user',
      enforceOwnerMatch: true,
      expectedOwnerId: 'first-user',
    );
    expect(await db.localDataOwner(), 'second-user');
    expect(await db.select(db.dailyInvestmentReviews).get(), isEmpty);
    await db.replaceLocalSyncData(
      {'assets': <Map<String, Object?>>[]},
      ownerId: 'first-user',
      enforceOwnerMatch: true,
      expectedOwnerId: 'second-user',
    );
    expect(
      (await db.select(db.dailyInvestmentReviews).get()).single.reviewDate,
      '2026-11-15',
    );
  });

  test('matching ownerless core keeps local-only investment review', () async {
    final id = await asset('기존 자산');
    final clientId = (await db.select(db.assets).get()).single.clientId!;
    await db.customStatement('UPDATE assets SET dirty = 0');
    await db.customStatement(
      "INSERT INTO daily_investment_reviews (review_date, status, mode, created_at, updated_at) VALUES ('2026-11-15', 'draft', 'manual', 'now', 'now')",
    );

    await db.replaceLocalSyncData(
      {
        'assets': [
          {'client_id': clientId, 'title': '기존 자산'},
        ],
      },
      requireCleanLocal: true,
      ownerId: 'current-user',
      enforceOwnerMatch: true,
      expectedOwnerId: null,
    );

    expect(await db.localDataOwner(), 'current-user');
    expect((await db.select(db.assets).get()).single.clientId, clientId);
    expect(await db.select(db.dailyInvestmentReviews).get(), hasLength(1));
    expect(id, greaterThan(0));
  });

  test('different ownerless core does not retain local-only review', () async {
    await asset('다른 계정 자산');
    await db.customStatement('UPDATE assets SET dirty = 0');
    await db.customStatement(
      "INSERT INTO daily_investment_reviews (review_date, status, mode, created_at, updated_at) VALUES ('2026-11-15', 'draft', 'manual', 'now', 'now')",
    );

    await db.replaceLocalSyncData(
      {
        'assets': [
          {'client_id': 'different-client-id', 'title': '서버 자산'},
        ],
      },
      requireCleanLocal: true,
      ownerId: 'current-user',
      enforceOwnerMatch: true,
      expectedOwnerId: null,
    );

    expect(await db.select(db.dailyInvestmentReviews).get(), isEmpty);
  });

  test('account change during replacement rolls back all deletions', () async {
    await db.assignLocalDataOwner('first-user');
    final id = await asset('보존할 자산');
    await db.customStatement('UPDATE assets SET dirty = 0');
    var checks = 0;
    await expectLater(
      db.replaceLocalSyncData(
        {'assets': <Map<String, Object?>>[]},
        requireCleanLocal: true,
        ownerId: 'first-user',
        canApply: () => ++checks == 1,
      ),
      throwsStateError,
    );
    expect((await db.select(db.assets).get()).single.id, id);
    expect(await db.localDataOwner(), 'first-user');
  });
}
