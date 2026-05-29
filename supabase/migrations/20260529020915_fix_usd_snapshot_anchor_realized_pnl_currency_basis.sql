-- Correct USD snapshot-anchor sell realized PnL using user-provided
-- source-currency average cost seeds.
--
-- This is intentionally forward-only and narrowly scoped. It does not replay
-- all historical trades and it never reconciles holding quantities from the
-- ledger, because users may not have entered every pre-app transaction.

create schema if not exists recovery_archive;

alter table public.holdings
  add column if not exists average_price_source double precision not null default 0,
  add column if not exists average_price_krw double precision not null default 0,
  add column if not exists average_purchase_fx_rate double precision not null default 1,
  add column if not exists cost_basis_krw double precision not null default 0;

alter table public.transaction_lines
  add column if not exists cost_basis_source_delta double precision not null default 0,
  add column if not exists realized_pnl_source text not null default 'auto';

create temp table usd_snapshot_anchor_currency_seed (
  asset_title text not null,
  holding_id bigint not null,
  symbol text not null,
  holding_name text not null,
  expected_quantity double precision not null,
  expected_average_price_krw double precision not null,
  average_price_source double precision not null,
  primary key (asset_title, holding_id)
) on commit drop;

insert into usd_snapshot_anchor_currency_seed (
  asset_title,
  holding_id,
  symbol,
  holding_name,
  expected_quantity,
  expected_average_price_krw,
  average_price_source
) values
  ('주식', 8, 'SATL', '새틀로직', 50, 4690, 3.2925),
  ('주식', 3, 'IONQ', '아이온큐', 16, 39680, 28.3813),
  ('주식', 1, 'TSLA', '테슬라', 2, 317648, 225.9928),
  ('주식', 4, 'PLTR', '팔란티어', 6, 104149, 74.4933),
  ('주식', 5, 'NVDA', '엔비디아', 7, 143943.642857143, 133.1379),
  ('+', 21, 'TSLA', '테슬라', 66, 286663, 259.5674);

create temp table matched_seed_holdings on commit drop as
select
  seed.asset_title,
  seed.holding_id,
  seed.symbol,
  seed.holding_name,
  seed.expected_quantity,
  seed.expected_average_price_krw,
  seed.average_price_source,
  h.user_id,
  h.asset_id,
  h.client_id as holding_client_id
from usd_snapshot_anchor_currency_seed seed
join public.holdings h
  on h.id = seed.holding_id
 and h.deleted_at is null
join public.assets a
  on a.id = h.asset_id
 and a.user_id = h.user_id
 and a.deleted_at is null
where a.title = seed.asset_title
  and h.symbol = seed.symbol
  and h.currency_code = 'USD';

create table if not exists recovery_archive.usd_snapshot_anchor_fix_skipped_20260529
as
select
  now() as archived_at,
  tl.id as line_id,
  tl.user_id,
  tl.holding_id,
  h.symbol,
  h.name as holding_name,
  h.currency_code,
  te.source as event_source,
  te.occurred_at,
  tl.quantity_delta,
  tl.gross_amount,
  coalesce(tl.realized_pnl_source, 'auto') as realized_pnl_source,
  case
    when upper(coalesce(tl.currency_code, 'KRW')) <> 'USD' then 'non_usd_snapshot_anchor'
    when ms.holding_id is null then 'missing_or_mismatched_user_seed'
    else 'unknown'
  end as skip_reason
from public.transaction_lines tl
join public.transaction_events te
  on te.id = tl.event_id
 and te.deleted_at is null
left join public.holdings h
  on h.id = tl.holding_id
 and h.user_id = tl.user_id
left join matched_seed_holdings ms
  on ms.holding_id = tl.holding_id
 and ms.user_id = tl.user_id
where tl.deleted_at is null
  and tl.action = 'sell'
  and coalesce(tl.realized_pnl_source, 'auto') = 'snapshot_anchor'
  and te.source not in ('snapshot_restore', 'history_display', 'record_only')
  and (
    upper(coalesce(tl.currency_code, 'KRW')) <> 'USD'
    or ms.holding_id is null
  );

create temp table affected_usd_snapshot_anchor_sell_lines on commit drop as
select
  tl.id as line_id,
  tl.user_id,
  tl.holding_id,
  tl.asset_id,
  tl.event_id,
  abs(coalesce(tl.quantity_delta, 0))::double precision as quantity_sold,
  abs(coalesce(tl.gross_amount, 0))::double precision as gross_amount,
  ms.expected_average_price_krw,
  ms.average_price_source,
  ms.expected_quantity,
  anchor.snapshot_id as anchor_snapshot_id,
  anchor.snapshot_date as anchor_snapshot_date,
  anchor.anchor_quantity,
  anchor.anchor_cost_krw
from public.transaction_lines tl
join public.transaction_events te
  on te.id = tl.event_id
 and te.deleted_at is null
join matched_seed_holdings ms
  on ms.holding_id = tl.holding_id
 and ms.user_id = tl.user_id
join public.holdings h
  on h.id = tl.holding_id
 and h.user_id = tl.user_id
 and h.deleted_at is null
join lateral (
  select
    s.id as snapshot_id,
    s.snapshot_date,
    shi.quantity::double precision as anchor_quantity,
    shi.total_purchase_amount::double precision as anchor_cost_krw
  from public.daily_portfolio_snapshots s
  join public.daily_portfolio_snapshot_holding_items shi
    on shi.snapshot_id = s.id
   and shi.user_id = s.user_id
  where s.user_id = tl.user_id
    and s.snapshot_date < te.occurred_at
    and coalesce(shi.quantity, 0) > 0
    and (
      shi.holding_client_id = ms.holding_client_id
      or (
        shi.holding_client_id is null
        and shi.holding_id = h.id
      )
    )
  order by s.snapshot_date desc, s.created_at desc, s.id desc
  limit 1
) anchor on true
where tl.deleted_at is null
  and tl.holding_id is not null
  and tl.action = 'sell'
  and upper(coalesce(tl.currency_code, 'KRW')) = 'USD'
  and coalesce(tl.realized_pnl_source, 'auto') = 'snapshot_anchor'
  and te.source not in ('snapshot_restore', 'history_display', 'record_only')
  and abs(coalesce(tl.quantity_delta, 0)) > 0.000001;

create table if not exists recovery_archive.transaction_lines_before_usd_snapshot_anchor_fix_20260529
as
select
  now() as archived_at,
  affected.anchor_snapshot_id,
  affected.anchor_snapshot_date,
  affected.anchor_quantity,
  affected.anchor_cost_krw,
  affected.expected_average_price_krw as seed_average_price_krw,
  affected.average_price_source as seed_average_price_source,
  tl.*
from affected_usd_snapshot_anchor_sell_lines affected
join public.transaction_lines tl
  on tl.id = affected.line_id;

create table if not exists recovery_archive.holdings_before_usd_snapshot_anchor_fix_20260529
as
select
  now() as archived_at,
  ms.asset_title as seed_asset_title,
  ms.holding_id as seed_holding_id,
  ms.symbol as seed_symbol,
  ms.holding_name as seed_holding_name,
  ms.expected_quantity as seed_expected_quantity,
  ms.expected_average_price_krw as seed_average_price_krw,
  ms.average_price_source as seed_average_price_source,
  h.*
from matched_seed_holdings ms
join public.holdings h
  on h.id = ms.holding_id
where exists (
  select 1
  from affected_usd_snapshot_anchor_sell_lines affected
  where affected.holding_id = ms.holding_id
);

-- SATL reference check:
-- qty 30, gross USD 285, source average USD 3.2925
-- realized_pnl = 285 - (3.2925 * 30) = 186.225
-- cost_basis_delta = -(4690 * 30) = -140700
-- cost_basis_source_delta = -(3.2925 * 30) = -98.775
update public.transaction_lines tl
set
  realized_pnl =
    affected.gross_amount - (affected.average_price_source * affected.quantity_sold),
  cost_basis_delta =
    -(affected.expected_average_price_krw * affected.quantity_sold),
  cost_basis_source_delta =
    -(affected.average_price_source * affected.quantity_sold),
  realized_pnl_source = 'snapshot_anchor',
  updated_at = now(),
  last_modified_at = now()
from affected_usd_snapshot_anchor_sell_lines affected
where tl.id = affected.line_id
  and (
    abs(
      tl.realized_pnl
      - (affected.gross_amount - (affected.average_price_source * affected.quantity_sold))
    ) > 0.000001
    or abs(
      tl.cost_basis_delta
      - (-(affected.expected_average_price_krw * affected.quantity_sold))
    ) > 0.000001
    or abs(
      tl.cost_basis_source_delta
      - (-(affected.average_price_source * affected.quantity_sold))
    ) > 0.000001
    or coalesce(tl.realized_pnl_source, 'auto') <> 'snapshot_anchor'
  );

update public.holdings h
set
  average_price = ms.expected_average_price_krw,
  average_price_krw = ms.expected_average_price_krw,
  average_price_source = ms.average_price_source,
  average_purchase_fx_rate =
    ms.expected_average_price_krw / ms.average_price_source,
  cost_basis_krw = h.quantity * ms.expected_average_price_krw,
  updated_at = now(),
  last_modified_at = now()
from matched_seed_holdings ms
where h.id = ms.holding_id
  and h.deleted_at is null
  and exists (
    select 1
    from affected_usd_snapshot_anchor_sell_lines affected
    where affected.holding_id = h.id
  )
  and (
    abs(coalesce(h.average_price, 0) - ms.expected_average_price_krw) > 0.000001
    or abs(coalesce(h.average_price_krw, 0) - ms.expected_average_price_krw) > 0.000001
    or abs(coalesce(h.average_price_source, 0) - ms.average_price_source) > 0.000001
    or abs(coalesce(h.average_purchase_fx_rate, 0) - (ms.expected_average_price_krw / ms.average_price_source)) > 0.000001
    or abs(coalesce(h.cost_basis_krw, 0) - (h.quantity * ms.expected_average_price_krw)) > 0.000001
  );

CREATE OR REPLACE FUNCTION public.recompute_asset_metrics(target_user_id uuid DEFAULT NULL::uuid)
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
  affected_rows integer := 0;
begin
  with latest_rate as (
    select coalesce(
      (
        select er.rate
        from public.exchange_rates er
        where er.currency_pair = 'USD/KRW'
        order by er.recorded_at desc
        limit 1
      ),
      1.0
    ) as usd_krw
  ),
  holding_agg as (
    select
      h.asset_id,
      sum(
        case
          when coalesce(h.cost_basis_krw, 0) > 0
            then h.cost_basis_krw
          else h.quantity * h.average_price
        end
      ) as purchase_krw,
      sum(
        (h.quantity * h.current_price) *
        case
          when upper(coalesce(h.currency_code, 'KRW')) = 'USD'
            then lr.usd_krw
          else 1.0
        end
      ) as valuation_krw
    from public.holdings h
    cross join latest_rate lr
    where h.deleted_at is null
      and (target_user_id is null or h.user_id = target_user_id)
    group by h.asset_id
  ),
  computed as (
    select
      a.id as asset_id,
      coalesce(ha.purchase_krw, 0)::double precision as purchase_krw,
      coalesce(ha.valuation_krw, 0)::double precision as valuation_krw,
      (coalesce(ha.valuation_krw, 0) - coalesce(ha.purchase_krw, 0))::double precision as profit_krw,
      (
        case
          when coalesce(ha.purchase_krw, 0) = 0 then 0
          else ((coalesce(ha.valuation_krw, 0) - coalesce(ha.purchase_krw, 0)) / ha.purchase_krw) * 100
        end
      )::double precision as profit_rate
    from public.assets a
    left join holding_agg ha on ha.asset_id = a.id
    where a.deleted_at is null
      and (target_user_id is null or a.user_id = target_user_id)
  )
  update public.assets a
  set
    purchase_krw = c.purchase_krw,
    valuation_krw = c.valuation_krw,
    profit_krw = c.profit_krw,
    profit_rate = c.profit_rate,
    value = case
      when c.valuation_krw < 0
        then '-₩' || to_char(abs(round(c.valuation_krw))::numeric, 'FM999,999,999,999,999,990')
      else '₩' || to_char(round(c.valuation_krw)::numeric, 'FM999,999,999,999,999,990')
    end,
    change = (
      case
        when c.profit_rate >= 0 then '+'
        else ''
      end
    ) || to_char(round(c.profit_rate::numeric, 1), 'FM999999999990.0') || '%',
    metrics_updated_at = now()
  from computed c
  where a.id = c.asset_id;

  get diagnostics affected_rows = row_count;
  return affected_rows;
end;
$$;

COMMENT ON FUNCTION public.recompute_asset_metrics(uuid)
IS 'Recomputes asset metrics from active holdings. Purchase cost prefers holdings.cost_basis_krw and falls back to quantity * average_price; this function does not update holding quantities.';

select public.recompute_asset_metrics(null);
