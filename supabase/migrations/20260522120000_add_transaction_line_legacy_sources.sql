alter table public.transaction_lines
  add column if not exists legacy_source_table text;

alter table public.transaction_lines
  add column if not exists legacy_source_id bigint;

update public.transaction_lines tl
set
  legacy_source_table = 'transactions',
  legacy_source_id = te.legacy_source_id
from public.transaction_events te
where tl.event_id = te.id
  and tl.legacy_source_id is null
  and tl.holding_id is not null
  and te.legacy_source_table = 'transactions';

update public.transaction_lines tl
set
  legacy_source_table = 'cash_transactions',
  legacy_source_id = c.id
from public.transaction_events te
join public.cash_transactions c
  on c.user_id = te.user_id
 and (
      c.id = te.legacy_source_id
      or c.linked_transaction_id = te.legacy_source_id
      or te.legacy_source_id = c.linked_transaction_id
 )
where tl.event_id = te.id
  and tl.legacy_source_id is null
  and tl.cash_account_id = c.cash_account_id
  and te.legacy_source_table = 'cash_transactions';

update public.transaction_lines tl
set
  legacy_source_table = 'cash_transactions',
  legacy_source_id = c.id
from public.transaction_events te
join public.cash_transactions c
  on c.user_id = te.user_id
 and c.linked_transaction_id = -te.legacy_source_id
where tl.event_id = te.id
  and tl.legacy_source_id is null
  and tl.action = 'settlement'
  and te.legacy_source_table = 'transactions';
