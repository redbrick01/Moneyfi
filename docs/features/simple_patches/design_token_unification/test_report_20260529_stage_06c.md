# Design Token Unification Test Report - Stage 06C

작성일: 2026-05-29

## Scope

Stage 06C auth/my 계열 및 연결된 공용 progress indicator 토큰화.

Changed files:

- `lib/design_system/spec/visual_spec.dart`
- `lib/pages/my_page.dart`
- `lib/components/buttons/app_buttons.dart`
- `lib/pages/sync_overlay.dart`
- `lib/pages/app_shell_page.dart`

Rechecked files:

- `lib/pages/login_page.dart`
- `lib/pages/signup_page.dart`

## Changes

- `VisualSpec.icon`에 progress indicator size/stroke 토큰을 추가했습니다.
- `my_page.dart`의 settings action row trailing 로딩 인디케이터 반복 구현을 `_inlineProgressIndicator`로 통합하고 신규 progress 토큰을 사용하도록 변경했습니다.
- `AppPrimaryButton`, `SyncOverlay`, app shell account replacement loading UI의 progress size/stroke 직접값을 `VisualSpec.icon` 기준으로 교체했습니다.
- `login_page.dart`, `signup_page.dart`는 재스캔 결과 Stage 06C 범위의 legacy token 패턴이 없어 코드 변경하지 않았습니다.
- auth, profile update, password update, sync, logout, clipboard copy 동작은 변경하지 않았습니다.

## Legacy Pattern Delta

Stage 06C auth/my scan:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize:|const EdgeInsets|BorderRadius\\.circular\\(999|9999" lib/pages/my_page.dart lib/pages/login_page.dart lib/pages/signup_page.dart
```

Result: no matches.

Progress indicator direct-value scan:

```bash
rg -n "strokeWidth: 2\\.2|strokeWidth: 2\\.4|width: 28,|height: 28,|width: 20,|height: 20,|width: 18,|height: 18," lib/pages/my_page.dart lib/components/buttons/app_buttons.dart lib/pages/sync_overlay.dart lib/pages/app_shell_page.dart lib/design_system/spec/visual_spec.dart
```

Result: no matches.

## Verification

```bash
dart format lib/design_system/spec/visual_spec.dart lib/pages/my_page.dart lib/components/buttons/app_buttons.dart lib/pages/sync_overlay.dart lib/pages/app_shell_page.dart
flutter analyze lib/design_system/spec/visual_spec.dart lib/components/buttons/app_buttons.dart lib/pages/my_page.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/sync_overlay.dart lib/pages/app_shell_page.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/widget_test.dart
```

Result:

- `dart format`: passed
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests
- `flutter test test/widget_test.dart`: passed, 19 tests

## Manual QA Notes

Automated walkthrough, smoke, and widget coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- Progress indicator visual size is now centralized, so any future global adjustment affects button, sync overlay, my page, and app shell loading indicators together.
- Stage 06D brand/native asset consistency audit는 `test_report_20260529_stage_06d.md`에서 완료 기록했습니다.
