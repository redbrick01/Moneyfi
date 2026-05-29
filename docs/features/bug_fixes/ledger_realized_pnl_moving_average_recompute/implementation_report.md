# Ledger Realized PnL Moving Average Recompute Implementation Report

## Summary

실현손익 보정 방향을 전체 거래 이력 재생에서 스냅샷 anchor 기반 보정으로 변경했다. 사용자가 과거 모든 매수/매도 거래를 입력했다고 가정하지 않고, 매도 이전 최신 스냅샷 holding row가 안전하게 매칭되는 경우에만 원격 migration이 자동 보정한다.

스냅샷 anchor가 없거나, holding 매칭이 불확실하거나, anchor 이후 oversell이 감지되는 경우는 자동 보정하지 않는다. 신규/수정 매도 거래에서는 사용자가 실현손익을 직접 입력할 수 있게 하고, 직접 입력된 값은 `manual` source로 저장해 이후 자동 보정에서 제외한다.

## Implemented Changes

### Remote Migration

Added:

- `supabase/migrations/20260529100000_recompute_ledger_realized_pnl_from_moving_average.sql`

Key behavior:

- Adds `transaction_lines.realized_pnl_source text not null default 'auto'`.
- Finds the latest snapshot with `snapshot_date < sell.occurred_at`.
- Matches snapshot holding rows by `holding_client_id` first, then same-user `holding_id` only when `holding_client_id` is null.
- Computes anchor average cost as `total_purchase_amount / quantity`.
- Replays only `buy` and `sell` rows after that snapshot within the same anchor segment.
- Skips rows where `realized_pnl_source = 'manual'`.
- Marks recomputed sell rows as `realized_pnl_source = 'snapshot_anchor'`.
- Stops automatic recomputation for a segment after an unsafe sell/oversell condition.
- Recalculates `holdings.quantity` and `holdings.average_price` while keeping `snapshot_restore` included in current state and excluding only `history_display`, `record_only`.
- Updates both `updated_at` and `last_modified_at` for changed remote rows.

### Local Schema And Sync

Updated local Drift schema:

- `transaction_lines.realized_pnl_source`
- `schemaVersion` bumped from `32` to `33`.
- Local migration helper ensures the column exists on upgrade.
- Generated Drift code was rebuilt.

Updated sync payloads:

- `buildDirtySyncPayload()` now sends `realized_pnl_source`.
- Remote pull sync reads `realized_pnl_source`.
- Supabase `sync-local-db` accepts `realized_pnl_source`.
- Supabase `get-sync-local-db` returns `realized_pnl_source`.

### App Save Flow

Updated sell transaction handling:

- `createTransaction()` accepts `manualRealizedProfitAmount`.
- `_normalizedTransactionValues()` uses manual realized profit only for sell rows.
- Manual sell rows store:
  - `realized_pnl = manualRealizedProfitAmount`
  - `realized_pnl_source = 'manual'`
  - `cost_basis_delta = -(gross_amount - realized_pnl)`
- Auto rows keep `realized_pnl_source = 'auto'`.

Updated transaction model:

- `TransactionItem.realizedProfitSource`.

Updated transaction form:

- Sell transactions show an `자동 계산` / `직접 입력` choice.
- `직접 입력` reveals a signed decimal `실현손익 금액` field.
- Existing manual sell rows reopen in manual mode with the stored value.
- Editing a manual sell preserves the manual value/source unless the user switches back to automatic mode.

## Tests

Added:

- `manual sell realized profit is stored as manual ledger source`

This verifies:

- Manual realized profit is surfaced on the fetched transaction.
- `transaction_lines.realized_pnl_source = 'manual'`.
- `cost_basis_delta = -(gross_amount - realized_pnl)`.

Executed:

```bash
flutter analyze
flutter test test/transaction_flow_test.dart
git diff --check
```

Results:

- `flutter analyze`: passed
- `flutter test test/transaction_flow_test.dart`: passed, 60 tests
- `git diff --check`: passed

## Remote Application

Applied to linked Supabase project:

- Project: `Moneyfi`
- Ref: `oeweumxfabobwlhzrzqk`
- Migration: `20260529100000_recompute_ledger_realized_pnl_from_moving_average`

Application notes:

- The migration SQL was applied with `supabase db query --linked --file`.
- The migration was recorded in `supabase_migrations.schema_migrations`.
- `supabase migration list --linked` confirmed `20260529100000` exists on both local and remote.
- Verification query after migration reported:
  - `snapshot_anchor_count = 5`
  - `auto_count = 193`
  - `manual_count = 0`

Deployed Edge Functions:

- `sync-local-db`
- `get-sync-local-db`

Functions were deployed to project `oeweumxfabobwlhzrzqk` so `realized_pnl_source` is included in push/pull sync.

Operational note:

- Local migrations `20260528090000` and `20260528093000` are still not applied remotely. They were intentionally not pushed because they are unrelated Reddit mirror migrations.
- Remote migrations `20260528001841` and `20260528005339` exist remotely but are not present locally.

## Important Policy Decisions

- Same-day snapshots are not used as automatic anchors because they may reflect post-trade state.
- Snapshot anchor matching does not fall back to symbol/name matching, because that could silently attach a sell to the wrong holding.
- Oversell rows are not partially auto-corrected. They require user/manual correction.
- Manual realized PnL is protected from snapshot-anchor migration by `realized_pnl_source = 'manual'`.

## Residual Risk

- The SQL migration has been executed against the linked live Supabase project. It should still be rehearsed on staging before any repeat application or derivative migration.
- Snapshot-anchor correction depends on historical snapshots having valid `holding_client_id` or reliable same-user `holding_id`.
- Manual input is app-performance data, not a tax-lot accounting guarantee.
- Existing clients must pull the new `realized_pnl_source` column after deployment to avoid losing source metadata.

## Incident And Recovery

After the first remote application, existing holdings that did not have active ledger lines were recalculated to `quantity = 0`. The remote `assets` rows were not deleted, but several current asset totals dropped to zero because the migration's state reconcile used all active holdings as the update target.

Immediate recovery:

- Confirmed active remote row counts:
  - assets: 8 active
  - holdings: 31 active
  - cash_accounts: 11 active
  - snapshots: 91
- Used latest snapshot `2026-05-28` (`snapshot_id = 128`) as the recovery source.
- Backed up affected holdings into `recovery_archive.holdings_before_realized_pnl_restore_20260529`.
- Restored matched holdings from latest snapshot using `holding_client_id` first and same-user `holding_id` fallback.
- Re-ran `public.recompute_asset_metrics(null)`.
- Verified that the count of holdings where the latest snapshot has nonzero quantity but the current holding remains zero is `0`.

Post-restore spot check showed asset totals restored for existing asset groups:

- `+`: `₩43,680,364`
- `ISA`: `₩9,955,405`
- `주식`: `₩7,273,519`
- `코인`: `₩520,879`

Preventive local migration fix:

- Changed the final holdings state reconcile in `20260529100000_recompute_ledger_realized_pnl_from_moving_average.sql` to update only holdings that have included ledger lines.
- This prevents holdings with no ledger lines from being overwritten to zero.

## Follow-up Recommendations

- Run the migration on a staging Supabase project with fixture data for:
  - no snapshot anchor
  - valid snapshot anchor
  - same-day snapshot
  - missing `holding_client_id`
  - oversell
  - manual realized PnL
- Consider a small admin/anomaly query that counts sell rows skipped by the migration.
- Add UI surface later for reviewing historical sell rows that still require manual realized PnL.
