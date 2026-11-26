import 'dart:async';
import 'package:moneyfy/features/account/widgets/snapshot_calendar_section.dart';
import 'package:moneyfy/features/account/widgets/total_asset_history_card.dart';

import 'package:moneyfy/features/analysis/widgets/analysis_news_cards.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/navigation/moneyfy_router.dart';
import 'package:moneyfy/features/analysis/screens/analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/annual_asset_analysis_page.dart';
import 'package:moneyfy/features/portfolio/screens/asset_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/cash_account_detail_page.dart';
import 'package:moneyfy/features/analysis/screens/dividend_interest_analysis_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/asset_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/cash_account_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/holding_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/transaction_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/analysis/screens/investment_performance_page.dart';
import 'package:moneyfy/features/auth/screens/login_page.dart';
import 'package:moneyfy/features/auth/screens/signup_page.dart';
import 'package:moneyfy/features/portfolio/screens/snapshot_detail_page.dart';
import 'package:moneyfy/features/shell/screens/app_shell_page.dart';
import 'package:moneyfy/features/transactions/screens/transactions_page.dart';

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

  testWidgets('logout clears preserved tab data before manual refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 0,
          replacementMessage: null,
          title: '홈',
          child: const Center(child: Text('이전 계정 자산')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('이전 계정 자산'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 1,
          replacementMessage: '로그아웃 정보를 정리하고 있어요.',
          title: '홈',
          child: const Center(child: Text('이전 계정 자산')),
        ),
      ),
    );

    expect(find.text('이전 계정 자산'), findsNothing);
    expect(find.text('로그아웃 정보를 정리하고 있어요.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 2,
          replacementMessage: null,
          title: '홈',
          child: const Center(child: Text('새 계정 데이터 없음')),
        ),
      ),
    );

    expect(find.text('이전 계정 자산'), findsNothing);
    expect(find.text('새 계정 데이터 없음'), findsOneWidget);
  });

  testWidgets('login replacement hides preserved tab data until ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 0,
          replacementMessage: null,
          title: '홈',
          child: const Center(child: Text('로그인 전 데이터')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('로그인 전 데이터'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 1,
          replacementMessage: '로그인 정보를 불러오고 있어요.',
          title: '홈',
          child: const Center(child: Text('로그인 전 데이터')),
        ),
      ),
    );

    expect(find.text('로그인 전 데이터'), findsNothing);
    expect(find.text('로그인 정보를 불러오고 있어요.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: buildDataScopedTabPageForTesting(
          scopeVersion: 2,
          replacementMessage: null,
          title: '홈',
          child: const Center(child: Text('로그인 후 정상 데이터')),
        ),
      ),
    );

    expect(find.text('로그인 전 데이터'), findsNothing);
    expect(find.text('로그인 후 정상 데이터'), findsOneWidget);
  });

  testWidgets('stage 1: app shell visits every bottom tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: buildMoneyfyRouter(useStartupGate: false),
      ),
    );
    await settlePage(tester);

    for (final (label, pageText) in const [
      ('홈', null),
      ('포트폴', '포트폴리오'),
      ('거래', '거래'),
      ('분석', '분석'),
      ('My', 'My'),
    ]) {
      await tester.tap(find.byKey(ValueKey('bottom-tab-$label')));
      await settlePage(tester);
      final selectedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(ValueKey('bottom-tab-$label')),
          matching: find.byType(Icon),
        ),
      );
      expect(selectedIcon.color, VisualSpec.brand.lightSurface);
      if (pageText != null) {
        expect(find.text(pageText), findsWidgets);
      }
    }
  });

  testWidgets('stage 2: analysis entry cards open their child pages', (
    tester,
  ) async {
    await pumpInteractivePage(tester, const AnalysisPage());

    expect(find.text('투자 기록'), findsNothing);
    expect(find.text('투자 회고'), findsNothing);
    expect(find.text('내 포트폴리오'), findsNothing);
    expect(find.text('먼저 확인할 항목'), findsNothing);
    final titles = ['총자산 변화', '내 투자 분석', '리서치·채팅', '종합 뉴스', '종목별 뉴스'];
    expect(
      tester.getTopLeft(find.text('스냅샷 캘린더')).dy,
      greaterThan(tester.getTopLeft(find.text('종목별 뉴스')).dy),
    );
    for (var i = 1; i < titles.length; i++) {
      expect(
        tester.getTopLeft(find.text(titles[i])).dy,
        greaterThan(tester.getTopLeft(find.text(titles[i - 1])).dy),
      );
    }
    for (final (label, destination) in [
      ('투자성과 분석', '순 투자성과'),
      ('배당/이자 분석', '배당/이자 총합'),
      ('포트폴리오 진단', '포트폴리오 진단'),
      ('자산 추이·통계', '자산 추이·통계'),
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await settlePage(tester);
      expect(find.text(destination), findsWidgets);
      if (label == '자산 추이·통계') expect(find.text('총자산 변화'), findsNothing);
      Navigator.of(tester.element(find.text(destination).first)).pop();
      await settlePage(tester);
      expect(find.text('총자산 변화'), findsOneWidget);
    }
    for (final label in ['기업 리서치', 'Reddit 요약', 'RAG채팅']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
  });

  testWidgets('market and company news load independently as separate cards', (
    tester,
  ) async {
    final companies = Completer<List<CompanyNewsSummaryItem>>();
    final market = MarketNewsSummary.fromJson({'market_summary': '시장 동향'});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnalysisNewsCards(
              marketNews: Future.value(market),
              companyNews: companies.future,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('종합 뉴스'), findsOneWidget);
    expect(find.text('종목별 뉴스'), findsOneWidget);
    expect(find.text('시장 동향'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    companies.complete([
      const CompanyNewsSummaryItem(
        symbol: 'AAPL',
        assetType: '주식',
        found: true,
        summary: {'company_summary': '종목 소식'},
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('종목 소식'), findsOneWidget);
    expect(find.text('시장 동향'), findsOneWidget);
  });

  testWidgets('snapshot calendar navigates months and opens a saved date', (
    tester,
  ) async {
    final saved = _snapshotFor(_walkthroughIds);
    await pumpInteractivePage(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SnapshotCalendarSection(
            snapshots: [saved],
            transactionDates: {saved.snapshotDate},
            onRetry: () async {},
          ),
        ),
      ),
    );
    expect(find.text('2026년 5월'), findsOneWidget);
    expect(find.text('월 분기점(1일)'), findsOneWidget);
    for (final text in tester.widgetList<Text>(find.text('1'))) {
      expect(text.style?.color, VisualSpec.brand.brandRed);
    }
    await tester.tap(find.byTooltip('이전 달'));
    await settlePage(tester);
    expect(find.text('2026년 4월'), findsOneWidget);
    await tester.tap(find.byTooltip('다음 달'));
    await settlePage(tester);
    await tester.tap(find.text('23'));
    await settlePage(tester);
    expect(find.byType(SnapshotDetailPage), findsOneWidget);
  });

  testWidgets('annual asset history follows the selected year', (tester) async {
    final latest = _snapshotFor(_walkthroughIds);
    final prior = latest.copyWith(id: 2, snapshotDate: '2025-05-23');
    final item = _snapshotItemFor(_walkthroughIds);
    await pumpInteractivePage(
      tester,
      AnnualAssetAnalysisPage(
        snapshots: [prior, latest],
        items: [
          item,
          item.copyWith(snapshotId: prior.id),
        ],
      ),
    );
    expect(find.text('총자산 변화'), findsOneWidget);
    final chart = find.byType(TotalAssetHistoryCard);
    expect(
      tester.widget<TotalAssetHistoryCard>(chart).snapshots.single.id,
      latest.id,
    );
    await tester.tap(find.byTooltip('이전 연도'));
    await settlePage(tester);
    final historical = tester.widget<TotalAssetHistoryCard>(chart);
    expect(historical.snapshots.single.id, prior.id);
    expect(
      (await historical.loadItems([prior.snapshotDate])).single.snapshotId,
      prior.id,
    );
  });

  test('transactions page groups ledger lines by event id', () {
    final grouped = groupTransactionEventsForTesting(
      const [
        TransactionItem(
          assetId: 1,
          holdingId: -101,
          date: '2026-05-21',
          type: '이체',
          name: '계좌 이동',
          amount: '-250',
          quantity: '',
          cashFlowAmount: -250,
          ledgerEventId: 7,
          ledgerLineId: 11,
          ledgerAction: 'transfer_out',
        ),
        TransactionItem(
          assetId: 1,
          holdingId: -102,
          date: '2026-05-21',
          type: '이체',
          name: '계좌 이동',
          amount: '250',
          quantity: '',
          cashFlowAmount: 250,
          ledgerEventId: 7,
          ledgerLineId: 12,
          ledgerAction: 'transfer_in',
        ),
        TransactionItem(
          assetId: 1,
          holdingId: 201,
          date: '2026-05-22',
          type: '매수',
          name: '대표 투자 라인',
          amount: '100',
          quantity: '2',
          ledgerEventId: 8,
          ledgerLineId: 13,
          ledgerAction: 'buy',
        ),
        TransactionItem(
          assetId: 1,
          holdingId: -103,
          date: '2026-05-22',
          type: '매수',
          name: '현금 결제 라인',
          amount: '-200',
          quantity: '',
          cashFlowAmount: -200,
          ledgerEventId: 8,
          ledgerLineId: 14,
          ledgerAction: 'settlement',
        ),
      ],
      cashHoldingIds: {-101, -102, -103},
    );

    expect(grouped, hasLength(2));
    expect(grouped.map((item) => item.ledgerEventId), [7, 8]);
    expect(grouped.first.ledgerAction, 'transfer_out');
    expect(grouped.last.ledgerAction, 'buy');
  });

  testWidgets('transactions pull refresh downloads remote data first', (
    tester,
  ) async {
    var remoteRefreshCount = 0;

    await pumpInteractivePage(
      tester,
      TransactionsPage(
        remoteRefresh: () async {
          remoteRefreshCount++;
          return true;
        },
      ),
    );

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 360));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(remoteRefreshCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction form exposes market item search', (tester) async {
    await pumpInteractivePage(
      tester,
      TransactionFormPage(
        assetId: _walkthroughIds.stockAssetId,
        holdingId: _walkthroughIds.holdingId,
        defaultName: '삼성전자',
      ),
    );

    expect(find.text('새 종목 검색'), findsOneWidget);
    expect(find.widgetWithText(TextField, '종목명 또는 티커'), findsOneWidget);
  });

  testWidgets('new transaction forms default to calculation included', (
    tester,
  ) async {
    await pumpInteractivePage(
      tester,
      TransactionFormPage(
        assetId: _walkthroughIds.stockAssetId,
        holdingId: _walkthroughIds.holdingId,
        defaultName: '삼성전자',
      ),
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpInteractivePage(
      tester,
      CashTransactionFormPage(
        assetId: _walkthroughIds.cashAssetId,
        holdingId: _walkthroughIds.cashHoldingId,
        defaultName: '생활비',
      ),
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
  });

  testWidgets('investment performance explains redesigned dashboard', (
    tester,
  ) async {
    await pumpInteractivePage(tester, const InvestmentPerformancePage());

    expect(find.text('투자성과 분석'), findsWidgets);
    expect(find.text('성과 스코어보드'), findsWidgets);
    expect(find.text('순 투자성과'), findsWidgets);
    expect(find.text('수익률'), findsWidgets);
    expect(find.text('벤치마크 대비'), findsWidgets);
    expect(find.text('리스크'), findsWidgets);
    expect(find.text('성과 구성'), findsWidgets);
    expect(find.text('자산 변화 대조'), findsWidgets);
    expect(find.text('월별 성과 신호'), findsWidgets);
    expect(find.text('종목별 성과 영향'), findsWidgets);
    expect(find.text('리스크 신호'), findsNothing);
    expect(find.text('Sharpe'), findsNothing);
    expect(find.text('데이터 신뢰도'), findsWidgets);
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
  _StandalonePageCase(
    name: 'transactions',
    build: (_) => const TransactionsPage(),
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
      return SnapshotDetailPage(snapshot: snapshot);
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
    assetClientId: null,
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
