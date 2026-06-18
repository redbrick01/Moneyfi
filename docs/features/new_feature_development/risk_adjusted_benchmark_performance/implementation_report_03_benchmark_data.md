# Implementation Report 03: Benchmark Data

## Scope

Benchmark comparison uses separate benchmark price rows so portfolio performance can be compared with market references without changing user assets.

## Benchmark Rules

- `benchmark_prices` stores benchmark code, date, close price, adjusted close price, currency, and optional FX rate.
- Missing benchmark rows are displayed as 데이터 부족 rather than a failed screen.
- Benchmark return is calculated from the matching period boundaries when sufficient data exists.

## Safety

Benchmark data is read-only for authenticated clients. It does not update user portfolio records.
