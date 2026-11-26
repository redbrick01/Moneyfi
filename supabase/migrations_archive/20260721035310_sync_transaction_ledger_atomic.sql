create or replace function public.sync_transaction_ledger_atomic(
  p_user_id uuid,
  p_events jsonb,
  p_lines jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = pg_catalog, pg_temp
as $$
declare
  v_conflicts jsonb;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'p_user_id is required';
  end if;

  create temporary table _sync_events_input (
    client_id uuid,
    last_modified_at timestamptz,
    deleted_at timestamptz,
    occurred_at date,
    kind text,
    title text,
    memo text,
    source text,
    flow_category text,
    legacy_source_table text,
    legacy_source_id bigint,
    sort_order integer
  ) on commit drop;

  create temporary table _sync_lines_input (
    client_id uuid,
    last_modified_at timestamptz,
    event_client_id uuid,
    asset_client_id uuid,
    holding_client_id uuid,
    cash_account_client_id uuid,
    deleted_at timestamptz,
    legacy_source_table text,
    legacy_source_id bigint,
    action text,
    currency_code text,
    quantity_delta double precision,
    cash_delta double precision,
    unit_price double precision,
    gross_amount double precision,
    fee_amount double precision,
    tax_amount double precision,
    cost_basis_delta double precision,
    cost_basis_source_delta double precision,
    realized_pnl double precision,
    realized_pnl_source text,
    fx_rate double precision,
    sort_order integer
  ) on commit drop;

  insert into _sync_events_input
  select *
  from jsonb_to_recordset(coalesce(p_events, '[]'::jsonb)) as event_row(
    client_id uuid,
    last_modified_at timestamptz,
    deleted_at timestamptz,
    occurred_at date,
    kind text,
    title text,
    memo text,
    source text,
    flow_category text,
    legacy_source_table text,
    legacy_source_id bigint,
    sort_order integer
  );

  insert into _sync_lines_input
  select *
  from jsonb_to_recordset(coalesce(p_lines, '[]'::jsonb)) as line_row(
    client_id uuid,
    last_modified_at timestamptz,
    event_client_id uuid,
    asset_client_id uuid,
    holding_client_id uuid,
    cash_account_client_id uuid,
    deleted_at timestamptz,
    legacy_source_table text,
    legacy_source_id bigint,
    action text,
    currency_code text,
    quantity_delta double precision,
    cash_delta double precision,
    unit_price double precision,
    gross_amount double precision,
    fee_amount double precision,
    tax_amount double precision,
    cost_basis_delta double precision,
    cost_basis_source_delta double precision,
    realized_pnl double precision,
    realized_pnl_source text,
    fx_rate double precision,
    sort_order integer
  );

  if exists (
    select 1 from _sync_events_input
    where client_id is null or last_modified_at is null
  ) or exists (
    select 1 from _sync_lines_input
    where client_id is null or last_modified_at is null or event_client_id is null
  ) then
    raise exception using errcode = '22023', message = 'ledger client ids and timestamps are required';
  end if;

  if exists (
    select 1 from _sync_events_input group by client_id having count(*) > 1
  ) or exists (
    select 1 from _sync_lines_input group by client_id having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'duplicate ledger client id in payload';
  end if;

  if exists (
    select 1
    from _sync_lines_input line_row
    where not exists (
      select 1 from _sync_events_input event_row
      where event_row.client_id = line_row.event_client_id
    )
    and not exists (
      select 1 from public.transaction_events event_row
      where event_row.user_id = p_user_id
        and event_row.client_id = line_row.event_client_id
    )
  ) then
    raise exception using errcode = '23503', message = 'missing transaction event relation';
  end if;

  if exists (
    select 1
    from _sync_lines_input line_row
    where line_row.asset_client_id is not null
      and not exists (
        select 1 from public.assets asset_row
        where asset_row.user_id = p_user_id
          and asset_row.client_id = line_row.asset_client_id
      )
  ) or exists (
    select 1
    from _sync_lines_input line_row
    where line_row.holding_client_id is not null
      and not exists (
        select 1 from public.holdings holding_row
        where holding_row.user_id = p_user_id
          and holding_row.client_id = line_row.holding_client_id
      )
  ) or exists (
    select 1
    from _sync_lines_input line_row
    where line_row.cash_account_client_id is not null
      and not exists (
        select 1 from public.cash_accounts cash_row
        where cash_row.user_id = p_user_id
          and cash_row.client_id = line_row.cash_account_client_id
      )
  ) then
    raise exception using errcode = '23503', message = 'missing ledger account relation';
  end if;

  select coalesce(jsonb_agg(conflict_row), '[]'::jsonb)
  into v_conflicts
  from (
    select jsonb_build_object(
      'table', 'transaction_events',
      'client_id', input_row.client_id,
      'reason', 'server_newer',
      'client_last_modified_at', input_row.last_modified_at,
      'server_last_modified_at', server_row.last_modified_at
    ) as conflict_row
    from _sync_events_input input_row
    join public.transaction_events server_row
      on server_row.user_id = p_user_id
     and server_row.client_id = input_row.client_id
    where server_row.last_modified_at > input_row.last_modified_at
    union all
    select jsonb_build_object(
      'table', 'transaction_lines',
      'client_id', input_row.client_id,
      'reason', 'server_newer',
      'client_last_modified_at', input_row.last_modified_at,
      'server_last_modified_at', server_row.last_modified_at
    )
    from _sync_lines_input input_row
    join public.transaction_lines server_row
      on server_row.user_id = p_user_id
     and server_row.client_id = input_row.client_id
    where server_row.last_modified_at > input_row.last_modified_at
  ) conflicts;

  if jsonb_array_length(v_conflicts) > 0 then
    return jsonb_build_object('ok', false, 'conflicts', v_conflicts);
  end if;

  create temporary table _sync_affected_fx_events (
    event_client_id uuid primary key
  ) on commit drop;

  insert into _sync_affected_fx_events(event_client_id)
  select client_id
  from _sync_events_input
  where kind = 'fx_exchange' and deleted_at is null
  union
  select distinct line_row.event_client_id
  from _sync_lines_input line_row
  join public.transaction_events event_row
    on event_row.user_id = p_user_id
   and event_row.client_id = line_row.event_client_id
  where event_row.kind = 'fx_exchange'
    and event_row.deleted_at is null
    and not exists (
      select 1
      from _sync_events_input input_event
      where input_event.client_id = event_row.client_id
        and input_event.deleted_at is not null
    );

  create temporary table _sync_effective_fx_lines (
    event_client_id uuid,
    line_client_id uuid,
    asset_client_id uuid,
    cash_account_client_id uuid,
    action text,
    currency_code text,
    cash_delta double precision,
    fx_rate double precision
  ) on commit drop;

  insert into _sync_effective_fx_lines
  select
    event_row.client_id,
    line_row.client_id,
    asset_row.client_id,
    cash_row.client_id,
    line_row.action,
    upper(line_row.currency_code),
    line_row.cash_delta,
    line_row.fx_rate
  from public.transaction_lines line_row
  join public.transaction_events event_row on event_row.id = line_row.event_id
  left join public.assets asset_row on asset_row.id = line_row.asset_id
  left join public.cash_accounts cash_row on cash_row.id = line_row.cash_account_id
  join _sync_affected_fx_events affected
    on affected.event_client_id = event_row.client_id
  where event_row.user_id = p_user_id
    and line_row.user_id = p_user_id
    and line_row.deleted_at is null
    and not exists (
      select 1 from _sync_lines_input input_row
      where input_row.client_id = line_row.client_id
    );

  insert into _sync_effective_fx_lines
  select
    input_row.event_client_id,
    input_row.client_id,
    input_row.asset_client_id,
    input_row.cash_account_client_id,
    input_row.action,
    upper(input_row.currency_code),
    input_row.cash_delta,
    input_row.fx_rate
  from _sync_lines_input input_row
  join _sync_affected_fx_events affected
    on affected.event_client_id = input_row.event_client_id
  where input_row.deleted_at is null;

  if exists (
    select 1
    from _sync_affected_fx_events affected
    left join _sync_effective_fx_lines line_row
      on line_row.event_client_id = affected.event_client_id
    group by affected.event_client_id
    having count(line_row.line_client_id) <> 2
      or count(*) filter (where line_row.action = 'fx_out') <> 1
      or count(*) filter (where line_row.action = 'fx_in') <> 1
  ) then
    raise exception using errcode = '22023', message = 'fx exchange must contain exactly one fx_out and one fx_in';
  end if;

  if exists (
    select 1
    from _sync_effective_fx_lines out_line
    join _sync_effective_fx_lines in_line
      on in_line.event_client_id = out_line.event_client_id
     and in_line.action = 'fx_in'
    left join public.cash_accounts out_cash
      on out_cash.user_id = p_user_id
     and out_cash.client_id = out_line.cash_account_client_id
    left join public.cash_accounts in_cash
      on in_cash.user_id = p_user_id
     and in_cash.client_id = in_line.cash_account_client_id
    left join public.assets out_asset
      on out_asset.user_id = p_user_id
     and out_asset.client_id = out_line.asset_client_id
    left join public.assets in_asset
      on in_asset.user_id = p_user_id
     and in_asset.client_id = in_line.asset_client_id
    where out_line.action = 'fx_out'
      and (
        out_line.cash_account_client_id is null
        or in_line.cash_account_client_id is null
        or out_cash.id is null
        or in_cash.id is null
        or out_asset.id is null
        or in_asset.id is null
        or out_line.cash_account_client_id = in_line.cash_account_client_id
        or out_line.asset_client_id is null
        or in_line.asset_client_id is null
        or out_asset.id <> in_asset.id
        or out_cash.asset_id <> out_asset.id
        or in_cash.asset_id <> in_asset.id
        or upper(out_cash.currency_code) <> out_line.currency_code
        or upper(in_cash.currency_code) <> in_line.currency_code
        or not (
          (out_line.currency_code = 'KRW' and in_line.currency_code = 'USD')
          or (out_line.currency_code = 'USD' and in_line.currency_code = 'KRW')
        )
        or out_line.cash_delta >= 0
        or in_line.cash_delta <= 0
        or out_line.fx_rate is null
        or in_line.fx_rate is null
        or out_line.fx_rate <= 0
        or out_line.fx_rate <> in_line.fx_rate
        or abs(
          in_line.cash_delta - case
            when out_line.currency_code = 'KRW'
              then abs(out_line.cash_delta) / out_line.fx_rate
            else abs(out_line.cash_delta) * out_line.fx_rate
          end
        ) > greatest(
          0.00000001,
          abs(in_line.cash_delta) * 0.000000001
        )
      )
  ) then
    raise exception using errcode = '22023', message = 'invalid fx exchange ledger state';
  end if;

  insert into public.transaction_events (
    user_id, client_id, last_modified_at, deleted_at, occurred_at, kind,
    title, memo, source, flow_category, legacy_source_table,
    legacy_source_id, sort_order, updated_at
  )
  select
    p_user_id, client_id, last_modified_at, deleted_at, occurred_at, kind,
    coalesce(title, ''), coalesce(memo, ''), coalesce(source, 'manual'),
    coalesce(flow_category, 'internal'), legacy_source_table,
    legacy_source_id, coalesce(sort_order, 0), now()
  from _sync_events_input
  on conflict (user_id, client_id) do update set
    last_modified_at = excluded.last_modified_at,
    deleted_at = excluded.deleted_at,
    occurred_at = excluded.occurred_at,
    kind = excluded.kind,
    title = excluded.title,
    memo = excluded.memo,
    source = excluded.source,
    flow_category = excluded.flow_category,
    legacy_source_table = excluded.legacy_source_table,
    legacy_source_id = excluded.legacy_source_id,
    sort_order = excluded.sort_order,
    updated_at = now();

  insert into public.transaction_lines (
    user_id, client_id, last_modified_at, event_id, asset_id, holding_id,
    cash_account_id, deleted_at, legacy_source_table, legacy_source_id,
    action, currency_code, quantity_delta, cash_delta, unit_price,
    gross_amount, fee_amount, tax_amount, cost_basis_delta,
    cost_basis_source_delta, realized_pnl, realized_pnl_source, fx_rate,
    sort_order, updated_at
  )
  select
    p_user_id,
    input_row.client_id,
    input_row.last_modified_at,
    event_row.id,
    asset_row.id,
    holding_row.id,
    cash_row.id,
    input_row.deleted_at,
    input_row.legacy_source_table,
    input_row.legacy_source_id,
    input_row.action,
    coalesce(input_row.currency_code, 'KRW'),
    coalesce(input_row.quantity_delta, 0),
    coalesce(input_row.cash_delta, 0),
    coalesce(input_row.unit_price, 0),
    coalesce(input_row.gross_amount, 0),
    coalesce(input_row.fee_amount, 0),
    coalesce(input_row.tax_amount, 0),
    coalesce(input_row.cost_basis_delta, 0),
    coalesce(input_row.cost_basis_source_delta, 0),
    coalesce(input_row.realized_pnl, 0),
    coalesce(input_row.realized_pnl_source, 'auto'),
    input_row.fx_rate,
    coalesce(input_row.sort_order, 0),
    now()
  from _sync_lines_input input_row
  join public.transaction_events event_row
    on event_row.user_id = p_user_id
   and event_row.client_id = input_row.event_client_id
  left join public.assets asset_row
    on asset_row.user_id = p_user_id
   and asset_row.client_id = input_row.asset_client_id
  left join public.holdings holding_row
    on holding_row.user_id = p_user_id
   and holding_row.client_id = input_row.holding_client_id
  left join public.cash_accounts cash_row
    on cash_row.user_id = p_user_id
   and cash_row.client_id = input_row.cash_account_client_id
  on conflict (user_id, client_id) do update set
    last_modified_at = excluded.last_modified_at,
    event_id = excluded.event_id,
    asset_id = excluded.asset_id,
    holding_id = excluded.holding_id,
    cash_account_id = excluded.cash_account_id,
    deleted_at = excluded.deleted_at,
    legacy_source_table = excluded.legacy_source_table,
    legacy_source_id = excluded.legacy_source_id,
    action = excluded.action,
    currency_code = excluded.currency_code,
    quantity_delta = excluded.quantity_delta,
    cash_delta = excluded.cash_delta,
    unit_price = excluded.unit_price,
    gross_amount = excluded.gross_amount,
    fee_amount = excluded.fee_amount,
    tax_amount = excluded.tax_amount,
    cost_basis_delta = excluded.cost_basis_delta,
    cost_basis_source_delta = excluded.cost_basis_source_delta,
    realized_pnl = excluded.realized_pnl,
    realized_pnl_source = excluded.realized_pnl_source,
    fx_rate = excluded.fx_rate,
    sort_order = excluded.sort_order,
    updated_at = now();

  return jsonb_build_object(
    'ok', true,
    'accepted_event_client_ids', coalesce(
      (select jsonb_agg(client_id order by client_id) from _sync_events_input),
      '[]'::jsonb
    ),
    'accepted_line_client_ids', coalesce(
      (select jsonb_agg(client_id order by client_id) from _sync_lines_input),
      '[]'::jsonb
    ),
    'counts', jsonb_build_object(
      'transaction_events', (select count(*) from _sync_events_input),
      'transaction_lines', (select count(*) from _sync_lines_input)
    )
  );
end;
$$;

revoke all on function public.sync_transaction_ledger_atomic(uuid, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.sync_transaction_ledger_atomic(uuid, jsonb, jsonb)
  to service_role;
