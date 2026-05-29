# Design Token Unification Test Report - Stage 05A

작성일: 2026-05-29

## Scope

Stage 05A 자산 상세 화면 잔여 토큰화.

Changed files:

- `lib/pages/asset_detail_page.dart`

## Changes

- 화면/AppBar background, empty state text, hero icon surface, hero metric text/value color를 `context.colors` 기반 semantic token으로 교체했습니다.
- 상세 화면의 주요 page padding, section gap, hero metric gap, dash chip padding/border/radius를 `context.spacing`, `context.radius`, `context.contentHorizontalPadding`으로 교체했습니다.
- `_HeroMetricRow`, `_HoldingProfitLine`의 `moneyfyValueColor` 의존을 context-aware `_valueStringColor`로 교체했습니다.
- `MoneyfyPalette` import와 직접 의존을 제거했습니다.
- 자산/보유/현금 계좌 계산, DB read/write, sync, reorder, hidden toggle, navigation 동작은 변경하지 않았습니다.

## Legacy Pattern Delta

Pre-batch direct legacy scan covered:

- `MoneyfyPalette`
- `MoneyfySpacing`
- `moneyfyValueColor`
- direct `Color(0x...)`
- `Colors.*`
- direct `fontSize:`
- selected direct spacing/radius/motion patterns

Before: `42` direct legacy matches

After:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize:|const SizedBox|const EdgeInsets|BorderRadius\\.circular|Duration\\(milliseconds" lib/pages/asset_detail_page.dart
```

Result:

- `16` matches remain.
- Remaining matches are intentional functional/layout constants or tokenized radius calls:
  - retry delay `Duration(milliseconds: ...)`
  - collapsed/leading placeholder `SizedBox`
  - established row/card geometry radius calls using `context.radius` or `VisualSpec.surface.radiusCard`
- No `MoneyfyPalette`, `moneyfyValueColor`, direct hex color, `Colors.*`, direct `fontSize`, or `const EdgeInsets` matches remain.

## Verification

```bash
dart format lib/pages/asset_detail_page.dart
flutter analyze lib/pages/asset_detail_page.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result:

- `dart format`: passed, 1 file formatted
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests

## Manual QA Notes

Automated walkthrough and smoke coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- Hero value/status colors now use semantic positive/negative roles, so 기존 `MoneyfyPalette` 색과 미세한 농도 차이가 있을 수 있습니다.
- Stage 05B의 `holding_detail_page.dart`, `cash_account_detail_page.dart`가 후속 작업으로 남아 있습니다.
