-- Final client-role permission hardening.
--
-- Remote inspection on 2026-05-24 showed RLS enabled on public tables, but
-- broad anon/authenticated ACLs still existed on user data tables, snapshot
-- tables, ledger tables, sequences, and the trigger helper function.

revoke all on all tables in schema public from anon, authenticated;

grant select
on table
  public.company_news,
  public.company_news_summaries,
  public.exchange_rates,
  public.market_news,
  public.market_news_summaries
to anon, authenticated;

revoke all on all sequences in schema public from anon, authenticated;

revoke all on function public.set_updated_at()
from anon, authenticated;
revoke all on function public.recompute_asset_metrics(uuid)
from anon, authenticated;

alter table public.api_tokens enable row level security;
alter table public.asset_allocation_targets enable row level security;
alter table public.assets enable row level security;
alter table public.cash_accounts enable row level security;
alter table public.company_news enable row level security;
alter table public.company_news_summaries enable row level security;
alter table public.daily_portfolio_snapshot_cash_accounts
  enable row level security;
alter table public.daily_portfolio_snapshot_holding_items
  enable row level security;
alter table public.daily_portfolio_snapshot_items enable row level security;
alter table public.daily_portfolio_snapshots enable row level security;
alter table public.exchange_rates enable row level security;
alter table public.holdings enable row level security;
alter table public.market_news enable row level security;
alter table public.market_news_summaries enable row level security;
alter table public.portfolio_diagnosis_history enable row level security;
alter table public.snapshot_notes enable row level security;
alter table public.transaction_events enable row level security;
alter table public.transaction_lines enable row level security;

drop policy if exists asset_allocation_targets_own_rows
  on public.asset_allocation_targets;
create policy asset_allocation_targets_own_rows
on public.asset_allocation_targets
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists assets_own_rows on public.assets;
create policy assets_own_rows
on public.assets
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists cash_accounts_own_rows on public.cash_accounts;
create policy cash_accounts_own_rows
on public.cash_accounts
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists daily_portfolio_snapshot_cash_accounts_own_rows
  on public.daily_portfolio_snapshot_cash_accounts;
create policy daily_portfolio_snapshot_cash_accounts_own_rows
on public.daily_portfolio_snapshot_cash_accounts
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists daily_portfolio_snapshot_holding_items_own_rows
  on public.daily_portfolio_snapshot_holding_items;
create policy daily_portfolio_snapshot_holding_items_own_rows
on public.daily_portfolio_snapshot_holding_items
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists daily_portfolio_snapshot_items_own_rows
  on public.daily_portfolio_snapshot_items;
create policy daily_portfolio_snapshot_items_own_rows
on public.daily_portfolio_snapshot_items
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists daily_portfolio_snapshots_own_rows
  on public.daily_portfolio_snapshots;
create policy daily_portfolio_snapshots_own_rows
on public.daily_portfolio_snapshots
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists holdings_own_rows on public.holdings;
create policy holdings_own_rows
on public.holdings
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists snapshot_notes_own_rows on public.snapshot_notes;
create policy snapshot_notes_own_rows
on public.snapshot_notes
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists transaction_events_own_rows
  on public.transaction_events;
create policy transaction_events_own_rows
on public.transaction_events
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists transaction_lines_own_rows
  on public.transaction_lines;
create policy transaction_lines_own_rows
on public.transaction_lines
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can read own diagnosis history"
  on public.portfolio_diagnosis_history;
create policy "Users can read own diagnosis history"
on public.portfolio_diagnosis_history
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists company_news_public_read on public.company_news;
create policy company_news_public_read
on public.company_news
for select
to anon, authenticated
using (true);

drop policy if exists company_news_summaries_public_read
  on public.company_news_summaries;
create policy company_news_summaries_public_read
on public.company_news_summaries
for select
to anon, authenticated
using (true);

drop policy if exists exchange_rates_public_read on public.exchange_rates;
create policy exchange_rates_public_read
on public.exchange_rates
for select
to anon, authenticated
using (true);

drop policy if exists market_news_public_read on public.market_news;
create policy market_news_public_read
on public.market_news
for select
to anon, authenticated
using (true);

drop policy if exists market_news_summaries_public_read
  on public.market_news_summaries;
create policy market_news_summaries_public_read
on public.market_news_summaries
for select
to anon, authenticated
using (true);

alter default privileges for role postgres in schema public
revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public
revoke all on sequences from anon, authenticated;
alter default privileges for role postgres in schema public
revoke all on functions from anon, authenticated;
