# Transactions Load More Design

## Goal

Make the transactions page easier to scan by grouping visible rows into month periods that start on the 20th and showing older periods only when the user taps a load-more button.

## Design

The page keeps the current data loading, search, filter, and sort behavior. After those rules produce `visibleEntries`, the screen renders only the latest 20th-based period. Each tap on the load-more button reveals one older period.

Rows are grouped by the statement-style period that runs from the 20th of one month through the 19th of the next month. For example, transactions from 2026-06-20 through 2026-07-19 appear under `2026년 6월 20일 ~ 7월 19일`. The list stays inside the existing `SectionCard` so the visual style remains consistent with the rest of the app.

Changing search text, period, category, quick filter, sort mode, refresh tick, or reloading data resets the visible period count to the latest period. This keeps new result sets predictable.

## Testing

Add a widget test that injects test assets into `TransactionsPage`, verifies that only the latest 20th-based period appears, taps the load-more button, and verifies that the next older period becomes visible.
