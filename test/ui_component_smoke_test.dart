import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/components/expandable/expandable_tile.dart';
import 'package:moneyfy/components/headers/detail_header_card.dart';
import 'package:moneyfy/components/rows/asset_row.dart';
import 'package:moneyfy/components/rows/transaction_row.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';

void main() {
  Future<void> pumpUi(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SectionCard renders with title/body', (tester) async {
    await pumpUi(tester, const SectionCard(title: '섹션', child: Text('내용')));
    expect(find.text('섹션'), findsOneWidget);
    expect(find.text('내용'), findsOneWidget);
  });

  testWidgets('DetailHeaderCard renders metrics', (tester) async {
    await pumpUi(
      tester,
      const DetailHeaderCard(
        title: '종목명',
        primaryText: '₩12,300,000',
        secondaryRows: [Text('당일 +1.2%')],
      ),
    );
    expect(find.text('종목명'), findsOneWidget);
    expect(find.text('₩12,300,000'), findsOneWidget);
  });

  testWidgets('AssetRow and TransactionRow render tap targets', (tester) async {
    await pumpUi(
      tester,
      Column(
        children: const [
          AssetRow(
            leading: Icon(Icons.pie_chart_outline_rounded),
            title: '주식',
            subtitle: 'KRW',
            amountText: '₩5,000,000',
          ),
          TransactionRow(
            typeLabel: '매수',
            title: '삼성전자',
            subtitle: '2026.03.20 · 수량 2',
            amountText: '₩140,000',
          ),
        ],
      ),
    );
    expect(find.text('주식'), findsOneWidget);
    expect(find.text('매수'), findsOneWidget);
  });

  testWidgets('State widgets render', (tester) async {
    await pumpUi(
      tester,
      SizedBox(
        width: 360,
        child: Column(
          children: [
            EmptyStateCard(
              title: '데이터 없음',
              description: '새 항목을 추가하세요.',
              actionLabel: '추가',
              onAction: () {},
            ),
            const InlineError(message: '네트워크 오류'),
            RetryRow(message: '다시 시도해 주세요', onRetry: () {}),
          ],
        ),
      ),
    );
    expect(find.text('데이터 없음'), findsOneWidget);
    expect(find.text('네트워크 오류'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);
  });

  testWidgets('MoneyfyPage paints scaffold background on pushed pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const MoneyfyPage(title: '분석', children: [Text('내용')]),
      ),
    );
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('분석'), matching: find.byType(Material)).first,
    );

    expect(material.color, AppTheme.light.scaffoldBackgroundColor);
    expect(find.text('내용'), findsOneWidget);
  });

  testWidgets('ExpandableTile expands and collapses', (tester) async {
    await pumpUi(
      tester,
      const ExpandableTile(
        title: '이슈 제목',
        subtitle: '요약',
        children: [Text('확장 내용')],
      ),
    );
    expect(find.text('확장 내용'), findsNothing);
    await tester.tap(find.text('이슈 제목'));
    await tester.pumpAndSettle();
    expect(find.text('확장 내용'), findsOneWidget);
  });

  testWidgets('AppPageScaffold form renders fixed CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: AppPageScaffold.form(
          title: '폼',
          primaryActionLabel: '저장',
          onPrimaryActionPressed: () {},
          body: const Text('입력 필드'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('폼'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });
}
