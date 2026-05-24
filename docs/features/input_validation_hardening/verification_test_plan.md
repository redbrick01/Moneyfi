# Input Validation Hardening Verification Test Plan

## Scope

공통 입력 validator와 주요 입력 화면의 저장 전 검증 적용을 확인한다.

## Quality Goals

- 이메일, 날짜, 숫자, 음수/0, symbol 검증이 공통 helper로 동작한다.
- 기존 화면 smoke test가 깨지지 않는다.
- 저장 전 정규화가 기존 DB/API 계약과 호환된다.

## Automated Test Plan

```bash
dart format lib/utils/input_validators.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/forms/holding_form_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/cash_account_form_page.dart test/input_validators_test.dart
flutter test test/input_validators_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- LoginPage에서 잘못된 이메일 입력 시 Supabase 호출 전 오류가 표시되는지 확인한다.
- SignupPage에서 잘못된 이메일, 빈 이름, 비밀번호 불일치를 확인한다.
- 거래 추가에서 `2026.02.30`, `0`, `-1`, 빈 수량이 저장되지 않는지 확인한다.
- 현금 계좌 잔액 0은 저장되고 음수는 저장되지 않는지 확인한다.
- 보유 항목 수동 수정에서 symbol 공백/공백 포함 입력이 저장되지 않는지 확인한다.

## Responsive Checklist

- SnackBar 문구가 하단 저장 버튼과 과도하게 겹치지 않는다.
- 긴 validator 문구가 작은 화면에서 잘리지 않는다.

## Acceptance Criteria

- validator 단위 테스트가 통과한다.
- LoginPage와 주요 form walkthrough가 통과한다.
- 정적 분석이 통과한다.
- 수동 QA 미수행 항목은 test report에 남긴다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| 기존 사용자가 쓰던 특수 symbol이 막힘 | Medium | Medium | `.`, `_`, `-`까지 허용하고 20자 제한으로 완화 |
| 날짜 구분자 변경 혼란 | Low | Low | `.`와 `-` 모두 허용 |
| 실시간 오류가 없어 사용자가 저장 후 알게 됨 | Medium | Low | 이번 MVP는 기존 UX와 맞춰 SnackBar/InlineError 사용 |

## Future Test Expansion

- Form field별 error text widget test 추가.
- input formatter로 숫자/날짜 입력 중 실시간 제한.
- 기존 DB 값 정규화 마이그레이션 검토.
