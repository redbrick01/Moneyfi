import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system/app_theme.dart';
import 'navigation/moneyfy_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
