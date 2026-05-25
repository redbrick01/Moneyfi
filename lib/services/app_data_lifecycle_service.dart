import 'package:flutter/foundation.dart';

class AppDataLifecycleService {
  AppDataLifecycleService._();

  static final ValueNotifier<AppDataLifecycleState> state =
      ValueNotifier<AppDataLifecycleState>(const AppDataLifecycleState.ready());

  static int _version = 0;

  static void beginReplacement({required String message}) {
    _version++;
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: true,
      message: message,
    );
  }

  static void completeReplacement() {
    _version++;
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: false,
      message: null,
    );
  }
}

class AppDataLifecycleState {
  const AppDataLifecycleState({
    required this.version,
    required this.isReplacing,
    required this.message,
  });

  const AppDataLifecycleState.ready()
    : version = 0,
      isReplacing = false,
      message = null;

  final int version;
  final bool isReplacing;
  final String? message;
}
