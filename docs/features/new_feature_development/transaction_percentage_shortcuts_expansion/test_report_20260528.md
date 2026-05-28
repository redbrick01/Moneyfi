# Transaction Percentage Shortcuts Expansion Test Report 2026-05-28

## Summary

매도에만 있던 `25%`, `50%`, `75%`, `100%` 빠른 선택 버튼을 현금 출금, 현금 이체, 환전, 매수 흐름으로 확장했다. 공통 버튼 컴포넌트를 도입하고, 각 폼에서 기준 잔액/현금을 계산해 금액 또는 수량 필드에 입력하도록 구현했다.

## Implemented Scope

- `MoneyfyPercentageShortcutButtons` 공통 action button 컴포넌트를 추가했다.
- 기존 매도 비중 버튼을 공통 컴포넌트로 교체했다.
- 현금 거래 폼에 source 현금 잔액 기준 비중 버튼을 추가했다.
  - 출금, 이체, 환전에서 표시된다.
  - record-only 기존 거래는 기준 잔액에 되돌리지 않는다.
  - 계산 반영 기존 출금/이체/환전은 같은 source 계좌일 때 기존 금액을 되돌린다.
- 매수 폼에 settlement cash 기준 비중 버튼을 추가했다.
  - 단가가 0보다 클 때만 버튼이 활성화된다.
  - 버튼은 기준 현금 / 단가로 수량을 계산하고 `formatPlainQuantity()`로 입력한다.
  - record-only 기존 매수는 기존 매수 지출을 되돌리지 않는다.
- widget test용으로 `CashTransactionFormPage.assetsFutureForTesting` 주입 경로를 추가했다.

## Settlement Cash Rule

매수 settlement cash는 DB의 `_ensureSettlementCashAccount(assetId, currencyCode)` 규칙을 따른다. 해당 asset과 보유 종목 currency가 같은 cash account 중 `sortOrder`, `id` 오름차순 첫 계좌를 사용하고, 없으면 새 settlement cash account를 생성한다.

UI도 `fetchAssets()` 결과의 같은 asset 안에서 currency가 같은 cash-like holding 중 첫 항목을 기준으로 계산한다. 동일 통화 cash account가 여러 개일 때는 DB와 같은 "첫 settlement cash" 의미를 유지한다.

## Changed Files

- `lib/pages/forms/form_design.dart`
- `lib/pages/forms/cash_transaction_form_page.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `test/widget_test.dart`
- `test/transaction_flow_test.dart`

## Commands Run

| 명령 | 결과 |
| --- | --- |
| `dart format lib/pages/forms/form_design.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/transaction_form_page.dart test/transaction_flow_test.dart test/widget_test.dart test/page_walkthrough_test.dart` | Pass |
| `flutter test test/widget_test.dart` | Pass, 15 tests |
| `flutter test test/transaction_flow_test.dart` | Pass, 59 tests |
| `flutter test test/page_walkthrough_test.dart` | Pass, 23 tests |
| `flutter analyze` | Pass |
| `git diff --check` | Pass |

## Regression Coverage

- 기존 매도 비중 버튼 노출/입력/수정/holding 변경 테스트가 계속 통과한다.
- 현금 출금 100% 버튼이 source 잔액 전체를 입력한다.
- 계산 반영 출금 수정은 기존 출금 금액을 되돌려 100% 기준을 계산한다.
- record-only 출금 수정은 기존 출금 금액을 되돌리지 않는다.
- 현금 이체 50% 버튼이 source 잔액 절반을 입력한다.
- 환전 75% 버튼은 환율 입력 없이도 source 금액을 입력한다.
- 매수 100% 버튼은 settlement cash와 단가 기준으로 수량을 입력한다.
- 매수 버튼은 단가가 비어 있으면 비활성화된다.
- 계산 반영 매수 수정은 기존 매수 지출을 되돌려 기준 현금을 계산한다.
- record-only 매수 수정은 기존 매수 지출을 되돌리지 않는다.
- DB 테스트에서 전액 출금, 전액 환전, 첫 settlement cash 전액 매수 저장이 성공하고 잔액이 기대대로 반영된다.

## Manual QA Status

Manual app UI QA는 실행하지 않았다. 자동 widget test가 버튼 노출, 스크롤 후 탭, 금액/수량 입력, record-only 보정, 매수 비활성화 상태를 검증했다. 실제 기기에서는 키보드가 열린 상태에서 버튼 접근성과 작은 화면 줄바꿈을 확인하는 것이 좋다.

## Remaining Risk

- 현금 금액 formatter는 기존 3자리 소수 정책을 유지한다. USD 등 더 긴 소수 금액 정밀도가 필요한 경우 별도 currency scale 작업이 필요하다.
- 매수 settlement cash가 여러 개인 경우 DB 규칙과 동일하게 첫 계좌를 사용한다. 사용자가 결제 현금 계좌를 직접 고르는 UX는 아직 없다.
- 환전 target 계좌 선택은 기존 DB 자동 선택/생성 규칙을 따른다. target을 사용자가 직접 선택하는 기능은 범위 밖이다.

## Final Result

Pass. 현금 출금/이체/환전/매수 비중 빠른 선택 기능이 구현되었고, 주요 신규/수정/record-only/저장 케이스가 자동 테스트로 확인되었다.
