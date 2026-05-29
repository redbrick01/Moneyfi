# Design Token Unification Test Report - Stage 05B

작성일: 2026-05-29

## Scope

Stage 05B 보유 종목 상세/현금 계좌 상세 화면 잔여 토큰화.

Changed files:

- `lib/pages/holding_detail_page.dart`
- `lib/pages/cash_account_detail_page.dart`

## Changes

- 두 상세 화면의 background, hero icon surface, section action color, transaction amount color, status chip color를 `context.colors` 기반 semantic token으로 교체했습니다.
- page padding, hero gap, section header gap, dash chip padding/radius/border, transaction row padding을 `context.spacing`, `context.radius`, `context.contentHorizontalPadding`으로 교체했습니다.
- `moneyfyValueColor` 의존을 context-aware value string color helper로 교체했습니다.
- `holding_detail_page.dart`의 거래 유형 chip hard-coded hex colors를 semantic positive/negative/warning/neutral roles로 교체했습니다.
- 보유 종목/현금 계좌 계산, market snapshot fetch, comparison metric load, DB write/delete, sync, transaction navigation 동작은 변경하지 않았습니다.

## Legacy Pattern Delta

Pre-batch direct legacy scan covered:

- `MoneyfyPalette`
- `MoneyfySpacing`
- `moneyfyValueColor`
- direct `Color(0x...)`
- `Colors.*`
- direct `fontSize:`
- selected direct spacing/radius/motion patterns

Before: `111` direct legacy matches

After:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize:|const SizedBox|const EdgeInsets|BorderRadius\\.circular|Duration\\(milliseconds" lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart
```

Result:

- `24` matches remain.
- Remaining matches are intentional functional/layout constants or tokenized radius calls:
  - retry delay `Duration(milliseconds: ...)`
  - collapsed/empty `SizedBox` placeholders
  - chart/row geometry constants
  - `context.radius` or `VisualSpec.surface.radiusCard` radius calls
- No `MoneyfyPalette`, `moneyfyValueColor`, direct hex color, `Colors.*`, direct `fontSize`, or `const EdgeInsets` matches remain.

## Verification

```bash
dart format lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart
flutter analyze lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart
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

- 거래 유형 chip과 주간 범위 bar 색상이 semantic role로 바뀌어 기존 hard-coded 색과 미세한 차이가 있을 수 있습니다.
- Stage 05C의 form page 계열이 후속 작업으로 남아 있습니다.
