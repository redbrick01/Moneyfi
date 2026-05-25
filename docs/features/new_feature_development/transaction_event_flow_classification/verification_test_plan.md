# Transaction Event Flow Classification Verification Test Plan

## Scope

- Local Drift schema migration and generated code.
- Transaction event `flow_category` assignment/backfill.
- Sync payload preservation through Flutter and Supabase Edge Functions.
- UI amount color source switching from action strings to `flowCategory`.

## Quality Goals

- External deposit/withdrawal classification is explicit and stable.
- Internal transactions remain neutral in UI.
- Existing calculations and record-only behavior do not change.
- Older local/remote rows without `flow_category` safely fall back to `internal`.

## Automated Test Plan

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database.g.dart lib/models/asset_item.dart lib/pages/transactions_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/components/rows/transaction_row.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 거래 탭에서 외부 입금 금액이 초록색인지 확인한다.
- 거래 탭에서 외부 출금 금액이 빨간색인지 확인한다.
- 매수, 매도, 이체, 환전, 배당, 이자 금액이 기본 텍스트 색인지 확인한다.
- 앱 업데이트 후 기존 거래 목록이 정상 로드되는지 확인한다.

## Responsive Checklist

- 금액 색상 변경은 레이아웃 크기를 바꾸지 않아야 한다.
- 긴 금액 텍스트의 말줄임 정책은 기존과 동일해야 한다.

## Regression Test Commands

- `flutter test test/transaction_flow_test.dart`
- `flutter test test/page_walkthrough_test.dart`
- `flutter analyze`

## Acceptance Criteria

- `transaction_events.flow_category`가 로컬 schema와 Supabase migration에 존재한다.
- 새 cash deposit event는 `external_deposit`, cash withdrawal event는 `external_withdrawal`이다.
- trade, cash transfer, fx exchange, income 이벤트는 `internal`이다.
- sync export/import와 Edge Function payload가 `flow_category`를 보존한다.
- UI amount color는 `TransactionItem.flowCategory`를 기준으로 결정한다.
- 관련 자동 테스트와 analyzer가 통과한다.

## Release Risk Matrix

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Remote migration and Edge Function deployment order mismatch | Sync upsert could fail | Deploy remote migration before or with updated functions |
| Existing rows misclassified | UI color could be misleading | Backfill only explicit deposit/withdrawal, default ambiguous rows to internal |
| Generated Drift mismatch | Compile failures | Run build_runner and analyzer |

## Future Test Expansion

- Widget-level color assertion for representative transaction rows.
- Disposable Supabase migration replay test.
