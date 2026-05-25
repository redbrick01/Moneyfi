# Transaction Record Only Calculation And Supabase Start Verification Plan

## Automated Regression

1. Run `flutter test test/transaction_flow_test.dart`.
   - Confirms transaction add/edit/delete, cash transfer, cash exchange, normalized ledger, dirty sync payload, soft delete, and record-only behavior.
   - Expected result: pass.

2. Run `flutter test`.
   - Confirms full unit/widget smoke coverage.
   - Expected result: pass.

3. Run `flutter analyze`.
   - Confirms static analysis stays clean.
   - Expected result: pass.

4. Run `./gradlew :app:compileDebugKotlin` from `android/`.
   - Confirms Android compile path is still valid.
   - Expected result: pass.

5. Run `deno check supabase/functions/sync-local-db/index.ts supabase/functions/get-sync-local-db/index.ts`.
   - Confirms sync Edge Functions still type-check.
   - Expected result: pass.

6. Run `supabase start`.
   - Confirms local migrations apply and the local Supabase stack can start.
   - Expected result: pass, unless Docker image download or local Docker state fails outside repository control.

## Record-Only Calculation Checks

- Create a record-only investment buy.
  - Transaction list/detail must show the row.
  - `includeInCalculations` must read as `false`.
  - Holding quantity must remain unchanged.
  - Settlement cash balance must remain unchanged.
  - Holding performance `buyAmount` must include the row.
  - Portfolio performance `buyAmount` must include the row.
  - Currency performance must include the row.
  - Performance event drill-down must include the row.

- Create a record-only cash deposit.
  - Transaction list/detail must show the row.
  - Cash balance must remain unchanged.
  - Portfolio performance external deposit/cash flow may include the row for analysis, while current cash balance must remain unchanged.

## Supabase Local DB Checks

When `supabase start` succeeds:

- Confirm migrations apply without `latest_restore_snapshots` relation errors.
- Confirm `sync-local-db` and `get-sync-local-db` type-check.
- Optional manual DB check:
  - Insert or sync a dirty record-only event.
  - Query `transaction_events.source` and verify it is `record_only`.
  - Pull data back into local Drift DB and verify `includeInCalculations == false`.

## Manual QA

- In the app, create a calculation-excluded buy/deposit.
- Confirm the transaction remains visible in the 거래 list with record-only labeling.
- Confirm current holdings/cash values do not change.
- Confirm analysis/statistics can still use the transaction as historical input.
- Edit excluded to included and confirm values are added.
- Edit included to excluded and confirm values are removed.
