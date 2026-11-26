import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/account/screens/my_page.dart';
import 'package:moneyfy/features/account/widgets/monthly_pivot_setting.dart';
import 'package:moneyfy/utils/monthly_pivot.dart';

void main() {
  test(
    'monthly pivot restores account preference and handles short months',
    () {
      expect(MonthlyPivot.fromMetadata(null).day, 1);
      expect(MonthlyPivot.fromMetadata({'monthly_pivot_day': 0}).day, 1);
      final pivot = MonthlyPivot.fromMetadata({'monthly_pivot_day': 31});
      expect(pivot.inMonth(2024, 2), DateTime(2024, 2, 29));
      expect(pivot.periodStart(DateTime(2025, 2, 28)), DateTime(2025, 2, 28));
      expect(
        pivot.periodStart(DateTime(2025, 2, 28), includeToday: false),
        DateTime(2025, 1, 31),
      );
      expect(pivot.periodEnd(DateTime(2025, 2, 28)), DateTime(2025, 3, 30));
      expect(pivot.periodStart(DateTime(2025, 1, 1)), DateTime(2024, 12, 31));
    },
  );

  testWidgets('monthly pivot picker saves the chosen day', (tester) async {
    var saved = 20;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, update) => MonthlyPivotSetting(
              day: saved,
              onSave: (day) async => update(() => saved = day),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('월 분기점'));
    await tester.pumpAndSettle();
    final wheel = find.byType(CupertinoPicker);
    int selected() =>
        tester.widget<CupertinoPicker>(wheel).scrollController!.selectedItem +
        1;
    expect(selected(), 20);
    await tester.drag(wheel, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(selected(), greaterThan(20));
    expect(saved, 20);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(saved, 20);
    await tester.tap(find.text('월 분기점'));
    await tester.pumpAndSettle();
    expect(selected(), 20);
    await tester.drag(wheel, const Offset(0, 100));
    await tester.pumpAndSettle();
    final chosen = selected();
    expect(chosen, lessThan(20));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(saved, chosen);
    expect(find.text('매월 $chosen일'), findsOneWidget);
  });
  group('profile management validation', () {
    test('validates password change inputs', () {
      expect(
        validatePasswordChangeForTesting('', ''),
        '새 비밀번호와 확인 값을 모두 입력해 주세요.',
      );
      expect(
        validatePasswordChangeForTesting('12345', '12345'),
        '새 비밀번호는 6자 이상이어야 합니다.',
      );
      expect(
        validatePasswordChangeForTesting('123456', '654321'),
        '새 비밀번호가 일치하지 않습니다.',
      );
      expect(validatePasswordChangeForTesting('123456', '123456'), isNull);
    });
  });
}
