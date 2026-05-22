-- Harden public schema permissions after establishing the remote baseline.
-- Service-role Edge Functions keep their access, while anonymous/authenticated
-- clients are limited to explicit RLS policies and read-only public reference data.

revoke all on table public.api_tokens from anon, authenticated;
alter table public.api_tokens enable row level security;

revoke insert, update, delete, truncate, references, trigger
on table
  public.company_news,
  public.company_news_summaries,
  public.exchange_rates,
  public.market_news,
  public.market_news_summaries
from anon, authenticated;

grant select
on table
  public.company_news,
  public.company_news_summaries,
  public.exchange_rates,
  public.market_news,
  public.market_news_summaries
to anon, authenticated;

alter table public.company_news enable row level security;
alter table public.company_news_summaries enable row level security;
alter table public.exchange_rates enable row level security;
alter table public.market_news enable row level security;
alter table public.market_news_summaries enable row level security;

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

revoke all on function public.recompute_asset_metrics(uuid)
from anon, authenticated;
grant execute on function public.recompute_asset_metrics(uuid)
to service_role;

alter default privileges for role postgres in schema public
revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public
revoke all on sequences from anon, authenticated;
alter default privileges for role postgres in schema public
revoke all on functions from anon, authenticated;
