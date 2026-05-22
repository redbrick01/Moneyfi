-- Restore current portfolio state from each user's latest daily snapshot.
--
-- This intentionally restores both state tables and the normalized ledger.
-- If only assets/holdings/cash_accounts are restored, the app can overwrite
-- them again from transaction_lines during sync. Snapshot rows become opening
-- ledger lines so state and ledger agree.

create schema if not exists recovery_archive;

create table if not exists recovery_archive.assets_before_snapshot_restore_20260522
  as table public.assets with data;

create table if not exists recovery_archive.holdings_before_snapshot_restore_20260522
  as table public.holdings with data;

create table if not exists recovery_archive.cash_accounts_before_snapshot_restore_20260522
  as table public.cash_accounts with data;

create table if not exists recovery_archive.transaction_events_before_snapshot_restore_20260522
  as table public.transaction_events with data;

create table if not exists recovery_archive.transaction_lines_before_snapshot_restore_20260522
  as table public.transaction_lines with data;

revoke all on schema recovery_archive from anon, authenticated;
grant usage on schema recovery_archive to service_role;
grant select on all tables in schema recovery_archive to service_role;

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

create temp table restore_assets as
select
  asset_id,
  user_id,
  min(asset_title) as title,
  min(snapshot_date) as snapshot_date,
  sum(total_purchase_amount)::double precision as purchase_krw,
  sum(total_valuation_amount)::double precision as valuation_krw,
  sum(profit_amount)::double precision as profit_krw,
  case
    when sum(total_purchase_amount) = 0 then 0::double precision
    else (sum(profit_amount) / sum(total_purchase_amount)) * 100
  end as profit_rate
from (
  select
    i.asset_id,
    i.user_id,
    i.asset_title,
    s.snapshot_date,
    i.total_purchase_amount,
    i.total_valuation_amount,
    i.profit_amount
  from public.daily_portfolio_snapshot_items i
  join latest_restore_snapshots s
    on s.id = i.snapshot_id
   and s.user_id = i.user_id

  union all

  select
    c.asset_id,
    c.user_id,
    c.asset_title,
    s.snapshot_date,
    0::double precision,
    0::double precision,
    0::double precision
  from public.daily_portfolio_snapshot_cash_accounts c
  join latest_restore_snapshots s
    on s.id = c.snapshot_id
   and s.user_id = c.user_id
  where c.asset_id is not null
) source
where asset_id is not null
group by asset_id, user_id;

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
  case
    when abs(h.quantity) <= 0.0000001 then 0::double precision
    else (h.total_valuation_amount / h.quantity)::double precision
  end as current_price,
  h.total_purchase_amount::double precision as cost_basis,
  h.total_valuation_amount::double precision as valuation_amount,
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
  coalesce(c.note, '') as note,
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

insert into public.assets (
  id,
  asset_type,
  title,
  alias,
  hidden,
  currency_code,
  value,
  change,
  icon_code_point,
  quantity_label,
  quantity_value,
  average_label,
  average_value,
  note,
  sort_order,
  user_id,
  client_id,
  created_at,
  updated_at,
  deleted_at,
  valuation_krw,
  purchase_krw,
  profit_krw,
  profit_rate,
  metrics_updated_at
)
select
  ra.asset_id,
  coalesce(a.asset_type, '주식'),
  ra.title,
  coalesce(a.alias, ''),
  false,
  coalesce(a.currency_code, 'KRW'),
  case
    when ra.valuation_krw < 0
      then '-₩' || to_char(abs(round(ra.valuation_krw))::numeric, 'FM999,999,999,999,999,990')
    else '₩' || to_char(round(ra.valuation_krw)::numeric, 'FM999,999,999,999,999,990')
  end,
  (
    case when ra.profit_rate >= 0 then '+' else '' end
  ) || to_char(round(ra.profit_rate::numeric, 1), 'FM999999999990.0') || '%',
  coalesce(a.icon_code_point, 0),
  coalesce(a.quantity_label, ''),
  coalesce(a.quantity_value, ''),
  coalesce(a.average_label, ''),
  coalesce(a.average_value, ''),
  coalesce(a.note, ''),
  row_number() over (partition by ra.user_id order by ra.title, ra.asset_id)::integer - 1,
  ra.user_id,
  coalesce(a.client_id, gen_random_uuid()),
  coalesce(a.created_at, now()),
  now(),
  null,
  ra.valuation_krw,
  ra.purchase_krw,
  ra.profit_krw,
  ra.profit_rate,
  now()
from restore_assets ra
left join public.assets a
  on a.id = ra.asset_id
on conflict (id) do update set
  title = excluded.title,
  hidden = false,
  value = excluded.value,
  change = excluded.change,
  sort_order = excluded.sort_order,
  updated_at = now(),
  deleted_at = null,
  valuation_krw = excluded.valuation_krw,
  purchase_krw = excluded.purchase_krw,
  profit_krw = excluded.profit_krw,
  profit_rate = excluded.profit_rate,
  metrics_updated_at = now();

update public.assets a
set deleted_at = now(), updated_at = now()
where a.user_id in (select user_id from latest_restore_snapshots)
  and not exists (
    select 1 from restore_assets ra
    where ra.asset_id = a.id
      and ra.user_id = a.user_id
  );

insert into public.holdings (
  id,
  asset_id,
  hidden,
  currency_code,
  market_updated_at,
  exchange_code,
  name,
  symbol,
  quantity,
  average_price,
  current_price,
  note,
  sort_order,
  user_id,
  client_id,
  created_at,
  updated_at,
  deleted_at
)
select
  rh.holding_id,
  rh.asset_id,
  false,
  rh.currency_code,
  null,
  coalesce(h.exchange_code, ''),
  rh.holding_name,
  rh.holding_symbol,
  rh.quantity,
  rh.average_price,
  rh.current_price,
  coalesce(h.note, ''),
  rh.sort_order,
  rh.user_id,
  coalesce(h.client_id, gen_random_uuid()),
  coalesce(h.created_at, now()),
  now(),
  null
from restore_holdings rh
left join public.holdings h
  on h.id = rh.holding_id
on conflict (id) do update set
  asset_id = excluded.asset_id,
  hidden = false,
  currency_code = excluded.currency_code,
  name = excluded.name,
  symbol = excluded.symbol,
  quantity = excluded.quantity,
  average_price = excluded.average_price,
  current_price = excluded.current_price,
  sort_order = excluded.sort_order,
  updated_at = now(),
  deleted_at = null;

update public.holdings h
set deleted_at = now(), updated_at = now()
where h.user_id in (select user_id from latest_restore_snapshots)
  and not exists (
    select 1 from restore_holdings rh
    where rh.holding_id = h.id
      and rh.user_id = h.user_id
  );

insert into public.cash_accounts (
  id,
  asset_id,
  hidden,
  currency_code,
  name,
  base_balance,
  balance,
  note,
  sort_order,
  user_id,
  client_id,
  created_at,
  updated_at,
  deleted_at
)
select
  rc.cash_account_id,
  rc.asset_id,
  false,
  rc.currency_code,
  rc.cash_account_name,
  0,
  rc.balance,
  rc.note,
  rc.sort_order,
  rc.user_id,
  coalesce(ca.client_id, gen_random_uuid()),
  coalesce(ca.created_at, now()),
  now(),
  null
from restore_cash_accounts rc
left join public.cash_accounts ca
  on ca.id = rc.cash_account_id
on conflict (id) do update set
  asset_id = excluded.asset_id,
  hidden = false,
  currency_code = excluded.currency_code,
  name = excluded.name,
  base_balance = 0,
  balance = excluded.balance,
  note = excluded.note,
  sort_order = excluded.sort_order,
  updated_at = now(),
  deleted_at = null;

update public.cash_accounts ca
set deleted_at = now(), updated_at = now()
where ca.user_id in (select user_id from latest_restore_snapshots)
  and not exists (
    select 1 from restore_cash_accounts rc
    where rc.cash_account_id = ca.id
      and rc.user_id = ca.user_id
  );

update public.transaction_lines tl
set deleted_at = now(), updated_at = now()
where tl.user_id in (select user_id from latest_restore_snapshots)
  and tl.deleted_at is null;

update public.transaction_events te
set deleted_at = now(), updated_at = now()
where te.user_id in (select user_id from latest_restore_snapshots)
  and te.deleted_at is null;

insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  memo,
  source,
  sort_order
)
select
  rh.user_id,
  rh.snapshot_date,
  'opening_balance',
  '스냅샷 복구 - ' || rh.holding_name,
  'latest daily snapshot restore',
  'snapshot_restore',
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
  0
from restore_holdings rh
join public.transaction_events te
  on te.user_id = rh.user_id
 and te.source = 'snapshot_restore'
 and te.kind = 'opening_balance'
 and te.title = '스냅샷 복구 - ' || rh.holding_name
 and te.occurred_at = rh.snapshot_date
 and te.deleted_at is null
where not exists (
  select 1
  from public.transaction_lines existing
  where existing.event_id = te.id
    and existing.holding_id = rh.holding_id
    and existing.action = 'opening_quantity'
);

insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  memo,
  source,
  sort_order
)
select
  rc.user_id,
  rc.snapshot_date,
  'opening_balance',
  '스냅샷 복구 - ' || rc.cash_account_name,
  'latest daily snapshot restore',
  'snapshot_restore',
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
  0
from restore_cash_accounts rc
join public.transaction_events te
  on te.user_id = rc.user_id
 and te.source = 'snapshot_restore'
 and te.kind = 'opening_balance'
 and te.title = '스냅샷 복구 - ' || rc.cash_account_name
 and te.occurred_at = rc.snapshot_date
 and te.deleted_at is null
where not exists (
  select 1
  from public.transaction_lines existing
  where existing.event_id = te.id
    and existing.cash_account_id = rc.cash_account_id
    and existing.action = 'opening_cash'
);

select public.recompute_asset_metrics(null);
