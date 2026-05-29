# Schema And Sync

## New Columns

Local Drift and Supabase:

- `holdings.average_price_source real not null default 0`
- `holdings.average_price_krw real not null default 0`
- `holdings.average_purchase_fx_rate real not null default 1`
- `holdings.cost_basis_krw real not null default 0`
- `transaction_lines.cost_basis_source_delta real not null default 0`

Existing column retained:

- `holdings.average_price`
  - Do not remove.
  - Do not redefine to source-currency average.
  - Keep it equal to `average_price_krw` for compatibility.

## Local Migration

- Bump Drift `schemaVersion`.
- Add migration helpers for all new columns.
- Backfill KRW holdings:
  - `average_price_source = average_price`
  - `average_price_krw = average_price`
  - `average_purchase_fx_rate = 1`
  - `cost_basis_krw = quantity * average_price`
- Backfill USD holdings:
  - Use seed values where available.
  - Do not infer source average from latest/current exchange rate.
  - If seed is absent, set source average and average FX to `0`.

## Transaction Line Backfill

- KRW row: `cost_basis_source_delta = cost_basis_delta`
- USD buy row: `cost_basis_source_delta = gross_amount` only when `gross_amount` is confirmed source-currency USD trade amount
- USD opening/snapshot_restore row with seed: `cost_basis_source_delta = quantity_delta * seeded average_price_source`
- USD opening/snapshot_restore row without seed: do not infer from `gross_amount`
- USD snapshot-anchor sell row: corrected `-(average_cost_source * quantity_sold)`
- USD manual sell row: `-(gross_amount - realized_pnl)` when manual realized PnL is source-currency input
- Uncertain USD row: do not guess; leave for anomaly/review handling

## Sync

Update dirty payload and remote pull payload for:

- `holdings.average_price_source`
- `holdings.average_price_krw`
- `holdings.average_purchase_fx_rate`
- `holdings.cost_basis_krw`
- `transaction_lines.cost_basis_source_delta`

Edge functions:

- `sync-local-db`
- `get-sync-local-db`

Backward compatibility:

- 구버전 클라이언트가 신규 컬럼 없이 sync하더라도 서버의 기존 신규 컬럼 값이 `0` 또는 null로 덮이지 않게 absent-field preserve 정책을 둔다.
