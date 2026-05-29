# Cash Snapshot Profit Fix Report

Date: 2026-05-24

## Summary

Cash must contribute to total assets, but it must not create valuation profit.
The snapshot generator previously mixed raw foreign-currency cash balances into
purchase amount and KRW-converted cash balances into valuation amount. This made
cash produce artificial profit.

The issue has been fixed in both places:

- Future snapshots: `create-portfolio-snapshot` now uses KRW-converted cash
  value for both purchase and valuation.
- Existing snapshots: historical cash snapshot items were normalized and
  snapshot headers were recalculated from item totals.

## Root Cause

For foreign-currency cash, previous snapshot logic effectively did this:

```text
purchase = KRW cash + raw USD cash
valuation = KRW cash + (USD cash * exchange rate)
profit = valuation - purchase
```

For the latest affected remote snapshot, this produced:

```text
snapshot id: 116
cash purchase: 400,556.7
cash valuation: 1,245,627.3
cash profit: 845,070.6
```

The correct policy is:

```text
cash purchase = KRW-converted cash balance
cash valuation = KRW-converted cash balance
cash profit = 0
cash profit rate = 0
```

This policy is now documented as a standing rule in
`docs/data_and_sync.md#snapshot-calculation-rules`.

## Changes Applied

### Edge Function

Updated `supabase/functions/create-portfolio-snapshot/index.ts` so cash account
balances are converted to KRW once and added to both purchase and valuation.

The same function also keeps these dashboard-aligned filters:

- Exclude hidden assets.
- Exclude hidden holdings.
- Exclude zero-quantity holdings.
- Exclude hidden cash accounts.
- Do not fall back to asset display value when an asset has only hidden or
  closed child rows.

The function was deployed to Supabase project `oeweumxfabobwlhzrzqk`.

### Remote Database

Applied migrations:

- `20260524093000_fix_cash_snapshot_profit.sql`
- `20260524094000_recalculate_snapshot_totals_after_cash_fix.sql`

The first migration normalized cash snapshot items. The second migration
recalculated snapshot headers from item totals to remove item/header drift.

### Local App Database

The local SQLite database used by the app was also normalized so the app can
display corrected values immediately.

Backup:

```text
/private/tmp/moneyfy_before_cash_snapshot_fix.sqlite
```

## Verification

### Remote DB Before Fix

```text
affected cash snapshot count: 68
first affected date: 2026-03-17
last affected date: 2026-05-23
min cash profit: 482,870.56
max cash profit: 1,201,280.4
sum cash profit: 47,372,716.744
```

### Remote DB After Fix

```text
cash_error_count: 0
header_mismatch_count: 0
```

Latest remote snapshot after fix:

```text
snapshot id: 116
snapshot_date: 2026-05-23
cash purchase: 1,245,627.3
cash valuation: 1,245,627.3
cash profit: 0
total_purchase_amount: 35,057,672.2552963
total_valuation_amount: 63,934,962.6883604
profit_amount: 28,877,290.4330642
profit_rate: 82.3708152177776
```

### Local DB After Fix

```text
cash_error_count: 0
header_mismatch_count: 0
```

Latest local snapshot after fix:

```text
snapshot id: 14158
snapshot_date: 2026-05-22
cash purchase: 1,245,627.3
cash valuation: 1,245,627.3
cash profit: 0
total_purchase_amount: 35,057,672.2552963
total_valuation_amount: 63,922,089.5214465
profit_amount: 28,864,417.2661502
profit_rate: 82.3340952472666
```

## Test Results

```text
deno check supabase/functions/create-portfolio-snapshot/index.ts
Result: passed

flutter analyze
Result: passed, no issues found

flutter test
Result: passed, 78 tests
```

## Notes

The first remote migration corrected cash item rows, but the immediate
verification caught that snapshot headers still needed recalculation. A follow-up
header recalculation migration was applied, and both remote and local databases
now verify cleanly.
