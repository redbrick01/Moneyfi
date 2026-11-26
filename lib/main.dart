import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'design_system/app_theme.dart';
import 'navigation/moneyfy_router.dart';
import 'db/app_database.dart';
import 'features/mcp/local_mcp_bridge.dart';
import 'features/mcp/mcp_confirmation_dialog.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/app_data_lifecycle_service.dart';
import 'features/sync/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = Platform.isMacOS ? await _localMcpToken() : null;
  if (token != null) {
    String? readyUser() =>
        AppDataLifecycleService.startupChecked &&
            !AppDataLifecycleService.state.value.isReplacing
        ? AuthService.currentUser?.id
        : null;
    try {
      await LocalMcpBridge(
        db: AppDatabase.instance,
        userId: readyUser,
        confirmChange: (preview) => confirmMcpTransaction(
          moneyfyRouter.routerDelegate.navigatorKey.currentState,
          preview,
        ),
        runtimeStatus: () => (
          loggedIn: AuthService.currentUser != null,
          loading:
              !AppDataLifecycleService.startupChecked ||
              AppDataLifecycleService.state.value.isReplacing,
          syncing: SyncService.instance.isSyncing,
        ),
        sync: (user) async {
          final synced = await SyncService.instance.syncNow(
            reason: 'mcp_write',
            expectedUserId: user,
          );
          if (readyUser() == user) {
            AppDataLifecycleService.completeReplacement(
              refreshReason: 'mcp_write',
            );
          }
          return synced;
        },
      ).start(token: token);
    } on SocketException {
      debugPrint('[mcp] 로컬 브리지 포트에 연결할 수 없습니다.');
    } on ArgumentError {
      debugPrint('[mcp] 로컬 브리지 토큰 설정이 올바르지 않습니다.');
    }
  }
  runApp(const MoneyfyApp());
}

Future<String?> _localMcpToken() async {
  const developmentToken = String.fromEnvironment('MONEYFY_MCP_TOKEN');
  if (developmentToken.isNotEmpty) return developmentToken;

  const installedBridge = bool.fromEnvironment('MONEYFY_MCP_INSTALLED');
  if (!installedBridge) return null;

  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/.moneyfy-mcp-bridge.json');
    final config = jsonDecode(await file.readAsString());
    final token = config is Map<String, dynamic> ? config['token'] : null;
    if (token is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
      return token;
    }
  } catch (_) {
    debugPrint('[mcp] 설치된 로컬 브리지 설정을 읽을 수 없습니다.');
    return null;
  }
  debugPrint('[mcp] 설치된 로컬 브리지 설정이 올바르지 않습니다.');
  return null;
}

class MoneyfyApp extends StatelessWidget {
  const MoneyfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MONEYFY',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scrollBehavior: const _MoneyfyScrollBehavior(),
      builder: (context, child) =>
          _scaledTextApp(context: context, child: child),
      routerConfig: moneyfyRouter,
    );
  }
}

class _MoneyfyScrollBehavior extends MaterialScrollBehavior {
  const _MoneyfyScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

Widget _scaledTextApp({required BuildContext context, required Widget? child}) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.94)),
    child: child ?? const SizedBox.shrink(),
  );
}
