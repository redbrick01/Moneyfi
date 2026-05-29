-- Recompute safe sell realized PnL from snapshot-anchored moving-average cost.
--
-- Older legacy transaction rows may have copied realized_pnl = 0 into the
-- normalized ledger. We must not replay from the beginning of time because
-- users may not have entered every pre-app trade. This migration only
-- recalculates sell rows that have a reliable pre-sell snapshot anchor.

alter table public.transaction_lines
  add column if not exists realized_pnl_source text not null default 'auto';

with recursive anchored_trade_lines as (
  select
    tl.id as line_id,
    tl.user_id,
    tl.holding_id,
    tl.action,
    coalesce(tl.quantity_delta, 0)::double precision as quantity_delta,
    abs(coalesce(tl.gross_amount, 0))::double precision as gross_amount,
    te.occurred_at,
    te.sort_order as event_sort_order,
    tl.sort_order as line_sort_order,
    h.client_id as holding_client_id,
    anchor.snapshot_id as anchor_snapshot_id,
    anchor.snapshot_date as anchor_snapshot_date,
    anchor.anchor_quantity,
    anchor.anchor_cost,
    row_number() over (
      partition by tl.holding_id, anchor.snapshot_id
      order by te.occurred_at, te.sort_order, tl.sort_order, tl.id
    ) as rn
  from public.transaction_lines tl
  join public.transaction_events te
    on te.id = tl.event_id
   and te.deleted_at is null
  join public.holdings h
    on h.id = tl.holding_id
   and h.user_id = tl.user_id
  join lateral (
    select
      s.id as snapshot_id,
      s.snapshot_date,
      shi.quantity::double precision as anchor_quantity,
      shi.total_purchase_amount::double precision as anchor_cost
    from public.daily_portfolio_snapshots s
    join public.daily_portfolio_snapshot_holding_items shi
      on shi.snapshot_id = s.id
     and shi.user_id = s.user_id
    where s.user_id = tl.user_id
      and s.snapshot_date < te.occurred_at
      and coalesce(shi.quantity, 0) > 0
      and (
        shi.holding_client_id = h.client_id
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
    and tl.action in ('buy', 'sell')
    and coalesce(tl.realized_pnl_source, 'auto') <> 'manual'
    and te.source not in ('snapshot_restore', 'history_display', 'record_only')
),
replayed_trade_lines as (
  select
    atl.line_id,
    atl.holding_id,
    atl.anchor_snapshot_id,
    atl.action,
    atl.quantity_delta,
    atl.gross_amount,
    atl.rn,
    atl.anchor_quantity as quantity_before,
    atl.anchor_cost as cost_before,
    case
      when abs(atl.anchor_quantity) <= 0.0000001 then 0::double precision
      else greatest(atl.anchor_cost / atl.anchor_quantity, 0)::double precision
    end as average_cost_before,
    case
      when atl.action = 'buy' then atl.anchor_quantity + atl.quantity_delta
      when abs(atl.anchor_quantity + atl.quantity_delta) <= 0.0000001 then 0::double precision
      else atl.anchor_quantity + atl.quantity_delta
    end as quantity_after,
    case
      when atl.action = 'buy' then atl.anchor_cost + atl.gross_amount
      when abs(atl.anchor_quantity + atl.quantity_delta) <= 0.0000001 then 0::double precision
      else atl.anchor_cost - (
        case
          when abs(atl.anchor_quantity) <= 0.0000001 then 0::double precision
          else greatest(atl.anchor_cost / atl.anchor_quantity, 0)::double precision
        end * abs(atl.quantity_delta)
      )
    end as cost_after,
    case
      when atl.action = 'buy' then atl.gross_amount
      when atl.action = 'sell' and abs(atl.quantity_delta) <= atl.anchor_quantity + 0.0000001 then
        -(
          case
            when abs(atl.anchor_quantity) <= 0.0000001 then 0::double precision
            else greatest(atl.anchor_cost / atl.anchor_quantity, 0)::double precision
          end * abs(atl.quantity_delta)
        )
      else 0::double precision
    end as computed_cost_basis_delta,
    case
      when atl.action = 'sell' and abs(atl.quantity_delta) <= atl.anchor_quantity + 0.0000001 then
        atl.gross_amount - (
          case
            when abs(atl.anchor_quantity) <= 0.0000001 then 0::double precision
            else greatest(atl.anchor_cost / atl.anchor_quantity, 0)::double precision
          end * abs(atl.quantity_delta)
        )
      else 0::double precision
    end as computed_realized_pnl,
    (
      atl.action <> 'sell'
      or (
        abs(atl.quantity_delta) <= atl.anchor_quantity + 0.0000001
        and atl.anchor_quantity > 0
      )
    ) as segment_valid,
    (
      atl.action = 'sell'
      and abs(atl.quantity_delta) <= atl.anchor_quantity + 0.0000001
      and atl.anchor_quantity > 0
    ) as can_recompute_sell
  from anchored_trade_lines atl
  where atl.rn = 1

  union all

  select
    atl.line_id,
    atl.holding_id,
    atl.anchor_snapshot_id,
    atl.action,
    atl.quantity_delta,
    atl.gross_amount,
    atl.rn,
    r.quantity_after as quantity_before,
    r.cost_after as cost_before,
    case
      when abs(r.quantity_after) <= 0.0000001 then 0::double precision
      else greatest(r.cost_after / r.quantity_after, 0)::double precision
    end as average_cost_before,
    case
      when atl.action = 'buy' then r.quantity_after + atl.quantity_delta
      when abs(r.quantity_after + atl.quantity_delta) <= 0.0000001 then 0::double precision
      else r.quantity_after + atl.quantity_delta
    end as quantity_after,
    case
      when atl.action = 'buy' then r.cost_after + atl.gross_amount
      when abs(r.quantity_after + atl.quantity_delta) <= 0.0000001 then 0::double precision
      else r.cost_after - (
        case
          when abs(r.quantity_after) <= 0.0000001 then 0::double precision
          else greatest(r.cost_after / r.quantity_after, 0)::double precision
        end * abs(atl.quantity_delta)
      )
    end as cost_after,
    case
      when atl.action = 'buy' then atl.gross_amount
      when atl.action = 'sell' and abs(atl.quantity_delta) <= r.quantity_after + 0.0000001 then
        -(
          case
            when abs(r.quantity_after) <= 0.0000001 then 0::double precision
            else greatest(r.cost_after / r.quantity_after, 0)::double precision
          end * abs(atl.quantity_delta)
        )
      else 0::double precision
    end as computed_cost_basis_delta,
    case
      when atl.action = 'sell' and abs(atl.quantity_delta) <= r.quantity_after + 0.0000001 then
        atl.gross_amount - (
          case
            when abs(r.quantity_after) <= 0.0000001 then 0::double precision
            else greatest(r.cost_after / r.quantity_after, 0)::double precision
          end * abs(atl.quantity_delta)
        )
      else 0::double precision
    end as computed_realized_pnl,
    (
      r.segment_valid
      and (
        atl.action <> 'sell'
        or (
          abs(atl.quantity_delta) <= r.quantity_after + 0.0000001
          and r.quantity_after > 0
        )
      )
    ) as segment_valid,
    (
      r.segment_valid
      and atl.action = 'sell'
      and abs(atl.quantity_delta) <= r.quantity_after + 0.0000001
      and r.quantity_after > 0
    ) as can_recompute_sell
  from replayed_trade_lines r
  join anchored_trade_lines atl
    on atl.holding_id = r.holding_id
   and atl.anchor_snapshot_id = r.anchor_snapshot_id
   and atl.rn = r.rn + 1
),
safe_sell_recomputes as (
  select
    line_id,
    computed_cost_basis_delta,
    computed_realized_pnl
  from replayed_trade_lines
  where action = 'sell'
    and can_recompute_sell
)
update public.transaction_lines tl
set
  cost_basis_delta = r.computed_cost_basis_delta,
  realized_pnl = r.computed_realized_pnl,
  realized_pnl_source = 'snapshot_anchor',
  updated_at = now(),
  last_modified_at = now()
from safe_sell_recomputes r
where tl.id = r.line_id
  and (
    abs(tl.cost_basis_delta - r.computed_cost_basis_delta) > 0.000001
    or abs(tl.realized_pnl - r.computed_realized_pnl) > 0.000001
    or coalesce(tl.realized_pnl_source, 'auto') <> 'snapshot_anchor'
  );

with active_holding_ledger as (
  select
    tl.holding_id,
    coalesce(sum(tl.quantity_delta), 0)::double precision as quantity,
    coalesce(sum(tl.cost_basis_delta), 0)::double precision as cost_basis
  from public.holdings h
  join public.transaction_lines tl
    on tl.holding_id = h.id
   and tl.deleted_at is null
  join public.transaction_events te
    on te.id = tl.event_id
   and te.deleted_at is null
   and te.source not in ('history_display', 'record_only')
  where h.deleted_at is null
  group by tl.holding_id
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
  average_price = ch.average_price,
  updated_at = now(),
  last_modified_at = now()
from computed_holdings ch
where h.id = ch.holding_id
  and (
    abs(h.quantity - ch.quantity) > 0.000001
    or abs(h.average_price - ch.average_price) > 0.000001
  );

select public.recompute_asset_metrics(null);
