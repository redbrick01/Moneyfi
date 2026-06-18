# Implementation Report 01: Calculation Contract

## Scope

Risk-adjusted performance calculations use derived daily portfolio values only. The contract keeps investment performance separate from cash movement so deposits and withdrawals are not treated as return.

## Calculation Rules

- Daily return is calculated from beginning value, ending value, and external cash flow.
- Cumulative return is compounded from valid daily return rows.
- Volatility is based on the daily return series.
- Sharpe Ratio uses excess return over the configured risk-free rate proxy.
- Max drawdown is calculated from the cumulative value curve.
- Rows marked as data 부족 are excluded from metrics that require continuous daily return data.

## Safety

This stage does not write to `assets`, `holdings`, `transaction_events`, or `transaction_lines`.
