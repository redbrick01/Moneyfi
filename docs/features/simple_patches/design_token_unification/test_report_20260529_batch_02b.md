# Design Token Unification Test Report - Batch 02B

작성일: 2026-05-29

## Scope

Stage 02 Batch 02B `moneyfy_ui.dart` compatibility layer 내부 토큰화.

Changed files:

- `lib/widgets/moneyfy_ui.dart`

## Changes

- `MoneyfyCardHeader`의 subtitle/trailing spacing을 `context.spacing` 기반으로 교체했습니다.
- `MoneyfyIconButtonSurface`의 radius, size, surface color, border color를 `context.radius`와 `context.colors` 기반으로 교체했습니다.
- `moneyfySingleSlideActionPane`의 `backgroundColor` 파라미터가 실제로 반영되도록 유지 보수성 개선을 함께 적용했습니다.
- public widget/class/function 이름과 constructor는 유지했습니다.

## Compatibility Kept

- `MoneyfySpacing`은 `lib/pages/forms/form_design.dart`에서 사용 중이라 삭제하지 않았습니다.
- `moneyfyValueColor`는 여러 page에서 public helper로 사용 중이고 `BuildContext`를 받지 않는 API라 `MoneyfyPalette` 기반 compatibility를 유지했습니다.
- `moneyfySingleSlideActionPane`의 `Colors.transparent`, fixed action padding은 top-level helper 특성상 context token을 직접 받을 수 없어 유지했습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib/widgets/moneyfy_ui.dart --count-matches
```

Before: `26`

After: `22`

Notes:

- 남은 legacy match는 대부분 compatibility API 또는 이미 token-derived `SizedBox`/`EdgeInsets`입니다.
- `moneyfyValueColor`의 완전 토큰화는 callsite API를 바꾸는 작업이라 Stage 07 또는 별도 compatibility migration으로 넘깁니다.

## Verification

```bash
dart format lib/widgets/moneyfy_ui.dart
flutter analyze lib/widgets/moneyfy_ui.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

Result:

- `dart format`: passed, 1 file formatted, 0 changed
- `flutter analyze`: passed, no issues
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests

## Manual QA Notes

Automated smoke and walkthrough coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- `MoneyfySpacing`과 `moneyfyValueColor`가 compatibility API로 남아 있어 Stage 07에서 migration path를 다시 결정해야 합니다.
- `MoneyfyIconButtonSurface`는 시각적으로 같은 크기를 유지하도록 `context.spacing.xl + context.spacing.sm`을 사용했습니다.
