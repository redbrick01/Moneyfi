# 02. Report/View Model Contract

상태: 완료

## Role

리디자인 UI가 필요한 데이터를 안정적으로 읽을 수 있도록 report/view model 계약을 정의한다.

이 단계는 UI 구현을 시작하기 전, 데이터와 상태 표현을 고정한다.

## Depends On

- [00_audit_and_boundaries.md](00_audit_and_boundaries.md)
- [01_ia_and_copy_contract.md](01_ia_and_copy_contract.md)

## Scope

1. `_InvestmentPerformanceReport`에서 유지할 raw 계산 field를 확정한다.
2. UI용 derived state를 `_InvestmentPerformanceViewModel` 또는 getter 묶음으로 정의한다.
3. 데이터 부족 사유 enum/state object를 정의한다.
4. benchmark state, risk state, attribution summary state를 정의한다.
5. reconciliation 가능 여부와 fallback state를 정의한다.
6. 테스트 가능한 계산 contract를 확정한다.

## Out Of Scope

- 화면 레이아웃 구현
- 디자인/spacing/token 적용
- copy 문구 새로 작성
- 신규 DB schema 설계
- 종목별 비용 완전 배분
- IRR/MWRR/XIRR 계산
- benchmark 선택 UI
- 월별 미실현손익 신규 계산

## Contract Decision

v2 구현은 기존 `_InvestmentPerformanceReport`를 raw calculation report로 유지하고, UI는 새 derived view model을 통해 상태를 읽는다.

권장 이름:

```text
_InvestmentPerformanceViewModel
```

핵심 원칙:

- UI widget은 nullable raw value를 직접 해석하지 않는다.
- null, 0, empty list, fallback을 구분하는 상태를 view model에서 만든다.
- 기존 계산식은 변경하지 않는다.
- 새로운 계산이 필요하면 derived state로만 추가하고, 원장 집계 함수는 건드리지 않는다.

## Raw Report Contract

기존 `_InvestmentPerformanceReport`는 아래 역할로 유지한다.

| Field/Getter | 유지 여부 | 역할 |
| --- | --- | --- |
| `holdings` | 유지 | 종목별 기여도 raw list |
| `monthlyPerformance` | 유지 | 월별 확정 성과 raw list |
| `advancedPerformance` | 유지 | 기간 수익률, benchmark, risk raw report |
| `realizedProfit` | 유지 | 성과 원인 |
| `unrealizedProfit` | 유지 | 성과 원인, 순 투자성과 |
| `incomeAmount` | 유지 | 성과 원인 |
| `feeAmount` | 유지 | 비용 영향 |
| `taxAmount` | 유지 | 비용 영향 |
| `externalCashFlowAmount` | 유지 | 현금흐름 연결 |
| `externalDepositAmount` | 유지 | 현금흐름 연결 |
| `externalWithdrawalAmount` | 유지 | 현금흐름 연결 |
| `tradeSettlementCashFlowAmount` | 유지 | 데이터 기준/현금흐름 상세 |
| `internalCashMovementAmount` | 유지 | 데이터 기준/현금흐름 상세 |
| `buyAmount` | 유지 | 원금 대비 수익률 분모 |
| `sellAmount` | 유지 | 데이터 기준/보조 정보 |
| `pureRealizedPerformance` | 유지 | derived raw getter |
| `pureInvestmentPerformance` | 유지 | derived raw getter |
| `pureInvestmentPerformanceRate` | 유지 | 원금 대비 raw getter |
| `totalExpenseAmount` | 유지 | 비용 영향 raw getter |

금지:

- raw report 안에서 사용자 표시 copy를 만들지 않는다.
- raw report 안에서 데이터 부족 이유 문구를 만들지 않는다.
- raw report 계산식을 v2 UI 요구 때문에 바꾸지 않는다.

## View Model Contract

`_InvestmentPerformanceViewModel`은 `_InvestmentPerformanceReport`, `_PerformanceDateRange`, 추가 상태를 받아 UI section state를 제공한다.

필수 field:

| Field | Type 후보 | 설명 |
| --- | --- | --- |
| `range` | `_PerformanceDateRange` | 현재 선택 기간 |
| `judgment` | `_PerformanceJudgmentState` | 첫 화면 기간 수익률/순 투자성과 상태 |
| `benchmark` | `_BenchmarkSnapshotState` | 참고 벤치마크 상태 |
| `attribution` | `_AttributionSummaryState` | 성과 원인과 주요 요인 |
| `reconciliation` | `_ReconciliationState` | 총자산 검산 또는 현금흐름 fallback |
| `monthly` | `_MonthlySectionState` | 월별 확정 성과 state |
| `holdings` | `_HoldingContributionState` | 종목별 기여도 state |
| `risk` | `_RiskInterpretationState` | 위험 지표 state |
| `dataBasis` | `_DataBasisState` | 하단 기준/주의 문구 state |

생성 원칙:

- `fromReport(report, range, extraData)` 형태의 factory를 둔다.
- Phase 3-5에서 section별로 필요한 state를 점진 구현해도 된다.
- 단, state 이름과 unavailable reason은 이 문서 기준을 따른다.

## Metric State Contract

UI는 숫자 표시를 아래 공통 state로 읽는다.

```text
MetricValue<T>
- available(value)
- unavailable(reason)
```

권장 enum:

```text
MetricUnavailableReason
- noTransactions
- missingDailyReturns
- missingBenchmarkPrices
- missingRiskFreeRate
- insufficientObservations
- missingSnapshotBaseline
- missingStartSnapshot
- missingEndSnapshot
- zeroBasisAmount
- unsupportedForRange
- unknown
```

매핑:

| Reason | 01 copy |
| --- | --- |
| `noTransactions` | `분석할 투자 거래가 아직 없습니다.` |
| `missingDailyReturns` | `평가 데이터가 더 쌓이면 입출금 보정 수익률을 표시합니다.` |
| `missingBenchmarkPrices` | `참고 벤치마크 가격을 아직 확보하지 못했습니다.` |
| `missingRiskFreeRate` | `무위험수익률은 임시로 0% 기준을 사용했습니다.` |
| `insufficientObservations` | `최소 기간 데이터가 더 필요합니다.` |
| `missingSnapshotBaseline` | `시작 전 스냅샷이 없으면 미실현손익 기준점이 제한될 수 있습니다.` |
| `missingStartSnapshot` | `시작 기준 총자산이 없어 현금흐름만 분리해 표시합니다.` |
| `missingEndSnapshot` | `종료 기준 총자산이 없어 현금흐름만 분리해 표시합니다.` |
| `zeroBasisAmount` | `원금 대비 데이터 부족` |
| `unsupportedForRange` | `총자산 변화 검산에 필요한 스냅샷이 부족합니다.` |
| `unknown` | `데이터 부족` |

## Section State Contracts

### Judgment State

```text
_PerformanceJudgmentState
- periodReturn: MetricValue<double>
- pureInvestmentPerformance: double
- principalReturn: MetricValue<double>
- pureRealizedPerformance: double
- unrealizedProfit: double
- caption: fixed by 01 copy
```

Rules:

| State | Rule |
| --- | --- |
| `periodReturn.available` | `report.advancedPerformance.periodReturn != null` |
| `periodReturn.unavailable(missingDailyReturns)` | `periodReturn == null` and daily return rows are empty or all valid returns are null |
| `principalReturn.available` | `report.pureInvestmentPerformanceRate != null` |
| `principalReturn.unavailable(zeroBasisAmount)` | `buyAmount.abs() < tolerance` |
| `pureInvestmentPerformance` | always available from raw report |

Note:

- Current raw report does not expose daily return row count or dataQuality. Phase 2 implementation must either add lightweight extra state from `_loadAdvancedPerformanceReport` or initially map null periodReturn to `missingDailyReturns`.

### Benchmark Snapshot State

```text
_BenchmarkSnapshotState
- label: String
- portfolioReturn: MetricValue<double>
- benchmarkReturn: MetricValue<double>
- excessReturn: MetricValue<double>
- comparisonStatus: MetricUnavailableReason?
```

Rules:

| State | Rule |
| --- | --- |
| `portfolioReturn.available` | `periodReturn != null` |
| `portfolioReturn.unavailable(missingDailyReturns)` | `periodReturn == null` |
| `benchmarkReturn.available` | `benchmarkReturn != null` |
| `benchmarkReturn.unavailable(missingBenchmarkPrices)` | `periodReturn != null && benchmarkReturn == null` |
| `benchmarkReturn.unavailable(missingDailyReturns)` | `periodReturn == null` |
| `excessReturn.available` | `excessReturn != null` |
| `excessReturn.unavailable(...)` | follows missing side of portfolio/benchmark |

Boundary:

- Benchmark fetch failure is currently not preserved as a distinct state. Do not invent network/error copy in UI until loading code exposes it.
- v2 first implementation may use `missingBenchmarkPrices` for all benchmark null states after period return is available.

### Attribution Summary State

```text
_AttributionSummaryState
- entries: List<_AttributionEntryState>
- topPositive: _AttributionEntryState?
- topNegative: _AttributionEntryState?
- total: double
- expenseTotal: double
- contributionBasis: double
```

Entry contract:

```text
_AttributionEntryState
- label: String
- amount: double
- contribution: MetricValue<double>
- kind: positive | negative | neutral
```

Entries:

| Label | Amount |
| --- | --- |
| `실현손익` | `report.realizedProfit` |
| `미실현손익` | `report.unrealizedProfit` |
| `배당/이자` | `report.incomeAmount` |
| `수수료` | `-report.feeAmount` |
| `세금` | `-report.taxAmount` |

Rules:

| Calculation | Rule |
| --- | --- |
| `total` | `report.pureInvestmentPerformance` |
| `expenseTotal` | `report.totalExpenseAmount` |
| `contribution.available` | `total.abs() >= tolerance` |
| `contribution.unavailable(zeroBasisAmount)` | `total.abs() < tolerance` |
| `topPositive` | entry with largest amount where amount > tolerance |
| `topNegative` | entry with smallest amount where amount < -tolerance |
| `neutral summary` | no positive and no negative entry beyond tolerance |

Tie-break:

1. larger absolute amount wins.
2. if equal, keep display order: 실현손익, 미실현손익, 배당/이자, 수수료, 세금.

### Reconciliation State

```text
_ReconciliationState
- mode: available | fallback
- startTotalAsset: MetricValue<double>
- endTotalAsset: MetricValue<double>
- pureInvestmentPerformance: double
- externalCashFlow: double
- externalDeposit: double
- externalWithdrawal: double
- internalMovement: double
- tradeSettlementCashFlow: double
- residual: MetricValue<double>
- fallbackReason: MetricUnavailableReason?
```

Decision:

- 총자산 검산은 v2에서 지원하되, 첫 구현은 fallback 가능성을 기본으로 둔다.
- 현재 raw report에 시작/종료 총자산이 없으므로 Phase 4 전까지 `mode=fallback`이 정상 상태다.

Rules:

| State | Rule |
| --- | --- |
| `mode.available` | start/end total asset are both available under a documented snapshot rule |
| `mode.fallback(missingStartSnapshot)` | start total asset unavailable |
| `mode.fallback(missingEndSnapshot)` | end total asset unavailable |
| `mode.fallback(unsupportedForRange)` | `전체` 등 기준 정의가 불명확한 range |
| `residual.available` | only when mode is available |
| `residual.unavailable(...)` | follows fallback reason |

Snapshot rule deferred:

- 시작/종료 총자산 기준은 Phase 4 구현 전 확정한다.
- 이 문서는 state shape만 확정하고, 스냅샷 선택 알고리즘은 확정하지 않는다.

### Monthly Section State

```text
_MonthlySectionState
- items: List<_MonthlyPerformance>
- isEmpty: bool
- caption: fixed by 01 copy
```

Rules:

| State | Rule |
| --- | --- |
| empty | `report.monthlyPerformance.isEmpty` |
| non-empty | use up to latest 12 items, existing sort desc retained |
| caveat | always show monthly unrealized exclusion caption when section is visible |

No new monthly unrealized calculation in v2 first implementation.

### Holding Contribution State

```text
_HoldingContributionState
- items: List<_HoldingPerformance>
- isEmpty: bool
- filterMode: existing _HoldingFilterMode
- sortMode: existing _HoldingSortMode
- totalPerformanceBasis: double
- costAllocation: notAllocated
```

Rules:

| State | Rule |
| --- | --- |
| `costAllocation` | always `notAllocated` in v2 first implementation |
| contribution available | `totalPerformanceBasis.abs() >= tolerance` |
| contribution unavailable | `totalPerformanceBasis.abs() < tolerance` |
| filter/sort | existing behavior retained |

No 종목별 비용 완전 배분 in v2 first implementation.

### Risk Interpretation State

```text
_RiskInterpretationState
- volatility: MetricValue<double>
- sharpe: MetricValue<double>
- maxDrawdown: MetricValue<double>
- riskFreeRate: double
- riskFreeRateState: MetricValue<double>
```

Rules:

| Metric | Available | Unavailable reason |
| --- | --- | --- |
| volatility | `annualizedVolatility != null` | `insufficientObservations` when daily returns < 20 or null |
| sharpe | `sharpeRatio != null` | `insufficientObservations` when daily returns < 60 or null |
| maxDrawdown | `maxDrawdown != null` | `insufficientObservations` when portfolio values < 2 or null |
| riskFreeRate | `isRiskFreeRateFallback == false` | `missingRiskFreeRate` |

Note:

- Current raw report does not expose daily return count. Phase 2 implementation should add count/data-quality to advanced report or map nulls to `insufficientObservations`.

### Data Basis State

```text
_DataBasisState
- usesFallbackFx: bool
- hasSnapshotBaseline: bool
- holdingCostAllocation: notAllocated
- monthlyUnrealizedIncluded: false
- benchmarkLabel: String
- benchmarkIsReferenceOnly: true
```

Current limitations:

- `usesFallbackFx` is not exposed by current report. Initial implementation may show generic fallback caveat or add a boolean in loading step.
- `hasSnapshotBaseline` can be derived when `_fetchBaselineUnrealizedProfitByHoldingId` returns a status, but current helper returns only map. Phase 2 implementation should add a status wrapper if exact copy is needed.

## Derived Metric Contract

| Derived value | Formula / source | Existing calculation changes |
| --- | --- | --- |
| `periodReturn` | `report.advancedPerformance.periodReturn` | none |
| `pureInvestmentPerformance` | `report.pureInvestmentPerformance` | none |
| `principalReturn` | `report.pureInvestmentPerformanceRate` | none |
| `benchmarkReturn` | `report.advancedPerformance.benchmarkReturn` | none |
| `excessReturn` | `report.advancedPerformance.excessReturn` | none |
| `pureRealizedPerformance` | `report.pureRealizedPerformance` | none |
| `totalExpenseAmount` | `report.feeAmount + report.taxAmount` | none |
| `attribution contribution` | `entry.amount / report.pureInvestmentPerformance * 100` | existing contribution logic reused |
| `holding contribution` | `holding.totalPerformance / report.pureInvestmentPerformance * 100` | existing contribution logic reused |
| `monthly confirmed performance` | `realized + income - fee - tax` | existing monthly getter reused |

## Existing Calculation Change Decision

기존 계산식 변경 여부: `없음`

No changes:

- 순 실현성과
- 순 투자성과
- 매수 원금 대비 수익률
- 기간 수익률
- benchmark period return
- 초과수익률
- 변동성
- Sharpe
- 최대 낙폭
- 월별 확정 성과
- 종목 총 성과

## Unit Test List

구현 시 아래 테스트를 추가하거나 기존 테스트를 갱신한다.

| Test | Expected |
| --- | --- |
| `judgment state exposes available period return` | periodReturn value가 있으면 `available` |
| `judgment state falls back when period return is null` | periodReturn null이면 `missingDailyReturns` |
| `principal return uses zero basis reason` | buyAmount 0이면 `zeroBasisAmount` |
| `benchmark state separates portfolio and benchmark absence` | periodReturn 있음 + benchmark null이면 `missingBenchmarkPrices` |
| `benchmark state follows missing daily returns` | periodReturn null이면 benchmark도 비교 불가 |
| `attribution picks top positive and negative` | 최대 양수/최대 음수 항목 선택 |
| `attribution omits contribution when total is zero` | total 0이면 contribution unavailable |
| `reconciliation state falls back without snapshots` | start/end total asset 없으면 fallback |
| `risk volatility requires enough observations or value` | volatility null이면 `insufficientObservations` |
| `risk sharpe requires enough observations or value` | sharpe null이면 `insufficientObservations` |
| `risk free fallback maps to missingRiskFreeRate` | risk-free fallback이면 missingRiskFreeRate |
| `holding contribution keeps cost allocation not allocated` | v2 first implementation에서 costAllocation은 notAllocated |
| `monthly state keeps unrealized excluded` | monthlyUnrealizedIncluded false |

## Completion Gate

- [x] UI가 직접 raw nullable 값을 해석하지 않도록 state 계약이 정리되었다.
- [x] period return, benchmark, risk metric의 unavailable reason이 구분된다.
- [x] attribution의 가장 큰 플러스/마이너스 요인 계산 기준이 정해졌다.
- [x] reconciliation 가능 여부와 fallback 조건이 정해졌다.
- [x] 기존 계산식 변경 여부가 `없음`으로 확인되었거나 변경 사유가 별도 문서화되었다.
- [x] 필요한 unit test 목록이 확정되었다.

## Stop Rule

이 단계에서 UI를 만들지 않는다. view model 계약이 확정되기 전 Phase 3의 header 구현으로 넘어가지 않는다.

