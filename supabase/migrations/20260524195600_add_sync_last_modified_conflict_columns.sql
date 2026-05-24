-- Add explicit sync conflict timestamps to the ledger-only core sync tables.
-- Client pushes are accepted only when incoming last_modified_at is newer than
-- or equal to the current server row timestamp.

alter table public.assets
  add column if not exists last_modified_at timestamp with time zone;
alter table public.holdings
  add column if not exists last_modified_at timestamp with time zone;
alter table public.cash_accounts
  add column if not exists last_modified_at timestamp with time zone;
alter table public.transaction_events
  add column if not exists last_modified_at timestamp with time zone;
alter table public.transaction_lines
  add column if not exists last_modified_at timestamp with time zone;

update public.assets
set last_modified_at = coalesce(last_modified_at, updated_at)
where last_modified_at is null;

update public.holdings
set last_modified_at = coalesce(last_modified_at, updated_at)
where last_modified_at is null;

update public.cash_accounts
set last_modified_at = coalesce(last_modified_at, updated_at)
where last_modified_at is null;

update public.transaction_events
set last_modified_at = coalesce(last_modified_at, updated_at)
where last_modified_at is null;

update public.transaction_lines
set last_modified_at = coalesce(last_modified_at, updated_at)
where last_modified_at is null;

create index if not exists idx_assets_sync_last_modified
  on public.assets (user_id, client_id, last_modified_at);
create index if not exists idx_holdings_sync_last_modified
  on public.holdings (user_id, client_id, last_modified_at);
create index if not exists idx_cash_accounts_sync_last_modified
  on public.cash_accounts (user_id, client_id, last_modified_at);
create index if not exists idx_transaction_events_sync_last_modified
  on public.transaction_events (user_id, client_id, last_modified_at);
create index if not exists idx_transaction_lines_sync_last_modified
  on public.transaction_lines (user_id, client_id, last_modified_at);
