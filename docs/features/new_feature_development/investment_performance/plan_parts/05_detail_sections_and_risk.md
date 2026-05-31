# 05. Detail Sections And Risk

상태: 완료

## Role

하단 상세 영역을 판단 보조 정보로 재정리한다. 월별, 종목별, 위험 지표를 각각의 범위가 명확한 섹션으로 만든다.

이 phase는 상단 판단/성과 원인/검산을 보완하는 상세 영역만 다룬다.

## Depends On

- [01_ia_and_copy_contract.md](01_ia_and_copy_contract.md)
- [02_report_view_model_contract.md](02_report_view_model_contract.md)
- [04_attribution_and_reconciliation.md](04_attribution_and_reconciliation.md)

## Scope

1. `월별 실현성과`를 `월별 확정 성과`로 변경한다.
2. 월별 섹션에 `미실현 평가 변화는 포함하지 않습니다.` caption을 표시한다.
3. 월별 mini bar와 row를 compact하게 조정한다.
4. 종목별 기여도 row를 조밀하게 재구성한다.
5. 종목별 섹션에 비용 미배분 caption을 표시한다.
6. 위험 지표를 숫자 + 해석 문장 + 데이터 부족 사유 tile로 재구성한다.
7. benchmark 비교는 이 섹션에서 중복 표시하지 않는다.

## Out Of Scope

- 첫 화면 header 수정
- 총자산 검산 수정
- 월별 미실현손익 계산 신규 도입
- 종목별 비용 완전 배분
- 사용자 지정 benchmark
- 투자 조언 문구
- 새 drill-down 화면
- 거래 상세 route 추가
- 위험 지표 신규 계산식 추가

## Implementation Boundary

이 phase는 세 영역으로만 나뉜다.

| 영역 | 담당 widget 후보 | 처리 |
| --- | --- | --- |
| 월별 확정 성과 | `_MonthlyTrendCard`, `_MonthlyBarStrip`, `_MonthlyBar`, `_MonthlyTrendRow` | 이름/caption/row copy/density 수정 |
| 종목별 기여도 | `_HoldingContributionCard`, `_HoldingContributionRow`, `_MetricPill` | 비용 미배분 caption, row density, overflow 대응 |
| 위험 해석 | `_MarketAndRiskCard`, `_RiskMetricTile` | benchmark 제거, risk interpretation tiles로 재구성 |

이 phase에서 건드리지 않는 영역:

| 대상 | 이유 |
| --- | --- |
| `_PerformanceJudgmentHeader` | Phase 3 담당 |
| `_BenchmarkSnapshotStrip` | Phase 3 담당 |
| `_PerformanceAttributionCard` | Phase 4 담당 |
| `_PerformanceReconciliationSection` | Phase 4 담당 |
| `_HoldingPerformance.totalPerformance` | 비용 배분 금지 |
| monthly unrealized calculation | v2 첫 구현 범위 제외 |

## Required View Model Inputs

이 phase는 02 계약의 아래 state만 사용한다.

```text
_InvestmentPerformanceViewModel
- monthly
- holdings
- risk
- dataBasis
```

필수 state:

| State | Required field |
| --- | --- |
| `monthly.items` | 최근 최대 12개월 월별 확정 성과 |
| `monthly.isEmpty` | 월별 empty state |
| `monthly.caption` | 미실현 제외 caption |
| `holdings.items` | 종목별 기여도 list |
| `holdings.isEmpty` | 종목 empty state |
| `holdings.filterMode` | 기존 필터 |
| `holdings.sortMode` | 기존 정렬 |
| `holdings.totalPerformanceBasis` | 기여율 분모 |
| `holdings.costAllocation` | `notAllocated` |
| `risk.volatility` | 변동성 state |
| `risk.sharpe` | Sharpe state |
| `risk.maxDrawdown` | 최대 낙폭 state |
| `risk.riskFreeRateState` | 무위험수익률 fallback state |

금지:

- widget에서 월별 미실현손익을 새로 계산하지 않는다.
- widget에서 종목별 비용 배분을 새로 계산하지 않는다.
- widget에서 risk metric null 상태를 직접 copy로 해석하지 않는다.
- risk 영역에서 benchmark comparison을 다시 표시하지 않는다.

## Monthly Confirmed Performance Contract

### Copy

| Element | Text |
| --- | --- |
| section title | `월별 확정 성과` |
| header trailing | `최근 {count}개월` |
| caption | `미실현 평가 변화는 포함하지 않습니다.` |
| empty | `월별로 집계할 확정 성과가 아직 없습니다.` |
| row detail | `실현 {realized} · 수입 {income} · 비용 {expense}` |
| result meaning | `순 확정 성과` |

### Data Rules

| Rule | Decision |
| --- | --- |
| item source | `report.monthlyPerformance` |
| visible count | latest max 12 items |
| sort | existing desc month order for rows, reversed for chart if needed |
| amount | `pureRealizedPerformance` |
| expense display | `-(fee + tax)` |
| unrealized | not included |

### Visual Rules

- mini bar chart stays compact.
- bar label uses `MM`.
- positive/negative bar colors use semantic tokens.
- caption must be visible whenever monthly section is visible.
- empty state still shows title and empty copy, not a blank area.

## Holding Contribution Contract

### Copy

| Element | Text |
| --- | --- |
| section title | `종목별 기여도` |
| caption | `수수료와 세금은 전체 비용으로 표시되며 종목별로 배분하지 않습니다.` |
| contribution label | `전체 대비` |
| total label | `총 성과` |
| empty all | `분석할 투자 거래가 아직 없습니다.` |
| empty realized | `실현손익이 발생한 매도 거래가 아직 없습니다.` |
| empty loss | `손실이 발생한 종목이 없습니다.` |
| empty income | `배당이나 이자가 발생한 종목이 없습니다.` |

### Filter Contract

기존 의미를 유지한다.

| Filter | Label | Rule |
| --- | --- | --- |
| all | `전체` | all visible holdings |
| realized | `실현` | `realizedProfit.abs() > tolerance` |
| loss | `손실` | `totalPerformance < -tolerance` |
| income | `수입` | `incomeAmount.abs() > tolerance` |

### Sort Contract

기존 의미를 유지한다.

| Sort | Label | Rule |
| --- | --- | --- |
| totalDesc | `총 성과` | totalPerformance desc |
| totalAsc | `손실` | totalPerformance asc |
| realizedDesc | `실현` | realizedProfit desc |
| unrealizedDesc | `미실현` | unrealizedProfit desc |
| incomeDesc | `배당/이자` | incomeAmount desc |

### Row Contract

Row 표시 정보:

```text
종목명
자산명 · 심볼 · 통화
실현 {amount}  미실현 {amount}  수입 {amount}
총 성과 {amount}     전체 대비 {percent}
```

Rules:

- `총 성과`는 기존 `realized + unrealized + income` 유지.
- 수수료/세금은 종목별로 배분하지 않는다.
- 기여율 분모가 0에 가까우면 `전체 대비`를 생략한다.
- 긴 종목명/심볼/통화는 wrap 또는 scaleDown으로 처리한다.

## Risk Interpretation Contract

### Copy

| Element | Text |
| --- | --- |
| section title | `위험 해석` |
| volatility label | `변동성` |
| volatility caption | `수익률 변동 폭입니다.` |
| sharpe label | `Sharpe` |
| sharpe caption | `위험 대비 성과입니다.` |
| drawdown label | `최대 낙폭` |
| drawdown caption | `선택 기간 중 고점 대비 가장 큰 하락입니다.` |
| risk-free fallback | `무위험수익률은 임시로 0% 기준을 사용했습니다.` |

### Metric Rendering

| Metric | Available UI | Unavailable UI |
| --- | --- | --- |
| volatility | annualized percent | `데이터 부족` + `최소 기간 데이터가 더 필요합니다.` |
| Sharpe | decimal | `데이터 부족` + `최소 기간 데이터가 더 필요합니다.` |
| maxDrawdown | signed percent | `데이터 부족` + `최소 기간 데이터가 더 필요합니다.` |
| riskFreeRate | footer/helper | fallback helper when missing |

### Boundary

- Risk 영역은 benchmark 수익률이나 S&P 500 대비 문구를 표시하지 않는다.
- `참고 벤치마크` 비교는 Phase 3의 benchmark strip에서만 표시한다.
- 위험 지표는 투자 조언으로 쓰지 않는다. "좋다/나쁘다/매수/매도" 판단을 피한다.

## Data Basis Touchpoint

이 phase에서 하단 `데이터 기준` 섹션을 구현할 수 있다면, 아래 세 문구는 최소 포함한다.

| Caveat | Text |
| --- | --- |
| 종목별 비용 | `종목별 총 성과에는 수수료와 세금이 종목별로 배분되지 않습니다.` |
| 월별 미실현 | `월별 확정 성과에는 미실현 평가 변화가 포함되지 않습니다.` |
| benchmark reference | `S&P 500은 기본 참고 기준이며, 포트폴리오 구성과 다를 수 있습니다.` |

단, Data Basis를 accordion으로 할지 static section으로 할지는 Phase 6 QA 전까지 확정하지 않아도 된다.

## Design Contract

모든 디자인 요소는 기존 design md와 token을 따른다.

Allowed patterns:

| UI need | Use |
| --- | --- |
| Section surface | `SectionCard` or existing panel contract |
| Filter chips | `_InvestmentChoiceChip`, `MoneyfyPillStyle` |
| Sort control | existing dropdown or design-system equivalent |
| Metric tile | `AppMetricTile` or compact row based on component contract |
| Amount color | `_valueColor` equivalent semantic helper |
| Typography | `context.typography` |
| Spacing/radius | `context.spacing`, `context.radius`, `VisualSpec.surface` |
| Chart color | semantic positive/negative/neutral tokens |

Hardcoding rule:

- No raw hex colors.
- No arbitrary `EdgeInsets`.
- No arbitrary `BorderRadius` outside token access.
- Chart geometry direct values are allowed only as documented chart exceptions.
- Dropdown replacement must follow existing component contract.

## Implementation Steps

### Monthly

1. Rename `_MonthlyTrendCard` title to `월별 확정 성과`.
2. Add caption `미실현 평가 변화는 포함하지 않습니다.`.
3. Keep latest max 12 months.
4. Keep mini bar compact.
5. Update empty copy.

### Holding

1. Rename section to `종목별 기여도`.
2. Add cost non-allocation caption.
3. Keep existing filter and sort semantics.
4. Adjust row density without adding nested cards.
5. Hide contribution when basis is zero.

### Risk

1. Remove benchmark comparison from risk section.
2. Convert risk grid into interpretation tiles.
3. Render metric unavailable reasons from `MetricValue`.
4. Show risk-free fallback helper when needed.

## Tests Required In This Phase

| Test | Expectation |
| --- | --- |
| monthly title and caption | `월별 확정 성과`, 미실현 제외 caption visible |
| monthly empty | `월별로 집계할 확정 성과가 아직 없습니다.` visible |
| monthly excludes unrealized | no UI implying monthly unrealized is included |
| holding title and caption | `종목별 기여도`, 비용 미배분 caption visible |
| holding filters retain behavior | 전체/실현/손실/수입 rules unchanged |
| holding sort retains behavior | 총 성과/손실/실현/미실현/배당/이자 rules unchanged |
| holding zero basis | contribution text omitted |
| risk unavailable | 데이터 부족 + 구체 reason visible |
| risk benchmark duplication absent | risk section does not show S&P 500 comparison |
| long holding row | long name/symbol/currency does not overlap amount |

Visual checks:

- 360dp monthly row
- 390dp holding row with long Korean name
- 430dp holding filters/sort
- 390dp text scale 1.3 risk tiles

## Completion Gate

- [x] 월별 섹션 이름과 caption이 확정 copy와 일치한다.
- [x] 월별 데이터 없음 상태가 깨지지 않는다.
- [x] 종목별 비용 미배분 안내가 화면에서 확인된다.
- [x] 필터 `전체`, `실현`, `손실`, `수입`이 기존 의미를 유지한다.
- [x] 정렬 `총 성과`, `손실`, `실현`, `미실현`, `배당/이자`가 기존 의미를 유지한다.
- [x] 위험 지표 null/부족 상태가 구체적 문구로 표시된다.
- [x] 360/390/430dp에서 긴 종목명과 금액이 겹치지 않는다.

## Completion Meaning

위 체크박스는 이 문서의 계획 기준이 충족되었음을 뜻한다. 실제 구현 phase에서는 동일 항목을 테스트/QA로 다시 검증해야 한다.

## Stop Rule

월별/종목별 상세를 다루는 동안 새 drill-down 화면, 비용 배분 엔진, 월별 총성과 계산을 추가하지 않는다. 이들은 별도 후속 계획으로만 다룬다.

