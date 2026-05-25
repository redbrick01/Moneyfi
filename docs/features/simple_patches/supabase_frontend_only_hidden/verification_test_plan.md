# Supabase Frontend-Only Hidden State Verification Test Plan

## Automated Checks

1. `flutter test test/transaction_flow_test.dart`
   - Confirms ledger/sync regression coverage still passes.
   - Includes a targeted assertion that dirty sync payload rows omit `hidden` for assets, holdings, and cash accounts.

2. `flutter analyze`
   - Confirms Dart changes compile and static analysis remains clean.

3. `git diff --check`
   - Confirms no whitespace or patch formatting issues.

## Static Inspection

Run:

```bash
rg -n "hidden" supabase/functions supabase/migrations
```

Expected result:

- No active Supabase migration or Edge Function references remote table `hidden` columns.
- References in archived migrations are acceptable because archives are not active schema changes.

## Manual QA

Not executed in this patch unless a local Supabase stack is available:

- Apply migrations to a disposable Supabase database and confirm `assets`, `holdings`, and `cash_accounts` no longer have `hidden`.
- Deploy or type-check Edge Functions in a Deno environment and confirm no function selects or writes missing hidden columns.

## Acceptance Criteria

- Supabase schema removes hidden columns from asset, holding, and cash-account tables.
- Edge Functions neither select nor mutate hidden fields.
- Flutter outbound sync payload does not include hidden state.
- Frontend local hidden controls remain backed by local Drift fields.
