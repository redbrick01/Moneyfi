import 'dart:async';

import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'auth_service.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  bool _isSyncing = false;
  bool _isPullingCoreData = false;
  bool _isPullingSnapshots = false;
  Future<bool>? _inFlightCorePull;
  Future<int>? _inFlightSnapshotPull;
  Future<bool>? _inFlightRefresh;
  String? _inFlightCorePullUserId;
  String? _inFlightSnapshotPullUserId;
  String? _inFlightRefreshUserId;

  bool get canSync =>
      AuthService.isInitialized && AuthService.currentUser != null;

  Future<bool> syncNow({String reason = 'manual'}) async {
    if (!canSync || _isSyncing) {
      return false;
    }

    _isSyncing = true;
    try {
      final payload = await _buildPayload();
      final session = AuthService.client.auth.currentSession;
      debugPrint(
        '[sync] start reason=$reason canSync=$canSync hasSession=${session != null} '
        'hasAccessToken=${(session?.accessToken ?? '').isNotEmpty}',
      );
      if (_isPayloadEmpty(payload)) {
        debugPrint('[sync] skipped empty payload reason=$reason');
        return true;
      }

      final response = await AuthService.client.functions.invoke(
        'sync-local-db',
        body: payload,
      );
      debugPrint(
        '[sync] response reason=$reason status=${response.status} data=${response.data}',
      );
      if (response.status != 200) {
        debugPrint('[sync] non-200 reason=$reason error=${response.data}');
        return false;
      }
      if (response.data is Map && (response.data as Map)['ok'] == false) {
        debugPrint('[sync] rejected reason=$reason error=${response.data}');
        return false;
      }
      final responsePayload = response.data is Map
          ? Map<String, Object?>.from(response.data as Map)
          : const <String, Object?>{};
      final acceptedClientIds = responsePayload['accepted_client_ids'] is Map
          ? Map<String, Object?>.from(
              responsePayload['accepted_client_ids'] as Map,
            )
          : null;
      final conflictCount = responsePayload['conflict_count'];
      if (conflictCount is num && conflictCount > 0) {
        debugPrint(
          '[sync] conflict reason=$reason count=${conflictCount.toInt()} '
          'conflicts=${responsePayload['conflicts']}',
        );
      }
      await AppDatabase.instance.markDirtySyncPayloadAsSynced(
        payload,
        acceptedClientIds,
      );
      debugPrint('[sync] success reason=$reason');
      return true;
    } catch (error, stackTrace) {
      final session = AuthService.client.auth.currentSession;
      debugPrint(
        '[sync] failed reason=$reason type=${error.runtimeType} error=$error',
      );
      debugPrint(
        '[sync] session state reason=$reason hasSession=${session != null} '
        'hasAccessToken=${(session?.accessToken ?? '').isNotEmpty} '
        'userId=${AuthService.currentUser?.id}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  void syncInBackground({String reason = 'background'}) {
    unawaited(syncNow(reason: reason));
  }

  Future<bool> pullRemoteCoreData({String reason = 'foreground'}) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null || !canSync) {
      return false;
    }
    if (_inFlightCorePull != null && _inFlightCorePullUserId == userId) {
      return _inFlightCorePull!;
    }
    if (_isPullingCoreData && _inFlightCorePullUserId == userId) {
      return false;
    }

    final future = _pullRemoteCoreDataInternal(reason: reason, userId: userId);
    _inFlightCorePull = future;
    _inFlightCorePullUserId = userId;
    try {
      return await future;
    } finally {
      if (identical(_inFlightCorePull, future)) {
        _inFlightCorePull = null;
        _inFlightCorePullUserId = null;
      }
    }
  }

  Future<bool> refreshFromServer({String reason = 'foreground'}) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null || !canSync) {
      return false;
    }
    if (_inFlightRefresh != null && _inFlightRefreshUserId == userId) {
      return _inFlightRefresh!;
    }
    final future = _refreshFromServerInternal(reason: reason);
    _inFlightRefresh = future;
    _inFlightRefreshUserId = userId;
    try {
      return await future;
    } finally {
      if (identical(_inFlightRefresh, future)) {
        _inFlightRefresh = null;
        _inFlightRefreshUserId = null;
      }
    }
  }

  Future<int> pullRemoteSnapshots({String reason = 'foreground'}) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null || !canSync) {
      return 0;
    }
    if (_inFlightSnapshotPull != null &&
        _inFlightSnapshotPullUserId == userId) {
      return _inFlightSnapshotPull!;
    }
    if (_isPullingSnapshots && _inFlightSnapshotPullUserId == userId) {
      return 0;
    }

    final future = _pullRemoteSnapshotsInternal(reason: reason, userId: userId);
    _inFlightSnapshotPull = future;
    _inFlightSnapshotPullUserId = userId;
    try {
      return await future;
    } finally {
      if (identical(_inFlightSnapshotPull, future)) {
        _inFlightSnapshotPull = null;
        _inFlightSnapshotPullUserId = null;
      }
    }
  }

  Future<bool> _pullRemoteCoreDataInternal({
    required String reason,
    required String userId,
  }) async {
    _isPullingCoreData = true;
    try {
      debugPrint('[core-pull] start reason=$reason userId=$userId');
      final response = await AuthService.client.functions.invoke(
        'get-sync-local-db',
        body: const <String, Object?>{},
      );
      debugPrint(
        '[core-pull] response reason=$reason status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return false;
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true) {
        return false;
      }
      if (!_isSupportedCorePayload(payload)) {
        debugPrint(
          '[core-pull] unsupported payload reason=$reason '
          'payload_version=${payload['payload_version']} '
          'schema_mode=${payload['schema_mode']}',
        );
        return false;
      }

      debugPrint(
        '[core-pull] payload counts reason=$reason '
        'assets=${_payloadCount(payload['assets'])} '
        'holdings=${_payloadCount(payload['holdings'])} '
        'cash_accounts=${_payloadCount(payload['cash_accounts'])} '
        'transaction_events=${_payloadCount(payload['transaction_events'])} '
        'transaction_lines=${_payloadCount(payload['transaction_lines'])}',
      );
      if (AuthService.currentUser?.id != userId) {
        debugPrint(
          '[core-pull] ignored stale response reason=$reason '
          'startedUserId=$userId currentUserId=${AuthService.currentUser?.id}',
        );
        return false;
      }
      await AppDatabase.instance.replaceLocalSyncData(payload);
      debugPrint('[core-pull] success reason=$reason');
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[core-pull] failed reason=$reason type=${error.runtimeType} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isPullingCoreData = false;
    }
  }

  Future<bool> _refreshFromServerInternal({required String reason}) async {
    final corePulled = await pullRemoteCoreData(reason: '${reason}_core');
    if (!corePulled) {
      return false;
    }

    await pullRemoteSnapshots(reason: '${reason}_snapshots');
    return true;
  }

  bool _isSupportedCorePayload(Map<String, dynamic> payload) {
    return payload['payload_version'] == 4 &&
        payload['schema_mode'] == 'ledger_only_delta';
  }

  int _payloadCount(Object? value) {
    return value is List ? value.length : 0;
  }

  Future<int> _pullRemoteSnapshotsInternal({
    required String reason,
    required String userId,
  }) async {
    _isPullingSnapshots = true;
    try {
      debugPrint('[snapshot-pull] start reason=$reason userId=$userId');
      final response = await AuthService.client.functions.invoke(
        'get-portfolio-snapshots',
        body: const <String, Object?>{},
      );
      debugPrint(
        '[snapshot-pull] response reason=$reason status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return -1;
      }
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true) {
        return -1;
      }

      final rawSnapshots = payload['snapshots'];
      if (rawSnapshots is! List) {
        return -1;
      }

      final snapshots = rawSnapshots
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false);
      if (AuthService.currentUser?.id != userId) {
        debugPrint(
          '[snapshot-pull] ignored stale response reason=$reason '
          'startedUserId=$userId currentUserId=${AuthService.currentUser?.id}',
        );
        return -1;
      }
      if (snapshots.isEmpty) {
        return 0;
      }

      final importedCount = await AppDatabase.instance
          .importRemotePortfolioSnapshots(snapshots);
      debugPrint(
        '[snapshot-pull] success reason=$reason imported=$importedCount',
      );
      return importedCount;
    } catch (error, stackTrace) {
      debugPrint(
        '[snapshot-pull] failed reason=$reason type=${error.runtimeType} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return -1;
    } finally {
      _isPullingSnapshots = false;
    }
  }

  void pullRemoteSnapshotsInBackground({String reason = 'background'}) {
    unawaited(pullRemoteSnapshots(reason: reason));
  }

  Future<Map<String, Object?>> _buildPayload() async {
    return AppDatabase.instance.buildDirtySyncPayload();
  }

  bool _isPayloadEmpty(Map<String, Object?> payload) {
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return false;
      }
    }
    return true;
  }
}
