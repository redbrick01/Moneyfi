# Implementation Report 02: Derived Daily Returns

## Scope

Daily return data is stored as an analysis-derived dataset. It is rebuilt from snapshots and transaction records, and it is not a source of truth for portfolio holdings.

## Derived Data

- `portfolio_daily_returns` stores daily portfolio value, external cash flow, daily return, and data quality.
- Snapshot gaps produce 데이터 부족 rows instead of invented returns.
- Recalculation failure must not block the existing investment performance screen.

## Safety

The derived table can be deleted and rebuilt. Core tables remain unchanged during generation.
