# Design Token Unification Test Report - Stage 05E

작성일: 2026-05-29

## Scope

Stage 05E 상세/폼 주변 보조 UI 잔여 정리 및 Stage 05 전체 재검증.

Changed files:

- `lib/pages/asset_detail_page.dart`
- `lib/pages/holding_detail_page.dart`

Rechecked files:

- `lib/pages/cash_account_detail_page.dart`
- `lib/pages/forms/asset_form_page.dart`
- `lib/pages/forms/holding_form_page.dart`
- `lib/pages/forms/cash_account_form_page.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `lib/pages/forms/cash_transaction_form_page.dart`
- `lib/pages/forms/form_design.dart`

## Changes

- `asset_detail_page.dart`, `holding_detail_page.dart`의 삭제 확인 `AlertDialog` actions를 `TextButton`에서 공용 `AppGhostButton`, `AppDestructiveButton`으로 교체했습니다.
- `cash_account_detail_page.dart`의 삭제 확인 dialog와 동일한 버튼 체계로 맞췄습니다.
- Stage 05 전체 대상 파일군을 재스캔해 legacy color/spacing/font 패턴이 남지 않았는지 확인했습니다.
- 삭제/재시도/저장/동기화/페이지 이동 동작은 변경하지 않았습니다.

## Legacy Pattern Delta

Stage 05 full-scope scan:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize:|const EdgeInsets|BorderRadius\\.circular\\(999|9999" lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/forms
```

Result: no matches.

Dialog/sheet audit:

- Destructive confirm dialogs now use shared app buttons across asset, holding, and cash account detail pages.
- Remaining `TextButton` usage in Stage 05 scope is limited to non-destructive retry actions in error/empty states.
- Selection bottom sheet in `form_design.dart` was already tokenized in Stage 05C.

## Intentional Exceptions

The following remaining patterns are functional/layout constants and were not changed:

- retry/search debounce `Duration(milliseconds: ...)`
- collapsed placeholder `SizedBox`
- slidable/row fixed hit target geometry
- chart/range bar track and marker geometry
- hidden row blur sigma values

## Verification

```bash
dart format lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart
flutter analyze lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/forms/asset_form_page.dart lib/pages/forms/holding_form_page.dart lib/pages/forms/cash_account_form_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/form_design.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result:

- `dart format`: passed, 2 files formatted
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests

## Manual QA Notes

Automated walkthrough and smoke coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- 공용 destructive/ghost button으로 바뀌며 삭제 확인 dialog의 버튼 폭/아이콘 표현이 기존 `TextButton` 대비 약간 달라질 수 있습니다.
- Stage 06의 app shell/auth/my/portfolio/transaction/statistics/sync overlay 잔여 화면이 후속 작업으로 남아 있습니다.
