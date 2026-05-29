# Design Token Unification Test Report - Stage 06A

작성일: 2026-05-29

## Scope

Stage 06A app shell/navigation/sync overlay 잔여 토큰화.

Changed files:

- `lib/pages/app_shell_page.dart`

Rechecked files:

- `lib/pages/sync_overlay.dart`
- `lib/pages/login_page.dart`
- `lib/pages/signup_page.dart`

## Changes

- `app_shell_page.dart`의 account data replacement surface/padding/gap을 `context.colors`, `context.spacing`, `context.contentHorizontalPadding`으로 교체했습니다.
- floating tab bar의 surface, outline, pill radius, item padding, selected background, label style, icon size를 `context.colors`, `context.spacing`, `context.radius`, `context.typography`, `VisualSpec.icon`으로 교체했습니다.
- `sync_overlay.dart`, `login_page.dart`, `signup_page.dart`는 재스캔 결과 직접 legacy token 패턴이 없어 코드 변경하지 않았습니다.
- tab switching, polling, refresh, auth data replacement, scroll-to-top, analysis reselection, portfolio diagnosis focus 동작은 변경하지 않았습니다.

## Legacy Pattern Delta

Stage 06A scan:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|moneyfyValueColor|Color\\(0x|Colors\\.|fontSize:|const EdgeInsets|BorderRadius\\.circular\\(999|9999" lib/pages/app_shell_page.dart lib/pages/sync_overlay.dart lib/pages/login_page.dart lib/pages/signup_page.dart
```

Result: no matches.

## Verification

```bash
dart format lib/pages/app_shell_page.dart
flutter analyze lib/pages/app_shell_page.dart lib/pages/sync_overlay.dart lib/pages/login_page.dart lib/pages/signup_page.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result:

- `dart format`: passed
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests

## Manual QA Notes

Automated walkthrough and smoke coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- Floating tab bar label style now derives from app typography caption, so 기존 explicit `fontSize: 11`과 미세한 크기/line-height 차이가 있을 수 있습니다.
- Stage 06B portfolio/transaction/statistics 계열 정리는 `test_report_20260529_stage_06b.md`에서 완료 기록했습니다.
