# Snapshot Detail Holding Rows Fix

## Summary

Snapshot detail pages can show asset-class summary rows without the underlying holding rows when older or remotely synced snapshots do not have usable local holding identifiers.

## Root Cause

The detail page used current local holding visibility and strict asset-id matching to decide which snapshot holding rows to render. That made valid snapshot details disappear when:

- snapshot holding rows were imported with remapped, missing, or stale holding ids;
- rows only matched by asset title;
- older snapshots had asset summary rows but no saved holding detail rows.

## Fix

`SnapshotDetailPage` now:

- loads display snapshot summary rows for visible asset classes;
- loads stored snapshot holding rows by date and filters only by visible asset class;
- matches holding and cash rows by both asset id and normalized asset title;
- falls back to current visible investment holdings when a snapshot asset row has no stored holding rows.

Stored snapshot holding rows still take priority, so historical detail remains unchanged when data exists.

## Verification

- `flutter analyze lib/pages/snapshot_detail_page.dart`
- `flutter test test/transaction_flow_test.dart`
