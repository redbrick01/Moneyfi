-- 06 USD realized PnL currency-basis verification and rollback helper.
--
-- Intended use:
-- 1. Before applying 05, run only sections marked "Pre-05" or "Pre/post".
-- 2. Apply the migration only after reviewing the expected affected rows.
-- 3. After applying 05, run sections marked "Post-05" plus the "Pre/post"
--    sections again.
-- 4. Use the rollback templates only if the archived values prove that a
--    targeted restore is needed.
--
-- Sections 05, 07, and 08 reference archive tables created by the 05
-- migration. They are expected to fail before 05 has run.

-- 01. Pre-05 aggregate transaction performance by currency.
select
  coalesce(nullif(tl.currency_code, ''), 'KRW') as currency_code,
  count(*) filter (where tl.action = 'sell') as sell_rows,
  sum(case when tl.action = 'sell' then tl.gross_amount else 0 end) as sell_amount,
  sum(tl.realized_pnl) as realized_pnl
from public.transaction_lines tl
join public.transaction_events te
  on te.id = tl.event_id
where tl.deleted_at is null
  and te.deleted_at is null
  and te.source not in ('snapshot_restore', 'history_display')
group by coalesce(nullif(tl.currency_code, ''), 'KRW')
order by currency_code;

-- 02. Pre-05 candidate rows that the 05 migration is allowed to correct.
-- Expected SATL reference, if present:
-- gross_amount 285, quantity_sold 30, realized_pnl 186.225,
-- cost_basis_delta -140700, cost_basis_source_delta -98.775.
select
  te.id as event_id,
  te.occurred_at,
  te.title,
  tl.id as line_id,
  tl.holding_id,
  h.symbol,
  h.name as holding_name,
  tl.currency_code,
  abs(tl.quantity_delta) as quantity_sold,
  tl.gross_amount,
  tl.realized_pnl,
  tl.cost_basis_delta,
  tl.cost_basis_source_delta,
  tl.realized_pnl_source
from public.transaction_lines tl
join public.transaction_events te
  on te.id = tl.event_id
join public.holdings h
  on h.id = tl.holding_id
 and h.user_id = tl.user_id
where tl.deleted_at is null
  and te.deleted_at is null
  and tl.action = 'sell'
  and tl.currency_code = 'USD'
  and tl.realized_pnl_source = 'snapshot_anchor'
  and te.source not in ('snapshot_restore', 'history_display', 'record_only')
order by te.occurred_at, tl.id;

-- 03. Pre/post USD anomaly query.
-- This should be reviewed before and after migration. Rows remaining after
-- migration usually need manual realized PnL review or an additional seed.
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
join public.transaction_events te
  on te.id = tl.event_id
where tl.deleted_at is null
  and te.deleted_at is null
  and tl.action = 'sell'
  and tl.currency_code = 'USD'
  and abs(coalesce(tl.realized_pnl, 0)) >
      greatest(abs(coalesce(tl.gross_amount, 0)) * 10, 1000)
order by abs(tl.realized_pnl) desc;

-- 04. Pre/post zero-wipe verification.
-- Expected after the corrective migration: still_zero_but_snapshot_nonzero = 0.
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

-- 05. Post-05 archive and skipped-row review created by the 05 migration.
select
  count(*) as archived_transaction_lines
from recovery_archive.transaction_lines_before_usd_snapshot_anchor_fix_20260529;

select
  count(*) as archived_holdings
from recovery_archive.holdings_before_usd_snapshot_anchor_fix_20260529;

select
  skip_reason,
  count(*) as skipped_rows
from recovery_archive.usd_snapshot_anchor_fix_skipped_20260529
group by skip_reason
order by skip_reason;

-- 06. Post-05 asset metric purchase basis verification.
-- Asset purchase_krw should now be derivable from holdings.cost_basis_krw when
-- present, with quantity * average_price as the fallback.
select
  a.id as asset_id,
  a.title,
  a.purchase_krw as stored_purchase_krw,
  coalesce(sum(
    case
      when coalesce(h.cost_basis_krw, 0) > 0 then h.cost_basis_krw
      else h.quantity * h.average_price
    end
  ), 0) as expected_purchase_krw,
  a.purchase_krw - coalesce(sum(
    case
      when coalesce(h.cost_basis_krw, 0) > 0 then h.cost_basis_krw
      else h.quantity * h.average_price
    end
  ), 0) as purchase_krw_diff
from public.assets a
left join public.holdings h
  on h.asset_id = a.id
 and h.user_id = a.user_id
 and h.deleted_at is null
where a.deleted_at is null
group by a.id, a.title, a.purchase_krw
having abs(
  a.purchase_krw - coalesce(sum(
    case
      when coalesce(h.cost_basis_krw, 0) > 0 then h.cost_basis_krw
      else h.quantity * h.average_price
    end
  ), 0)
) > 0.000001
order by abs(
  a.purchase_krw - coalesce(sum(
    case
      when coalesce(h.cost_basis_krw, 0) > 0 then h.cost_basis_krw
      else h.quantity * h.average_price
    end
  ), 0)
) desc;

-- 07. Post-05 targeted rollback template for transaction lines.
-- Review archive rows first. Uncomment only when a targeted restore is needed.
/*
update public.transaction_lines tl
set
  quantity_delta = archive.quantity_delta,
  cash_delta = archive.cash_delta,
  unit_price = archive.unit_price,
  gross_amount = archive.gross_amount,
  fee_amount = archive.fee_amount,
  tax_amount = archive.tax_amount,
  cost_basis_delta = archive.cost_basis_delta,
  cost_basis_source_delta = archive.cost_basis_source_delta,
  realized_pnl = archive.realized_pnl,
  realized_pnl_source = archive.realized_pnl_source,
  fx_rate = archive.fx_rate,
  updated_at = now(),
  last_modified_at = now()
from recovery_archive.transaction_lines_before_usd_snapshot_anchor_fix_20260529 archive
where tl.id = archive.id;
*/

-- 08. Post-05 targeted rollback template for holding currency-basis fields.
-- This intentionally does not restore holding quantity. If holding quantity was
-- already damaged by a previous migration, use a separate snapshot-based
-- recovery plan.
/*
update public.holdings h
set
  average_price = archive.average_price,
  average_price_krw = archive.average_price_krw,
  average_price_source = archive.average_price_source,
  average_purchase_fx_rate = archive.average_purchase_fx_rate,
  cost_basis_krw = archive.cost_basis_krw,
  updated_at = now(),
  last_modified_at = now()
from recovery_archive.holdings_before_usd_snapshot_anchor_fix_20260529 archive
where h.id = archive.id;

select public.recompute_asset_metrics(null);
*/
