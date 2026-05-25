# Transaction Event Flow Classification Implementation Report 2026-05-25

## Summary

거래 이벤트에 `flow_category`를 추가해 외부 입금, 외부 출금, 내부 거래를 명시적으로 구분한다. UI 금액 색상은 더 이상 액션 문자열을 직접 해석하지 않고 이 분류값을 사용한다.

## Implemented Stages

1. `TransactionFlowCategory` model helper and `TransactionItem.flowCategory`.
2. Local Drift schema version 32 and migration/backfill helpers.
3. Event writer category assignment for ledger, legacy rebuild, record-only, replacement, and opening events.
4. Transaction fetch queries expose `flowCategory`.
5. Sync payload, local restore, and Supabase Edge Function payload support.
6. Supabase forward migration and remote apply.
7. UI amount color switch to `flowCategory`.
8. Transaction flow regression assertions.

## Changed Files

- `lib/models/asset_item.dart`
- `lib/db/app_database_tables.dart`
- `lib/db/app_database.dart`
- `lib/db/app_database.g.dart`
- `lib/pages/transactions_page.dart`
- `lib/pages/holding_detail_page.dart`
- `lib/pages/cash_account_detail_page.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `lib/pages/forms/cash_transaction_form_page.dart`
- `supabase/functions/get-sync-local-db/index.ts`
- `supabase/functions/sync-local-db/index.ts`
- `supabase/migrations/20260525140000_add_transaction_event_flow_category.sql`
- `test/transaction_flow_test.dart`

## Data Layer Changes

- Local column: `transaction_events.flow_category TEXT NOT NULL DEFAULT 'internal'`.
- Remote column: `public.transaction_events.flow_category text not null default 'internal'`, applied to linked project `oeweumxfabobwlhzrzqk`.
- Backfill:
  - cash_flow + deposit line -> `external_deposit`
  - cash_flow + withdrawal line -> `external_withdrawal`
  - all other events -> `internal`
- New event assignment follows the same rule.

## UI Changes

- 거래 탭 row amount color uses `TransactionFlowCategory`.
- 보유 상세 거래내역 row amount color uses `TransactionFlowCategory`.
- 현금 상세 거래내역 row amount color uses `TransactionFlowCategory`.

## Tests Added Or Updated

- Cash withdrawal flow category assertion.
- Cash deposit flow category assertion.
- Record-only cash flow category assertion.
- Cash transfer internal category assertion.
- FX exchange internal category assertion.
- Dirty sync payload `flow_category` assertion.

## Verification Results

See `test_report_20260525.md`. Remote verification confirmed the column exists and the aggregate categories are populated.

## Known Limitations

- App-level sync round-trip QA against a real user session has not been performed.
- Manual device QA is still required.

## Risk Notes

- Remote migration was applied before deploying the updated Edge Functions.
- Older remote payloads without `flow_category` are safe because local restore falls back to `internal`.

## Follow-Up Items

- Consider adding a UI widget test that asserts representative amount colors.
- Run real-device sync QA with a signed-in account.
