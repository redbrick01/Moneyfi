alter table public.daily_portfolio_snapshots
add column if not exists user_id uuid;

alter table public.daily_portfolio_snapshot_items
add column if not exists user_id uuid;

alter table public.daily_portfolio_snapshot_holding_items
add column if not exists user_id uuid;

alter table public.daily_portfolio_snapshot_cash_accounts
add column if not exists user_id uuid;

alter table public.snapshot_notes
add column if not exists user_id uuid,
add column if not exists created_at timestamptz not null default now(),
add column if not exists updated_at timestamptz not null default now();

create unique index if not exists daily_portfolio_snapshots_user_date_idx
on public.daily_portfolio_snapshots (user_id, snapshot_date);

create unique index if not exists snapshot_notes_user_date_idx
on public.snapshot_notes (user_id, snapshot_date);
