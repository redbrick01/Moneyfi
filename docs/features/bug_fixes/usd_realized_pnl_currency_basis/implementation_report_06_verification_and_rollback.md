# 06 Verification And Rollback Report

## Scope

- Added operational verification and rollback SQL:
  - `docs/features/bug_fixes/usd_realized_pnl_currency_basis/remote_verification_and_rollback_06.sql`
- Added a verification-document contract test:
  - `test/usd_verification_and_rollback_doc_test.dart`
- Added a missing USD manual sell contract test in:
  - `test/transaction_flow_test.dart`

No remote Supabase migration was applied in this step.

## What Changed

### 1. USD manual sell verification

Added a local DB test that confirms:

- manual USD realized PnL is stored as source-currency USD
- `realized_pnl_source = 'manual'`
- KRW cost basis still uses the KRW average cost
- source-currency cost basis uses the source-currency relation

Covered example:

- holding average KRW cost: `14,000`
- holding average source cost: `10 USD`
- sell `5 * 30 USD`
- manual realized PnL: `100 USD`
- expected `cost_basis_delta = -70,000 KRW`
- expected `cost_basis_source_delta = -50 USD`

### 2. Remote verification SQL

Created a SQL helper with these sections:

- currency aggregate before/after check
- candidate USD `snapshot_anchor` sell-line review
- USD anomaly query
- zero-wipe verification
- migration archive counts
- skipped-row summary
- asset `purchase_krw` recompute verification using `cost_basis_krw`
- targeted transaction-line rollback template
- targeted holding currency-basis rollback template

The SQL is split by execution timing:

- pre-05 or pre/post sections can be run before the corrective migration
- post-05 sections reference archive tables created by the 05 migration and should be run only after 05 has applied

The rollback template intentionally does not restore holding `quantity`; it only restores the currency-basis fields archived by the 05 migration. If an earlier bad migration already damaged holding quantities, this rollback is not sufficient and a separate snapshot-based quantity recovery plan is required.

### 3. Verification-document guard

Added a test that keeps the SQL helper from losing critical safeguards:

- zero-wipe query exists
- SATL expected correction values are documented
- archive tables are referenced
- holding rollback avoids `quantity = ...`
- asset purchase verification prefers `cost_basis_krw`

## Verification

Commands run:

```sh
flutter test test/transaction_flow_test.dart test/usd_verification_and_rollback_doc_test.dart test/usd_snapshot_anchor_fix_migration_test.dart
flutter test test/widget_test.dart test/sync_currency_basis_contract_test.dart test/usd_currency_seed_migration_test.dart test/usd_verification_and_rollback_doc_test.dart
flutter analyze
git diff --check
```

Result:

- All targeted tests passed.
- `flutter analyze` passed.
- `git diff --check` passed.

## Operational Notes

- Before applying 05, run only the pre-05 and pre/post sections in `remote_verification_and_rollback_06.sql`.
- After applying 05, run the post-05 archive/skipped-row sections and repeat the pre/post anomaly and zero-wipe checks.
- After applying 05, expected zero-wipe check:
  - `still_zero_but_snapshot_nonzero = 0`
- Review skipped rows before deciding whether more user-provided source averages are needed.
- Prefer archive-based targeted rollback over broad point-in-time recovery.
- Follow `operational_runbook.md` for the complete remote deployment order.
