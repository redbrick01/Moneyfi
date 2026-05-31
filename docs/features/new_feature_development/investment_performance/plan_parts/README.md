# Investment Performance Redesign v2 Plan Parts

이 폴더는 `투자성과 분석` v2 리디자인을 실행 가능한 독립 계획으로 분리한다.

중요 원칙:

- 각 문서는 해당 단계의 역할, 범위, 완료 조건만 다룬다.
- 한 단계를 진행하는 동안 다음 단계의 작업을 임의로 만들어 구현하지 않는다.
- 다음 단계로 넘어가려면 현재 단계의 `Completion Gate`가 모두 충족되어야 한다.
- 새 요구사항이 생기면 기존 phase에 몰래 추가하지 않고 `redesign_plan_v2.md`의 `Open Decisions` 또는 별도 후속 문서로 기록한다.
- 모든 디자인 작업은 `docs/design_system.md`, design md component contract, `lib/design_system` token/context extension을 우선한다.

## Execution Order

| 순서 | 문서 | 역할 |
| --- | --- | --- |
| 0 | [00_audit_and_boundaries.md](00_audit_and_boundaries.md) | 현재 구조, 데이터, 디자인 토큰 이탈, 구현 경계를 확정 |
| 1 | [01_ia_and_copy_contract.md](01_ia_and_copy_contract.md) | 새 IA, 섹션명, 화면 copy, 데이터 부족 문구를 고정 |
| 2 | [02_report_view_model_contract.md](02_report_view_model_contract.md) | UI가 사용할 report/view model과 metric state 계약을 정의 |
| 3 | [03_judgment_header.md](03_judgment_header.md) | 첫 화면 판단 영역과 벤치마크 strip 구현 범위를 정의 |
| 4 | [04_attribution_and_reconciliation.md](04_attribution_and_reconciliation.md) | 성과 원인과 총자산 변화/현금흐름 연결 영역을 정의 |
| 5 | [05_detail_sections_and_risk.md](05_detail_sections_and_risk.md) | 월별, 종목별, 위험 해석 영역을 정의 |
| 6 | [06_responsive_empty_states_and_qa.md](06_responsive_empty_states_and_qa.md) | 반응형, 빈 상태, 테스트, visual QA 완료 조건을 정의 |

## Non-Expansion Rule

각 phase 실행 중 발견된 아이디어는 즉시 구현하지 않는다.

| 발견 유형 | 처리 |
| --- | --- |
| 현재 phase completion gate를 막는 문제 | 현재 phase 안에서 해결 |
| 다음 phase에 이미 포함된 문제 | 다음 phase 문서에 따라 처리 |
| 어떤 phase에도 없는 새 기능 | 별도 follow-up 문서 또는 `Open Decisions`에 기록 |
| 디자인 토큰/문법 부족 | 예외 사유와 token화 후보를 기록하고 최소 범위로 처리 |

