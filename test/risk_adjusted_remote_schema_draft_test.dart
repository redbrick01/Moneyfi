import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sqlFile = File(
    'docs/features/new_feature_development/'
    'risk_adjusted_benchmark_performance/remote_schema_draft_05.sql',
  );

  test('remote schema draft only creates derived analysis tables', () {
    final sql = sqlFile.readAsStringSync().toLowerCase();
    final executableSql = sql
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');

    expect(
      sql,
      contains('create table if not exists public.portfolio_daily_returns'),
    );
    expect(sql, contains('create table if not exists public.benchmark_prices'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('(select auth.uid()) = user_id'));
    expect(
      sql,
      contains(
        'grant select, insert, update, delete on public.portfolio_daily_returns',
      ),
    );
    expect(sql, contains('grant select on public.benchmark_prices'));

    expect(executableSql, isNot(contains('update holdings')));
    expect(executableSql, isNot(contains('delete from holdings')));
    expect(executableSql, isNot(contains('update assets')));
    expect(executableSql, isNot(contains('delete from assets')));
    expect(executableSql, isNot(contains('truncate')));
  });
}
