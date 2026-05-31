# 04. Attribution And Reconciliation

상태: 완료

## Role

성과를 만든 원인을 설명하고, 투자성과와 현금흐름/총자산 변화의 관계를 연결하는 구현 범위를 확정한다.

이 phase의 목적은 사용자가 `왜 성과가 났는지`와 `입출금이 성과와 어떻게 분리되는지`를 이해하게 하는 것이다.

## Depends On

- [02_report_view_model_contract.md](02_report_view_model_contract.md)
- [03_judgment_header.md](03_judgment_header.md)

## Scope

1. 기존 성과 원인 섹션을 compact attribution breakdown으로 재구성한다.
2. 가장 큰 플러스/마이너스 원인 문장을 표시한다.
3. 비용 영향 문장을 표시한다.
4. 기존 제외 현금흐름 섹션을 reconciliation/fallback 구조로 대체한다.
5. 총자산 검산 가능 시 시작 총자산, 순 투자성과, 외부 입출금, 종료 총자산, 잔차를 표시한다.
6. 검산 불가능 시 `성과와 현금흐름` fallback을 표시한다.

## Out Of Scope

- judgment header 수정
- 월별/종목별/위험 영역 구현
- 종목별 비용 배분
- 월별 미실현손익 계산
- 내부 이동/결제 현금흐름을 총자산 검산에 무리하게 합산
- 새 DB schema 도입
- IRR/MWRR/XIRR 계산
- 새로운 투자 조언 문구

## Implementation Boundary

이 phase에서 바꿀 수 있는 영역:

| 대상 | 처리 |
| --- | --- |
| `_PerformanceAttributionCard` | compact attribution + summary 문장 구조로 재작성 |
| `_AttributionRow` | 유지/수정 가능. contribution unavailable 상태 대응 추가 |
| `_AttributionData` | `_AttributionEntryState` 기반으로 대체 가능 |
| `_CashFlowExclusionCard` | `_PerformanceReconciliationSection` 또는 동등한 이름으로 대체 |
| `_MetricRow` | reconciliation row로 재사용 가능 |

이 phase에서 바꾸지 않는 영역:

| 대상 | 이유 |
| --- | --- |
| `_PerformanceJudgmentHeader` | Phase 3 완료 범위 |
| `_MonthlyTrendCard` | Phase 5 담당 |
| `_HoldingContributionCard` | Phase 5 담당 |
| `_MarketAndRiskCard` risk 부분 | Phase 5 담당 |
| `_HoldingPerformance.totalPerformance` | 종목별 비용 배분 금지 |

## Required View Model Inputs

이 phase는 02 계약의 아래 state만 사용한다.

```text
_InvestmentPerformanceViewModel
- attribution
- reconciliation
```

필수 state:

| State | Required field |
| --- | --- |
| `attribution.entries` | 실현손익, 미실현손익, 배당/이자, 수수료, 세금 |
| `attribution.topPositive` | 가장 큰 플러스 요인 |
| `attribution.topNegative` | 가장 큰 마이너스 요인 |
| `attribution.total` | 순 투자성과 |
| `attribution.expenseTotal` | 수수료 + 세금 |
| `reconciliation.mode` | `available` 또는 `fallback` |
| `reconciliation.startTotalAsset` | 검산 가능 시 시작 총자산 |
| `reconciliation.endTotalAsset` | 검산 가능 시 종료 총자산 |
| `reconciliation.pureInvestmentPerformance` | 순 투자성과 |
| `reconciliation.externalCashFlow` | 외부 입출금 합계 |
| `reconciliation.externalDeposit` | 외부 입금 |
| `reconciliation.externalWithdrawal` | 외부 출금 |
| `reconciliation.internalMovement` | 내부 이동 |
| `reconciliation.tradeSettlementCashFlow` | 투자 결제 현금흐름 |
| `reconciliation.residual` | 검산 가능 시 차이 |
| `reconciliation.fallbackReason` | 검산 불가 사유 |

금지:

- widget에서 contribution 분모 0을 직접 계산하지 않는다.
- widget에서 총자산 검산 가능 여부를 raw snapshot null로 직접 판정하지 않는다.
- widget에서 내부 이동/결제 현금흐름을 총자산 변화 식에 임의로 더하지 않는다.

## Attribution Contract

### Entries

항목 순서는 고정한다.

| 순서 | Label | Amount |
| --- | --- | --- |
| 1 | `실현손익` | `report.realizedProfit` |
| 2 | `미실현손익` | `report.unrealizedProfit` |
| 3 | `배당/이자` | `report.incomeAmount` |
| 4 | `수수료` | `-report.feeAmount` |
| 5 | `세금` | `-report.taxAmount` |

### Summary Copy

01 계약의 문구를 그대로 사용한다.

| State | Copy |
| --- | --- |
| top positive exists | `이번 기간 성과는 {label}이 가장 크게 만들었습니다.` |
| top negative exists | `{label}이 성과를 가장 크게 낮췄습니다.` |
| no dominant factor | `이번 기간에는 두드러진 성과 요인이 없습니다.` |
| expense exists | `수수료와 세금은 전체 순성과에서 차감됩니다.` |

Summary rendering rule:

- top positive 문장을 우선 표시한다.
- top negative가 있으면 보조 문장 또는 다음 줄로 표시한다.
- positive/negative 둘 다 없으면 neutral summary를 표시한다.
- 비용이 0보다 크면 cost helper를 표시한다.

### Contribution

| State | UI |
| --- | --- |
| `contribution.available(value)` | `{value}%` |
| `contribution.unavailable(zeroBasisAmount)` | contribution text 생략 |

Rules:

- total이 0에 가까우면 contribution을 표시하지 않는다.
- NaN/Infinity는 절대 화면에 표시하지 않는다.
- bar 길이는 contribution이 아니라 `maxAbsComponent` 기준으로 계산한다.

### Bar Rules

| Rule | Decision |
| --- | --- |
| 기준 | attribution entries 중 `amount.abs()` 최대값 |
| positive color | design token의 positive semantic |
| negative color | design token의 negative semantic |
| zero color | neutral surface/outline token |
| height | chart geometry 예외. 기존 6-8px 범위 권장 |
| radius | `context.radius` 사용 |

## Reconciliation Contract

### Available Mode

총자산 검산 가능 시 아래 row를 표시한다.

```text
총자산 변화 검산
선택 기간의 시작/종료 총자산 기준으로 연결했습니다.

시작 총자산
순 투자성과
외부 입출금
종료 총자산
차이
```

Available mode 표시 규칙:

| Row | Source |
| --- | --- |
| 시작 총자산 | `reconciliation.startTotalAsset.available` |
| 순 투자성과 | `reconciliation.pureInvestmentPerformance` |
| 외부 입출금 | `reconciliation.externalCashFlow` |
| 종료 총자산 | `reconciliation.endTotalAsset.available` |
| 차이 | `reconciliation.residual.available` |

검산 식의 표시 의미:

```text
시작 총자산 + 순 투자성과 + 외부 입출금 ~= 종료 총자산
```

주의:

- 내부 이동과 투자 결제 현금흐름은 검산식에 직접 더하지 않는다.
- 내부 이동과 투자 결제 현금흐름은 상세/부록성 row로만 표시한다.

### Fallback Mode

검산 불가능 시 아래 구조를 표시한다.

```text
성과와 현금흐름
순 투자성과는 입출금과 내부 이동을 제외한 투자 결과입니다.

순 투자성과
외부 입금
외부 출금
외부 입출금
투자 결제 현금흐름
내부 이동
```

Fallback reason copy:

| Reason | Copy |
| --- | --- |
| `missingStartSnapshot` | `시작 기준 총자산이 없어 현금흐름만 분리해 표시합니다.` |
| `missingEndSnapshot` | `종료 기준 총자산이 없어 현금흐름만 분리해 표시합니다.` |
| `unsupportedForRange` | `총자산 변화 검산에 필요한 스냅샷이 부족합니다.` |
| `unknown` | `총자산 변화 검산에 필요한 스냅샷이 부족합니다.` |

Fallback mode는 실패 상태가 아니다. snapshot 기준이 부족한 정상 UI 상태다.

## Snapshot Boundary

이 phase 문서는 snapshot 선택 알고리즘을 새로 확정하지 않는다.

허용:

- 02 계약의 `_ReconciliationState.mode`를 읽어 available/fallback을 렌더링한다.
- available 상태가 들어오면 검산 row를 표시한다.
- fallback 상태가 들어오면 현금흐름 분리 row를 표시한다.

금지:

- 이 phase에서 `fetchPreviousPortfolioSnapshot` 호출 규칙을 새로 정하지 않는다.
- 이 phase에서 `전체` 기간의 시작 총자산 기준을 새로 정하지 않는다.
- 이 phase에서 현재 평가액을 종료 총자산으로 임의 사용하지 않는다.

Snapshot 선택 기준은 별도 implementation decision 또는 Phase 4 구현 직전 change note로 확정해야 한다.

## Design Contract

모든 디자인 요소는 기존 design md와 token을 따른다.

Allowed patterns:

| UI need | Use |
| --- | --- |
| Section surface | `SectionCard` or existing panel contract |
| Row | existing `_MetricRow` pattern or design-system row |
| Amount typography | `context.typography.cardTitle`, `context.typography.meta` |
| Summary text | `context.typography.meta` or `context.typography.cardTitle` |
| Positive/negative | `_valueColor` 기준 또는 equivalent semantic helper |
| Bar color | `context.colors.positiveContainer`, `context.colors.negativeContainer`, neutral surface token |
| Spacing/radius | `context.spacing`, `context.radius`, `VisualSpec.surface` |

Hardcoding rule:

- No raw hex colors.
- No arbitrary `EdgeInsets`.
- No arbitrary `BorderRadius` outside token access.
- Divider/bar heights must either use token rhythm or be documented as chart geometry exception.

## Implementation Steps

1. Use `_InvestmentPerformanceViewModel.attribution` in the attribution section.
2. Render top positive/negative summary before breakdown rows.
3. Render entries in fixed order.
4. Render contribution only when `MetricValue.available`.
5. Ensure total 0 does not show NaN/Infinity.
6. Replace `_CashFlowExclusionCard` with reconciliation/fallback section.
7. If `reconciliation.mode == available`, render `총자산 변화 검산`.
8. If `reconciliation.mode == fallback`, render `성과와 현금흐름`.
9. Keep internal movement and trade settlement as explanatory rows, not equation rows.

## Tests Required In This Phase

| Test | Expectation |
| --- | --- |
| attribution renders fixed entries | 실현손익, 미실현손익, 배당/이자, 수수료, 세금 visible |
| attribution top positive | largest positive entry appears in summary |
| attribution top negative | largest negative entry appears in summary |
| attribution neutral | all near zero -> neutral summary |
| attribution total zero | contribution omitted, no NaN/Infinity |
| attribution expenses | fee/tax positive raw amounts render as negative rows |
| reconciliation available | start/end/residual rows visible |
| reconciliation fallback missing start | fallback copy visible |
| reconciliation fallback missing end | fallback copy visible |
| cash flow separation | external deposits/withdrawals separate from pure performance |
| no holding cost allocation | no 종목별 비용 배분 change in this phase |

Visual checks:

- attribution long label/value row at 360dp
- contribution text omitted cleanly when unavailable
- reconciliation rows at 390dp text scale 1.3
- positive/negative/neutral colors remain token-based

## Completion Gate

- [x] attribution 항목이 실현, 미실현, 배당/이자, 수수료, 세금으로 표시된다.
- [x] 기여율 분모가 0일 때 NaN/Infinity가 표시되지 않는다.
- [x] 가장 큰 플러스/마이너스 원인 문구가 데이터에 맞게 표시된다.
- [x] 비용만 있는 경우에도 breakdown이 깨지지 않는다.
- [x] 총자산 검산 가능/불가능 상태가 구분된다.
- [x] 외부 입금/출금이 투자성과에 섞여 보이지 않는다.
- [x] reconciliation row와 bar가 design token을 따른다.

## Completion Meaning

위 체크박스는 이 문서의 계획 기준이 충족되었음을 뜻한다. 실제 구현 phase에서는 동일 항목을 테스트/QA로 다시 검증해야 한다.

## Stop Rule

reconciliation 구현 중 월별 미실현손익이나 종목별 비용 배분을 새로 구현하지 않는다. 해당 주제는 Phase 5 또는 후속 문서에서만 다룬다.

