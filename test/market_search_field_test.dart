import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/components/forms/market_search_field.dart';
import 'package:moneyfy/design_system/app_theme.dart';

void main() {
  testWidgets(
    'local matches appear first and stale quotes cannot replace a newer search',
    (tester) async {
      final first = Completer<List<String>>();
      final second = Completer<List<String>>();
      final controller = TextEditingController();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: MarketSearchField<String>(
              controller: controller,
              label: '검색',
              localSearch: (query) => ['local $query'],
              verify: (query, _) => query == 'A' ? first.future : second.future,
              itemBuilder: (_, item) => Text(item),
              onEdited: () {},
              onSelected: (item) => selected = item,
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      await tester.tap(field);
      await tester.pumpAndSettle();
      for (final query in ['A', 'B']) {
        await tester.enterText(field, query);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(find.text('local $query'), findsOneWidget);
      }
      first.complete(['stale quote']);
      await tester.pump();
      expect(find.text('stale quote'), findsNothing);
      second.complete(['verified B']);
      await tester.pumpAndSettle();
      await tester.tap(find.text('verified B'));
      await tester.pumpAndSettle();
      expect(selected, 'verified B');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
