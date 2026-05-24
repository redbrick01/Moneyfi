import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/pages/my_page.dart';

void main() {
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
