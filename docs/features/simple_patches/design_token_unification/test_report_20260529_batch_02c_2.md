# Design Token Unification Test Report - Batch 02C-2

작성일: 2026-05-29

## Scope

Stage 02 Batch 02C-2 buttons/section shell 컴포넌트 점검 및 저위험 토큰화.

Changed files:

- `lib/components/buttons/app_buttons.dart`
- `lib/components/section_header.dart`

Checked but unchanged:

- `lib/components/section_card.dart`

## Changes

- button loading spinner size를 `context.spacing.md`로 교체했습니다.
- button minimum height를 `VisualSpec.icon.minTapTarget`으로 교체했습니다.
- button vertical padding을 `context.spacing.sm`으로 교체했습니다.
- section header height를 `VisualSpec.icon.minTapTarget`으로 교체했습니다.
- public constructor, route, DB, sync, 계산 로직은 변경하지 않았습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(|Size\\(0, 48\\)|height: 48|width: 16|height: 16|vertical: 12" lib/components/buttons/app_buttons.dart lib/components/section_card.dart lib/components/section_header.dart --count-matches
```

Before: `20`

After: `19`

Notes:

- `Size(0, 48)`, `height: 48`, spinner `16`, `vertical: 12` 직접 수치를 제거했습니다.
- 남은 `Colors.transparent`는 ghost/destructive button과 transparent Material의 의도된 예외입니다.
- 남은 `SizedBox`, `EdgeInsets`, `BorderRadius.circular`는 대부분 `context.spacing`, `context.cardPadding`, `context.radius`, `VisualSpec` 기반입니다.
- `section_card.dart`는 이미 canonical shell에 가까워 이번 batch에서 수정하지 않았습니다.

## Verification

```bash
dart format lib/components/buttons/app_buttons.dart lib/components/section_card.dart lib/components/section_header.dart
flutter analyze lib/components/buttons/app_buttons.dart lib/components/section_card.dart lib/components/section_header.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed, 3 files formatted, 1 changed
- `flutter analyze`: passed, no issues
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests

## Manual QA Notes

Automated smoke and walkthrough coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- Button vertical padding remains visually equivalent because `context.spacing.sm` is currently `12`.
- Section header height remains visually equivalent because `VisualSpec.icon.minTapTarget` is currently `48`.
- Stage 02D의 `ui_scaffold`, icon/feedback/expandable 컴포넌트가 후속 batch로 남아 있습니다.
