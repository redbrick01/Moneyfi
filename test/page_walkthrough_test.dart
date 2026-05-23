import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/main.dart';
import 'package:moneyfy/pages/analysis_page.dart';
import 'package:moneyfy/pages/annual_asset_analysis_page.dart';
import 'package:moneyfy/pages/asset_detail_page.dart';
import 'package:moneyfy/pages/cash_account_detail_page.dart';
import 'package:moneyfy/pages/dividend_interest_analysis_page.dart';
import 'package:moneyfy/pages/forms/asset_form_page.dart';
import 'package:moneyfy/pages/forms/cash_account_form_page.dart';
import 'package:moneyfy/pages/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/pages/forms/holding_form_page.dart';
import 'package:moneyfy/pages/forms/transaction_form_page.dart';
import 'package:moneyfy/pages/holding_detail_page.dart';
import 'package:moneyfy/pages/investment_performance_page.dart';
import 'package:moneyfy/pages/login_page.dart';
import 'package:moneyfy/pages/signup_page.dart';
import 'package:moneyfy/pages/snapshot_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settlePage(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    final exception = tester.takeException();
    expect(exception, isNull);
  }

  Future<void> pumpFirstFramePage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, home: page),
    );
    await tester.pump();
    final exception = tester.takeException();
    expect(exception, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final disposeException = tester.takeException();
    expect(disposeException, isNull);
  }

  Future<void> pumpInteractivePage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, home: page),
    );
    await settlePage(tester);
  }

  testWidgets('stage 1: app shell visits every bottom tab', (tester) async {
    await tester.pumpWidget(const MoneyfyApp());
    await settlePage(tester);

    for (final label in const ['홈', '포트폴리오', '분석', '통계', 'My']) {
      await tester.tap(find.text(label).last);
      await settlePage(tester);
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('stage 2: analysis entry cards open their child pages', (
    tester,
  ) async {
    await pumpInteractivePage(tester, const AnalysisPage());

    await tester.scrollUntilVisible(
      find.text('투자성과 분석'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('투자성과 분석').first);
    await settlePage(tester);
    expect(find.text('순수 투자성과'), findsOneWidget);

    Navigator.of(tester.element(find.byType(InvestmentPerformancePage))).pop();
    await settlePage(tester);

    await tester.scrollUntilVisible(
      find.text('배당/이자 분석'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('배당/이자 분석').first);
    await settlePage(tester);
    expect(find.text('배당/이자 총합'), findsOneWidget);
  });

  for (final pageCase in _standalonePageCases) {
    testWidgets('stage 3: ${pageCase.name} builds once', (tester) async {
      await pumpFirstFramePage(tester, pageCase.build(_walkthroughIds));
    });
  }
}

const _walkthroughIds = _WalkthroughIds(
  stockAssetId: -101,
  holdingId: -102,
  cashAssetId: -201,
  cashHoldingId: -202,
);

final _standalonePageCases = <_StandalonePageCase>[
  _StandalonePageCase(
    name: 'asset detail',
    build: (ids) => AssetDetailPage(assetId: ids.stockAssetId),
  ),
  _StandalonePageCase(
    name: 'holding detail',
    build: (ids) => HoldingDetailPage(holdingId: ids.holdingId),
  ),
  _StandalonePageCase(
    name: 'cash account detail',
    build: (ids) => CashAccountDetailPage(holdingId: ids.cashHoldingId),
  ),
  _StandalonePageCase(name: 'asset form', build: (_) => const AssetFormPage()),
  _StandalonePageCase(
    name: 'holding form',
    build: (ids) => HoldingFormPage(assetId: ids.stockAssetId),
  ),
  _StandalonePageCase(
    name: 'cash account form',
    build: (ids) => CashAccountFormPage(assetId: ids.cashAssetId),
  ),
  _StandalonePageCase(
    name: 'transaction form',
    build: (ids) => TransactionFormPage(
      assetId: ids.stockAssetId,
      holdingId: ids.holdingId,
      defaultName: '삼성전자',
    ),
  ),
  _StandalonePageCase(
    name: 'cash transaction form',
    build: (ids) => CashTransactionFormPage(
      assetId: ids.cashAssetId,
      holdingId: ids.cashHoldingId,
      defaultName: '생활비',
    ),
  ),
  _StandalonePageCase(name: 'login', build: (_) => const LoginPage()),
  _StandalonePageCase(name: 'signup', build: (_) => const SignupPage()),
  _StandalonePageCase(
    name: 'investment performance',
    build: (_) => const InvestmentPerformancePage(),
  ),
  _StandalonePageCase(
    name: 'dividend interest analysis',
    build: (_) => const DividendInterestAnalysisPage(),
  ),
  _StandalonePageCase(
    name: 'annual asset analysis',
    build: (ids) {
      final snapshot = _snapshotFor(ids);
      return AnnualAssetAnalysisPage(
        snapshots: [snapshot],
        items: [_snapshotItemFor(ids)],
      );
    },
  ),
  _StandalonePageCase(
    name: 'snapshot detail',
    build: (ids) {
      final snapshot = _snapshotFor(ids);
      return SnapshotDetailPage(
        snapshot: snapshot,
        items: [_snapshotItemFor(ids)],
      );
    },
  ),
];

DailyPortfolioSnapshot _snapshotFor(_WalkthroughIds ids) {
  return const DailyPortfolioSnapshot(
    id: 1,
    snapshotDate: '2026-05-23',
    totalPurchaseAmount: 600000,
    totalValuationAmount: 700000,
    profitAmount: 100000,
    profitRate: 16.67,
    exchangeRate: 1,
    createdAt: '2026-05-23T00:00:00.000',
  );
}

DailyPortfolioSnapshotItem _snapshotItemFor(_WalkthroughIds ids) {
  return DailyPortfolioSnapshotItem(
    id: 1,
    snapshotId: 1,
    assetId: ids.stockAssetId,
    assetTitle: '주식',
    totalPurchaseAmount: 600000,
    totalValuationAmount: 700000,
    profitAmount: 100000,
    profitRate: 16.67,
    holdingCount: 1,
  );
}

class _StandalonePageCase {
  const _StandalonePageCase({required this.name, required this.build});

  final String name;
  final Widget Function(_WalkthroughIds ids) build;
}

class _WalkthroughIds {
  const _WalkthroughIds({
    required this.stockAssetId,
    required this.holdingId,
    required this.cashAssetId,
    required this.cashHoldingId,
  });

  final int stockAssetId;
  final int holdingId;
  final int cashAssetId;
  final int cashHoldingId;
}
