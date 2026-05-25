# Logout Stale Tab Data Verification Test Plan

## Automated regression

Run:

```bash
flutter test test/page_walkthrough_test.dart
```

Expected:

- The new logout stale-data regression test passes.
- Existing page walkthrough smoke tests still pass.

## Static verification

Run:

```bash
flutter analyze
```

Expected:

- No analyzer errors or warnings from the shell lifecycle changes.

## Manual QA

1. Log in with an account that has portfolio data.
2. Visit Home, Portfolio, Analysis, and Statistics tabs.
3. Open My tab and log out.
4. Immediately visit each data tab.

Expected:

- Previous account assets, summaries, analysis entries backed by local data, and statistics are not shown after logout.
- During local cleanup, data tabs show a neutral clearing state instead of stale values.
- Pull-to-refresh is not required to clear old data.
