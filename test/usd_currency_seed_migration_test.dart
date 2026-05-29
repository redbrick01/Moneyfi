import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260529014953_seed_existing_usd_currency_basis.sql',
  );

  test('USD currency basis seed migration keeps seed rows explicit', () {
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
  });

  test('USD currency basis seed migration has safety archives and guards', () {
    final sql = migration.readAsStringSync();
    final updateBlock = RegExp(
      r'update public\.holdings h\s+set(?<set>[\s\S]*?)from matched_seed',
      caseSensitive: false,
    ).firstMatch(sql)?.namedGroup('set');

    expect(
      sql,
      contains(
        'recovery_archive.holdings_before_usd_currency_basis_seed_20260529',
      ),
    );
    expect(
      sql,
      contains('recovery_archive.usd_currency_basis_seed_skipped_20260529'),
    );
    expect(sql, contains("h.currency_code = 'USD'"));
    expect(sql, contains('a.title = seed.asset_title'));
    expect(sql, contains('h.symbol = seed.symbol'));
    expect(sql, contains('h.name = seed.holding_name'));
    expect(
      sql,
      contains('abs(coalesce(h.quantity, 0) - seed.expected_quantity)'),
    );
    expect(updateBlock, isNotNull);
    expect(updateBlock, isNot(contains('quantity =')));
    expect(updateBlock, isNot(contains('current_price')));
    expect(updateBlock, isNot(contains('currency_code')));
    expect(updateBlock, isNot(contains('symbol')));
    expect(updateBlock, isNot(contains('name')));
  });
}
