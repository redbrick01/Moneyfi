-- Existing snapshots can share a baseline because revisions are compared per date.
alter table public.daily_portfolio_snapshots add column sync_revision uuid not null
  default '00000000-0000-0000-0000-000000000000';
alter table public.daily_portfolio_snapshots alter column sync_revision set default gen_random_uuid();

create schema if not exists private;
create function private.set_snapshot_revision() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.sync_revision := gen_random_uuid();
  return new;
end $$;
create trigger set_snapshot_revision before update on public.daily_portfolio_snapshots
for each row execute function private.set_snapshot_revision();

-- Statement transition tables coalesce bulk changes to one bump per affected day.
create function private.touch_snapshot_parents() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  affected text;
  predicate text;
begin
  if tg_table_name = 'snapshot_notes' then
    affected := 'select user_id, snapshot_date from ';
    predicate := '(s.user_id, s.snapshot_date) in ';
  else
    affected := 'select snapshot_id from ';
    predicate := 's.id in ';
  end if;
  execute 'update public.daily_portfolio_snapshots s set sync_revision = s.sync_revision where ' ||
    predicate || '(' || case tg_op
      when 'INSERT' then affected || 'new_rows'
      when 'DELETE' then affected || 'old_rows'
      else affected || 'old_rows union ' || affected || 'new_rows' end || ')';
  return null;
end $$;
revoke all on function private.touch_snapshot_parents() from public, anon, authenticated;
do $$
declare t text;
begin
  foreach t in array array['daily_portfolio_snapshot_items','daily_portfolio_snapshot_holding_items',
                           'daily_portfolio_snapshot_cash_accounts','snapshot_notes'] loop
    execute format('create trigger snapshot_insert after insert on public.%I referencing new table as new_rows for each statement execute function private.touch_snapshot_parents()', t);
    execute format('create trigger snapshot_delete after delete on public.%I referencing old table as old_rows for each statement execute function private.touch_snapshot_parents()', t);
    execute format('create trigger snapshot_update after update on public.%I referencing old table as old_rows new table as new_rows for each statement execute function private.touch_snapshot_parents()', t);
  end loop;
end $$;

create function public.portfolio_snapshot_manifest(p_user_id uuid) returns jsonb
language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_object_agg(snapshot_date, sync_revision), '{}')
  from public.daily_portfolio_snapshots where user_id = p_user_id
$$;
revoke all on function public.portfolio_snapshot_manifest(uuid) from public, anon, authenticated;
grant execute on function public.portfolio_snapshot_manifest(uuid) to service_role;
