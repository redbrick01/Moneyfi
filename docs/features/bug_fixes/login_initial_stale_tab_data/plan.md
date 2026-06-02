# Login Initial Stale Tab Data Plan

## Bug summary

After login, bottom-tab pages may first show stale/wrong local data until manual pull-refresh.

## User impact

User signs in, but first visible tab may show data from wrong account. Trust in account switch drops; pull-refresh feels mandatory after each login.

## Reproduction or evidence

- User report: after login, strange data appears first; pull-to-refresh shows correct data.
- Code evidence:
  - `LoginPage._handleLogin()` calls `AuthService.signIn()` before clearing local data and running post-login sync.
  - `AppShellPage` listens to auth events behind the login route and calls `refreshFromServer()` as soon as a signed-in auth state arrives.
  - Data tabs preserved in `IndexedStack`, so old state can render before post-login sync settles.
  - Prior logout fix already showed data tabs need explicit local-data lifecycle scope.

## Root cause hypothesis

No single lifecycle signal for "account data replacing" and "account data ready." Sign-in auth events, login cleanup, remote pull, and tab refresh race. Preserved tab state can show pre-sync/intermediate data.

## Fix strategy

- Add small app data lifecycle coordinator for local account-data replacement.
- Let `AppShellPage` listen to coordinator and:
  - replace data tabs with neutral loading/cleanup state while account data replacing;
  - recreate data-tab subtrees when account data ready;
  - increment refresh ticks so inactive tabs drop old futures/cached lists.
- Login starts account-data replacement before local DB cleanup; completes only after post-login sync succeeds and before login route pops.
- Keep logout on same coordinator-style path where possible.

## Non-goals

- No Supabase schema or Edge Function changes.
- No individual tab page rewrite.
- No account credentials/profile flow change.

## Regression test plan

- Add focused widget test for data-scoped tab wrapper: old preserved content hidden during account-data replacement; new scoped child renders afterward.
- Keep existing logout stale-tab regression.
- Run `flutter test test/page_walkthrough_test.dart`.
- Run `flutter analyze`.

## Risk and rollback notes

Risk mainly shell lifecycle state. Rollback: remove coordinator and scope-version changes; return to prior auth-event refresh behavior.