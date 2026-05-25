# Logout Stale Tab Data Plan

## Bug summary

After signing out, bottom-tab pages can keep rendering the previous account's portfolio data until the user manually pulls to refresh.

## User impact

Signed-out users can briefly or persistently see stale assets, summaries, analysis, and statistics from the previous account. This is confusing and risks exposing data across account transitions on the same device.

## Reproduction or evidence

- User report: after logout, each tab still shows previous account data and only clears after pull-to-refresh.
- Code evidence: `AppShellPage` keeps tab pages alive inside an `IndexedStack`. The sign-out handler clears local DB/cache and increments `dataRefreshTick`, but child pages keep their in-memory `FutureBuilder` snapshots, cached lists, controllers, and module-level dashboard cache until they choose to reload.
- `PortfolioDashboardPage` also has `_dashboardSharedDataCache` and child widgets that retain previous `_items` while a background reload runs.

## Root cause hypothesis

The local database is cleared on sign-out, but the tab subtree is not scoped to the auth/local-data lifecycle. Because `IndexedStack` preserves each tab state, stale widget state can outlive the signed-out local store and remain visible until a manual refresh forces a deeper reload.

## Fix strategy

- Add an auth data scope version to `AppShellPage`.
- When sign-out starts, immediately enter a local-data-clearing state so portfolio tabs render a neutral clearing screen instead of stale content.
- After local DB and market cache are cleared, increment the scope version and refresh tick so all data tabs are recreated with fresh keys.
- Reset tab-local transient state by keying the bottom-tab children from the scope version.
- Keep the change inside shell/auth transition handling; do not refactor page internals.

## Non-goals

- No Supabase schema, sync protocol, or remote data changes.
- No redesign of tab pages or data-loading components.
- No change to login form behavior beyond safer account-transition state.

## Regression test plan

- Add a focused widget test for the data-scoped tab wrapper used by `AppShellPage`.
- Render preserved old-account content, switch the wrapper into signed-out cleanup mode, and verify the old content disappears immediately.
- Switch to a new data scope and verify the old child does not carry over.
- Run targeted widget test and `flutter analyze`.

## Risk and rollback notes

Risk is limited to `AppShellPage` lifecycle behavior. If a regression appears, rollback the shell scope-key and clearing-screen changes; page-level data loaders will return to previous pull-to-refresh behavior.
