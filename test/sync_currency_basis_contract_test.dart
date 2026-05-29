import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final syncLocalDb = File('supabase/functions/sync-local-db/index.ts');
  final getSyncLocalDb = File('supabase/functions/get-sync-local-db/index.ts');

  test('sync-local-db preserves seeded USD currency-basis values', () {
    final source = syncLocalDb.readAsStringSync();

    expect(source, contains('preserveUsdHoldingCurrencyBasis'));
    expect(source, contains('holdings currency-basis preload failed'));
    expect(source, contains('preserved_rows'));
    expect(source, contains('"average_price_source"'));
    expect(source, contains('"average_price_krw"'));
    expect(source, contains('"average_purchase_fx_rate"'));
    expect(source, contains('"cost_basis_krw"'));
    expect(source, contains('shouldPreservePositiveServerValue'));
    expect(source, contains('incomingNumber <= 0'));
    expect(source, contains('currentNumber <= 0'));
  });

  test(
    'core sync payload includes currency-basis fields in both directions',
    () {
      final pushSource = syncLocalDb.readAsStringSync();
      final pullSource = getSyncLocalDb.readAsStringSync();

      for (final field in [
        'average_price_source',
        'average_price_krw',
        'average_purchase_fx_rate',
        'cost_basis_krw',
        'cost_basis_source_delta',
      ]) {
        expect(pushSource, contains(field));
        expect(pullSource, contains(field));
      }
    },
  );
}
