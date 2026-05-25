# Login Sync Overlay Layout Verification Test Plan

## Automated regression

Run:

```bash
flutter test test/sync_overlay_test.dart
```

Expected:

- Running, success, retry, and short-window overlay states render without clipping exceptions.
- The overlay exposes the centered modal container marker.

## Static verification

Run:

```bash
flutter analyze
```

Expected:

- No analyzer issues.

## Manual QA

1. Start login.
2. Wait for the data-fetching overlay.
3. Check normal and small-height device/window sizes.

Expected:

- The login screen behind the overlay is visibly dimmed.
- The data-fetching card appears centered, not attached to the bottom.
- Card content and buttons are not clipped.
- Short screens can scroll the modal content cleanly.
