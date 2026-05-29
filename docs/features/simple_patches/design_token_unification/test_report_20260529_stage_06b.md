# Design Token Unification Test Report - Stage 06B

작성일: 2026-05-29

## Scope

Stage 06B portfolio/transaction/statistics 계열 잔여 토큰화.

Changed files:

- `lib/design_system/tokens.dart`
- `lib/design_system/spec/visual_spec.dart`
- `lib/pages/portfolio_dashboard_page.dart`
- `lib/pages/portfolio_page.dart`
- `lib/pages/transactions_page.dart`
- `lib/pages/statistics_page.dart`

## Changes

- `AppFontSizes`에 `s32` 토큰을 추가해 dashboard hero number의 직접 `fontSize: 32`를 제거했습니다.
- `VisualSpec.surface.modalBarrierAlpha`를 추가해 transaction bottom sheet barrier alpha 직접값을 제거했습니다.
- `portfolio_dashboard_page.dart`의 `MoneyfyPalette`, `moneyfyValueColor`, 직접 dash chip padding/border/background, diagnosis tone, donut size/stroke를 `context.colors`, `context.surfaces`, `context.spacing`, `VisualSpec.icon` 기준으로 교체했습니다.
- `portfolio_page.dart`의 rebalancing value color, diagnosis block surface/border/radius, risk badge, score bar tone을 `context.colors`, `context.surfaces`, `context.radius` 기준으로 교체했습니다.
- `transactions_page.dart`의 modal transparent/scrim, filter badge size/padding/font 직접값을 token/context 기준으로 교체했습니다. 기존 filter redesign 동작은 유지했습니다.
- `statistics_page.dart`의 monthly trend axis padding/font, selected month strip value font, delta colors, calendar legend transparent fill, painter point stroke color를 token/context 기준으로 교체했습니다.
- portfolio calculation, diagnosis generation, transaction filtering/sorting, ledger flow, statistics chart data logic은 변경하지 않았습니다.

## Legacy Pattern Delta

Stage 06B scan:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize: [0-9]|const EdgeInsets|BorderRadius\\.circular\\(999|9999|strokeWidth: 2\\.2|strokeWidth: 2\\.4" lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/statistics_page.dart
```

Result: no matches.

## Verification

```bash
dart format lib/design_system/tokens.dart lib/design_system/spec/visual_spec.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/statistics_page.dart
flutter analyze lib/design_system/tokens.dart lib/design_system/spec/visual_spec.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/statistics_page.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/transaction_flow_test.dart
```

Result:

- `dart format`: passed
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/transaction_flow_test.dart`: passed, 70 tests

## Manual QA Notes

Automated walkthrough, UI smoke, and transaction flow coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- `transactions_page.dart`에는 이번 Stage 이전부터 filter redesign diff가 포함되어 있어, 이번 리포트는 해당 동작을 보존한 상태에서 디자인 토큰 직접값만 정리한 결과입니다.
- Statistics chart painter geometry와 chart palette mapping은 chart-specific exception으로 유지했습니다.
- Stage 06D brand/native asset consistency audit는 `test_report_20260529_stage_06d.md`에서 완료 기록했습니다.
