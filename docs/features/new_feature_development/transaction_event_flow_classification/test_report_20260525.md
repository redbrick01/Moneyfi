# Transaction Event Flow Classification Test Report 2026-05-25

## Summary

`transaction_events.flow_category`를 로컬 Drift schema와 Supabase migration에 추가하고, 외부 입금/외부 출금/내부 거래 분류를 원장 이벤트에 저장하도록 구현했다. 거래 탭, 보유 상세, 현금 상세의 금액 색상은 이제 `TransactionItem.flowCategory`를 기준으로 결정한다. 자동 검증은 모두 통과했다.

## Test Environment

- Date: 2026-05-25
- Workspace: `/Users/yw0410/Desktop/Project/MONEYFY`
- Flutter/Dart: local project toolchain
- Remote Supabase apply: migration and sync Edge Function deploy completed

## Commands Run

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database.g.dart lib/models/asset_item.dart lib/pages/transactions_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/components/rows/transaction_row.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test test/page_walkthrough_test.dart
git diff --check
supabase migration list --linked
supabase db push --linked --dry-run
supabase db push --linked --yes
supabase migration list --linked
supabase db query --linked "select column_name, data_type, column_default, is_nullable from information_schema.columns where table_schema = 'public' and table_name = 'transaction_events' and column_name = 'flow_category';"
supabase functions deploy get-sync-local-db sync-local-db --use-api
supabase functions list
supabase db query --linked "select flow_category, count(*)::int as count from public.transaction_events group by flow_category order by flow_category;"
```

## Command Results

- `dart run build_runner build --delete-conflicting-outputs`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다. Drift generated file이 갱신됐다.
- `dart format ...`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다.
- `flutter test test/transaction_flow_test.dart`: passed, 49 tests.
- `flutter analyze`: passed, no issues found.
- `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
- `git diff --check`: passed.
- `supabase migration list --linked`: before push, only `20260525140000` was local-only; after push, local and remote both included `20260525140000`.
- `supabase db push --linked --dry-run`: confirmed only `20260525140000_add_transaction_event_flow_category.sql` would be applied.
- `supabase db push --linked --yes`: applied `20260525140000_add_transaction_event_flow_category.sql`.
- Remote catalog query: `transaction_events.flow_category` exists as `text`, `NOT NULL`, default `'internal'::text`.
- `supabase functions deploy get-sync-local-db sync-local-db --use-api`: deployed both sync Edge Functions.
- `supabase functions list`: `get-sync-local-db` and `sync-local-db` are `ACTIVE`, updated at `2026-05-25 05:10:19 UTC`.
- Remote flow category aggregate query: `external_deposit` 26, `external_withdrawal` 21, `internal` 65.

## Verification Against Plan

- Local Drift `transaction_events.flow_category`: implemented.
- Local migration/backfill: implemented via `_ensureTransactionEventFlowCategoryColumn` and `_backfillTransactionEventFlowCategories`.
- Supabase migration: added and applied as `20260525140000_add_transaction_event_flow_category.sql`.
- Sync payload and Edge Functions: `flow_category` is exported, imported, selected, and allowed in upsert payloads.
- UI color source: 거래 탭, 보유 상세, 현금 상세 row now use `flowCategory`.
- Calculation behavior: unchanged; transaction flow tests passed.

## Manual QA Status

Not run. 실제 기기에서 외부 입금 초록색, 외부 출금 빨간색, 매수/매도/이체/환전 기본색 표시를 확인해야 한다.

## Responsive QA Status

Not run. 색상 기준 변경은 레이아웃 크기를 바꾸지 않지만, 실제 거래 탭/상세 화면에서 긴 금액 말줄임은 수동 확인이 필요하다.

## Acceptance Criteria Result

- `external_deposit`, `external_withdrawal`, `internal` storage: passed.
- Cash deposit/withdrawal flow category tests: passed.
- Transfer/exchange internal category tests: passed.
- Sync payload includes `flow_category`: passed.
- Page walkthrough: passed.
- Analyzer: passed.

## Risk Assessment After Testing

로컬 앱, 원격 schema, sync Edge Function 기준 리스크는 낮다. 원격 migration과 함수 배포는 완료됐지만, 실제 사용자 계정에서 앱 sync 왕복 QA는 아직 수행하지 않았다.

## Follow-Up Recommendations

- 실제 앱 로그인 계정으로 sync 왕복 후 거래 row 색상과 데이터 보존을 확인한다.
- 이후 색상 정책을 필터나 분석 지표로 확장할 때 `flow_category`를 기준으로 사용한다.

## Final Result

자동 검증 통과. 원격 Supabase migration 적용과 sync Edge Function 배포 완료. 실제 기기 QA는 pending.
