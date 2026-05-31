# Plan G Test Report

## 실행 결과

| 명령 | 결과 | 메모 |
| --- | --- | --- |
| `dart format lib/main.dart lib/navigation/moneyfy_router.dart lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_navigation.dart lib/pages/app_shell_page.dart lib/pages/startup_gate.dart test/router_smoke_test.dart test/widget_test.dart test/page_walkthrough_test.dart` | 통과 | 수정 파일 포맷 완료 |
| `flutter analyze` | 통과 | `No issues found!` |
| `flutter test test/router_smoke_test.dart` | 통과 | 6탭 직접 route, analysis/detail/auth route smoke |
| `flutter test test/widget_test.dart` | 통과 | shell smoke와 form shortcut tests |
| `flutter test test/page_walkthrough_test.dart` | 통과 | 기존 `bottom-tab-홈` 실패 해소 |
| `flutter test test/transaction_flow_test.dart` | 통과 | form route 미전환 상태에서 거래 도메인 회귀 확인 |

## Router Smoke Coverage

| 범위 | 확인 |
| --- | --- |
| shell routes | `/`, `/portfolio`, `/transactions`, `/analysis`, `/statistics`, `/my` 직접 진입 |
| analysis route | `/analysis/investment-performance` 직접 진입 |
| detail routes | `/assets/-101`, `/holdings/-102`, `/cash-accounts/-202` 직접 진입 |
| auth route | `/login` 직접 진입 |

## 특이사항

- 테스트 환경에서는 Supabase auth auto-refresh timer가 남을 수 있어, shell route smoke는 `buildMoneyfyRouter(useStartupGate: false)`로 startup gate를 우회한다.
- production router 기본값은 `useStartupGate: true`이며 앱 시작 초기화/splash/error 흐름은 유지된다.
- Android back/iOS swipe back은 자동 테스트의 route pop smoke로 대체 기록했으며, 실제 디바이스 수동 QA는 후속 후보로 남긴다.
