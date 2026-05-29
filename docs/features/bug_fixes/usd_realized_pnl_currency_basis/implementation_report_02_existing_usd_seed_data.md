# Implementation Report 02 - Existing USD Seed Data

## Scope

Implemented the existing USD source-average seed backfill from `plan_parts/02_existing_usd_seed_data.md`.

This step prepares a forward-only Supabase migration for the six user-provided USD holdings. It does not apply the migration to the remote database.

## Implemented

- Added Supabase migration:
  - `supabase/migrations/20260529014953_seed_existing_usd_currency_basis.sql`
- Seeded rows are explicit by holding id and asset context:
  - `주식 / SATL / 새틀로직 / holding 8`
  - `주식 / IONQ / 아이온큐 / holding 3`
  - `주식 / TSLA / 테슬라 / holding 1`
  - `주식 / PLTR / 팔란티어 / holding 4`
  - `주식 / NVDA / 엔비디아 / holding 5`
  - `+ / TSLA / 테슬라 / holding 21`
- Backfill formula:
  - `average_price_krw = existing KRW average`
  - `average_price_source = user-provided source average`
  - `average_purchase_fx_rate = average_price_krw / average_price_source`
  - `cost_basis_krw = quantity * average_price_krw`
- Added archive table before update:
  - `recovery_archive.holdings_before_usd_currency_basis_seed_20260529`
- Added skipped-row report table:
  - `recovery_archive.usd_currency_basis_seed_skipped_20260529`
- Added regression test:
  - `test/usd_currency_seed_migration_test.dart`

## Safety Decisions

- The migration matches by `holding.id` first, then verifies:
  - `asset.title`
  - `symbol`
  - `name`
  - `currency_code = 'USD'`
  - `quantity`
  - existing KRW average price
- TSLA rows are separated by asset title and holding id, so `주식/TSLA` and `+/TSLA` cannot be mixed.
- The holdings update does not set:
  - `quantity`
  - `current_price`
  - `currency_code`
  - `name`
  - `symbol`
- Rows that do not match exactly are skipped and recorded instead of guessed.
- No source average is inferred from current FX, current price, or snapshot FX.
- This seed migration is intended for a still-consistent remote state. If an earlier bad migration has already changed current `quantity` or KRW `average_price`, the exact-match guard may skip the row. In that case, use the skipped-row report and the 05 corrective path or a separate recovery plan rather than weakening this seed migration in place.

## Verification

- `flutter test test/usd_currency_seed_migration_test.dart`
- `git diff --check`

All verification commands passed.

## Remaining Work

- Implement sync-side preserve policy so older or stale local clients cannot overwrite seeded nonzero USD source averages with `0`.
- Implement USD buy/sell calculation flow using source average and weighted average FX.
- Apply the seed migration remotely only after deciding the deployment sequence with the sync preserve work.
- Use `operational_runbook.md` for the final order: schema, Edge Functions with preserve behavior, seed, corrective migration, verification.
