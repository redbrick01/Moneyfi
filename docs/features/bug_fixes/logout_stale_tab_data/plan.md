# Logout Stale Tab Data Plan

## Bug summary

After sign out, bottom tabs can still show old account portfolio data until user pull-refresh.

## User impact

Signed-out user may see stale assets, summaries, analysis, stats from previous account. Confusing. Data exposure risk on same device account switch.

## Reproduction or evidence

- User report: after logout, each tab still shows previous account data; clears only after pull-to-refresh.
- Code evidence: `AppShellPage` keeps tab pages alive inside an `IndexedStack`. Sign-out handler clears local DB/cache and increments `dataRefreshTick`, but child pages keep in-memory `FutureBuilder` snapshots, cached lists, controllers, module-level dashboard cache until reload.
- `PortfolioDashboardPage` also has `_dashboardSharedDataCache` and child widgets retain old `_items` while background reload runs.

## Root cause hypothesis

Local DB clears on sign-out, but tab subtree not scoped to auth/local-data lifecycle. `IndexedStack` preserves tab state, so stale widget state outlives signed-out local store and stays visible until manual refresh forces deeper reload.

## Fix strategy

- Add auth data scope version to `AppShellPage`.
- When sign-out starts, immediately enter local-data-clearing state so portfolio tabs show neutral clearing screen, not stale content.
- After local DB and market cache clear, increment scope version and refresh tick so all data tabs recreate with fresh keys.
- Reset tab-local transient state by keying bottom-tab children from scope version.
- Keep change inside shell/auth transition handling; no page internals refactor.

## Non-goals

- No Supabase schema, sync protocol, or remote data changes.
- No tab page or data-loading component redesign.
- No login form behavior change beyond safer account-transition state.

## Regression test plan

- Add focused widget test for data-scoped tab wrapper used by `AppShellPage`.
- Render preserved old-account content, switch wrapper to signed-out cleanup mode, verify old content disappears immediately.
- Switch to new data scope, verify old child does not carry over.
- Run targeted widget test and `flutter analyze`.

## Risk and rollback notes

Risk limited to `AppShellPage` lifecycle behavior. If regression appears, rollback shell scope-key and clearing-screen changes; page-level data loaders return to previous pull-to-refresh behavior.