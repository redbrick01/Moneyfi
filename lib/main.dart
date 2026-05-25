import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'design_system/context_extensions.dart';
import 'db/app_database.dart';
import 'pages/app_shell_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint(
      '[main] env KIS_APP_KEY=${const String.fromEnvironment('KIS_APP_KEY').isNotEmpty} '
      'KIS_APP_SECRET=${const String.fromEnvironment('KIS_APP_SECRET').isNotEmpty}',
    );
    await AuthService.initialize();
    await AppDatabase.instance.removeLegacySeededCashHoldings();
    if (AuthService.currentUser == null) {
      await AppDatabase.instance.clearAllLocalUserData();
    }
    runApp(const MoneyfyApp());
  } catch (error, stackTrace) {
    debugPrint('[main] startup failed: $error');
    debugPrint(stackTrace.toString());
    runApp(StartupErrorApp(error: error.toString()));
  }
}

class MoneyfyApp extends StatelessWidget {
  const MoneyfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MONEYFY',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scrollBehavior: const _MoneyfyScrollBehavior(),
      builder: (context, child) =>
          _scaledTextApp(context: context, child: child),
      home: const AppShellPage(),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MONEYFY',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scrollBehavior: const _MoneyfyScrollBehavior(),
      builder: (context, child) =>
          _scaledTextApp(context: context, child: child),
      home: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.spacing.xxxl),
                    Text('앱 시작 오류', style: context.typography.pageTitle),
                    SizedBox(height: context.spacing.md),
                    Text(
                      '초기화 중 문제가 발생했습니다. 아래 메시지를 확인하세요.',
                      style: context.typography.body,
                    ),
                    SizedBox(height: context.spacing.lg),
                    SelectableText(error, style: context.typography.meta),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
