import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/main.dart';

void main() {
  testWidgets('Moneyfy app renders shell smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MoneyfyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });
}
