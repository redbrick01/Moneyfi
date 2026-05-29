# USD Realized PnL Currency Basis Operational Runbook

## Remote Deployment Order

Apply the remote pieces in this order:

1. Schema migration:
   - `20260529014240_add_currency_basis_columns.sql`
2. Edge Function deployment:
   - `sync-local-db`
   - `get-sync-local-db`
3. Sync preserve verification:
   - confirm stale clients cannot overwrite positive server USD currency-basis fields with `0`
4. Seed migration:
   - `20260529014953_seed_existing_usd_currency_basis.sql`
5. Corrective migration:
   - `20260529020915_fix_usd_snapshot_anchor_realized_pnl_currency_basis.sql`
6. Verification:
   - `remote_verification_and_rollback_06.sql`

Do not apply the seed migration before the sync preserve behavior is deployed.

## Before Applying 05

Run only the pre-05 sections in `remote_verification_and_rollback_06.sql`:

- 01. Pre-05 aggregate transaction performance by currency
- 02. Pre-05 candidate USD `snapshot_anchor` sell-line review
- 03. Pre/post USD anomaly query
- 04. Pre/post zero-wipe verification

The archive/skipped-row sections require tables created by 05 and will fail before 05 has run.

## After Applying 05

Run the post-05 sections:

- 03. Pre/post USD anomaly query
- 04. Pre/post zero-wipe verification
- 05. Post-05 archive and skipped-row review
- 06. Post-05 asset metric purchase basis verification

Expected zero-wipe check:

- `still_zero_but_snapshot_nonzero = 0`

## Rollback Boundary

Use the rollback templates only for targeted archive-based restore.

The holding rollback intentionally does not restore `quantity`. If an earlier migration already damaged holding quantities, this rollback does not repair that state; quantity repair must be handled with a separate snapshot-based recovery plan.
