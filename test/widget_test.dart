import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/components/cards/investment_review_home_card.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/models/asset_item.dart';
import 'package:moneyfy/navigation/moneyfy_router.dart';
import 'package:moneyfy/pages/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/pages/forms/transaction_form_page.dart';
import 'package:moneyfy/pages/investment_performance_page.dart';
import 'package:moneyfy/pages/investment_review_page.dart';
import 'package:moneyfy/pages/portfolio_dashboard_page.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';
import 'package:moneyfy/utils/input_validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('period unrealized profit subtracts baseline snapshot profit', () {
    expect(
      calculatePeriodUnrealizedProfit(
        currentUnrealizedProfit: 5600000,
        baselineUnrealizedProfit: 2500000,
      ),
      3100000,
    );
    expect(
      calculatePeriodUnrealizedProfit(currentUnrealizedProfit: 5600000),
      5600000,
    );
  });

  test(
    'manual realized profit validator allows losses only when requested',
    () {
      final defaultValidation = MoneyfyInputValidators.decimal(
        '-1200',
        fieldName: '실현손익',
      );
      final realizedProfitValidation = MoneyfyInputValidators.decimal(
        '-1200',
        fieldName: '실현손익',
        allowNegative: true,
      );

      expect(defaultValidation.isValid, isFalse);
      expect(realizedProfitValidation.isValid, isTrue);
      expect(realizedProfitValidation.value, -1200);
    },
  );

  test('performance rate uses buy amount as basis', () {
    expect(calculatePerformanceRate(250000, 1000000), 25);
    expect(calculatePerformanceRate(-50000, 1000000), -5);
    expect(calculatePerformanceRate(250000, 0), isNull);
  });

  HoldingItem holding({
    required int id,
    required String name,
    required double quantity,
  }) {
    return HoldingItem(
      id: id,
      assetId: 1,
      assetType: '가상화폐',
      currencyCode: 'KRW',
      name: name,
      symbol: name.toUpperCase(),
      quantity: quantity,
      averagePrice: 100,
      currentPrice: 110,
      note: '',
      transactions: const [],
    );
  }

  AssetItem assetWithHoldings(List<HoldingItem> holdings) {
    return AssetItem(
      id: 1,
      assetType: '가상화폐',
      title: '가상화폐',
      alias: '가상화폐',
      currencyCode: 'KRW',
      value: '0',
      change: '0%',
      icon: Icons.currency_bitcoin_rounded,
      quantityLabel: '항목',
      quantityValue: '${holdings.length}개',
      averageLabel: '수익률',
      averageValue: '0%',
      note: '',
      holdings: holdings,
      transactions: const [],
    );
  }

  HoldingItem cashHolding({
    required int id,
    required String name,
    required double balance,
    String currencyCode = 'KRW',
  }) {
    return HoldingItem(
      id: id,
      assetId: 1,
      assetType: '가상화폐',
      currencyCode: currencyCode,
      name: name,
      symbol: '',
      quantity: balance,
      averagePrice: 1,
      currentPrice: 1,
      note: '',
      transactions: const [],
    );
  }

  Future<void> pumpTransactionForm(
    WidgetTester tester, {
    required List<HoldingItem> holdings,
    int holdingId = 1,
    TransactionItem? item,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TransactionFormPage(
          assetId: 1,
          holdingId: holdingId,
          item: item,
          assetsFutureForTesting: Future.value([assetWithHoldings(holdings)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCashTransactionForm(
    WidgetTester tester, {
    required List<HoldingItem> holdings,
    int holdingId = -1,
    TransactionItem? item,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CashTransactionFormPage(
          assetId: 1,
          holdingId: holdingId,
          item: item,
          assetsFutureForTesting: Future.value([assetWithHoldings(holdings)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField quantityTextField(WidgetTester tester) {
    return tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText == '매도 수량' ||
                widget.decoration?.hintText == '매수 수량'),
      ),
    );
  }

  Finder quantityTextFieldFinder() {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == '매도 수량',
    );
  }

  TextField amountTextField(WidgetTester tester, String hintText) {
    return tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == hintText,
      ),
    );
  }

  Finder amountTextFieldFinder(String hintText) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == hintText,
    );
  }

  InvestmentReviewReport reviewReport(String headline) {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 5, 31),
    );
    return InvestmentReviewReport(
      period: period,
      metrics: const [],
      signals: const [],
      narrative: InvestmentReviewNarrative(
        headline: headline,
        summary: '요약입니다.',
        nextActions: const ['다음 액션입니다.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: const InvestmentReviewActivitySummary(),
    );
  }

  InvestmentReviewReport todayReviewReport({
    required String headline,
    InvestmentReviewActivitySummary activity =
        const InvestmentReviewActivitySummary(),
  }) {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 6),
    );
    return InvestmentReviewReport(
      period: period,
      metrics: const [
        InvestmentReviewMetric(label: '순 투자성과', value: '+12,000원'),
      ],
      signals: const [
        InvestmentReviewSignal(title: '분산 점검', description: '비중을 확인하세요.'),
      ],
      narrative: InvestmentReviewNarrative(
        headline: headline,
        summary: '오늘 자동 초안 요약입니다.',
        nextActions: const ['내일 확인할 가격을 정하세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: activity,
      generatedAt: DateTime(2026, 6, 1, 18, 30),
    );
  }

  DailyInvestmentReviewEntry dailyReviewEntry({
    required DailyInvestmentReviewStatus status,
    required DailyInvestmentReviewMode mode,
  }) {
    return DailyInvestmentReviewEntry(
      id: 1,
      reviewDate: DateTime(2026, 6),
      status: status,
      mode: mode,
      performanceNote: '성과 메모',
      tradeReviewNote: '매매 복기 메모',
      selectedDecisionTags: const ['계획 매매'],
      selectedNoTradeReasons: const ['목표 가격 대기'],
      selectedEmotions: const ['차분함'],
      principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
      riskNote: '리스크 메모',
      insightGood: '잘한 점',
      insightWeak: '아쉬운 점',
      insightRepeatOrAvoid: '반복할 점',
      nextPlan: '다음 계획',
      createdAt: DateTime(2026, 6, 1, 18),
      updatedAt: DateTime(2026, 6, 1, 18, 10),
    );
  }

  Future<void> ensureSellShortcutVisible(
    WidgetTester tester,
    int percent,
  ) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('sell-quantity-shortcut-$percent')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> ensureShortcutVisible(
    WidgetTester tester,
    String keyPrefix,
    int percent,
  ) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('$keyPrefix-$percent')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> ensureTextFieldVisible(
    WidgetTester tester,
    String hintText,
  ) async {
    await tester.scrollUntilVisible(
      amountTextFieldFinder(hintText),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Moneyfy app renders shell smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: buildMoneyfyRouter(useStartupGate: false),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bottom-tab-홈')).evaluate().isNotEmpty ||
          find.text('Moneyfy').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('sell quantity shortcuts appear only for sell type', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [holding(id: 1, name: 'btc', quantity: 0.12345678)],
    );

    expect(
      find.byKey(const ValueKey('sell-quantity-shortcut-100')),
      findsNothing,
    );

    await tester.tap(find.text('매도'));
    await tester.pumpAndSettle();
    await ensureSellShortcutVisible(tester, 100);
    expect(
      find.byKey(const ValueKey('sell-quantity-shortcut-100')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('매수'),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('매수'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('sell-quantity-shortcut-100')),
      findsNothing,
    );
  });

  testWidgets('sell quantity shortcuts fill crypto-scale percentages', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [holding(id: 1, name: 'btc', quantity: 0.12345678)],
    );
    await tester.tap(find.text('매도'));
    await tester.pumpAndSettle();
    await ensureSellShortcutVisible(tester, 100);

    await tester.tap(find.byKey(const ValueKey('sell-quantity-shortcut-100')));
    await tester.pumpAndSettle();
    expect(quantityTextField(tester).controller!.text, '0.12345678');

    await ensureSellShortcutVisible(tester, 50);
    await tester.tap(find.byKey(const ValueKey('sell-quantity-shortcut-50')));
    await tester.pumpAndSettle();
    expect(quantityTextField(tester).controller!.text, '0.06172839');
  });

  testWidgets('sell shortcut value can be manually edited', (tester) async {
    await pumpTransactionForm(
      tester,
      holdings: [holding(id: 1, name: 'btc', quantity: 0.12345678)],
    );
    await tester.tap(find.text('매도'));
    await tester.pumpAndSettle();
    await ensureSellShortcutVisible(tester, 100);
    await tester.tap(find.byKey(const ValueKey('sell-quantity-shortcut-100')));
    await tester.pumpAndSettle();

    await tester.enterText(quantityTextFieldFinder(), '0.01');
    await tester.pumpAndSettle();
    expect(quantityTextField(tester).controller!.text, '0.01');
  });

  testWidgets('sell edit shortcut restores existing sell quantity', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [holding(id: 1, name: 'btc', quantity: 0.07345678)],
      item: const TransactionItem(
        id: 10,
        assetId: 1,
        holdingId: 1,
        date: '2026.05.28',
        type: '매도',
        name: '기존 매도',
        amount: '100',
        quantity: '0.05',
      ),
    );

    await ensureSellShortcutVisible(tester, 100);
    await tester.tap(find.byKey(const ValueKey('sell-quantity-shortcut-100')));
    await tester.pumpAndSettle();
    expect(quantityTextField(tester).controller!.text, '0.12345678');
  });

  testWidgets('sell shortcut uses newly selected holding quantity', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdingId: 2,
      holdings: [
        holding(id: 1, name: 'new coin', quantity: 0.2),
        holding(id: 2, name: 'old coin', quantity: 0.07345678),
      ],
      item: const TransactionItem(
        id: 10,
        assetId: 1,
        holdingId: 2,
        date: '2026.05.28',
        type: '매도',
        name: '기존 매도',
        amount: '100',
        quantity: '0.05',
      ),
    );

    await tester.tap(find.text('old coin').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('new coin').last);
    await tester.pumpAndSettle();
    await ensureSellShortcutVisible(tester, 100);
    await tester.tap(find.byKey(const ValueKey('sell-quantity-shortcut-100')));
    await tester.pumpAndSettle();

    expect(quantityTextField(tester).controller!.text, '0.2');
  });

  testWidgets('cash withdrawal shortcut fills source balance', (tester) async {
    await pumpCashTransactionForm(
      tester,
      holdings: [cashHolding(id: -1, name: 'KRW cash', balance: 1000)],
    );

    await tester.tap(find.text('출금'));
    await tester.pumpAndSettle();
    await ensureShortcutVisible(tester, 'cash-amount-shortcut', 100);
    await tester.tap(find.byKey(const ValueKey('cash-amount-shortcut-100')));
    await tester.pumpAndSettle();

    expect(amountTextField(tester, '출금 금액').controller!.text, '1000');
  });

  testWidgets('cash withdrawal edit shortcut restores calculated withdrawal', (
    tester,
  ) async {
    await pumpCashTransactionForm(
      tester,
      holdings: [cashHolding(id: -1, name: 'KRW cash', balance: 800)],
      item: const TransactionItem(
        id: -10,
        assetId: 1,
        holdingId: -1,
        date: '2026.05.28',
        type: '출금',
        name: '기존 출금',
        amount: '200',
        quantity: '',
      ),
    );

    await ensureShortcutVisible(tester, 'cash-amount-shortcut', 100);
    await tester.tap(find.byKey(const ValueKey('cash-amount-shortcut-100')));
    await tester.pumpAndSettle();

    expect(amountTextField(tester, '출금 금액').controller!.text, '1000');
  });

  testWidgets(
    'record-only cash withdrawal edit shortcut does not restore amount',
    (tester) async {
      await pumpCashTransactionForm(
        tester,
        holdings: [cashHolding(id: -1, name: 'KRW cash', balance: 1000)],
        item: const TransactionItem(
          id: -10,
          assetId: 1,
          holdingId: -1,
          date: '2026.05.28',
          type: '출금',
          name: '기록용 출금',
          amount: '200',
          quantity: '',
          includeInCalculations: false,
        ),
      );

      await ensureShortcutVisible(tester, 'cash-amount-shortcut', 100);
      await tester.tap(find.byKey(const ValueKey('cash-amount-shortcut-100')));
      await tester.pumpAndSettle();

      expect(amountTextField(tester, '출금 금액').controller!.text, '1000');
    },
  );

  testWidgets('cash transfer shortcut uses half of source balance', (
    tester,
  ) async {
    await pumpCashTransactionForm(
      tester,
      holdings: [
        cashHolding(id: -1, name: 'source', balance: 1000),
        cashHolding(id: -2, name: 'target', balance: 0),
      ],
    );

    await tester.tap(find.text('이체'));
    await tester.pumpAndSettle();
    await ensureShortcutVisible(tester, 'cash-amount-shortcut', 50);
    await tester.tap(find.byKey(const ValueKey('cash-amount-shortcut-50')));
    await tester.pumpAndSettle();

    expect(amountTextField(tester, '이체 금액').controller!.text, '500');
  });

  testWidgets('cash exchange shortcut works without exchange rate', (
    tester,
  ) async {
    await pumpCashTransactionForm(
      tester,
      holdings: [cashHolding(id: -1, name: 'USD cash', balance: 1000)],
    );

    await tester.tap(find.text('환전'));
    await tester.pumpAndSettle();
    await ensureShortcutVisible(tester, 'cash-amount-shortcut', 75);
    await tester.tap(find.byKey(const ValueKey('cash-amount-shortcut-75')));
    await tester.pumpAndSettle();

    expect(amountTextField(tester, '환전할 원천 금액').controller!.text, '750');
  });

  testWidgets(
    'buy shortcut fills quantity from settlement cash and unit price',
    (tester) async {
      await pumpTransactionForm(
        tester,
        holdings: [
          holding(id: 1, name: 'btc', quantity: 0),
          cashHolding(id: -1, name: 'KRW cash', balance: 1000),
        ],
      );

      await ensureTextFieldVisible(tester, '매수 단가');
      await tester.enterText(amountTextFieldFinder('매수 단가'), '100');
      await tester.pumpAndSettle();
      await ensureShortcutVisible(tester, 'buy-cash-shortcut', 100);
      await tester.tap(find.byKey(const ValueKey('buy-cash-shortcut-100')));
      await tester.pumpAndSettle();

      await ensureTextFieldVisible(tester, '매수 수량');
      expect(quantityTextField(tester).controller!.text, '10');
    },
  );

  testWidgets('buy edit shortcut restores calculated buy spending', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [
        holding(id: 1, name: 'btc', quantity: 5),
        cashHolding(id: -1, name: 'KRW cash', balance: 500),
      ],
      item: const TransactionItem(
        id: 10,
        assetId: 1,
        holdingId: 1,
        date: '2026.05.28',
        type: '매수',
        name: '기존 매수',
        amount: '100',
        quantity: '5',
      ),
    );

    await ensureShortcutVisible(tester, 'buy-cash-shortcut', 100);
    await tester.tap(find.byKey(const ValueKey('buy-cash-shortcut-100')));
    await tester.pumpAndSettle();

    await ensureTextFieldVisible(tester, '매수 수량');
    expect(quantityTextField(tester).controller!.text, '10');
  });

  testWidgets('record-only buy edit shortcut does not restore spending', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [
        holding(id: 1, name: 'btc', quantity: 0),
        cashHolding(id: -1, name: 'KRW cash', balance: 1000),
      ],
      item: const TransactionItem(
        id: 10,
        assetId: 1,
        holdingId: 1,
        date: '2026.05.28',
        type: '매수',
        name: '기록용 매수',
        amount: '100',
        quantity: '5',
        includeInCalculations: false,
      ),
    );

    await ensureShortcutVisible(tester, 'buy-cash-shortcut', 100);
    await tester.tap(find.byKey(const ValueKey('buy-cash-shortcut-100')));
    await tester.pumpAndSettle();

    await ensureTextFieldVisible(tester, '매수 수량');
    expect(quantityTextField(tester).controller!.text, '10');
  });

  testWidgets('record-only sell still shows manual realized profit input', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [holding(id: 1, name: 'btc', quantity: 5)],
    );

    await tester.tap(find.text('매도'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('포트폴리오 계산에 반영'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('실현손익'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('실현손익'), findsOneWidget);
    expect(find.text('자동 계산'), findsOneWidget);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();

    await ensureTextFieldVisible(tester, '실현손익 금액');
    expect(find.widgetWithText(TextField, '실현손익 금액'), findsOneWidget);
  });

  testWidgets('buy shortcut is disabled before unit price is entered', (
    tester,
  ) async {
    await pumpTransactionForm(
      tester,
      holdings: [
        holding(id: 1, name: 'btc', quantity: 0),
        cashHolding(id: -1, name: 'KRW cash', balance: 1000),
      ],
    );

    await ensureShortcutVisible(tester, 'buy-cash-shortcut', 100);
    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('buy-cash-shortcut-100')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'investment review page shows period segments and low-data state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestmentReviewPage(
            reportBuilderForTesting: (type) async {
              final period = InvestmentReviewPeriodResolver.resolve(
                type,
                now: DateTime(2026, 5, 31),
              );
              return InvestmentReviewReport(
                period: period,
                metrics: const [],
                signals: const [],
                narrative: InvestmentReviewNarrative(
                  headline: '${period.label} 회고를 만들 기록이 더 필요해요.',
                  summary: '거래나 스냅샷 기록이 쌓이면 보여드릴게요.',
                  nextActions: const ['거래와 스냅샷 기록을 먼저 쌓아보세요.'],
                ),
                aiState: const InvestmentReviewAiState.off(),
                hasEnoughData: false,
                activity: const InvestmentReviewActivitySummary(
                  buyCount: 0,
                  sellCount: 0,
                  incomeCount: 0,
                  cashFlowCount: 0,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('투자 회고'), findsOneWidget);
      expect(find.text('오늘'), findsWidgets);
      expect(find.text('주간'), findsWidgets);
      expect(find.text('월간'), findsWidgets);
      expect(find.text('오늘 회고를 만들 기록이 더 필요해요.'), findsOneWidget);
    },
  );

  testWidgets(
    'investment review page shows loading instead of stale data while switching periods',
    (tester) async {
      InvestmentReviewReport reportFor(
        InvestmentReviewPeriodType type,
        String headline,
      ) {
        final period = InvestmentReviewPeriodResolver.resolve(
          type,
          now: DateTime(2026, 5, 31),
        );
        return InvestmentReviewReport(
          period: period,
          metrics: const [],
          signals: const [],
          narrative: InvestmentReviewNarrative(
            headline: headline,
            summary: '요약입니다.',
            nextActions: const ['다음 액션입니다.'],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: true,
          activity: const InvestmentReviewActivitySummary(buyCount: 1),
        );
      }

      final weeklyCompleter = Completer<InvestmentReviewReport>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestmentReviewPage(
            reportBuilderForTesting: (type) {
              if (type == InvestmentReviewPeriodType.weekly) {
                return weeklyCompleter.future;
              }
              return Future.value(reportFor(type, '오늘 회고가 준비됐어요.'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 회고가 준비됐어요.'), findsOneWidget);

      await tester.tap(find.text('주간'));
      await tester.pump();

      expect(find.text('오늘 회고가 준비됐어요.'), findsNothing);
      expect(find.text('투자 회고를 불러오는 중이에요.'), findsOneWidget);

      weeklyCompleter.complete(
        reportFor(InvestmentReviewPeriodType.weekly, '주간 회고가 준비됐어요.'),
      );
      await tester.pumpAndSettle();

      expect(find.text('주간 회고가 준비됐어요.'), findsOneWidget);
    },
  );

  testWidgets(
    'weekly and monthly investment reviews remain read-only reports',
    (tester) async {
      InvestmentReviewReport reportFor(InvestmentReviewPeriodType type) {
        final period = InvestmentReviewPeriodResolver.resolve(
          type,
          now: DateTime(2026, 6),
        );
        final periodName = switch (type) {
          InvestmentReviewPeriodType.today => '오늘',
          InvestmentReviewPeriodType.weekly => '주간',
          InvestmentReviewPeriodType.monthly => '월간',
        };
        return InvestmentReviewReport(
          period: period,
          metrics: [
            InvestmentReviewMetric(
              label: '$periodName 순 투자성과',
              value: '+12,000원',
            ),
          ],
          signals: [
            InvestmentReviewSignal(
              title: '$periodName 분산 점검',
              description: '비중을 확인하세요.',
            ),
          ],
          narrative: InvestmentReviewNarrative(
            headline: '$periodName 회고가 준비됐어요.',
            summary: '$periodName 자동 요약입니다.',
            nextActions: const ['다음 액션을 확인하세요.'],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: true,
          activity: const InvestmentReviewActivitySummary(buyCount: 1),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestmentReviewPage(
            reportBuilderForTesting: (type) async => reportFor(type),
            dailyReviewLoaderForTesting: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('성과 분석'), findsWidgets);

      await tester.tap(find.text('주간'));
      await tester.pumpAndSettle();

      expect(find.text('주간 회고가 준비됐어요.'), findsOneWidget);
      expect(find.text('주요 지표'), findsOneWidget);
      expect(find.text('리뷰 신호'), findsOneWidget);
      expect(find.text('성과 분석'), findsNothing);

      await tester.tap(find.text('월간'));
      await tester.pumpAndSettle();

      expect(find.text('월간 회고가 준비됐어요.'), findsOneWidget);
      expect(find.text('주요 지표'), findsOneWidget);
      expect(find.text('리뷰 신호'), findsOneWidget);
      expect(find.text('성과 분석'), findsNothing);
    },
  );

  testWidgets(
    'today investment review no-trade composer shows draft prompts and reasons',
    (tester) async {
      DateTime? loadedDate;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestmentReviewPage(
            reportBuilderForTesting: (_) async =>
                todayReviewReport(headline: '오늘 관망 회고가 준비됐어요.'),
            dailyReviewLoaderForTesting: (date) async {
              loadedDate = date;
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loadedDate, DateTime(2026, 6));
      for (final label in [
        '초안 생성됨',
        '작성 중',
        '완료',
        '자동 초안',
        '성과 분석',
        '관망 회고',
        '리스크/멘탈 점검',
        '핵심 인사이트',
        '다음 투자 계획',
        '임시 저장',
        '회고 완료',
        '수정하기',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      for (final reason in [
        '원칙에 맞는 기회가 없었음',
        '목표 가격 대기',
        '현금 비중 유지',
        '추가 분석 필요',
        '변동성이 커서 관망',
        '충동 매매를 참음',
        '특별히 기록할 변화 없음',
      ]) {
        expect(find.text(reason), findsOneWidget);
      }
      expect(find.text('계획 매매'), findsNothing);
    },
  );

  testWidgets(
    'today investment review trading composer shows decision prompts and calls actions',
    (tester) async {
      DailyInvestmentReviewDraft? savedDraft;
      DateTime? completedDate;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: InvestmentReviewPage(
            reportBuilderForTesting: (_) async => todayReviewReport(
              headline: '오늘 매매 회고가 준비됐어요.',
              activity: const InvestmentReviewActivitySummary(buyCount: 1),
            ),
            dailyReviewLoaderForTesting: (_) async => dailyReviewEntry(
              status: DailyInvestmentReviewStatus.inProgress,
              mode: DailyInvestmentReviewMode.tradingDay,
            ),
            dailyReviewSaveForTesting: (draft) async {
              savedDraft = draft;
            },
            dailyReviewCompleteForTesting: (date) async {
              completedDate = date;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in [
        '매매 복기',
        '계획 매매',
        '리밸런싱',
        '손절/익절 원칙',
        'FOMO',
        '소문/추천',
        '충동 매매',
        '차분함',
        '불안함',
        '원칙 준수',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.text('관망 회고'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('임시 저장'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('임시 저장'));
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.mode, DailyInvestmentReviewMode.tradingDay);

      await tester.scrollUntilVisible(
        find.text('회고 완료'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('회고 완료'));
      await tester.pumpAndSettle();

      expect(completedDate, DateTime(2026, 6));
    },
  );

  testWidgets('today investment review save success SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestmentReviewPage(
          reportBuilderForTesting: (_) async =>
              todayReviewReport(headline: '오늘 회고가 준비됐어요.'),
          dailyReviewLoaderForTesting: (_) async => null,
          dailyReviewSaveForTesting: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('임시 저장'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('임시 저장'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 회고를 저장했어요.'), findsOneWidget);
  });

  testWidgets(
    'today investment review save failure keeps form and shows SnackBar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InvestmentReviewPage(
              reportBuilderForTesting: (_) async =>
                  todayReviewReport(headline: '오늘 회고가 준비됐어요.'),
              dailyReviewLoaderForTesting: (_) async => null,
              dailyReviewSaveForTesting: (_) async {
                throw Exception('save failed');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '성과 기록 유지');
      await tester.scrollUntilVisible(
        find.text('임시 저장'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('임시 저장'));
      await tester.pumpAndSettle();

      expect(find.text('회고를 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      final performanceField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(performanceField.controller!.text, '성과 기록 유지');
    },
  );

  testWidgets(
    'today investment review discard confirmation preserves edits when continuing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InvestmentReviewPage(
                            reportBuilderForTesting: (_) async =>
                                todayReviewReport(headline: '오늘 회고가 준비됐어요.'),
                            dailyReviewLoaderForTesting: (_) async => null,
                          ),
                        ),
                      );
                    },
                    child: const Text('회고 열기'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('회고 열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '나가기 전 작성');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('저장하지 않은 회고가 있어요'), findsOneWidget);
      expect(find.text('저장하지 않고 나가면 작성 중인 내용이 사라집니다.'), findsOneWidget);
      expect(find.text('계속 작성'), findsOneWidget);
      expect(find.text('나가기'), findsOneWidget);

      await tester.tap(find.text('계속 작성'));
      await tester.pumpAndSettle();

      expect(find.text('저장하지 않은 회고가 있어요'), findsNothing);
      final performanceField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(performanceField.controller!.text, '나가기 전 작성');
    },
  );

  testWidgets(
    'today investment review complete saves current draft before completing',
    (tester) async {
      DailyInvestmentReviewDraft? savedDraft;
      DateTime? completedDate;
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InvestmentReviewPage(
              reportBuilderForTesting: (_) async =>
                  todayReviewReport(headline: '오늘 회고가 준비됐어요.'),
              dailyReviewLoaderForTesting: (_) async => null,
              dailyReviewSaveForTesting: (draft) async {
                savedDraft = draft;
                events.add('save:${draft.performanceNote}');
              },
              dailyReviewCompleteForTesting: (date) async {
                completedDate = date;
                events.add('complete');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '완료 직전 성과 기록');
      await tester.scrollUntilVisible(
        find.text('회고 완료'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('회고 완료'));
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.performanceNote, '완료 직전 성과 기록');
      expect(completedDate, DateTime(2026, 6));
      expect(events, ['save:완료 직전 성과 기록', 'complete']);
    },
  );

  testWidgets(
    'today investment review complete failure keeps form and shows SnackBar',
    (tester) async {
      DailyInvestmentReviewDraft? savedDraft;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InvestmentReviewPage(
              reportBuilderForTesting: (_) async =>
                  todayReviewReport(headline: '오늘 회고가 준비됐어요.'),
              dailyReviewLoaderForTesting: (_) async => null,
              dailyReviewSaveForTesting: (draft) async {
                savedDraft = draft;
              },
              dailyReviewCompleteForTesting: (_) async {
                throw Exception('complete failed');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '완료 실패 후 유지');
      await tester.scrollUntilVisible(
        find.text('회고 완료'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('회고 완료'));
      await tester.pumpAndSettle();

      expect(savedDraft, isNotNull);
      expect(savedDraft!.performanceNote, '완료 실패 후 유지');
      expect(find.text('회고를 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      final performanceField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(performanceField.controller!.text, '완료 실패 후 유지');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('저장하지 않은 회고가 있어요'), findsNothing);
    },
  );

  testWidgets('investment review home card shows draft status and action', (
    tester,
  ) async {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 5, 31),
    );
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InvestmentReviewHomeCard(
            reviewStatus: DailyInvestmentReviewComposerStatus.draft,
            report: InvestmentReviewReport(
              period: period,
              metrics: const [
                InvestmentReviewMetric(label: '순 투자성과', value: '+10,000원'),
              ],
              signals: const [],
              narrative: const InvestmentReviewNarrative(
                headline: '오늘은 성과 개선이 보여요.',
                summary: '순 투자성과 +10,000원 기준으로 확인했습니다.',
                nextActions: ['비중을 확인해 보세요.'],
              ),
              aiState: const InvestmentReviewAiState.off(),
              hasEnoughData: true,
              activity: const InvestmentReviewActivitySummary(
                buyCount: 0,
                sellCount: 0,
                incomeCount: 0,
                cashFlowCount: 0,
              ),
            ),
            onOpen: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('오늘의 투자 회고'), findsOneWidget);
    expect(find.text('오늘 회고 초안이 준비됐어요'), findsOneWidget);
    expect(find.text('비중을 확인해 보세요.'), findsOneWidget);
    expect(find.text('오늘은 성과 개선이 보여요.'), findsNothing);
    await tester.tap(find.text('작성하기'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'investment review home card shows in-progress status and action',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InvestmentReviewHomeCard(
              reviewStatus: DailyInvestmentReviewComposerStatus.inProgress,
              report: reviewReport('오늘은 성과 개선이 보여요.'),
              onOpen: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('작성 중인 회고가 있어요'), findsOneWidget);
      await tester.tap(find.text('이어쓰기'));
      expect(tapped, isTrue);
    },
  );

  testWidgets('investment review home card shows completed status and action', (
    tester,
  ) async {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 5, 31),
    );
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InvestmentReviewHomeCard(
            reviewStatus: DailyInvestmentReviewComposerStatus.completed,
            report: InvestmentReviewReport(
              period: period,
              metrics: const [
                InvestmentReviewMetric(label: '순 투자성과', value: '+10,000원'),
              ],
              signals: const [],
              narrative: const InvestmentReviewNarrative(
                headline: '오늘은 성과 개선이 보여요.',
                summary: '순 투자성과 +10,000원 기준으로 확인했습니다.',
                nextActions: ['비중을 확인해 보세요.', '현금 비중을 점검해 보세요.', '분산을 확인하세요.'],
              ),
              aiState: const InvestmentReviewAiState.off(),
              hasEnoughData: true,
              activity: const InvestmentReviewActivitySummary(
                buyCount: 0,
                sellCount: 0,
                incomeCount: 0,
                cashFlowCount: 0,
              ),
            ),
            onOpen: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('오늘의 투자 회고'), findsOneWidget);
    expect(find.text('오늘 회고 완료'), findsOneWidget);
    expect(find.text('비중을 확인해 보세요.'), findsOneWidget);
    expect(find.text('현금 비중을 점검해 보세요.'), findsOneWidget);
    expect(find.text('분산을 확인하세요.'), findsNothing);
    await tester.tap(find.text('보기'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'portfolio dashboard wires in-progress investment review status',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PortfolioDashboardPage(
            todayReviewBuilderForTesting: () async => reviewReport('헤드라인'),
            todayReviewLoaderForTesting: (_) async => dailyReviewEntry(
              status: DailyInvestmentReviewStatus.inProgress,
              mode: DailyInvestmentReviewMode.noTradeDay,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('작성 중인 회고가 있어요'), findsOneWidget);
      expect(find.text('이어쓰기'), findsOneWidget);
    },
  );

  testWidgets(
    'portfolio dashboard shows draft status when saved review status load fails',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PortfolioDashboardPage(
            todayReviewBuilderForTesting: () async => reviewReport('헤드라인'),
            todayReviewLoaderForTesting: (_) async {
              throw StateError('status load failed');
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('오늘 회고 초안이 준비됐어요'), findsOneWidget);
      expect(find.text('작성하기'), findsOneWidget);
    },
  );

  testWidgets(
    'portfolio dashboard hides stale investment review while refreshing',
    (tester) async {
      final firstReport = Completer<InvestmentReviewReport>();
      final secondReport = Completer<InvestmentReviewReport>();
      DailyInvestmentReviewEntry? savedReview;
      var callCount = 0;

      Future<InvestmentReviewReport> loadTodayReview() {
        callCount++;
        return callCount == 1 ? firstReport.future : secondReport.future;
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PortfolioDashboardPage(
            todayReviewBuilderForTesting: loadTodayReview,
            todayReviewLoaderForTesting: (_) async => savedReview,
          ),
        ),
      );

      firstReport.complete(reviewReport('헤드라인 A'));
      await tester.pump();

      expect(find.text('오늘 회고 초안이 준비됐어요'), findsOneWidget);

      savedReview = dailyReviewEntry(
        status: DailyInvestmentReviewStatus.completed,
        mode: DailyInvestmentReviewMode.noTradeDay,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PortfolioDashboardPage(
            dataRefreshTick: 1,
            todayReviewBuilderForTesting: loadTodayReview,
            todayReviewLoaderForTesting: (_) async => savedReview,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('오늘 회고 초안이 준비됐어요'), findsNothing);

      secondReport.complete(reviewReport('헤드라인 B'));
      await tester.pump();

      expect(find.text('오늘 회고 완료'), findsOneWidget);
    },
  );
}
