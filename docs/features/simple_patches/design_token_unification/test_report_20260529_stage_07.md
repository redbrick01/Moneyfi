# Design Token Unification Test Report - Stage 07

작성일: 2026-05-29

## Scope

Stage 07 legacy token retirement / reporting-only guardrail 정리.

Changed files:

- `lib/widgets/moneyfy_ui.dart`
- `lib/theme/moneyfy_colors.dart`
- `tools/check_design_token_guardrails.sh`
- `docs/design_system.md`
- `docs/features/simple_patches/design_token_unification/plan_parts/07_legacy_token_retirement.md`

## Changes

- `MoneyfySpacing`을 deprecated compatibility API로 표시했습니다.
- `moneyfyValueColor`를 deprecated compatibility API로 표시했습니다.
- `MoneyfyPalette.brandManifest`를 current web manifest/theme seed color인 `#0066CC`로 맞췄습니다.
- 오래된 icon color constants를 현재 canonical icon SVG 색상명에 맞게 정리했습니다.
- `tools/check_design_token_guardrails.sh`를 추가했습니다. 이 스크립트는 reporting-only로 동작하며 match가 있어도 exit `0`을 반환합니다.
- `docs/design_system.md`와 Stage 07 계획서에 compatibility policy, 남은 예외, guardrail 운영 방식을 반영했습니다.

## Guardrail Snapshot

Command:

```bash
tools/check_design_token_guardrails.sh
```

Initial result:

- Remaining `MoneyfyPalette` page usage was isolated to `lib/pages/snapshot_detail_page.dart`.
- Direct `Color(0x...)` outside design system/theme: no matches.
- Direct numeric `fontSize:` outside design system/theme: no matches.
- `Colors.transparent` appeared in small component/helper surfaces.

Follow-up cleanup result:

- `lib/pages/snapshot_detail_page.dart` now has no `MoneyfyPalette` page usage.
- Transparent component/helper surfaces now use `VisualSpec.surface.transparent`.
- `tools/check_design_token_guardrails.sh` reports clean.

## Compatibility Policy

| API | Status | Next Action |
| --- | --- | --- |
| `MoneyfyPalette` | compatibility bridge | Keep only for theme bridge and deprecated compatibility helpers |
| `MoneyfySpacing` | deprecated | Do not use in new code |
| `moneyfyValueColor` | deprecated | Do not use in new code |
| `MoneyfySurfaceCard` / `MoneyfySectionCard` | compatibility components | Keep until remaining page wrappers are migrated |
| `moneyfySingleSlideActionPane` | compatibility helper | Keep until shared swipe action component exists |
| `MoneyfyChartPalette` | chart compatibility helper | Keep until context-aware chart palette API exists |

## Verification

```bash
dart format lib/widgets/moneyfy_ui.dart lib/theme/moneyfy_colors.dart
flutter analyze lib/widgets/moneyfy_ui.dart lib/theme/moneyfy_colors.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed
- `flutter analyze`: passed, no issues
- `tools/check_design_token_guardrails.sh`: passed as reporting-only; clean after follow-up cleanup
- `flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart`: passed, 31 tests

## Remaining Risk

- Guardrail is not CI-blocking yet. It is now clean locally and can be moved to CI as reporting-only first.
- Full CI blocking should still wait until the team agrees that the current allowlist scope is stable.
