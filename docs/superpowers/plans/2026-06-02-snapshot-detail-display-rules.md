# Snapshot Detail Display Rules Implementation Plan

> Note: `superpowers:writing-plans` was requested by the brainstorming flow, but that skill is not available in this session. This plan follows the existing `docs/superpowers/plans` format.

**Goal:** Make the snapshot detail page read-only, remove detail-page child deletion behavior, and calculate visible totals from current app visibility settings.

**Design Source:** `docs/superpowers/specs/2026-06-02-snapshot-detail-display-rules-design.md`

**Tech Stack:** Flutter, Dart, Drift SQLite, `flutter_test`.

**Core Decisions:**

- Snapshot detail is a read-only historical record screen.
- Snapshot detail does not provide its own hide or unhide controls.
- Existing app-level hidden asset, holding, and cash-account state controls what appears.
- Visible totals are based on visible rows only.
- Total assets include visible investment valuation plus visible cash.
- Investment profit and return rate exclude cash.
- Snapshot child rows are not deleted from the detail page.

## File Structure

- Modify `lib/pages/snapshot_detail_page.dart`
  - Remove child delete UI and state methods.
  - Render holding rows as normal read-only rows, not slidable delete rows.
  - Keep page navigation, expansion, notes, and section structure.
  - Calculate header and item values from visible holding and cash rows.
- Modify `lib/db/app_database.dart`
  - Keep existing snapshot child delete methods only if still referenced.
  - Prefer removing methods if no production code or tests use them after page cleanup.
  - Reuse existing visibility-aware snapshot retrieval helpers where practical.
- Modify or add tests under `test/`
  - Cover hidden assets, hidden holdings, hidden cash accounts, visible totals, and read-only UI behavior.

## Task 1: Lock Existing Behavior With Focused Tests

**Files:**

- Modify: `test/page_walkthrough_test.dart` or create a focused snapshot detail widget test.
- Modify: `test/transaction_flow_test.dart` only if DB helper behavior needs fixture coverage.

- [ ] Add a widget test that opens `SnapshotDetailPage` with one visible asset and one hidden asset.
- [ ] Assert the hidden asset title is not rendered.
- [ ] Assert the visible asset title is rendered.
- [ ] Add a test where one holding under a visible asset is hidden.
- [ ] Assert the hidden holding name is not rendered.
- [ ] Add a test where one cash account under a visible asset is hidden.
- [ ] Assert the hidden cash account name is not rendered.
- [ ] Add a test that no delete affordance is present for snapshot asset and holding rows.

Expected failing points before implementation:

- Slidable delete actions may still exist.
- Holding delete actions may still exist.
- Header totals may still use item-level stored totals instead of visible child totals.

## Task 2: Remove Snapshot Detail Child Deletion

**Files:**

- Modify: `lib/pages/snapshot_detail_page.dart`
- Optionally modify: `lib/db/app_database.dart`

- [ ] Remove `_confirmDelete` if it is only used for snapshot child deletion.
- [ ] Remove `_deleteSnapshotItem`.
- [ ] Remove `_deleteSnapshotHoldingItem`.
- [ ] Remove calls to `AppDatabase.instance.deletePortfolioSnapshotItem`.
- [ ] Remove calls to `AppDatabase.instance.deletePortfolioSnapshotHoldingItem`.
- [ ] Replace slidable asset and holding rows with read-only rows.
- [ ] Keep expansion and visual layout unchanged where possible.
- [ ] Run analyzer on `lib/pages/snapshot_detail_page.dart`.

If `deletePortfolioSnapshotItem` and `deletePortfolioSnapshotHoldingItem` become unused:

- [ ] Remove them from `lib/db/app_database.dart`.
- [ ] Remove any tests that only verify child-row mutation from snapshot detail behavior.

If they are still used outside snapshot detail:

- [ ] Leave them in place.
- [ ] Add a short comment or test coverage only if needed to prevent accidental page re-use.

## Task 3: Build Visible Snapshot Calculation

**Files:**

- Modify: `lib/pages/snapshot_detail_page.dart`
- Consider extracting a small private helper in the same file first.

- [ ] Group visible holding rows by snapshot asset key.
- [ ] Group visible cash rows by snapshot asset key.
- [ ] For each visible item, recompute display purchase amount from visible holdings only.
- [ ] For each visible item, recompute display valuation amount from visible holdings plus visible cash converted to KRW with the snapshot exchange rate.
- [ ] For each visible item, recompute display profit amount from visible holdings only.
- [ ] For each visible item, recompute display profit rate from visible holding purchase amount.
- [ ] Exclude items that have no visible holdings and no visible cash rows.
- [ ] Recompute header total value from visible item display values.
- [ ] Recompute header purchase amount from visible investment purchase amount only.
- [ ] Recompute previous comparison values using the same visibility rules when previous snapshot rows are available.

Implementation note:

- Cash child rows store their own currency balance.
- USD cash must be converted to KRW with the current snapshot's `exchangeRate` for total value.
- KRW cash uses its balance as KRW.
- Cash contributes to total valuation and total assets, but not profit or profit-rate denominator.

## Task 4: Preserve Existing Page UX

**Files:**

- Modify: `lib/pages/snapshot_detail_page.dart`

- [ ] Keep current header style.
- [ ] Keep section and row styling.
- [ ] Keep previous and next snapshot navigation.
- [ ] Keep snapshot notes if currently active.
- [ ] Keep empty state, but ensure it appears when all rows are filtered out by app visibility settings.
- [ ] Avoid adding new controls for snapshot-specific hide or unhide.

## Task 5: Test Visible Totals

**Files:**

- Modify or create focused tests under `test/`.

- [ ] Test visible total asset value includes visible cash.
- [ ] Test visible investment profit excludes cash.
- [ ] Test visible return-rate denominator excludes cash.
- [ ] Test USD cash uses snapshot exchange rate for total asset value.
- [ ] Test hiding all child rows under an item removes that item from the list.
- [ ] Test hiding all items shows the empty state.

## Task 6: Regression Checks

**Commands:**

- [ ] `flutter analyze lib/pages/snapshot_detail_page.dart`
- [ ] Run focused widget tests for snapshot detail.
- [ ] Run focused DB/transaction-flow tests if DB helper removal changes compile surface.
- [ ] Run broader `flutter test` only if focused changes touch shared DB models or generated code.

## Risks

- Existing snapshot item rows may include historical fallback values that do not have matching child rows. The implementation should keep unmatched historical rows visible unless they are clearly hidden by current app visibility state.
- Current hidden-state matching may rely on local IDs. Prefer stable client IDs where available so imported snapshots continue to match after sync.
- Previous-snapshot comparisons must use the same visibility rules as current rows, or the comparison can mix visible current rows with hidden previous rows.

## Completion Criteria

- Snapshot detail page has no child delete UI.
- Snapshot detail page performs no child-row delete DB calls.
- Hidden app-level assets, holdings, and cash accounts are excluded from display.
- Visible header and item totals match visible rows.
- Cash appears under its connected asset group and is included only in total asset value.
- Focused tests pass.
