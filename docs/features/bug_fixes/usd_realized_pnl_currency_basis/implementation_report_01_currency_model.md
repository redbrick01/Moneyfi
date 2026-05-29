# Implementation Report 01 - Currency Model

## Scope

Implemented the currency-basis storage foundation from `plan_parts/01_currency_model.md`.

This step adds explicit KRW and source-currency cost-basis fields without changing the meaning of the existing `holdings.average_price` compatibility column.

## Implemented

- Local Drift schema version bumped to `34`.
- Added local holding columns:
  - `average_price_source`
  - `average_price_krw`
  - `average_purchase_fx_rate`
  - `cost_basis_krw`
- Added local ledger column:
  - `transaction_lines.cost_basis_source_delta`
- Added local migration helpers:
  - KRW holdings backfill source average from `average_price`.
  - USD holdings keep unknown source average and average FX at `0` until seeded.
  - Existing `average_price` remains KRW compatibility average.
  - KRW transaction lines backfill `cost_basis_source_delta = cost_basis_delta`.
  - USD transaction lines are not inferred from KRW cost data.
- Updated sync payload creation and restore for the new fields.
- Updated Edge Functions:
  - `sync-local-db`
  - `get-sync-local-db`
- Added Supabase migration:
  - `supabase/migrations/20260529014240_add_currency_basis_columns.sql`
- Added regression test:
  - verifies KRW/USD initial currency-basis values
  - verifies new fields are included in dirty sync payload
  - verifies values survive local sync restore

## Safety Decisions

- Existing USD `average_price` is treated as KRW average cost.
- USD `average_price_source` is not inferred from latest exchange rate, current price, or snapshot exchange rate.
- USD `average_purchase_fx_rate` remains `0` when source average is unknown.
- This implementation does not run the corrective remote data migration and does not update existing remote holdings quantities.
- Do not apply the remote seed migration until the sync preserve behavior from report 03 is deployed; otherwise stale clients may push `0` currency-basis values back over seeded server values.

## Verification

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test test/transaction_flow_test.dart`

All verification commands passed.

## Remaining Work

- Seed existing USD source averages and weighted purchase FX values.
- Update buy/sell calculation flow so USD buys record trade FX and recompute weighted average FX.
- Correct affected historical USD sell realized PnL rows with archived rollback data.
- Follow `operational_runbook.md` for the remote deployment order.
