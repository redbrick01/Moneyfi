import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' show IconData;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_item.dart';
import '../utils/display_currency.dart';

part 'app_database_records.dart';
part 'app_database_tables.dart';
part 'app_database_calculations.dart';
part 'app_database.g.dart';

const Uuid _uuid = Uuid();

@DriftDatabase(
  tables: [
    Assets,
    Holdings,
    Transactions,
    CashAccounts,
    CashTransactions,
    TransactionEvents,
    TransactionLines,
    MarketNewsCaches,
    CompanyNewsCaches,
    DailyPortfolioSnapshots,
    DailyPortfolioSnapshotItems,
    DailyPortfolioSnapshotHoldingItems,
    AssetAllocationTargets,
    ExchangeRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase._internal();

  @override
  int get schemaVersion => 32;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _ensureCashTables();
      await _ensureLedgerTables();
      await _ensureNewsCacheTables();
      await _ensurePortfolioDiagnosisCacheTable();
      await customStatement('''
            CREATE TABLE IF NOT EXISTS snapshot_notes (
              snapshot_date TEXT NOT NULL PRIMARY KEY,
              note TEXT NOT NULL DEFAULT ''
            )
          ''');
      await _migrateLegacyCashHoldingsToCashAccounts();
      await _backfillAllClientIds();
    },
    onUpgrade: (migrator, from, to) async {
      await _createCurrentTablesIfNeeded();
      await _ensureCashTables();
      await _ensureLedgerTables();
      await _ensureNewsCacheTables();
      await _ensurePortfolioDiagnosisCacheTable();

      if (from < 10 && await _tableExists('assets')) {
        await customStatement(
          "ALTER TABLE assets ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'KRW'",
        );
      }

      if (from < 11 && await _tableExists('holdings')) {
        await customStatement(
          "ALTER TABLE holdings ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'KRW'",
        );
      }

      if (from < 12 && await _tableExists('holdings')) {
        await customStatement(
          'ALTER TABLE holdings ADD COLUMN market_updated_at TEXT',
        );
      }

      if (from < 13 && await _tableExists('holdings')) {
        await customStatement(
          "ALTER TABLE holdings ADD COLUMN exchange_code TEXT NOT NULL DEFAULT ''",
        );
      }

      if (from < 14 && await _tableExists('assets')) {
        await customStatement(
          "ALTER TABLE assets ADD COLUMN alias TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          "UPDATE assets SET alias = title WHERE alias = ''",
        );
      }

      if (from < 15 && await _tableExists('assets')) {
        await customStatement(
          "ALTER TABLE assets ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0",
        );
      }

      if (from < 15 && await _tableExists('holdings')) {
        await customStatement(
          "ALTER TABLE holdings ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0",
        );
      }

      if (from < 16) {
        await customStatement('''
              CREATE TABLE IF NOT EXISTS snapshot_notes (
                snapshot_date TEXT NOT NULL PRIMARY KEY,
                note TEXT NOT NULL DEFAULT ''
              )
            ''');
      }

      if (from < 17) {
        await customStatement('''
              CREATE TABLE IF NOT EXISTS daily_portfolio_snapshot_holding_items (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                snapshot_id INTEGER NOT NULL REFERENCES daily_portfolio_snapshots(id),
                asset_id INTEGER,
                asset_title TEXT NOT NULL,
                holding_id INTEGER,
                holding_name TEXT NOT NULL,
                holding_symbol TEXT NOT NULL,
                currency_code TEXT NOT NULL,
                quantity REAL NOT NULL,
                total_purchase_amount REAL NOT NULL,
                total_valuation_amount REAL NOT NULL,
                profit_amount REAL NOT NULL,
                profit_rate REAL NOT NULL
              )
            ''');
      }

      if (from < 18 && await _tableExists('assets')) {
        await customStatement(
          "ALTER TABLE assets ADD COLUMN asset_type TEXT NOT NULL DEFAULT '주식'",
        );
        await customStatement(
          "UPDATE assets SET asset_type = title WHERE asset_type = '주식'",
        );
      }

      if (from < 19) {
        await _migrateLegacyCashHoldingsToCashAccounts();
      }

      if (from < 20 && await _tableExists('cash_accounts')) {
        if (!await _columnExists('cash_accounts', 'base_balance')) {
          await customStatement(
            "ALTER TABLE cash_accounts ADD COLUMN base_balance REAL NOT NULL DEFAULT 0",
          );
        }
        await _backfillCashAccountBaseBalances();
      }

      if (from < 21 && await _tableExists('cash_transactions')) {
        if (!await _columnExists(
          'cash_transactions',
          'linked_transaction_id',
        )) {
          await customStatement(
            'ALTER TABLE cash_transactions ADD COLUMN linked_transaction_id INTEGER',
          );
        }
      }

      if (from < 22) {
        await customStatement('''
              CREATE TABLE IF NOT EXISTS daily_portfolio_snapshot_cash_accounts (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                snapshot_id INTEGER NOT NULL REFERENCES daily_portfolio_snapshots(id),
                asset_id INTEGER,
                asset_title TEXT NOT NULL,
                cash_account_id INTEGER,
                cash_account_name TEXT NOT NULL,
                currency_code TEXT NOT NULL,
                balance REAL NOT NULL,
                note TEXT NOT NULL DEFAULT ''
              )
            ''');
        await _backfillExistingSnapshotCashAccounts();
      }

      if (from < 23) {
        if (await _tableExists('assets') &&
            !await _columnExists('assets', 'client_id')) {
          await customStatement('ALTER TABLE assets ADD COLUMN client_id TEXT');
        }
        if (await _tableExists('holdings') &&
            !await _columnExists('holdings', 'client_id')) {
          await customStatement(
            'ALTER TABLE holdings ADD COLUMN client_id TEXT',
          );
        }
        if (await _tableExists('transactions') &&
            !await _columnExists('transactions', 'client_id')) {
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN client_id TEXT',
          );
        }
        if (await _tableExists('cash_accounts') &&
            !await _columnExists('cash_accounts', 'client_id')) {
          await customStatement(
            'ALTER TABLE cash_accounts ADD COLUMN client_id TEXT',
          );
        }
        if (await _tableExists('cash_transactions') &&
            !await _columnExists('cash_transactions', 'client_id')) {
          await customStatement(
            'ALTER TABLE cash_transactions ADD COLUMN client_id TEXT',
          );
        }
        await _backfillAllClientIds();
      }

      if (from < 24 && await _tableExists('daily_portfolio_snapshots')) {
        if (!await _columnExists(
          'daily_portfolio_snapshots',
          'exchange_rate',
        )) {
          await customStatement(
            'ALTER TABLE daily_portfolio_snapshots ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1',
          );
        }
      }

      if (from < 26) {
        await _ensureLocalSyncMetadataColumns();
      }
      if (from < 27) {
        await _ensureNewsCacheTables();
      }
      if (from < 28) {
        await _ensureNormalizedTransactionColumns();
        await _backfillNormalizedTransactionColumns();
      }
      if (from < 29) {
        await _ensureLedgerTables();
      }
      if (from < 30) {
        await rebuildNormalizedLedgerFromLegacy(markDirty: false);
      }
      if (from < 31) {
        await _ensureLedgerLineLegacySourceColumns();
        await rebuildNormalizedLedgerFromLegacy(markDirty: false);
      }
      if (from < 32) {
        await _ensureTransactionEventFlowCategoryColumn();
        await _backfillTransactionEventFlowCategories();
      }

      await _ensureSeedExchangeRateIfEmpty();
    },
  );

  String _syncTimestamp() => DateTime.now().toIso8601String();

  String _transactionFlowCategoryForCashType(String type) {
    return switch (_normalizeTransactionType(type)) {
      '입금' => TransactionFlowCategory.externalDeposit,
      '출금' => TransactionFlowCategory.externalWithdrawal,
      _ => TransactionFlowCategory.internal,
    };
  }

  Future<void> _softDeleteByIds(String tableName, List<int> ids) async {
    if (ids.isEmpty) return;
    final deletedAt = _syncTimestamp();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement(
      'UPDATE $tableName SET dirty = 1, last_modified_at = ?, deleted_at = ? WHERE id IN ($placeholders)',
      [deletedAt, deletedAt, ...ids],
    );
  }

  Future<void> _ensureLocalSyncMetadataColumns() async {
    final tableNames = [
      'assets',
      'holdings',
      'transactions',
      'cash_accounts',
      'cash_transactions',
      'transaction_events',
      'transaction_lines',
    ];

    for (final tableName in tableNames) {
      if (!await _tableExists(tableName)) continue;
      if (!await _columnExists(tableName, 'dirty')) {
        await customStatement(
          'ALTER TABLE $tableName ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!await _columnExists(tableName, 'last_modified_at')) {
        await customStatement(
          'ALTER TABLE $tableName ADD COLUMN last_modified_at TEXT',
        );
      }
      if (!await _columnExists(tableName, 'deleted_at')) {
        await customStatement(
          'ALTER TABLE $tableName ADD COLUMN deleted_at TEXT',
        );
      }
    }
  }

  Future<void> _ensureNormalizedTransactionColumns() async {
    if (await _tableExists('transactions')) {
      final transactionColumns = <String, String>{
        'unit_price': 'REAL NOT NULL DEFAULT 0',
        'quantity_value': 'REAL NOT NULL DEFAULT 0',
        'gross_amount': 'REAL NOT NULL DEFAULT 0',
        'cash_flow_amount': 'REAL NOT NULL DEFAULT 0',
        'realized_profit_amount': 'REAL NOT NULL DEFAULT 0',
      };
      for (final entry in transactionColumns.entries) {
        if (!await _columnExists('transactions', entry.key)) {
          await customStatement(
            'ALTER TABLE transactions ADD COLUMN ${entry.key} ${entry.value}',
          );
        }
      }
    }

    if (await _tableExists('cash_transactions')) {
      final cashTransactionColumns = <String, String>{
        'amount_value': 'REAL NOT NULL DEFAULT 0',
        'cash_flow_amount': 'REAL NOT NULL DEFAULT 0',
      };
      for (final entry in cashTransactionColumns.entries) {
        if (!await _columnExists('cash_transactions', entry.key)) {
          await customStatement(
            'ALTER TABLE cash_transactions ADD COLUMN ${entry.key} ${entry.value}',
          );
        }
      }
    }
  }

  Future<void> _ensureLedgerTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS transaction_events (
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
        flow_category TEXT NOT NULL DEFAULT 'internal',
        legacy_source_table TEXT,
        legacy_source_id INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS transaction_lines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES transaction_events(id),
        asset_id INTEGER REFERENCES assets(id),
        holding_id INTEGER REFERENCES holdings(id),
        cash_account_id INTEGER REFERENCES cash_accounts(id),
        client_id TEXT,
        dirty INTEGER NOT NULL DEFAULT 0,
        last_modified_at TEXT,
        deleted_at TEXT,
        legacy_source_table TEXT,
        legacy_source_id INTEGER,
        action TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'KRW',
        quantity_delta REAL NOT NULL DEFAULT 0,
        cash_delta REAL NOT NULL DEFAULT 0,
        unit_price REAL NOT NULL DEFAULT 0,
        gross_amount REAL NOT NULL DEFAULT 0,
        fee_amount REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        cost_basis_delta REAL NOT NULL DEFAULT 0,
        realized_pnl REAL NOT NULL DEFAULT 0,
        fx_rate REAL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_events_deleted_at_idx ON transaction_events(deleted_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_events_kind_idx ON transaction_events(kind)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_events_flow_category_idx ON transaction_events(flow_category)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_lines_event_id_idx ON transaction_lines(event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_lines_holding_id_idx ON transaction_lines(holding_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_lines_cash_account_id_idx ON transaction_lines(cash_account_id)',
    );
    await _ensureLedgerLineLegacySourceColumns();
    await _ensureTransactionEventFlowCategoryColumn();
  }

  Future<void> _ensureTransactionEventFlowCategoryColumn() async {
    if (!await _tableExists('transaction_events')) return;
    if (!await _columnExists('transaction_events', 'flow_category')) {
      await customStatement(
        "ALTER TABLE transaction_events ADD COLUMN flow_category TEXT NOT NULL DEFAULT 'internal'",
      );
    }
    await customStatement(
      'CREATE INDEX IF NOT EXISTS transaction_events_flow_category_idx ON transaction_events(flow_category)',
    );
  }

  Future<void> _backfillTransactionEventFlowCategories() async {
    if (!await _tableExists('transaction_events') ||
        !await _tableExists('transaction_lines')) {
      return;
    }
    await customStatement('''
      UPDATE transaction_events
      SET flow_category = 'internal'
      WHERE flow_category IS NULL OR flow_category = ''
    ''');
    await customStatement('''
      UPDATE transaction_events
      SET flow_category = 'external_deposit'
      WHERE kind = 'cash_flow'
        AND deleted_at IS NULL
        AND EXISTS (
          SELECT 1
          FROM transaction_lines
          WHERE transaction_lines.event_id = transaction_events.id
            AND transaction_lines.deleted_at IS NULL
            AND transaction_lines.action = 'deposit'
        )
    ''');
    await customStatement('''
      UPDATE transaction_events
      SET flow_category = 'external_withdrawal'
      WHERE kind = 'cash_flow'
        AND deleted_at IS NULL
        AND EXISTS (
          SELECT 1
          FROM transaction_lines
          WHERE transaction_lines.event_id = transaction_events.id
            AND transaction_lines.deleted_at IS NULL
            AND transaction_lines.action = 'withdrawal'
        )
    ''');
  }

  Future<void> _ensureLedgerLineLegacySourceColumns() async {
    if (!await _tableExists('transaction_lines')) return;
    if (!await _columnExists('transaction_lines', 'legacy_source_table')) {
      await customStatement(
        'ALTER TABLE transaction_lines ADD COLUMN legacy_source_table TEXT',
      );
    }
    if (!await _columnExists('transaction_lines', 'legacy_source_id')) {
      await customStatement(
        'ALTER TABLE transaction_lines ADD COLUMN legacy_source_id INTEGER',
      );
    }
  }

  Future<void> _backfillNormalizedTransactionColumns() async {
    if (await _tableExists('holdings')) {
      final holdingIds = await customSelect(
        'SELECT id FROM holdings',
        readsFrom: {holdings},
      ).get();
      for (final row in holdingIds) {
        await _recalculateHoldingFromTransactions(
          row.read<int>('id'),
          markDirty: false,
        );
      }
    }

    if (await _tableExists('cash_accounts')) {
      final cashAccountIds = await customSelect(
        'SELECT id FROM cash_accounts',
        readsFrom: {cashAccounts},
      ).get();
      for (final row in cashAccountIds) {
        await _recalculateCashAccountFromTransactions(
          row.read<int>('id'),
          markDirty: false,
        );
      }
    }
  }

  Future<void> rebuildNormalizedLedgerFromLegacy({
    bool markDirty = false,
  }) async {
    await _ensureLedgerTables();

    await transaction(() async {
      await delete(transactionLines).go();
      await delete(transactionEvents).go();

      final holdingRows = await select(holdings).get();
      final holdingById = {for (final row in holdingRows) row.id: row};
      final cashAccountRows = await select(cashAccounts).get();
      final cashAccountById = {for (final row in cashAccountRows) row.id: row};

      await _insertLegacyInvestmentLedger(
        holdingById: holdingById,
        cashAccountById: cashAccountById,
        markDirty: markDirty,
      );
      await _insertLegacyCashLedger(
        cashAccountById: cashAccountById,
        markDirty: markDirty,
      );
    });
  }

  Future<void> _refreshSnapshotAndLedgerAfterLegacyMutation({
    Set<int> investmentHoldingIds = const {},
    bool cashLedgerChanged = false,
  }) async {
    if (investmentHoldingIds.isEmpty && !cashLedgerChanged) {
      await rebuildNormalizedLedgerFromLegacy(markDirty: true);
    } else {
      await _refreshNormalizedLedgerFromLegacyScope(
        investmentHoldingIds: investmentHoldingIds,
        cashLedgerChanged: cashLedgerChanged,
        markDirty: true,
        softDeleteOldLedger: true,
      );
    }
    await refreshTodaySnapshot();
  }

  Future<void> _refreshNormalizedLedgerFromLegacyScope({
    Set<int> investmentHoldingIds = const {},
    bool cashLedgerChanged = false,
    bool markDirty = false,
    bool softDeleteOldLedger = false,
  }) async {
    await _ensureLedgerTables();

    await transaction(() async {
      final holdingRows = await select(holdings).get();
      final holdingById = {for (final row in holdingRows) row.id: row};
      final cashAccountRows = await select(cashAccounts).get();
      final cashAccountById = {for (final row in cashAccountRows) row.id: row};

      if (investmentHoldingIds.isNotEmpty) {
        final transactionIds = await _legacyTransactionIdsForHoldingIds(
          investmentHoldingIds,
        );
        await _deleteLedgerEventsForLegacySources(
          sourceTable: 'transactions',
          sourceIds: transactionIds,
          softDelete: softDeleteOldLedger,
          markDirty: markDirty,
        );
        await _insertLegacyInvestmentLedger(
          holdingById: holdingById,
          cashAccountById: cashAccountById,
          markDirty: markDirty,
          holdingIds: investmentHoldingIds,
        );
      }

      if (cashLedgerChanged) {
        await _deleteLedgerEventsForLegacyTable(
          'cash_transactions',
          softDelete: softDeleteOldLedger,
          markDirty: markDirty,
        );
        await _insertLegacyCashLedger(
          cashAccountById: cashAccountById,
          markDirty: markDirty,
        );
      }
    });

    for (final holdingId in investmentHoldingIds) {
      await _recalculateHoldingFromLedgerLines(holdingId, markDirty: markDirty);
    }
    if (investmentHoldingIds.isNotEmpty) {
      final placeholders = List.filled(
        investmentHoldingIds.length,
        '?',
      ).join(', ');
      final rows = await customSelect(
        '''
          SELECT DISTINCT settlement.cash_account_id AS cash_account_id
          FROM transaction_lines investment
          INNER JOIN transaction_events te ON te.id = investment.event_id
          INNER JOIN transaction_lines settlement
            ON settlement.event_id = investment.event_id
          WHERE investment.deleted_at IS NULL
            AND settlement.deleted_at IS NULL
            AND te.deleted_at IS NULL
            AND investment.holding_id IN ($placeholders)
            AND settlement.cash_account_id IS NOT NULL
        ''',
        variables: investmentHoldingIds
            .map((holdingId) => Variable.withInt(holdingId))
            .toList(),
        readsFrom: {transactionEvents, transactionLines},
      ).get();
      for (final row in rows) {
        await _recalculateCashAccountFromLedgerLines(
          row.read<int>('cash_account_id'),
          markDirty: markDirty,
        );
      }
    }
    if (cashLedgerChanged) {
      final cashAccountRows = await select(cashAccounts).get();
      for (final account in cashAccountRows) {
        await _recalculateCashAccountFromLedgerLines(
          account.id,
          markDirty: markDirty,
        );
      }
    }
  }

  Future<List<int>> _legacyTransactionIdsForHoldingIds(
    Set<int> holdingIds,
  ) async {
    if (holdingIds.isEmpty) return const [];
    final rows = await (select(
      transactions,
    )..where((table) => table.holdingId.isIn(holdingIds.toList()))).get();
    return rows.map((row) => row.id).toList(growable: false);
  }

  Future<void> _deleteLedgerEventsForLegacyTable(
    String sourceTable, {
    bool softDelete = false,
    bool markDirty = false,
  }) async {
    final rows = await (select(
      transactionEvents,
    )..where((table) => table.legacySourceTable.equals(sourceTable))).get();
    await _deleteLedgerEvents(
      rows.map((row) => row.id).toList(growable: false),
      softDelete: softDelete,
      markDirty: markDirty,
    );
  }

  Future<void> _deleteLedgerEventsForLegacySources({
    required String sourceTable,
    required List<int> sourceIds,
    bool softDelete = false,
    bool markDirty = false,
  }) async {
    if (sourceIds.isEmpty) return;
    final rows =
        await (select(transactionEvents)..where(
              (table) =>
                  table.legacySourceTable.equals(sourceTable) &
                  table.legacySourceId.isIn(sourceIds),
            ))
            .get();
    await _deleteLedgerEvents(
      rows.map((row) => row.id).toList(growable: false),
      softDelete: softDelete,
      markDirty: markDirty,
    );
  }

  Future<void> _deleteLedgerEvents(
    List<int> eventIds, {
    bool softDelete = false,
    bool markDirty = false,
  }) async {
    if (eventIds.isEmpty) return;
    if (softDelete) {
      final timestamp = _syncTimestamp();
      await (update(
        transactionLines,
      )..where((table) => table.eventId.isIn(eventIds))).write(
        TransactionLinesCompanion(
          deletedAt: Value(timestamp),
          dirty: Value(markDirty),
          lastModifiedAt: Value(markDirty ? timestamp : null),
        ),
      );
      await (update(
        transactionEvents,
      )..where((table) => table.id.isIn(eventIds))).write(
        TransactionEventsCompanion(
          deletedAt: Value(timestamp),
          dirty: Value(markDirty),
          lastModifiedAt: Value(markDirty ? timestamp : null),
        ),
      );
      return;
    }
    await (delete(
      transactionLines,
    )..where((table) => table.eventId.isIn(eventIds))).go();
    await (delete(
      transactionEvents,
    )..where((table) => table.id.isIn(eventIds))).go();
  }

  Future<Map<int, LedgerHoldingPerformanceRecord>>
  fetchLedgerHoldingPerformanceByHoldingId({
    DateTime? from,
    DateTime? to,
  }) async {
    final dateWhere = _ledgerDateWhereClause(from: from, to: to);
    final rows = await customSelect(
      '''
        SELECT
          holding_id,
          COALESCE(SUM(quantity_delta), 0) AS quantity,
          COALESCE(SUM(cost_basis_delta), 0) AS remaining_cost,
          COALESCE(SUM(realized_pnl), 0) AS realized_pnl,
          COALESCE(SUM(
            CASE
              WHEN action IN ('dividend', 'interest') THEN
                CASE
                  WHEN ABS(COALESCE(gross_amount, 0)) > 0 THEN ABS(gross_amount)
                  ELSE ABS(COALESCE(cash_delta, 0))
                END
              ELSE 0
            END
          ), 0) AS income_amount,
          COALESCE(SUM(CASE WHEN action = 'buy' THEN gross_amount ELSE 0 END), 0) AS buy_amount,
          COALESCE(SUM(CASE WHEN action = 'sell' THEN gross_amount ELSE 0 END), 0) AS sell_amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
        WHERE tl.deleted_at IS NULL
          AND holding_id IS NOT NULL
          $dateWhere
        GROUP BY holding_id
      ''',
      variables: _ledgerDateVariables(from: from, to: to),
      readsFrom: {transactionEvents, transactionLines},
    ).get();

    return {
      for (final row in rows)
        row.read<int>('holding_id'): LedgerHoldingPerformanceRecord(
          holdingId: row.read<int>('holding_id'),
          quantity: row.read<double>('quantity'),
          remainingCost: row.read<double>('remaining_cost'),
          realizedPnl: row.read<double>('realized_pnl'),
          incomeAmount: row.read<double>('income_amount'),
          buyAmount: row.read<double>('buy_amount'),
          sellAmount: row.read<double>('sell_amount'),
        ),
    };
  }

  Future<LedgerPortfolioPerformanceRecord> fetchLedgerPortfolioPerformance({
    DateTime? from,
    DateTime? to,
  }) async {
    final dateWhere = _ledgerDateWhereClause(from: from, to: to);
    final row = await customSelect(
      '''
        SELECT
          COALESCE(SUM(realized_pnl), 0) AS realized_pnl,
          COALESCE(SUM(
            CASE
              WHEN action IN ('dividend', 'interest') THEN
                CASE
                  WHEN ABS(COALESCE(gross_amount, 0)) > 0 THEN ABS(gross_amount)
                  ELSE ABS(COALESCE(cash_delta, 0))
                END
              ELSE 0
            END
          ), 0) AS income_amount,
          COALESCE(SUM(
            CASE
              WHEN action = 'fee' THEN
                CASE
                  WHEN ABS(COALESCE(cash_delta, 0)) > 0 THEN ABS(cash_delta)
                  ELSE ABS(COALESCE(gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS fee_amount,
          COALESCE(SUM(
            CASE
              WHEN action = 'tax' THEN
                CASE
                  WHEN ABS(COALESCE(cash_delta, 0)) > 0 THEN ABS(cash_delta)
                  ELSE ABS(COALESCE(gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS tax_amount,
          COALESCE(SUM(CASE WHEN action IN ('deposit', 'withdrawal', 'opening_cash') THEN cash_delta ELSE 0 END), 0) AS external_cash_flow_amount,
          COALESCE(SUM(CASE WHEN action IN ('deposit', 'opening_cash') THEN ABS(cash_delta) ELSE 0 END), 0) AS external_deposit_amount,
          COALESCE(SUM(CASE WHEN action = 'withdrawal' THEN ABS(cash_delta) ELSE 0 END), 0) AS external_withdrawal_amount,
          COALESCE(SUM(CASE WHEN action = 'settlement' THEN cash_delta ELSE 0 END), 0) AS trade_settlement_cash_flow_amount,
          COALESCE(SUM(CASE WHEN action IN ('transfer_out', 'transfer_in', 'fx_out', 'fx_in') THEN ABS(cash_delta) ELSE 0 END), 0) AS internal_cash_movement_amount,
          COALESCE(SUM(CASE WHEN action = 'buy' THEN gross_amount ELSE 0 END), 0) AS buy_amount,
          COALESCE(SUM(CASE WHEN action = 'sell' THEN gross_amount ELSE 0 END), 0) AS sell_amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
        WHERE tl.deleted_at IS NULL
          $dateWhere
      ''',
      variables: _ledgerDateVariables(from: from, to: to),
      readsFrom: {transactionEvents, transactionLines},
    ).getSingle();

    return LedgerPortfolioPerformanceRecord(
      realizedPnl: row.read<double>('realized_pnl'),
      incomeAmount: row.read<double>('income_amount'),
      feeAmount: row.read<double>('fee_amount'),
      taxAmount: row.read<double>('tax_amount'),
      externalCashFlowAmount: row.read<double>('external_cash_flow_amount'),
      externalDepositAmount: row.read<double>('external_deposit_amount'),
      externalWithdrawalAmount: row.read<double>('external_withdrawal_amount'),
      tradeSettlementCashFlowAmount: row.read<double>(
        'trade_settlement_cash_flow_amount',
      ),
      internalCashMovementAmount: row.read<double>(
        'internal_cash_movement_amount',
      ),
      buyAmount: row.read<double>('buy_amount'),
      sellAmount: row.read<double>('sell_amount'),
    );
  }

  Future<Map<String, LedgerPortfolioPerformanceRecord>>
  fetchLedgerPortfolioPerformanceByCurrency({
    DateTime? from,
    DateTime? to,
  }) async {
    final dateWhere = _ledgerDateWhereClause(from: from, to: to);
    final rows = await customSelect(
      '''
        SELECT
          COALESCE(NULLIF(currency_code, ''), 'KRW') AS currency_code,
          COALESCE(SUM(realized_pnl), 0) AS realized_pnl,
          COALESCE(SUM(
            CASE
              WHEN action IN ('dividend', 'interest') THEN
                CASE
                  WHEN ABS(COALESCE(gross_amount, 0)) > 0 THEN ABS(gross_amount)
                  ELSE ABS(COALESCE(cash_delta, 0))
                END
              ELSE 0
            END
          ), 0) AS income_amount,
          COALESCE(SUM(
            CASE
              WHEN action = 'fee' THEN
                CASE
                  WHEN ABS(COALESCE(cash_delta, 0)) > 0 THEN ABS(cash_delta)
                  ELSE ABS(COALESCE(gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS fee_amount,
          COALESCE(SUM(
            CASE
              WHEN action = 'tax' THEN
                CASE
                  WHEN ABS(COALESCE(cash_delta, 0)) > 0 THEN ABS(cash_delta)
                  ELSE ABS(COALESCE(gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS tax_amount,
          COALESCE(SUM(CASE WHEN action IN ('deposit', 'withdrawal', 'opening_cash') THEN cash_delta ELSE 0 END), 0) AS external_cash_flow_amount,
          COALESCE(SUM(CASE WHEN action IN ('deposit', 'opening_cash') THEN ABS(cash_delta) ELSE 0 END), 0) AS external_deposit_amount,
          COALESCE(SUM(CASE WHEN action = 'withdrawal' THEN ABS(cash_delta) ELSE 0 END), 0) AS external_withdrawal_amount,
          COALESCE(SUM(CASE WHEN action = 'settlement' THEN cash_delta ELSE 0 END), 0) AS trade_settlement_cash_flow_amount,
          COALESCE(SUM(CASE WHEN action IN ('transfer_out', 'transfer_in', 'fx_out', 'fx_in') THEN ABS(cash_delta) ELSE 0 END), 0) AS internal_cash_movement_amount,
          COALESCE(SUM(CASE WHEN action = 'buy' THEN gross_amount ELSE 0 END), 0) AS buy_amount,
          COALESCE(SUM(CASE WHEN action = 'sell' THEN gross_amount ELSE 0 END), 0) AS sell_amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
        WHERE tl.deleted_at IS NULL
          $dateWhere
        GROUP BY COALESCE(NULLIF(currency_code, ''), 'KRW')
      ''',
      variables: _ledgerDateVariables(from: from, to: to),
      readsFrom: {transactionEvents, transactionLines},
    ).get();

    return {
      for (final row in rows)
        row.read<String>('currency_code'): LedgerPortfolioPerformanceRecord(
          currencyCode: row.read<String>('currency_code'),
          realizedPnl: row.read<double>('realized_pnl'),
          incomeAmount: row.read<double>('income_amount'),
          feeAmount: row.read<double>('fee_amount'),
          taxAmount: row.read<double>('tax_amount'),
          externalCashFlowAmount: row.read<double>('external_cash_flow_amount'),
          externalDepositAmount: row.read<double>('external_deposit_amount'),
          externalWithdrawalAmount: row.read<double>(
            'external_withdrawal_amount',
          ),
          tradeSettlementCashFlowAmount: row.read<double>(
            'trade_settlement_cash_flow_amount',
          ),
          internalCashMovementAmount: row.read<double>(
            'internal_cash_movement_amount',
          ),
          buyAmount: row.read<double>('buy_amount'),
          sellAmount: row.read<double>('sell_amount'),
        ),
    };
  }

  Future<List<LedgerMonthlyPerformanceRecord>>
  fetchLedgerMonthlyPerformanceByCurrency({
    DateTime? from,
    DateTime? to,
  }) async {
    final dateWhere = _ledgerDateWhereClause(from: from, to: to);
    final rows = await customSelect(
      '''
        SELECT
          SUBSTR(REPLACE(te.occurred_at, '.', '-'), 1, 7) AS month,
          COALESCE(NULLIF(tl.currency_code, ''), 'KRW') AS currency_code,
          COALESCE(SUM(tl.realized_pnl), 0) AS realized_pnl,
          COALESCE(SUM(
            CASE
              WHEN tl.action IN ('dividend', 'interest') THEN
                CASE
                  WHEN ABS(COALESCE(tl.gross_amount, 0)) > 0 THEN ABS(tl.gross_amount)
                  ELSE ABS(COALESCE(tl.cash_delta, 0))
                END
              ELSE 0
            END
          ), 0) AS income_amount,
          COALESCE(SUM(
            CASE
              WHEN tl.action = 'fee' THEN
                CASE
                  WHEN ABS(COALESCE(tl.cash_delta, 0)) > 0 THEN ABS(tl.cash_delta)
                  ELSE ABS(COALESCE(tl.gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS fee_amount,
          COALESCE(SUM(
            CASE
              WHEN tl.action = 'tax' THEN
                CASE
                  WHEN ABS(COALESCE(tl.cash_delta, 0)) > 0 THEN ABS(tl.cash_delta)
                  ELSE ABS(COALESCE(tl.gross_amount, 0))
                END
              ELSE 0
            END
          ), 0) AS tax_amount,
          COALESCE(SUM(CASE WHEN tl.action = 'buy' THEN tl.gross_amount ELSE 0 END), 0) AS buy_amount,
          COALESCE(SUM(CASE WHEN tl.action = 'sell' THEN tl.gross_amount ELSE 0 END), 0) AS sell_amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
          $dateWhere
          AND tl.action IN (
            'sell',
            'dividend',
            'interest',
            'fee',
            'tax'
          )
        GROUP BY
          SUBSTR(REPLACE(te.occurred_at, '.', '-'), 1, 7),
          COALESCE(NULLIF(tl.currency_code, ''), 'KRW')
        ORDER BY month DESC, currency_code ASC
      ''',
      variables: _ledgerDateVariables(from: from, to: to),
      readsFrom: {transactionEvents, transactionLines},
    ).get();

    return rows
        .map(
          (row) => LedgerMonthlyPerformanceRecord(
            month: row.read<String>('month'),
            currencyCode: row.read<String>('currency_code'),
            realizedPnl: row.read<double>('realized_pnl'),
            incomeAmount: row.read<double>('income_amount'),
            feeAmount: row.read<double>('fee_amount'),
            taxAmount: row.read<double>('tax_amount'),
            buyAmount: row.read<double>('buy_amount'),
            sellAmount: row.read<double>('sell_amount'),
          ),
        )
        .toList(growable: false);
  }

  Future<List<LedgerStateParityIssue>> fetchLedgerStateParityIssues({
    double tolerance = 0.000001,
  }) async {
    final holdingRows = await customSelect(
      '''
        SELECT
          h.id AS id,
          h.quantity AS expected_value,
          COALESCE(
            SUM(CASE WHEN te.id IS NULL THEN 0 ELSE tl.quantity_delta END),
            0
          ) AS ledger_value
        FROM holdings h
        LEFT JOIN transaction_lines tl
          ON tl.holding_id = h.id
          AND tl.deleted_at IS NULL
        LEFT JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('history_display', 'record_only')
        WHERE h.deleted_at IS NULL
        GROUP BY h.id
        HAVING ABS(
          h.quantity - COALESCE(
            SUM(CASE WHEN te.id IS NULL THEN 0 ELSE tl.quantity_delta END),
            0
          )
        ) > ?
      ''',
      variables: [Variable.withReal(tolerance)],
      readsFrom: {holdings, transactionEvents, transactionLines},
    ).get();

    final cashRows = await customSelect(
      '''
        SELECT
          ca.id AS id,
          ca.balance AS expected_value,
          ca.base_balance + COALESCE(
            SUM(CASE WHEN te.id IS NULL THEN 0 ELSE tl.cash_delta END),
            0
          ) AS ledger_value
        FROM cash_accounts ca
        LEFT JOIN transaction_lines tl
          ON tl.cash_account_id = ca.id
          AND tl.deleted_at IS NULL
        LEFT JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('history_display', 'record_only')
        WHERE ca.deleted_at IS NULL
        GROUP BY ca.id
        HAVING ABS(
          ca.balance - (
            ca.base_balance + COALESCE(
              SUM(CASE WHEN te.id IS NULL THEN 0 ELSE tl.cash_delta END),
              0
            )
          )
        ) > ?
      ''',
      variables: [Variable.withReal(tolerance)],
      readsFrom: {cashAccounts, transactionEvents, transactionLines},
    ).get();

    return [
      for (final row in holdingRows)
        LedgerStateParityIssue(
          kind: 'holding_quantity',
          id: row.read<int>('id'),
          expectedValue: row.read<double>('expected_value'),
          ledgerValue: row.read<double>('ledger_value'),
        ),
      for (final row in cashRows)
        LedgerStateParityIssue(
          kind: 'cash_balance',
          id: row.read<int>('id'),
          expectedValue: row.read<double>('expected_value'),
          ledgerValue: row.read<double>('ledger_value'),
        ),
    ];
  }

  Future<List<LedgerIncomeTransactionRecord>>
  fetchLedgerIncomeTransactions() async {
    final rows = await customSelect(
      '''
        SELECT
          te.occurred_at AS date,
          tl.action AS action,
          CASE
            WHEN COALESCE(a.alias, '') != '' THEN a.alias
            ELSE COALESCE(a.title, '')
          END AS asset_name,
          COALESCE(h.name, '') AS holding_name,
          COALESCE(h.symbol, '') AS symbol,
          COALESCE(NULLIF(tl.currency_code, ''), h.currency_code, 'KRW') AS currency_code,
          CASE
            WHEN ABS(COALESCE(tl.gross_amount, 0)) > 0 THEN ABS(tl.gross_amount)
            ELSE ABS(COALESCE(tl.cash_delta, 0))
          END AS amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
        LEFT JOIN holdings h
          ON h.id = tl.holding_id
        LEFT JOIN assets a
          ON a.id = COALESCE(tl.asset_id, h.asset_id)
        WHERE tl.deleted_at IS NULL
          AND tl.action IN ('dividend', 'interest')
        ORDER BY te.occurred_at DESC, tl.gross_amount DESC, tl.id DESC
      ''',
      readsFrom: {transactionEvents, transactionLines, holdings, assets},
    ).get();

    return rows
        .map(
          (row) => LedgerIncomeTransactionRecord(
            date: row.read<String>('date'),
            action: row.read<String>('action'),
            assetName: row.read<String>('asset_name'),
            holdingName: row.read<String>('holding_name'),
            symbol: row.read<String>('symbol'),
            currencyCode: row.read<String>('currency_code'),
            amount: row.read<double>('amount'),
          ),
        )
        .toList(growable: false);
  }

  Future<List<LedgerPerformanceEventRecord>> fetchLedgerPerformanceEvents({
    DateTime? from,
    DateTime? to,
    String? action,
    int? holdingId,
  }) async {
    final dateWhere = _ledgerDateWhereClause(from: from, to: to);
    final actionWhere = action == null ? '' : ' AND tl.action = ?';
    final holdingWhere = holdingId == null ? '' : ' AND tl.holding_id = ?';
    final rows = await customSelect(
      '''
        SELECT
          te.id AS event_id,
          tl.id AS line_id,
          te.occurred_at AS date,
          te.kind AS kind,
          tl.action AS action,
          te.title AS title,
          CASE
            WHEN COALESCE(a.alias, '') != '' THEN a.alias
            ELSE COALESCE(a.title, '')
          END AS asset_name,
          COALESCE(h.name, '') AS holding_name,
          COALESCE(ca.name, '') AS cash_account_name,
          COALESCE(NULLIF(tl.currency_code, ''), h.currency_code, ca.currency_code, 'KRW') AS currency_code,
          CASE
            WHEN ABS(COALESCE(tl.realized_pnl, 0)) > 0 THEN tl.realized_pnl
            WHEN ABS(COALESCE(tl.gross_amount, 0)) > 0 THEN tl.gross_amount
            ELSE COALESCE(tl.cash_delta, 0)
          END AS amount
        FROM transaction_lines tl
        INNER JOIN transaction_events te
          ON te.id = tl.event_id
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')
        LEFT JOIN holdings h
          ON h.id = tl.holding_id
        LEFT JOIN cash_accounts ca
          ON ca.id = tl.cash_account_id
        LEFT JOIN assets a
          ON a.id = COALESCE(tl.asset_id, h.asset_id, ca.asset_id)
        WHERE tl.deleted_at IS NULL
          $dateWhere
          $actionWhere
          $holdingWhere
        ORDER BY
          SUBSTR(REPLACE(te.occurred_at, '.', '-'), 1, 10) DESC,
          te.id DESC,
          tl.sort_order ASC,
          tl.id ASC
      ''',
      variables: [
        ..._ledgerDateVariables(from: from, to: to),
        if (action != null) Variable.withString(action),
        if (holdingId != null) Variable.withInt(holdingId),
      ],
      readsFrom: {
        transactionEvents,
        transactionLines,
        holdings,
        cashAccounts,
        assets,
      },
    ).get();

    return rows
        .map(
          (row) => LedgerPerformanceEventRecord(
            eventId: row.read<int>('event_id'),
            lineId: row.read<int>('line_id'),
            date: row.read<String>('date'),
            kind: row.read<String>('kind'),
            action: row.read<String>('action'),
            title: row.read<String>('title'),
            assetName: row.read<String>('asset_name'),
            holdingName: row.read<String>('holding_name'),
            cashAccountName: row.read<String>('cash_account_name'),
            currencyCode: row.read<String>('currency_code'),
            amount: row.read<double>('amount'),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _insertLegacyInvestmentLedger({
    required Map<int, Holding> holdingById,
    required Map<int, CashAccount> cashAccountById,
    required bool markDirty,
    Set<int>? holdingIds,
  }) async {
    final rows =
        await (select(transactions)
              ..where(
                (table) =>
                    table.deletedAt.isNull() &
                    (holdingIds == null
                        ? const Constant(true)
                        : table.holdingId.isIn(holdingIds.toList())),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.holdingId),
                (table) => OrderingTerm.asc(table.date),
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    final quantityByHoldingId = <int, double>{};
    final costByHoldingId = <int, double>{};

    for (final row in rows) {
      final holdingId = row.holdingId;
      final holding = holdingId == null ? null : holdingById[holdingId];
      final normalizedType = _normalizeTransactionType(row.type);
      final eventKind = switch (normalizedType) {
        '초기' => 'opening_balance',
        '매수' || '매도' => 'trade',
        '배당' || '이자' => 'income',
        _ => 'adjustment',
      };
      final timestamp = _syncTimestamp();
      final eventId = await into(transactionEvents).insert(
        TransactionEventsCompanion.insert(
          clientId: Value(_uuid.v4()),
          dirty: Value(markDirty),
          lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
          occurredAt: row.date,
          kind: eventKind,
          title: Value(row.name),
          source: const Value('legacy'),
          flowCategory: const Value(TransactionFlowCategory.internal),
          legacySourceTable: const Value('transactions'),
          legacySourceId: Value(row.id),
          sortOrder: Value(row.sortOrder),
        ),
      );

      final unitPrice = _parseTransactionNumber(row.amount).abs();
      final quantityValue = _parseTransactionNumber(row.quantity).abs();
      final grossAmount = normalizedType == '배당' || normalizedType == '이자'
          ? unitPrice
          : unitPrice * quantityValue;
      final currentQuantity = quantityByHoldingId[holdingId] ?? 0;
      final currentCost = costByHoldingId[holdingId] ?? 0;
      final averageCost = currentQuantity <= 0
          ? 0.0
          : currentCost / currentQuantity;

      var quantityDelta = 0.0;
      var costBasisDelta = 0.0;
      var realizedPnl = 0.0;
      final action = switch (normalizedType) {
        '초기' => 'opening_quantity',
        '매수' => 'buy',
        '매도' => 'sell',
        '배당' => 'dividend',
        '이자' => 'interest',
        _ => 'adjustment',
      };

      switch (normalizedType) {
        case '초기':
        case '매수':
          quantityDelta = quantityValue;
          costBasisDelta = grossAmount;
          quantityByHoldingId[holdingId ?? -1] =
              currentQuantity + quantityDelta;
          costByHoldingId[holdingId ?? -1] = currentCost + costBasisDelta;
          break;
        case '매도':
          final sellQuantity = quantityValue
              .clamp(0.0, currentQuantity)
              .toDouble();
          quantityDelta = -sellQuantity;
          costBasisDelta = -(averageCost * sellQuantity);
          realizedPnl = (unitPrice - averageCost) * sellQuantity;
          final nextQuantity = currentQuantity + quantityDelta;
          quantityByHoldingId[holdingId ?? -1] = nextQuantity <= 0.0000001
              ? 0
              : nextQuantity;
          costByHoldingId[holdingId ?? -1] = nextQuantity <= 0.0000001
              ? 0
              : currentCost + costBasisDelta;
          break;
      }

      await into(transactionLines).insert(
        TransactionLinesCompanion.insert(
          eventId: eventId,
          assetId: Value(row.assetId),
          holdingId: Value(holdingId),
          clientId: Value(_uuid.v4()),
          dirty: Value(markDirty),
          lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
          legacySourceTable: const Value('transactions'),
          legacySourceId: Value(row.id),
          action: action,
          currencyCode: Value(holding?.currencyCode ?? 'KRW'),
          quantityDelta: Value(quantityDelta),
          cashDelta: const Value(0),
          unitPrice: Value(unitPrice),
          grossAmount: Value(grossAmount),
          costBasisDelta: Value(costBasisDelta),
          realizedPnl: Value(realizedPnl),
          sortOrder: const Value(0),
        ),
      );

      final settlementRow = await _findLegacySettlementCashTransaction(row.id);
      if (settlementRow != null) {
        final cashAccount = cashAccountById[settlementRow.cashAccountId];
        await into(transactionLines).insert(
          TransactionLinesCompanion.insert(
            eventId: eventId,
            assetId: Value(settlementRow.assetId),
            cashAccountId: Value(settlementRow.cashAccountId),
            clientId: Value(_uuid.v4()),
            dirty: Value(markDirty),
            lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
            legacySourceTable: const Value('cash_transactions'),
            legacySourceId: Value(settlementRow.id),
            action: 'settlement',
            currencyCode: Value(cashAccount?.currencyCode ?? 'KRW'),
            cashDelta: Value(
              _cashTransactionBalanceDelta(
                type: settlementRow.type,
                amount: settlementRow.amount,
              ),
            ),
            grossAmount: Value(
              _parseTransactionNumber(settlementRow.amount).abs(),
            ),
            sortOrder: const Value(1),
          ),
        );
      }
    }
  }

  Future<CashTransaction?> _findLegacySettlementCashTransaction(
    int transactionId,
  ) async {
    return (select(cashTransactions)
          ..where(
            (table) =>
                (table.linkedTransactionId.equals(-transactionId) |
                    table.linkedTransactionId.equals(transactionId)) &
                table.deletedAt.isNull(),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> _insertLegacyCashLedger({
    required Map<int, CashAccount> cashAccountById,
    required bool markDirty,
  }) async {
    final rows =
        await (select(cashTransactions)
              ..where((table) => table.deletedAt.isNull())
              ..orderBy([
                (table) => OrderingTerm.asc(table.date),
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    final investmentIds = (await select(
      transactions,
    ).get()).map((row) => row.id).toSet();
    final cashTransactionIds = rows.map((row) => row.id).toSet();
    final processedCashIds = <int>{};

    for (final row in rows) {
      if (processedCashIds.contains(row.id)) continue;
      if (_isLegacyInvestmentSettlement(
        row,
        investmentIds,
        cashTransactionIds,
      )) {
        continue;
      }

      final normalizedType = _normalizeTransactionType(row.type);
      CashTransaction? linkedRow;
      if (row.linkedTransactionId != null) {
        for (final candidate in rows) {
          if (candidate.id == row.linkedTransactionId) {
            linkedRow = candidate;
            break;
          }
        }
      }
      if (normalizedType == '입금' && linkedRow != null) {
        final linkedType = _normalizeTransactionType(linkedRow.type);
        if (linkedType == '이체' || linkedType == '환전') {
          continue;
        }
      }
      final isOutgoingPair =
          (normalizedType == '이체' || normalizedType == '환전') &&
          linkedRow != null;
      final eventKind = switch (normalizedType) {
        '이체' => 'cash_transfer',
        '환전' => 'fx_exchange',
        '입금' || '출금' => 'cash_flow',
        _ => 'adjustment',
      };
      final timestamp = _syncTimestamp();
      final eventId = await into(transactionEvents).insert(
        TransactionEventsCompanion.insert(
          clientId: Value(_uuid.v4()),
          dirty: Value(markDirty),
          lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
          occurredAt: row.date,
          kind: eventKind,
          title: Value(row.name),
          source: const Value('legacy'),
          flowCategory: Value(
            isOutgoingPair
                ? TransactionFlowCategory.internal
                : _transactionFlowCategoryForCashType(normalizedType),
          ),
          legacySourceTable: const Value('cash_transactions'),
          legacySourceId: Value(row.id),
          sortOrder: Value(row.sortOrder),
        ),
      );

      await _insertLegacyCashLedgerLine(
        eventId: eventId,
        row: row,
        action: switch (normalizedType) {
          '입금' => isOutgoingPair ? 'transfer_in' : 'deposit',
          '출금' => 'withdrawal',
          '이체' => 'transfer_out',
          '환전' => 'fx_out',
          _ => 'adjustment',
        },
        cashAccountById: cashAccountById,
        sortOrder: 0,
        markDirty: markDirty,
        timestamp: timestamp,
      );
      processedCashIds.add(row.id);

      if (linkedRow != null &&
          !_isLegacyInvestmentSettlement(
            linkedRow,
            investmentIds,
            cashTransactionIds,
          )) {
        await _insertLegacyCashLedgerLine(
          eventId: eventId,
          row: linkedRow,
          action: normalizedType == '환전' ? 'fx_in' : 'transfer_in',
          cashAccountById: cashAccountById,
          sortOrder: 1,
          markDirty: markDirty,
          timestamp: timestamp,
        );
        processedCashIds.add(linkedRow.id);
      }
    }
  }

  bool _isLegacyInvestmentSettlement(
    CashTransaction row,
    Set<int> investmentTransactionIds,
    Set<int> cashTransactionIds,
  ) {
    final linkedId = row.linkedTransactionId;
    if (linkedId == null) return false;
    if (linkedId < 0) {
      return investmentTransactionIds.contains(linkedId.abs());
    }
    if (cashTransactionIds.contains(linkedId)) return false;
    return investmentTransactionIds.contains(linkedId.abs());
  }

  Future<void> _insertLegacyCashLedgerLine({
    required int eventId,
    required CashTransaction row,
    required String action,
    required Map<int, CashAccount> cashAccountById,
    required int sortOrder,
    required bool markDirty,
    required String timestamp,
  }) async {
    final cashAccount = cashAccountById[row.cashAccountId];
    final amountValue = _parseTransactionNumber(row.amount).abs();
    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(row.assetId),
        cashAccountId: Value(row.cashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: Value(markDirty),
        lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
        legacySourceTable: const Value('cash_transactions'),
        legacySourceId: Value(row.id),
        action: action,
        currencyCode: Value(cashAccount?.currencyCode ?? 'KRW'),
        cashDelta: Value(
          _cashTransactionBalanceDelta(type: row.type, amount: row.amount),
        ),
        grossAmount: Value(amountValue),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<void> _insertLedgerForLegacyCashTransaction({
    required int cashTransactionId,
    required bool markDirty,
  }) async {
    final row =
        await (select(cashTransactions)..where(
              (table) =>
                  table.id.equals(cashTransactionId) & table.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) return;

    final cashAccountById = {
      for (final account in await select(cashAccounts).get())
        account.id: account,
    };
    final normalizedType = _normalizeTransactionType(row.type);
    final eventKind = switch (normalizedType) {
      '이체' => 'cash_transfer',
      '환전' => 'fx_exchange',
      '입금' || '출금' => 'cash_flow',
      _ => 'adjustment',
    };
    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: Value(markDirty),
        lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
        occurredAt: row.date,
        kind: eventKind,
        title: Value(row.name),
        source: const Value('legacy'),
        flowCategory: Value(
          _transactionFlowCategoryForCashType(normalizedType),
        ),
        legacySourceTable: const Value('cash_transactions'),
        legacySourceId: Value(row.id),
        sortOrder: Value(row.sortOrder),
      ),
    );

    await _insertLegacyCashLedgerLine(
      eventId: eventId,
      row: row,
      action: switch (normalizedType) {
        '입금' => 'deposit',
        '출금' => 'withdrawal',
        '이체' => 'transfer_out',
        '환전' => 'fx_out',
        _ => 'adjustment',
      },
      cashAccountById: cashAccountById,
      sortOrder: 0,
      markDirty: markDirty,
      timestamp: timestamp,
    );
  }

  Future<void> _insertLedgerForLegacyCashPair({
    required int sourceCashTransactionId,
    required bool markDirty,
  }) async {
    final sourceRow =
        await (select(cashTransactions)..where(
              (table) =>
                  table.id.equals(sourceCashTransactionId) &
                  table.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (sourceRow == null) return;
    final linkedId = sourceRow.linkedTransactionId;
    final linkedRow = linkedId == null
        ? null
        : await (select(cashTransactions)..where(
                (table) => table.id.equals(linkedId) & table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
    if (linkedRow == null) {
      await _insertLedgerForLegacyCashTransaction(
        cashTransactionId: sourceCashTransactionId,
        markDirty: markDirty,
      );
      return;
    }

    final normalizedType = _normalizeTransactionType(sourceRow.type);
    final eventKind = switch (normalizedType) {
      '이체' => 'cash_transfer',
      '환전' => 'fx_exchange',
      _ => 'adjustment',
    };
    final cashAccountById = {
      for (final account in await select(cashAccounts).get())
        account.id: account,
    };
    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: Value(markDirty),
        lastModifiedAt: markDirty ? Value(timestamp) : const Value.absent(),
        occurredAt: sourceRow.date,
        kind: eventKind,
        title: Value(sourceRow.name),
        source: const Value('legacy'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        legacySourceTable: const Value('cash_transactions'),
        legacySourceId: Value(sourceRow.id),
        sortOrder: Value(sourceRow.sortOrder),
      ),
    );

    await _insertLegacyCashLedgerLine(
      eventId: eventId,
      row: sourceRow,
      action: normalizedType == '환전' ? 'fx_out' : 'transfer_out',
      cashAccountById: cashAccountById,
      sortOrder: 0,
      markDirty: markDirty,
      timestamp: timestamp,
    );
    await _insertLegacyCashLedgerLine(
      eventId: eventId,
      row: linkedRow,
      action: normalizedType == '환전' ? 'fx_in' : 'transfer_in',
      cashAccountById: cashAccountById,
      sortOrder: 1,
      markDirty: markDirty,
      timestamp: timestamp,
    );
  }

  Future<int> _createLedgerCashFlowWithLegacyMirror({
    required int assetId,
    required int cashAccountId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required int sortOrder,
  }) async {
    final normalizedType = _normalizeTransactionType(type);
    final cashAccount = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (cashAccount == null) {
      throw StateError('현금 계좌를 찾을 수 없습니다.');
    }
    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: 'cash_flow',
        title: Value(name),
        source: const Value('ledger'),
        flowCategory: Value(
          _transactionFlowCategoryForCashType(normalizedType),
        ),
        sortOrder: Value(sortOrder),
      ),
    );

    final cashDelta = _cashTransactionBalanceDelta(
      type: normalizedType,
      amount: amount,
    );
    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(assetId),
        cashAccountId: Value(cashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: switch (normalizedType) {
          '입금' => 'deposit',
          '출금' => 'withdrawal',
          _ => 'adjustment',
        },
        currencyCode: Value(cashAccount.currencyCode),
        cashDelta: Value(cashDelta),
        grossAmount: Value(_parseTransactionNumber(amount).abs()),
        sortOrder: const Value(0),
      ),
    );

    await _recalculateCashAccountFromLedgerLines(cashAccountId);
    return eventId;
  }

  Future<int> _createRecordOnlyCashFlow({
    required int assetId,
    required int cashAccountId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required int sortOrder,
  }) async {
    final normalizedType = _normalizeTransactionType(type);
    final cashAccount = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (cashAccount == null) {
      throw StateError('현금 계좌를 찾을 수 없습니다.');
    }

    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: 'record_only',
        title: Value(name),
        source: const Value('record_only'),
        flowCategory: Value(
          _transactionFlowCategoryForCashType(normalizedType),
        ),
        sortOrder: Value(sortOrder),
      ),
    );

    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(assetId),
        cashAccountId: Value(cashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: switch (normalizedType) {
          '입금' => 'deposit',
          '출금' => 'withdrawal',
          '이체' => 'transfer_out',
          '환전' => 'fx_out',
          _ => 'adjustment',
        },
        currencyCode: Value(cashAccount.currencyCode),
        cashDelta: const Value(0),
        grossAmount: Value(_parseTransactionNumber(amount).abs()),
        sortOrder: const Value(0),
      ),
    );
    return eventId;
  }

  Future<int> _createLedgerCashTransferWithLegacyMirror({
    required int sourceAssetId,
    required int sourceCashAccountId,
    required int targetCashAccountId,
    required String date,
    required String name,
    required double amount,
    required int sourceSortOrder,
    required int targetSortOrder,
  }) async {
    final sourceAccount =
        await (select(cashAccounts)
              ..where((table) => table.id.equals(sourceCashAccountId)))
            .getSingleOrNull();
    final targetAccount =
        await (select(cashAccounts)
              ..where((table) => table.id.equals(targetCashAccountId)))
            .getSingleOrNull();
    if (sourceAccount == null || targetAccount == null) {
      throw StateError('현금 계좌를 찾을 수 없습니다.');
    }

    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: 'cash_transfer',
        title: Value(name),
        source: const Value('ledger'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        sortOrder: Value(sourceSortOrder),
      ),
    );

    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(sourceAssetId),
        cashAccountId: Value(sourceCashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: 'transfer_out',
        currencyCode: Value(sourceAccount.currencyCode),
        cashDelta: Value(-amount),
        grossAmount: Value(amount),
        sortOrder: const Value(0),
      ),
    );
    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(targetAccount.assetId),
        cashAccountId: Value(targetCashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: 'transfer_in',
        currencyCode: Value(targetAccount.currencyCode),
        cashDelta: Value(amount),
        grossAmount: Value(amount),
        sortOrder: const Value(1),
      ),
    );

    await _recalculateCashAccountFromLedgerLines(sourceCashAccountId);
    await _recalculateCashAccountFromLedgerLines(targetCashAccountId);
    return eventId;
  }

  Future<int> _createLedgerFxExchangeWithLegacyMirror({
    required int sourceAssetId,
    required int sourceCashAccountId,
    required int targetCashAccountId,
    required String date,
    required String name,
    required double sourceAmount,
    required double targetAmount,
    required double exchangeRate,
    required int sourceSortOrder,
    required int targetSortOrder,
  }) async {
    final sourceAccount =
        await (select(cashAccounts)
              ..where((table) => table.id.equals(sourceCashAccountId)))
            .getSingleOrNull();
    final targetAccount =
        await (select(cashAccounts)
              ..where((table) => table.id.equals(targetCashAccountId)))
            .getSingleOrNull();
    if (sourceAccount == null || targetAccount == null) {
      throw StateError('현금 계좌를 찾을 수 없습니다.');
    }

    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: 'fx_exchange',
        title: Value(name),
        source: const Value('ledger'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        sortOrder: Value(sourceSortOrder),
      ),
    );

    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(sourceAssetId),
        cashAccountId: Value(sourceCashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: 'fx_out',
        currencyCode: Value(sourceAccount.currencyCode),
        cashDelta: Value(-sourceAmount),
        grossAmount: Value(sourceAmount),
        fxRate: Value(exchangeRate),
        sortOrder: const Value(0),
      ),
    );
    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(targetAccount.assetId),
        cashAccountId: Value(targetCashAccountId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: 'fx_in',
        currencyCode: Value(targetAccount.currencyCode),
        cashDelta: Value(targetAmount),
        grossAmount: Value(targetAmount),
        fxRate: Value(exchangeRate),
        sortOrder: const Value(1),
      ),
    );

    await _recalculateCashAccountFromLedgerLines(sourceCashAccountId);
    await _recalculateCashAccountFromLedgerLines(targetCashAccountId);
    return eventId;
  }

  Future<int> _createLedgerInvestmentWithLegacyMirror({
    required int assetId,
    required int holdingId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required String quantity,
    required int sortOrder,
  }) async {
    final holding = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holding == null) {
      throw StateError('보유 항목을 찾을 수 없습니다.');
    }

    final normalizedType = _normalizeTransactionType(type);
    final normalizedValues = _normalizedTransactionValues(
      type: normalizedType,
      amount: amount,
      quantity: quantity,
      averageCostBasis: holding.averagePrice,
    );
    final eventKind = switch (normalizedType) {
      '초기' => 'opening_balance',
      '매수' || '매도' => 'trade',
      '배당' || '이자' => 'income',
      _ => 'adjustment',
    };
    final action = switch (normalizedType) {
      '초기' => 'opening_quantity',
      '매수' => 'buy',
      '매도' => 'sell',
      '배당' => 'dividend',
      '이자' => 'interest',
      _ => 'adjustment',
    };
    final quantityDelta = normalizedType == '매도'
        ? -normalizedValues.quantityValue
        : (normalizedType == '초기' || normalizedType == '매수'
              ? normalizedValues.quantityValue
              : 0.0);
    final costBasisDelta = switch (normalizedType) {
      '초기' || '매수' => normalizedValues.grossAmount,
      '매도' =>
        -(normalizedValues.grossAmount - normalizedValues.realizedProfitAmount),
      _ => 0.0,
    };
    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: eventKind,
        title: Value(name),
        source: const Value('ledger'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        sortOrder: Value(sortOrder),
      ),
    );

    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(assetId),
        holdingId: Value(holdingId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: action,
        currencyCode: Value(holding.currencyCode),
        quantityDelta: Value(quantityDelta),
        cashDelta: const Value(0),
        unitPrice: Value(normalizedValues.unitPrice),
        grossAmount: Value(normalizedValues.grossAmount),
        costBasisDelta: Value(costBasisDelta),
        realizedPnl: Value(normalizedValues.realizedProfitAmount),
        sortOrder: const Value(0),
      ),
    );

    if (_shouldSyncHoldingTransactionWithCash(normalizedType)) {
      final cashAccountId = await _ensureSettlementCashAccount(
        assetId: assetId,
        currencyCode: holding.currencyCode,
      );
      final cashAccount = await (select(
        cashAccounts,
      )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
      final settlementAmount = _tradeSettlementAmount(
        amount: amount,
        quantity: quantity,
      );
      final cashDelta = normalizedType == '매수'
          ? -settlementAmount
          : settlementAmount;
      await into(transactionLines).insert(
        TransactionLinesCompanion.insert(
          eventId: eventId,
          assetId: Value(assetId),
          cashAccountId: Value(cashAccountId),
          clientId: Value(_uuid.v4()),
          dirty: const Value(true),
          lastModifiedAt: Value(timestamp),
          action: 'settlement',
          currencyCode: Value(
            cashAccount?.currencyCode ?? holding.currencyCode,
          ),
          cashDelta: Value(cashDelta),
          grossAmount: Value(settlementAmount.abs()),
          sortOrder: const Value(1),
        ),
      );
      await _recalculateCashAccountFromLedgerLines(cashAccountId);
    }

    await _recalculateHoldingFromLedgerLines(holdingId, zeroWhenNoLines: true);
    return eventId;
  }

  Future<int> _createRecordOnlyInvestment({
    required int assetId,
    required int holdingId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required String quantity,
    required int sortOrder,
  }) async {
    final holding = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holding == null) {
      throw StateError('보유 항목을 찾을 수 없습니다.');
    }

    final normalizedType = _normalizeTransactionType(type);
    final normalizedValues = _normalizedTransactionValues(
      type: normalizedType,
      amount: amount,
      quantity: quantity,
      averageCostBasis: holding.averagePrice,
    );
    final action = switch (normalizedType) {
      '초기' => 'opening_quantity',
      '매수' => 'buy',
      '매도' => 'sell',
      '배당' => 'dividend',
      '이자' => 'interest',
      _ => 'adjustment',
    };
    final displayQuantityDelta = switch (normalizedType) {
      '매도' => -normalizedValues.quantityValue,
      '초기' || '매수' => normalizedValues.quantityValue,
      _ => 0.0,
    };
    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: date,
        kind: 'record_only',
        title: Value(name),
        source: const Value('record_only'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        sortOrder: Value(sortOrder),
      ),
    );

    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(assetId),
        holdingId: Value(holdingId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: action,
        currencyCode: Value(holding.currencyCode),
        quantityDelta: Value(displayQuantityDelta),
        cashDelta: const Value(0),
        unitPrice: Value(normalizedValues.unitPrice),
        grossAmount: Value(normalizedValues.grossAmount),
        costBasisDelta: const Value(0),
        realizedPnl: const Value(0),
        sortOrder: const Value(0),
      ),
    );
    return eventId;
  }

  Future<Map<int, List<TransactionItem>>>
  _fetchLedgerInvestmentTransactionsByHoldingId() async {
    final rows = await customSelect(
      '''
        SELECT
          tl.id AS line_id,
          te.id AS event_id,
          te.client_id AS event_client_id,
          tl.id AS ledger_line_id,
          COALESCE(te.kind, 'adjustment') AS ledger_kind,
          COALESCE(te.source, 'manual') AS ledger_source,
          COALESCE(te.flow_category, 'internal') AS flow_category,
          te.legacy_source_id AS legacy_source_id,
          te.legacy_source_table AS event_legacy_source_table,
          tl.legacy_source_table AS line_legacy_source_table,
          tl.legacy_source_id AS line_legacy_source_id,
          tl.asset_id AS asset_id,
          tl.holding_id AS holding_id,
          COALESCE(te.occurred_at, '') AS date,
          COALESCE(tl.action, 'adjustment') AS action,
          COALESCE(te.title, '') AS name,
          COALESCE(tl.unit_price, 0) AS unit_price,
          COALESCE(tl.gross_amount, 0) AS gross_amount,
          ABS(COALESCE(tl.quantity_delta, 0)) AS quantity_value,
          COALESCE((
            SELECT SUM(settlement.cash_delta)
            FROM transaction_lines settlement
            WHERE settlement.event_id = te.id
              AND settlement.deleted_at IS NULL
              AND settlement.action = 'settlement'
          ), COALESCE(tl.cash_delta, 0)) AS cash_flow_amount,
          COALESCE(tl.realized_pnl, 0) AS realized_profit_amount,
          te.sort_order AS event_sort_order,
          tl.sort_order AS line_sort_order
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source != 'snapshot_restore'
          AND tl.holding_id IS NOT NULL
          AND tl.action IN (
            'buy',
            'sell',
            'dividend',
            'interest',
            'fee',
            'tax',
            'adjustment'
          )
        ORDER BY te.sort_order ASC, te.id ASC, tl.sort_order ASC, tl.id ASC
      ''',
      readsFrom: {transactionEvents, transactionLines},
    ).get();

    final result = <int, List<TransactionItem>>{};
    for (final row in rows) {
      final holdingId = row.read<int?>('holding_id');
      if (holdingId == null) continue;
      final action = row.read<String>('action');
      final unitPrice = row.read<double>('unit_price');
      final grossAmount = row.read<double>('gross_amount');
      final quantityValue = row.read<double>('quantity_value');
      final item = TransactionItem(
        id: row.read<int?>('legacy_source_id') ?? row.read<int>('event_id'),
        clientId: row.read<String?>('event_client_id'),
        assetId: row.read<int?>('asset_id'),
        holdingId: holdingId,
        date: row.read<String>('date'),
        type: _ledgerInvestmentActionLabel(action),
        name: row.read<String>('name'),
        amount: _formatPlainNumber(
          _ledgerInvestmentDisplayAmount(
            action: action,
            unitPrice: unitPrice,
            grossAmount: grossAmount,
          ),
        ),
        quantity: _formatPlainNumber(quantityValue),
        unitPrice: unitPrice,
        quantityValue: quantityValue,
        grossAmount: grossAmount,
        cashFlowAmount: row.read<double>('cash_flow_amount'),
        realizedProfitAmount: row.read<double>('realized_profit_amount'),
        ledgerEventId: row.read<int>('event_id'),
        ledgerLineId: row.read<int>('ledger_line_id'),
        ledgerKind: row.read<String>('ledger_kind'),
        ledgerAction: action,
        flowCategory: TransactionFlowCategory.normalize(
          row.read<String?>('flow_category'),
        ),
        legacySourceTable:
            row.read<String?>('line_legacy_source_table') ??
            row.read<String?>('event_legacy_source_table'),
        legacySourceId:
            row.read<int?>('line_legacy_source_id') ??
            row.read<int?>('legacy_source_id'),
        includeInCalculations:
            row.read<String>('ledger_source') != 'record_only',
      );
      result.putIfAbsent(holdingId, () => <TransactionItem>[]).add(item);
    }

    return {
      for (final entry in result.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  Future<Map<int, List<TransactionItem>>>
  _fetchLedgerCashTransactionsByCashAccountId() async {
    final rows = await customSelect(
      '''
        SELECT
          tl.id AS line_id,
          te.id AS event_id,
          te.client_id AS event_client_id,
          tl.id AS ledger_line_id,
          COALESCE(te.kind, 'adjustment') AS ledger_kind,
          COALESCE(te.source, 'manual') AS ledger_source,
          COALESCE(te.flow_category, 'internal') AS flow_category,
          te.legacy_source_table AS event_legacy_source_table,
          te.legacy_source_id AS event_legacy_source_id,
          tl.legacy_source_table AS line_legacy_source_table,
          tl.legacy_source_id AS legacy_source_id,
          COALESCE(tl.asset_id, ca.asset_id) AS asset_id,
          tl.cash_account_id AS cash_account_id,
          COALESCE(te.occurred_at, '') AS date,
          COALESCE(tl.action, 'adjustment') AS action,
          COALESCE(te.title, '') AS name,
          COALESCE(tl.cash_delta, 0) AS cash_delta,
          ABS(COALESCE(tl.cash_delta, 0)) AS amount_value,
          COALESCE(tl.gross_amount, 0) AS gross_amount,
          te.sort_order AS event_sort_order,
          tl.sort_order AS line_sort_order
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        LEFT JOIN cash_accounts ca ON ca.id = tl.cash_account_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source != 'snapshot_restore'
          AND tl.cash_account_id IS NOT NULL
          AND tl.action IN (
            'opening_cash',
            'settlement',
            'deposit',
            'withdrawal',
            'transfer_out',
            'transfer_in',
            'fx_out',
            'fx_in',
            'dividend',
            'interest',
            'fee',
            'tax',
            'adjustment'
          )
        ORDER BY te.sort_order ASC, te.id ASC, tl.sort_order ASC, tl.id ASC
      ''',
      readsFrom: {transactionEvents, transactionLines, cashAccounts},
    ).get();

    final result = <int, List<TransactionItem>>{};
    for (final row in rows) {
      final cashAccountId = row.read<int?>('cash_account_id');
      if (cashAccountId == null) continue;
      final cashDelta = row.read<double>('cash_delta');
      final legacySourceId = row.read<int?>('legacy_source_id');
      final ledgerSource = row.read<String>('ledger_source');
      final item = TransactionItem(
        id: -(legacySourceId ?? row.read<int>('event_id')),
        clientId: row.read<String?>('event_client_id'),
        assetId: row.read<int?>('asset_id'),
        holdingId: -cashAccountId,
        date: row.read<String>('date'),
        type: _ledgerCashActionLabel(
          action: row.read<String>('action'),
          cashDelta: cashDelta,
        ),
        name: row.read<String>('name'),
        amount: _formatPlainNumber(
          ledgerSource == 'record_only'
              ? row.read<double>('gross_amount')
              : cashDelta,
        ),
        quantity: '',
        grossAmount: row.read<double>('amount_value'),
        cashFlowAmount: cashDelta,
        ledgerEventId: row.read<int>('event_id'),
        ledgerLineId: row.read<int>('ledger_line_id'),
        ledgerKind: row.read<String>('ledger_kind'),
        ledgerAction: row.read<String>('action'),
        flowCategory: TransactionFlowCategory.normalize(
          row.read<String?>('flow_category'),
        ),
        legacySourceTable:
            row.read<String?>('line_legacy_source_table') ??
            row.read<String?>('event_legacy_source_table'),
        legacySourceId:
            legacySourceId ?? row.read<int?>('event_legacy_source_id'),
        includeInCalculations: ledgerSource != 'record_only',
      );
      result.putIfAbsent(cashAccountId, () => <TransactionItem>[]).add(item);
    }

    return {
      for (final entry in result.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  Future<List<AssetItem>> fetchAssets() async {
    final usdKrwRate = await fetchLatestExchangeRate() ?? 1.0;
    final assetRows =
        await (select(assets)
              ..where((table) => table.deletedAt.isNull())
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final holdingRows =
        await (select(holdings)
              ..where((table) => table.deletedAt.isNull())
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final ledgerHoldingTransactions =
        await _fetchLedgerInvestmentTransactionsByHoldingId();
    final cashAccountRows =
        await (select(cashAccounts)
              ..where((table) => table.deletedAt.isNull())
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final ledgerCashTransactions =
        await _fetchLedgerCashTransactionsByCashAccountId();

    return assetRows.map((assetRow) {
      final investmentHoldings = holdingRows
          .where((holding) => holding.assetId == assetRow.id)
          .map((holdingRow) {
            final holdingTransactions =
                ledgerHoldingTransactions[holdingRow.id] ??
                const <TransactionItem>[];

            return HoldingItem(
              id: holdingRow.id,
              clientId: holdingRow.clientId,
              assetId: holdingRow.assetId,
              assetTitle: assetRow.alias.isEmpty
                  ? assetRow.title
                  : assetRow.alias,
              assetType: assetRow.assetType,
              isHidden: holdingRow.hidden,
              currencyCode: holdingRow.currencyCode,
              exchangeRate: holdingRow.currencyCode == 'USD' ? usdKrwRate : 1.0,
              marketUpdatedAt: holdingRow.marketUpdatedAt,
              exchangeCode: holdingRow.exchangeCode,
              name: holdingRow.name,
              symbol: holdingRow.symbol,
              quantity: holdingRow.quantity,
              averagePrice: holdingRow.averagePrice,
              currentPrice: holdingRow.currentPrice,
              note: holdingRow.note,
              transactions: holdingTransactions,
            );
          })
          .toList(growable: false);

      final cashHoldings = cashAccountRows
          .where((row) => row.assetId == assetRow.id)
          .map((row) {
            final cashAccountId = row.id;
            final holdingTransactions =
                ledgerCashTransactions[cashAccountId] ??
                const <TransactionItem>[];
            final balance = row.balance;
            final currencyCode = row.currencyCode;
            final cashPurchaseUnitPrice = currencyCode == 'USD'
                ? usdKrwRate
                : 1.0;

            return HoldingItem(
              id: -cashAccountId,
              clientId: row.clientId,
              assetId: row.assetId,
              assetTitle: assetRow.alias.isEmpty
                  ? assetRow.title
                  : assetRow.alias,
              assetType: assetRow.assetType,
              isHidden: row.hidden,
              currencyCode: currencyCode,
              exchangeRate: currencyCode == 'USD' ? usdKrwRate : 1.0,
              marketUpdatedAt: null,
              exchangeCode: '',
              name: row.name,
              symbol: '',
              quantity: balance,
              averagePrice: cashPurchaseUnitPrice,
              currentPrice: 1,
              note: row.note,
              transactions: holdingTransactions,
            );
          })
          .toList(growable: false);

      final assetHoldings = [...investmentHoldings, ...cashHoldings];

      final assetTransactions = const <TransactionItem>[];

      final visibleAssetHoldings = assetHoldings
          .where((holding) => !holding.isHidden)
          .toList(growable: false);
      final valuationAmount = visibleAssetHoldings.fold<double>(
        0,
        (sum, holding) => sum + holding.valuationAmount,
      );
      final purchaseAmount = visibleAssetHoldings.fold<double>(
        0,
        (sum, holding) => sum + holding.purchaseAmount,
      );
      final profitRate = purchaseAmount == 0
          ? 0.0
          : ((valuationAmount - purchaseAmount) / purchaseAmount) * 100;

      return AssetItem(
        id: assetRow.id,
        clientId: assetRow.clientId,
        assetType: assetRow.assetType,
        title: assetRow.title,
        alias: assetRow.alias.isEmpty ? assetRow.title : assetRow.alias,
        isHidden: assetRow.hidden,
        currencyCode: assetRow.currencyCode,
        value: visibleAssetHoldings.isEmpty
            ? assetRow.value
            : MoneyfyDisplayCurrencySettings.formatAmountFromKrw(
                valuationAmount,
              ),
        change: visibleAssetHoldings.isEmpty
            ? assetRow.change
            : _formatPercent(profitRate),
        icon: _materialIconFromCodePoint(assetRow.iconCodePoint),
        quantityLabel: assetRow.quantityLabel,
        quantityValue: visibleAssetHoldings.isEmpty
            ? assetRow.quantityValue
            : '${visibleAssetHoldings.length}개',
        averageLabel: assetRow.averageLabel,
        averageValue: visibleAssetHoldings.isEmpty
            ? assetRow.averageValue
            : _formatPercent(profitRate),
        note: assetRow.note,
        holdings: assetHoldings,
        transactions: assetTransactions,
      );
    }).toList();
  }

  Future<AssetItem?> fetchAssetById(int assetId) async {
    final items = await fetchAssets();
    for (final item in items) {
      if (item.id == assetId) return item;
    }
    return null;
  }

  Future<AssetItem?> fetchAssetByClientId(String clientId) async {
    final normalized = clientId.trim();
    if (normalized.isEmpty) return null;
    final items = await fetchAssets();
    for (final item in items) {
      if ((item.clientId ?? '').trim() == normalized) return item;
    }
    return null;
  }

  Future<void> _refreshAssetSummary(
    int assetId, {
    bool markDirty = true,
  }) async {
    final asset = await fetchAssetById(assetId);
    if (asset == null) return;

    await (update(assets)..where((table) => table.id.equals(assetId))).write(
      AssetsCompanion(
        dirty: markDirty ? const Value(true) : const Value.absent(),
        lastModifiedAt: markDirty
            ? Value(_syncTimestamp())
            : const Value.absent(),
        value: Value(asset.value),
        change: Value(asset.change),
        quantityValue: Value(asset.quantityValue),
        averageValue: Value(asset.averageValue),
      ),
    );
  }

  Future<List<Map<String, Object?>>> fetchCashAccountDebugRows(
    int assetId,
  ) async {
    final rows =
        await (select(cashAccounts)
              ..where(
                (table) =>
                    table.assetId.equals(assetId) & table.deletedAt.isNull(),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    return rows
        .map(
          (row) => <String, Object?>{
            'id': row.id,
            'asset_id': row.assetId,
            'hidden': row.hidden ? 1 : 0,
            'currency_code': row.currencyCode,
            'name': row.name,
            'base_balance': row.baseBalance,
            'balance': row.balance,
            'note': row.note,
            'sort_order': row.sortOrder,
          },
        )
        .toList(growable: false);
  }

  Future<HoldingItem?> fetchHoldingById(int holdingId) async {
    final items = await fetchAssets();
    for (final asset in items) {
      for (final holding in asset.holdings) {
        if (holding.id == holdingId) return holding;
      }
    }
    return null;
  }

  Future<HoldingItem?> fetchHoldingByClientId(String clientId) async {
    final normalized = clientId.trim();
    if (normalized.isEmpty) return null;
    final items = await fetchAssets();
    for (final asset in items) {
      for (final holding in asset.holdings) {
        if ((holding.clientId ?? '').trim() == normalized) return holding;
      }
    }
    return null;
  }

  Future<int> createAsset({
    required String assetType,
    required String title,
    required String alias,
    required bool hidden,
    required String currencyCode,
    required String value,
    required String change,
    required IconData icon,
    required String quantityLabel,
    required String quantityValue,
    required String averageLabel,
    required String averageValue,
    required String note,
  }) async {
    final maxQuery = selectOnly(assets)..addColumns([assets.sortOrder.max()]);
    final currentMax =
        (await maxQuery.getSingleOrNull())?.read(assets.sortOrder.max()) ?? -1;

    final insertedId = await into(assets).insert(
      AssetsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        assetType: Value(assetType),
        title: title,
        alias: Value(alias),
        hidden: Value(hidden),
        currencyCode: Value(currencyCode),
        value: value,
        change: change,
        iconCodePoint: icon.codePoint,
        quantityLabel: quantityLabel,
        quantityValue: quantityValue,
        averageLabel: averageLabel,
        averageValue: averageValue,
        note: note,
        sortOrder: currentMax + 1,
      ),
    );
    await refreshTodaySnapshot();
    return insertedId;
  }

  Future<void> updateAssetItem(AssetItem item) async {
    if (item.id == null) return;

    await (update(assets)..where((table) => table.id.equals(item.id!))).write(
      AssetsCompanion(
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        assetType: Value(item.assetType),
        title: Value(item.title),
        alias: Value(item.alias),
        hidden: Value(item.isHidden),
        currencyCode: Value(item.currencyCode),
        value: Value(item.value),
        change: Value(item.change),
        iconCodePoint: Value(item.icon.codePoint),
        quantityLabel: Value(item.quantityLabel),
        quantityValue: Value(item.quantityValue),
        averageLabel: Value(item.averageLabel),
        averageValue: Value(item.averageValue),
        note: Value(item.note),
      ),
    );
    await refreshTodaySnapshot();
  }

  Future<void> reorderAssets(List<int> assetIds) async {
    await transaction(() async {
      for (var index = 0; index < assetIds.length; index++) {
        await (update(
          assets,
        )..where((table) => table.id.equals(assetIds[index]))).write(
          AssetsCompanion(
            sortOrder: Value(index),
            dirty: const Value(true),
            lastModifiedAt: Value(_syncTimestamp()),
          ),
        );
      }
    });
    await refreshTodaySnapshot();
  }

  Future<void> deleteAssetItem(int assetId) async {
    await transaction(() async {
      final assetHoldingRows =
          await (select(holdings)..where(
                (table) =>
                    table.assetId.equals(assetId) & table.deletedAt.isNull(),
              ))
              .get();
      final holdingIds = assetHoldingRows.map((row) => row.id).toList();
      final cashAccountRows =
          await (select(cashAccounts)..where(
                (table) =>
                    table.assetId.equals(assetId) & table.deletedAt.isNull(),
              ))
              .get();
      final cashAccountIds = cashAccountRows
          .map((row) => row.id)
          .toList(growable: false);

      if (holdingIds.isNotEmpty) {
        final linkedTransactionRows =
            await (select(transactions)..where(
                  (table) =>
                      table.holdingId.isIn(holdingIds) &
                      table.deletedAt.isNull(),
                ))
                .get();
        await _softDeleteByIds(
          'transactions',
          linkedTransactionRows.map((row) => row.id).toList(growable: false),
        );
      }
      if (cashAccountIds.isNotEmpty) {
        final linkedCashTransactionRows =
            await (select(cashTransactions)..where(
                  (table) =>
                      table.cashAccountId.isIn(cashAccountIds) &
                      table.deletedAt.isNull(),
                ))
                .get();
        await _softDeleteByIds(
          'cash_transactions',
          linkedCashTransactionRows
              .map((row) => row.id)
              .toList(growable: false),
        );
        await _softDeleteByIds('cash_accounts', cashAccountIds);
      }

      final assetTransactionRows =
          await (select(transactions)..where(
                (table) =>
                    table.assetId.equals(assetId) & table.deletedAt.isNull(),
              ))
              .get();
      await _softDeleteByIds(
        'transactions',
        assetTransactionRows.map((row) => row.id).toList(growable: false),
      );
      await _softDeleteByIds('holdings', holdingIds);
      await _softDeleteByIds('assets', [assetId]);
    });
    await refreshTodaySnapshot();
  }

  Future<void> updateAssetHidden(int assetId, bool isHidden) async {
    await (update(assets)..where((table) => table.id.equals(assetId))).write(
      AssetsCompanion(hidden: Value(isHidden)),
    );
    await refreshTodaySnapshot();
  }

  Future<int> createHolding({
    required int assetId,
    required String currencyCode,
    required String exchangeCode,
    required String name,
    required String symbol,
    required double quantity,
    required double averagePrice,
    required double currentPrice,
    required String note,
  }) async {
    final assetRow = await (select(
      assets,
    )..where((table) => table.id.equals(assetId))).getSingleOrNull();
    if (assetRow?.assetType == '현금') {
      final balance =
          (quantity != 0
                  ? quantity
                  : (currentPrice != 0
                        ? currentPrice
                        : (averagePrice != 0 ? averagePrice : 0.0)))
              .toDouble();
      return createCashAccount(
        assetId: assetId,
        currencyCode: currencyCode,
        name: name,
        note: note,
        balance: balance,
      );
    }

    final maxQuery = selectOnly(holdings)
      ..addColumns([holdings.sortOrder.max()])
      ..where(holdings.assetId.equals(assetId) & holdings.deletedAt.isNull());
    final currentMax =
        (await maxQuery.getSingleOrNull())?.read(holdings.sortOrder.max()) ??
        -1;

    final insertedId = await into(holdings).insert(
      HoldingsCompanion.insert(
        assetId: assetId,
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        currencyCode: Value(currencyCode),
        marketUpdatedAt: const Value.absent(),
        exchangeCode: Value(exchangeCode),
        name: name,
        symbol: symbol,
        quantity: quantity,
        averagePrice: averagePrice,
        currentPrice: currentPrice,
        note: note,
        sortOrder: currentMax + 1,
      ),
    );
    await refreshTodaySnapshot();
    return insertedId;
  }

  Future<int> createCashAccount({
    required int assetId,
    required String currencyCode,
    required String name,
    required String note,
    double balance = 0,
  }) async {
    final maxQuery = selectOnly(cashAccounts)
      ..addColumns([cashAccounts.sortOrder.max()])
      ..where(
        cashAccounts.assetId.equals(assetId) & cashAccounts.deletedAt.isNull(),
      );
    final currentMax =
        (await maxQuery.getSingleOrNull())?.read(
          cashAccounts.sortOrder.max(),
        ) ??
        -1;

    final inserted = await into(cashAccounts).insert(
      CashAccountsCompanion.insert(
        assetId: assetId,
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        currencyCode: Value(currencyCode),
        name: name,
        baseBalance: Value(balance),
        balance: Value(balance),
        note: Value(note),
        hidden: const Value(false),
        sortOrder: Value(currentMax + 1),
      ),
    );
    await refreshTodaySnapshot();
    return -inserted;
  }

  Future<int> _insertCashAccount({
    required int assetId,
    required String currencyCode,
    required String name,
    required String note,
    required double balance,
  }) async {
    final maxQuery = selectOnly(cashAccounts)
      ..addColumns([cashAccounts.sortOrder.max()])
      ..where(
        cashAccounts.assetId.equals(assetId) & cashAccounts.deletedAt.isNull(),
      );
    final currentMax =
        (await maxQuery.getSingleOrNull())?.read(
          cashAccounts.sortOrder.max(),
        ) ??
        -1;

    return into(cashAccounts).insert(
      CashAccountsCompanion.insert(
        assetId: assetId,
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        currencyCode: Value(currencyCode),
        name: name,
        baseBalance: Value(balance),
        balance: Value(balance),
        note: Value(note),
        hidden: const Value(false),
        sortOrder: Value(currentMax + 1),
      ),
    );
  }

  Future<int> _ensureSettlementCashAccount({
    required int assetId,
    required String currencyCode,
  }) async {
    final existing =
        await (select(cashAccounts)
              ..where(
                (table) =>
                    table.assetId.equals(assetId) &
                    table.currencyCode.equals(currencyCode) &
                    table.deletedAt.isNull(),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    return _insertCashAccount(
      assetId: assetId,
      currencyCode: currencyCode,
      name: '$currencyCode 현금 계좌',
      note: '',
      balance: 0,
    );
  }

  Future<double> _cashAccountBalanceExcluding({
    required int cashAccountId,
    Set<int> excludedTransactionIds = const {},
  }) async {
    final account = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (account == null) {
      throw StateError('현금 계좌를 찾을 수 없습니다.');
    }
    if (excludedTransactionIds.isEmpty) {
      return account.balance;
    }

    final rows =
        await (select(cashTransactions)..where(
              (table) =>
                  table.cashAccountId.equals(cashAccountId) &
                  table.deletedAt.isNull(),
            ))
            .get();

    return rows.fold<double>(account.baseBalance, (balance, row) {
      if (excludedTransactionIds.contains(row.id)) return balance;
      return balance +
          _cashTransactionBalanceDelta(type: row.type, amount: row.amount);
    });
  }

  Future<void> _ensureSufficientCashBalance({
    required int cashAccountId,
    required String type,
    required String amount,
    Set<int> excludedTransactionIds = const {},
  }) async {
    final requiredAmount = _cashOutgoingAmount(type: type, amount: amount);
    if (requiredAmount <= 0) return;

    final availableBalance = await _cashAccountBalanceExcluding(
      cashAccountId: cashAccountId,
      excludedTransactionIds: excludedTransactionIds,
    );
    if (availableBalance + 0.0000001 < requiredAmount) {
      throw StateError(
        '현금 잔액이 부족합니다. 필요 ${_formatPlainNumber(requiredAmount)} / 보유 ${_formatPlainNumber(availableBalance)}',
      );
    }
  }

  Future<void> _ensureSufficientHoldingQuantityForSell({
    required int holdingId,
    required String type,
    required String quantity,
    int? editingAssetTransactionId,
  }) async {
    final normalizedType = _normalizeTransactionType(type);
    if (normalizedType != '매도') return;

    final sellQuantity = _parseTransactionNumber(quantity).abs();
    if (sellQuantity <= 0) {
      throw StateError('매도 수량이 0보다 커야 합니다.');
    }

    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null) {
      throw StateError('보유 종목 정보를 찾을 수 없습니다.');
    }

    var availableQuantity = holdingRow.quantity;

    // When editing, holding.quantity already includes the old transaction.
    // Restore that old effect before validating the replacement sell.
    if (editingAssetTransactionId != null) {
      final existing =
          await (select(transactions)..where(
                (table) =>
                    table.id.equals(editingAssetTransactionId) &
                    table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (existing != null) {
        final existingQuantity = _parseTransactionNumber(
          existing.quantity,
        ).abs();
        switch (_normalizeTransactionType(existing.type)) {
          case '초기':
          case '매수':
          case '입금':
            availableQuantity -= existingQuantity;
            break;
          case '매도':
          case '출금':
            availableQuantity += existingQuantity;
            break;
        }
      }
    }

    if (availableQuantity < 0.0000001) {
      availableQuantity = 0;
    }

    if (sellQuantity > availableQuantity + 0.0000001) {
      throw StateError(
        '매도 수량이 보유 수량보다 많습니다. 매도 ${_formatPlainNumber(sellQuantity)} / 보유 ${_formatPlainNumber(availableQuantity)}',
      );
    }
  }

  Future<void> _ensureSufficientSettlementCashForBuy({
    required int assetId,
    required int holdingId,
    required String type,
    required String amount,
    required String quantity,
    int? editingAssetTransactionId,
  }) async {
    final normalizedType = _normalizeTransactionType(type);
    if (normalizedType != '매수') return;

    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null) {
      throw StateError('보유 종목 정보를 찾을 수 없습니다.');
    }

    final cashAccountId = await _ensureSettlementCashAccount(
      assetId: assetId,
      currencyCode: holdingRow.currencyCode,
    );
    final cashAccountRow = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (cashAccountRow == null) {
      throw StateError('결제 현금 계좌를 찾을 수 없습니다.');
    }

    var availableBalance = cashAccountRow.balance;

    // Editing an existing trade: restore the previous linked cash effect
    // before checking affordability of the new buy amount.
    if (editingAssetTransactionId != null) {
      final linkedTransactionKey = -editingAssetTransactionId;
      final linked =
          await (select(cashTransactions)
                ..where(
                  (table) =>
                      (table.linkedTransactionId.equals(linkedTransactionKey) |
                          table.linkedTransactionId.equals(
                            editingAssetTransactionId,
                          )) &
                      table.deletedAt.isNull() &
                      table.type.isIn(const ['매수', '매도', '입금', '출금']),
                )
                ..limit(1))
              .getSingleOrNull();
      if (linked != null) {
        final linkedAmount = _parseTransactionNumber(linked.amount).abs();
        switch (_normalizeTransactionType(linked.type)) {
          case '출금':
          case '매수':
            availableBalance += linkedAmount;
            break;
          case '입금':
          case '매도':
            availableBalance -= linkedAmount;
            break;
        }
      }
    }

    final requiredAmount = _tradeSettlementAmount(
      amount: amount,
      quantity: quantity,
    );
    if (requiredAmount <= 0) {
      throw StateError('매수 총액이 0보다 커야 합니다.');
    }
    if (availableBalance + 0.0000001 < requiredAmount) {
      throw StateError(
        '매수 가능 현금이 부족합니다. 필요 ${_formatPlainNumber(requiredAmount)} / 보유 ${_formatPlainNumber(availableBalance)}',
      );
    }
  }

  Future<int> _nextCashTransactionSortOrder(int cashAccountId) async {
    final maxQuery = selectOnly(cashTransactions)
      ..addColumns([cashTransactions.sortOrder.max()])
      ..where(
        cashTransactions.cashAccountId.equals(cashAccountId) &
            cashTransactions.deletedAt.isNull(),
      );
    return ((await maxQuery.getSingleOrNull())?.read(
              cashTransactions.sortOrder.max(),
            ) ??
            -1) +
        1;
  }

  Future<int?> _upsertLinkedCashTransactionForHoldingTrade({
    required int assetTransactionId,
    required int assetId,
    required int holdingId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required String quantity,
  }) async {
    final normalizedType = _normalizeTransactionType(type);
    if (!_shouldSyncHoldingTransactionWithCash(normalizedType)) return null;

    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null) return null;

    final cashAccountId = await _ensureSettlementCashAccount(
      assetId: assetId,
      currencyCode: holdingRow.currencyCode,
    );
    final linkedTransactionKey = -assetTransactionId;
    final normalizedAmount = _formatPlainNumber(
      _tradeSettlementAmount(amount: amount, quantity: quantity),
    );
    final cashTransactionType = normalizedType == '매수' ? '출금' : '입금';
    final existing =
        await (select(cashTransactions)
              ..where(
                (table) =>
                    (table.linkedTransactionId.equals(linkedTransactionKey) |
                        table.linkedTransactionId.equals(assetTransactionId)) &
                    table.type.isIn(const ['매수', '매도', '입금', '출금']),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      final insertedId = await into(cashTransactions).insert(
        CashTransactionsCompanion.insert(
          assetId: assetId,
          cashAccountId: cashAccountId,
          clientId: Value(_uuid.v4()),
          dirty: const Value(true),
          lastModifiedAt: Value(_syncTimestamp()),
          linkedTransactionId: Value(linkedTransactionKey),
          date: date,
          type: cashTransactionType,
          name: name,
          amount: normalizedAmount,
          sortOrder: Value(await _nextCashTransactionSortOrder(cashAccountId)),
        ),
      );
      await _recalculateCashAccountFromTransactions(cashAccountId);
      return insertedId;
    }

    final previousCashAccountId = existing.cashAccountId;
    var nextSortOrder = existing.sortOrder;
    if (previousCashAccountId != cashAccountId) {
      nextSortOrder = await _nextCashTransactionSortOrder(cashAccountId);
    }

    await (update(
      cashTransactions,
    )..where((table) => table.id.equals(existing.id))).write(
      CashTransactionsCompanion(
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        assetId: Value(assetId),
        cashAccountId: Value(cashAccountId),
        linkedTransactionId: Value(linkedTransactionKey),
        date: Value(date),
        type: Value(cashTransactionType),
        name: Value(name),
        amount: Value(normalizedAmount),
        sortOrder: Value(nextSortOrder),
      ),
    );
    if (previousCashAccountId != cashAccountId) {
      await _recalculateCashAccountFromTransactions(previousCashAccountId);
    }
    await _recalculateCashAccountFromTransactions(cashAccountId);
    return existing.id;
  }

  Future<void> _ensureHoldingOpeningLedgerLine(int holdingId) async {
    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null || holdingRow.quantity <= 0) return;

    final existing = await customSelect(
      '''
        SELECT COUNT(*) AS count
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('history_display', 'record_only')
          AND tl.holding_id = ?
          AND ABS(tl.quantity_delta) > 0.0000001
      ''',
      variables: [Variable.withInt(holdingId)],
      readsFrom: {transactionEvents, transactionLines},
    ).getSingle();
    if (existing.read<int>('count') > 0) return;

    final timestamp = _syncTimestamp();
    final eventId = await into(transactionEvents).insert(
      TransactionEventsCompanion.insert(
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        occurredAt: '1900-01-01',
        kind: 'opening_balance',
        title: Value(holdingRow.name),
        source: const Value('ledger'),
        flowCategory: const Value(TransactionFlowCategory.internal),
        sortOrder: const Value(0),
      ),
    );
    await into(transactionLines).insert(
      TransactionLinesCompanion.insert(
        eventId: eventId,
        assetId: Value(holdingRow.assetId),
        holdingId: Value(holdingId),
        clientId: Value(_uuid.v4()),
        dirty: const Value(true),
        lastModifiedAt: Value(timestamp),
        action: 'opening_quantity',
        currencyCode: Value(holdingRow.currencyCode),
        quantityDelta: Value(holdingRow.quantity),
        unitPrice: Value(holdingRow.averagePrice),
        grossAmount: Value(holdingRow.quantity * holdingRow.averagePrice),
        costBasisDelta: Value(holdingRow.quantity * holdingRow.averagePrice),
      ),
    );
  }

  Future<void> _deleteLinkedCashTransactionForHoldingTrade(
    int assetTransactionId,
  ) async {
    final linkedTransactionKey = -assetTransactionId;
    final linked =
        await (select(cashTransactions)
              ..where(
                (table) =>
                    (table.linkedTransactionId.equals(linkedTransactionKey) |
                        table.linkedTransactionId.equals(assetTransactionId)) &
                    table.deletedAt.isNull() &
                    table.type.isIn(const ['매수', '매도', '입금', '출금']),
              )
              ..limit(1))
            .getSingleOrNull();
    if (linked == null) return;

    await _softDeleteByIds('cash_transactions', [linked.id]);
    await _recalculateCashAccountFromTransactions(linked.cashAccountId);
  }

  Future<void> updateHoldingItem(HoldingItem item) async {
    if (item.id == null) return;

    if (item.id! < 0 || item.assetType == '현금') {
      final cashAccountId = item.id!.abs();
      final ledgerRow = await customSelect(
        '''
          SELECT COALESCE(SUM(tl.cash_delta), 0) AS cash_delta
          FROM transaction_lines tl
          INNER JOIN transaction_events te ON te.id = tl.event_id
          WHERE tl.deleted_at IS NULL
            AND te.deleted_at IS NULL
            AND te.source NOT IN ('history_display', 'record_only')
            AND tl.cash_account_id = ?
        ''',
        variables: [Variable.withInt(cashAccountId)],
        readsFrom: {transactionEvents, transactionLines},
      ).getSingle();
      final transactionDelta = ledgerRow.read<double>('cash_delta');
      final baseBalance = item.quantity - transactionDelta;
      await (update(
        cashAccounts,
      )..where((table) => table.id.equals(cashAccountId))).write(
        CashAccountsCompanion(
          dirty: const Value(true),
          lastModifiedAt: Value(_syncTimestamp()),
          currencyCode: Value(item.currencyCode),
          hidden: Value(item.isHidden),
          name: Value(item.name),
          baseBalance: Value(baseBalance),
          balance: Value(item.quantity),
          note: Value(item.note),
        ),
      );
      await refreshTodaySnapshot();
      return;
    }

    await (update(holdings)..where((table) => table.id.equals(item.id!))).write(
      HoldingsCompanion(
        dirty: const Value(true),
        lastModifiedAt: Value(_syncTimestamp()),
        currencyCode: Value(item.currencyCode),
        marketUpdatedAt: Value(item.marketUpdatedAt),
        exchangeCode: Value(item.exchangeCode),
        hidden: Value(item.isHidden),
        name: Value(item.name),
        symbol: Value(item.symbol),
        quantity: Value(item.quantity),
        averagePrice: Value(item.averagePrice),
        currentPrice: Value(item.currentPrice),
        note: Value(item.note),
      ),
    );
    await refreshTodaySnapshot();
  }

  Future<void> updateHoldingCurrentPrice(
    int holdingId,
    double currentPrice,
  ) async {
    if (holdingId < 0) return;
    final existing = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (existing == null) return;
    final nowIso = DateTime.now().toIso8601String();
    if ((existing.currentPrice - currentPrice).abs() < 0.000001) {
      await (update(holdings)..where((table) => table.id.equals(holdingId)))
          .write(HoldingsCompanion(marketUpdatedAt: Value(nowIso)));
      await refreshTodaySnapshot();
      return;
    }

    await (update(
      holdings,
    )..where((table) => table.id.equals(holdingId))).write(
      HoldingsCompanion(
        currentPrice: Value(currentPrice),
        marketUpdatedAt: Value(nowIso),
      ),
    );
    await refreshTodaySnapshot();
  }

  Future<void> updateHoldingHidden(int holdingId, bool isHidden) async {
    if (holdingId < 0) {
      await (update(cashAccounts)
            ..where((table) => table.id.equals(holdingId.abs())))
          .write(CashAccountsCompanion(hidden: Value(isHidden)));
      await refreshTodaySnapshot();
      return;
    }
    await (update(holdings)..where((table) => table.id.equals(holdingId)))
        .write(HoldingsCompanion(hidden: Value(isHidden)));
    await refreshTodaySnapshot();
  }

  Future<void> deleteHoldingItem(int holdingId) async {
    if (holdingId < 0) {
      await transaction(() async {
        final cashTransactionRows =
            await (select(cashTransactions)..where(
                  (table) =>
                      table.cashAccountId.equals(holdingId.abs()) &
                      table.deletedAt.isNull(),
                ))
                .get();
        await _softDeleteByIds(
          'cash_transactions',
          cashTransactionRows.map((row) => row.id).toList(growable: false),
        );
        await _softDeleteByIds('cash_accounts', [holdingId.abs()]);
      });
      await refreshTodaySnapshot();
      return;
    }
    await transaction(() async {
      final transactionRows =
          await (select(transactions)..where(
                (table) =>
                    table.holdingId.equals(holdingId) &
                    table.deletedAt.isNull(),
              ))
              .get();
      await _softDeleteByIds(
        'transactions',
        transactionRows.map((row) => row.id).toList(growable: false),
      );
      await _softDeleteByIds('holdings', [holdingId]);
    });
    await refreshTodaySnapshot();
  }

  Future<void> reorderHoldings({
    required int assetId,
    required List<int> holdingIds,
  }) async {
    final assetRow = await (select(
      assets,
    )..where((table) => table.id.equals(assetId))).getSingleOrNull();
    if (assetRow?.assetType == '현금') {
      await transaction(() async {
        for (var index = 0; index < holdingIds.length; index++) {
          await (update(cashAccounts)..where(
                (table) =>
                    table.assetId.equals(assetId) &
                    table.id.equals(holdingIds[index].abs()),
              ))
              .write(
                CashAccountsCompanion(
                  sortOrder: Value(index),
                  dirty: const Value(true),
                  lastModifiedAt: Value(_syncTimestamp()),
                ),
              );
        }
      });
      await refreshTodaySnapshot();
      return;
    }
    await transaction(() async {
      for (var index = 0; index < holdingIds.length; index++) {
        await (update(holdings)..where(
              (table) =>
                  table.assetId.equals(assetId) &
                  table.id.equals(holdingIds[index]),
            ))
            .write(
              HoldingsCompanion(
                sortOrder: Value(index),
                dirty: const Value(true),
                lastModifiedAt: Value(_syncTimestamp()),
              ),
            );
      }
    });
    await refreshTodaySnapshot();
  }

  Future<void> reorderCashAccounts({
    required int assetId,
    required List<int> cashAccountIds,
  }) async {
    await transaction(() async {
      for (var index = 0; index < cashAccountIds.length; index++) {
        await (update(cashAccounts)..where(
              (table) =>
                  table.assetId.equals(assetId) &
                  table.id.equals(cashAccountIds[index].abs()),
            ))
            .write(
              CashAccountsCompanion(
                sortOrder: Value(index),
                dirty: const Value(true),
                lastModifiedAt: Value(_syncTimestamp()),
              ),
            );
      }
    });
    await refreshTodaySnapshot();
  }

  Future<int?> fetchLinkedCashTransferCounterpartyHoldingId(
    int transactionId,
  ) async {
    final eventId = transactionId.abs();
    final ledgerRows = await customSelect(
      '''
        SELECT cash_account_id
        FROM transaction_lines
        WHERE event_id = ?
          AND deleted_at IS NULL
          AND action IN ('transfer_out', 'transfer_in')
          AND cash_account_id IS NOT NULL
        ORDER BY sort_order ASC, id ASC
      ''',
      variables: [Variable.withInt(eventId)],
      readsFrom: {transactionLines},
    ).get();
    if (ledgerRows.length >= 2) {
      final sourceCashAccountId = ledgerRows.first.read<int>('cash_account_id');
      final other = ledgerRows
          .map((row) => row.read<int>('cash_account_id'))
          .firstWhere(
            (cashAccountId) => cashAccountId != sourceCashAccountId,
            orElse: () => sourceCashAccountId,
          );
      return -other;
    }

    final row = await (select(
      cashTransactions,
    )..where((table) => table.id.equals(transactionId))).getSingleOrNull();
    if (row?.linkedTransactionId == null) return null;

    final linkedRow =
        await (select(cashTransactions)
              ..where((table) => table.id.equals(row!.linkedTransactionId!)))
            .getSingleOrNull();
    if (linkedRow == null) return null;
    return -linkedRow.cashAccountId;
  }

  Future<double?> fetchLinkedCashExchangeRate(int transactionId) async {
    final eventId = transactionId.abs();
    final ledgerRows = await customSelect(
      '''
        SELECT action, fx_rate
        FROM transaction_lines
        WHERE event_id = ?
          AND deleted_at IS NULL
          AND action IN ('fx_out', 'fx_in')
        ORDER BY sort_order ASC, id ASC
      ''',
      variables: [Variable.withInt(eventId)],
      readsFrom: {transactionLines},
    ).get();
    double? ledgerRate;
    for (final row in ledgerRows) {
      final value = row.read<double?>('fx_rate');
      if (value != null && value > 0) {
        ledgerRate = value;
        break;
      }
    }
    if (ledgerRate != null) return ledgerRate;

    final maybeRow = await (select(
      cashTransactions,
    )..where((table) => table.id.equals(transactionId))).getSingleOrNull();
    if (maybeRow?.linkedTransactionId == null) return null;
    final row = maybeRow!;

    final linkedRow =
        await (select(cashTransactions)
              ..where((table) => table.id.equals(row.linkedTransactionId!)))
            .getSingleOrNull();
    if (linkedRow == null) return null;

    final sourceAccount = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(row.cashAccountId))).getSingleOrNull();
    if (sourceAccount == null) return null;

    final sourceAmount = _parseTransactionNumber(row.amount).abs();
    final targetAmount = _parseTransactionNumber(linkedRow.amount).abs();
    if (sourceAmount <= 0 || targetAmount <= 0) return null;

    return sourceAccount.currencyCode == 'KRW'
        ? sourceAmount / targetAmount
        : targetAmount / sourceAmount;
  }

  Future<int> createCashTransfer({
    required int assetId,
    required int sourceHoldingId,
    required int targetHoldingId,
    required String date,
    required String name,
    required String amount,
  }) async {
    final sourceCashAccountId = sourceHoldingId.abs();
    final targetCashAccountId = targetHoldingId.abs();
    if (sourceCashAccountId == targetCashAccountId) {
      throw StateError('같은 현금 계좌로는 이체할 수 없습니다.');
    }
    final parsedAmount = _parseTransactionNumber(amount).abs();
    if (parsedAmount <= 0) {
      throw StateError('이체 금액은 0보다 커야 합니다.');
    }
    final formattedNegativeAmount = _formatPlainNumber(-parsedAmount);
    final normalizedDate = _normalizeStoredDateKey(date);

    await _ensureSufficientCashBalance(
      cashAccountId: sourceCashAccountId,
      type: '이체',
      amount: formattedNegativeAmount,
    );
    final targetAccount =
        await (select(cashAccounts)..where(
              (table) =>
                  table.id.equals(targetCashAccountId) &
                  table.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (targetAccount == null) {
      throw StateError('이체 대상 현금 계좌를 찾을 수 없습니다.');
    }

    final sourceSortQuery = selectOnly(transactionEvents)
      ..addColumns([transactionEvents.sortOrder.max()])
      ..where(transactionEvents.deletedAt.isNull());
    final sourceMax =
        (await sourceSortQuery.getSingleOrNull())?.read(
          transactionEvents.sortOrder.max(),
        ) ??
        -1;
    final targetMax = sourceMax;

    late final int sourceTransactionId;
    await transaction(() async {
      sourceTransactionId = await _createLedgerCashTransferWithLegacyMirror(
        sourceAssetId: assetId,
        sourceCashAccountId: sourceCashAccountId,
        targetCashAccountId: targetCashAccountId,
        date: normalizedDate,
        name: name,
        amount: parsedAmount,
        sourceSortOrder: sourceMax + 1,
        targetSortOrder: targetMax + 1,
      );
    });
    await refreshTodaySnapshot();
    return -sourceTransactionId;
  }

  Future<int> createCashExchange({
    required int assetId,
    required int sourceHoldingId,
    required String date,
    required String name,
    required String amount,
    required double exchangeRate,
  }) async {
    final sourceCashAccountId = sourceHoldingId.abs();
    final sourceAccount =
        await (select(cashAccounts)
              ..where((table) => table.id.equals(sourceCashAccountId)))
            .getSingleOrNull();
    if (sourceAccount == null) {
      throw StateError('원본 현금 계좌를 찾을 수 없습니다.');
    }

    final sourceCurrency = sourceAccount.currencyCode;
    final targetCurrency = switch (sourceCurrency) {
      'KRW' => 'USD',
      'USD' => 'KRW',
      _ => throw StateError('지원하지 않는 통화입니다: $sourceCurrency'),
    };

    if (exchangeRate <= 0) {
      throw StateError('환율은 0보다 커야 합니다.');
    }

    final sourceAmount = _parseTransactionNumber(amount).abs();
    if (sourceAmount <= 0) {
      throw StateError('환전 금액은 0보다 커야 합니다.');
    }
    final targetAmount = sourceCurrency == 'KRW'
        ? sourceAmount / exchangeRate
        : sourceAmount * exchangeRate;

    await _ensureSufficientCashBalance(
      cashAccountId: sourceCashAccountId,
      type: '환전',
      amount: _formatPlainNumber(-sourceAmount),
    );

    var targetAccount =
        await (select(cashAccounts)..where(
              (table) =>
                  table.assetId.equals(assetId) &
                  table.currencyCode.equals(targetCurrency),
            ))
            .getSingleOrNull();

    late final int targetCashAccountId;
    if (targetAccount == null) {
      targetCashAccountId = await _insertCashAccount(
        assetId: assetId,
        currencyCode: targetCurrency,
        name: '$targetCurrency 현금 계좌',
        note: '',
        balance: 0,
      );
      targetAccount =
          await (select(cashAccounts)
                ..where((table) => table.id.equals(targetCashAccountId)))
              .getSingleOrNull();
    } else {
      targetCashAccountId = targetAccount.id;
    }

    final sourceSortQuery = selectOnly(transactionEvents)
      ..addColumns([transactionEvents.sortOrder.max()])
      ..where(transactionEvents.deletedAt.isNull());
    final sourceMax =
        (await sourceSortQuery.getSingleOrNull())?.read(
          transactionEvents.sortOrder.max(),
        ) ??
        -1;
    final targetMax = sourceMax;

    final normalizedDate = _normalizeStoredDateKey(date);

    late final int sourceTransactionId;
    await transaction(() async {
      sourceTransactionId = await _createLedgerFxExchangeWithLegacyMirror(
        sourceAssetId: assetId,
        sourceCashAccountId: sourceCashAccountId,
        targetCashAccountId: targetCashAccountId,
        date: normalizedDate,
        name: name,
        sourceAmount: sourceAmount,
        targetAmount: targetAmount,
        exchangeRate: exchangeRate,
        sourceSortOrder: sourceMax + 1,
        targetSortOrder: targetMax + 1,
      );
    });
    await refreshTodaySnapshot();
    return -sourceTransactionId;
  }

  Future<int> createTransaction({
    required int assetId,
    required int holdingId,
    required String date,
    required String type,
    required String name,
    required String amount,
    required String quantity,
    bool includeInCalculations = true,
  }) async {
    final normalizedDate = _normalizeStoredDateKey(date);
    if (holdingId < 0) {
      final normalizedType = _normalizeTransactionType(type);
      final rawAmount = amount.trim().isNotEmpty
          ? amount.trim()
          : quantity.trim();
      final savedAmount = _storedCashTransactionAmount(
        type: normalizedType,
        amount: rawAmount,
      );
      if (_parseTransactionNumber(savedAmount) == 0) {
        throw StateError('거래 금액은 0보다 커야 합니다.');
      }
      final maxQuery = selectOnly(transactionEvents)
        ..addColumns([transactionEvents.sortOrder.max()])
        ..where(transactionEvents.deletedAt.isNull());
      final currentMax =
          (await maxQuery.getSingleOrNull())?.read(
            transactionEvents.sortOrder.max(),
          ) ??
          -1;

      late final int insertedId;
      await transaction(() async {
        if (includeInCalculations) {
          await _ensureSufficientCashBalance(
            cashAccountId: holdingId.abs(),
            type: normalizedType,
            amount: savedAmount,
          );
          insertedId = await _createLedgerCashFlowWithLegacyMirror(
            assetId: assetId,
            cashAccountId: holdingId.abs(),
            date: normalizedDate,
            type: normalizedType,
            name: name,
            amount: savedAmount,
            sortOrder: currentMax + 1,
          );
        } else {
          insertedId = await _createRecordOnlyCashFlow(
            assetId: assetId,
            cashAccountId: holdingId.abs(),
            date: normalizedDate,
            type: normalizedType,
            name: name,
            amount: savedAmount,
            sortOrder: currentMax + 1,
          );
        }
      });
      await refreshTodaySnapshot();
      return -insertedId;
    }

    late final int insertedId;
    final normalizedType = _normalizeTransactionType(type);
    final parsedAmount = _parseTransactionNumber(amount);
    final parsedQuantity = _parseTransactionNumber(quantity);
    if ((normalizedType == '매수' || normalizedType == '매도') &&
        (parsedAmount <= 0 || parsedQuantity <= 0)) {
      throw StateError('매수/매도 거래는 단가와 수량을 0보다 크게 입력해야 합니다.');
    }
    if ((normalizedType == '배당' || normalizedType == '이자') &&
        parsedAmount <= 0) {
      throw StateError('배당/이자 거래는 금액을 0보다 크게 입력해야 합니다.');
    }
    final storedAmount = parsedAmount > 0
        ? _formatPlainNumber(parsedAmount.abs())
        : amount.trim();
    final storedQuantity = parsedQuantity > 0
        ? _formatPlainNumber(parsedQuantity.abs())
        : quantity.trim();
    await transaction(() async {
      final maxQuery = selectOnly(transactionEvents)
        ..addColumns([transactionEvents.sortOrder.max()])
        ..where(transactionEvents.deletedAt.isNull());
      final currentMax =
          (await maxQuery.getSingleOrNull())?.read(
            transactionEvents.sortOrder.max(),
          ) ??
          -1;

      if (includeInCalculations) {
        await _ensureHoldingOpeningLedgerLine(holdingId);
        await _ensureSufficientHoldingQuantityForSell(
          holdingId: holdingId,
          type: normalizedType,
          quantity: storedQuantity,
        );
        await _ensureSufficientSettlementCashForBuy(
          assetId: assetId,
          holdingId: holdingId,
          type: normalizedType,
          amount: storedAmount,
          quantity: storedQuantity,
        );
        insertedId = await _createLedgerInvestmentWithLegacyMirror(
          assetId: assetId,
          holdingId: holdingId,
          date: normalizedDate,
          type: normalizedType,
          name: name,
          amount: storedAmount,
          quantity: storedQuantity,
          sortOrder: currentMax + 1,
        );
      } else {
        insertedId = await _createRecordOnlyInvestment(
          assetId: assetId,
          holdingId: holdingId,
          date: normalizedDate,
          type: normalizedType,
          name: name,
          amount: storedAmount,
          quantity: storedQuantity,
          sortOrder: currentMax + 1,
        );
      }
    });
    if (includeInCalculations) {
      final parityIssues = await fetchLedgerStateParityIssues();
      if (parityIssues.any(
        (issue) =>
            (issue.kind == 'holding_quantity' && issue.id == holdingId) ||
            issue.kind == 'cash_balance',
      )) {
        await _refreshNormalizedLedgerFromLegacyScope(
          investmentHoldingIds: {holdingId},
          markDirty: true,
          softDeleteOldLedger: true,
        );
      }
    }
    await refreshTodaySnapshot();
    return insertedId;
  }

  Future<void> updateTransactionItem(TransactionItem item) async {
    if (item.ledgerEventId != null) {
      await _replaceLedgerTransactionItem(item);
      return;
    }
    if (item.id == null) return;
    final ledgerEventId = await _activeLedgerEventIdForExternalId(item.id!);
    if (ledgerEventId != null) {
      await _replaceLedgerTransactionItem(
        TransactionItem(
          id: item.id,
          clientId: item.clientId,
          assetId: item.assetId,
          holdingId: item.holdingId,
          date: item.date,
          type: item.type,
          name: item.name,
          amount: item.amount,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          quantityValue: item.quantityValue,
          grossAmount: item.grossAmount,
          cashFlowAmount: item.cashFlowAmount,
          realizedProfitAmount: item.realizedProfitAmount,
          ledgerEventId: ledgerEventId,
          ledgerLineId: item.ledgerLineId,
          ledgerKind: item.ledgerKind,
          ledgerAction: item.ledgerAction,
          legacySourceTable: item.legacySourceTable,
          legacySourceId: item.legacySourceId,
          includeInCalculations: item.includeInCalculations,
          flowCategory: item.flowCategory,
        ),
      );
      return;
    }
    final normalizedDate = _normalizeStoredDateKey(item.date);

    if (item.id! < 0) {
      final normalizedType = _normalizeTransactionType(item.type);
      final rawAmount = item.amount.trim().isNotEmpty
          ? item.amount.trim()
          : item.quantity.trim();
      final savedAmount = _storedCashTransactionAmount(
        type: normalizedType,
        amount: rawAmount,
      );
      if (_parseTransactionNumber(savedAmount) == 0) {
        throw StateError('거래 금액은 0보다 커야 합니다.');
      }
      await transaction(() async {
        final row = await (select(
          cashTransactions,
        )..where((table) => table.id.equals(item.id!.abs()))).getSingleOrNull();
        if (row == null) return;
        final linkedRow = row.linkedTransactionId == null
            ? null
            : await (select(cashTransactions)..where(
                    (table) =>
                        table.id.equals(row.linkedTransactionId!) &
                        table.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
        final sourceAccount =
            await (select(cashAccounts)
                  ..where((table) => table.id.equals(row.cashAccountId)))
                .getSingleOrNull();
        if (sourceAccount == null) {
          throw StateError('현금 계좌를 찾을 수 없습니다.');
        }

        await _ensureSufficientCashBalance(
          cashAccountId: row.cashAccountId,
          type: normalizedType,
          amount: savedAmount,
          excludedTransactionIds: {row.id},
        );

        await (update(
          cashTransactions,
        )..where((table) => table.id.equals(item.id!.abs()))).write(
          CashTransactionsCompanion(
            dirty: const Value(true),
            lastModifiedAt: Value(_syncTimestamp()),
            date: Value(normalizedDate),
            type: Value(normalizedType),
            name: Value(item.name),
            amount: Value(savedAmount),
            linkedTransactionId: Value(
              linkedRow == null ||
                      normalizedType == '이체' ||
                      normalizedType == '환전'
                  ? row.linkedTransactionId
                  : null,
            ),
          ),
        );
        await _recalculateCashAccountFromTransactions(row.cashAccountId);
        if (linkedRow != null) {
          if (normalizedType == '이체' || normalizedType == '환전') {
            final sourceAmount = _parseTransactionNumber(savedAmount).abs();
            var linkedAmount = sourceAmount;
            if (normalizedType == '환전') {
              final exchangeRate = double.tryParse(item.quantity.trim());
              if (exchangeRate != null && exchangeRate > 0) {
                linkedAmount = sourceAccount.currencyCode == 'KRW'
                    ? sourceAmount / exchangeRate
                    : sourceAmount * exchangeRate;
              } else {
                final previousSourceAmount = _parseTransactionNumber(
                  row.amount,
                ).abs();
                final previousTargetAmount = _parseTransactionNumber(
                  linkedRow.amount,
                ).abs();
                linkedAmount =
                    previousSourceAmount > 0 && previousTargetAmount > 0
                    ? sourceAmount * previousTargetAmount / previousSourceAmount
                    : previousTargetAmount;
              }
            }
            await (update(
              cashTransactions,
            )..where((table) => table.id.equals(linkedRow.id))).write(
              CashTransactionsCompanion(
                dirty: const Value(true),
                lastModifiedAt: Value(_syncTimestamp()),
                date: Value(normalizedDate),
                type: const Value('입금'),
                name: Value(item.name),
                amount: Value(_formatPlainNumber(linkedAmount)),
              ),
            );
          } else {
            await _softDeleteByIds('cash_transactions', [linkedRow.id]);
          }
          await _recalculateCashAccountFromTransactions(
            linkedRow.cashAccountId,
          );
        }
        await _deleteLedgerEventsForLegacySources(
          sourceTable: 'cash_transactions',
          sourceIds: [row.id],
          softDelete: true,
          markDirty: true,
        );
        if (normalizedType == '이체' || normalizedType == '환전') {
          await _insertLedgerForLegacyCashPair(
            sourceCashTransactionId: row.id,
            markDirty: true,
          );
        } else {
          await _insertLedgerForLegacyCashTransaction(
            cashTransactionId: row.id,
            markDirty: true,
          );
        }
      });
      await refreshTodaySnapshot();
      return;
    }

    final updatedHoldingIds = <int>{};
    await transaction(() async {
      final existing = await (select(
        transactions,
      )..where((table) => table.id.equals(item.id!))).getSingleOrNull();
      if (existing == null) return;
      final normalizedType = _normalizeTransactionType(item.type);
      final parsedAmount = _parseTransactionNumber(item.amount);
      final parsedQuantity = _parseTransactionNumber(item.quantity);
      if ((normalizedType == '매수' || normalizedType == '매도') &&
          (parsedAmount <= 0 || parsedQuantity <= 0)) {
        throw StateError('매수/매도 거래는 단가와 수량을 0보다 크게 입력해야 합니다.');
      }
      if ((normalizedType == '배당' || normalizedType == '이자') &&
          parsedAmount <= 0) {
        throw StateError('배당/이자 거래는 금액을 0보다 크게 입력해야 합니다.');
      }
      final storedAmount = parsedAmount > 0
          ? _formatPlainNumber(parsedAmount.abs())
          : item.amount.trim();
      final storedQuantity = parsedQuantity > 0
          ? _formatPlainNumber(parsedQuantity.abs())
          : item.quantity.trim();
      final assetId = existing.assetId ?? item.assetId ?? 0;
      final holdingId = existing.holdingId;
      if (holdingId != null) {
        updatedHoldingIds.add(holdingId);
      }

      if (holdingId != null) {
        await _ensureSufficientHoldingQuantityForSell(
          holdingId: holdingId,
          type: normalizedType,
          quantity: storedQuantity,
          editingAssetTransactionId: item.id,
        );
        await _ensureSufficientSettlementCashForBuy(
          assetId: assetId,
          holdingId: holdingId,
          type: normalizedType,
          amount: storedAmount,
          quantity: storedQuantity,
          editingAssetTransactionId: item.id,
        );
      }

      await (update(
        transactions,
      )..where((table) => table.id.equals(item.id!))).write(
        TransactionsCompanion(
          dirty: const Value(true),
          lastModifiedAt: Value(_syncTimestamp()),
          date: Value(normalizedDate),
          type: Value(normalizedType),
          name: Value(item.name),
          amount: Value(storedAmount),
          quantity: Value(storedQuantity),
        ),
      );

      if (holdingId != null) {
        await _recalculateHoldingFromTransactions(holdingId);
        if (_shouldSyncHoldingTransactionWithCash(normalizedType)) {
          await _upsertLinkedCashTransactionForHoldingTrade(
            assetTransactionId: item.id!,
            assetId: assetId,
            holdingId: holdingId,
            date: normalizedDate,
            type: normalizedType,
            name: item.name,
            amount: storedAmount,
            quantity: storedQuantity,
          );
        } else {
          await _deleteLinkedCashTransactionForHoldingTrade(item.id!);
        }
      }
    });
    await _refreshSnapshotAndLedgerAfterLegacyMutation(
      investmentHoldingIds: updatedHoldingIds,
    );
  }

  Future<int?> _activeLedgerEventIdForExternalId(int id) async {
    final eventId = id.abs();
    final row =
        await (select(transactionEvents)..where(
              (table) => table.id.equals(eventId) & table.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row != null) return row.id;
    final replacement =
        await (select(transactionEvents)..where(
              (table) =>
                  table.legacySourceTable.equals('transaction_events') &
                  table.legacySourceId.equals(eventId) &
                  table.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return replacement?.id;
  }

  Future<int?> _activeLedgerEventIdForItem(TransactionItem item) async {
    final explicitEventId = item.ledgerEventId;
    if (explicitEventId != null) {
      final row =
          await (select(transactionEvents)..where(
                (table) =>
                    table.id.equals(explicitEventId) & table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (row != null) return row.id;
    }

    final clientId = item.clientId?.trim() ?? '';
    if (clientId.isNotEmpty) {
      final row =
          await (select(transactionEvents)..where(
                (table) =>
                    table.clientId.equals(clientId) & table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (row != null) return row.id;
    }

    final externalId = item.id;
    if (externalId != null) {
      return _activeLedgerEventIdForExternalId(externalId);
    }
    return null;
  }

  Future<void> _replaceLedgerTransactionItem(TransactionItem item) async {
    final eventId = await _activeLedgerEventIdForItem(item);
    if (eventId == null) return;

    final lineRows = await customSelect(
      '''
        SELECT
          id,
          asset_id,
          holding_id,
          cash_account_id,
          action,
          cash_delta
        FROM transaction_lines
        WHERE event_id = ?
          AND deleted_at IS NULL
        ORDER BY sort_order ASC, id ASC
      ''',
      variables: [Variable.withInt(eventId)],
      readsFrom: {transactionLines},
    ).get();
    if (lineRows.isEmpty) return;

    int? primaryHoldingId;
    int? primaryCashAccountId;
    int? primaryAssetId;
    for (final row in lineRows) {
      primaryHoldingId ??= row.read<int?>('holding_id');
      primaryCashAccountId ??= row.read<int?>('cash_account_id');
      primaryAssetId ??= row.read<int?>('asset_id');
    }
    if (primaryAssetId == null) return;

    final affectedHoldingIds = lineRows
        .map((row) => row.read<int?>('holding_id'))
        .whereType<int>()
        .toSet();
    final affectedCashAccountIds = lineRows
        .map((row) => row.read<int?>('cash_account_id'))
        .whereType<int>()
        .toSet();

    await _softDeleteByIds('transaction_lines', [
      for (final row in lineRows) row.read<int>('id'),
    ]);
    await _softDeleteByIds('transaction_events', [eventId]);
    for (final holdingId in affectedHoldingIds) {
      await _recalculateHoldingFromLedgerLines(
        holdingId,
        zeroWhenNoLines: true,
      );
    }
    for (final cashAccountId in affectedCashAccountIds) {
      await _recalculateCashAccountFromLedgerLines(cashAccountId);
    }

    final normalizedType = _normalizeTransactionType(item.type);
    Future<void> markReplacement(int newExternalId) async {
      final newEventId = newExternalId.abs();
      await (update(
        transactionEvents,
      )..where((table) => table.id.equals(newEventId))).write(
        TransactionEventsCompanion(
          legacySourceTable: const Value('transaction_events'),
          legacySourceId: Value(eventId),
          dirty: const Value(true),
          lastModifiedAt: Value(_syncTimestamp()),
        ),
      );
    }

    if (primaryHoldingId != null) {
      final newId = await createTransaction(
        assetId: primaryAssetId,
        holdingId: primaryHoldingId,
        date: item.date,
        type: normalizedType,
        name: item.name,
        amount: item.amount,
        quantity: item.quantity,
        includeInCalculations: item.includeInCalculations,
      );
      await markReplacement(newId);
      return;
    }

    if (primaryCashAccountId == null) return;
    if (!item.includeInCalculations) {
      final newId = await createTransaction(
        assetId: primaryAssetId,
        holdingId: -primaryCashAccountId,
        date: item.date,
        type: normalizedType,
        name: item.name,
        amount: item.amount,
        quantity: item.quantity,
        includeInCalculations: false,
      );
      await markReplacement(newId);
      return;
    }
    if (normalizedType == '이체') {
      final cashAccountIds = lineRows
          .map((row) => row.read<int?>('cash_account_id'))
          .whereType<int>()
          .toSet()
          .toList(growable: false);
      if (cashAccountIds.length < 2) {
        throw StateError('이체 대상 현금 계좌를 찾을 수 없습니다.');
      }
      final targetCashAccountId = cashAccountIds.firstWhere(
        (id) => id != primaryCashAccountId,
        orElse: () => cashAccountIds.last,
      );
      final newId = await createCashTransfer(
        assetId: primaryAssetId,
        sourceHoldingId: -primaryCashAccountId,
        targetHoldingId: -targetCashAccountId,
        date: item.date,
        name: item.name,
        amount: item.amount,
      );
      await markReplacement(newId);
      return;
    }
    if (normalizedType == '환전') {
      final exchangeRate =
          double.tryParse(item.quantity.trim()) ??
          await fetchLinkedCashExchangeRate(-eventId) ??
          0;
      final newId = await createCashExchange(
        assetId: primaryAssetId,
        sourceHoldingId: -primaryCashAccountId,
        date: item.date,
        name: item.name,
        amount: item.amount,
        exchangeRate: exchangeRate,
      );
      await markReplacement(newId);
      return;
    }
    final newId = await createTransaction(
      assetId: primaryAssetId,
      holdingId: -primaryCashAccountId,
      date: item.date,
      type: normalizedType,
      name: item.name,
      amount: item.amount,
      quantity: item.quantity,
      includeInCalculations: item.includeInCalculations,
    );
    await markReplacement(newId);
  }

  Future<void> deleteTransactionItem(int transactionId) async {
    final ledgerEventId = await _activeLedgerEventIdForExternalId(
      transactionId,
    );
    if (ledgerEventId != null) {
      await deleteLedgerTransactionItem(
        TransactionItem(
          id: transactionId,
          date: '',
          type: '',
          name: '',
          amount: '',
          quantity: '',
          ledgerEventId: ledgerEventId,
        ),
      );
      return;
    }
    if (transactionId < 0) {
      await transaction(() async {
        final row =
            await (select(cashTransactions)..where(
                  (table) =>
                      table.id.equals(transactionId.abs()) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (row == null) return;
        final linkedTransactionId = row.linkedTransactionId;
        final linkedRow = linkedTransactionId == null
            ? null
            : await (select(cashTransactions)..where(
                    (table) =>
                        table.id.equals(linkedTransactionId) &
                        table.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
        await _softDeleteByIds('cash_transactions', [transactionId.abs()]);
        if (linkedTransactionId != null) {
          await _softDeleteByIds('cash_transactions', [linkedTransactionId]);
        }
        await _recalculateCashAccountFromTransactions(row.cashAccountId);
        if (linkedRow != null) {
          await _recalculateCashAccountFromTransactions(
            linkedRow.cashAccountId,
          );
        }
        await _deleteLedgerEventsForLegacySources(
          sourceTable: 'cash_transactions',
          sourceIds: [row.id],
          softDelete: true,
          markDirty: true,
        );
      });
      await refreshTodaySnapshot();
      return;
    }
    final deletedHoldingIds = <int>{};
    await transaction(() async {
      final existing =
          await (select(transactions)..where(
                (table) =>
                    table.id.equals(transactionId) & table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (existing == null) return;

      await _deleteLinkedCashTransactionForHoldingTrade(transactionId);
      await _softDeleteByIds('transactions', [transactionId]);

      final holdingId = existing.holdingId;
      if (holdingId != null) {
        deletedHoldingIds.add(holdingId);
        await _recalculateHoldingFromTransactions(holdingId);
      }
    });
    await _refreshSnapshotAndLedgerAfterLegacyMutation(
      investmentHoldingIds: deletedHoldingIds,
    );
  }

  Future<void> deleteLedgerTransactionItem(TransactionItem item) async {
    final eventId = await _activeLedgerEventIdForItem(item);
    if (eventId == null) {
      final transactionId = item.id;
      if (transactionId != null) {
        await deleteTransactionItem(transactionId);
      }
      return;
    }

    final affectedHoldingIds = <int>{};
    final affectedCashAccountIds = <int>{};
    final legacyInvestmentIds = <int>{};
    final legacyCashIds = <int>{};

    await transaction(() async {
      final lineRows = await customSelect(
        '''
          SELECT
            id,
            holding_id,
            cash_account_id,
            legacy_source_table,
            legacy_source_id
          FROM transaction_lines
          WHERE event_id = ?
            AND deleted_at IS NULL
        ''',
        variables: [Variable.withInt(eventId)],
        readsFrom: {transactionLines},
      ).get();

      final eventRow = await (select(
        transactionEvents,
      )..where((table) => table.id.equals(eventId))).getSingleOrNull();
      if (eventRow == null || eventRow.deletedAt != null) return;

      for (final row in lineRows) {
        final holdingId = row.read<int?>('holding_id');
        final cashAccountId = row.read<int?>('cash_account_id');
        if (holdingId != null) affectedHoldingIds.add(holdingId);
        if (cashAccountId != null) affectedCashAccountIds.add(cashAccountId);

        final legacyTable = row.read<String?>('legacy_source_table');
        final legacyId = row.read<int?>('legacy_source_id');
        if (legacyTable == 'transactions' && legacyId != null) {
          legacyInvestmentIds.add(legacyId);
        } else if (legacyTable == 'cash_transactions' && legacyId != null) {
          legacyCashIds.add(legacyId);
        }
      }

      if (eventRow.legacySourceTable == 'transactions' &&
          eventRow.legacySourceId != null) {
        legacyInvestmentIds.add(eventRow.legacySourceId!);
      } else if (eventRow.legacySourceTable == 'cash_transactions' &&
          eventRow.legacySourceId != null) {
        legacyCashIds.add(eventRow.legacySourceId!);
      }

      for (final transactionId in legacyInvestmentIds) {
        await _deleteLinkedCashTransactionForHoldingTrade(transactionId);
      }
      await _softDeleteByIds('transactions', legacyInvestmentIds.toList());

      if (legacyCashIds.isNotEmpty) {
        final linkedRows =
            await (select(cashTransactions)..where(
                  (table) =>
                      table.id.isIn(legacyCashIds.toList()) &
                      table.deletedAt.isNull(),
                ))
                .get();
        for (final row in linkedRows) {
          if (row.linkedTransactionId != null) {
            legacyCashIds.add(row.linkedTransactionId!);
          }
          affectedCashAccountIds.add(row.cashAccountId);
        }
        await _softDeleteByIds('cash_transactions', legacyCashIds.toList());
      }

      await _softDeleteByIds('transaction_lines', [
        for (final row in lineRows) row.read<int>('id'),
      ]);
    });

    await _softDeleteByIds('transaction_events', [eventId]);
    for (final holdingId in affectedHoldingIds) {
      await _recalculateHoldingFromLedgerLines(
        holdingId,
        zeroWhenNoLines: true,
      );
    }
    for (final cashAccountId in affectedCashAccountIds) {
      await _recalculateCashAccountFromLedgerLines(cashAccountId);
    }
    await refreshTodaySnapshot();
  }

  Future<void> _recalculateHoldingFromTransactions(
    int holdingId, {
    bool markDirty = true,
  }) async {
    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null) return;

    final assetRow = await (select(
      assets,
    )..where((table) => table.id.equals(holdingRow.assetId))).getSingleOrNull();
    if (assetRow == null) return;

    final allTransactionRows = await (select(
      transactions,
    )..where((table) => table.holdingId.equals(holdingId))).get();
    final transactionRows = allTransactionRows
        .where((row) => row.deletedAt == null)
        .toList(growable: false);
    transactionRows.sort(_compareTransactions);

    final isCashLike = assetRow.assetType == '현금';
    final preservedCurrentPrice = isCashLike && holdingRow.currentPrice == 0
        ? 1.0
        : holdingRow.currentPrice;
    final cashUnitPrice = holdingRow.averagePrice == 0
        ? (preservedCurrentPrice == 0 ? 1.0 : preservedCurrentPrice)
        : holdingRow.averagePrice;
    final hasAcquisitionTransaction = transactionRows.any((row) {
      final type = _normalizeTransactionType(row.type);
      return type == '매수' || type == '입금';
    });

    var quantity = 0.0;
    var totalCost = 0.0;
    var averagePrice = isCashLike ? cashUnitPrice : 0.0;

    if (allTransactionRows.isEmpty &&
        !hasAcquisitionTransaction &&
        holdingRow.quantity > 0) {
      quantity = holdingRow.quantity;
      averagePrice = holdingRow.averagePrice > 0
          ? holdingRow.averagePrice
          : (preservedCurrentPrice > 0 ? preservedCurrentPrice : averagePrice);
      totalCost = quantity * averagePrice;
    }

    for (final row in transactionRows) {
      final amount = _parseTransactionNumber(row.amount);
      final transactionQuantity = _parseTransactionNumber(row.quantity);
      final normalizedValues = _normalizedTransactionValues(
        type: row.type,
        amount: row.amount,
        quantity: row.quantity,
        averageCostBasis: averagePrice,
      );
      await (update(
        transactions,
      )..where((table) => table.id.equals(row.id))).write(
        TransactionsCompanion(
          unitPrice: Value(normalizedValues.unitPrice),
          quantityValue: Value(normalizedValues.quantityValue),
          grossAmount: Value(normalizedValues.grossAmount),
          cashFlowAmount: Value(normalizedValues.cashFlowAmount),
          realizedProfitAmount: Value(normalizedValues.realizedProfitAmount),
        ),
      );

      if (isCashLike) {
        final delta = amount != 0 ? amount : transactionQuantity;
        if (delta <= 0) continue;

        switch (_normalizeTransactionType(row.type)) {
          case '매수':
          case '입금':
            quantity += delta;
            break;
          case '매도':
          case '출금':
            quantity = (quantity - delta)
                .clamp(0.0, double.infinity)
                .toDouble();
            break;
        }
        totalCost = quantity * cashUnitPrice;
        averagePrice = quantity == 0 ? cashUnitPrice : totalCost / quantity;
        continue;
      }

      switch (_normalizeTransactionType(row.type)) {
        case '초기':
        case '매수':
          final deltaQuantity = transactionQuantity;
          if (deltaQuantity <= 0) continue;
          final addedCost = amount > 0
              ? amount * deltaQuantity
              : (averagePrice > 0
                    ? averagePrice * deltaQuantity
                    : preservedCurrentPrice * deltaQuantity);
          quantity += deltaQuantity;
          totalCost += addedCost;
          averagePrice = quantity == 0 ? 0 : totalCost / quantity;
          break;
        case '매도':
          final deltaQuantity = transactionQuantity <= 0
              ? 0.0
              : transactionQuantity.clamp(0.0, quantity).toDouble();
          if (deltaQuantity <= 0 || quantity <= 0) continue;
          totalCost -= averagePrice * deltaQuantity;
          quantity -= deltaQuantity;
          if (quantity <= 0.0000001) {
            quantity = 0;
            totalCost = 0;
            averagePrice = 0;
          } else {
            averagePrice = totalCost / quantity;
          }
          break;
        case '입금':
          final deltaQuantity = transactionQuantity > 0
              ? transactionQuantity
              : (preservedCurrentPrice > 0
                    ? amount / preservedCurrentPrice
                    : 0.0);
          if (deltaQuantity <= 0) continue;
          final addedCost = amount > 0
              ? amount * deltaQuantity
              : averagePrice * deltaQuantity;
          quantity += deltaQuantity;
          totalCost += addedCost;
          averagePrice = quantity == 0 ? 0 : totalCost / quantity;
          break;
        case '출금':
          final rawQuantity = transactionQuantity > 0
              ? transactionQuantity
              : (preservedCurrentPrice > 0
                    ? amount / preservedCurrentPrice
                    : 0.0);
          final deltaQuantity = rawQuantity.clamp(0.0, quantity).toDouble();
          if (deltaQuantity <= 0 || quantity <= 0) continue;
          totalCost -= averagePrice * deltaQuantity;
          quantity -= deltaQuantity;
          if (quantity <= 0.0000001) {
            quantity = 0;
            totalCost = 0;
            averagePrice = 0;
          } else {
            averagePrice = totalCost / quantity;
          }
          break;
      }
    }

    await (update(
      holdings,
    )..where((table) => table.id.equals(holdingId))).write(
      HoldingsCompanion(
        dirty: markDirty ? const Value(true) : const Value.absent(),
        lastModifiedAt: markDirty
            ? Value(_syncTimestamp())
            : const Value.absent(),
        quantity: Value(quantity),
        averagePrice: Value(averagePrice),
        currentPrice: Value(
          isCashLike && preservedCurrentPrice == 0
              ? 1.0
              : preservedCurrentPrice,
        ),
      ),
    );
    await _refreshAssetSummary(holdingRow.assetId, markDirty: markDirty);
  }

  Future<void> _recalculateHoldingFromLedgerLines(
    int holdingId, {
    bool markDirty = true,
    bool zeroWhenNoLines = false,
  }) async {
    final holdingRow = await (select(
      holdings,
    )..where((table) => table.id.equals(holdingId))).getSingleOrNull();
    if (holdingRow == null) return;

    final row = await customSelect(
      '''
        SELECT
          COUNT(*) AS line_count,
          COALESCE(SUM(tl.quantity_delta), 0) AS quantity,
          COALESCE(SUM(tl.cost_basis_delta), 0) AS cost_basis
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('history_display', 'record_only')
          AND tl.holding_id = ?
      ''',
      variables: [Variable.withInt(holdingId)],
      readsFrom: {transactionEvents, transactionLines},
    ).getSingle();

    final lineCount = row.read<int>('line_count');
    if (lineCount == 0 && !zeroWhenNoLines) return;

    final quantity = row.read<double>('quantity');
    final costBasis = row.read<double>('cost_basis');
    final averagePrice = quantity.abs() <= 0.0000001
        ? 0.0
        : costBasis / quantity;

    await (update(
      holdings,
    )..where((table) => table.id.equals(holdingId))).write(
      HoldingsCompanion(
        dirty: markDirty ? const Value(true) : const Value.absent(),
        lastModifiedAt: markDirty
            ? Value(_syncTimestamp())
            : const Value.absent(),
        quantity: Value(quantity.abs() <= 0.0000001 ? 0 : quantity),
        averagePrice: Value(averagePrice < 0 ? 0 : averagePrice),
      ),
    );
    await _refreshAssetSummary(holdingRow.assetId, markDirty: markDirty);
  }

  Future<void> _recalculateCashAccountFromTransactions(
    int cashAccountId, {
    bool markDirty = true,
  }) async {
    final account = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (account == null) return;

    final rows =
        await (select(cashTransactions)
              ..where(
                (table) =>
                    table.cashAccountId.equals(cashAccountId) &
                    table.deletedAt.isNull(),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.date),
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    var balance = account.baseBalance;
    for (final row in rows) {
      final normalizedValues = _normalizedCashTransactionValues(
        type: row.type,
        amount: row.amount,
      );
      await (update(
        cashTransactions,
      )..where((table) => table.id.equals(row.id))).write(
        CashTransactionsCompanion(
          amountValue: Value(normalizedValues.grossAmount),
          cashFlowAmount: Value(normalizedValues.cashFlowAmount),
        ),
      );
      balance += _cashTransactionBalanceDelta(
        type: row.type,
        amount: row.amount,
      );
    }

    await (update(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).write(
      CashAccountsCompanion(
        dirty: markDirty ? const Value(true) : const Value.absent(),
        lastModifiedAt: markDirty
            ? Value(_syncTimestamp())
            : const Value.absent(),
        balance: Value(balance),
      ),
    );
    await _refreshAssetSummary(account.assetId, markDirty: markDirty);
  }

  Future<void> _recalculateCashAccountFromLedgerLines(
    int cashAccountId, {
    bool markDirty = true,
  }) async {
    final account = await (select(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).getSingleOrNull();
    if (account == null) return;

    final row = await customSelect(
      '''
        SELECT COALESCE(SUM(tl.cash_delta), 0) AS cash_delta
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source NOT IN ('history_display', 'record_only')
          AND tl.cash_account_id = ?
      ''',
      variables: [Variable.withInt(cashAccountId)],
      readsFrom: {transactionEvents, transactionLines},
    ).getSingle();

    final balance = account.baseBalance + row.read<double>('cash_delta');
    await (update(
      cashAccounts,
    )..where((table) => table.id.equals(cashAccountId))).write(
      CashAccountsCompanion(
        dirty: markDirty ? const Value(true) : const Value.absent(),
        lastModifiedAt: markDirty
            ? Value(_syncTimestamp())
            : const Value.absent(),
        balance: Value(balance),
      ),
    );
    await _refreshAssetSummary(account.assetId, markDirty: markDirty);
  }

  Future<void> saveTodaySnapshotIfMissing() async {
    // Snapshots are no longer generated on-device.
  }

  Future<void> refreshTodaySnapshot() async {
    // Snapshots are no longer generated on-device.
  }

  Future<int> importRemotePortfolioSnapshots(
    List<Map<String, dynamic>> snapshots,
  ) async {
    if (snapshots.isEmpty) {
      return 0;
    }

    await _createCurrentTablesIfNeeded();

    final assetIdByClientId = {
      for (final row in await select(assets).get())
        if ((row.clientId ?? '').trim().isNotEmpty)
          row.clientId!.trim(): row.id,
    };
    final holdingIdByClientId = {
      for (final row in await select(holdings).get())
        if ((row.clientId ?? '').trim().isNotEmpty)
          row.clientId!.trim(): row.id,
    };
    final cashAccountIdByClientId = {
      for (final row in await select(cashAccounts).get())
        if ((row.clientId ?? '').trim().isNotEmpty)
          row.clientId!.trim(): row.id,
    };

    int snapshotAssetId(Map<String, dynamic> row) {
      final assetClientId = _nullableString(row['asset_client_id']);
      if (assetClientId != null) {
        return assetIdByClientId[assetClientId] ?? -1;
      }
      return _readInt(row['asset_id']);
    }

    int? snapshotNullableAssetId(Map<String, dynamic> row) {
      final assetClientId = _nullableString(row['asset_client_id']);
      if (assetClientId != null) {
        return assetIdByClientId[assetClientId];
      }
      return _readNullableInt(row['asset_id']);
    }

    int? snapshotHoldingId(Map<String, dynamic> row) {
      final holdingClientId = _nullableString(row['holding_client_id']);
      if (holdingClientId != null) {
        return holdingIdByClientId[holdingClientId];
      }
      return _readNullableInt(row['holding_id']);
    }

    int? snapshotCashAccountId(Map<String, dynamic> row) {
      final cashAccountClientId = _nullableString(
        row['cash_account_client_id'],
      );
      if (cashAccountClientId != null) {
        return cashAccountIdByClientId[cashAccountClientId];
      }
      return _readNullableInt(row['cash_account_id']);
    }

    var importedCount = 0;
    await transaction(() async {
      for (final snapshot in snapshots) {
        final snapshotDate = _normalizeSnapshotDateKey(
          _readString(snapshot['snapshot_date']),
        );
        if (snapshotDate.isEmpty) {
          continue;
        }

        await _deleteExistingSnapshotForDate(snapshotDate);

        final snapshotId = await into(dailyPortfolioSnapshots).insert(
          DailyPortfolioSnapshotsCompanion.insert(
            snapshotDate: snapshotDate,
            totalPurchaseAmount: _readDouble(snapshot['total_purchase_amount']),
            totalValuationAmount: _readDouble(
              snapshot['total_valuation_amount'],
            ),
            profitAmount: _readDouble(snapshot['profit_amount']),
            profitRate: _readDouble(snapshot['profit_rate']),
            exchangeRate: Value(_readDouble(snapshot['exchange_rate'], 1.0)),
            createdAt: _readString(
              snapshot['created_at'],
              fallback: DateTime.now().toIso8601String(),
            ),
          ),
        );

        final itemRows = _readMapList(snapshot['items']);
        final holdingRows = _readMapList(snapshot['holding_items']);
        final cashAccountRows = _readMapList(snapshot['cash_accounts']);

        await batch((batch) {
          for (final item in itemRows) {
            final assetTitle = _readString(item['asset_title']);
            if (assetTitle.isEmpty) {
              continue;
            }
            batch.insert(
              dailyPortfolioSnapshotItems,
              DailyPortfolioSnapshotItemsCompanion.insert(
                snapshotId: snapshotId,
                assetId: snapshotAssetId(item),
                assetTitle: assetTitle,
                totalPurchaseAmount: _readDouble(item['total_purchase_amount']),
                totalValuationAmount: _readDouble(
                  item['total_valuation_amount'],
                ),
                profitAmount: _readDouble(item['profit_amount']),
                profitRate: _readDouble(item['profit_rate']),
                holdingCount: _readInt(item['holding_count'], fallback: 0),
              ),
            );
          }

          for (final holding in holdingRows) {
            final assetTitle = _readString(holding['asset_title']);
            final holdingName = _readString(holding['holding_name']);
            if (assetTitle.isEmpty || holdingName.isEmpty) {
              continue;
            }
            batch.insert(
              dailyPortfolioSnapshotHoldingItems,
              DailyPortfolioSnapshotHoldingItemsCompanion.insert(
                snapshotId: snapshotId,
                assetTitle: assetTitle,
                holdingName: holdingName,
                holdingSymbol: _readString(holding['holding_symbol']),
                currencyCode: _readString(
                  holding['currency_code'],
                  fallback: 'KRW',
                ),
                quantity: _readDouble(holding['quantity']),
                totalPurchaseAmount: _readDouble(
                  holding['total_purchase_amount'],
                ),
                totalValuationAmount: _readDouble(
                  holding['total_valuation_amount'],
                ),
                profitAmount: _readDouble(holding['profit_amount']),
                profitRate: _readDouble(holding['profit_rate']),
                assetId: Value.absentIfNull(snapshotNullableAssetId(holding)),
                holdingId: Value.absentIfNull(snapshotHoldingId(holding)),
              ),
            );
          }

          for (final account in cashAccountRows) {
            final assetTitle = _readString(account['asset_title']);
            final cashAccountName = _readString(account['cash_account_name']);
            if (assetTitle.isEmpty || cashAccountName.isEmpty) {
              continue;
            }
            batch.customStatement(
              'INSERT INTO daily_portfolio_snapshot_cash_accounts '
              '(snapshot_id, asset_id, asset_title, cash_account_id, cash_account_name, currency_code, balance, note) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [
                snapshotId,
                snapshotNullableAssetId(account),
                assetTitle,
                snapshotCashAccountId(account),
                cashAccountName,
                _readString(account['currency_code'], fallback: 'KRW'),
                _readDouble(account['balance']),
                _readString(account['note']),
              ],
            );
          }
        });

        await saveSnapshotNote(
          snapshotDate: snapshotDate,
          note: _readString(snapshot['note']),
        );
        importedCount++;
      }
    });

    return importedCount;
  }

  Future<void> backfillAllSnapshotDetails() async {
    // Snapshot backfill is handled by server-delivered payloads.
  }

  Future<void> insertManualPortfolioSnapshot({
    required String snapshotDate,
    required Map<String, double> assetValues,
  }) async {
    // Snapshots are no longer generated on-device.
  }

  Future<void> ensureSeededHistoricalSnapshots() async {
    // Historical snapshots are delivered by the server.
  }

  Future<void> deletePortfolioSnapshotItem({
    required int snapshotItemId,
    required int snapshotId,
    int? assetId,
    required String assetTitle,
  }) async {
    await transaction(() async {
      final holdingDelete = delete(dailyPortfolioSnapshotHoldingItems)
        ..where((table) => table.snapshotId.equals(snapshotId));
      if (assetId != null) {
        holdingDelete.where((table) => table.assetId.equals(assetId));
      } else {
        holdingDelete.where((table) => table.assetTitle.equals(assetTitle));
      }
      await holdingDelete.go();

      if (assetId != null) {
        await customStatement(
          'DELETE FROM daily_portfolio_snapshot_cash_accounts '
          'WHERE snapshot_id = ? AND asset_id = ?',
          [snapshotId, assetId],
        );
      } else {
        await customStatement(
          'DELETE FROM daily_portfolio_snapshot_cash_accounts '
          'WHERE snapshot_id = ? AND asset_title = ?',
          [snapshotId, assetTitle],
        );
      }

      await (delete(
        dailyPortfolioSnapshotItems,
      )..where((table) => table.id.equals(snapshotItemId))).go();
    });
  }

  Future<void> deletePortfolioSnapshotHoldingItem(
    int snapshotHoldingItemId,
  ) async {
    await (delete(
      dailyPortfolioSnapshotHoldingItems,
    )..where((table) => table.id.equals(snapshotHoldingItemId))).go();
  }

  Future<DailyPortfolioSnapshot?> fetchPortfolioSnapshotByDate(
    String snapshotDate,
  ) {
    return (select(dailyPortfolioSnapshots)
          ..where((table) => table.snapshotDate.equals(snapshotDate))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DailyPortfolioSnapshot?> fetchPreviousPortfolioSnapshot(
    String snapshotDate,
  ) {
    return (select(dailyPortfolioSnapshots)
          ..where(
            (table) => table.snapshotDate.isSmallerThanValue(snapshotDate),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.snapshotDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DailyPortfolioSnapshot?> fetchNextPortfolioSnapshot(
    String snapshotDate,
  ) {
    return (select(dailyPortfolioSnapshots)
          ..where((table) => table.snapshotDate.isBiggerThanValue(snapshotDate))
          ..orderBy([(table) => OrderingTerm.asc(table.snapshotDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<DailyPortfolioSnapshot>> fetchRecentPortfolioSnapshots({
    int maxDates = 6,
  }) async {
    final rows =
        await (select(dailyPortfolioSnapshots)
              ..orderBy([(table) => OrderingTerm.desc(table.snapshotDate)])
              ..limit(maxDates))
            .get();

    return rows..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
  }

  Future<List<DailyPortfolioSnapshot>> fetchAllPortfolioSnapshots() async {
    return (select(
      dailyPortfolioSnapshots,
    )..orderBy([(table) => OrderingTerm.asc(table.snapshotDate)])).get();
  }

  Future<List<DailyPortfolioSnapshotItem>> fetchPortfolioSnapshotItemsByDates(
    List<String> snapshotDates,
  ) async {
    if (snapshotDates.isEmpty) return const [];

    final snapshots = await (select(
      dailyPortfolioSnapshots,
    )..where((table) => table.snapshotDate.isIn(snapshotDates))).get();
    if (snapshots.isEmpty) return const [];

    final snapshotIdByDate = {
      for (final snapshot in snapshots) snapshot.id: snapshot.snapshotDate,
    };
    final rows =
        await (select(dailyPortfolioSnapshotItems)
              ..where(
                (table) =>
                    table.snapshotId.isIn(snapshotIdByDate.keys.toList()),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.snapshotId),
                (table) => OrderingTerm.asc(table.assetTitle),
              ]))
            .get();

    rows.sort((a, b) {
      final dateA = snapshotIdByDate[a.snapshotId] ?? '';
      final dateB = snapshotIdByDate[b.snapshotId] ?? '';
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      return a.assetTitle.compareTo(b.assetTitle);
    });

    return rows;
  }

  Future<List<DailyPortfolioSnapshotHoldingItem>>
  fetchPortfolioSnapshotHoldingItemsByDates(List<String> snapshotDates) async {
    if (snapshotDates.isEmpty) return const [];

    final snapshots = await (select(
      dailyPortfolioSnapshots,
    )..where((table) => table.snapshotDate.isIn(snapshotDates))).get();
    if (snapshots.isEmpty) return const [];

    final snapshotIdByDate = {
      for (final snapshot in snapshots) snapshot.id: snapshot.snapshotDate,
    };
    final rows =
        await (select(dailyPortfolioSnapshotHoldingItems)
              ..where(
                (table) =>
                    table.snapshotId.isIn(snapshotIdByDate.keys.toList()),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.snapshotId),
                (table) => OrderingTerm.asc(table.assetTitle),
                (table) => OrderingTerm.asc(table.holdingName),
              ]))
            .get();

    rows.sort((a, b) {
      final dateA = snapshotIdByDate[a.snapshotId] ?? '';
      final dateB = snapshotIdByDate[b.snapshotId] ?? '';
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      final assetCompare = a.assetTitle.compareTo(b.assetTitle);
      if (assetCompare != 0) return assetCompare;
      return a.holdingName.compareTo(b.holdingName);
    });

    return rows;
  }

  Future<void> _deleteExistingSnapshotForDate(String snapshotDate) async {
    final normalizedDate = _normalizeSnapshotDateKey(snapshotDate);
    if (normalizedDate.isEmpty) return;

    final existingSnapshotRows = await customSelect(
      'SELECT * FROM daily_portfolio_snapshots WHERE substr(snapshot_date, 1, 10) = ?',
      variables: [Variable<String>(normalizedDate)],
      readsFrom: {dailyPortfolioSnapshots},
    ).get();
    final existingSnapshotIds = existingSnapshotRows
        .map((row) => row.read<int>('id'))
        .whereType<int>()
        .toList(growable: false);
    if (existingSnapshotIds.isEmpty) return;

    final placeholders = List.filled(
      existingSnapshotIds.length,
      '?',
    ).join(', ');
    await customStatement(
      'DELETE FROM daily_portfolio_snapshot_cash_accounts '
      'WHERE snapshot_id IN ($placeholders)',
      existingSnapshotIds,
    );
    await (delete(
      dailyPortfolioSnapshotHoldingItems,
    )..where((table) => table.snapshotId.isIn(existingSnapshotIds))).go();
    await (delete(
      dailyPortfolioSnapshotItems,
    )..where((table) => table.snapshotId.isIn(existingSnapshotIds))).go();
    await (delete(
      dailyPortfolioSnapshots,
    )..where((table) => table.id.isIn(existingSnapshotIds))).go();
  }

  Future<void> _insertSnapshotCashAccountRows({
    required int snapshotId,
    required String snapshotDate,
  }) async {
    final assetRows = await (select(
      assets,
    )..orderBy([(table) => OrderingTerm.asc(table.sortOrder)])).get();
    final cashAccountRows =
        await (select(cashAccounts)..orderBy([
              (table) => OrderingTerm.asc(table.sortOrder),
              (table) => OrderingTerm.asc(table.id),
            ]))
            .get();

    final assetRowById = {for (final row in assetRows) row.id: row};

    await batch((batch) {
      for (final account in cashAccountRows) {
        final asset = assetRowById[account.assetId];
        if (asset == null) continue;
        batch.customStatement(
          'INSERT INTO daily_portfolio_snapshot_cash_accounts '
          '(snapshot_id, asset_id, asset_title, cash_account_id, cash_account_name, currency_code, balance, note) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            snapshotId,
            account.assetId,
            asset.alias.isEmpty ? asset.title : asset.alias,
            account.id,
            account.name,
            account.currencyCode,
            account.balance,
            account.note,
          ],
        );
      }
    });
  }

  String _normalizeSnapshotDateKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      final month = parsed.month.toString().padLeft(2, '0');
      final day = parsed.day.toString().padLeft(2, '0');
      return '${parsed.year}-$month-$day';
    }
    return trimmed.split('T').first;
  }

  Future<void> _backfillExistingSnapshotCashAccounts() async {
    final snapshots = await (select(
      dailyPortfolioSnapshots,
    )..orderBy([(table) => OrderingTerm.asc(table.snapshotDate)])).get();
    for (final snapshot in snapshots) {
      await customStatement(
        'DELETE FROM daily_portfolio_snapshot_cash_accounts WHERE snapshot_id = ?',
        [snapshot.id],
      );
      await _insertSnapshotCashAccountRows(
        snapshotId: snapshot.id,
        snapshotDate: snapshot.snapshotDate,
      );
    }
  }

  Future<List<SnapshotCashAccountRecord>>
  fetchPortfolioSnapshotCashAccountsByDates(List<String> snapshotDates) async {
    if (snapshotDates.isEmpty) return const [];

    final snapshots = await (select(
      dailyPortfolioSnapshots,
    )..where((table) => table.snapshotDate.isIn(snapshotDates))).get();
    if (snapshots.isEmpty) return const [];

    final snapshotIdByDate = {
      for (final snapshot in snapshots) snapshot.id: snapshot.snapshotDate,
    };
    final placeholders = List.filled(snapshotIdByDate.length, '?').join(', ');
    final rows = await customSelect(
      'SELECT id, snapshot_id, asset_id, asset_title, cash_account_id, cash_account_name, '
      'currency_code, balance, note '
      'FROM daily_portfolio_snapshot_cash_accounts '
      'WHERE snapshot_id IN ($placeholders) '
      'ORDER BY snapshot_id ASC, asset_title ASC, cash_account_name ASC',
      variables: snapshotIdByDate.keys.map(Variable.withInt).toList(),
    ).get();

    rows.sort((a, b) {
      final dateA = snapshotIdByDate[a.read<int>('snapshot_id')] ?? '';
      final dateB = snapshotIdByDate[b.read<int>('snapshot_id')] ?? '';
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      final assetCompare = a
          .read<String>('asset_title')
          .compareTo(b.read<String>('asset_title'));
      if (assetCompare != 0) return assetCompare;
      return a
          .read<String>('cash_account_name')
          .compareTo(b.read<String>('cash_account_name'));
    });

    return rows
        .map(
          (row) => SnapshotCashAccountRecord(
            id: row.read<int>('id'),
            snapshotId: row.read<int>('snapshot_id'),
            assetId: row.read<int?>('asset_id'),
            assetTitle: row.read<String>('asset_title'),
            cashAccountId: row.read<int?>('cash_account_id'),
            cashAccountName: row.read<String>('cash_account_name'),
            currencyCode: row.read<String>('currency_code'),
            balance: row.read<double>('balance'),
            note: row.read<String>('note'),
          ),
        )
        .toList(growable: false);
  }

  Future<List<SnapshotTransactionRecord>> fetchTransactionsForDate(
    String snapshotDate,
  ) async {
    final rows = await customSelect(
      '''
        SELECT
          tl.id AS id,
          te.id AS event_id,
          te.legacy_source_id AS legacy_source_id,
          COALESCE(tl.asset_id, h.asset_id) AS asset_id,
          CASE WHEN a.alias IS NULL OR a.alias = '' THEN a.title ELSE a.alias END AS asset_title,
          tl.holding_id AS holding_id,
          COALESCE(h.name, '') AS holding_name,
          te.occurred_at AS date,
          tl.action AS action,
          te.title AS name,
          tl.unit_price AS unit_price,
          tl.gross_amount AS gross_amount,
          ABS(tl.quantity_delta) AS quantity,
          te.sort_order AS event_sort_order,
          tl.sort_order AS line_sort_order
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        LEFT JOIN holdings h ON h.id = tl.holding_id
        LEFT JOIN assets a ON a.id = COALESCE(tl.asset_id, h.asset_id)
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source != 'snapshot_restore'
          AND tl.holding_id IS NOT NULL
          AND tl.action IN (
            'opening_quantity',
            'buy',
            'sell',
            'dividend',
            'interest',
            'fee',
            'tax',
            'adjustment'
          )
        ORDER BY te.sort_order ASC, te.id ASC, tl.sort_order ASC, tl.id ASC
      ''',
      readsFrom: {transactionEvents, transactionLines, holdings, assets},
    ).get();

    return rows
        .where(
          (row) =>
              _normalizeStoredDateKey(row.read<String>('date')) == snapshotDate,
        )
        .map((row) {
          final assetId = row.read<int?>('asset_id');
          final action = row.read<String>('action');
          return SnapshotTransactionRecord(
            id: row.read<int>('id'),
            snapshotId: 0,
            assetId: assetId,
            assetTitle: row.read<String?>('asset_title') ?? '',
            holdingId: row.read<int?>('holding_id'),
            holdingName: row.read<String>('holding_name'),
            transactionId:
                row.read<int?>('legacy_source_id') ?? row.read<int>('event_id'),
            date: row.read<String>('date'),
            type: _ledgerInvestmentActionLabel(action),
            name: row.read<String>('name'),
            amount: _formatPlainNumber(
              _ledgerInvestmentDisplayAmount(
                action: action,
                unitPrice: row.read<double>('unit_price'),
                grossAmount: row.read<double>('gross_amount'),
              ),
            ),
            quantity: _formatPlainNumber(row.read<double>('quantity')),
            sortOrder: row.read<int>('event_sort_order'),
          );
        })
        .whereType<SnapshotTransactionRecord>()
        .toList(growable: false);
  }

  Future<List<SnapshotCashTransactionRecord>> fetchCashTransactionsForDate(
    String snapshotDate,
  ) async {
    final rows = await customSelect(
      '''
        SELECT
          tl.id AS id,
          te.id AS event_id,
          te.legacy_source_id AS legacy_source_id,
          tl.asset_id AS asset_id,
          CASE WHEN a.alias IS NULL OR a.alias = '' THEN a.title ELSE a.alias END AS asset_title,
          tl.cash_account_id AS cash_account_id,
          ca.name AS cash_account_name,
          tl.currency_code AS currency_code,
          te.occurred_at AS date,
          tl.action AS action,
          te.title AS name,
          tl.cash_delta AS cash_delta,
          te.sort_order AS event_sort_order,
          tl.sort_order AS line_sort_order
        FROM transaction_lines tl
        INNER JOIN transaction_events te ON te.id = tl.event_id
        LEFT JOIN cash_accounts ca ON ca.id = tl.cash_account_id
        LEFT JOIN assets a ON a.id = COALESCE(tl.asset_id, ca.asset_id)
        WHERE tl.deleted_at IS NULL
          AND te.deleted_at IS NULL
          AND te.source != 'snapshot_restore'
          AND tl.cash_account_id IS NOT NULL
          AND tl.action IN (
            'opening_cash',
            'settlement',
            'deposit',
            'withdrawal',
            'transfer_out',
            'transfer_in',
            'fx_out',
            'fx_in',
            'dividend',
            'interest',
            'fee',
            'tax',
            'adjustment'
          )
        ORDER BY te.sort_order ASC, te.id ASC, tl.sort_order ASC, tl.id ASC
      ''',
      readsFrom: {transactionEvents, transactionLines, cashAccounts, assets},
    ).get();

    return rows
        .where(
          (row) =>
              _normalizeStoredDateKey(row.read<String>('date')) == snapshotDate,
        )
        .map((row) {
          final cashDelta = row.read<double>('cash_delta');
          return SnapshotCashTransactionRecord(
            id: row.read<int>('id'),
            snapshotId: 0,
            assetId: row.read<int?>('asset_id'),
            assetTitle: row.read<String?>('asset_title') ?? '',
            cashAccountId: row.read<int?>('cash_account_id'),
            cashAccountName: row.read<String?>('cash_account_name') ?? '',
            currencyCode: row.read<String>('currency_code'),
            transactionId:
                row.read<int?>('legacy_source_id') ?? row.read<int>('event_id'),
            linkedTransactionId: row.read<int>('event_id'),
            date: row.read<String>('date'),
            type: _ledgerCashActionLabel(
              action: row.read<String>('action'),
              cashDelta: cashDelta,
            ),
            name: row.read<String>('name'),
            amount: _formatPlainNumber(cashDelta),
            sortOrder: row.read<int>('event_sort_order'),
          );
        })
        .whereType<SnapshotCashTransactionRecord>()
        .toList(growable: false);
  }

  Future<List<DailyPortfolioSnapshotHoldingItem>>
  fetchDisplayPortfolioSnapshotHoldingItemsByDates(
    List<String> snapshotDates,
  ) async {
    if (snapshotDates.isEmpty) return const [];

    final assets = await fetchAssets();
    final visibleAssets = assets
        .where((asset) => !asset.isHidden)
        .toList(growable: false);
    final visibleAssetIds = visibleAssets
        .map((asset) => asset.id)
        .whereType<int>()
        .toSet();
    final visibleHoldingIds = visibleAssets
        .expand((asset) => asset.visibleHoldings)
        .map((holding) => holding.id)
        .whereType<int>()
        .toSet();
    final visibleAssetTitles = visibleAssets
        .map((asset) => _normalizeSnapshotLookupText(asset.displayName))
        .where((title) => title.isNotEmpty)
        .toSet();
    final visibleHoldingKeys = visibleAssets
        .expand(
          (asset) => asset.visibleHoldings.map(
            (holding) =>
                '${_normalizeSnapshotLookupText(holding.name)}|${_normalizeSnapshotLookupText(holding.symbol)}',
          ),
        )
        .where((key) => key != '|')
        .toSet();
    final visibleHoldingNames = visibleAssets
        .expand(
          (asset) => asset.visibleHoldings.map(
            (holding) => _normalizeSnapshotLookupText(holding.name),
          ),
        )
        .where((name) => name.isNotEmpty)
        .toSet();

    final rows = await fetchPortfolioSnapshotHoldingItemsByDates(snapshotDates);
    return rows
        .where((row) {
          final assetId = row.assetId;
          final assetTitle = _normalizeSnapshotLookupText(row.assetTitle);
          final assetMatches =
              assetId != null && visibleAssetIds.contains(assetId) ||
              assetTitle.isNotEmpty && visibleAssetTitles.contains(assetTitle);
          if (!assetMatches) {
            return false;
          }
          final holdingId = row.holdingId;
          if (holdingId != null && visibleHoldingIds.contains(holdingId)) {
            return true;
          }
          final holdingKey =
              '${_normalizeSnapshotLookupText(row.holdingName)}|${_normalizeSnapshotLookupText(row.holdingSymbol)}';
          final holdingName = _normalizeSnapshotLookupText(row.holdingName);
          return holdingKey != '|' && visibleHoldingKeys.contains(holdingKey) ||
              holdingName.isNotEmpty &&
                  visibleHoldingNames.contains(holdingName);
        })
        .toList(growable: false);
  }

  Future<List<DailyPortfolioSnapshotItem>>
  fetchDisplayPortfolioSnapshotItemsByDates(List<String> snapshotDates) async {
    if (snapshotDates.isEmpty) return const [];

    final assets = await fetchAssets();
    final visibleAssets = assets
        .where((asset) => !asset.isHidden)
        .toList(growable: false);
    final visibleAssetIds = visibleAssets
        .map((asset) => asset.id)
        .whereType<int>()
        .toSet();
    final visibleManualAssetIds = visibleAssets
        .where((asset) => asset.id != null && asset.holdings.isEmpty)
        .map((asset) => asset.id!)
        .toSet();
    final visibleAssetTitles = visibleAssets
        .map((asset) => _normalizeSnapshotLookupText(asset.displayName))
        .where((title) => title.isNotEmpty)
        .toSet();
    final visibleHoldingIds = visibleAssets
        .expand((asset) => asset.visibleHoldings)
        .map((holding) => holding.id)
        .whereType<int>()
        .toSet();
    final visibleHoldingKeys = visibleAssets
        .expand(
          (asset) => asset.visibleHoldings.map(
            (holding) =>
                '${_normalizeSnapshotLookupText(holding.name)}|${_normalizeSnapshotLookupText(holding.symbol)}',
          ),
        )
        .where((key) => key != '|')
        .toSet();
    final visibleHoldingNames = visibleAssets
        .expand(
          (asset) => asset.visibleHoldings.map(
            (holding) => _normalizeSnapshotLookupText(holding.name),
          ),
        )
        .where((name) => name.isNotEmpty)
        .toSet();
    final assetById = {
      for (final asset in assets)
        if (asset.id != null) asset.id!: asset,
    };
    final assetByTitle = {
      for (final asset in assets)
        _normalizeSnapshotLookupText(asset.displayName): asset,
    };

    final snapshots = await (select(
      dailyPortfolioSnapshots,
    )..where((table) => table.snapshotDate.isIn(snapshotDates))).get();
    if (snapshots.isEmpty) return const [];

    final snapshotDateById = {
      for (final snapshot in snapshots) snapshot.id: snapshot.snapshotDate,
    };
    final assetRows = await fetchPortfolioSnapshotItemsByDates(snapshotDates);
    final holdingRows = await fetchPortfolioSnapshotHoldingItemsByDates(
      snapshotDates,
    );
    final groupedRows = <String, DailyPortfolioSnapshotItem>{};
    var syntheticId = -1;

    for (final holding in holdingRows) {
      final holdingId = holding.holdingId;
      final assetId = holding.assetId;
      final holdingKey =
          '${_normalizeSnapshotLookupText(holding.holdingName)}|${_normalizeSnapshotLookupText(holding.holdingSymbol)}';
      final assetTitleKey = _normalizeSnapshotLookupText(holding.assetTitle);
      final assetMatches =
          assetId != null && visibleAssetIds.contains(assetId) ||
          assetTitleKey.isNotEmpty &&
              visibleAssetTitles.contains(assetTitleKey);
      final holdingMatches =
          holdingId != null && visibleHoldingIds.contains(holdingId) ||
          holdingKey != '|' && visibleHoldingKeys.contains(holdingKey) ||
          _normalizeSnapshotLookupText(holding.holdingName).isNotEmpty &&
              visibleHoldingNames.contains(
                _normalizeSnapshotLookupText(holding.holdingName),
              );
      if (!assetMatches || !holdingMatches) {
        continue;
      }
      final asset = assetId == null ? null : assetById[assetId];
      final matchedAsset = asset ?? assetByTitle[assetTitleKey];
      final assetTitle = matchedAsset?.displayName ?? holding.assetTitle;
      final resolvedAssetId = matchedAsset?.id ?? assetId;

      final key = '${holding.snapshotId}:${resolvedAssetId ?? assetTitleKey}';
      final existing = groupedRows[key];
      final nextPurchase =
          (existing?.totalPurchaseAmount ?? 0) + holding.totalPurchaseAmount;
      final nextValuation =
          (existing?.totalValuationAmount ?? 0) + holding.totalValuationAmount;
      final nextProfit = nextValuation - nextPurchase;
      final nextHoldingCount = (existing?.holdingCount ?? 0) + 1;

      groupedRows[key] = DailyPortfolioSnapshotItem(
        id: existing?.id ?? syntheticId--,
        snapshotId: holding.snapshotId,
        assetId: resolvedAssetId ?? -1,
        assetTitle: assetTitle,
        totalPurchaseAmount: nextPurchase,
        totalValuationAmount: nextValuation,
        profitAmount: nextProfit,
        profitRate: nextPurchase == 0 ? 0 : (nextProfit / nextPurchase) * 100,
        holdingCount: nextHoldingCount,
      );
    }

    final results = <DailyPortfolioSnapshotItem>[];
    final representedAssetKeys = {
      for (final row in results) '${row.snapshotId}:${row.assetId}',
    };

    for (final row in assetRows) {
      final assetTitleKey = _normalizeSnapshotLookupText(row.assetTitle);
      final asset = assetById[row.assetId];
      final matchedAsset = asset ?? assetByTitle[assetTitleKey];
      if (matchedAsset == null || matchedAsset.isHidden) continue;
      final resolvedAssetId = matchedAsset.id ?? row.assetId;
      final representedKey = '${row.snapshotId}:$resolvedAssetId';
      final isVisibleManualAsset =
          visibleManualAssetIds.contains(row.assetId) ||
          assetTitleKey.isNotEmpty &&
              visibleAssetTitles.contains(assetTitleKey) &&
              matchedAsset.holdings.isEmpty;
      final isMissingFromDisplayedHoldings = !representedAssetKeys.contains(
        representedKey,
      );
      if (!isVisibleManualAsset && !isMissingFromDisplayedHoldings) continue;
      results.add(
        row.copyWith(
          assetId: resolvedAssetId,
          assetTitle: matchedAsset.displayName,
        ),
      );
      representedAssetKeys.add(representedKey);
    }

    for (final row in groupedRows.values) {
      final key = '${row.snapshotId}:${row.assetId}';
      if (representedAssetKeys.contains(key)) continue;
      results.add(row);
      representedAssetKeys.add(key);
    }

    final deduplicated = <String, DailyPortfolioSnapshotItem>{};
    for (final row in results) {
      final key = '${row.snapshotId}:${row.assetId}';
      final existing = deduplicated[key];
      if (existing == null) {
        deduplicated[key] = row;
        continue;
      }

      final existingTitle = existing.assetTitle.trim();
      final nextTitle = row.assetTitle.trim();
      if (existingTitle.isEmpty && nextTitle.isNotEmpty) {
        deduplicated[key] = row;
        continue;
      }
      if (existing.holdingCount < row.holdingCount) {
        deduplicated[key] = row;
      }
    }

    final finalResults = deduplicated.values
        .where((row) => row.assetTitle.trim().isNotEmpty)
        .toList(growable: false);

    finalResults.sort((a, b) {
      final dateA = snapshotDateById[a.snapshotId] ?? '';
      final dateB = snapshotDateById[b.snapshotId] ?? '';
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      return a.assetTitle.compareTo(b.assetTitle);
    });

    return finalResults;
  }

  Future<String> fetchSnapshotNote(String snapshotDate) async {
    final result = await customSelect(
      'SELECT note FROM snapshot_notes WHERE snapshot_date = ? LIMIT 1',
      variables: [Variable.withString(snapshotDate)],
      readsFrom: {},
    ).getSingleOrNull();

    return result?.data['note'] as String? ?? '';
  }

  Future<void> saveSnapshotNote({
    required String snapshotDate,
    required String note,
  }) async {
    await customStatement(
      '''
      INSERT INTO snapshot_notes (snapshot_date, note)
      VALUES (?, ?)
      ON CONFLICT(snapshot_date) DO UPDATE SET note = excluded.note
      ''',
      [snapshotDate, note],
    );
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _normalizeSnapshotLookupText(String value) {
    return value.trim().toLowerCase();
  }

  double _readDouble(dynamic value, [double fallback = 0]) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((row) => row.map((key, rowValue) => MapEntry('$key', rowValue)))
        .toList(growable: false);
  }

  Future<Map<int, double>> fetchAssetAllocationTargets() async {
    final rows = await select(assetAllocationTargets).get();
    return {for (final row in rows) row.assetId: row.targetRatio};
  }

  Future<Set<String>> fetchTransactionDates() async {
    final rows =
        await (selectOnly(transactionEvents)
              ..addColumns([transactionEvents.occurredAt])
              ..where(
                transactionEvents.deletedAt.isNull() &
                    transactionEvents.source.equals('snapshot_restore').not(),
              ))
            .get();

    return {
      ...rows
          .map((row) => row.read(transactionEvents.occurredAt))
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .map(_normalizeStoredDateKey),
    };
  }

  Future<void> _ensureCashTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS cash_accounts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL REFERENCES assets(id),
        client_id TEXT,
        dirty INTEGER NOT NULL DEFAULT 0,
        last_modified_at TEXT,
        hidden INTEGER NOT NULL DEFAULT 0,
        currency_code TEXT NOT NULL DEFAULT 'KRW',
        name TEXT NOT NULL,
        base_balance REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    if (!await _columnExists('cash_accounts', 'base_balance')) {
      await customStatement(
        "ALTER TABLE cash_accounts ADD COLUMN base_balance REAL NOT NULL DEFAULT 0",
      );
      await _backfillCashAccountBaseBalances();
    }
    if (!await _columnExists('cash_accounts', 'client_id')) {
      await customStatement(
        'ALTER TABLE cash_accounts ADD COLUMN client_id TEXT',
      );
    }
    if (!await _columnExists('cash_accounts', 'dirty')) {
      await customStatement(
        'ALTER TABLE cash_accounts ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!await _columnExists('cash_accounts', 'last_modified_at')) {
      await customStatement(
        'ALTER TABLE cash_accounts ADD COLUMN last_modified_at TEXT',
      );
    }
    await customStatement('''
      CREATE TABLE IF NOT EXISTS cash_transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL REFERENCES assets(id),
        cash_account_id INTEGER NOT NULL REFERENCES cash_accounts(id),
        client_id TEXT,
        dirty INTEGER NOT NULL DEFAULT 0,
        last_modified_at TEXT,
        linked_transaction_id INTEGER REFERENCES cash_transactions(id),
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        amount TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    if (!await _columnExists('cash_transactions', 'linked_transaction_id')) {
      await customStatement(
        'ALTER TABLE cash_transactions ADD COLUMN linked_transaction_id INTEGER',
      );
    }
    if (!await _columnExists('cash_transactions', 'client_id')) {
      await customStatement(
        'ALTER TABLE cash_transactions ADD COLUMN client_id TEXT',
      );
    }
    if (!await _columnExists('cash_transactions', 'dirty')) {
      await customStatement(
        'ALTER TABLE cash_transactions ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!await _columnExists('cash_transactions', 'last_modified_at')) {
      await customStatement(
        'ALTER TABLE cash_transactions ADD COLUMN last_modified_at TEXT',
      );
    }
    if (!await _columnExists('cash_accounts', 'deleted_at')) {
      await customStatement(
        'ALTER TABLE cash_accounts ADD COLUMN deleted_at TEXT',
      );
    }
    if (!await _columnExists('cash_transactions', 'deleted_at')) {
      await customStatement(
        'ALTER TABLE cash_transactions ADD COLUMN deleted_at TEXT',
      );
    }
  }

  Future<void> _ensureNewsCacheTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS market_news_caches (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL UNIQUE,
        found INTEGER NOT NULL DEFAULT 0,
        summary_date TEXT,
        model TEXT,
        news_count INTEGER,
        summary_json TEXT,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS company_news_caches (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        symbol TEXT NOT NULL UNIQUE,
        found INTEGER NOT NULL DEFAULT 0,
        summary_date TEXT,
        model TEXT,
        news_count INTEGER,
        summary_json TEXT,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensurePortfolioDiagnosisCacheTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS portfolio_diagnosis_caches (
        payload_key TEXT NOT NULL PRIMARY KEY,
        diagnosis_json TEXT NOT NULL,
        model TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateLegacyCashHoldingsToCashAccounts() async {
    final cashAssetRows = await (select(
      assets,
    )..where((table) => table.assetType.equals('현금'))).get();
    final cashAssetIds = cashAssetRows
        .map((row) => row.id)
        .toList(growable: false);
    if (cashAssetIds.isEmpty) return;

    final legacyHoldings = await (select(
      holdings,
    )..where((table) => table.assetId.isIn(cashAssetIds))).get();
    if (legacyHoldings.isEmpty) return;

    await transaction(() async {
      for (final holding in legacyHoldings) {
        final unitPrice = holding.currentPrice != 0
            ? holding.currentPrice
            : (holding.averagePrice != 0 ? holding.averagePrice : 1.0);
        final balance = holding.quantity * unitPrice;

        final insertedCashAccountId = await customInsert(
          '''
          INSERT INTO cash_accounts
          (asset_id, client_id, hidden, currency_code, name, base_balance, balance, note, sort_order)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withInt(holding.assetId),
            Variable.withString(_uuid.v4()),
            Variable.withInt(holding.hidden ? 1 : 0),
            Variable.withString(holding.currencyCode),
            Variable.withString(holding.name),
            Variable.withReal(balance),
            Variable.withReal(balance),
            Variable.withString(holding.note),
            Variable.withInt(holding.sortOrder),
          ],
        );

        final legacyTransactions = await (select(
          transactions,
        )..where((table) => table.holdingId.equals(holding.id))).get();
        for (final tx in legacyTransactions) {
          final amountText = tx.amount.trim().isNotEmpty
              ? tx.amount
              : _formatPlainNumber(_parseTransactionNumber(tx.quantity));
          await customInsert(
            '''
            INSERT INTO cash_transactions
            (asset_id, cash_account_id, client_id, date, type, name, amount, sort_order)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            variables: [
              Variable.withInt(tx.assetId ?? holding.assetId),
              Variable.withInt(insertedCashAccountId),
              Variable.withString(_uuid.v4()),
              Variable.withString(tx.date),
              Variable.withString(tx.type),
              Variable.withString(tx.name),
              Variable.withString(amountText),
              Variable.withInt(tx.sortOrder),
            ],
          );
        }
      }

      await (delete(transactions)..where(
            (table) =>
                table.holdingId.isIn(legacyHoldings.map((e) => e.id).toList()),
          ))
          .go();
      await (delete(holdings)..where(
            (table) => table.id.isIn(legacyHoldings.map((e) => e.id).toList()),
          ))
          .go();
    });
  }

  Future<void> _backfillCashAccountBaseBalances() async {
    final accountRows = await customSelect(
      'SELECT id, balance FROM cash_accounts',
    ).get();

    for (final accountRow in accountRows) {
      final cashAccountId = accountRow.read<int>('id');
      final currentBalance =
          (accountRow.data['balance'] as num?)?.toDouble() ?? 0.0;
      final transactionRows = await customSelect(
        '''
        SELECT type, amount
        FROM cash_transactions
        WHERE cash_account_id = ?
        ORDER BY date ASC, sort_order ASC, id ASC
        ''',
        variables: [Variable.withInt(cashAccountId)],
      ).get();

      var transactionDelta = 0.0;
      for (final row in transactionRows) {
        final amount = _parseTransactionNumber(row.read<String>('amount'));
        switch (_normalizeTransactionType(row.read<String>('type'))) {
          case '입금':
          case '매도':
            transactionDelta += amount;
            break;
          case '출금':
          case '매수':
            transactionDelta -= amount;
            break;
          case '환전':
          case '이체':
            transactionDelta += amount;
            break;
        }
      }

      final baseBalance = currentBalance - transactionDelta;
      await customStatement(
        'UPDATE cash_accounts SET base_balance = ? WHERE id = ?',
        [baseBalance, cashAccountId],
      );
    }
  }

  Future<void> saveAssetAllocationTargets(Map<int, double> targets) async {
    await transaction(() async {
      await delete(assetAllocationTargets).go();

      for (final entry in targets.entries) {
        await into(assetAllocationTargets).insert(
          AssetAllocationTargetsCompanion.insert(
            assetId: entry.key,
            targetRatio: entry.value,
          ),
        );
      }
    });
  }

  Future<double?> fetchLatestExchangeRate({
    String currencyPair = 'USD/KRW',
  }) async {
    final row =
        await (select(exchangeRates)
              ..where((table) => table.currencyPair.equals(currencyPair))
              ..orderBy([(table) => OrderingTerm.desc(table.recordedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.rate;
  }

  Future<void> saveExchangeRate({
    required String currencyPair,
    required double rate,
    String source = 'manual',
    String? recordedAt,
  }) async {
    await into(exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        currencyPair: currencyPair,
        rate: rate,
        recordedAt: recordedAt ?? DateTime.now().toIso8601String(),
        source: Value(source),
      ),
    );
  }

  Future<void> removeLegacySeededCashHoldings() async {
    const legacyNames = ['생활비 통장', '예비자금'];

    await transaction(() async {
      final legacyHoldingRows = await (select(
        holdings,
      )..where((table) => table.name.isIn(legacyNames))).get();
      final legacyHoldingIds = legacyHoldingRows.map((row) => row.id).toList();

      if (legacyHoldingIds.isNotEmpty) {
        await (delete(
          transactions,
        )..where((table) => table.holdingId.isIn(legacyHoldingIds))).go();
        await (delete(
          holdings,
        )..where((table) => table.id.isIn(legacyHoldingIds))).go();
      }

      await (delete(
        transactions,
      )..where((table) => table.name.isIn(legacyNames))).go();
    });
  }

  Future<void> clearAllLocalUserData() async {
    await transaction(() async {
      await delete(companyNewsCaches).go();
      await delete(marketNewsCaches).go();
      if (await _tableExists('portfolio_diagnosis_caches')) {
        await customStatement('DELETE FROM portfolio_diagnosis_caches');
      }
      if (await _tableExists('snapshot_notes')) {
        await customStatement('DELETE FROM snapshot_notes');
      }
      if (await _tableExists('daily_portfolio_snapshot_cash_accounts')) {
        await customStatement(
          'DELETE FROM daily_portfolio_snapshot_cash_accounts',
        );
      }
      await delete(dailyPortfolioSnapshotHoldingItems).go();
      await delete(dailyPortfolioSnapshotItems).go();
      await delete(dailyPortfolioSnapshots).go();
      await delete(assetAllocationTargets).go();
      await delete(transactionLines).go();
      await delete(transactionEvents).go();
      await delete(cashTransactions).go();
      await delete(cashAccounts).go();
      await delete(transactions).go();
      await delete(holdings).go();
      await delete(assets).go();
      await delete(exchangeRates).go();
    });
  }

  Future<void> saveMarketNewsCache({
    required String category,
    required bool found,
    required String? summaryDate,
    required String? model,
    required int? newsCount,
    required Map<String, dynamic>? summary,
    required String? createdAt,
    required String? updatedAt,
  }) async {
    await transaction(() async {
      // Older local schemas may have allowed duplicate categories, so replace
      // any existing rows explicitly before saving the latest payload.
      await (delete(
        marketNewsCaches,
      )..where((table) => table.category.equals(category))).go();
      await into(marketNewsCaches).insert(
        MarketNewsCachesCompanion.insert(
          category: category,
          found: Value(found),
          summaryDate: Value(summaryDate),
          model: Value(model),
          newsCount: Value(newsCount),
          summaryJson: Value(summary == null ? null : jsonEncode(summary)),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          cachedAt: _syncTimestamp(),
        ),
      );
    });
  }

  Future<Map<String, dynamic>?> fetchMarketNewsCache({
    String category = 'general',
  }) async {
    final row =
        await (select(marketNewsCaches)
              ..where((table) => table.category.equals(category))
              ..orderBy([
                (table) => OrderingTerm.desc(table.cachedAt),
                (table) => OrderingTerm.desc(table.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return <String, dynamic>{
      'category': row.category,
      'found': row.found,
      'summary_date': row.summaryDate,
      'model': row.model,
      'news_count': row.newsCount,
      'summary': row.summaryJson == null
          ? null
          : jsonDecode(row.summaryJson!) as Map<String, dynamic>,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'cached_at': row.cachedAt,
    };
  }

  Future<void> replaceCompanyNewsCaches(
    List<Map<String, dynamic>> items,
  ) async {
    await transaction(() async {
      await delete(companyNewsCaches).go();
      for (final item in items) {
        await into(companyNewsCaches).insert(
          CompanyNewsCachesCompanion.insert(
            symbol: '${item['symbol'] ?? ''}',
            found: Value(item['found'] == true),
            summaryDate: Value(item['summary_date']?.toString()),
            model: Value(item['model']?.toString()),
            newsCount: Value(
              item['news_count'] is num
                  ? (item['news_count'] as num).toInt()
                  : int.tryParse('${item['news_count'] ?? ''}'),
            ),
            summaryJson: Value(
              item['summary'] is Map ? jsonEncode(item['summary']) : null,
            ),
            createdAt: Value(item['created_at']?.toString()),
            updatedAt: Value(item['updated_at']?.toString()),
            cachedAt: _syncTimestamp(),
          ),
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchCompanyNewsCaches() async {
    final rows = await (select(
      companyNewsCaches,
    )..orderBy([(table) => OrderingTerm.asc(table.symbol)])).get();
    return rows
        .map(
          (row) => <String, dynamic>{
            'symbol': row.symbol,
            'found': row.found,
            'summary_date': row.summaryDate,
            'model': row.model,
            'news_count': row.newsCount,
            'summary': row.summaryJson == null
                ? null
                : jsonDecode(row.summaryJson!) as Map<String, dynamic>,
            'created_at': row.createdAt,
            'updated_at': row.updatedAt,
            'cached_at': row.cachedAt,
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, String>> fetchVisibleHoldingSymbolAssetTypes() async {
    final rows = await customSelect('''
      SELECT UPPER(TRIM(h.symbol)) AS symbol, a.asset_type AS asset_type
      FROM holdings h
      INNER JOIN assets a ON a.id = h.asset_id
	      WHERE h.deleted_at IS NULL
	        AND a.deleted_at IS NULL
	        AND h.hidden = 0
	        AND a.hidden = 0
	        AND h.quantity > 0
	        AND TRIM(COALESCE(h.symbol, '')) <> ''
	      ''').get();

    final symbolAssetTypeMap = <String, String>{};
    for (final row in rows) {
      final symbol = (row.read<String?>('symbol') ?? '').trim().toUpperCase();
      final assetType = (row.read<String?>('asset_type') ?? '').trim();
      if (symbol.isEmpty) continue;

      if (assetType == '코인') {
        symbolAssetTypeMap[symbol] = '코인';
      } else if (!symbolAssetTypeMap.containsKey(symbol)) {
        symbolAssetTypeMap[symbol] = assetType.isEmpty ? '주식' : assetType;
      }
    }

    return symbolAssetTypeMap;
  }

  Future<void> savePortfolioDiagnosisCache({
    required String payloadKey,
    required Map<String, dynamic> diagnosis,
    String? model,
  }) async {
    await _ensurePortfolioDiagnosisCacheTable();
    await customStatement(
      '''
      INSERT INTO portfolio_diagnosis_caches (payload_key, diagnosis_json, model, cached_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(payload_key) DO UPDATE SET
        diagnosis_json = excluded.diagnosis_json,
        model = excluded.model,
        cached_at = excluded.cached_at
      ''',
      [payloadKey, jsonEncode(diagnosis), model, _syncTimestamp()],
    );
  }

  Future<Map<String, dynamic>?> fetchPortfolioDiagnosisCache({
    required String payloadKey,
  }) async {
    await _ensurePortfolioDiagnosisCacheTable();
    final row = await customSelect(
      '''
      SELECT diagnosis_json, model, cached_at
      FROM portfolio_diagnosis_caches
      WHERE payload_key = ?
      LIMIT 1
      ''',
      variables: [Variable.withString(payloadKey)],
      readsFrom: {},
    ).getSingleOrNull();
    if (row == null) return null;

    final diagnosisJson = row.read<String?>('diagnosis_json');
    if (diagnosisJson == null || diagnosisJson.trim().isEmpty) return null;

    final decoded = jsonDecode(diagnosisJson);
    if (decoded is! Map) return null;
    return {
      'diagnosis': Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry('$key', value)),
      ),
      'model': row.read<String?>('model'),
      'cached_at': row.read<String?>('cached_at'),
    };
  }

  Future<Map<String, Object?>> buildDirtySyncPayload() async {
    final dirtyAssetRows = await (select(
      assets,
    )..where((table) => table.dirty.equals(true))).get();
    final dirtyHoldingRows = await (select(
      holdings,
    )..where((table) => table.dirty.equals(true))).get();
    final dirtyCashAccountRows = await (select(
      cashAccounts,
    )..where((table) => table.dirty.equals(true))).get();
    final dirtyTransactionEventRows = await (select(
      transactionEvents,
    )..where((table) => table.dirty.equals(true))).get();
    final dirtyTransactionLineRows = await (select(
      transactionLines,
    )..where((table) => table.dirty.equals(true))).get();

    final assetClientIdById = {
      for (final row in await select(assets).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.id: row.clientId!,
    };
    final holdingClientIdById = {
      for (final row in await select(holdings).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.id: row.clientId!,
    };
    final cashAccountClientIdById = {
      for (final row in await select(cashAccounts).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.id: row.clientId!,
    };
    final transactionEventClientIdById = {
      for (final row in await select(transactionEvents).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.id: row.clientId!,
    };

    final assetRows = dirtyAssetRows
        .where((row) => row.clientId != null && row.clientId!.isNotEmpty)
        .map(
          (row) => <String, Object?>{
            'client_id': row.clientId,
            'last_modified_at': row.lastModifiedAt ?? _syncTimestamp(),
            'deleted_at': row.deletedAt,
            'asset_type': row.assetType,
            'title': row.title,
            'alias': row.alias,
            'currency_code': row.currencyCode,
            'value': row.value,
            'change': row.change,
            'icon_code_point': row.iconCodePoint,
            'quantity_label': row.quantityLabel,
            'quantity_value': row.quantityValue,
            'average_label': row.averageLabel,
            'average_value': row.averageValue,
            'note': row.note,
            'sort_order': row.sortOrder,
          },
        )
        .toList(growable: false);

    final holdingRows = dirtyHoldingRows
        .where((row) => row.clientId != null && row.clientId!.isNotEmpty)
        .map((row) {
          final assetClientId = assetClientIdById[row.assetId];
          if (assetClientId == null || assetClientId.isEmpty) {
            return null;
          }
          return <String, Object?>{
            'client_id': row.clientId,
            'last_modified_at': row.lastModifiedAt ?? _syncTimestamp(),
            'asset_client_id': assetClientId,
            'deleted_at': row.deletedAt,
            'currency_code': row.currencyCode,
            'market_updated_at': row.marketUpdatedAt,
            'exchange_code': row.exchangeCode,
            'name': row.name,
            'symbol': row.symbol,
            'quantity': row.quantity,
            'average_price': row.averagePrice,
            'current_price': row.currentPrice,
            'note': row.note,
            'sort_order': row.sortOrder,
          };
        })
        .whereType<Map<String, Object?>>()
        .toList(growable: false);

    final cashAccountRows = dirtyCashAccountRows
        .where((row) => row.clientId != null && row.clientId!.isNotEmpty)
        .map((row) {
          final assetClientId = assetClientIdById[row.assetId];
          if (assetClientId == null || assetClientId.isEmpty) {
            return null;
          }
          return <String, Object?>{
            'client_id': row.clientId,
            'last_modified_at': row.lastModifiedAt ?? _syncTimestamp(),
            'asset_client_id': assetClientId,
            'deleted_at': row.deletedAt,
            'currency_code': row.currencyCode,
            'name': row.name,
            'base_balance': row.baseBalance,
            'balance': row.balance,
            'note': row.note,
            'sort_order': row.sortOrder,
          };
        })
        .whereType<Map<String, Object?>>()
        .toList(growable: false);

    final transactionEventRows = dirtyTransactionEventRows
        .where((row) => row.clientId != null && row.clientId!.isNotEmpty)
        .map(
          (row) => <String, Object?>{
            'client_id': row.clientId,
            'last_modified_at': row.lastModifiedAt ?? _syncTimestamp(),
            'deleted_at': row.deletedAt,
            'occurred_at': row.occurredAt,
            'kind': row.kind,
            'title': row.title,
            'memo': row.memo,
            'source': row.source,
            'flow_category': row.flowCategory,
            'legacy_source_table': row.legacySourceTable,
            'legacy_source_id': row.legacySourceId,
            'sort_order': row.sortOrder,
          },
        )
        .toList(growable: false);

    final transactionLineRows = dirtyTransactionLineRows
        .where((row) => row.clientId != null && row.clientId!.isNotEmpty)
        .map((row) {
          final eventClientId = transactionEventClientIdById[row.eventId];
          final assetClientId = row.assetId == null
              ? null
              : assetClientIdById[row.assetId!];
          final holdingClientId = row.holdingId == null
              ? null
              : holdingClientIdById[row.holdingId!];
          final cashAccountClientId = row.cashAccountId == null
              ? null
              : cashAccountClientIdById[row.cashAccountId!];
          if (eventClientId == null || eventClientId.isEmpty) return null;
          if (row.assetId != null &&
              (assetClientId == null || assetClientId.isEmpty)) {
            return null;
          }
          if (row.holdingId != null &&
              (holdingClientId == null || holdingClientId.isEmpty)) {
            return null;
          }
          if (row.cashAccountId != null &&
              (cashAccountClientId == null || cashAccountClientId.isEmpty)) {
            return null;
          }
          return <String, Object?>{
            'client_id': row.clientId,
            'last_modified_at': row.lastModifiedAt ?? _syncTimestamp(),
            'event_client_id': eventClientId,
            'asset_client_id': assetClientId,
            'holding_client_id': holdingClientId,
            'cash_account_client_id': cashAccountClientId,
            'deleted_at': row.deletedAt,
            'legacy_source_table': row.legacySourceTable,
            'legacy_source_id': row.legacySourceId,
            'action': row.action,
            'currency_code': row.currencyCode,
            'quantity_delta': row.quantityDelta,
            'cash_delta': row.cashDelta,
            'unit_price': row.unitPrice,
            'gross_amount': row.grossAmount,
            'fee_amount': row.feeAmount,
            'tax_amount': row.taxAmount,
            'cost_basis_delta': row.costBasisDelta,
            'realized_pnl': row.realizedPnl,
            'fx_rate': row.fxRate,
            'sort_order': row.sortOrder,
          };
        })
        .whereType<Map<String, Object?>>()
        .toList(growable: false);

    return {
      'payload_version': 4,
      'schema_mode': 'ledger_only_delta',
      'assets': assetRows,
      'holdings': holdingRows,
      'cash_accounts': cashAccountRows,
      'transaction_events': transactionEventRows,
      'transaction_lines': transactionLineRows,
    };
  }

  Future<void> markDirtySyncPayloadAsSynced(
    Map<String, Object?> payload,
    Map<String, Object?>? acceptedClientIds,
  ) async {
    await transaction(() async {
      await _clearDirtyByClientIds(
        'assets',
        _acceptedOrPayloadClientIds(acceptedClientIds, payload, 'assets'),
      );
      await _clearDirtyByClientIds(
        'holdings',
        _acceptedOrPayloadClientIds(acceptedClientIds, payload, 'holdings'),
      );
      await _clearDirtyByClientIds(
        'cash_accounts',
        _acceptedOrPayloadClientIds(
          acceptedClientIds,
          payload,
          'cash_accounts',
        ),
      );
      await _clearDirtyByClientIds(
        'transaction_events',
        _acceptedOrPayloadClientIds(
          acceptedClientIds,
          payload,
          'transaction_events',
        ),
      );
      await _clearDirtyByClientIds(
        'transaction_lines',
        _acceptedOrPayloadClientIds(
          acceptedClientIds,
          payload,
          'transaction_lines',
        ),
      );
    });
  }

  List<String> _acceptedOrPayloadClientIds(
    Map<String, Object?>? acceptedClientIds,
    Map<String, Object?> payload,
    String key,
  ) {
    final accepted = acceptedClientIds?[key];
    if (accepted is List) {
      return accepted
          .map((value) => value?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    return _payloadClientIds(payload[key]);
  }

  List<String> _payloadClientIds(Object? rawRows) {
    if (rawRows is! List) return const [];
    return rawRows
        .whereType<Map>()
        .map((row) => row['client_id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _clearDirtyByClientIds(
    String tableName,
    List<String> clientIds,
  ) async {
    if (clientIds.isEmpty) return;
    final placeholders = List.filled(clientIds.length, '?').join(', ');
    await customStatement(
      'UPDATE $tableName SET dirty = 0 WHERE client_id IN ($placeholders)',
      clientIds,
    );
  }

  Future<void> replaceLocalSyncData(Map<String, dynamic> payload) async {
    final rawAssets = (payload['assets'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
    final rawHoldings = (payload['holdings'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
    final rawTransactions = (payload['transactions'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
    final rawCashAccounts = (payload['cash_accounts'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
    final rawCashTransactions =
        (payload['cash_transactions'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((key, value) => MapEntry('$key', value)))
            .toList(growable: false);
    final rawTransactionEvents =
        (payload['transaction_events'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((key, value) => MapEntry('$key', value)))
            .toList(growable: false);
    final rawTransactionLines =
        (payload['transaction_lines'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => row.map((key, value) => MapEntry('$key', value)))
            .toList(growable: false);

    final localAssetHiddenByClientId = {
      for (final row in await select(assets).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.clientId!: row.hidden,
    };
    final localHoldingHiddenByClientId = {
      for (final row in await select(holdings).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.clientId!: row.hidden,
    };
    final localCashAccountHiddenByClientId = {
      for (final row in await select(cashAccounts).get())
        if (row.clientId != null && row.clientId!.isNotEmpty)
          row.clientId!: row.hidden,
    };

    await transaction(() async {
      await delete(transactionLines).go();
      await delete(transactionEvents).go();
      await delete(cashTransactions).go();
      await delete(transactions).go();
      await delete(cashAccounts).go();
      await delete(holdings).go();
      await delete(assets).go();

      final assetIdByClientId = <String, int>{};
      for (final row in rawAssets) {
        final clientId = _nullableString(row['client_id']);
        final insertedId = await into(assets).insert(
          AssetsCompanion.insert(
            clientId: Value(clientId),
            lastModifiedAt: Value(_nullableString(row['last_modified_at'])),
            assetType: Value(_stringValue(row['asset_type'], '주식')),
            title: _stringValue(row['title'], ''),
            alias: Value(_stringValue(row['alias'], '')),
            hidden: Value(localAssetHiddenByClientId[clientId] ?? false),
            currencyCode: Value(_stringValue(row['currency_code'], 'KRW')),
            value: _stringValue(row['value'], ''),
            change: _stringValue(row['change'], ''),
            iconCodePoint: _intValue(row['icon_code_point']),
            quantityLabel: _stringValue(row['quantity_label'], ''),
            quantityValue: _stringValue(row['quantity_value'], ''),
            averageLabel: _stringValue(row['average_label'], ''),
            averageValue: _stringValue(row['average_value'], ''),
            note: _stringValue(row['note'], ''),
            sortOrder: _intValue(row['sort_order']),
          ),
        );
        if (clientId != null && clientId.isNotEmpty) {
          assetIdByClientId[clientId] = insertedId;
        }
      }

      final holdingIdByClientId = <String, int>{};
      for (final row in rawHoldings) {
        final assetClientId = _nullableString(row['asset_client_id']);
        final assetId = assetClientId == null
            ? null
            : assetIdByClientId[assetClientId];
        if (assetId == null) {
          continue;
        }

        final clientId = _nullableString(row['client_id']);
        final insertedId = await into(holdings).insert(
          HoldingsCompanion.insert(
            assetId: assetId,
            clientId: Value(clientId),
            lastModifiedAt: Value(_nullableString(row['last_modified_at'])),
            hidden: Value(localHoldingHiddenByClientId[clientId] ?? false),
            currencyCode: Value(_stringValue(row['currency_code'], 'KRW')),
            marketUpdatedAt: Value(_nullableString(row['market_updated_at'])),
            exchangeCode: Value(_stringValue(row['exchange_code'], '')),
            name: _stringValue(row['name'], ''),
            symbol: _stringValue(row['symbol'], ''),
            quantity: _doubleValue(row['quantity']),
            averagePrice: _doubleValue(row['average_price']),
            currentPrice: _doubleValue(row['current_price']),
            note: _stringValue(row['note'], ''),
            sortOrder: _intValue(row['sort_order']),
          ),
        );
        if (clientId != null && clientId.isNotEmpty) {
          holdingIdByClientId[clientId] = insertedId;
        }
      }

      for (final row in rawTransactions) {
        final assetClientId = _nullableString(row['asset_client_id']);
        final holdingClientId = _nullableString(row['holding_client_id']);
        final assetId = assetClientId == null
            ? null
            : assetIdByClientId[assetClientId];
        final holdingId = holdingClientId == null
            ? null
            : holdingIdByClientId[holdingClientId];

        final clientId = _nullableString(row['client_id']);
        await into(transactions).insert(
          TransactionsCompanion.insert(
            assetId: Value(assetId),
            holdingId: Value(holdingId),
            clientId: Value(clientId),
            date: _stringValue(row['date'], ''),
            type: _stringValue(row['type'], ''),
            name: _stringValue(row['name'], ''),
            amount: _stringValue(row['amount'], ''),
            quantity: _stringValue(row['quantity'], ''),
            unitPrice: Value(_doubleValue(row['unit_price'])),
            quantityValue: Value(_doubleValue(row['quantity_value'])),
            grossAmount: Value(_doubleValue(row['gross_amount'])),
            cashFlowAmount: Value(_doubleValue(row['cash_flow_amount'])),
            realizedProfitAmount: Value(
              _doubleValue(row['realized_profit_amount']),
            ),
            sortOrder: _intValue(row['sort_order']),
          ),
        );
      }

      final cashAccountIdByClientId = <String, int>{};
      for (final row in rawCashAccounts) {
        final assetClientId = _nullableString(row['asset_client_id']);
        final assetId = assetClientId == null
            ? null
            : assetIdByClientId[assetClientId];
        if (assetId == null) {
          continue;
        }

        final clientId = _nullableString(row['client_id']);
        final insertedId = await into(cashAccounts).insert(
          CashAccountsCompanion.insert(
            assetId: assetId,
            clientId: Value(clientId),
            lastModifiedAt: Value(_nullableString(row['last_modified_at'])),
            hidden: Value(localCashAccountHiddenByClientId[clientId] ?? false),
            currencyCode: Value(_stringValue(row['currency_code'], 'KRW')),
            name: _stringValue(row['name'], ''),
            baseBalance: Value(_doubleValue(row['base_balance'])),
            balance: Value(_doubleValue(row['balance'])),
            note: Value(_stringValue(row['note'], '')),
            sortOrder: Value(_intValue(row['sort_order'])),
          ),
        );
        if (clientId != null && clientId.isNotEmpty) {
          cashAccountIdByClientId[clientId] = insertedId;
        }
      }

      final cashTransactionIdByClientId = <String, int>{};
      final pendingCashTransactionLinks = <int, String>{};
      for (final row in rawCashTransactions) {
        final assetClientId = _nullableString(row['asset_client_id']);
        final cashAccountClientId = _nullableString(
          row['cash_account_client_id'],
        );
        final linkedTransactionClientId = _nullableString(
          row['linked_transaction_client_id'],
        );
        final assetId = assetClientId == null
            ? null
            : assetIdByClientId[assetClientId];
        final cashAccountId = cashAccountClientId == null
            ? null
            : cashAccountIdByClientId[cashAccountClientId];
        if (assetId == null || cashAccountId == null) {
          continue;
        }

        final clientId = _nullableString(row['client_id']);
        final insertedId = await into(cashTransactions).insert(
          CashTransactionsCompanion.insert(
            assetId: assetId,
            cashAccountId: cashAccountId,
            clientId: Value(clientId),
            date: _stringValue(row['date'], ''),
            type: _stringValue(row['type'], ''),
            name: _stringValue(row['name'], ''),
            amount: _stringValue(row['amount'], ''),
            amountValue: Value(_doubleValue(row['amount_value'])),
            cashFlowAmount: Value(_doubleValue(row['cash_flow_amount'])),
            sortOrder: Value(_intValue(row['sort_order'])),
          ),
        );
        if (clientId != null && clientId.isNotEmpty) {
          cashTransactionIdByClientId[clientId] = insertedId;
        }
        if (linkedTransactionClientId != null &&
            linkedTransactionClientId.isNotEmpty) {
          pendingCashTransactionLinks[insertedId] = linkedTransactionClientId;
        }
      }

      for (final entry in pendingCashTransactionLinks.entries) {
        final linkedId = cashTransactionIdByClientId[entry.value];
        if (linkedId == null) continue;
        await (update(
          cashTransactions,
        )..where((table) => table.id.equals(entry.key))).write(
          CashTransactionsCompanion(linkedTransactionId: Value(linkedId)),
        );
      }

      final transactionEventIdByClientId = <String, int>{};
      for (final row in rawTransactionEvents) {
        final clientId = _nullableString(row['client_id']);
        final insertedId = await into(transactionEvents).insert(
          TransactionEventsCompanion.insert(
            clientId: Value(clientId),
            lastModifiedAt: Value(_nullableString(row['last_modified_at'])),
            occurredAt: _stringValue(row['occurred_at'], ''),
            kind: _stringValue(row['kind'], 'adjustment'),
            title: Value(_stringValue(row['title'], '')),
            memo: Value(_stringValue(row['memo'], '')),
            source: Value(_stringValue(row['source'], 'manual')),
            flowCategory: Value(
              TransactionFlowCategory.normalize(
                _nullableString(row['flow_category']),
              ),
            ),
            legacySourceTable: Value(
              _nullableString(row['legacy_source_table']),
            ),
            legacySourceId: Value(
              row['legacy_source_id'] == null
                  ? null
                  : _intValue(row['legacy_source_id']),
            ),
            sortOrder: Value(_intValue(row['sort_order'])),
          ),
        );
        if (clientId != null && clientId.isNotEmpty) {
          transactionEventIdByClientId[clientId] = insertedId;
        }
      }

      for (final row in rawTransactionLines) {
        final eventClientId = _nullableString(row['event_client_id']);
        final assetClientId = _nullableString(row['asset_client_id']);
        final holdingClientId = _nullableString(row['holding_client_id']);
        final cashAccountClientId = _nullableString(
          row['cash_account_client_id'],
        );
        final eventId = eventClientId == null
            ? null
            : transactionEventIdByClientId[eventClientId];
        final assetId = assetClientId == null
            ? null
            : assetIdByClientId[assetClientId];
        final holdingId = holdingClientId == null
            ? null
            : holdingIdByClientId[holdingClientId];
        final cashAccountId = cashAccountClientId == null
            ? null
            : cashAccountIdByClientId[cashAccountClientId];
        if (eventId == null) continue;

        await into(transactionLines).insert(
          TransactionLinesCompanion.insert(
            eventId: eventId,
            assetId: Value(assetId),
            holdingId: Value(holdingId),
            cashAccountId: Value(cashAccountId),
            clientId: Value(_nullableString(row['client_id'])),
            lastModifiedAt: Value(_nullableString(row['last_modified_at'])),
            legacySourceTable: Value(
              _nullableString(row['legacy_source_table']),
            ),
            legacySourceId: Value(
              row['legacy_source_id'] == null
                  ? null
                  : _intValue(row['legacy_source_id']),
            ),
            action: _stringValue(row['action'], 'adjustment'),
            currencyCode: Value(_stringValue(row['currency_code'], 'KRW')),
            quantityDelta: Value(_doubleValue(row['quantity_delta'])),
            cashDelta: Value(_doubleValue(row['cash_delta'])),
            unitPrice: Value(_doubleValue(row['unit_price'])),
            grossAmount: Value(_doubleValue(row['gross_amount'])),
            feeAmount: Value(_doubleValue(row['fee_amount'])),
            taxAmount: Value(_doubleValue(row['tax_amount'])),
            costBasisDelta: Value(_doubleValue(row['cost_basis_delta'])),
            realizedPnl: Value(_doubleValue(row['realized_pnl'])),
            fxRate: Value(
              row['fx_rate'] == null ? null : _doubleValue(row['fx_rate']),
            ),
            sortOrder: Value(_intValue(row['sort_order'])),
          ),
        );
      }
    });

    // Remote payloads already carry calculation-ready state tables and
    // normalized ledger lines. Replaying legacy transaction tables here can
    // overwrite the just-imported server balances with old local semantics.
    if (rawTransactionEvents.isNotEmpty && rawTransactionLines.isNotEmpty) {
      final holdingRows = await select(holdings).get();
      for (final holding in holdingRows) {
        await _recalculateHoldingFromLedgerLines(holding.id, markDirty: false);
      }
      final cashAccountRows = await select(cashAccounts).get();
      for (final account in cashAccountRows) {
        await _recalculateCashAccountFromLedgerLines(
          account.id,
          markDirty: false,
        );
      }
    }
  }

  String _stringValue(Object? value, String fallback) {
    if (value == null) {
      return fallback;
    }
    final result = '$value';
    return result.isEmpty ? fallback : result;
  }

  String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }
    final result = '$value'.trim();
    return result.isEmpty ? null : result;
  }

  int _intValue(Object? value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }

  double _doubleValue(Object? value, [double fallback = 0]) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  Future<bool> _tableExists(String tableName) async {
    final row = await customSelect(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      variables: [Variable.withString('table'), Variable.withString(tableName)],
    ).getSingleOrNull();

    return row != null;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  Future<void> _backfillAllClientIds() async {
    await _backfillClientIdsForTable('assets');
    await _backfillClientIdsForTable('holdings');
    await _backfillClientIdsForTable('transactions');
    await _backfillClientIdsForTable('cash_accounts');
    await _backfillClientIdsForTable('cash_transactions');
    await _backfillClientIdsForTable('transaction_events');
    await _backfillClientIdsForTable('transaction_lines');
  }

  Future<void> _backfillClientIdsForTable(String tableName) async {
    if (!await _tableExists(tableName) ||
        !await _columnExists(tableName, 'client_id')) {
      return;
    }

    final rows = await customSelect(
      "SELECT id FROM $tableName WHERE client_id IS NULL OR client_id = ''",
    ).get();

    for (final row in rows) {
      final id = row.read<int>('id');
      await customStatement(
        'UPDATE $tableName SET client_id = ? WHERE id = ?',
        [_uuid.v4(), id],
      );
    }
  }

  Future<void> _createCurrentTablesIfNeeded() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS daily_portfolio_snapshots (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        snapshot_date TEXT NOT NULL,
        total_purchase_amount REAL NOT NULL,
        total_valuation_amount REAL NOT NULL,
        profit_amount REAL NOT NULL,
        profit_rate REAL NOT NULL,
        exchange_rate REAL NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    if (!await _columnExists('daily_portfolio_snapshots', 'exchange_rate')) {
      await customStatement(
        'ALTER TABLE daily_portfolio_snapshots ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1',
      );
    }

    await customStatement('''
      CREATE TABLE IF NOT EXISTS daily_portfolio_snapshot_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        snapshot_id INTEGER NOT NULL REFERENCES daily_portfolio_snapshots(id),
        asset_id INTEGER NOT NULL REFERENCES assets(id),
        asset_title TEXT NOT NULL,
        total_purchase_amount REAL NOT NULL,
        total_valuation_amount REAL NOT NULL,
        profit_amount REAL NOT NULL,
        profit_rate REAL NOT NULL,
        holding_count INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS snapshot_notes (
        snapshot_date TEXT NOT NULL PRIMARY KEY,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS daily_portfolio_snapshot_holding_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        snapshot_id INTEGER NOT NULL REFERENCES daily_portfolio_snapshots(id),
        asset_id INTEGER,
        asset_title TEXT NOT NULL,
        holding_id INTEGER,
        holding_name TEXT NOT NULL,
        holding_symbol TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        quantity REAL NOT NULL,
        total_purchase_amount REAL NOT NULL,
        total_valuation_amount REAL NOT NULL,
        profit_amount REAL NOT NULL,
        profit_rate REAL NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS daily_portfolio_snapshot_cash_accounts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        snapshot_id INTEGER NOT NULL REFERENCES daily_portfolio_snapshots(id),
        asset_id INTEGER,
        asset_title TEXT NOT NULL,
        cash_account_id INTEGER,
        cash_account_name TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        balance REAL NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS asset_allocation_targets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL UNIQUE REFERENCES assets(id),
        target_ratio REAL NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS exchange_rates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        currency_pair TEXT NOT NULL,
        rate REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual'
      )
    ''');

    await _ensureLedgerTables();
  }

  Future<void> _ensureSeedExchangeRateIfEmpty() async {
    if (!await _tableExists('exchange_rates')) return;

    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM exchange_rates',
    ).getSingle();
    final count = row.read<int>('count');
    if (count > 0) return;

    await into(exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        currencyPair: 'USD/KRW',
        rate: 1501.24,
        recordedAt: '2025-03-20T09:00:00',
        source: const Value('seed'),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'moneyfy.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
