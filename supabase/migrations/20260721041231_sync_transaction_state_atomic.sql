create or replace function public.sync_transaction_state_atomic(
  p_user_id uuid,
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
  v_ledger_result jsonb;
begin
  if p_user_id is null then
    raise exception using errcode = '22023', message = 'p_user_id is required';
  end if;

  create temporary table _sync_cash_balances_input (
    client_id uuid,
    last_modified_at timestamptz,
    base_balance double precision,
    balance double precision
  ) on commit drop;

  insert into _sync_cash_balances_input
  select *
  from jsonb_to_recordset(coalesce(p_cash_accounts, '[]'::jsonb)) as cash_row(
    client_id uuid,
    last_modified_at timestamptz,
    base_balance double precision,
    balance double precision
  );

  if exists (
    select 1
    from _sync_cash_balances_input
    where client_id is null or last_modified_at is null
  ) then
    raise exception using errcode = '22023', message = 'cash account client_id and last_modified_at are required';
  end if;

  if exists (
    select 1
    from _sync_cash_balances_input
    group by client_id
    having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'duplicate cash account client_id';
  end if;

  if exists (
    select 1
    from _sync_cash_balances_input input_row
    where not exists (
      select 1
      from public.cash_accounts cash_row
      where cash_row.user_id = p_user_id
        and cash_row.client_id = input_row.client_id
    )
  ) then
    raise exception using errcode = '23503', message = 'cash account relation is missing';
  end if;

  select coalesce(jsonb_agg(conflict_row), '[]'::jsonb)
  into v_conflicts
  from (
    select jsonb_build_object(
      'table', 'cash_accounts',
      'client_id', input_row.client_id,
      'reason', 'server_newer',
      'client_last_modified_at', input_row.last_modified_at,
      'server_last_modified_at', server_row.last_modified_at
    ) as conflict_row
    from _sync_cash_balances_input input_row
    join public.cash_accounts server_row
      on server_row.user_id = p_user_id
     and server_row.client_id = input_row.client_id
    where server_row.last_modified_at > input_row.last_modified_at
  ) conflicts;

  if jsonb_array_length(v_conflicts) > 0 then
    return jsonb_build_object('ok', false, 'conflicts', v_conflicts);
  end if;

  v_ledger_result := public.sync_transaction_ledger_atomic(
    p_user_id,
    p_events,
    p_lines
  );

  if coalesce((v_ledger_result->>'ok')::boolean, false) is not true then
    return v_ledger_result;
  end if;

  update public.cash_accounts cash_row
  set
    base_balance = coalesce(input_row.base_balance, 0),
    balance = coalesce(input_row.balance, input_row.base_balance, 0),
    last_modified_at = input_row.last_modified_at,
    updated_at = now()
  from _sync_cash_balances_input input_row
  where cash_row.user_id = p_user_id
    and cash_row.client_id = input_row.client_id;

  return v_ledger_result || jsonb_build_object(
    'accepted_cash_account_client_ids', (
      select coalesce(jsonb_agg(client_id order by client_id), '[]'::jsonb)
      from _sync_cash_balances_input
    ),
    'accepted_cash_account_count', (
      select count(*)
      from _sync_cash_balances_input
    )
  );
end;
$$;

revoke all on function public.sync_transaction_state_atomic(uuid, jsonb, jsonb, jsonb) from public;
revoke all on function public.sync_transaction_state_atomic(uuid, jsonb, jsonb, jsonb) from anon;
revoke all on function public.sync_transaction_state_atomic(uuid, jsonb, jsonb, jsonb) from authenticated;
grant execute on function public.sync_transaction_state_atomic(uuid, jsonb, jsonb, jsonb) to service_role;
