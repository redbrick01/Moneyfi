# Implementation Report 03 - Schema And Sync

## Scope

Completed the schema and sync layer from `plan_parts/03_schema_and_sync.md`.

Most schema fields were introduced during the 01 currency-model implementation. This step finishes the sync safety contract, especially protecting seeded USD currency-basis values from stale local clients.

## Implemented

- Confirmed local Drift schema fields are present:
  - `holdings.average_price_source`
  - `holdings.average_price_krw`
  - `holdings.average_purchase_fx_rate`
  - `holdings.cost_basis_krw`
  - `transaction_lines.cost_basis_source_delta`
- Confirmed Supabase migration exists:
  - `supabase/migrations/20260529014240_add_currency_basis_columns.sql`
- Confirmed pull payload includes new fields:
  - `supabase/functions/get-sync-local-db/index.ts`
- Confirmed dirty push payload includes new fields:
  - `lib/db/app_database.dart`
  - `supabase/functions/sync-local-db/index.ts`
- Added sync preserve policy in `sync-local-db`:
  - Preloads current server holding currency-basis fields by `client_id`.
  - For USD holdings, preserves positive server values when incoming values are absent, null, invalid, or `<= 0`.
  - Preserved fields:
    - `average_price_source`
    - `average_price_krw`
    - `average_purchase_fx_rate`
    - `cost_basis_krw`
  - Adds `preserved_rows` to the sync response for observability.
- Added contract test:
  - `test/sync_currency_basis_contract_test.dart`

## Safety Decisions

- Existing `holdings.average_price` remains the compatibility KRW average.
- The sync preserve policy is limited to holdings and only protects positive server currency-basis values.
- The preserve policy does not infer source averages from FX, current price, or snapshots.
- The preserve policy is defensive against stale clients that send `0` for fields they do not understand yet.
- If a positive server currency-basis value is wrong, the preserve policy may keep protecting it from client-side overwrite. Correct bad positive values with an explicit admin/corrective migration, not by relying on ordinary sync.
- This step does not run remote migrations or mutate remote data.

## Supabase Changelog Check

Checked on 2026-05-29. The April 28, 2026 Supabase Data API exposure change affects newly created public tables and explicit grants. This step only modifies existing exposed tables and Edge Function code, so no new public-table grant is required. Re-check Supabase release notes before deploying if the rollout date moves materially.

## Verification

- `flutter analyze test/sync_currency_basis_contract_test.dart`
- `flutter test test/sync_currency_basis_contract_test.dart`
- `git diff --check`

All verification commands passed.

## Remaining Work

- Implement USD buy/sell calculation flow so new USD buys store trade FX and recompute weighted average FX.
- Correct historical USD sell rows after the seed and sync-preserve migrations are deployed in order.
- Deploy this sync preserve behavior before applying the 02 seed migration.
