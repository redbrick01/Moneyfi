import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/analysis/services/local_chat_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'history survives reopening; delivery retries and deleted threads stay idempotent',
    () {
      final dir = Directory.systemTemp.createTempSync();
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/chat.sqlite';
      var store = LocalChatStore(sqlite3.open(path));
      final device = store.device;
      ChatRow row(int i) => {
        'id': 'id$i',
        'thread_id': 'room',
        'question': '질문$i',
        'answer': '답변$i',
        'sources': [
          {'title': '기사'},
        ],
        'status': 'done',
        'created_at': '2026-11-26T12:00:0${i}Z',
      };
      for (final i in [3, 1, 4, 2]) {
        expect(store.save(row(i)), true);
      }
      expect(store.save(row(2)), false);
      store.db.close();
      store = LocalChatStore(sqlite3.open(path));
      addTearDown(() => store.db.close());
      expect(store.device, device);
      expect(store.rooms(null).single['title'], '질문1');
      expect(store.rooms(store.rooms(null).single), isEmpty);
      expect(store.history('room').first['sources'], row(4)['sources']);
      expect(jsonDecode(jsonEncode(store.context('room'))), [
        for (final i in [2, 3, 4]) {'question': '질문$i', 'answer': '답변$i'},
      ]);
      store.remove('room');
      expect(store.save(row(4)), false);
      expect(store.history('room'), isEmpty);
      expect(store.rooms(null), isEmpty);
    },
  );
}
