import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final verificationSql = File(
    'docs/features/bug_fixes/usd_realized_pnl_currency_basis/remote_verification_and_rollback_06.sql',
  );

  test('verification SQL includes core before and after checks', () {
    final sql = verificationSql.readAsStringSync();

    expect(
      sql,
      contains('Pre-05 aggregate transaction performance by currency'),
    );
    expect(sql, contains('Post-05 archive and skipped-row review'));
    expect(sql, contains('USD anomaly query'));
    expect(sql, contains('zero-wipe verification'));
    expect(sql, contains('still_zero_but_snapshot_nonzero'));
    expect(sql, contains('asset metric purchase basis verification'));
    expect(sql, contains('coalesce(h.cost_basis_krw, 0) > 0'));
    expect(sql, contains('select public.recompute_asset_metrics(null)'));
  });

  test('verification SQL documents SATL expected correction values', () {
    final sql = verificationSql.readAsStringSync();

    expect(sql, contains('gross_amount 285'));
    expect(sql, contains('quantity_sold 30'));
    expect(sql, contains('realized_pnl 186.225'));
    expect(sql, contains('cost_basis_delta -140700'));
    expect(sql, contains('cost_basis_source_delta -98.775'));
  });

  test('rollback SQL uses archives and avoids restoring holding quantity', () {
    final sql = verificationSql.readAsStringSync();
    final holdingRollbackBlock = RegExp(
      r'08\. Post-05 targeted rollback template for holding currency-basis fields\.[\s\S]*?\*/',
      caseSensitive: false,
    ).firstMatch(sql)?.group(0);

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
    expect(holdingRollbackBlock, isNotNull);
    expect(holdingRollbackBlock, contains('separate snapshot-based'));
    expect(holdingRollbackBlock, isNot(contains('quantity =')));
    expect(holdingRollbackBlock, isNot(contains('current_price =')));
  });
}
