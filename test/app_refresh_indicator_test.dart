import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/widgets/app_refresh_indicator.dart';

void main() {
  testWidgets('an extra upward wheel event at the top refreshes once', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 80);
    addTearDown(controller.dispose);
    final pending = Completer<void>();
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRefreshIndicator(
            onRefresh: () {
              refreshes++;
              return pending.future;
            },
            child: ListView(
              controller: controller,
              children: const [SizedBox(height: 2000)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> wheel(double dy) async {
      await tester.sendEventToBinding(
        PointerScrollEvent(
          kind: PointerDeviceKind.mouse,
          position: tester.getCenter(find.byType(ListView)),
          scrollDelta: Offset(0, dy),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    await wheel(-120);
    expect(controller.offset, 0);
    expect(refreshes, 0);
    await wheel(-120);
    expect(refreshes, 1);
    await wheel(-120);
    expect(refreshes, 1);
    pending.complete();
    await tester.pumpAndSettle();
    await wheel(120);
    expect(controller.offset, greaterThan(0));
    expect(refreshes, 1);
  });
}
