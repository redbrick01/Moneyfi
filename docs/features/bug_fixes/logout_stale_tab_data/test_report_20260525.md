# Logout Stale Tab Data Test Report 2026-05-25

## Summary

Fixed stale previous-account data remaining visible in bottom-tab pages after logout.

## Reproduction status

Code-path reproduction was confirmed from the shell/page lifecycle:

- `AppShellPage` preserves Home, Portfolio, Analysis, and Statistics in an `IndexedStack`.
- Logout cleared local DB/cache, but preserved child page state could continue rendering old `FutureBuilder` snapshots, cached lists, and tab-local state until refresh.

## Root cause

The bottom-tab subtree was not scoped to auth/local-data lifecycle changes. Clearing the local store alone did not immediately invalidate preserved tab widget state.

## Fix summary

- Added a data-scope version in `AppShellPage`.
- On signed-out auth state, data tabs immediately switch to a neutral cleanup screen.
- After local DB and market cache cleanup completes, the data-scope version changes again so data tabs are recreated from clean state.
- Added a focused widget regression for the data-scoped tab wrapper.

## Commands run

```bash
dart format lib/pages/app_shell_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart --plain-name "logout clears preserved tab data before manual refresh"
flutter test test/page_walkthrough_test.dart
flutter analyze
```

## Command results

- Targeted logout stale-data regression: passed.
- Page walkthrough test suite: passed, 17 tests.
- `flutter analyze`: passed with no issues.

## Regression coverage

The new widget test verifies that a preserved child containing old account content is hidden while signed-out cleanup is active, and a new scoped child can render afterward without carrying the old content.

## Manual QA status

Not run on a physical device in this session. Manual QA should verify logging out from My and immediately visiting Home, Portfolio, Analysis, and Statistics without pull-to-refresh.

## Remaining risk

The cleanup screen appears only while local cleanup is in progress. If a page outside the bottom-tab data tabs keeps a detail route open during logout, that route is outside this fix scope.

## Final result

Logout now invalidates preserved data-tab UI state and prevents previous account data from staying visible until manual refresh.
