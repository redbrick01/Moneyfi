insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  source,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  t.user_id,
  t.date,
  case
    when t.type = '초기' then 'opening_balance'
    when t.type in ('매수', '매도') then 'trade'
    when t.type in ('배당', '이자') then 'income'
    else 'adjustment'
  end,
  t.name,
  'legacy',
  'transactions',
  t.id,
  t.sort_order
from public.transactions t
where t.deleted_at is null
  and not exists (
    select 1
    from public.transaction_events e
    where e.user_id = t.user_id
      and e.legacy_source_table = 'transactions'
      and e.legacy_source_id = t.id
  );

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
  cost_basis_delta,
  realized_pnl,
  sort_order
)
select
  t.user_id,
  e.id,
  t.asset_id,
  t.holding_id,
  case
    when t.type = '초기' then 'opening_quantity'
    when t.type = '매수' then 'buy'
    when t.type = '매도' then 'sell'
    when t.type = '배당' then 'dividend'
    when t.type = '이자' then 'interest'
    else 'adjustment'
  end,
  coalesce(h.currency_code, 'KRW'),
  case
    when t.type in ('초기', '매수') then coalesce(t.quantity_value, 0)
    when t.type = '매도' then -coalesce(t.quantity_value, 0)
    else 0
  end,
  0,
  coalesce(t.unit_price, 0),
  coalesce(t.gross_amount, 0),
  case
    when t.type in ('초기', '매수') then coalesce(t.gross_amount, 0)
    when t.type = '매도' then -(
      coalesce(t.gross_amount, 0) - coalesce(t.realized_profit_amount, 0)
    )
    else 0
  end,
  coalesce(t.realized_profit_amount, 0),
  0
from public.transactions t
join public.transaction_events e
  on e.user_id = t.user_id
 and e.legacy_source_table = 'transactions'
 and e.legacy_source_id = t.id
left join public.holdings h
  on h.id = t.holding_id
where t.deleted_at is null
  and not exists (
    select 1
    from public.transaction_lines l
    where l.event_id = e.id
      and l.action in ('opening_quantity', 'buy', 'sell', 'dividend', 'interest', 'adjustment')
      and l.sort_order = 0
  );

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
  sort_order
)
select
  c.user_id,
  e.id,
  c.asset_id,
  c.cash_account_id,
  'settlement',
  coalesce(ca.currency_code, 'KRW'),
  0,
  coalesce(c.cash_flow_amount, 0),
  0,
  coalesce(c.amount_value, 0),
  1
from public.cash_transactions c
join public.transaction_events e
  on e.user_id = c.user_id
 and e.legacy_source_table = 'transactions'
 and e.legacy_source_id = abs(c.linked_transaction_id)
left join public.cash_accounts ca
  on ca.id = c.cash_account_id
where c.deleted_at is null
  and c.linked_transaction_id is not null
  and not exists (
    select 1
    from public.transaction_lines l
    where l.event_id = e.id
      and l.action = 'settlement'
      and l.cash_account_id = c.cash_account_id
  );

insert into public.transaction_events (
  user_id,
  occurred_at,
  kind,
  title,
  source,
  legacy_source_table,
  legacy_source_id,
  sort_order
)
select
  c.user_id,
  c.date,
  case
    when c.type = '이체' then 'cash_transfer'
    when c.type = '환전' then 'fx_exchange'
    when c.type in ('입금', '출금') then 'cash_flow'
    else 'adjustment'
  end,
  c.name,
  'legacy',
  'cash_transactions',
  c.id,
  c.sort_order
from public.cash_transactions c
where c.deleted_at is null
  and (
    c.linked_transaction_id is null
    or not exists (
      select 1 from public.transactions t
      where t.id = abs(c.linked_transaction_id)
    )
  )
  and not exists (
    select 1
    from public.transaction_events e
    where e.user_id = c.user_id
      and e.legacy_source_table = 'cash_transactions'
      and e.legacy_source_id = c.id
  );

insert into public.transaction_lines (
  user_id,
  event_id,
  asset_id,
  cash_account_id,
  action,
  currency_code,
  cash_delta,
  gross_amount,
  sort_order
)
select
  c.user_id,
  e.id,
  c.asset_id,
  c.cash_account_id,
  case
    when c.type = '입금' then 'deposit'
    when c.type = '출금' then 'withdrawal'
    when c.type = '이체' then 'transfer_out'
    when c.type = '환전' then 'fx_out'
    else 'adjustment'
  end,
  coalesce(ca.currency_code, 'KRW'),
  coalesce(c.cash_flow_amount, 0),
  coalesce(c.amount_value, 0),
  0
from public.cash_transactions c
join public.transaction_events e
  on e.user_id = c.user_id
 and e.legacy_source_table = 'cash_transactions'
 and e.legacy_source_id = c.id
left join public.cash_accounts ca
  on ca.id = c.cash_account_id
where c.deleted_at is null
  and (
    c.linked_transaction_id is null
    or not exists (
      select 1 from public.transactions t
      where t.id = abs(c.linked_transaction_id)
    )
  )
  and not exists (
    select 1
    from public.transaction_lines l
    where l.event_id = e.id
      and l.sort_order = 0
  );
