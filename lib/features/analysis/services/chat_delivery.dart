import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'local_chat_store.dart';

/// The server holds deliveries until their final version is committed locally.
class ChatDelivery extends ChangeNotifier {
  ChatDelivery(this.store, this.user);
  final LocalChatStore store;
  final String user;
  Timer? _timer;
  bool _closed = false, _syncing = false, _again = false;
  bool offline = false;
  int roomRevision = 0;
  DateTime _nextImport = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _active => !_closed && AuthService.currentUser?.id == user;
  static const _fields =
      'id,thread_id,question,answer,sources,status,created_at';
  Future<void> send(String thread, String question) async {
    final id = const Uuid().v4();
    try {
      final row = await AuthService.client
          .from('rag_chat_requests')
          .insert({
            'id': id,
            'thread_id': thread,
            'device_id': store.device,
            'question': question,
            'local_history': store.context(thread),
          })
          .select(_fields)
          .single();
      if (_active && store.save(row)) {
        roomRevision++;
        notifyListeners();
      }
    } finally {
      if (_active) unawaited(sync());
    }
  }

  void remove(String thread) {
    store.remove(thread);
    notifyListeners();
    unawaited(sync());
  }

  Future<void> sync() async {
    if (!_active) return;
    if (_syncing) {
      _again = true;
      return;
    }
    _timer?.cancel();
    _syncing = true;
    var busy = false;
    try {
      final client = AuthService.client;
      if (DateTime.now().isAfter(_nextImport)) {
        await client.rpc(
          'collect_legacy_chat',
          params: {'p_device': store.device},
        );
        _nextImport = DateTime.now().add(const Duration(minutes: 1));
      }
      String? cursor;
      while (_active) {
        var query = client
            .from('rag_chat_requests')
            .select(_fields)
            .eq('user_id', user)
            .eq('device_id', store.device);
        if (cursor != null) query = query.gt('id', cursor);
        final page = await query.order('id').limit(60);
        if (!_active) break;
        final ack = <String>[];
        var changed = false;
        for (final row in page) {
          final thread = row['thread_id'] as String;
          final discarded = store.deleted(thread);
          if (!discarded && !store.hasTurn(row['id'] as String)) roomRevision++;
          final saved = store.save(row);
          changed = changed || saved;
          if (discarded ||
              row['status'] == 'done' ||
              row['status'] == 'failed') {
            ack.add(row['id'] as String);
          } else {
            busy = true;
          }
        }
        if (changed || offline) {
          offline = false;
          notifyListeners();
        }
        if (ack.isNotEmpty) {
          await client
              .from('rag_chat_requests')
              .delete()
              .eq('user_id', user)
              .eq('device_id', store.device)
              .inFilter('id', ack);
        }
        if (page.length < 60) break;
        cursor = page.last['id'] as String;
      }
      if (_active && offline) {
        offline = false;
        notifyListeners();
      }
    } catch (_) {
      if (_active && !offline) {
        offline = true;
        notifyListeners();
      }
    } finally {
      _syncing = false;
      if (_closed) {
        store.db.close();
      } else if (_active) {
        _timer = Timer(
          _again
              ? Duration.zero
              : busy
              ? const Duration(milliseconds: 650)
              : offline
              ? const Duration(seconds: 5)
              : const Duration(seconds: 20),
          sync,
        );
        _again = false;
      }
    }
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    if (!_syncing) store.db.close();
    super.dispose();
  }
}
