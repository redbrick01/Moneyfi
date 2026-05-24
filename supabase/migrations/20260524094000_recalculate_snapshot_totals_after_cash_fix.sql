-- Recalculate snapshot headers after normalizing cash snapshot items.
-- This also makes headers resilient to any previous item/header drift.

with snapshot_totals as (
  select
    snapshot_id,
    sum(total_purchase_amount) as total_purchase_amount,
    sum(total_valuation_amount) as total_valuation_amount
  from public.daily_portfolio_snapshot_items
  group by snapshot_id
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
where s.id = t.snapshot_id
  and (
    abs(s.total_purchase_amount - t.total_purchase_amount) > 0.01
    or abs(s.total_valuation_amount - t.total_valuation_amount) > 0.01
    or abs(s.profit_amount - (t.total_valuation_amount -
      t.total_purchase_amount)) > 0.01
  );
