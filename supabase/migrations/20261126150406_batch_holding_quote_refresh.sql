-- One small freshness record per portfolio. Quote refreshes only touch holdings
-- when a price changes. Failed quotes keep their previous successful timestamp.
create table public.holding_quote_checks (
  user_id uuid primary key references auth.users(id) on delete cascade,
  checks jsonb not null default '{}'
);
alter table public.holding_quote_checks enable row level security;
revoke all on public.holding_quote_checks from public, anon, authenticated;
grant select, insert, update on public.holding_quote_checks to service_role;

-- Include the instrument identity so a reassigned holding cannot inherit a check.
create function public.holding_quote_check_key(h public.holdings)
returns text language sql stable strict security invoker set search_path = ''
as $$
  select jsonb_build_array(h.id, h.asset_id, h.symbol, h.currency_code, h.exchange_code)::text
$$;
revoke all on function public.holding_quote_check_key(public.holdings) from public, anon, authenticated;
grant execute on function public.holding_quote_check_key(public.holdings) to service_role;

create view public.holdings_with_quote_checks with (security_invoker = true) as
select h.*, greatest(h.market_updated_at,
  case when (q.checks -> public.holding_quote_check_key(h) ->> 'price')::float8 = h.current_price
    then (q.checks -> public.holding_quote_check_key(h) ->> 'at')::timestamptz end
) as quote_checked_at
from public.holdings h left join public.holding_quote_checks q on q.user_id = h.user_id;
revoke all on public.holdings_with_quote_checks from public, anon, authenticated;
grant select on public.holdings_with_quote_checks to service_role;

create function public.apply_holding_quote_batch(p_user_id uuid, p_quotes jsonb)
returns jsonb language plpgsql security invoker set search_path = ''
as $$
declare
  previous_checks jsonb;
  accepted jsonb;
  next_checks jsonb;
  refreshed integer;
  changed integer;
  recomputed integer := 0;
begin
  insert into public.holding_quote_checks(user_id) values (p_user_id)
    on conflict do nothing;
  select checks into strict previous_checks from public.holding_quote_checks
    where user_id = p_user_id for update;

  with eligible as materialized (
    select h.id, h.current_price, public.holding_quote_check_key(h) as key,
           q.price, q.checked_at, h.current_price is null or abs(h.current_price - q.price) >= 0.000001 as changed
    from jsonb_to_recordset(p_quotes) as q(id bigint, asset_id bigint, symbol text,
      currency_code text, exchange_code text, price float8, checked_at timestamptz)
    join public.holdings h on h.id = q.id and h.asset_id = q.asset_id
      and h.symbol = q.symbol and h.currency_code = q.currency_code and h.exchange_code = q.exchange_code
    where h.user_id = p_user_id and h.deleted_at is null and h.quantity > 0 and q.price > 0
      and q.checked_at > coalesce(greatest(h.market_updated_at,
        (previous_checks -> public.holding_quote_check_key(h) ->> 'at')::timestamptz), '-infinity')
  ), updated as (
    update public.holdings h set current_price = e.price, market_updated_at = e.checked_at
    from eligible e where e.changed and h.id = e.id and h.user_id = p_user_id
      and public.holding_quote_check_key(h) = e.key and h.deleted_at is null and h.quantity > 0
      and h.current_price is not distinct from e.current_price
      and (h.market_updated_at is null or h.market_updated_at < e.checked_at)
    returning h.id
  )
  select coalesce(jsonb_object_agg(e.key, jsonb_build_object(
      'at', e.checked_at, 'price', case when e.changed then e.price else e.current_price end)), '{}'),
    count(*), count(u.id)
  into accepted, refreshed, changed
  from eligible e left join updated u on e.id = u.id where not e.changed or u.id is not null;

  if refreshed > 0 then
    -- Retain failures from previous runs and prune deleted or repurposed positions.
    select coalesce(jsonb_object_agg(k.key, previous_checks -> k.key), '{}') || accepted
    into next_checks from (
      select public.holding_quote_check_key(h) as key from public.holdings h
      where h.user_id = p_user_id and h.deleted_at is null and h.quantity > 0
    ) k where previous_checks ? k.key and not accepted ? k.key;
    update public.holding_quote_checks set checks = next_checks where user_id = p_user_id;
  end if;
  if changed > 0 then
    recomputed := public.recompute_asset_metrics(p_user_id);
  end if;
  return jsonb_build_object('updated', changed, 'refreshed', refreshed, 'recomputed', recomputed);
end
$$;
revoke all on function public.apply_holding_quote_batch(uuid,jsonb) from public, anon, authenticated;
grant execute on function public.apply_holding_quote_batch(uuid,jsonb) to service_role;
