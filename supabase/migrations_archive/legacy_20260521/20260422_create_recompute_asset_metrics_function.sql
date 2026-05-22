create or replace function public.recompute_asset_metrics(target_user_id uuid default null)
returns integer
language plpgsql
as $$
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
      sum(h.quantity * h.average_price) as purchase_krw,
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
      and coalesce(h.hidden, false) = false
      and (target_user_id is null or h.user_id = target_user_id)
    group by h.asset_id
  )
  update public.assets a
  set
    purchase_krw = coalesce((
      select ha.purchase_krw
      from holding_agg ha
      where ha.asset_id = a.id
    ), 0),
    valuation_krw = coalesce((
      select ha.valuation_krw
      from holding_agg ha
      where ha.asset_id = a.id
    ), 0),
    profit_krw = coalesce((
      select ha.valuation_krw - ha.purchase_krw
      from holding_agg ha
      where ha.asset_id = a.id
    ), 0),
    profit_rate = coalesce((
      select case
        when ha.purchase_krw = 0 then 0
        else ((ha.valuation_krw - ha.purchase_krw) / ha.purchase_krw) * 100
      end
      from holding_agg ha
      where ha.asset_id = a.id
    ), 0),
    metrics_updated_at = now()
  where a.deleted_at is null
    and (target_user_id is null or a.user_id = target_user_id);

  get diagnostics affected_rows = row_count;
  return affected_rows;
end;
$$;

comment on function public.recompute_asset_metrics(uuid) is
  'Recomputes assets.valuation_krw/purchase_krw/profit_krw/profit_rate from non-hidden, non-deleted holdings. USD holdings are converted with latest USD/KRW exchange rate.';

-- Initial backfill for existing rows
select public.recompute_asset_metrics(null);
