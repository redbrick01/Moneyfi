-- Cash is part of total assets, but it must not create valuation profit.
-- Previous snapshot generation mixed raw foreign-currency cash balances into
-- purchase amount and KRW-converted balances into valuation amount.

with cash_snapshot_items as (
  select
    i.id,
    i.snapshot_id
  from public.daily_portfolio_snapshot_items i
  join public.assets a on a.id = i.asset_id
  where (a.asset_type = '현금' or a.title = '현금')
    and abs(coalesce(i.profit_amount, 0)) > 0.0001
),
updated_cash_items as (
  update public.daily_portfolio_snapshot_items i
  set
    total_purchase_amount = i.total_valuation_amount,
    profit_amount = 0,
    profit_rate = 0
  from cash_snapshot_items c
  where i.id = c.id
  returning i.snapshot_id
),
affected_snapshots as (
  select distinct snapshot_id
  from updated_cash_items
),
snapshot_totals as (
  select
    i.snapshot_id,
    sum(i.total_purchase_amount) as total_purchase_amount,
    sum(i.total_valuation_amount) as total_valuation_amount
  from public.daily_portfolio_snapshot_items i
  join affected_snapshots a on a.snapshot_id = i.snapshot_id
  group by i.snapshot_id
)
update public.daily_portfolio_snapshots s
set
  total_purchase_amount = t.total_purchase_amount,
  total_valuation_amount = t.total_valuation_amount,
  profit_amount = t.total_valuation_amount - t.total_purchase_amount,
  profit_rate = case
    when t.total_purchase_amount = 0 then 0
    else ((t.total_valuation_amount - t.total_purchase_amount) /
      t.total_purchase_amount) * 100
  end
from snapshot_totals t
where s.id = t.snapshot_id;
