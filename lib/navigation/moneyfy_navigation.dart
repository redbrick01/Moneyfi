import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:moneyfy/features/portfolio/screens/asset_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/cash_account_detail_page.dart';
import 'package:moneyfy/features/analysis/screens/dividend_interest_analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/equity_research_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/asset_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/cash_account_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/transaction_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/analysis/screens/investment_performance_page.dart';
import 'package:moneyfy/features/auth/screens/login_page.dart';
import 'package:moneyfy/features/analysis/screens/portfolio_analysis_mvp_page.dart';
import 'package:moneyfy/features/analysis/screens/reddit_post_summaries_page.dart';
import 'package:moneyfy/features/account/screens/statistics_page.dart';
import 'package:moneyfy/features/auth/screens/signup_page.dart';
import 'moneyfy_routes.dart';

extension MoneyfyNavigation on BuildContext {
  Future<bool?> openAssetCreate() {
    if (!_hasRouter) {
      return Navigator.of(this).push<bool>(
        MaterialPageRoute(
          settings: const RouteSettings(name: MoneyfyRoutePaths.assetCreate),
          builder: (_) => const AssetFormPage(),
        ),
      );
    }
    return push<bool>(MoneyfyRoutePaths.assetCreate);
  }

  Future<bool?> openAssetBuyCreate({required int assetId}) {
    if (!_hasRouter) {
      return Navigator.of(this).push<bool>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.assetBuyCreate(assetId),
          ),
          builder: (_) => TransactionFormPage(
            assetId: assetId,
            holdingId: null,
            assetBuyMode: true,
          ),
        ),
      );
    }
    return push<bool>(MoneyfyRoutePaths.assetBuyCreate(assetId));
  }

  Future<bool?> openHoldingCreate({required int assetId}) {
    return openAssetBuyCreate(assetId: assetId);
  }

  Future<bool?> openCashAccountCreate({required int assetId}) {
    if (!_hasRouter) {
      return Navigator.of(this).push<bool>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.cashAccountCreate(assetId),
          ),
          builder: (_) => CashAccountFormPage(assetId: assetId),
        ),
      );
    }
    return push<bool>(MoneyfyRoutePaths.cashAccountCreate(assetId));
  }

  Future<bool?> openTransactionCreate({
    required int assetId,
    required int holdingId,
    String? holdingClientId,
    String? defaultName,
  }) {
    if (!_hasRouter) {
      return Navigator.of(this).push<bool>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.transactionCreate(holdingId),
          ),
          builder: (_) => TransactionFormPage(
            assetId: assetId,
            holdingId: holdingId,
            holdingClientId: holdingClientId,
            defaultName: defaultName,
          ),
        ),
      );
    }
    return push<bool>(
      MoneyfyRoutePaths.transactionCreateWithArgs(
        assetId: assetId,
        holdingId: holdingId,
        holdingClientId: holdingClientId,
        defaultName: defaultName,
      ),
    );
  }

  Future<bool?> openCashTransactionCreate({
    required int assetId,
    required int holdingId,
    String? holdingClientId,
    String? defaultName,
  }) {
    if (!_hasRouter) {
      return Navigator.of(this).push<bool>(
        MaterialPageRoute(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.cashTransactionCreate(holdingId),
          ),
          builder: (_) => CashTransactionFormPage(
            assetId: assetId,
            holdingId: holdingId,
            holdingClientId: holdingClientId,
            defaultName: defaultName,
          ),
        ),
      );
    }
    return push<bool>(
      MoneyfyRoutePaths.cashTransactionCreateWithArgs(
        assetId: assetId,
        holdingId: holdingId,
        holdingClientId: holdingClientId,
        defaultName: defaultName,
      ),
    );
  }

  Future<void> openAssetDetail(AssetDetailRouteArgs args) {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.assetDetail(args.assetId),
            arguments: args,
          ),
          builder: (_) => AssetDetailPage(
            assetId: args.assetId,
            assetClientId: args.assetClientId,
          ),
        ),
      );
    }
    return push<void>(
      MoneyfyRoutePaths.assetDetailWithClientId(
        args.assetId,
        args.assetClientId,
      ),
    );
  }

  Future<void> openHoldingDetail(HoldingDetailRouteArgs args) {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.holdingDetail(args.holdingId),
            arguments: args,
          ),
          builder: (_) => HoldingDetailPage(
            holdingId: args.holdingId,
            holdingClientId: args.holdingClientId,
          ),
        ),
      );
    }
    return push<void>(
      MoneyfyRoutePaths.holdingDetailWithClientId(
        args.holdingId,
        args.holdingClientId,
      ),
    );
  }

  Future<void> openCashAccountDetail(CashAccountDetailRouteArgs args) {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: MoneyfyRoutePaths.cashAccountDetail(args.holdingId),
            arguments: args,
          ),
          builder: (_) => CashAccountDetailPage(
            holdingId: args.holdingId,
            holdingClientId: args.holdingClientId,
          ),
        ),
      );
    }
    return push<void>(
      MoneyfyRoutePaths.cashAccountDetailWithClientId(
        args.holdingId,
        args.holdingClientId,
      ),
    );
  }

  Future<void> openPortfolioDiagnosis() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: MoneyfyRoutePaths.portfolioDiagnosis,
          ),
          builder: (_) => const PortfolioAnalysisMvpPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.portfolioDiagnosis);
  }

  Future<void> openInvestmentPerformance() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: MoneyfyRoutePaths.investmentPerformance,
          ),
          builder: (_) => const InvestmentPerformancePage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.investmentPerformance);
  }

  Future<void> openDividendInterest() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: MoneyfyRoutePaths.dividendInterest,
          ),
          builder: (_) => const DividendInterestAnalysisPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.dividendInterest);
  }

  Future<void> openEquityResearch({String? ticker}) {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: MoneyfyRoutePaths.equityResearch),
          builder: (_) => EquityResearchPage(initialTicker: ticker),
        ),
      );
    }
    final normalizedTicker = ticker?.trim().toUpperCase() ?? '';
    return push<void>(
      normalizedTicker.isEmpty
          ? MoneyfyRoutePaths.equityResearch
          : MoneyfyRoutePaths.equityResearchForTicker(normalizedTicker),
    );
  }

  Future<void> openRedditPostSummaries() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: MoneyfyRoutePaths.redditPostSummaries,
          ),
          builder: (_) => const RedditPostSummariesPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.redditPostSummaries);
  }

  Future<void> openStatistics() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: MoneyfyRoutePaths.statistics),
          builder: (_) => const StatisticsPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.statistics);
  }

  Future<void> openLogin() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: MoneyfyRoutePaths.login),
          builder: (_) => const LoginPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.login);
  }

  Future<void> openSignup() {
    if (!_hasRouter) {
      return Navigator.of(this).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: MoneyfyRoutePaths.signup),
          builder: (_) => const SignupPage(),
        ),
      );
    }
    return push<void>(MoneyfyRoutePaths.signup);
  }

  bool get _hasRouter => GoRouter.maybeOf(this) != null;
}
