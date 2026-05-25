# Login Initial Stale Tab Data Plan

## Bug summary

After login, bottom-tab pages can initially show stale or incorrect local data until the user manually pulls to refresh.

## User impact

Users can sign in successfully but see data that does not match the signed-in account on the first visible tab render. This undermines trust in account switching and makes pull-to-refresh feel required after every login.

## Reproduction or evidence

- User report: after login, strange data appears first; pull-to-refresh shows the correct data.
- Code evidence:
  - `LoginPage._handleLogin()` calls `AuthService.signIn()` before clearing local data and running post-login sync.
  - `AppShellPage` listens to auth events behind the login route and calls `refreshFromServer()` as soon as a signed-in auth state arrives.
  - Data tabs are preserved in an `IndexedStack`, so their existing state can render before the post-login sync fully settles.
  - The prior logout fix already showed that data tabs need an explicit local-data lifecycle scope.

## Root cause hypothesis

The app does not have a single lifecycle signal for "account data is being replaced" and "account data is ready." Sign-in auth events, login-page cleanup, remote pull, and data-tab refresh can race, leaving preserved tab state visible with pre-sync or intermediate data.

## Fix strategy

- Add a small app data lifecycle coordinator for local account-data replacement.
- Let `AppShellPage` listen to this coordinator and:
  - replace data tabs with a neutral loading/cleanup state while account data is being replaced;
  - recreate data-tab subtrees when account data becomes ready;
  - increment refresh ticks so inactive tabs do not keep old futures or cached lists.
- Have login start the account-data replacement state before local DB cleanup and complete it only after post-login sync succeeds and before the login route pops.
- Keep existing logout behavior on the same coordinator-style path where possible.

## Non-goals

- No Supabase schema or Edge Function changes.
- No rewrite of individual tab pages.
- No change to account credentials or profile flows.

## Regression test plan

- Add a focused widget test for the data-scoped tab wrapper that verifies preserved old content is hidden during account-data replacement and a new scoped child renders afterward.
- Keep the existing logout stale-tab regression.
- Run `flutter test test/page_walkthrough_test.dart`.
- Run `flutter analyze`.

## Risk and rollback notes

Risk is concentrated in shell lifecycle state. If needed, rollback the coordinator and scope-version changes to return to the previous auth-event refresh behavior.
