import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static const String _configAssetPath = 'assets/config.json';

  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';

  static bool _initialized = false;
  static Future<void>? _initializing;

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<bool> ensureInitialized() async {
    if (_initialized) {
      return true;
    }
    await initialize();
    return _initialized;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase has not been initialized.');
    }
    return Supabase.instance.client;
  }

  static User? get currentUser => _initialized ? client.auth.currentUser : null;

  static Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      return const Stream<AuthState>.empty();
    }
    return client.auth.onAuthStateChange;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (_initializing != null) {
      await _initializing;
      return;
    }
    final config = await _loadConfig();
    _supabaseUrl = config.supabaseUrl;
    _supabaseAnonKey = config.supabaseAnonKey;

    if (!isConfigured) {
      debugPrint('[auth] SUPABASE_URL / SUPABASE_ANON_KEY are not configured');
      return;
    }

    final future = Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _initializing = future;
    try {
      await future;
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {if (name != null && name.trim().isNotEmpty) 'name': name.trim()},
    );
  }

  static Future<UserResponse> updateProfileName(String name) {
    return client.auth.updateUser(UserAttributes(data: {'name': name.trim()}));
  }

  static Future<UserResponse> updatePassword(String password) {
    return client.auth.updateUser(UserAttributes(password: password));
  }

  static Future<void> signOut() {
    return client.auth.signOut();
  }

  static Future<_SupabaseConfig> _loadConfig() async {
    try {
      final jsonText = await rootBundle.loadString(_configAssetPath);
      final jsonValue = jsonDecode(jsonText);
      if (jsonValue is! Map<String, dynamic>) {
        debugPrint('[auth] $_configAssetPath must contain a JSON object');
        return const _SupabaseConfig.empty();
      }

      return _SupabaseConfig(
        supabaseUrl: _readString(jsonValue, 'SUPABASE_URL'),
        supabaseAnonKey: _readString(jsonValue, 'SUPABASE_ANON_KEY'),
      );
    } catch (error, stackTrace) {
      debugPrint('[auth] failed to load $_configAssetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const _SupabaseConfig.empty();
    }
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value.trim() : '';
  }
}

class _SupabaseConfig {
  const _SupabaseConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  const _SupabaseConfig.empty() : supabaseUrl = '', supabaseAnonKey = '';

  final String supabaseUrl;
  final String supabaseAnonKey;
}
