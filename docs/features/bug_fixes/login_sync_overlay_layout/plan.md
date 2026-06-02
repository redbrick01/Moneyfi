# Login Sync Overlay Layout Plan

## Bug summary

Login sync data-fetch screen shows clipped bottom card, bad vertical spacing. Wanted: dimmed login screen, centered data-fetch card above.

## User impact

During login, users see broken transition. Card can look cut off. Bottom-sheet placement makes login screen feel unfinished, not intentionally blocked while data loads.

## Reproduction or evidence

- User report: login data-fetching card clipped, awkward top/bottom spacing.
- Screenshot path provided, not readable in this session.
- Code evidence: `SyncOverlay` uses `Align(alignment: Alignment.bottomCenter)` with `SafeArea(top: false)` and internal `SingleChildScrollView`. This makes bottom-sheet layout over translucent scrim, not centered modal over dimmed login page.

## Root cause hypothesis

Overlay built as bottom sheet. Login wants modal-like UI, so bottom align + constrained internal scroll gives bad vertical balance and can make card look clipped.

## Fix strategy

- Change `SyncOverlay` to centered modal card over darker scrim.
- Preserve short-window scroll: make full overlay scrollable, center content, bound card width.
- Keep button/error/progress behavior same.
- Add widget test: overlay renders on short windows and exposes centered modal semantics marker.

## Non-goals

- No login sync order or sync business logic change.
- No login form redesign.
- No platform-specific layout branching.

## Regression test plan

- Update `test/sync_overlay_test.dart` for centered modal behavior.
- Keep short-window test so card does not clip.
- Run `flutter test test/sync_overlay_test.dart`.
- Run `flutter analyze`.

## Risk and rollback notes

Risk limited to shared `SyncOverlay`. If centered modal causes UX issues, roll back layout to previous bottom-aligned card while keeping tests as guide for non-clipping behavior.