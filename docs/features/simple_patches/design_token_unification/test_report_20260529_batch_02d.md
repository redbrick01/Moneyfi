# Design Token Unification Test Report - Batch 02D

작성일: 2026-05-29

## Scope

Stage 02 Batch 02D `ui_scaffold`, icons, feedback, expandable 컴포넌트 점검 및 저위험 토큰화.

Changed files:

- `lib/ui_scaffold/app_page_scaffold.dart`
- `lib/components/expandable/expandable_tile.dart`

Checked but unchanged:

- `lib/ui_scaffold/app_insets.dart`
- `lib/components/icons/app_avatar.dart`
- `lib/components/icons/app_icon.dart`
- `lib/components/icons/app_icon_button.dart`
- `lib/components/icons/leading_badge.dart`
- `lib/components/feedback/app_snackbar.dart`

## Changes

- `AppPageScaffold` overflow menu icon을 raw Material icon에서 `AppIcon(AppIconName.more)`로 교체했습니다.
- `ExpandableTile` expand icon size를 직접 `24`에서 `VisualSpec.icon.sizeDefault`로 교체했습니다.
- public constructor, route, DB, sync, 계산 로직은 변경하지 않았습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(|size: 24|Icon\\(Icons\\.more_horiz_rounded\\)|Duration\\(milliseconds|floatingNavHeight" lib/ui_scaffold lib/components/icons lib/components/feedback/app_snackbar.dart lib/components/expandable/expandable_tile.dart --count-matches
```

Before: `27`

After: `25`

Notes:

- `Icon(Icons.more_horiz_rounded)`와 `size: 24` 직접 사용을 제거했습니다.
- `AppInsets.floatingNavHeight = 72`는 `app_shell_page.dart`의 floating navigation contract와 함께 Stage 06에서 다룹니다.
- `SnackBar.duration = 3000ms`는 animation token이 아니라 display policy라 이번 batch에서 유지했습니다.
- 남은 `SizedBox`, `EdgeInsets`, `BorderRadius.circular`는 대부분 `context.spacing`, `context.radius`, `VisualSpec` 기반입니다.

## Verification

```bash
dart format lib/ui_scaffold/app_insets.dart lib/ui_scaffold/app_page_scaffold.dart lib/components/icons/app_avatar.dart lib/components/icons/app_icon.dart lib/components/icons/app_icon_button.dart lib/components/icons/leading_badge.dart lib/components/feedback/app_snackbar.dart lib/components/expandable/expandable_tile.dart
flutter analyze lib/ui_scaffold lib/components/icons lib/components/feedback/app_snackbar.dart lib/components/expandable/expandable_tile.dart
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

- `floatingNavHeight`는 shell layout과 맞물려 있어 Stage 06에서 `app_shell_page.dart`와 함께 검증해야 합니다.
- `moneyfy_ui.dart` compatibility layer는 아직 Stage 02B로 남아 있습니다.
