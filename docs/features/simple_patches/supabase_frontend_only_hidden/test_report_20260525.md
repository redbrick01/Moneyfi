# Supabase Frontend-Only Hidden State Test Report 2026-05-25

## Summary

Supabase no longer owns asset, holding, or cash-account hidden state. Remote schema migration drops the hidden columns, Edge Functions stop reading or writing hidden values, and Flutter sync payloads no longer send local hidden state.

## Commands Run

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
deno check supabase/functions/create-portfolio-snapshot/index.ts supabase/functions/sync-local-db/index.ts supabase/functions/get-sync-local-db/index.ts supabase/functions/update-holding-prices/index.ts supabase/functions/fetch-company-news/index.ts supabase/functions/get-user-company-news-summaries/index.ts
rg -n "hidden" supabase/functions supabase/migrations
supabase migration list
supabase db push
supabase functions deploy create-portfolio-snapshot fetch-company-news get-sync-local-db get-user-company-news-summaries sync-local-db update-holding-prices --use-api --jobs 1
supabase functions list
supabase db diff --from migrations --to linked --schema public
supabase db query --linked "select table_name, column_name from information_schema.columns where table_schema = 'public' and table_name in ('assets','holdings','cash_accounts') and column_name = 'hidden' order by table_name"
```

## Command Results

- `flutter test test/transaction_flow_test.dart`: passed, 47 tests.
- `flutter analyze`: passed with no issues.
- `deno check ...`: passed for all touched Edge Functions.
- `rg -n "hidden" supabase/functions supabase/migrations`: only the new migration's `DROP COLUMN IF EXISTS hidden` statements remain in active Supabase paths.
- `supabase migration list`: confirmed remote includes `20260524195600` and `20260525090000` after push.
- `supabase db push`: applied `20260524195600_add_sync_last_modified_conflict_columns.sql` and `20260525090000_remove_remote_hidden_state.sql`.
- `supabase functions deploy ...`: deployed the six touched Edge Functions successfully.
- `supabase functions list`: confirmed all functions are `ACTIVE`; touched functions were updated at `2026-05-25 03:13:55 UTC`.
- `supabase db diff --from migrations --to linked --schema public`: did not complete because the local shadow replay hit an existing migration temp-table issue in `20260522153000_rebuild_snapshot_restore_ledger_lines.sql` (`latest_restore_snapshots` already exists). This is a diff-tool replay issue, not a failed remote apply.
- `supabase db query --linked ... hidden ...`: returned no rows, confirming the remote `assets`, `holdings`, and `cash_accounts` tables no longer have `hidden` columns.

## Compatibility Result

- Local Drift hidden columns and frontend hidden controls remain intact.
- Hidden-only local toggles no longer mark asset, holding, or cash-account rows dirty for remote sync.
- Remote sync continues to carry durable asset, holding, cash-account, and ledger fields without hidden values.
- Incoming remote payloads without hidden values preserve existing local hidden state by `client_id`; new rows default to visible.

## Manual QA Status

Executed:

- Remote migration apply was run against linked project `oeweumxfabobwlhzrzqk`.
- Edge Function deployment was run for the six touched functions.

Not executed:

- End-to-end app login/sync smoke test against a real user session was not run.

## Risk Assessment

- Existing remote hidden values are intentionally dropped by migration and cannot be restored without a rollback migration.
- Server-created snapshots now include all non-deleted remote rows because hidden state is no longer available on Supabase.
- Multi-device hidden preference sync is intentionally removed; hidden preferences are frontend-local.

## Follow-Up Recommendations

- If local hidden preferences need backup/export later, add a frontend-local export path rather than reintroducing Supabase hidden columns.
- Update any product copy that implies hidden state syncs across devices.

## Final Result

Pass. The patch satisfies the frontend-only hidden state contract for Supabase schema, Edge Functions, and Flutter outbound sync.
