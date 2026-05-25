# Login Initial Stale Tab Data Test Report 2026-05-25

## Summary

Fixed the first post-login render showing stale or incorrect bottom-tab data until pull-to-refresh.

## Reproduction status

Code-path reproduction was confirmed:

- `LoginPage` signs in, then clears local data, then pulls remote data.
- `AppShellPage` receives the signed-in auth event behind the login route and can refresh/rebuild preserved tabs while login sync is still in progress.
- Preserved `IndexedStack` tab state can therefore render pre-sync or intermediate local data.

## Root cause

The app lacked an account-data replacement lifecycle. Auth state, local DB cleanup, remote pull, and tab refresh were coordinated only indirectly through auth events and refresh ticks.

## Fix summary

- Added `AppDataLifecycleService` with a replacement state and version.
- `LoginPage` begins account-data replacement before sign-in can trigger shell refresh work, and completes replacement only after login sync is ready to enter the app.
- `AppShellPage` listens to replacement lifecycle changes, hides data tabs behind a neutral progress state while data is being replaced, increments refresh ticks, and recreates data-tab subtrees when ready.
- Added a regression test for login replacement hiding preserved tab data until the new scope is ready.

## Commands run

```bash
dart format lib/services/app_data_lifecycle_service.dart lib/pages/login_page.dart lib/pages/app_shell_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
```

## Command results

- Page walkthrough test suite: passed, 18 tests.
- `flutter analyze`: passed with no issues.

## Regression coverage

The new login replacement widget regression verifies that preserved old content is hidden during login account-data replacement and that a new scoped child renders afterward. Existing logout stale-data regression remains covered in the same test file.

## Manual QA status

Not run on a physical device in this session. Manual QA should log in as a different account and inspect every data tab immediately after the sync overlay finishes without pull-to-refresh.

## Remaining risk

If core data sync fails and the user remains on the login screen, the data tabs behind the route remain in replacement state to avoid showing stale data. This is intentional but should be revisited if a cancel/back flow is added to the login sync overlay.

## Final result

Login now gates visible data tabs behind the account-data replacement lifecycle and recreates them only after login data is ready, so pull-to-refresh is no longer needed to correct the first post-login view.
