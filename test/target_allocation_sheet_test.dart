import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/shell/screens/target_allocation_sheet.dart';

void main() {
  testWidgets('target allocation sheet uses compact footer with keyboard', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);

    final controllers = {
      1: TextEditingController(text: '50'),
      2: TextEditingController(text: '0'),
    };
    addTearDown(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showTargetAllocationSheet(
                    context: context,
                    entries: const [
                      TargetAllocationEntry(
                        assetId: 1,
                        label: 'ISA',
                        currentRatio: 50,
                      ),
                      TargetAllocationEntry(
                        assetId: 2,
                        label: '코인',
                        currentRatio: 0,
                      ),
                    ],
                    controllers: controllers,
                    onSave: (_) async {},
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('저장'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('합계가 100%여야 저장할 수 있어요.'), findsNothing);
  });
}
