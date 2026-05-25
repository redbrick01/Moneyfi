# Login Sync Overlay Layout Plan

## Bug summary

The data-fetching screen shown during login sync appears as a clipped bottom card with awkward vertical spacing. The requested behavior is a dimmed login screen with a centered data-fetching card above it.

## User impact

During login, users see a visually broken transition state. The card can look cut off and the bottom-sheet placement makes the login screen feel unfinished instead of intentionally blocked while data loads.

## Reproduction or evidence

- User report: login data-fetching card is clipped and has awkward top/bottom spacing.
- Screenshot path was provided but was not readable in this session.
- Code evidence: `SyncOverlay` currently uses `Align(alignment: Alignment.bottomCenter)` with `SafeArea(top: false)` and an internal `SingleChildScrollView`. This creates a bottom-sheet layout over a translucent scrim, not a centered modal over a dimmed login page.

## Root cause hypothesis

The overlay is designed as a bottom sheet. On login, the intended UI is modal-like, so bottom alignment plus constrained internal scrolling produces poor vertical balance and can make the card appear clipped.

## Fix strategy

- Convert `SyncOverlay` to a centered modal card over a darker scrim.
- Preserve scrollability for short windows by making the full overlay area scrollable with centered content and bounded card width.
- Keep button/error/progress behavior unchanged.
- Add widget coverage that verifies the overlay still renders on short windows and exposes a centered modal semantics marker.

## Non-goals

- No change to login sync order or sync business logic.
- No redesign of the login form itself.
- No platform-specific layout branching.

## Regression test plan

- Update `test/sync_overlay_test.dart` to reflect centered modal behavior.
- Keep the short-window test to ensure the card does not clip.
- Run `flutter test test/sync_overlay_test.dart`.
- Run `flutter analyze`.

## Risk and rollback notes

Risk is limited to the shared `SyncOverlay` component. If the new centered modal causes unexpected UX issues, rollback the layout to the previous bottom-aligned card while keeping tests as guidance for non-clipping behavior.
