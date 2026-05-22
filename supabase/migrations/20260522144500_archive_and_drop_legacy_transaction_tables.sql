-- Archive and remove the legacy transaction tables from the remote schema.
--
-- transaction_events and transaction_lines are now the source of truth.
-- The legacy public.transactions and public.cash_transactions tables are kept
-- as timestamped archive copies before being dropped from the public API.

do $$
declare
  missing_transaction_ledger_count integer := 0;
  missing_cash_transaction_ledger_count integer := 0;
begin
  if to_regclass('public.transactions') is not null then
    select count(*)
      into missing_transaction_ledger_count
    from public.transactions t
    where t.deleted_at is null
      and not exists (
        select 1
        from public.transaction_events te
        join public.transaction_lines tl
          on tl.event_id = te.id
         and tl.deleted_at is null
        where te.deleted_at is null
          and te.legacy_source_table = 'transactions'
          and te.legacy_source_id = t.id
      );
  end if;

  if to_regclass('public.cash_transactions') is not null then
    select count(*)
      into missing_cash_transaction_ledger_count
    from public.cash_transactions c
    where c.deleted_at is null
      and not exists (
        select 1
        from public.transaction_lines tl
        join public.transaction_events te
          on te.id = tl.event_id
         and te.deleted_at is null
        where tl.deleted_at is null
          and tl.legacy_source_table = 'cash_transactions'
          and tl.legacy_source_id = c.id
      );
  end if;

  if missing_transaction_ledger_count > 0 then
    raise exception
      'Cannot drop public.transactions: % active rows are not represented in the normalized ledger',
      missing_transaction_ledger_count;
  end if;

  if missing_cash_transaction_ledger_count > 0 then
    raise exception
      'Cannot drop public.cash_transactions: % active rows are not represented in the normalized ledger',
      missing_cash_transaction_ledger_count;
  end if;
end $$;

create schema if not exists legacy_archive;

do $$
begin
  if to_regclass('public.transactions') is not null then
    create table if not exists legacy_archive.transactions_20260522
      as table public.transactions with data;

    comment on table legacy_archive.transactions_20260522 is
      'Archived copy of public.transactions before the normalized ledger became the only remote transaction store.';
  end if;

  if to_regclass('public.cash_transactions') is not null then
    create table if not exists legacy_archive.cash_transactions_20260522
      as table public.cash_transactions with data;

    comment on table legacy_archive.cash_transactions_20260522 is
      'Archived copy of public.cash_transactions before the normalized ledger became the only remote transaction store.';
  end if;
end $$;

revoke all on schema legacy_archive from anon, authenticated;
grant usage on schema legacy_archive to service_role;
grant select on all tables in schema legacy_archive to service_role;

drop table if exists public.cash_transactions cascade;
drop table if exists public.transactions cascade;
