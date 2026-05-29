# Design Token Unification Test Report - Batch 02A

작성일: 2026-05-29

## Scope

Stage 02 Batch 02A 공용 row/metric 컴포넌트 토큰화.

Changed files:

- `lib/components/transaction_history_list.dart`
- `lib/components/rows/snapshot_row.dart`
- `lib/components/rows/rebalance_row.dart`
- `lib/components/rows/allocation_legend_row.dart`

Checked but unchanged:

- `lib/components/metrics/metric_header.dart`
- `lib/components/metrics/metric_row.dart`

## Changes

- `MoneyfyPalette` 의존을 `context.colors` 기반 semantic token으로 교체했습니다.
- 직접 간격 값 일부를 `context.spacing` 기반 값으로 교체했습니다.
- 직접 pill radius를 `context.radius.rPill`로 교체했습니다.
- `rebalance_row.dart`의 직접 `fontSize: 12`를 `context.fontSizes.s12`로 교체했습니다.
- public constructor, route, DB, sync, 계산 로직은 변경하지 않았습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart --count-matches
```

Before: `54`

After: `41`

Notes:

- 남은 `SizedBox`, `EdgeInsets`, `BorderRadius.circular`는 대부분 이미 `context.spacing`, `context.radius`, `VisualSpec` 기반입니다.
- `metric_header.dart`, `metric_row.dart`는 이미 토큰 기반이라 이번 batch에서 수정하지 않았습니다.

## Verification

```bash
dart format lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart
flutter analyze lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed, 6 files formatted, 0 changed
- `flutter analyze`: passed, no issues
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests

## Manual QA Notes

Automated smoke and walkthrough coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- `context.colors.positiveOn/negativeOn`은 semantic token 기준으로 맞지만, 기존 `MoneyfyPalette.positive/negative`와 색감이 미세하게 달라질 수 있습니다.
- Stage 02 전체 대상 중 buttons/chips/states/scaffold/moneyfy_ui compatibility layer는 아직 후속 batch로 남아 있습니다.
