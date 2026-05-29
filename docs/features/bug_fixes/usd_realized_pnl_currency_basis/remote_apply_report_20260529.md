# Remote Apply Report - 2026-05-29

## Project

- Supabase project: `Moneyfi`
- Project ref: `oeweumxfabobwlhzrzqk`

## Applied

### Database migrations

- `add_currency_basis_columns`
- `seed_existing_usd_currency_basis`
- `seed_existing_usd_currency_basis_remote_identity_fix`
- `fix_usd_snapshot_anchor_realized_pnl_currency_basis`

The original seed migration matched the user-provided Korean holding names, but the remote holdings use English names such as `SATELLOGIC`, `TESLA`, `PALANTIR`, and `NVIDIA`. The identity-fix migration therefore seeded by stable identity:

- holding id
- asset title
- symbol
- USD currency

It did not update holding quantity.

### Edge Functions

Deployed:

- `sync-local-db`
- `get-sync-local-db`
- `create-portfolio-snapshot`

All remain `verify_jwt = true`.

## Verified Results

### SATL corrective sell row

Remote transaction line `375` now has:

- quantity sold: `30`
- gross amount: `285 USD`
- realized PnL: `186.225 USD`
- KRW cost-basis delta: `-140,700`
- source cost-basis delta: `-98.775 USD`
- realized PnL source: `snapshot_anchor`

### Seeded USD holdings

The six user-provided USD source averages are now present on remote holdings:

- TSLA holding `1`: `225.9928`
- IONQ holding `3`: `28.3813`
- PLTR holding `4`: `74.4933`
- NVDA holding `5`: `133.1379`
- SATL holding `8`: `3.2925`
- TSLA holding `21`: `259.5674`

### Safety checks

- `still_zero_but_snapshot_nonzero = 0`
- `asset_purchase_mismatches = 0`
- archived transaction lines before 05: `1`
- archived holdings before 05: `1`
- 05 skipped rows: `4` non-USD `snapshot_anchor` rows

## Notes

- The remote already had `recompute_ledger_realized_pnl_from_moving_average` applied before this run.
- No Reddit migrations were applied by this run.
- The extra identity-fix migration is local and remote-applied because the actual remote holding names did not match the originally supplied Korean labels.
