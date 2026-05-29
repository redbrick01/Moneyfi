# Remote Corrective Migration And Safety

## Forward-Only Rule

Existing remote migration `20260529100000_recompute_ledger_realized_pnl_from_moving_average` is already recorded in remote migration history. Do not delete it, rewrite history, or try to solve this by re-pushing the edited file.

Create a new forward-only corrective migration:

```bash
supabase migration new fix_usd_snapshot_anchor_realized_pnl_currency_basis
```

Fresh DB behavior:

- Old migration may run first.
- New corrective migration must run after it and produce correct final values.

## Corrective Scope

This migration has two distinct update scopes. Keep them separate.

### Seed Holding Backfill Scope

Seed holding backfill applies to all user-provided seed rows, even if the holding does not have an affected sell line.

Allowed seed holding updates:

- `average_price_source`
- `average_price_krw`
- `average_purchase_fx_rate`
- `cost_basis_krw`
- compatibility `average_price`

Seed holding update must verify:

- `h.id` matches the seed holding id
- `asset.title` matches the seed asset
- `h.symbol`, `h.name`, `h.currency_code = 'USD'`, and `h.quantity` match the seed row

Seed holding update must not change:

- `quantity`
- `current_price`
- `currency_code`
- `name`
- `symbol`

### Sell Line Correction Scope

Target transaction lines:

- `tl.action = 'sell'`
- `tl.currency_code = 'USD'`
- `tl.realized_pnl_source = 'snapshot_anchor'`
- `te.source NOT IN ('snapshot_restore', 'history_display', 'record_only')`
- Pre-sell snapshot anchor exists
- Holding has a user-provided source-average seed
- Snapshot row exists only as a safety/matching anchor; do not use snapshot exchange rate to infer source average for seeded holdings

Holding update target:

- `h.id` comes only from affected sell lines
- `h.deleted_at is null`
- `h.quantity > 0`
- Snapshot anchor exists
- Update only:
  - `average_price_source`
  - `average_price_krw`
  - `average_purchase_fx_rate`
  - `cost_basis_krw`
  - compatibility `average_price`
- Do not update:
  - `quantity`
  - `current_price`
  - `currency_code`
  - `name`
  - `symbol`

Important:

- Seed backfill may update seed holdings that have no affected sell line.
- Sell-line correction must not update unseeded holdings.
- Do not combine these scopes into one broad holdings update.

## SATL Expected Correction

- Snapshot avg cost KRW: `4,690`
- User-provided source avg: `3.2925`
- Avg buy FX: `1,424.449506`
- Sell quantity: `30`
- Gross: `285 USD`
- Correct realized PnL: `285 - 3.2925 * 30 = 186.225 USD`
- Cost basis delta: `-4,690 * 30 = -140,700 KRW`
- Cost basis source delta: `-3.2925 * 30 = -98.775 USD`

Note: This differs from a snapshot-rate-derived estimate. Use the user-provided source average for seeded holdings.

Unseeded USD holdings:

- Do not correct realized PnL automatically.
- Do not derive source average from snapshot exchange rate.
- Leave them in anomaly/review output and require manual source-average seed or manual realized PnL.

## Zero-Wipe Prevention Gates

1. No broad holding state reconcile
   - Do not run `update public.holdings set quantity = ...`.
   - Do not use `left join transaction_lines` to place all holdings in the update target.
   - This migration must not modify `holdings.quantity`.

2. Explicit affected holding set
   - Build `affected_sell_lines` first.
   - Build `affected_holding_ids` only from `affected_sell_lines`.
   - Holdings update must be limited to affected ids.
   - This applies to sell-line correction. Seed holding backfill must instead be limited to the explicit seed table.

3. Snapshot-backed update only
   - If snapshot holding row is missing, update neither transaction line nor holding.

4. Preserve current quantity
   - `quantity` must not appear in the holdings update set list.
   - If `h.quantity <= 0`, skip average field updates instead of zeroing them.

5. Archive before update
   - Archive affected `transaction_lines`.
   - Archive all seed holdings that will be backfilled.
   - Archive affected sell-line holdings.

6. Abort conditions
   - Affected holdings include unexpected rows.
   - TSLA seed does not distinguish `주식/TSLA` from `+/TSLA`.
   - Any dry-run preview contains non-USD rows.
   - Any USD affected row lacks a user-provided source-average seed.

## Post-Migration Asset Recompute

Call `public.recompute_asset_metrics(null)` only after corrective updates.

`recompute_asset_metrics()` should recompute assets summary from holdings and must not update holdings quantities.

The function should prefer `sum(h.cost_basis_krw)` and fallback to old `quantity * average_price` only for rows where new columns are absent or zero.
