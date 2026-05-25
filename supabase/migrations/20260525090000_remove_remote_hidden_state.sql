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
IS 'Recomputes assets numeric metrics and display fields(value/change) from non-deleted holdings. USD holdings are converted with latest USD/KRW exchange rate.';

COMMENT ON COLUMN public.assets.valuation_krw
IS 'Derived total valuation in KRW from non-deleted holdings.';

COMMENT ON COLUMN public.assets.purchase_krw
IS 'Derived total purchase amount in KRW from non-deleted holdings.';

ALTER TABLE public.assets DROP COLUMN IF EXISTS hidden;
ALTER TABLE public.holdings DROP COLUMN IF EXISTS hidden;
ALTER TABLE public.cash_accounts DROP COLUMN IF EXISTS hidden;
