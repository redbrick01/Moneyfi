# Input Validation Hardening Plan

## Product Goal

로그인, 회원가입, 보유 항목, 거래 입력에서 잘못된 이메일, 날짜, 숫자, 음수/0, 종목 코드 입력을 저장 전에 일관되게 막는다.

## Current Baseline

- 입력 화면은 대부분 `TextField` 기반이며 저장 시점에 개별 `tryParse`로 일부 숫자만 확인한다.
- 이메일 형식 검증은 비어 있음만 확인한다.
- 날짜는 문자열 그대로 저장되어 잘못된 형식이나 존재하지 않는 날짜가 들어갈 수 있다.
- 현금 잔액과 거래 금액의 0/음수 처리 기준이 화면별로 다르다.
- 종목 symbol은 수동 편집 경로에서 형식 검증 없이 저장될 수 있다.

## Success Criteria

- 공통 validator에서 이메일, 날짜, decimal, required text, symbol 규칙을 제공한다.
- 로그인/회원가입은 이메일 형식을 확인한다.
- 거래/현금 거래는 날짜와 양수 금액/수량을 확인한다.
- 현금 계좌 잔액은 0을 허용하되 음수는 막는다.
- 보유 항목은 수량/평단/현재가/symbol을 공통 규칙으로 확인한다.
- validator 규칙은 단위 테스트로 고정한다.

## Proposed UX

- 저장 버튼을 누르면 첫 번째 오류를 SnackBar 또는 InlineError로 표시한다.
- 날짜는 `YYYY.MM.DD`와 `YYYY-MM-DD`를 허용하고 저장 전 `YYYY.MM.DD`로 정규화한다.
- 숫자는 콤마 입력을 허용하고 저장 전 단순 숫자 문자열로 정규화한다.
- 종목 코드는 대문자로 정규화한다.

## Data/API Changes

- DB schema, Supabase API, sync payload 계약은 변경하지 않는다.
- 저장 전 client-side validation과 정규화만 추가한다.

## Development Phases

1. 기존 입력 검증 위치 조사.
2. `MoneyfyInputValidators` 공통 helper 추가.
3. LoginPage/SignupPage 이메일 검증 적용.
4. 보유/현금 계좌/거래/현금 거래 form 저장 전 검증 적용.
5. validator 단위 테스트와 관련 form smoke test 실행.
6. 문서와 검증 결과 업데이트.

## MVP Scope

- 저장 시점 검증 공통화.
- 기존 `TextField` 기반 UI 유지.
- Field별 실시간 error UI 전환은 후속 과제로 둔다.

## Test Plan

```bash
dart format lib/utils/input_validators.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/forms/holding_form_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/cash_account_form_page.dart test/input_validators_test.dart
flutter test test/input_validators_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- 기존 데이터 중 날짜가 `YYYY.MM.DD`가 아닌 값은 이번 patch에서 마이그레이션하지 않는다.
- 거래 금액/수량은 실제 거래 생성에 필요한 값이므로 0을 막는다.
- 현금 잔액은 계좌 생성/수정 시 0원이 자연스러우므로 0을 허용한다.
- symbol 허용 문자는 영문, 숫자, `.`, `_`, `-`로 제한한다.

## Feasibility And Feedback

- 공통 helper 추가 방식은 기존 form 구조와 잘 맞고 변경 범위가 작다.
- 완전한 `Form`/`TextFormField` 전환은 UX 개선 여지는 크지만 리스크가 커서 이번 MVP에서 제외한다.
- 다음 단계에서는 각 필드 하단 error text와 input formatter를 추가할 수 있다.
