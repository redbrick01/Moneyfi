class InputValidationResult<T> {
  const InputValidationResult._({this.value, this.message});

  const InputValidationResult.valid(T value)
    : this._(value: value, message: null);

  const InputValidationResult.invalid(String message)
    : this._(value: null, message: message);

  final T? value;
  final String? message;

  bool get isValid => message == null;
}

class MoneyfyInputValidators {
  MoneyfyInputValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final RegExp _symbolPattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]{0,19}$');

  static InputValidationResult<String> requiredText(
    String raw, {
    required String fieldName,
  }) {
    final value = raw.trim();
    if (value.isEmpty) {
      return InputValidationResult.invalid('$fieldName을 입력해 주세요.');
    }
    return InputValidationResult.valid(value);
  }

  static InputValidationResult<String> email(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const InputValidationResult.invalid('이메일을 입력해 주세요.');
    }
    if (!_emailPattern.hasMatch(value)) {
      return const InputValidationResult.invalid(
        '이메일 형식이 올바르지 않습니다. 예: name@example.com',
      );
    }
    return InputValidationResult.valid(value);
  }

  static InputValidationResult<String> date(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const InputValidationResult.invalid('날짜를 입력해 주세요.');
    }

    final match = RegExp(r'^(\d{4})[.-](\d{2})[.-](\d{2})$').firstMatch(value);
    if (match == null) {
      return const InputValidationResult.invalid(
        '날짜는 YYYY.MM.DD 또는 YYYY-MM-DD 형식으로 입력해 주세요.',
      );
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) {
      return const InputValidationResult.invalid('날짜 형식이 올바르지 않습니다.');
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return const InputValidationResult.invalid('존재하지 않는 날짜입니다.');
    }

    final normalized =
        '${year.toString().padLeft(4, '0')}.'
        '${month.toString().padLeft(2, '0')}.'
        '${day.toString().padLeft(2, '0')}';
    return InputValidationResult.valid(normalized);
  }

  static InputValidationResult<double> decimal(
    String raw, {
    required String fieldName,
    double? min,
    double? max,
    bool allowZero = true,
    bool allowNegative = false,
  }) {
    final normalized = raw.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return InputValidationResult.invalid('$fieldName을 입력해 주세요.');
    }

    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) {
      return InputValidationResult.invalid('$fieldName은 숫자로 입력해 주세요.');
    }

    if (!allowZero && value == 0) {
      return InputValidationResult.invalid('$fieldName은 0보다 커야 합니다.');
    }
    if (!allowNegative && value < 0) {
      return InputValidationResult.invalid('$fieldName은 음수로 입력할 수 없습니다.');
    }
    if (min != null && value < min) {
      return InputValidationResult.invalid('$fieldName은 $min 이상이어야 합니다.');
    }
    if (max != null && value > max) {
      return InputValidationResult.invalid('$fieldName은 $max 이하이어야 합니다.');
    }

    return InputValidationResult.valid(value);
  }

  static InputValidationResult<String> symbol(String raw) {
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) {
      return const InputValidationResult.invalid('종목 코드를 입력해 주세요.');
    }
    if (!_symbolPattern.hasMatch(value)) {
      return const InputValidationResult.invalid(
        '종목 코드는 영문, 숫자, 점, 하이픈, 밑줄만 20자 이내로 입력해 주세요.',
      );
    }
    return InputValidationResult.valid(value);
  }
}
