alter table public.transaction_events
  add column if not exists flow_category text not null default 'internal';

update public.transaction_events
set flow_category = 'internal'
where flow_category is null
   or flow_category = '';

update public.transaction_events te
set flow_category = 'external_deposit'
where te.kind = 'cash_flow'
  and te.deleted_at is null
  and exists (
    select 1
    from public.transaction_lines tl
    where tl.event_id = te.id
      and tl.deleted_at is null
      and tl.action = 'deposit'
  );

update public.transaction_events te
set flow_category = 'external_withdrawal'
where te.kind = 'cash_flow'
  and te.deleted_at is null
  and exists (
    select 1
    from public.transaction_lines tl
    where tl.event_id = te.id
      and tl.deleted_at is null
      and tl.action = 'withdrawal'
  );

create index if not exists transaction_events_user_id_flow_category_idx
  on public.transaction_events using btree (user_id, flow_category);

comment on column public.transaction_events.flow_category is
  'External cash-flow classification: external_deposit, external_withdrawal, or internal.';
