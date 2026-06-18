# Release Gate 06: Risk-Adjusted Performance Remote Apply

## Remote Apply Result

Supabase 원격 적용은 2026-05-29에 완료.

Applied scope was limited to analysis-derived structures for risk-adjusted performance:

- `portfolio_daily_returns`
- `benchmark_prices`

## Source Table Safety Checks

The release gate checked that source portfolio tables stayed stable:

- `assets`
- `holdings`

Validation focused on 수량 합계, 매수원금 합계, and zero 분포 before and after the remote apply.

## Data Quality Checks

The rollout accepts 데이터 부족 states for periods without enough daily return or benchmark data. Missing derived rows must be shown as insufficient data, not as a failed investment performance page.

## Destructive Write Guard

No destructive source-table operation is part of this gate. Any future remote apply must repeat the same preflight and document the result before release.
