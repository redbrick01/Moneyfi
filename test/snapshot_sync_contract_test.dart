import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final syncLocalDbSource = File(
    'supabase/functions/sync-local-db/index.ts',
  ).readAsStringSync();
  final getPortfolioSnapshotsSource = File(
    'supabase/functions/get-portfolio-snapshots/index.ts',
  ).readAsStringSync();

  test('sync-local-db accepts snapshot note payloads', () {
    expect(syncLocalDbSource, contains('body.snapshot_notes'));
    expect(syncLocalDbSource, contains('.from("snapshot_notes")'));
    expect(syncLocalDbSource, contains('onConflict: "user_id,snapshot_date"'));
    expect(syncLocalDbSource, contains('accepted_client_ids'));
    expect(syncLocalDbSource, contains('snapshot_notes'));
  });

  test('get-portfolio-snapshots paginates child tables', () {
    expect(getPortfolioSnapshotsSource, contains('fetchAllRows'));
    expect(getPortfolioSnapshotsSource, contains('.range(from, to)'));
    expect(
      getPortfolioSnapshotsSource,
      contains('.from("daily_portfolio_snapshot_holding_items")'),
    );
    expect(getPortfolioSnapshotsSource, contains('holding_items'));
  });
}
