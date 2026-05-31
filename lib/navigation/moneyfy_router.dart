import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/asset_detail_page.dart';
import '../pages/app_shell_page.dart';
import '../pages/cash_account_detail_page.dart';
import '../pages/dividend_interest_analysis_page.dart';
import '../pages/forms/asset_form_page.dart';
import '../pages/forms/cash_account_form_page.dart';
import '../pages/forms/cash_transaction_form_page.dart';
import '../pages/forms/holding_form_page.dart';
import '../pages/forms/transaction_form_page.dart';
import '../pages/holding_detail_page.dart';
import '../pages/investment_performance_page.dart';
import '../pages/login_page.dart';
import '../pages/signup_page.dart';
import '../pages/portfolio_analysis_mvp_page.dart';
import '../pages/startup_gate.dart';
import 'moneyfy_routes.dart';

final moneyfyRouter = buildMoneyfyRouter();
const _shellPageKey = ValueKey('moneyfy-shell-page');

GoRouter buildMoneyfyRouter({
  String initialLocation = MoneyfyRoutePaths.home,
  bool useStartupGate = true,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final path in MoneyfyRoutePaths.shellCompatiblePaths)
        GoRoute(
          path: path,
          name: MoneyfyRouteNames.shellRouteNameForPath(path),
          pageBuilder: (context, state) {
            final shell = AppShellPage(
              key: const ValueKey('moneyfy-shell'),
              initialLocation: state.uri.path,
            );
            final child = useStartupGate ? StartupGate(child: shell) : shell;
            return NoTransitionPage(key: _shellPageKey, child: child);
          },
        ),
      GoRoute(
        path: MoneyfyRoutePaths.assetCreate,
        name: MoneyfyRouteNames.assetCreate,
        builder: (context, state) => const AssetFormPage(),
      ),
      GoRoute(
        path: MoneyfyRoutePaths.holdingCreatePattern,
        name: MoneyfyRouteNames.holdingCreate,
        builder: (context, state) {
          final assetId = _pathInt(state, 'assetId');
          if (assetId == null) {
            return const _InvalidRoutePage(message: '자산 경로가 올바르지 않아요.');
          }
          return HoldingFormPage(assetId: assetId);
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.cashAccountCreatePattern,
        name: MoneyfyRouteNames.cashAccountCreate,
        builder: (context, state) {
          final assetId = _pathInt(state, 'assetId');
          if (assetId == null) {
            return const _InvalidRoutePage(message: '자산 경로가 올바르지 않아요.');
          }
          return CashAccountFormPage(assetId: assetId);
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.transactionCreatePattern,
        name: MoneyfyRouteNames.transactionCreate,
        builder: (context, state) {
          final holdingId = _pathInt(state, 'holdingId');
          final assetId = _queryInt(state, 'assetId');
          if (holdingId == null || assetId == null) {
            return const _InvalidRoutePage(message: '거래 경로가 올바르지 않아요.');
          }
          return TransactionFormPage(
            assetId: assetId,
            holdingId: holdingId,
            holdingClientId: state.uri.queryParameters['holdingClientId'],
            defaultName: state.uri.queryParameters['defaultName'],
          );
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.cashTransactionCreatePattern,
        name: MoneyfyRouteNames.cashTransactionCreate,
        builder: (context, state) {
          final holdingId = _pathInt(state, 'holdingId');
          final assetId = _queryInt(state, 'assetId');
          if (holdingId == null || assetId == null) {
            return const _InvalidRoutePage(message: '현금 거래 경로가 올바르지 않아요.');
          }
          return CashTransactionFormPage(
            assetId: assetId,
            holdingId: holdingId,
            holdingClientId: state.uri.queryParameters['holdingClientId'],
            defaultName: state.uri.queryParameters['defaultName'],
          );
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.assetDetailPattern,
        name: MoneyfyRouteNames.assetDetail,
        builder: (context, state) {
          final assetId = _pathInt(state, 'assetId');
          if (assetId == null) {
            return const _InvalidRoutePage(message: '자산 경로가 올바르지 않아요.');
          }
          return AssetDetailPage(
            assetId: assetId,
            assetClientId: state.uri.queryParameters['assetClientId'],
          );
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.holdingDetailPattern,
        name: MoneyfyRouteNames.holdingDetail,
        builder: (context, state) {
          final holdingId = _pathInt(state, 'holdingId');
          if (holdingId == null) {
            return const _InvalidRoutePage(message: '보유 종목 경로가 올바르지 않아요.');
          }
          return HoldingDetailPage(
            holdingId: holdingId,
            holdingClientId: state.uri.queryParameters['holdingClientId'],
          );
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.cashAccountDetailPattern,
        name: MoneyfyRouteNames.cashAccountDetail,
        builder: (context, state) {
          final holdingId = _pathInt(state, 'holdingId');
          if (holdingId == null) {
            return const _InvalidRoutePage(message: '현금 계좌 경로가 올바르지 않아요.');
          }
          return CashAccountDetailPage(
            holdingId: holdingId,
            holdingClientId: state.uri.queryParameters['holdingClientId'],
          );
        },
      ),
      GoRoute(
        path: MoneyfyRoutePaths.portfolioDiagnosis,
        name: MoneyfyRouteNames.portfolioDiagnosis,
        builder: (context, state) => const PortfolioAnalysisMvpPage(),
      ),
      GoRoute(
        path: MoneyfyRoutePaths.investmentPerformance,
        name: MoneyfyRouteNames.investmentPerformance,
        builder: (context, state) => const InvestmentPerformancePage(),
      ),
      GoRoute(
        path: MoneyfyRoutePaths.dividendInterest,
        name: MoneyfyRouteNames.dividendInterest,
        builder: (context, state) => const DividendInterestAnalysisPage(),
      ),
      GoRoute(
        path: MoneyfyRoutePaths.login,
        name: MoneyfyRouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: MoneyfyRoutePaths.signup,
        name: MoneyfyRouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const _InvalidRoutePage(message: '요청한 화면을 찾을 수 없어요.'),
  );
}

int? _pathInt(GoRouterState state, String key) {
  return int.tryParse(state.pathParameters[key] ?? '');
}

int? _queryInt(GoRouterState state, String key) {
  return int.tryParse(state.uri.queryParameters[key] ?? '');
}

class _InvalidRoutePage extends StatelessWidget {
  const _InvalidRoutePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('경로 오류')),
      body: Center(child: Text(message)),
    );
  }
}
