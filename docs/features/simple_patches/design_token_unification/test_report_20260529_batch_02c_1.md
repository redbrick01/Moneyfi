# Design Token Unification Test Report - Batch 02C-1

작성일: 2026-05-29

## Scope

Stage 02 Batch 02C-1 chips/states/status/header 컴포넌트 점검 및 저위험 토큰화.

Changed files:

- `lib/components/chips/delta_chip.dart`
- `lib/components/chips/impact_chips.dart`

Checked but unchanged:

- `lib/components/states/empty_state.dart`
- `lib/components/states/inline_error.dart`
- `lib/components/states/retry_row.dart`
- `lib/components/states/skeletons.dart`
- `lib/components/cards/status_card.dart`
- `lib/components/headers/detail_header_card.dart`

## Changes

- `DeltaChip`의 compact/default min height와 padding을 `context.spacing` 기반으로 교체했습니다.
- `ImpactChips`의 chip height를 `context.spacing` 기반으로 교체했습니다.
- `ImpactChips`의 직접 icon size를 `VisualSpec.icon.chipIcon`으로 교체했습니다.
- public constructor, route, DB, sync, 계산 로직은 변경하지 않았습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(|height: 28|size: 18" lib/components/chips/delta_chip.dart lib/components/chips/impact_chips.dart lib/components/states/empty_state.dart lib/components/states/inline_error.dart lib/components/states/retry_row.dart lib/components/states/skeletons.dart lib/components/cards/status_card.dart lib/components/headers/detail_header_card.dart --count-matches
```

Before: `37`

After: `37`

Notes:

- 전체 grep count는 그대로지만, `height: 28`과 `size: 18` 직접 수치를 제거했습니다.
- 남은 `SizedBox`, `EdgeInsets`, `BorderRadius.circular`는 대부분 이미 `context.spacing`, `context.radius`, `VisualSpec` 기반입니다.
- states/status/header 파일은 이미 토큰 기준을 따르고 있어 이번 batch에서 수정하지 않았습니다.

## Verification

```bash
dart format lib/components/chips/delta_chip.dart lib/components/chips/impact_chips.dart lib/components/states/empty_state.dart lib/components/states/inline_error.dart lib/components/states/retry_row.dart lib/components/states/skeletons.dart lib/components/cards/status_card.dart lib/components/headers/detail_header_card.dart
flutter analyze lib/components/chips lib/components/states lib/components/cards/status_card.dart lib/components/headers/detail_header_card.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed, 8 files formatted, 0 changed
- `flutter analyze`: passed, no issues
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests

## Manual QA Notes

Automated smoke and walkthrough coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- `ImpactChips` icon size가 `18 -> VisualSpec.icon.chipIcon(16)`으로 미세하게 줄어듭니다.
- Stage 02C의 buttons/section shell은 아직 후속 batch로 남아 있습니다.
