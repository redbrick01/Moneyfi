# Sell Quantity Percentage Shortcuts Test Report 2026-05-28

## Summary

투자 거래 폼의 매도 입력에 `25%`, `50%`, `75%`, `100%` 수량 빠른 선택 버튼을 추가했다. 버튼은 매도 유형에서만 표시되며, 선택된 보유 종목의 매도 가능 수량을 기준으로 수량 필드를 자동 입력한다.

## Implemented Scope

- `TransactionFormPage` 매도 수량 필드 아래에 비중 액션 버튼을 추가했다.
- `MoneyfyChoiceWrap` 대신 선택 상태가 없는 `OutlinedButton` 액션으로 구현했다.
- 신규 매도는 현재 보유 수량을 기준으로 계산한다.
- 기존 매도 수정은 현재 보유 수량에 기존 매도 수량을 되돌린 값을 기준으로 계산한다.
- 기존 거래의 holding과 새 선택 holding이 다르면 새 holding의 현재 보유 수량을 기준으로 계산한다.
- 버튼 입력값은 `formatPlainQuantity()`를 사용해 코인급 소수 수량과 double 노이즈를 정리한다.
- widget test가 DB singleton에 의존하지 않도록 `TransactionFormPage.assetsFutureForTesting` 주입 경로를 추가했다.

## Changed Files

- `lib/pages/forms/transaction_form_page.dart`
- `test/widget_test.dart`
- `test/transaction_flow_test.dart`
- `test/page_walkthrough_test.dart`는 formatter 적용으로 줄바꿈만 변경되었다.

## Commands Run

| 명령 | 결과 |
| --- | --- |
| `dart format lib/pages/forms/transaction_form_page.dart test/page_walkthrough_test.dart test/transaction_flow_test.dart test/widget_test.dart` | Pass |
| `flutter test test/transaction_flow_test.dart` | Pass, 56 tests |
| `flutter test test/widget_test.dart` | Pass, 6 tests |
| `flutter test test/page_walkthrough_test.dart` | Pass, 23 tests |
| `flutter analyze` | Pass |
| `git diff --check` | Pass |

## Regression Coverage

- 매수 유형에서는 비중 버튼이 보이지 않고, 매도 유형으로 바꾸면 버튼이 표시된다.
- 다시 매수 유형으로 바꾸면 버튼이 사라진다.
- 보유 수량 `0.12345678`에서 `100%` 버튼은 `0.12345678`을 입력한다.
- 같은 보유 수량에서 `50%` 버튼은 `0.06172839`를 입력한다.
- 버튼으로 값을 채운 뒤 사용자가 수량 필드를 직접 `0.01`로 수정할 수 있다.
- 매도 거래 수정 화면에서 `100%`는 `현재 보유 수량 + 기존 매도 수량` 기준으로 계산된다.
- 기존 거래 holding과 새 선택 holding이 다르면 새 holding의 현재 수량 기준으로 버튼 값이 계산된다.
- DB 흐름 테스트에서 기존 매도 거래를 전량 매도로 수정할 수 있음을 확인했다.

## Manual QA Status

Manual app UI QA는 실행하지 않았다. 자동 widget test가 버튼 노출, 스크롤 후 탭, 수량 입력값 변경, holding 선택 변경 흐름을 검증했다. 릴리스 전 실제 기기에서는 작은 화면에서 버튼 줄바꿈과 키보드 표시 상태를 확인하면 좋다.

## Responsive QA Status

`page_walkthrough_test.dart` first-frame walkthrough는 통과했다. 실제 모바일/태블릿 viewport 스크린샷 QA는 수행하지 않았다.

## Risk Assessment

잔여 리스크는 낮음에서 중간이다. UI 계산 규칙은 widget test와 DB 흐름 테스트로 고정했지만, 향후 거래 편집 모델이 더 복잡해지면 매도 가능 수량 계산을 DB helper/API로 공유하는 편이 더 안전하다.

## Follow-Up Recommendations

- 매도 가능 수량 계산 helper를 DB 검증 로직과 직접 공유하는 구조를 검토한다.
- 비중 버튼을 현금 출금/이체 잔액 비중 선택에도 확장할지 별도 제품 요구로 검토한다.
- 실제 기기에서 키보드가 열린 상태의 버튼 접근성을 확인한다.

## Final Result

Pass. 매도 수량 비중 빠른 선택 기능이 구현되었고, 신규/수정/holding 변경 케이스가 자동 테스트로 확인되었다.
