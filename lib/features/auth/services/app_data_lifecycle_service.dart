import 'package:flutter/foundation.dart';

class AppDataLifecycleService {
  AppDataLifecycleService._();

  static final ValueNotifier<AppDataLifecycleState> state =
      ValueNotifier<AppDataLifecycleState>(const AppDataLifecycleState.ready());

  static int _version = 0;
  static int _refreshToken = 0;

  static void beginReplacement({required String message}) {
    _version++;
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: true,
      message: message,
      refreshToken: _refreshToken,
      refreshReason: null,
    );
  }

  static void completeReplacement({String? refreshReason}) {
    _version++;
    if (refreshReason != null) {
      _refreshToken++;
    }
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: false,
      message: null,
      refreshToken: _refreshToken,
      refreshReason: refreshReason,
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _version = 0;
    _refreshToken = 0;
    state.value = const AppDataLifecycleState.ready();
  }
}

class AppDataLifecycleState {
  const AppDataLifecycleState({
    required this.version,
    required this.isReplacing,
    required this.message,
    required this.refreshToken,
    required this.refreshReason,
  });

  const AppDataLifecycleState.ready()
    : version = 0,
      isReplacing = false,
      message = null,
      refreshToken = 0,
      refreshReason = null;

  final int version;
  final bool isReplacing;
  final String? message;
  final int refreshToken;
  final String? refreshReason;
}
