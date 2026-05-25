-- Keep current portfolio state independent from record-only history rows.
--
-- Record-only rows are still valid transaction history and remain available to
-- analysis and snapshot views, but state tables must mirror calculation-ready
-- ledger lines only.

with active_holding_ledger as (
  select
    h.id as holding_id,
    coalesce(
      sum(case when te.id is null then 0 else tl.quantity_delta end),
      0
    )::double precision as quantity,
    coalesce(
      sum(case when te.id is null then 0 else tl.cost_basis_delta end),
      0
    )::double precision as cost_basis
  from public.holdings h
  left join public.transaction_lines tl
    on tl.holding_id = h.id
   and tl.deleted_at is null
  left join public.transaction_events te
    on te.id = tl.event_id
   and te.deleted_at is null
   and te.source not in ('history_display', 'record_only')
  where h.deleted_at is null
  group by h.id
),
computed_holdings as (
  select
    holding_id,
    case
      when abs(quantity) <= 0.0000001 then 0::double precision
      else quantity
    end as quantity,
    case
      when abs(quantity) <= 0.0000001 then 0::double precision
      else greatest(cost_basis / quantity, 0)::double precision
    end as average_price
  from active_holding_ledger
)
update public.holdings h
set
  quantity = ch.quantity,
  average_price = ch.average_price
from computed_holdings ch
where h.id = ch.holding_id
  and (
    abs(h.quantity - ch.quantity) > 0.000001
    or abs(h.average_price - ch.average_price) > 0.000001
  );

with active_cash_ledger as (
  select
    ca.id as cash_account_id,
    (
      ca.base_balance + coalesce(
        sum(case when te.id is null then 0 else tl.cash_delta end),
        0
      )
    )::double precision as balance
  from public.cash_accounts ca
  left join public.transaction_lines tl
    on tl.cash_account_id = ca.id
   and tl.deleted_at is null
  left join public.transaction_events te
    on te.id = tl.event_id
   and te.deleted_at is null
   and te.source not in ('history_display', 'record_only')
  where ca.deleted_at is null
  group by ca.id, ca.base_balance
)
update public.cash_accounts ca
set balance = acl.balance
from active_cash_ledger acl
where ca.id = acl.cash_account_id
  and abs(ca.balance - acl.balance) > 0.000001;

select public.recompute_asset_metrics(null);
