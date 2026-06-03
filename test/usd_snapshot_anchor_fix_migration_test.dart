import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260529023219_fix_usd_snapshot_anchor_realized_pnl_currency_basis.sql',
  );

  test(
    'USD snapshot anchor fix keeps user-provided source averages explicit',
    () {
      final sql = migration.readAsStringSync();

      expect(sql, contains("('주식', 8, 'SATL', '새틀로직', 50, 4690, 3.2925)"));
      expect(sql, contains("('주식', 3, 'IONQ', '아이온큐', 16, 39680, 28.3813)"));
      expect(sql, contains("('주식', 1, 'TSLA', '테슬라', 2, 317648, 225.9928)"));
      expect(sql, contains("('주식', 4, 'PLTR', '팔란티어', 6, 104149, 74.4933)"));
      expect(
        sql,
        contains("('주식', 5, 'NVDA', '엔비디아', 7, 143943.642857143, 133.1379)"),
      );
      expect(sql, contains("('+', 21, 'TSLA', '테슬라', 66, 286663, 259.5674)"));
    },
  );

  test('USD snapshot anchor fix updates only anchored USD sell lines', () {
    final sql = migration.readAsStringSync();
    final seedMatchBlock = RegExp(
      r'create temp table matched_seed_holdings[\s\S]*?create table if not exists recovery_archive\.usd_snapshot_anchor_fix_skipped_20260529',
      caseSensitive: false,
    ).firstMatch(sql)?.group(0);

    expect(sql, contains('affected_usd_snapshot_anchor_sell_lines'));
    expect(sql, contains("tl.action = 'sell'"));
    expect(sql, contains("upper(coalesce(tl.currency_code, 'KRW')) = 'USD'"));
    expect(
      sql,
      contains("coalesce(tl.realized_pnl_source, 'auto') = 'snapshot_anchor'"),
    );
    expect(
      sql,
      contains(
        "te.source not in ('snapshot_restore', 'history_display', 'record_only')",
      ),
    );
    expect(sql, contains('join lateral'));
    expect(sql, contains('daily_portfolio_snapshot_holding_items'));
    expect(seedMatchBlock, isNotNull);
    expect(seedMatchBlock, isNot(contains('h.name = seed.holding_name')));
    expect(seedMatchBlock, isNot(contains('expected_quantity) <')));
    expect(seedMatchBlock, isNot(contains('expected_average_price_krw) <')));
  });

  test(
    'USD snapshot anchor fix applies source-currency realized PnL formula',
    () {
      final sql = migration.readAsStringSync();

      expect(
        sql,
        contains(
          'affected.gross_amount - (affected.average_price_source * affected.quantity_sold)',
        ),
      );
      expect(
        sql,
        contains(
          '-(affected.expected_average_price_krw * affected.quantity_sold)',
        ),
      );
      expect(
        sql,
        contains('-(affected.average_price_source * affected.quantity_sold)'),
      );
      expect(sql, contains('realized_pnl = 285 - (3.2925 * 30) = 186.225'));
      expect(sql, contains('cost_basis_delta = -(4690 * 30) = -140700'));
      expect(
        sql,
        contains('cost_basis_source_delta = -(3.2925 * 30) = -98.775'),
      );
    },
  );

  test('USD snapshot anchor fix has archive and zero-wipe guards', () {
    final sql = migration.readAsStringSync();
    final holdingUpdateBlock = RegExp(
      r'update public\.holdings h\s+set(?<set>[\s\S]*?)from matched_seed_holdings',
      caseSensitive: false,
    ).firstMatch(sql)?.namedGroup('set');

    expect(
      sql,
      contains(
        'recovery_archive.transaction_lines_before_usd_snapshot_anchor_fix_20260529',
      ),
    );
    expect(
      sql,
      contains(
        'recovery_archive.holdings_before_usd_snapshot_anchor_fix_20260529',
      ),
    );
    expect(
      sql,
      contains('recovery_archive.usd_snapshot_anchor_fix_skipped_20260529'),
    );
    expect(
      sql.toLowerCase(),
      isNot(contains('left join public.transaction_lines')),
    );
    expect(holdingUpdateBlock, isNotNull);
    expect(holdingUpdateBlock, isNot(contains('quantity =')));
    expect(holdingUpdateBlock, isNot(contains('current_price')));
    expect(holdingUpdateBlock, isNot(contains('currency_code')));
    expect(holdingUpdateBlock, isNot(contains('symbol')));
    expect(holdingUpdateBlock, isNot(contains('name')));
  });

  test(
    'asset metric recompute prefers stored KRW cost basis without holdings replay',
    () {
      final sql = migration.readAsStringSync();
      final lowerSql = sql.toLowerCase();

      expect(
        sql,
        contains('CREATE OR REPLACE FUNCTION public.recompute_asset_metrics'),
      );
      expect(sql, contains('coalesce(h.cost_basis_krw, 0) > 0'));
      expect(sql, contains('then h.cost_basis_krw'));
      expect(sql, contains('else h.quantity * h.average_price'));
      expect(sql, contains('select public.recompute_asset_metrics(null)'));
      expect(lowerSql, isNot(contains('computed_holdings')));
      expect(lowerSql, isNot(contains('active_holding_ledger')));
    },
  );
}
