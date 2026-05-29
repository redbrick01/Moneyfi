# Verification And Rollback

## Unit / DB Tests

Required tests:

- USD seeded sell:
  - `averagePriceKrw = 4,690 KRW`
  - `averagePriceSource = 3.2925 USD`
  - `averagePurchaseFxRate = 1,424.449506`
  - `costBasisKrw = 234,500`
  - Sell `30 * 9.5 USD`
  - Expected `realized_pnl = 186.225 USD`
  - Expected `cost_basis_delta = -140,700 KRW`
  - Expected `cost_basis_source_delta = -98.775 USD`

- Existing seed backfill:
  - All six user-provided USD seed holdings are backfilled.
  - Seeded holdings without affected sell lines still receive `average_price_source`, `average_price_krw`, `average_purchase_fx_rate`, and `cost_basis_krw`.
  - No seed backfill changes `quantity` or `current_price`.

- USD buy with trade FX:
  - First buy `$10 * 10`, FX `1,400`
  - Second buy `$20 * 10`, FX `1,500`
  - Expected source avg `$15`
  - Expected KRW avg `₩22,000`
  - Expected average buy FX `1,466.6667`
  - Each buy line stores its own `fx_rate`

- USD manual sell:
  - User input realized PnL is USD.
  - `realized_pnl_source = 'manual'`.
  - `cost_basis_delta` uses KRW average.
  - `cost_basis_source_delta` uses source-currency relation.

- Unseeded USD sell:
  - Automatic correction is skipped.
  - Row appears in anomaly/review output.
  - No holding average or quantity is changed.

- KRW sell:
  - Existing same-currency `cost_basis_delta = -(gross_amount - realized_pnl)` behavior remains.

- Sync:
  - New holdings and transaction line fields survive push/pull.

Run:

```bash
flutter test test/transaction_flow_test.dart
flutter test test/widget_test.dart
flutter analyze
git diff --check
```

## SQL Verification

Aggregate before/after:

```sql
select
  coalesce(nullif(tl.currency_code, ''), 'KRW') as currency_code,
  count(*) filter (where tl.action = 'sell') as sell_rows,
  sum(case when tl.action = 'sell' then tl.gross_amount else 0 end) as sell_amount,
  sum(tl.realized_pnl) as realized_pnl
from public.transaction_lines tl
join public.transaction_events te on te.id = tl.event_id
where tl.deleted_at is null
  and te.deleted_at is null
  and te.source not in ('snapshot_restore', 'history_display')
group by coalesce(nullif(tl.currency_code, ''), 'KRW');
```

USD anomaly query:

```sql
select
  te.id as event_id,
  te.occurred_at,
  te.title,
  tl.id as line_id,
  tl.currency_code,
  tl.gross_amount,
  tl.realized_pnl,
  tl.realized_pnl_source
from public.transaction_lines tl
join public.transaction_events te on te.id = tl.event_id
where tl.deleted_at is null
  and te.deleted_at is null
  and tl.action = 'sell'
  and tl.currency_code = 'USD'
  and abs(coalesce(tl.realized_pnl, 0)) > greatest(abs(coalesce(tl.gross_amount, 0)) * 10, 1000)
order by abs(tl.realized_pnl) desc;
```

Zero-wipe verification:

```sql
with latest as (
  select id
  from public.daily_portfolio_snapshots
  order by snapshot_date desc, created_at desc, id desc
  limit 1
)
select count(*) as still_zero_but_snapshot_nonzero
from public.holdings h
join latest l on true
join public.daily_portfolio_snapshot_holding_items shi
  on shi.snapshot_id = l.id
 and shi.user_id = h.user_id
 and (
   shi.holding_client_id = h.client_id
   or (shi.holding_client_id is null and shi.holding_id = h.id)
 )
where h.deleted_at is null
  and abs(coalesce(h.quantity, 0)) <= 0.0000001
  and coalesce(shi.quantity, 0) > 0.0000001;
```

Expected:

- `still_zero_but_snapshot_nonzero = 0`

## Rollback

- Corrective migration must archive affected `transaction_lines` before update.
- Corrective migration must archive all seed holdings and affected sell-line holdings before update.
- Do not use broad PITR unless the archive restore fails.
- If remote values look wrong, restore affected rows from the archive table.

## Open Questions

- Should USD sell KRW reporting use sell-date `fx_rate` when present instead of latest display FX?
- Should `average_purchase_fx_rate` be editable in holding form, or only derived from buys/snapshots?
- Should `average_price_source` be displayed in holding detail immediately, or remain internal until UX redesign?
