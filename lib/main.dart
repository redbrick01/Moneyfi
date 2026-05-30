import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'design_system/context_extensions.dart';
import 'db/app_database.dart';
import 'pages/app_shell_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoneyfyApp());
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
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<void> _startup = _initialize();

  Future<void> _initialize() async {
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
    } catch (error, stackTrace) {
      debugPrint('[main] startup failed: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StartupErrorPage(error: snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const AppShellPage();
        }
        return const StartupSplashPage();
      },
    );
  }
}

class StartupSplashPage extends StatelessWidget {
  const StartupSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.neutralBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.contentHorizontalPadding,
          ),
          child: Column(
            children: [
              const Spacer(flex: 5),
              const _StartupWordmark(),
              SizedBox(height: context.spacing.sm),
              Text(
                '내 자산 흐름을 차분하게 정리하는 중',
                style: context.typography.meta.copyWith(
                  color: colors.neutralTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.xl),
              SizedBox(
                width: context.spacing.xxxl,
                child: LinearProgressIndicator(
                  minHeight: context.spacing.xs / 2,
                  color: colors.primary,
                  backgroundColor: colors.neutralSurfaceRaised,
                  borderRadius: BorderRadius.circular(context.radius.rPill),
                ),
              ),
              const Spacer(flex: 4),
              Text(
                'Moneyfy',
                style: context.typography.caption.copyWith(
                  color: colors.neutralTextMuted,
                ),
              ),
              SizedBox(height: context.spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupWordmark extends StatelessWidget {
  const _StartupWordmark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typography.pageTitle.copyWith(
      fontWeight: AppFontWeights.medium,
      letterSpacing: -0.4,
    );

    return Semantics(
      header: true,
      label: 'Moneyfy',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'M',
                style: style.copyWith(color: colors.primary),
              ),
              TextSpan(
                text: 'oney',
                style: style.copyWith(color: colors.neutralText),
              ),
              TextSpan(
                text: 'f',
                style: style.copyWith(color: colors.positiveOn),
              ),
              TextSpan(
                text: 'y',
                style: style.copyWith(color: colors.neutralText),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
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
