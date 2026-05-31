# Plan C Test Report

## 실행일

- 2026-05-30

## 명령

| 명령 | 결과 |
| --- | --- |
| `dart format lib/navigation lib/pages/app_shell_page.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/asset_detail_page.dart lib/pages/analysis_page.dart lib/pages/my_page.dart` | 통과 |
| `flutter analyze` | 통과. `No issues found!` |
| `flutter test test/page_walkthrough_test.dart` | 실패. 1개 기존 워크스루 케이스에서 `bottom-tab-홈` key를 찾지 못함 |

## 실패 상세

- 실패 테스트: `stage 1: app shell visits every bottom tab`
- 실패 지점: `test/page_walkthrough_test.dart`
- 메시지: `The finder "Found 0 widgets with key [<'bottom-tab-홈'>]" could not find any matching widgets.`

## Plan C 판정

- Plan C 변경 후 `flutter analyze`는 통과했다.
- `page_walkthrough_test.dart` 실패는 Plan B 검증 때와 동일한 앱 셸 도달 문제로 재현되었다.
- Plan C에서는 `bottom-tab-${item.label}` key를 변경하지 않았고, `_NavItem`에 route metadata만 추가했다.
- 해당 실패는 Plan C helper/route registry 구현의 직접 회귀로 보이지 않지만, 다음 테스트 안정화 작업에서 별도 확인해야 한다.

## 수동 QA

- 별도 기기/시뮬레이터 수동 QA는 실행하지 않았다.
