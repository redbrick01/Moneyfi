# 07 Legacy Token Retirement

## Goal

`MoneyfyPalette`, `MoneyfySpacing`, direct colors, direct font sizes, and arbitrary spacing이 다시 늘지 않도록 guardrail을 단계화합니다.

## Strategy

Do not remove legacy tokens immediately. Treat them as compatibility APIs for untouched legacy screens until the previous stages have reduced usage enough to make removal safe.

## Soft Guardrail

Applies from Stage 01 onward.

Rules:

- every token unification batch records grep delta in test report
- no new `MoneyfyPalette` usage in touched files
- no new `Color(0x...)` outside design system/theme/spec files
- no new arbitrary `fontSize:` unless documented as exception
- exceptions are listed with reason

## Hard Guardrail Candidate

Introduce only after major legacy areas are reduced. Stage 07 adds a reporting-only command first:

```bash
tools/check_design_token_guardrails.sh
```

This command exits `0` even when matches are found, so it can be used in local review and CI logs before becoming blocking.

Possible CI checks:

```bash
rg -n "Color\\(0x" lib --glob "*.dart" --glob "!lib/design_system/**" --glob "!lib/theme/**"
rg -n "fontSize:" lib --glob "*.dart" --glob "!lib/design_system/**"
rg -n "MoneyfyPalette" lib --glob "*.dart"
```

Hard guardrail should begin as reporting-only before becoming blocking.

## Compatibility Layer Policy

Current Stage 07 compatibility status:

| API | Status | Rule |
| --- | --- | --- |
| `MoneyfyPalette` | compatibility bridge | Allowed in `lib/theme/**` and explicitly listed legacy screens only |
| `MoneyfySpacing` | deprecated compatibility API | Do not use in new code |
| `moneyfyValueColor` | deprecated compatibility API | Do not use in new code; prefer `context.colors.positiveOn/negativeOn` |
| `MoneyfySurfaceCard` / `MoneyfySectionCard` | compatibility components | Allowed until remaining legacy page wrappers are migrated |
| `moneyfySingleSlideActionPane` | compatibility component helper | Allowed while shared swipe action API is extracted |
| `MoneyfyChartPalette` | chart compatibility helper | Allowed for chart palette mapping until a context-aware chart color API exists |

`MoneyfyPalette` may remain for:

- legacy helper functions
- untouched legacy screens during migration
- asset icon/app icon constants
- migration period compatibility

New code should use:

- `context.colors`
- `Theme.of(context).colorScheme`
- `VisualSpec`
- component APIs

## Cutoff Proposal

After Stage 03:

- no new `MoneyfyPalette` in `lib/components/`
- no new direct `fontSize:` in `lib/components/`

After Stage 05:

- no new `MoneyfyPalette` in newly touched detail/form/analysis page files
- direct colors allowed only in design system/theme/spec or documented chart exceptions

After Stage 06:

- no new `MoneyfyPalette` in any newly touched page file
- no unassigned UI-bearing Dart files in the coverage matrix
- native/web brand assets have an explicit consistency audit result

After Stage 07:

- `MoneyfySpacing` and `moneyfyValueColor` are deprecated
- `MoneyfyPalette.brandManifest` matches the canonical web manifest seed color
- guardrail command is available as reporting-only
- remaining `MoneyfyPalette` page usage is isolated to `snapshot_detail_page.dart`

## Verification

Run and record:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:" lib --glob "*.dart"
tools/check_design_token_guardrails.sh
flutter analyze
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

## Acceptance Criteria

- legacy usage trend is down
- compatibility exceptions are explicit
- coverage matrix has no unassigned UI-bearing Dart files
- hard guardrail proposal has a safe reporting-only path
