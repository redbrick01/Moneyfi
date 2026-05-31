import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/navigation/moneyfy_router.dart';
import 'package:moneyfy/navigation/moneyfy_routes.dart';
import 'package:moneyfy/pages/forms/asset_form_page.dart';
import 'package:moneyfy/pages/forms/cash_account_form_page.dart';
import 'package:moneyfy/pages/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/pages/forms/holding_form_page.dart';
import 'package:moneyfy/pages/forms/transaction_form_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpRouter(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    final router = buildMoneyfyRouter(
      initialLocation: initialLocation,
      useStartupGate: false,
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(tester.takeException(), isNull);
  }

  for (final routeCase in const [
    _ShellRouteCase(MoneyfyRoutePaths.home, '홈'),
    _ShellRouteCase(MoneyfyRoutePaths.portfolio, '포트폴', '포트폴리오'),
    _ShellRouteCase(MoneyfyRoutePaths.transactions, '거래', '거래'),
    _ShellRouteCase(MoneyfyRoutePaths.analysis, '분석', '분석'),
    _ShellRouteCase(MoneyfyRoutePaths.my, 'My', 'My'),
  ]) {
    testWidgets('opens shell route ${routeCase.path}', (tester) async {
      await pumpRouter(tester, initialLocation: routeCase.path);

      expect(
        find.byKey(ValueKey('bottom-tab-${routeCase.tabLabel}')),
        findsOneWidget,
      );
      if (routeCase.pageText != null) {
        expect(find.text(routeCase.pageText!), findsWidgets);
      }
    });
  }

  testWidgets('opens statistics compatibility route under analysis tab', (
    tester,
  ) async {
    await pumpRouter(tester, initialLocation: MoneyfyRoutePaths.statistics);

    expect(find.byKey(const ValueKey('bottom-tab-분석')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-tab-통계')), findsNothing);
    expect(find.text('통계'), findsWidgets);
  });

  testWidgets('opens analysis detail route', (tester) async {
    await pumpRouter(
      tester,
      initialLocation: MoneyfyRoutePaths.investmentPerformance,
    );

    expect(find.text('순 투자성과'), findsWidgets);
  });

  for (final routePath in const [
    '/assets/-101',
    '/holdings/-102',
    '/cash-accounts/-202',
  ]) {
    testWidgets('opens detail route $routePath', (tester) async {
      await pumpRouter(tester, initialLocation: routePath);

      expect(find.byType(Scaffold), findsWidgets);
    });
  }

  testWidgets('opens auth route', (tester) async {
    await pumpRouter(tester, initialLocation: MoneyfyRoutePaths.login);

    expect(find.text('로그인'), findsWidgets);
  });

  for (final routeCase in const [
    _FormRouteCase('/assets/new', AssetFormPage),
    _FormRouteCase('/assets/-101/holdings/new', HoldingFormPage),
    _FormRouteCase('/assets/-101/cash-accounts/new', CashAccountFormPage),
    _FormRouteCase(
      '/holdings/-102/transactions/new?assetId=-101&defaultName=%EC%82%BC%EC%84%B1%EC%A0%84%EC%9E%90',
      TransactionFormPage,
    ),
    _FormRouteCase(
      '/cash-accounts/-202/transactions/new?assetId=-201&defaultName=%EC%83%9D%ED%99%9C%EB%B9%84',
      CashTransactionFormPage,
    ),
  ]) {
    testWidgets('opens form route ${routeCase.path}', (tester) async {
      await pumpRouter(tester, initialLocation: routeCase.path);

      expect(find.byType(routeCase.pageType), findsOneWidget);
    });
  }

  testWidgets('shows invalid route page for missing transaction asset id', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      initialLocation: MoneyfyRoutePaths.transactionCreate(-102),
    );

    expect(find.text('거래 경로가 올바르지 않아요.'), findsOneWidget);
  });
}

class _ShellRouteCase {
  const _ShellRouteCase(this.path, this.tabLabel, [this.pageText]);

  final String path;
  final String tabLabel;
  final String? pageText;
}

class _FormRouteCase {
  const _FormRouteCase(this.path, this.pageType);

  final String path;
  final Type pageType;
}
