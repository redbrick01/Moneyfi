import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/portfolio/screens/forms/holding_form_page.dart';
import 'package:moneyfy/utils/input_validators.dart';

void main() {
  group('MoneyfyInputValidators', () {
    test('validates email format', () {
      expect(MoneyfyInputValidators.email('user@example.com').isValid, isTrue);
      expect(
        MoneyfyInputValidators.email('user.name+tag@sub.co.kr').isValid,
        isTrue,
      );

      final invalid = MoneyfyInputValidators.email('not-an-email');
      expect(invalid.isValid, isFalse);
      expect(invalid.message, contains('이메일 형식'));
    });

    test('validates and normalizes dates', () {
      final dotted = MoneyfyInputValidators.date('2026.05.24');
      final dashed = MoneyfyInputValidators.date('2026-05-24');

      expect(dotted.value, '2026.05.24');
      expect(dashed.value, '2026.05.24');
      expect(MoneyfyInputValidators.date('2026.02.30').isValid, isFalse);
      expect(MoneyfyInputValidators.date('05/24/2026').isValid, isFalse);
    });

    test('validates decimal zero and negative rules', () {
      expect(
        MoneyfyInputValidators.decimal(
          '1,000.5',
          fieldName: '금액',
          allowZero: false,
        ).value,
        1000.5,
      );
      expect(
        MoneyfyInputValidators.decimal(
          '0',
          fieldName: '수량',
          allowZero: false,
        ).isValid,
        isFalse,
      );
      expect(
        MoneyfyInputValidators.decimal(
          '0',
          fieldName: '잔액',
          allowZero: true,
        ).value,
        0,
      );
      expect(
        MoneyfyInputValidators.decimal('-1', fieldName: '잔액').isValid,
        isFalse,
      );
    });

    test('validates symbol input', () {
      expect(MoneyfyInputValidators.symbol('aapl').value, 'AAPL');
      expect(MoneyfyInputValidators.symbol('BRK.B').value, 'BRK.B');
      expect(MoneyfyInputValidators.symbol('005930').value, '005930');
      expect(MoneyfyInputValidators.symbol('bad symbol').isValid, isFalse);
      expect(MoneyfyInputValidators.symbol('').isValid, isFalse);
    });

    test('holding quantity accepts zero for closed investment positions', () {
      final investmentQuantity = validateHoldingQuantityInput(
        '0',
        isCashAsset: false,
      );
      final cashQuantity = validateHoldingQuantityInput(
        '0',
        isCashAsset: true,
      );

      expect(investmentQuantity.isValid, isTrue);
      expect(investmentQuantity.value, 0);
      expect(cashQuantity.isValid, isTrue);
      expect(cashQuantity.value, 0);
    });
  });
}
