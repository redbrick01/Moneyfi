# Plan H-Impl Test Report

## 실행 결과

| 명령 | 결과 | 메모 |
| --- | --- | --- |
| `dart format lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_router.dart lib/pages/app_shell_page.dart lib/navigation/moneyfy_navigation.dart lib/pages/analysis_page.dart test/router_smoke_test.dart test/page_walkthrough_test.dart` | 통과 | 수정 파일 포맷 완료 |
| `flutter analyze` | 통과 | `No issues found!` |
| `flutter test test/router_smoke_test.dart` | 통과 | 5탭 shell route와 `/statistics` 호환 route 확인 |
| `flutter test test/widget_test.dart` | 통과 | shell smoke와 form shortcut tests |
| `flutter test test/page_walkthrough_test.dart` | 통과 | 하단 5탭 방문, 분석 탭 통계 진입 확인 |
| `flutter test test/transaction_flow_test.dart` | 통과 | form route 미전환 상태에서 거래 도메인 회귀 확인 |

## Router Smoke Coverage

| 범위 | 확인 |
| --- | --- |
| shell routes | `/`, `/portfolio`, `/transactions`, `/analysis`, `/my` 직접 진입 |
| statistics compatibility | `/statistics` 직접 진입, `bottom-tab-통계` 없음, `bottom-tab-분석` 존재 |
| analysis route | `/analysis/investment-performance` 직접 진입 |
| detail routes | `/assets/-101`, `/holdings/-102`, `/cash-accounts/-202` 직접 진입 |
| auth route | `/login` 직접 진입 |

## 특이사항

- `StatisticsPage`는 기존 구조상 자체 back button을 제공하지 않으므로 standalone walkthrough에서는 `Navigator.pop`으로 복귀를 확인했다.
- `/statistics`는 삭제하지 않았고, shell selected tab만 `분석`으로 매핑했다.
- My 탭 및 `내부 DB 요약 복사 (GPT)` 기능은 변경하지 않았다.
