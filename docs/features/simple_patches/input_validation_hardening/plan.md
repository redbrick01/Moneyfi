# Input Validation Hardening Plan

## Product Goal

로그인, 회원가입, 보유 항목, 거래 입력에서 잘못된 이메일, 날짜, 숫자, 음수/0, 종목 코드 저장 전 일관 차단.

## Current Baseline

- 입력 화면 대부분 `TextField` 기반. 저장 시 개별 `tryParse`로 일부 숫자만 확인.
- 이메일 형식 검증: 비어 있음만 확인.
- 날짜 문자열 그대로 저장. 잘못된 형식/없는 날짜 가능.
- 현금 잔액과 거래 금액 0/음수 기준 화면별 다름.
- 종목 symbol 수동 편집 경로에서 형식 검증 없이 저장 가능.

## Success Criteria

- 공통 validator가 이메일, 날짜, decimal, required text, symbol 규칙 제공.
- 로그인/회원가입 이메일 형식 확인.
- 거래/현금 거래 날짜 + 양수 금액/수량 확인.
- 현금 계좌 잔액 0 허용, 음수 차단.
- 보유 항목 수량/평단/현재가/symbol 공통 규칙 확인.
- validator 규칙 단위 테스트 고정.

## Proposed UX

- 저장 버튼 누르면 첫 오류 SnackBar 또는 InlineError 표시.
- 날짜는 `YYYY.MM.DD`, `YYYY-MM-DD` 허용. 저장 전 `YYYY.MM.DD` 정규화.
- 숫자는 콤마 입력 허용. 저장 전 단순 숫자 문자열 정규화.
- 종목 코드 대문자 정규화.

## Data/API Changes

- DB schema, Supabase API, sync payload 계약 변경 없음.
- 저장 전 client-side validation + 정규화만 추가.

## Development Phases

1. 기존 입력 검증 위치 조사.
2. `MoneyfyInputValidators` 공통 helper 추가.
3. LoginPage/SignupPage 이메일 검증 적용.
4. 보유/현금 계좌/거래/현금 거래 form 저장 전 검증 적용.
5. validator 단위 테스트 + 관련 form smoke test 실행.
6. 문서와 검증 결과 업데이트.

## MVP Scope

- 저장 시점 검증 공통화.
- 기존 `TextField` 기반 UI 유지.
- Field별 실시간 error UI 전환은 후속 과제.

## Test Plan

```bash
dart format lib/utils/input_validators.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/forms/holding_form_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/cash_account_form_page.dart test/input_validators_test.dart
flutter test test/input_validators_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- 기존 데이터 중 날짜가 `YYYY.MM.DD` 아닌 값은 이번 patch에서 마이그레이션 없음.
- 거래 금액/수량은 실제 거래 생성 필수값이므로 0 차단.
- 현금 잔액은 계좌 생성/수정 시 0원 자연스러워 0 허용.
- symbol 허용 문자: 영문, 숫자, `.`, `_`, `-`.

## Feasibility And Feedback

- 공통 helper 방식은 기존 form 구조와 잘 맞고 변경 범위 작음.
- 완전한 `Form`/`TextFormField` 전환은 UX 개선 크지만 리스크 커서 MVP 제외.
- 다음 단계: 각 필드 하단 error text + input formatter 추가 가능.