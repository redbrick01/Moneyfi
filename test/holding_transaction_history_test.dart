import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/panels/app_detail_section.dart';
import 'package:moneyfy/components/transaction_history_list.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/transaction_form_page.dart';

void main() {
  testWidgets('holding history shows recent trades and their controls', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('moneyfy_history_');
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => directory.path,
    );
    final db = AppDatabase.instance;
    addTearDown(() async {
      await db.close();
      messenger.setMockMethodCallHandler(pathProviderChannel, null);
      directory.deleteSync(recursive: true);
    });

    await tester.runAsync(() async {
      final assetId = await db.createAsset(
        assetType: '주식',
        title: '투자 계좌',
        alias: '',
        hidden: false,
        currencyCode: 'KRW',
        value: '0',
        change: '',
        icon: Icons.account_balance_wallet_rounded,
        quantityLabel: '항목',
        quantityValue: '0개',
        averageLabel: '수익률',
        averageValue: '',
        note: '',
      );
      await db.createCashAccount(
        assetId: assetId,
        currencyCode: 'KRW',
        name: '결제 계좌',
        note: '',
        balance: 10000,
      );
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: '',
        name: '테스트 종목',
        symbol: '',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 0,
        note: '',
      );
      for (final (day, type) in [
        (1, '배당'),
        (6, '매도'),
        (3, '매수'),
        (5, '배당'),
        (2, '배당'),
        (4, '배당'),
      ]) {
        final name = switch (day) {
          5 => '테스트 종목 분배금',
          4 => '테스트 종목',
          3 => '테스트 종목 매수',
          _ => '테스트 거래 $day',
        };
        await db.createTransaction(
          assetId: assetId,
          holdingId: holdingId,
          date: '2026.02.0$day',
          type: type,
          name: name,
          amount: '${1000 * day}',
          quantity: type == '배당' ? '' : '2',
          includeInCalculations: type != '매도',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HoldingDetailPage(holdingId: holdingId),
        ),
      );
      final history = find.byType(TransactionHistoryList);
      for (
        var attempt = 0;
        attempt < 40 && history.evaluate().isEmpty;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
      }
      expect(history, findsOneWidget);
      final section = tester.widget<AppDetailSection>(
        find.ancestor(of: history, matching: find.byType(AppDetailSection)),
      );
      final historyText = tester
          .widgetList<Text>(
            find.descendant(of: history, matching: find.byType(Text)),
          )
          .map((text) => text.data ?? text.textSpan?.toPlainText())
          .toList();
      expect(
        historyText.where((label) => label?.startsWith('2026-02-') ?? false),
        ['2026-02-06', '2026-02-05', '2026-02-04', '2026-02-03', '2026-02-02'],
      );
      expect(
        historyText,
        containsAll([
          '테스트 거래 6 · 기록전용',
          '테스트 거래 2',
          '₩12,000',
          '2주 × ₩6,000',
          '₩6,000',
          '2주 × ₩3,000',
          '₩5,000',
        ]),
      );
      expect(
        historyText.where((label) => label?.contains(' × ') ?? false),
        hasLength(2),
      );
      expect(
        historyText,
        isNot(contains(anyOf('테스트 종목', '테스트 종목 분배금', '테스트 종목 매수'))),
      );
      expect(
        historyText.where((label) => label?.contains('라인') ?? false),
        isEmpty,
      );
      expect(find.widgetWithText(TextButton, '추가'), findsOneWidget);
      expect(find.text('거래 금액'), findsOneWidget);
      expect(find.text('수량 × 단가'), findsOneWidget);
      _expectNeutralTradeBadges(tester);
      final latestDate = tester.getCenter(find.text('2026-02-06'));
      final latestDetail = tester.getCenter(find.text('2주 × ₩6,000'));
      final latestAmount = tester.getCenter(find.text('₩12,000'));
      expect(latestDetail.dx, greaterThan(latestDate.dx));
      expect(latestDetail.dx, lessThan(latestAmount.dx));
      expect(latestAmount.dy, closeTo(latestDate.dy, 1));
      expect(
        tester.getCenter(find.byTooltip('거래 옵션').first).dy,
        closeTo(latestDate.dy, 1),
      );
      expect(tester.takeException(), isNull);

      final latestOptions = find.byTooltip('거래 옵션').first;
      await tester.ensureVisible(latestOptions);
      await tester.tap(latestOptions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('2026-02-06 매도 내역을 삭제하시겠습니까?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      await tester.tap(latestOptions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final form = tester.widget<TransactionFormPage>(
        find.byType(TransactionFormPage),
      );
      expect(form.item?.name, '테스트 거래 6');
      expect(form.item?.includeInCalculations, isFalse);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('standalone-history'),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.contentHorizontalPadding,
                ),
                child: section,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '360 dp');
      _expectNeutralTradeBadges(tester);
      expect(find.text('거래 금액'), findsNothing);
      final compactAmount = tester.widget<Text>(find.text('₩12,000'));
      expect(compactAmount.semanticsLabel, '총액 ₩12,000');
      expect(compactAmount.softWrap, isFalse);
      for (final width in [390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$width dp');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

void _expectNeutralTradeBadges(WidgetTester tester) {
  for (final label in ['매수', '매도', '배당']) {
    final finder = find.widgetWithText(MoneyfyBadge, label).first;
    final badgeContext = tester.element(finder);
    final container = tester.widget<Container>(
      find.descendant(of: finder, matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    final renderedText = tester.widget<Text>(
      find.descendant(of: finder, matching: find.text(label)),
    );
    expect(decoration.color, badgeContext.surfaces.surfaceRaised);
    expect(renderedText.style!.color, badgeContext.colors.neutralText);
  }
}
