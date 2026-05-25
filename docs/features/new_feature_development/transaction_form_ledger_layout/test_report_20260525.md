# Transaction Form Ledger Layout Test Report 2026-05-25

## Summary

거래/현금 거래 폼을 원장 이벤트와 라인 대상 중심으로 재배치했다. 투자 거래는 보유 종목을 선택할 수 있고, 현금 거래는 source 계좌를 선택할 수 있으며, 이체는 target 계좌도 선택할 수 있다. 수정 저장 시 선택한 source/target이 원장 이벤트 재생성에 반영된다.

Follow-up UI correction: 이체 target 계좌 field가 `계산 반영` 토글에 종속되어 기본 꺼짐 상태에서 보이지 않던 문제를 수정했다. 이제 현금 거래 유형이 `이체`이면 target 계좌 field가 항상 표시된다.

## Test Environment

- Date: 2026-05-25
- Workspace: local Flutter project
- DB/remote changes: local model/API only, no schema migration

## Commands Run

```bash
dart format lib/models/asset_item.dart lib/db/app_database.dart lib/pages/forms/form_design.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
flutter analyze lib/pages/forms/cash_transaction_form_page.dart
git diff --check
```

## Command Results

- `dart format ...`: passed after escalated rerun because sandboxed Dart could not write Flutter SDK cache.
- `flutter test test/transaction_flow_test.dart`: passed, 52 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 20 tests.
- `flutter analyze`: passed, no issues.
- `flutter analyze lib/pages/forms/cash_transaction_form_page.dart`: passed after the transfer target visibility correction.
- `git diff --check`: passed.

## Verification Against Plan

- Investment transaction edit can move to another holding: covered by a new transaction flow test.
- Cash transfer edit can change source and target accounts: covered by a new transaction flow test.
- Existing sync restore remap tests still pass after adding requested account fallback logic.
- Form first-frame walkthrough still passes.
- Transfer target field visibility no longer depends on `includeInCalculations`; it is shown whenever transaction type is `이체`.

## Manual QA Status

Manual device QA was not run. Remaining manual checks are account picker interaction, small-screen text truncation, bottom sheet visual fit, and confirming the target account field is visible for record-only transfer input.

## Responsive QA Status

Automated first-frame walkthrough passed. Physical viewport QA was not run.

## Acceptance Criteria Result

- New account change tests: passed.
- Transaction flow suite: passed.
- Page walkthrough: passed.
- Analyzer and whitespace check: passed.

## Risk Assessment After Testing

Residual risk is medium for fine-grained form UX because bottom sheet selection was not manually exercised on device. Data-layer risk is low after targeted account-change regression coverage. The known visibility gap for transfer target selection was corrected and statically verified.

## Follow-Up Recommendations

- Add widget tests for opening the account picker bottom sheet and selecting source/target accounts.
- Add direct target selection for FX exchange if product requirements need it.

## Final Result

Ready for review. No temporary execution document was created for this batch.
