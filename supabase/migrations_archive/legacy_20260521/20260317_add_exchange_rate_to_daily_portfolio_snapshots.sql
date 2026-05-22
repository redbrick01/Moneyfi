alter table public.daily_portfolio_snapshots
add column if not exists exchange_rate double precision not null default 1;
