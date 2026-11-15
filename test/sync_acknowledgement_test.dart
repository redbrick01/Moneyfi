import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/sync/services/sync_acknowledgement.dart';

void main() {
  final payload = <String, Object?>{
    'transaction_events': [
      {'client_id': 'event-1'},
    ],
    'transaction_lines': [
      {'client_id': 'line-1'},
      {'client_id': 'line-2'},
    ],
    'snapshot_notes': [
      {'snapshot_date': '2026-11-14'},
    ],
  };
  Map<String, Object?> response() => {
    'ok': true,
    'conflict_count': 0,
    'accepted_client_ids': {
      'transaction_events': ['event-1'],
      'transaction_lines': ['line-1', 'line-2'],
      'snapshot_notes': ['2026-11-14'],
    },
  };
  test('all acknowledgements are required, including both transfer legs', () {
    expect(syncPayloadWasAccepted(payload, response()), true);
    final partial = response();
    (partial['accepted_client_ids'] as Map)['transaction_lines'] = ['line-1'];
    expect(syncPayloadWasAccepted(payload, partial), false);
  });
  test(
    'HTTP success without acknowledgements or with conflicts is not cloud success',
    () {
      expect(syncPayloadWasAccepted(payload, {'ok': true}), false);
      expect(
        syncPayloadWasAccepted(payload, response()..['conflict_count'] = 1),
        false,
      );
      expect(
        syncPayloadWasAccepted(payload, response()..['ok'] = false),
        false,
      );
    },
  );
}
