import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/models/asset_item.dart';
import 'package:moneyfy/pages/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/pages/forms/transaction_form_page.dart';
import 'package:moneyfy/pages/investment_performance_page.dart';
import 'package:moneyfy/pages/investment_review_page.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';
import 'package:moneyfy/utils/input_validators.dart';

import 'package:moneyfy/main.dart';

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
    await tester.pumpWidget(const MoneyfyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
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
}
