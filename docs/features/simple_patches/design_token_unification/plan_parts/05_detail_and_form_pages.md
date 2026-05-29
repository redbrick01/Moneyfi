# 05 Detail And Form Pages

## Goal

상세 화면과 입력 폼의 header, row, CTA, input spacing, destructive/error 표현을 공통 토큰으로 정리합니다.

## Target Files

- `lib/pages/asset_detail_page.dart`
- `lib/pages/holding_detail_page.dart`
- `lib/pages/cash_account_detail_page.dart`
- `lib/pages/snapshot_detail_page.dart`
- `lib/pages/forms/asset_form_page.dart`
- `lib/pages/forms/form_design.dart`
- `lib/pages/forms/holding_form_page.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `lib/pages/forms/cash_transaction_form_page.dart`
- `lib/pages/forms/cash_account_form_page.dart`
- `lib/pages/target_allocation_sheet.dart`

## Replacement Rules

| Area | Rule |
| --- | --- |
| detail header | `DetailHeaderCard` or equivalent tokenized shell |
| metric row | `KeyValueRow`, `MetricRow`, or local row using typography tokens |
| CTA | `AppPrimaryButton`/`AppSecondaryButton`/`AppDestructiveButton` |
| destructive action | `ColorScheme.error` or `context.colors.negativeOn` |
| form spacing | `context.spacing` and `AppPageScaffold.form` |
| input style | Theme `InputDecorationTheme`, no local font size unless required |
| sheets | `context.radius.rLg` or `VisualSpec.surface.radiusSheet` |

## Scope Boundaries

Keep:

- form validation behavior
- ledger/event calculation behavior
- navigation and save/delete flows
- keyboard-safe CTA behavior

Do not change:

- transaction calculation formulas
- DB writes
- sync triggers
- route contracts

## Verification

Required:

```bash
flutter analyze <touched detail/form files>
flutter test test/page_walkthrough_test.dart
flutter test test/widget_test.dart
```

If transaction form internals are touched:

```bash
flutter test test/transaction_flow_test.dart
```

## Manual QA

- asset detail opens and edits still navigate
- holding detail opens and transaction list remains readable
- cash account detail action rows remain clear
- transaction form keyboard does not overlap CTA
- percentage shortcuts still fit
- destructive delete confirmation remains visibly destructive

## Acceptance Criteria

- detail/form spacing is token-based
- CTA and input states match design system
- no calculation or persistence behavior changes
