# Plan G Implementation Report

## 요약

Plan G는 현재 6탭 IA를 유지한 채 앱 루트를 `go_router`와 `MaterialApp.router` 기반으로 전환했다. 5탭 통합, 폼 named route 전환, snapshot loader 전환은 진행하지 않았다.

## 구현 내용

| 항목 | 결과 |
| --- | --- |
| 의존성 | `go_router: ^17.2.3` 추가 |
| 앱 루트 | `MoneyfyApp`을 `MaterialApp.router`로 전환 |
| startup | 기존 `_StartupGate`를 `StartupGate`로 분리하고 초기화/splash/error 책임 유지 |
| router | `lib/navigation/moneyfy_router.dart` 추가 |
| shell tabs | `/`, `/portfolio`, `/transactions`, `/analysis`, `/statistics`, `/my` 직접 진입 지원 |
| shell state | `AppShellPage.initialLocation`으로 selected tab 동기화 |
| tab click | 탭 클릭 시 `context.go(routePath)` 적용, 같은 탭 재탭 동작 유지 |
| 주요 route | asset/holding/cash account detail, portfolio diagnosis, investment performance, dividend interest, login, signup 등록 |
| helper | Plan C helper를 router `push` 기반으로 전환 |
| fallback | router context가 없는 standalone page/test에서는 기존 `Navigator.push` fallback 유지 |
| form flow | 모든 form `Navigator.push<bool>` 저장/갱신 구조 유지 |
| tests | `test/router_smoke_test.dart` 추가, 기존 shell smoke/walkthrough 수정 |

## 제외 유지

- 5탭 통합.
- 분석/통계 탭 통합.
- form named route 전환.
- form edit loader 리팩터.
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage`의 id 기반 loader 전환.
- auth redirect 또는 protected route 정책.
- bottom sheet/dialog route 승격.

## 완료 판단

- 6탭 route 직접 진입과 탭 클릭 이동을 자동 테스트로 검증했다.
- 기존 `bottom-tab-홈` walkthrough 실패를 router shell 테스트 기준으로 해소했다.
- detail/auth/analysis route smoke를 추가했다.
- form 저장/갱신은 route 전환 대상에서 제외했고 `transaction_flow_test`로 도메인 회귀를 확인했다.
- Plan H 또는 Plan I는 시작하지 않았다.

## 남은 후속 후보

- Plan H: 5탭 통합 여부 결정.
- Plan I: form named route와 id 기반 edit loader 전환.
- Snapshot/annual analysis id 기반 loader 리팩터.
- auth redirect와 protected route 정책.
- 실제 디바이스에서 Android back/iOS swipe back 수동 QA.
