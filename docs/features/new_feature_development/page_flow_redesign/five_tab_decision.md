# Five Tab Decision

## 결정

`5탭 통합`으로 결정한다.

결정일: 2026-05-30

## 결정 요약

Plan G로 6탭 router shell이 안정화되었으므로, 장기 IA 목표에 맞춰 하단 탭을 `홈`, `포트폴`, `거래`, `분석`, `My`의 5개로 줄이는 방향을 채택한다.

단, Plan H에서는 구현하지 않는다. 통계 기능은 제거하지 않고, `/statistics` route도 호환 경로로 보존한다. 실제 5탭 전환은 별도 구현 계획인 `Plan H-Impl. 5탭 Shell 통합`에서만 진행한다.

## 판단 기준별 근거

| 기준 | 판단 |
| --- | --- |
| 발견성 | 통계는 중요하지만 독립 하단 탭보다 분석 내부의 명확한 섹션으로 제공해도 기능 발견성을 유지할 수 있다. |
| 하단 탭 밀도 | 6탭은 모바일 하단 내비게이션에서 밀도가 높고, Plan G 이후 route 직접 진입이 가능해졌으므로 탭 수를 줄일 기반이 생겼다. |
| 기능 경계 | 분석과 통계는 모두 회고/리포트 성격이 있어 장기적으로 하나의 `분석` 영역에 묶는 편이 이해하기 쉽다. |
| 구현 리스크 | snapshot/annual loader 전환 없이도 `/statistics` route를 보존하고 분석 탭에서 링크하는 방식으로 1차 통합이 가능하다. |
| 테스트 비용 | Plan G에서 router smoke가 추가되어 shell route 변경 회귀를 잡을 수 있다. |
| 장기 IA | `홈 · 포트폴 · 거래 · 분석 · My` 5탭 구조가 상위 개편 원칙과 가장 잘 맞는다. |

## 통합 범위

| 항목 | 결정 |
| --- | --- |
| 하단 탭 | `통계` 탭 제거, `분석` 탭으로 통합 |
| 분석 화면 | 통계 진입 섹션 또는 compact entry group 추가 |
| 통계 화면 | 기능 제거 없이 `StatisticsPage` 유지 |
| `/statistics` route | 삭제하지 않고 호환 route로 유지 |
| shell selected tab | `/statistics` 직접 진입 시 `분석` 탭 selected 처리 |
| snapshot/annual route | 객체/list 전달 구조 유지, id 기반 loader 전환은 별도 후속 |
| My 탭 | `내부 DB 요약 복사 (GPT)` 포함 기존 접근성 유지 |

## 사용성 영향

- 하단 탭 수가 6개에서 5개로 줄어 반복 사용성이 좋아진다.
- 분석 탭은 성과, 수익, 진단, 통계성 기록을 함께 담는 리포트 허브가 된다.
- 통계 기능은 사라지지 않지만, 기존처럼 하단 탭 한 번으로 바로 들어가는 접근성은 줄어든다.
- 이를 보완하기 위해 분석 첫 화면에서 통계/스냅샷 진입점을 명확히 제공해야 한다.

## Route 영향

| route | 결정 |
| --- | --- |
| `/analysis` | 5탭의 분석 루트로 유지 |
| `/statistics` | 호환 route로 유지 |
| `MoneyfyRouteNames.statistics` | 삭제하지 않고 route compatibility에 사용 |
| snapshot detail | 현 구조 유지 |
| annual analysis | 현 구조 유지 |

## 테스트 영향

후속 구현에서 아래 테스트를 수정 또는 추가한다.

| 테스트 | 변경 |
| --- | --- |
| `test/router_smoke_test.dart` | shell tab 목록을 5탭 기준으로 수정하고 `/statistics` 호환 route 확인 |
| `test/page_walkthrough_test.dart` | 하단 탭 방문 기대값에서 `통계` 탭 제거, 분석 내부 통계 진입 확인 |
| `test/widget_test.dart` | shell smoke가 5탭 구조를 확인하도록 수정 |
| 신규 targeted test | `/statistics` 직접 진입 시 분석 탭 selected 처리 확인 |

## 후속 작업

다음 구현은 자동으로 시작하지 않는다. 사용자가 명시적으로 승인하면 아래 별도 계획을 진행한다.

- `plans/10_plan_h_impl_five_tab_shell.md`

## 비결정 사항

- `StatisticsPage` 자체 UI 대규모 재설계는 결정하지 않는다.
- snapshot detail/annual analysis의 named route loader 전환은 결정하지 않는다.
- form named route 전환은 Plan I 범위로 남긴다.
- My 탭 구조와 GPT용 DB 요약 복사 기능 위치는 바꾸지 않는다.
