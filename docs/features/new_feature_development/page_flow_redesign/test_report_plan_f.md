# Plan F Test Report

## 실행일

- 2026-05-30

## 명령

| 명령 | 결과 |
| --- | --- |
| `dart format lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/asset_detail_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart` | 통과 |
| `flutter analyze` | 통과. `No issues found!` |
| `flutter test test/transaction_flow_test.dart` | 통과. `All tests passed!` |
| `flutter test test/widget_test.dart` | 실패. 앱 셸 smoke에서 특정 icon finder를 찾지 못함 |
| `flutter test test/page_walkthrough_test.dart` | 실패. 기존 워크스루 케이스에서 `bottom-tab-홈` key를 찾지 못함 |

## 실패 상세

### `test/widget_test.dart`

- 실패 테스트: `Moneyfy app renders shell smoke test`
- 실패 지점: `test/widget_test.dart:232`
- 메시지: `Found 0 widgets with icon "IconData(U+0F7F5)"`
- 참고: 같은 파일의 거래/현금 거래 form shortcut 관련 테스트들은 이후 통과했다.

### `test/page_walkthrough_test.dart`

- 실패 테스트: `stage 1: app shell visits every bottom tab`
- 실패 지점: `test/page_walkthrough_test.dart:171`
- 메시지: `The finder "Found 0 widgets with key [<'bottom-tab-홈'>]" could not find any matching widgets.`

## Plan F 판정

- Plan F 변경 후 `flutter analyze`는 통과했다.
- 거래 도메인 회귀 기준인 `transaction_flow_test.dart`는 전체 통과했다.
- Plan F에서는 bottom tab key나 shell 구조를 변경하지 않았다.
- `page_walkthrough_test.dart` 실패는 Plan B/C/D/E 검증 때와 동일한 앱 셸 도달 문제로 재현되었다.
- `widget_test.dart`의 shell smoke 실패도 shell icon 기대값 문제이며, Plan F의 입력 온보딩 문구/CTA 변경의 직접 회귀로 보이지 않는다.

## 수동 QA

- 별도 기기/시뮬레이터 수동 QA는 실행하지 않았다.
