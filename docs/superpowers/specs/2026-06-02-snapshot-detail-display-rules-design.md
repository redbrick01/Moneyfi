# Snapshot Detail Display Rules Design

Date: 2026-06-02

## Goal

Make snapshot detail behavior consistent and read-only. Snapshot rows represent historical records and must not be mutated by detail-page interactions. The page should reflect the app's existing visibility settings while keeping remote snapshot data intact.

## Current Problems

- Snapshot detail currently exposes item-level delete behavior, which can remove child rows without recalculating parent item and snapshot totals.
- Cash is included in snapshot totals, but cash child rows store balances in their own currency, so display rules must be explicit.
- Hidden assets and holdings should affect what the user sees, but this should happen only at display time.

## Decisions

### Snapshot Meaning

- Total assets include investment assets and all cash-like assets.
- Cash contributes to total asset value.
- Cash does not contribute to investment profit or investment return-rate denominator.
- Investment profit is visible investment valuation minus visible investment purchase amount.
- Investment return rate is investment profit divided by visible investment purchase amount.

### Read-Only Snapshot Detail

- Snapshot detail is a read-only record screen.
- Detail-page interactions must not delete or mutate snapshot item, holding-item, or cash-account rows.
- Remote snapshot tables remain the source of historical truth.
- Existing app-level hidden states control what appears on the page.

### Visibility

- Snapshot detail must not add its own hide/unhide feature.
- If the user hid an asset group, asset, holding, or cash account elsewhere in the app, the snapshot detail page excludes the matching snapshot row.
- Hidden rows are excluded from visible header totals, visible asset-group totals, investment profit, and investment return rate.
- Hidden state is not stored in snapshot tables.

### Cash Placement

- Cash appears under its connected asset group.
- Examples:
  - Stock brokerage cash appears under the stock group.
  - Coin cash appears under the coin group.
  - Independent cash accounts appear under the cash group.
- Cash rows should display their original currency amount where appropriate, but their contribution to visible total assets must use the snapshot exchange rate.

## Data Flow

1. Load the original snapshot:
   - `daily_portfolio_snapshots`
   - `daily_portfolio_snapshot_items`
   - `daily_portfolio_snapshot_holding_items`
   - `daily_portfolio_snapshot_cash_accounts`
2. Load current app-visible assets, holdings, and cash accounts.
3. Build display rows by applying current visibility settings to the snapshot children.
4. Recompute visible item totals from visible child rows.
5. Recompute the header from visible item totals.
6. Render the page from the display rows.

The original snapshot totals remain available as historical stored values, but the page header uses visible rows so the numbers match what the user sees.

## Existing Code Treatment

Keep `lib/pages/snapshot_detail_page.dart` as the page. Do not create a replacement page.

Keep:
- Header card
- Asset-group list
- Expand/collapse behavior
- Holding and cash row presentation
- Previous/next snapshot navigation
- Snapshot notes, if currently supported

Remove from the page:
- Asset-group slide delete action
- Holding slide delete action
- Delete confirmation dialog used only for snapshot child deletion
- Calls to `deletePortfolioSnapshotItem`
- Calls to `deletePortfolioSnapshotHoldingItem`

Existing database delete methods may remain temporarily if other code or tests still reference them, but the snapshot detail page must not call them. If they are unused after implementation, remove them in the implementation plan.

## Empty State

If all snapshot rows are filtered out by current app visibility settings, show an empty state:

> 표시할 스냅샷 항목이 없습니다.

No extra hide-management controls are added to this page.

## Error Handling

- If current live asset or holding IDs no longer exist, matching should prefer stable client IDs when available.
- Historical rows that cannot be matched to a visible live entity should remain visible unless there is enough information to identify them as hidden.
- Invalid or missing exchange rates should fall back to existing app behavior, but tests should cover USD cash conversion when a valid snapshot exchange rate exists.

## Testing

Add or update focused tests for:

- Hidden asset groups do not appear in snapshot detail.
- Hidden holdings do not appear under their asset group.
- Hidden cash accounts do not appear under their asset group.
- Visible header total uses only visible investment valuation plus visible cash.
- Visible investment profit excludes cash.
- Visible investment return rate excludes cash from the denominator.
- Snapshot detail no longer exposes item or holding delete actions.
- Snapshot detail no longer calls snapshot child delete methods.

## Out Of Scope

- Remote DB schema changes.
- Remote snapshot data mutation.
- Snapshot detail-specific hide/unhide controls.
- Persistent local snapshot-specific hide settings.
- Production cleanup of test-looking snapshot data.
- Backfilling old cash account client IDs.
