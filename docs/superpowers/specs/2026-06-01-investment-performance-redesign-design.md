# Investment Performance Redesign Design

## Context

The `InvestmentPerformancePage` currently presents a full performance report with a judgment header, attribution, reconciliation, monthly performance, holding contribution, risk interpretation, and data basis sections. The redesign keeps the existing calculation foundation but changes the page's information architecture.

The approved direction is a judgment-summary page with a performance scoreboard. The primary user goal is to decide quickly whether the selected period's investment performance is good or bad.

## Goals

- Make the selected period's investment result immediately scannable.
- Put net investment performance, return rate, benchmark delta, and risk state in the first viewport.
- Reframe lower sections as evidence for the top-level judgment.
- Preserve existing period selection, benchmark comparison, holding filtering, sorting, risk, and data-basis behavior.
- Avoid hiding calculation gaps or partial failures behind a confident summary.

## Non-Goals

- Replacing the ledger, snapshot, benchmark, or risk calculation systems.
- Adding buy, sell, rebalance, or asset-allocation recommendations.
- Redesigning unrelated Analysis tab cards.
- Changing the definition of investment performance.

## Information Architecture

The page should read in this order:

1. **Scoreboard judgment**
   - Net investment performance.
   - Return rate.
   - Benchmark delta.
   - Risk state.
   - A concise judgment label such as good, neutral, caution, or unavailable.

2. **Comparison evidence**
   - Benchmark comparison.
   - Previous-period comparison when available.
   - Risk-free or cash-like reference when available.

3. **Performance composition**
   - Realized PnL.
   - Unrealized PnL.
   - Dividend and interest income.
   - Fees and taxes.

4. **Time signals**
   - Monthly performance trend.
   - Notable positive or negative periods.

5. **Holding impact**
   - Top and bottom contributors.
   - Existing holding filter and sort modes.

6. **Risk and confidence**
   - Volatility, drawdown, Sharpe-like metrics when available.
   - Data basis, missing inputs, unavailable calculations, and benchmark date basis.

## Component Design

### `PerformanceScoreboardHeader`

New top-level header component. It replaces the current report-like first impression with a dense scoreboard.

It shows:

- Selected period controls.
- Net investment performance.
- Return rate.
- Benchmark delta.
- Risk state.
- Judgment label.
- Primary reason for the judgment.

The header should remain compact on mobile. Values may wrap, but labels and numbers must not overlap.

### `BenchmarkComparisonCard`

Shows whether performance beat or lagged the selected benchmark and optional reference points. Benchmark fetch failures should affect this card and the scoreboard's comparison slot, not the whole page.

### `PerformanceCompositionCard`

Reworks the existing attribution section into a clearer explanation of what produced the score:

- Realized PnL.
- Unrealized PnL.
- Dividend and interest.
- Fees and taxes.
- Expense impact.

### `MonthlySignalCard`

Keeps the monthly trend behavior but frames it as evidence for the judgment. It should highlight the strongest positive and negative months when data exists.

### `HoldingImpactCard`

Keeps existing holding contribution filtering and sorting. It should emphasize the top contributors, bottom contributors, and cases where total performance is zero or negative.

### `RiskSignalCard`

Keeps risk-adjusted metrics while making availability clear. If daily returns or the selected period are insufficient, show the unavailable reason rather than a misleading zero.

### `DataConfidenceCard`

Shows the calculation basis and missing-data warnings. This card is part of the judgment flow, not a footnote hidden at the end.

## Data Flow

Use the existing pipeline:

`Ledger/Snapshot data -> report loader -> _InvestmentPerformanceViewModel -> UI cards`

The redesign should add judgment-oriented display fields to the view model rather than replacing the underlying report calculation.

Suggested display fields:

- `performanceStatus`: good, neutral, caution, or unavailable.
- `benchmarkDeltaStatus`: outperforming, similar, lagging, or unavailable.
- `riskStatus`: low, normal, elevated, or unavailable.
- `headlineReason`: the main reason shown under the scoreboard judgment.
- `unavailableReasons`: calculation gaps grouped by card or metric.

## Calculation Principles

- Deposits, withdrawals, transfers, and FX movement should not be mixed directly into investment performance.
- Net investment performance remains based on realized PnL, unrealized PnL, dividends, interest, fees, and taxes.
- Settlement cash flow can explain trading scale but should not be added directly to net investment performance.
- Benchmark comparison must display the selected benchmark and date basis when available.
- If a metric is unavailable, the UI should state why instead of substituting zero.

## State And Error Handling

### Loading

Show a scoreboard skeleton first, then card-level placeholders. Avoid layout shift between loading and loaded states.

### Empty Data

Explain that transactions, holdings, or snapshots are needed before a performance judgment can be made. Show the next relevant path instead of an empty report.

### Partial Data

Show available metrics and disable only the missing ones. The scoreboard should be able to show performance while marking benchmark or risk as unavailable.

### Benchmark Failure

Show investment performance normally. Mark benchmark delta as unavailable and explain that benchmark prices could not be confirmed.

### Risk Calculation Unavailable

Show the reason, such as insufficient daily returns or too short a selected period.

### Zero Or Negative Performance

Avoid misleading contribution percentages when the total basis is zero or negative. Prefer absolute amounts and clear labels.

## Testing

### Unit Or Presenter Tests

- Judgment status mapping for positive, neutral, negative, and unavailable cases.
- Benchmark delta status for outperforming, similar, lagging, and unavailable cases.
- Risk status and unavailable reason mapping.
- Contribution behavior when total performance is zero or negative.
- Headline reason priority when multiple signals are present.

### Widget Or Smoke Tests

- Scoreboard renders net performance, return rate, benchmark delta, and risk state.
- Loading, empty, and partial-failure states render without crashing.
- Existing holding filter and sort controls still work.
- Mobile-width layout does not overlap text or controls.

## Implementation Notes

- Keep edits scoped to `lib/pages/investment_performance_page.dart` unless extraction becomes necessary to keep the file understandable.
- Reuse existing Moneyfy UI primitives and spacing tokens.
- Avoid adding new design tokens unless current tokens cannot express the layout.
- Keep Analysis tab navigation unchanged unless the entry card needs copy updates after the redesign.
