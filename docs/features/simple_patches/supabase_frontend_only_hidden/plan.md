# Supabase Frontend-Only Hidden State Plan

## Patch Goal

Remove hidden-state ownership from Supabase. Asset, holding, cash account hidden flags stay frontend-local only. Remote Supabase schema or Edge Functions must not store, select, filter, mutate them.

## Current Baseline

- Local Drift tables keep `hidden`; UI uses for portfolio display, ordering, snapshots, local calcs.
- Supabase remote tables `assets`, `holdings`, `cash_accounts` include `hidden boolean` in baseline schema.
- Sync Edge Functions send/receive `hidden`; local visibility can leak remote.
- Snapshot, price update, company-news functions filter/skip rows via remote `hidden`.

## Non-Goals

- Do not remove local Drift `hidden` columns or frontend UI controls.
- Do not change delete semantics, dirty-row conflict policy, or ledger table contracts.
- Do not rebuild full local database schema or regen unrelated generated files.
- Do not alter archived legacy migrations.

## Files/Modules Affected

- `supabase/migrations`: add forward migration dropping remote hidden columns + updating remote metric calc.
- `supabase/migrations/20260521043000_baseline_remote_schema.sql`: align repo baseline for fresh remote schema.
- `supabase/migrations/20260522151500_restore_state_from_latest_snapshots.sql`: remove hidden writes from snapshot restore SQL.
- `supabase/functions/sync-local-db/index.ts`: stop accepting hidden fields into remote upserts.
- `supabase/functions/get-sync-local-db/index.ts`: stop returning hidden fields to clients.
- `supabase/functions/create-portfolio-snapshot/index.ts`: stop selecting/filtering hidden remotely.
- `supabase/functions/update-holding-prices/index.ts`: stop using hidden as remote price-update exclusion.
- `supabase/functions/fetch-company-news/index.ts` and `get-user-company-news-summaries`: stop filtering by remote hidden.
- `lib/db/app_database.dart`: stop sending local hidden values in outbound sync payloads; preserve local defaults when remote payload omits them.
- `test/transaction_flow_test.dart`: pin sync payload behavior so hidden not sent to Supabase.

## Compatibility Promise

- Frontend hidden behavior stays local + working.
- Remote sync still moves durable asset, holding, cash, ledger data.
- Existing clients receiving remote payloads without `hidden` default local hidden state visible unless user changes locally.
- Existing remote DBs can apply new migration without full reset.

## Test Plan

- Add/adjust targeted sync payload test in `test/transaction_flow_test.dart` so asset, holding, cash-account payload rows omit `hidden`.
- Run `flutter test test/transaction_flow_test.dart`.
- Run `flutter analyze`.
- Run `git diff --check`.
- Inspect Supabase functions and migrations with `rg -n "hidden" supabase/functions supabase/migrations`.

## Risks And Rollback Notes

- Dropping remote columns irreversible for existing remote hidden values; intentional because hidden state frontend-only.
- Server-created portfolio snapshots cannot know local hidden choices. They include all non-deleted remote rows because Supabase no longer owns hidden state.
- Rollback needs migration re-adding dropped columns + redeploy previous Edge Function behavior.

## Follow-Up Candidates

- Consider local-only backup/export path for hidden prefs if multi-device local visibility persistence needed later.
- Update broader data/sync docs after code patch lands so docs stop describing remote hidden filtering.