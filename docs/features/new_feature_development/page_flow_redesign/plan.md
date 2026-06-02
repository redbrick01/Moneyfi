# Page Flow Redesign Plan

페이지 개편 상위 인덱스. 실제 구현 범위는 `plans/` 아래 세부 계획 파일에서만 확정.

## 문서 구조

| 문서 | 역할 |
| --- | --- |
| plans/00_overview_and_routing.md | 배경, 원칙, 최종 IA, 라우팅 전환 |
| plans/01_plan_a_baseline_matrix.md | 기준선/의존성 매트릭스 |
| plans/02_plan_b_ux_quick_wins.md | 라우팅 변경 없는 UX quick wins |
| plans/03_plan_c_route_registry.md | route registry, navigation helper 기준선 |
| plans/04_plan_d_portfolio_diagnosis.md | 포트폴리오 진단 진입점/명칭 통합 |
| plans/05_plan_e_analysis_statistics.md | 분석/통계 IA 정리 |
| plans/06_plan_f_input_onboarding.md | 입력 온보딩 정돈 |
| plans/07_plan_g_go_router_shell.md | 6탭 상태 GoRouter 셸 전환 |
| plans/08_plan_h_five_tab_decision.md | 5탭 통합 결정 |
| plans/09_plan_i_form_named_routes.md | 폼 named route 전환 |
| plans/10_plan_h_impl_five_tab_shell.md | Plan H 결정 따른 5탭 shell 구현 |

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

1. 한 번에 세부 계획 1개만 구현.
2. 각 세부 계획은 해당 파일 `역할`, `범위`, `제외`, `산출물`, `완료 조건` 만족해야 완료.
3. 완료 후 구현 리포트와 테스트 결과 남기고 정지.
4. 다음 세부 계획 착수는 사용자 승인 또는 명시 요청 있을 때만.
5. 계획 중 새 작업 발견 시 현재 세부 계획에 넣지 말고 `후속 후보` 기록.
6. 라우팅 전환과 5탭 통합은 독립 의사결정.

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

- Plan B와 Plan C 순서 변경 가능. 같은 작업 단위로 묶지 않음.
- Plan G는 Plan A와 Plan C 완료 전 착수 금지.
- Plan H는 Plan G 완료 전 착수 금지.
- Plan I는 Plan G 완료 전 착수 금지.
- 각 계획 완료 후 사용자 명시 전까지 정지.

## 상위 완료 정의

상위 계획은 모든 세부 계획 구현해야 완료되는 문서 아님. 완료는 선택된 세부 계획 단위 판단.

- 선택된 세부 계획 완료 조건 모두 충족.
- 계획 범위 밖 변경 없음. 있으면 별도 후속 후보 문서화.
- 구현 리포트와 테스트 결과 있음.
- 남은 세부 계획은 `미착수`, `보류`, `불필요` 중 하나로 상태 기록.

## 세부 문서 병합 요약

### 핵심 계획

- overview/routing은 개편 원칙, 최종 IA 이미지, route 전환 원칙, 데이터 전달 원칙 정의.
- Plan A는 route/test coverage baseline과 의존성 matrix 생성.
- Plan B는 포트폴리오 상세 진입, 거래 empty CTA, 포트폴리오 빈 상태, My 탭 DB 요약 copy 등 UX quick wins 처리.
- Plan C는 route constants, argument type, navigator helper, safe caller 적용해 route registry baseline 생성.
- Plan D는 포트폴리오 진단 명칭/역할/진입 정책 통합.
- Plan E는 분석 탭과 통계 탭 역할, 스냅샷/연도별 분석 소속 정리.
- Plan F는 첫 입력 권장 순서, 거래 empty state, 자산 상세 empty CTA, 거래 폼 안내 정돈.
- Plan G는 GoRouter shell 전환 적용. Plan H/H-Impl은 5탭 통합 결정을 shell destination 축소로 반영.
- Plan I는 form named route 전환. 보류 route는 별도 후보로 남김.

### 구현/결정 결과

- Plan A-I 모두 구현 리포트 또는 결정 문서 남김.
- 5탭 통합은 `five_tab_decision.md`에서 결정. statistics는 analysis 탭으로 통합.
- `route_matrix.md`는 route feasibility, direct push/modal surfaces, Plan C/F/G/H/I 적용 결과, `push<bool>` dependency 추적.
- `test_coverage_matrix.md`는 주요 테스트 파일, page walkthrough coverage, route-level gap, plan별 최소 검증 기준 정리.

### 검증 핵심

- Plan B-F test report는 실행 명령, 실패 상세, plan 판정, manual QA 기록.
- Plan G/H-Impl/I test report는 router smoke coverage와 특이사항 기록.
- 각 세부 계획은 완료 후 다음 계획 자동 진행 없음. 별도 승인 또는 명시 요청 때만 착수.
- 새 작업은 현재 plan scope에 넣지 않고 후속 후보로 문서화.