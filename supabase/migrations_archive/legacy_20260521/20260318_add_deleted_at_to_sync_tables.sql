alter table if exists public.assets
  add column if not exists deleted_at timestamptz;

alter table if exists public.holdings
  add column if not exists deleted_at timestamptz;

alter table if exists public.transactions
  add column if not exists deleted_at timestamptz;

alter table if exists public.cash_accounts
  add column if not exists deleted_at timestamptz;

alter table if exists public.cash_transactions
  add column if not exists deleted_at timestamptz;

create index if not exists assets_user_id_deleted_at_idx
  on public.assets (user_id, deleted_at);

create index if not exists holdings_user_id_deleted_at_idx
  on public.holdings (user_id, deleted_at);

create index if not exists transactions_user_id_deleted_at_idx
  on public.transactions (user_id, deleted_at);

create index if not exists cash_accounts_user_id_deleted_at_idx
  on public.cash_accounts (user_id, deleted_at);

create index if not exists cash_transactions_user_id_deleted_at_idx
  on public.cash_transactions (user_id, deleted_at);
