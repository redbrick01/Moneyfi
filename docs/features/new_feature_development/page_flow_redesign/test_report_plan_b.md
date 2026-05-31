# Plan B Test Report

## 실행일

- 2026-05-30

## 명령

| 명령 | 결과 |
| --- | --- |
| `dart format lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/my_page.dart` | 통과. `Formatted 3 files (0 changed)` |
| `flutter analyze` | 통과. `No issues found!` |
| `flutter test test/page_walkthrough_test.dart` | 실패. 1개 기존 워크스루 케이스에서 `bottom-tab-홈` key를 찾지 못함 |

## 실패 상세

- 실패 테스트: `stage 1: app shell visits every bottom tab`
- 실패 지점: `test/page_walkthrough_test.dart`
- 메시지: `The finder "Found 0 widgets with key [<'bottom-tab-홈'>]" could not find any matching widgets.`
- 참고: `lib/pages/app_shell_page.dart`에는 `ValueKey('bottom-tab-${item.label}')`가 남아 있으므로, 현재 테스트가 앱 셸의 bottom tab까지 도달하지 못하는 상태로 보인다.

## Plan B 판정

- Plan B 변경 파일은 `flutter analyze` 기준 문제 없음.
- `page_walkthrough_test.dart` 실패는 Plan B에서 변경한 포트폴리오/거래/My 화면 내부가 아니라 앱 셸 탭 탐색 단계에서 발생했다.
- 해당 실패는 Plan B 구현 완료를 막는 직접 회귀로 보이지 않지만, 다음 테스트 안정화 작업에서 별도 확인해야 한다.

## 수동 QA

- 별도 기기/시뮬레이터 수동 QA는 실행하지 않았다.
