import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'navigation/moneyfy_router.dart';
import 'db/app_database.dart';
import 'features/mcp/local_mcp_bridge.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/app_data_lifecycle_service.dart';
import 'features/sync/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('MONEYFY_MCP_TOKEN');
  if (token.isNotEmpty && Platform.isMacOS) {
    await LocalMcpBridge(
      db: AppDatabase.instance,
      userId: () => AppDataLifecycleService.state.value.isReplacing
          ? null
          : AuthService.currentUser?.id,
      sync: () async {
        final synced = await SyncService.instance.syncNow(
          reason: 'mcp_write',
          requireAcknowledgement: true,
        );
        if (!AppDataLifecycleService.state.value.isReplacing) {
          AppDataLifecycleService.completeReplacement(
            refreshReason: 'mcp_write',
          );
        }
        return synced;
      },
    ).start(token: token);
  }
  runApp(const MoneyfyApp());
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
