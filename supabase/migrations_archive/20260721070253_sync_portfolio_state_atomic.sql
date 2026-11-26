create or replace function public.sync_portfolio_state_atomic(
  p_user_id uuid,
  p_holdings jsonb,
  p_cash_accounts jsonb,
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
  v_state_result jsonb;
  v_conflict_detail text;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'p_user_id is required';
  end if;

  -- Serialize all portfolio-state writes for one user. This prevents two
  -- devices from interleaving holding and ledger mutations.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));

  create temporary table _sync_holdings_input (
    client_id uuid,
    last_modified_at timestamptz,
    asset_id bigint,
    deleted_at timestamptz,
    currency_code text,
    market_updated_at timestamptz,
    exchange_code text,
    name text,
    symbol text,
    quantity double precision,
    average_price double precision,
    average_price_source double precision,
    average_price_krw double precision,
    average_purchase_fx_rate double precision,
    cost_basis_krw double precision,
    current_price double precision,
    note text,
    sort_order integer
  ) on commit drop;

  insert into _sync_holdings_input
  select *
  from jsonb_to_recordset(coalesce(p_holdings, '[]'::jsonb)) as holding_row(
    client_id uuid,
    last_modified_at timestamptz,
    asset_id bigint,
    deleted_at timestamptz,
    currency_code text,
    market_updated_at timestamptz,
    exchange_code text,
    name text,
    symbol text,
    quantity double precision,
    average_price double precision,
    average_price_source double precision,
    average_price_krw double precision,
    average_purchase_fx_rate double precision,
    cost_basis_krw double precision,
    current_price double precision,
    note text,
    sort_order integer
  );

  create temporary table _sync_cash_accounts_input (
    client_id uuid,
    last_modified_at timestamptz,
    asset_id bigint,
    deleted_at timestamptz,
    currency_code text,
    name text,
    base_balance double precision,
    balance double precision,
    note text,
    sort_order integer
  ) on commit drop;

  insert into _sync_cash_accounts_input
  select *
  from jsonb_to_recordset(coalesce(p_cash_accounts, '[]'::jsonb)) as cash_row(
    client_id uuid,
    last_modified_at timestamptz,
    asset_id bigint,
    deleted_at timestamptz,
    currency_code text,
    name text,
    base_balance double precision,
    balance double precision,
    note text,
    sort_order integer
  );

  if exists (
    select 1
    from _sync_holdings_input
    where client_id is null
      or last_modified_at is null
      or asset_id is null
      or quantity is null
      or average_price is null
      or cost_basis_krw is null
  ) then
    raise exception using errcode = '22023', message = 'holding identity and calculated values are required';
  end if;

  if exists (
    select 1
    from _sync_holdings_input
    where quantity < 0
      or average_price < 0
      or cost_basis_krw < 0
  ) then
    raise exception using errcode = '22023', message = 'holding calculated values must be non-negative';
  end if;

  if exists (
    select 1
    from _sync_holdings_input
    group by client_id
    having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'duplicate holding client_id';
  end if;

  if exists (
    select 1
    from _sync_cash_accounts_input
    where client_id is null
      or last_modified_at is null
      or asset_id is null
      or base_balance is null
      or balance is null
  ) then
    raise exception using errcode = '22023', message = 'cash account identity and balances are required';
  end if;

  if exists (
    select 1
    from _sync_cash_accounts_input
    group by client_id
    having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'duplicate cash account client_id';
  end if;

  if exists (
    select 1
    from _sync_holdings_input input_row
    where not exists (
      select 1
      from public.assets asset_row
      where asset_row.id = input_row.asset_id
        and asset_row.user_id = p_user_id
    )
  ) then
    raise exception using errcode = '23503', message = 'holding asset relation is missing';
  end if;

  if exists (
    select 1
    from _sync_cash_accounts_input input_row
    where not exists (
      select 1
      from public.assets asset_row
      where asset_row.id = input_row.asset_id
        and asset_row.user_id = p_user_id
    )
  ) then
    raise exception using errcode = '23503', message = 'cash account asset relation is missing';
  end if;

  select coalesce(jsonb_agg(conflict_row), '[]'::jsonb)
  into v_conflicts
  from (
    select jsonb_build_object(
      'table', 'holdings',
      'client_id', input_row.client_id,
      'reason', 'server_newer',
      'client_last_modified_at', input_row.last_modified_at,
      'server_last_modified_at', server_row.last_modified_at
    ) as conflict_row
    from _sync_holdings_input input_row
    join public.holdings server_row
      on server_row.user_id = p_user_id
     and server_row.client_id = input_row.client_id
    where server_row.last_modified_at > input_row.last_modified_at
    union all
    select jsonb_build_object(
      'table', 'cash_accounts',
      'client_id', input_row.client_id,
      'reason', 'server_newer',
      'client_last_modified_at', input_row.last_modified_at,
      'server_last_modified_at', server_row.last_modified_at
    ) as conflict_row
    from _sync_cash_accounts_input input_row
    join public.cash_accounts server_row
      on server_row.user_id = p_user_id
     and server_row.client_id = input_row.client_id
    where server_row.last_modified_at > input_row.last_modified_at
  ) conflicts;

  if jsonb_array_length(v_conflicts) > 0 then
    return jsonb_build_object('ok', false, 'conflicts', v_conflicts);
  end if;

  begin
    insert into public.holdings (
      user_id,
      client_id,
      last_modified_at,
      asset_id,
      deleted_at,
      currency_code,
      market_updated_at,
      exchange_code,
      name,
      symbol,
      quantity,
      average_price,
      average_price_source,
      average_price_krw,
      average_purchase_fx_rate,
      cost_basis_krw,
      current_price,
      note,
      sort_order
    )
    select
      p_user_id,
      input_row.client_id,
      input_row.last_modified_at,
      input_row.asset_id,
      input_row.deleted_at,
      coalesce(input_row.currency_code, 'KRW'),
      input_row.market_updated_at,
      coalesce(input_row.exchange_code, ''),
      coalesce(input_row.name, ''),
      coalesce(input_row.symbol, ''),
      coalesce(input_row.quantity, 0),
      coalesce(input_row.average_price, 0),
      coalesce(input_row.average_price_source, input_row.average_price, 0),
      coalesce(input_row.average_price_krw, input_row.average_price, 0),
      coalesce(input_row.average_purchase_fx_rate, 1),
      coalesce(input_row.cost_basis_krw, 0),
      coalesce(input_row.current_price, 0),
      coalesce(input_row.note, ''),
      coalesce(input_row.sort_order, 0)
    from _sync_holdings_input input_row
    on conflict (user_id, client_id) do update set
      last_modified_at = excluded.last_modified_at,
      asset_id = excluded.asset_id,
      deleted_at = excluded.deleted_at,
      currency_code = excluded.currency_code,
      market_updated_at = excluded.market_updated_at,
      exchange_code = excluded.exchange_code,
      name = excluded.name,
      symbol = excluded.symbol,
      quantity = excluded.quantity,
      average_price = excluded.average_price,
      average_price_source = excluded.average_price_source,
      average_price_krw = excluded.average_price_krw,
      average_purchase_fx_rate = excluded.average_purchase_fx_rate,
      cost_basis_krw = excluded.cost_basis_krw,
      current_price = excluded.current_price,
      note = excluded.note,
      sort_order = excluded.sort_order,
      updated_at = now();

    insert into public.cash_accounts (
      user_id,
      client_id,
      last_modified_at,
      asset_id,
      deleted_at,
      currency_code,
      name,
      base_balance,
      balance,
      note,
      sort_order
    )
    select
      p_user_id,
      input_row.client_id,
      input_row.last_modified_at,
      input_row.asset_id,
      input_row.deleted_at,
      coalesce(input_row.currency_code, 'KRW'),
      coalesce(input_row.name, ''),
      coalesce(input_row.base_balance, 0),
      coalesce(input_row.balance, input_row.base_balance, 0),
      coalesce(input_row.note, ''),
      coalesce(input_row.sort_order, 0)
    from _sync_cash_accounts_input input_row
    on conflict (user_id, client_id) do update set
      last_modified_at = excluded.last_modified_at,
      asset_id = excluded.asset_id,
      deleted_at = excluded.deleted_at,
      currency_code = excluded.currency_code,
      name = excluded.name,
      base_balance = excluded.base_balance,
      balance = excluded.balance,
      note = excluded.note,
      sort_order = excluded.sort_order,
      updated_at = now();

    v_state_result := public.sync_transaction_state_atomic(
      p_user_id,
      p_cash_accounts,
      p_events,
      p_lines
    );

    if coalesce((v_state_result->>'ok')::boolean, false) is not true then
      raise exception using
        errcode = 'P0001',
        message = 'portfolio state conflict',
        detail = v_state_result::text;
    end if;

    -- The editor values are authoritative, but only when their active ledger
    -- totals match. Cost-only adjustments (quantity_delta = 0) are valid.
    if exists (
      select 1
      from _sync_holdings_input input_row
      join public.holdings holding_row
        on holding_row.user_id = p_user_id
       and holding_row.client_id = input_row.client_id
      left join lateral (
        select
          coalesce(sum(line_row.quantity_delta), 0) as quantity,
          coalesce(sum(line_row.cost_basis_delta), 0) as cost_basis,
          coalesce(sum(line_row.cost_basis_source_delta), 0) as source_cost_basis
        from public.transaction_lines line_row
        join public.transaction_events event_row
          on event_row.id = line_row.event_id
         and event_row.user_id = p_user_id
        where line_row.user_id = p_user_id
          and line_row.holding_id = holding_row.id
          and line_row.deleted_at is null
          and event_row.deleted_at is null
          and event_row.source not in ('history_display', 'record_only')
      ) ledger on true
      where input_row.deleted_at is null
        and (
          abs(coalesce(input_row.quantity, 0) - ledger.quantity) > 0.0000001
          or abs(coalesce(input_row.cost_basis_krw, 0) - ledger.cost_basis) > 0.0001
          or abs(
            coalesce(
              input_row.average_price_source * input_row.quantity,
              input_row.cost_basis_krw,
              0
            ) - ledger.source_cost_basis
          ) > 0.0001
        )
    ) then
      raise exception using errcode = '22023', message = 'holding and ledger totals do not match';
    end if;

    if exists (
      select 1
      from public.transaction_lines line_row
      join public.transaction_events event_row
        on event_row.id = line_row.event_id
       and event_row.user_id = p_user_id
      join public.holdings holding_row
        on holding_row.id = line_row.holding_id
       and holding_row.user_id = p_user_id
      join _sync_holdings_input input_row
        on input_row.client_id = holding_row.client_id
      where line_row.user_id = p_user_id
        and line_row.deleted_at is null
        and event_row.deleted_at is null
        and line_row.action = 'manual_adjustment'
        and (
          event_row.kind <> 'holding_adjustment'
          or event_row.source <> 'ledger'
          or line_row.cash_delta <> 0
          or line_row.realized_pnl <> 0
        )
    ) then
      raise exception using errcode = '22023', message = 'invalid holding adjustment ledger pair';
    end if;

    if exists (
      select 1
      from public.transaction_lines line_row
      join public.transaction_events event_row
        on event_row.id = line_row.event_id
       and event_row.user_id = p_user_id
      join public.holdings holding_row
        on holding_row.id = line_row.holding_id
       and holding_row.user_id = p_user_id
      join _sync_holdings_input input_row
        on input_row.client_id = holding_row.client_id
      where line_row.user_id = p_user_id
        and line_row.deleted_at is null
        and event_row.deleted_at is null
        and line_row.action = 'manual_adjustment'
      group by holding_row.id
      having count(*) > 1
    ) then
      raise exception using errcode = '22023', message = 'multiple active holding adjustments are not allowed';
    end if;
  exception
    when sqlstate 'P0001' then
      get stacked diagnostics v_conflict_detail = pg_exception_detail;
      return coalesce(v_conflict_detail::jsonb, jsonb_build_object('ok', false));
  end;

  return v_state_result || jsonb_build_object(
    'accepted_holding_client_ids', (
      select coalesce(jsonb_agg(client_id order by client_id), '[]'::jsonb)
      from _sync_holdings_input
    ),
    'accepted_holding_count', (
      select count(*)
      from _sync_holdings_input
    )
  );
end;
$$;

revoke all on function public.sync_portfolio_state_atomic(uuid, jsonb, jsonb, jsonb, jsonb) from public;
revoke all on function public.sync_portfolio_state_atomic(uuid, jsonb, jsonb, jsonb, jsonb) from anon;
revoke all on function public.sync_portfolio_state_atomic(uuid, jsonb, jsonb, jsonb, jsonb) from authenticated;
grant execute on function public.sync_portfolio_state_atomic(uuid, jsonb, jsonb, jsonb, jsonb) to service_role;
