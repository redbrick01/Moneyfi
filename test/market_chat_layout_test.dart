import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/analysis/screens/reddit_chat_page.dart';

void main() {
  testWidgets('drawer opens saved chats and reveals deletion on swipe', (
    tester,
  ) async {
    String? room;
    String? deleted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, refresh) => Scaffold(
            appBar: AppBar(),
            body: Text(room == null ? '빈 채팅' : '열린 채팅 $room'),
            endDrawer: ChatRoomsDrawer(
              onDelete: (id) async {
                deleted = id;
              },
              selectedId: room ?? '',
              loadPage: (_) async => [
                {'id': 'first', 'title': '반도체 전망'},
              ],
              onSelect: (id, title) => refresh(() => room = id),
            ),
          ),
        ),
      ),
    );
    Future<void> open() async {
      tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('반도체 전망'));
    await tester.pumpAndSettle();
    expect(find.text('열린 채팅 first'), findsOneWidget);
    await open();
    expect(find.text('새 채팅'), findsNothing);
    expect(find.bySemanticsLabel('대화 삭제'), findsNothing);
    await tester.drag(find.text('반도체 전망'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    await tester.tap(find.bySemanticsLabel('대화 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    expect(find.bySemanticsLabel('대화 삭제'), findsNothing);
    await tester.drag(find.text('반도체 전망'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    await tester.tap(find.bySemanticsLabel('대화 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(deleted, 'first');
    expect(find.text('아직 저장된 채팅이 없어요.'), findsOneWidget);
  });
  testWidgets('renders Korean strong spans during and after streaming', (
    tester,
  ) async {
    final input = TextEditingController();
    addTearDown(input.dispose);
    for (final status in ['running', 'done']) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MarketChatView(
              rows: [
                {
                  'id': 1,
                  'question': '요약해 줘',
                  'status': status,
                  'sources': [],
                  'answer':
                      r'**금리(3.8%)**는 상승했고 **표준 강조**와 \*\*핵심 지표\*\*를 확인해요. 코드: `**원문**`',
                },
              ],
              input: input,
              sending: false,
              busy: status == 'running',
              onSend: () {},
            ),
          ),
        ),
      );
      final text = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text)
          .firstWhere((span) => span.toPlainText().contains('3.8%'));
      expect(
        text.toPlainText(),
        '금리(3.8%)는 상승했고 표준 강조와 핵심 지표를 확인해요. 코드: **원문**',
      );
      final strong = StringBuffer();
      void visit(InlineSpan span, FontWeight? inherited) {
        if (span is! TextSpan) return;
        final weight = span.style?.fontWeight ?? inherited;
        if (weight != null && weight.value >= FontWeight.w600.value) {
          strong.write(span.text ?? '');
        }
        for (final child in span.children ?? <InlineSpan>[]) {
          visit(child, weight);
        }
      }

      visit(text, null);
      expect(strong.toString(), '금리(3.8%)표준 강조핵심 지표');
    }
  });
  testWidgets(
    'small screen supports composing, streaming and source inspection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final input = TextEditingController();
      addTearDown(input.dispose);
      var sent = 0;
      Future<void> show(
        List<Map<String, dynamic>> rows, {
        bool busy = false,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SafeArea(
                child: MarketChatView(
                  rows: rows,
                  input: input,
                  sending: false,
                  busy: busy,
                  onSend: () => sent++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show([]);
      await tester.tap(find.text('최근 뉴스 요약해 줘'));
      await tester.pump();
      expect(input.text, '최근 뉴스 요약해 줘');
      await tester.tap(find.byTooltip('질문 보내기'));
      expect(sent, 1);
      final row = <String, dynamic>{
        'id': 1,
        'question': '이번 주 뉴스와 Reddit 반응을 비교해 줘.',
        'answer':
            '### 뉴스\n\n**보도 내용** [1]\n\n- 첫 항목\n- 두 번째 항목\n\n'
            '|출처|요지|\n|---|---|\n|뉴스|보도|\n\n${'긴 답변입니다. ' * 90}',
        'status': 'running',
        'sources': [],
      };
      await show([row], busy: true);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == '질문 보내기',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      row['status'] = 'done';
      row['sources'] = [
        {
          'rank': 1,
          'sourceType': 'news_article',
          'title': '기사 제목',
          'publisher': '매체',
          'preview': '기사 요약',
        },
      ];
      await show([row]);
      await tester.tap(find.text('출처 1개'));
      await tester.pumpAndSettle();
      expect(find.text('답변 출처'), findsOneWidget);
      expect(find.text('[1] 뉴스 · 기사 제목'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
