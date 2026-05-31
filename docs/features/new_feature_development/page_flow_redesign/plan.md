# Page Flow Redesign Plan

이 문서는 페이지 개편의 상위 인덱스다. 실제 구현 범위는 `plans/` 아래의 세부 계획 파일에서만 확정한다.

## 문서 구조

| 문서 | 역할 |
| --- | --- |
| [plans/00_overview_and_routing.md](plans/00_overview_and_routing.md) | 배경, 원칙, 최종 IA, 라우팅 전환 방향 |
| [plans/01_plan_a_baseline_matrix.md](plans/01_plan_a_baseline_matrix.md) | 기준선/의존성 매트릭스 작성 |
| [plans/02_plan_b_ux_quick_wins.md](plans/02_plan_b_ux_quick_wins.md) | 라우팅 변경 없는 빠른 UX 개선 |
| [plans/03_plan_c_route_registry.md](plans/03_plan_c_route_registry.md) | route registry와 navigation helper 기준선 |
| [plans/04_plan_d_portfolio_diagnosis.md](plans/04_plan_d_portfolio_diagnosis.md) | 포트폴리오 진단 진입점/명칭 통합 |
| [plans/05_plan_e_analysis_statistics.md](plans/05_plan_e_analysis_statistics.md) | 분석/통계 IA 정리 |
| [plans/06_plan_f_input_onboarding.md](plans/06_plan_f_input_onboarding.md) | 입력 온보딩 정돈 |
| [plans/07_plan_g_go_router_shell.md](plans/07_plan_g_go_router_shell.md) | 6탭 상태에서 GoRouter 셸 전환 |
| [plans/08_plan_h_five_tab_decision.md](plans/08_plan_h_five_tab_decision.md) | 5탭 통합 여부 결정 |
| [plans/09_plan_i_form_named_routes.md](plans/09_plan_i_form_named_routes.md) | 폼 named route 전환 |
| [plans/10_plan_h_impl_five_tab_shell.md](plans/10_plan_h_impl_five_tab_shell.md) | Plan H 결정에 따른 5탭 shell 구현 계획 |

## 진행 상태

| 계획 | 상태 | 비고 |
| --- | --- | --- |
| Plan A. 기준선/의존성 매트릭스 | 완료 | `route_matrix.md`, `test_coverage_matrix.md`, `plan_a_completion_report.md` 작성 |
| Plan B. UX Quick Wins | 완료 | `implementation_report_plan_b.md`, `test_report_plan_b.md` 작성 |
| Plan C. Route Registry Baseline | 완료 | `implementation_report_plan_c.md`, `test_report_plan_c.md` 작성 |
| Plan D. 포트폴리오 진단 통합 | 완료 | `implementation_report_plan_d.md`, `test_report_plan_d.md` 작성 |
| Plan E. 분석/통계 IA 정리 | 완료 | `implementation_report_plan_e.md`, `test_report_plan_e.md` 작성 |
| Plan F. 입력 온보딩 정돈 | 완료 | `implementation_report_plan_f.md`, `test_report_plan_f.md` 작성 |
| Plan G. GoRouter 6탭 셸 전환 | 완료 | `implementation_report_plan_g.md`, `test_report_plan_g.md` 작성 |
| Plan H. 5탭 통합 결정 | 완료 | `five_tab_decision.md` 작성, 5탭 통합 결정 |
| Plan H-Impl. 5탭 Shell 통합 | 완료 | `implementation_report_plan_h_impl.md`, `test_report_plan_h_impl.md` 작성 |
| Plan I. 폼 Named Route 전환 | 완료 | `implementation_report_plan_i.md`, `test_report_plan_i.md` 작성 |

## 통제 규칙

1. 한 번에 하나의 세부 계획만 구현한다.
2. 각 세부 계획은 해당 파일의 `역할`, `범위`, `제외`, `산출물`, `완료 조건`을 만족해야 완료로 본다.
3. 완료 후에는 구현 리포트와 테스트 결과를 남기고 멈춘다.
4. 다음 세부 계획 착수는 별도 사용자 승인 또는 명시 요청이 있을 때만 한다.
5. 계획 중 새 작업이 발견되면 현재 세부 계획에 끼워 넣지 않고 `후속 후보`로 기록한다.
6. 라우팅 전환과 5탭 통합은 서로 독립된 의사결정으로 취급한다.

## 권장 순서

1. Plan A. 기준선/의존성 매트릭스
2. Plan B. UX Quick Wins
3. Plan C. Route Registry Baseline
4. Plan D. 포트폴리오 진단 통합
5. Plan E. 분석/통계 IA 정리
6. Plan F. 입력 온보딩 정돈
7. Plan G. GoRouter 6탭 셸 전환
8. Plan H. 5탭 통합 결정
9. Plan I. 폼 Named Route 전환

## 게이트

- Plan B와 Plan C는 순서를 바꿀 수 있지만 같은 작업 단위로 묶지 않는다.
- Plan G는 Plan A와 Plan C 완료 전 착수하지 않는다.
- Plan H는 Plan G 완료 전 착수하지 않는다.
- Plan I는 Plan G 완료 전 착수하지 않는다.
- 각 계획 완료 후 사용자가 다음 계획 착수를 명시하기 전까지 멈춘다.

## 상위 완료 정의

이 상위 계획은 모든 세부 계획을 구현해야 완료되는 문서가 아니다. 완료는 선택된 세부 계획 단위로 판단한다.

- 선택된 세부 계획의 완료 조건이 모두 충족된다.
- 계획 범위 밖 변경이 없거나, 별도 후속 후보로 문서화된다.
- 구현 리포트와 테스트 결과가 남는다.
- 남은 세부 계획은 `미착수`, `보류`, `불필요` 중 하나로 상태가 기록된다.
