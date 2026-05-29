# Stage 03 P0 Screen Compliance Report

작성일: 2026-05-29

## Scope

P0 화면 compliance 중 code-assisted 후보로 확인된 항목을 우선 처리했다.

이번 batch는 `P0-C Transactions`에 한정한다.

## Changed Files

- `lib/pages/transactions_page.dart`
- `docs/features/simple_patches/design_md_full_compliance/audit_matrix.md`
- `docs/features/simple_patches/design_md_full_compliance/manual_notes/needs_fix_20260529.md`

## Change

### Transaction Type Badge Background

기존 `_transactionTypeColor`는 거래 종류에 따라 `positiveContainer` 또는 `negativeContainer`를 badge background로 사용했다.

Design-MD 기준에서는 trading semantic green/red를 text/icon/chart mark 중심으로 쓰고, filled background는 신중히 제한해야 한다. 거래 종류 badge는 거래의 signed amount와 별도 의미를 갖기 때문에 semantic fill을 제거하고 neutral surface로 통일했다.

결과:

- 매수/매도/입금/출금/이체/환전 badge background가 `context.colors.neutralSurfaceOverlay`로 통일됨.
- 금액의 plus/minus semantic text color는 기존 `amountColor` 경로를 유지함.
- `TransactionRow` API 변경 없음.

## Manual QA Note

PNG screenshot harness가 아직 없으므로 이번 batch는 manual QA note로 기록한다.

권장 후속 캡처:

| 화면 | 캡처 |
| --- | --- |
| Transactions data | `screenshots/after/transactions_data_390dp.png` |
| Transactions overflow-risk | `screenshots/after/transactions_data_360dp.png` |
| Transactions filter/sort | `screenshots/after/transactions_filter_390dp.png` |

확인할 항목:

- 거래 종류 badge가 semantic filled chip처럼 보이지 않음.
- 거래 금액의 positive/negative text color는 유지됨.
- 360dp에서 badge, title, amount가 겹치지 않음.
- swipe delete action color는 destructive action으로 유지됨.

## Verification

```bash
dart format lib/pages/transactions_page.dart
flutter analyze lib/pages/transactions_page.dart
flutter test test/page_walkthrough_test.dart
tools/check_design_token_guardrails.sh
```

## Result

- `dart format lib/pages/transactions_page.dart`: passed. Flutter SDK cache write가 필요해 권한 상승으로 실행.
- `flutter analyze lib/pages/transactions_page.dart`: passed, no issues.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `tools/check_design_token_guardrails.sh`: clean.

## Remaining P0 Follow-Up

- App shell / floating tab bar: 실제 360/390dp screenshot 필요.
- Dashboard / portfolio: hero number, card nesting, chart legend screenshot 필요.
- Detail pages: header density, action icon, chart tooltip screenshot 필요.
- Forms/sheets: keyboard-safe CTA screenshot 필요.
- DeltaChip vivid: 실제 화면에서 fill 강도 확인 필요.
