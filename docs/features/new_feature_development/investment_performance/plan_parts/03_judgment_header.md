# 03. Judgment Header

상태: 완료

## Role

첫 화면 판단 영역의 구현 범위를 확정한다. 사용자가 스크롤 전 `기간 수익률`, `순 투자성과`, `원금 대비`, `참고 벤치마크 상태`를 구분해서 볼 수 있게 한다.

이 문서는 구현 계획이다. 실제 Flutter 코드는 이 문서의 Completion Gate를 기준으로 별도 구현 단계에서 작성한다.

## Depends On

- [01_ia_and_copy_contract.md](01_ia_and_copy_contract.md)
- [02_report_view_model_contract.md](02_report_view_model_contract.md)

## Scope

1. `_PerformanceCockpitCard`를 새 judgment header 구조로 대체한다.
2. 기간 selector를 header 상단에 배치한다.
3. primary metric을 `입출금 보정 기간 수익률`로 둔다.
4. 기간 수익률이 없으면 순 투자성과 fallback을 표시한다.
5. 순 투자성과와 매수 원금 대비 수익률을 secondary/supporting으로 배치한다.
6. benchmark comparison strip을 header 바로 아래에 배치한다.
7. 모든 spacing, radius, color, typography는 design token/context extension을 사용한다.

## Out Of Scope

- 성과 원인 breakdown 구현
- 총자산 검산 구현
- 월별/종목별/위험 영역 구현
- 새 benchmark 선택 기능
- view model 계약 변경
- 자체 디자인 문법 추가
- chart/waterfall 구현
- 신규 DB/API 도입

## Implementation Boundary

이 phase에서 바꿀 수 있는 영역:

| 대상 | 처리 |
| --- | --- |
| `_PerformanceCockpitCard` | 새 `_PerformanceJudgmentHeader`로 대체 |
| `_DateRangeSelector` | 유지하되 header 내부 상단으로 이동 |
| `_StatusPill` | 원금 대비/benchmark status badge로 재사용 가능 |
| `_MiniMetricGrid` | header supporting metric으로 축소하거나 제거 가능 |
| `_MarketAndRiskCard`의 benchmark 정보 | 이 phase에서는 benchmark strip에 필요한 표시만 이동 |
| `_MarketAndRiskCard`의 risk 정보 | 이 phase에서 구현하지 않음 |

이 phase에서 바꾸지 않는 영역:

| 대상 | 이유 |
| --- | --- |
| `_PerformanceAttributionCard` | Phase 4 담당 |
| `_CashFlowExclusionCard` | Phase 4 담당 |
| `_MonthlyTrendCard` | Phase 5 담당 |
| `_HoldingContributionCard` | Phase 5 담당 |
| risk metric tiles | Phase 5 담당 |

## Required View Model Inputs

이 phase는 02 계약의 아래 state만 사용한다.

```text
_InvestmentPerformanceViewModel
- range
- judgment
- benchmark
```

필수 state:

| State | Required field |
| --- | --- |
| `judgment.periodReturn` | `MetricValue<double>` |
| `judgment.pureInvestmentPerformance` | `double` |
| `judgment.principalReturn` | `MetricValue<double>` |
| `judgment.pureRealizedPerformance` | `double` |
| `judgment.unrealizedProfit` | `double` |
| `benchmark.label` | `String` |
| `benchmark.portfolioReturn` | `MetricValue<double>` |
| `benchmark.benchmarkReturn` | `MetricValue<double>` |
| `benchmark.excessReturn` | `MetricValue<double>` |

금지:

- widget에서 `report.advancedPerformance.periodReturn == null` 같은 raw nullable 판정을 직접 하지 않는다.
- widget에서 benchmark null 상태를 직접 해석하지 않는다.
- widget에서 매수 원금 0 여부를 직접 계산하지 않는다.

## Layout Contract

### 390dp First View

390dp 모바일에서 첫 화면은 아래 순서를 따른다.

```text
투자성과 분석

[1개월] [3개월] [6개월] [올해] [전체]

기간 수익률
+4.2%
입출금 영향을 제외한 성과

순 투자성과 +420,000원
원금 대비 +3.8%

참고 벤치마크
S&P 500 대비 +1.2%p
내 수익률 +4.2% · S&P 500 +3.0%
```

첫 화면에서 최소한 보여야 하는 정보:

1. 기간 selector
2. `기간 수익률` label
3. 기간 수익률 value 또는 데이터 부족 title
4. `순 투자성과` amount
5. `원금 대비` value 또는 데이터 부족 badge
6. `참고 벤치마크` section 시작과 비교 결과 첫 줄

### Section Structure

```text
_PerformanceJudgmentHeader
  _DateRangeSelector
  Primary metric block
  Secondary amount row/block
  Supporting metric chips/rows

_BenchmarkSnapshotStrip
  Title/caption
  Main comparison line
  Secondary return pair
  Optional helper/fallback text
```

`_BenchmarkSnapshotStrip`은 header와 같은 phase에서 구현하지만, 위험 지표는 포함하지 않는다.

## Copy Contract

01 계약의 문구를 그대로 사용한다.

### Judgment Header Copy

| Element | Text |
| --- | --- |
| primary label | `기간 수익률` |
| primary caption | `입출금 영향을 제외한 성과` |
| secondary label | `순 투자성과` |
| supporting label | `원금 대비` |
| helper | `기간 수익률은 일별 평가액과 입출금 보정 기준입니다.` |
| period fallback title | `기간 수익률 데이터 부족` |
| period fallback helper | `평가 데이터가 더 쌓이면 입출금 보정 수익률을 표시합니다.` |
| principal fallback | `원금 대비 데이터 부족` |

### Benchmark Strip Copy

| Element | Text |
| --- | --- |
| title | `참고 벤치마크` |
| comparison | `S&P 500 대비 {value}` |
| secondary pair | `내 수익률 {portfolioReturn} · S&P 500 {benchmarkReturn}` |
| helper | `S&P 500은 기본 참고 기준이며, 포트폴리오 구성과 다를 수 있습니다.` |
| fallback title | `참고 벤치마크 데이터 부족` |
| fallback helper | `참고 벤치마크 가격을 아직 확보하지 못했습니다.` |

금지 문구:

- `시장 비교`
- `시장 대비`
- `시장보다`
- `실제 수익률`
- `전체 수익률`

## State Rendering Contract

### Period Return

| State | UI |
| --- | --- |
| `available(value)` | signed percent as primary number |
| `unavailable(missingDailyReturns)` | `기간 수익률 데이터 부족` as primary text, helper below |
| other unavailable | generic `기간 수익률 데이터 부족`, reason-specific helper only if 01 copy exists |

Fallback rule:

- period return unavailable이어도 `순 투자성과`는 반드시 표시한다.
- unavailable state에서 순 투자성과를 primary로 승격할 수 있지만, label은 `순 투자성과`를 유지해 기간 수익률처럼 보이지 않게 한다.

### Principal Return

| State | UI |
| --- | --- |
| `available(value)` | `원금 대비 {value}` |
| `unavailable(zeroBasisAmount)` | `원금 대비 데이터 부족` |

### Benchmark

| State | UI |
| --- | --- |
| `excessReturn.available` | `S&P 500 대비 {excessReturn}` |
| `excessReturn.unavailable` + `benchmarkReturn.available` | `S&P 500 {benchmarkReturn}` |
| `benchmarkReturn.unavailable(missingBenchmarkPrices)` | `참고 벤치마크 데이터 부족` + fallback helper |
| `portfolioReturn.unavailable(missingDailyReturns)` | `평가 데이터가 더 쌓이면 비교할 수 있습니다.` |

Network/fetch failure boundary:

- 현재 02 계약상 fetch failure가 별도 state로 보존되지 않는다.
- 별도 state가 생기기 전까지는 `missingBenchmarkPrices`로만 표시한다.

## Design Contract

모든 디자인 요소는 기존 design md와 token을 따른다.

Required sources:

- `docs/design_system.md`
- `docs/features/simple_patches/design_md_full_compliance/component_contract.md`
- `docs/features/simple_patches/design_token_unification/plan.md`
- `lib/design_system/context_extensions.dart`
- `lib/design_system/spec/visual_spec.dart`
- `lib/widgets/moneyfy_ui.dart`

Allowed patterns:

| UI need | Use |
| --- | --- |
| Page shell | `MoneyfyPage` |
| Header/panel surface | `SectionCard` or existing panel contract |
| Chips | `_InvestmentChoiceChip`, `MoneyfyPillStyle`, `MoneyfyBadge` |
| Amount typography | `context.typography.heroNumber`, `context.typography.cardTitle` |
| Meta/caption | `context.typography.meta`, `context.typography.caption` |
| Positive/negative color | `context.colors.positiveOn`, `context.colors.negativeOn`, helper based on `_valueColor` |
| Spacing | `context.spacing`, `context.cardPadding()` |
| Radius | `context.radius`, `VisualSpec.surface` |

Hardcoding rule:

- No raw hex colors.
- No `Colors.*`.
- No new arbitrary `EdgeInsets`.
- No new arbitrary `BorderRadius.circular(...)` outside existing token access.
- No direct `FontWeight`.
- No new shadow/gradient/decorative surface.

Exception:

- Responsive threshold and scaleDown behavior may stay local if documented and verified in Phase 6.

## Implementation Steps

1. Add or derive `_InvestmentPerformanceViewModel` state required by `judgment` and `benchmark`.
2. Replace `_PerformanceCockpitCard` call site with `_PerformanceJudgmentHeader`.
3. Move `_DateRangeSelector` into the new header.
4. Render period return primary metric from `judgment.periodReturn`.
5. Render `순 투자성과` secondary amount from `judgment.pureInvestmentPerformance`.
6. Render `원금 대비` from `judgment.principalReturn`.
7. Add `_BenchmarkSnapshotStrip` directly below header.
8. Remove benchmark status pill from old cockpit once strip exists.
9. Keep risk grid untouched until Phase 5, except benchmark duplication may be removed only if strip covers the same information.

## Tests Required In This Phase

| Test | Expectation |
| --- | --- |
| header shows available period return | `기간 수익률` and signed percent visible |
| header shows period fallback | `기간 수익률 데이터 부족` visible, 순 투자성과 still visible |
| principal return zero basis | `원금 대비 데이터 부족` visible |
| benchmark excess return available | `S&P 500 대비` visible |
| benchmark missing prices | `참고 벤치마크 데이터 부족` visible |
| benchmark missing daily returns | `평가 데이터가 더 쌓이면 비교할 수 있습니다.` visible |
| old market wording removed | `시장 대비`, `시장 비교`, `시장보다` absent from new header/strip |

Visual checks:

- 360dp, text scale 1.0
- 390dp, text scale 1.0
- 430dp, text scale 1.0
- 390dp, text scale 1.3

## Completion Gate

- [x] 첫 화면에서 기간 selector, 기간 수익률, 순 투자성과, benchmark strip이 보인다.
- [x] period return 있음/없음 상태가 모두 깨지지 않는다.
- [x] 매수 원금 0일 때 원금 대비 수익률이 잘못 표시되지 않는다.
- [x] 360/390/430dp에서 header 텍스트 overflow가 없다.
- [x] text scale 1.3에서 chip과 금액 영역이 겹치지 않는다.
- [x] 하드코딩 색상/spacing/radius/typography가 추가되지 않았다.
- [x] benchmark fetch 실패가 전체 페이지 실패로 전파되지 않는다.

## Completion Meaning

위 체크박스는 이 문서의 계획 기준이 충족되었음을 뜻한다. 실제 구현 phase에서는 동일 항목을 테스트/QA로 다시 검증해야 한다.

## Stop Rule

header 완료 후 곧바로 성과 원인이나 하단 섹션을 만들지 않는다. Phase 4 문서의 Completion Gate를 별도로 시작한다.

