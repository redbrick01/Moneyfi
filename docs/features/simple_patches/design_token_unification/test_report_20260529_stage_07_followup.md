# Design Token Unification Test Report - Stage 07 Follow-up

작성일: 2026-05-29

## Scope

Stage 07 후속 cleanup:

- `snapshot_detail_page.dart` page-level `MoneyfyPalette` 제거
- component/helper `Colors.transparent` guardrail match 제거
- reporting-only guardrail clean 상태 확인

Changed files:

- `.github/workflows/flutter-ci.yml`
- `lib/pages/snapshot_detail_page.dart`
- `lib/design_system/spec/visual_spec.dart`
- `lib/components/buttons/app_buttons.dart`
- `lib/components/section_card.dart`
- `lib/components/rows/asset_row.dart`
- `lib/widgets/moneyfy_ui.dart`
- `docs/features/simple_patches/design_token_unification/test_report_20260529_stage_07.md`

## Changes

- `snapshot_detail_page.dart`의 남은 `MoneyfyPalette` 색상을 `context.colors`와 `context.surfaces`로 교체했습니다.
- `_changeColor`를 `BuildContext` 기반 helper로 바꿔 semantic positive/negative/neutral color를 사용하도록 했습니다.
- `VisualSpec.surface.transparent`를 추가하고, 버튼/카드/row/slidable helper의 직접 `Colors.transparent` 사용을 해당 token으로 교체했습니다.
- Flutter CI에 `Design token guardrail report` 단계를 추가했습니다. `continue-on-error: true`로 시작해 reporting-only 정책을 유지합니다.

## Guardrail Result

```bash
tools/check_design_token_guardrails.sh
```

Result: clean.

## Verification

```bash
dart format lib/pages/snapshot_detail_page.dart
dart format lib/design_system/spec/visual_spec.dart lib/components/buttons/app_buttons.dart lib/components/section_card.dart lib/components/rows/asset_row.dart lib/widgets/moneyfy_ui.dart
flutter analyze lib/pages/snapshot_detail_page.dart
flutter analyze lib/pages/snapshot_detail_page.dart lib/design_system/spec/visual_spec.dart lib/components/buttons/app_buttons.dart lib/components/section_card.dart lib/components/rows/asset_row.dart lib/widgets/moneyfy_ui.dart
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed
- `flutter analyze`: passed, no issues
- `tools/check_design_token_guardrails.sh`: clean
- `flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart`: passed, 31 tests
- `.github/workflows/flutter-ci.yml`: guardrail report step added after `flutter analyze`

## Remaining Risk

- Guardrail is still reporting-only by design. CI adoption should start as non-blocking before switching to blocking.
