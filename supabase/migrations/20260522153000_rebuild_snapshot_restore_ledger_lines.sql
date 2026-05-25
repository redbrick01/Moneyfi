-- Rebuild snapshot restore ledger lines with stable source ids.
--
-- The first restore matched events to lines by title. Duplicate holding names
-- can therefore attach one holding to multiple events. Rebuild those opening
-- ledger rows using legacy_source_table/id as the stable key.

drop table if exists latest_restore_snapshots;
drop table if exists restore_holdings;
drop table if exists restore_cash_accounts;

create temp table latest_restore_snapshots as
select id, user_id, snapshot_date
from (
  select
    s.*,
    row_number() over (
      partition by s.user_id
      order by s.snapshot_date desc, s.created_at desc, s.id desc
    ) as rn
  from public.daily_portfolio_snapshots s
) ranked
where rn = 1;

create temp table restore_holdings as
select
  h.holding_id,
  h.asset_id,
  h.user_id,
  h.holding_name,
  h.holding_symbol,
  h.currency_code,
  h.quantity::double precision as quantity,
  case
    when abs(h.quantity) <= 0.0000001 then 0::double precision
    else (h.total_purchase_amount / h.quantity)::double precision
  end as average_price,
  h.total_purchase_amount::double precision as cost_basis,
  row_number() over (
    partition by h.user_id, h.asset_id
    order by h.holding_name, h.holding_symbol, h.holding_id
  )::integer - 1 as sort_order,
  s.snapshot_date
from public.daily_portfolio_snapshot_holding_items h
join latest_restore_snapshots s
  on s.id = h.snapshot_id
 and s.user_id = h.user_id
where h.holding_id is not null
  and h.asset_id is not null;

create temp table restore_cash_accounts as
select
  c.cash_account_id,
  c.asset_id,
  c.user_id,
  c.cash_account_name,
  c.currency_code,
  c.balance::double precision as balance,
  row_number() over (
    partition by c.user_id, c.asset_id
    order by c.cash_account_name, c.cash_account_id
  )::integer - 1 as sort_order,
  s.snapshot_date
from public.daily_portfolio_snapshot_cash_accounts c
join latest_restore_snapshots s
  on s.id = c.snapshot_id
 and s.user_id = c.user_id
where c.cash_account_id is not null
  and c.asset_id is not null;

update public.transaction_lines tl
set deleted_at = now(), updated_at = now()
from public.transaction_events te
where te.id = tl.event_id
  and te.source = 'snapshot_restore'
  and te.user_id in (select user_id from latest_restore_snapshots)
  and tl.deleted_at is null;

update public.transaction_events te
set deleted_at = now(), updated_at = now()
where te.source = 'snapshot_restore'
  and te.user_id in (select user_id from latest_restore_snapshots)
  and te.deleted_at is null;

insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  memo,
  source,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  rh.user_id,
  rh.snapshot_date,
  'opening_balance',
  '스냅샷 복구 - ' || rh.holding_name,
  'latest daily snapshot restore',
  'snapshot_restore',
  'snapshot_holding',
  rh.holding_id,
  rh.sort_order
from restore_holdings rh;

insert into public.transaction_lines (
  user_id,
  event_id,
  asset_id,
  holding_id,
  action,
  currency_code,
  quantity_delta,
  cash_delta,
  unit_price,
  gross_amount,
  fee_amount,
  tax_amount,
  cost_basis_delta,
  realized_pnl,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  rh.user_id,
  te.id,
  rh.asset_id,
  rh.holding_id,
  'opening_quantity',
  rh.currency_code,
  rh.quantity,
  0,
  rh.average_price,
  rh.cost_basis,
  0,
  0,
  rh.cost_basis,
  0,
  'snapshot_holding',
  rh.holding_id,
  0
from restore_holdings rh
join public.transaction_events te
  on te.user_id = rh.user_id
 and te.source = 'snapshot_restore'
 and te.legacy_source_table = 'snapshot_holding'
 and te.legacy_source_id = rh.holding_id
 and te.deleted_at is null;

insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  memo,
  source,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  rc.user_id,
  rc.snapshot_date,
  'opening_balance',
  '스냅샷 복구 - ' || rc.cash_account_name,
  'latest daily snapshot restore',
  'snapshot_restore',
  'snapshot_cash_account',
  rc.cash_account_id,
  rc.sort_order
from restore_cash_accounts rc;

insert into public.transaction_lines (
  user_id,
  event_id,
  asset_id,
  cash_account_id,
  action,
  currency_code,
  quantity_delta,
  cash_delta,
  unit_price,
  gross_amount,
  fee_amount,
  tax_amount,
  cost_basis_delta,
  realized_pnl,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  rc.user_id,
  te.id,
  rc.asset_id,
  rc.cash_account_id,
  'opening_cash',
  rc.currency_code,
  0,
  rc.balance,
  0,
  rc.balance,
  0,
  0,
  0,
  0,
  'snapshot_cash_account',
  rc.cash_account_id,
  0
from restore_cash_accounts rc
join public.transaction_events te
  on te.user_id = rc.user_id
 and te.source = 'snapshot_restore'
 and te.legacy_source_table = 'snapshot_cash_account'
 and te.legacy_source_id = rc.cash_account_id
 and te.deleted_at is null;
