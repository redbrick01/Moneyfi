# Login Initial Stale Tab Data Verification Test Plan

## Automated regression

Run:

```bash
flutter test test/page_walkthrough_test.dart
```

Expected:

- Logout stale-data regression still passes.
- New login account-data replacement regression passes.
- Existing page walkthrough smoke tests still pass.

## Static verification

Run:

```bash
flutter analyze
```

Expected:

- No analyzer issues.

## Manual QA

1. Start with an existing visible dataset from account A.
2. Log out.
3. Log in as account B.
4. Let the login sync overlay complete.
5. Immediately inspect Home, Portfolio, Analysis, and Statistics without pulling to refresh.

Expected:

- Data tabs do not show account A data or an intermediate empty/incorrect state after account B login completes.
- Correct account B data is visible without pull-to-refresh.
- During replacement, tabs show a neutral progress state if visible behind the login flow.
