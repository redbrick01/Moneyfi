# 05 Remote Corrective Migration And Safety Report

## Scope

- Created a forward-only Supabase migration:
  - `supabase/migrations/20260529020915_fix_usd_snapshot_anchor_realized_pnl_currency_basis.sql`
- Added a migration contract test:
  - `test/usd_snapshot_anchor_fix_migration_test.dart`
- This implementation prepares the migration file only. It was not applied to the remote database in this step.

## What Changed

### 1. USD snapshot-anchor sell correction

The migration corrects only transaction lines that match all of these conditions:

- `transaction_lines.action = 'sell'`
- `transaction_lines.currency_code = 'USD'`
- `transaction_lines.realized_pnl_source = 'snapshot_anchor'`
- event source is not `snapshot_restore`, `history_display`, or `record_only`
- a pre-sell snapshot holding item exists
- the holding matches one of the user-provided USD source-average seeds by holding identity

The correction uses the user-provided source-currency average cost, not a replayed historical moving average:

- `realized_pnl = gross_amount - average_price_source * sell_quantity`
- `cost_basis_delta = -average_price_krw * sell_quantity`
- `cost_basis_source_delta = -average_price_source * sell_quantity`

SATL reference in the migration:

- `sell_quantity = 30`
- `gross_amount = 285 USD`
- `average_price_source = 3.2925 USD`
- `realized_pnl = 186.225 USD`
- `cost_basis_delta = -140,700 KRW`
- `cost_basis_source_delta = -98.775 USD`

### 2. Seed matching

The migration embeds the six user-provided USD source-average rows:

- SATL / 새틀로직: `3.2925`
- IONQ / 아이온큐: `28.3813`
- TSLA / 테슬라, holding `1`: `225.9928`
- PLTR / 팔란티어: `74.4933`
- NVDA / 엔비디아: `133.1379`
- TSLA / 테슬라, holding `21`: `259.5674`

To avoid skipping the correction after a previous bad migration changed current quantity or KRW average price, the 05 migration matches seed holdings by:

- `holding_id`
- asset title
- symbol
- holding name
- `USD` currency

It does not require the current holding quantity or current KRW average price to still equal the original seed.

### 3. Zero-wipe prevention

The migration does not replay all transaction history and does not reconcile holding quantities from ledger sums.

It intentionally avoids:

- `update public.holdings set quantity = ...`
- broad `left join transaction_lines` based holding reconciliation
- `computed_holdings` / `active_holding_ledger` style replay blocks

The only holding update is limited to seeded currency-basis fields for holdings that have affected sell lines:

- `average_price`
- `average_price_krw`
- `average_price_source`
- `average_purchase_fx_rate`
- `cost_basis_krw`

Current holding `quantity` is read only to recompute `cost_basis_krw`; it is never overwritten.

Important boundary: 05 does not backfill every seeded USD holding. Seeded holdings without affected sell lines depend on the 02 seed migration. If 02 was skipped because the current remote state had already drifted, review the 02 skipped-row archive before applying or interpreting 05 results.

### 4. Archives and skipped rows

Before correction, the migration writes recovery/audit tables:

- `recovery_archive.transaction_lines_before_usd_snapshot_anchor_fix_20260529`
- `recovery_archive.holdings_before_usd_snapshot_anchor_fix_20260529`
- `recovery_archive.usd_snapshot_anchor_fix_skipped_20260529`

Skipped rows include snapshot-anchor sells that are non-USD or do not match a user-provided seed.

### 5. Asset metric recompute hardening

The migration replaces `public.recompute_asset_metrics(uuid)` so asset `purchase_krw` prefers:

1. `holdings.cost_basis_krw` when positive
2. fallback `holdings.quantity * holdings.average_price`

The function updates only `public.assets` metrics and display fields. It does not update holdings or holding quantities.

## Verification

Commands run:

```sh
flutter test test/usd_snapshot_anchor_fix_migration_test.dart
flutter test test/transaction_flow_test.dart test/sync_currency_basis_contract_test.dart test/usd_currency_seed_migration_test.dart test/usd_snapshot_anchor_fix_migration_test.dart
git diff --check
```

Result:

- All targeted tests passed.
- `git diff --check` passed.

## Remaining Operational Notes

- The migration has not been pushed or applied to the remote Supabase database.
- Before remote application, run the pre-05 SELECT sections in `remote_verification_and_rollback_06.sql`.
- For a true dry run, apply the migration to a cloned/staging Supabase project or run the candidate SELECTs in a transaction that is rolled back. The archive tables such as `recovery_archive.usd_snapshot_anchor_fix_skipped_20260529` exist only after 05 has run.
- This migration prevents a repeat of the portfolio zero-wipe pattern by removing broad holding quantity reconciliation from the corrective path; it does not attempt to reconstruct quantities already damaged by a previously applied migration.
