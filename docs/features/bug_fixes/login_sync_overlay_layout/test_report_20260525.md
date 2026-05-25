# Login Sync Overlay Layout Test Report 2026-05-25

## Summary

Fixed the login data-fetching overlay so it dims the login screen and presents a centered modal card instead of a clipped bottom card.

## Reproduction status

Code-path reproduction was confirmed from `SyncOverlay`:

- The overlay used a bottom-aligned card with `SafeArea(top: false)`.
- The card used internal scrolling with a height constraint, which could create awkward vertical balance and clipped-looking content on short screens.

The user-provided screenshot file path was not readable in this session.

## Root cause

The login sync UI was implemented as a bottom sheet, but the desired login state is a modal progress overlay. Bottom alignment and constrained internal scrolling caused the visual mismatch.

## Fix summary

- Increased the scrim opacity so the login screen behind the overlay is clearly dimmed.
- Replaced the bottom-aligned card with a centered modal card.
- Moved scrolling to the full overlay area so short screens can scroll the card instead of clipping internal content.
- Added a stable card key and updated widget tests for centered modal behavior and short-window rendering.

## Commands run

```bash
dart format lib/pages/sync_overlay.dart test/sync_overlay_test.dart
flutter test test/sync_overlay_test.dart
flutter analyze
flutter test test/page_walkthrough_test.dart
```

## Command results

- `test/sync_overlay_test.dart`: passed, 5 tests.
- `flutter analyze`: passed with no issues.
- `test/page_walkthrough_test.dart`: passed, 18 tests.

## Regression coverage

The overlay tests now verify the running sync state renders a centered modal card, short-window rendering does not throw or hide required content, and success/retry states still render.

## Manual QA status

Not run on a physical device in this session. Manual QA should confirm the actual login sync screen on device sizes similar to the provided screenshot.

## Remaining risk

Very small screens may require scrolling the modal card, but the full overlay area now scrolls to avoid clipped content.

## Final result

The login sync screen now dims the login page and displays the data-fetching card as a centered modal with balanced spacing.
