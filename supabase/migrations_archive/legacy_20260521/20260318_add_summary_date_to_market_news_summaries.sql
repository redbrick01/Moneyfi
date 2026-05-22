alter table public.market_news_summaries
add column if not exists summary_date date;

update public.market_news_summaries
set summary_date = created_at::date
where summary_date is null;

alter table public.market_news_summaries
alter column summary_date set not null;

drop index if exists public.market_news_summaries_category_key;

create unique index if not exists market_news_summaries_category_summary_date_key
on public.market_news_summaries (category, summary_date);

create index if not exists market_news_summaries_category_summary_date_idx
on public.market_news_summaries (category, summary_date desc);
