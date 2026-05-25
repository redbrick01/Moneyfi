# Supabase Frontend-Only Hidden State Plan

## Patch Goal

Remove hidden-state ownership from Supabase. Asset, holding, and cash account hidden flags must remain a frontend-local concern and must not be stored, selected, filtered, or mutated by the remote Supabase schema or Edge Functions.

## Current Baseline

- Local Drift tables keep `hidden` columns and UI uses them for portfolio display, ordering, snapshots, and local calculations.
- Supabase remote tables `assets`, `holdings`, and `cash_accounts` currently include `hidden boolean` columns in the baseline schema.
- Sync Edge Functions send and receive `hidden`, so local visibility can leak into the remote database.
- Snapshot, price update, and company-news functions filter or skip rows using remote `hidden`.

## Non-Goals

- Do not remove local Drift `hidden` columns or frontend UI controls.
- Do not change delete semantics, dirty-row conflict policy, or ledger table contracts.
- Do not rebuild the full local database schema or regenerate unrelated generated files.
- Do not alter archived legacy migrations.

## Files/Modules Affected

- `supabase/migrations`: add a forward migration that drops remote hidden columns and updates remote metric calculation.
- `supabase/migrations/20260521043000_baseline_remote_schema.sql`: keep the repo baseline aligned for fresh remote schema creation.
- `supabase/migrations/20260522151500_restore_state_from_latest_snapshots.sql`: remove hidden writes from snapshot restore SQL.
- `supabase/functions/sync-local-db/index.ts`: stop accepting hidden fields into remote upserts.
- `supabase/functions/get-sync-local-db/index.ts`: stop returning hidden fields to clients.
- `supabase/functions/create-portfolio-snapshot/index.ts`: stop selecting or filtering hidden fields remotely.
- `supabase/functions/update-holding-prices/index.ts`: stop using hidden as a remote price-update exclusion.
- `supabase/functions/fetch-company-news/index.ts` and `get-user-company-news-summaries`: stop filtering by remote hidden.
- `lib/db/app_database.dart`: stop including local hidden values in outbound sync payloads and preserve local defaults when remote payload omits them.
- `test/transaction_flow_test.dart`: pin sync payload behavior so hidden is not sent to Supabase.

## Compatibility Promise

- Frontend hidden behavior remains local and functional.
- Remote sync continues to move durable asset, holding, cash, and ledger data.
- Existing clients receiving remote payloads without `hidden` default local hidden state to visible unless the user changes it locally.
- Existing remote databases can apply the new migration without depending on a full reset.

## Test Plan

- Add/adjust a targeted sync payload test in `test/transaction_flow_test.dart` so asset, holding, and cash-account payload rows do not include `hidden`.
- Run `flutter test test/transaction_flow_test.dart`.
- Run `flutter analyze`.
- Run `git diff --check`.
- Inspect Supabase functions and migrations with `rg -n "hidden" supabase/functions supabase/migrations`.

## Risks And Rollback Notes

- Dropping remote columns is irreversible for existing remote hidden values; this is intentional because hidden state must be frontend-only.
- Server-created portfolio snapshots can no longer know local hidden choices. They will include all non-deleted remote rows because Supabase no longer owns hidden state.
- Rollback requires a migration that re-adds the dropped columns and redeploys the previous Edge Function behavior.

## Follow-Up Candidates

- Consider a local-only backup/export path for hidden preferences if multi-device local visibility persistence becomes required later.
- Update broader data/sync docs after the code patch lands so documentation no longer describes remote hidden filtering.
