create table if not exists public.codex_news_sources (
  id bigserial primary key,
  summary_type text not null
    check (summary_type = any (array['market'::text, 'company'::text])),
  summary_date date not null,
  category text,
  symbol text,
  issue_id text,
  title text not null,
  source_name text,
  url text not null,
  published_at timestamptz,
  collected_at timestamptz not null default now(),
  raw_summary text,
  constraint codex_news_sources_unique_source
    unique nulls not distinct (
      summary_type,
      summary_date,
      category,
      symbol,
      url
    )
);

comment on table public.codex_news_sources is
  'Source URLs and evidence snippets for Codex-generated market and company news summaries.';
comment on column public.codex_news_sources.summary_type is
  'market or company, matching the summary table where the issue is stored.';
comment on column public.codex_news_sources.issue_id is
  'Issue id used inside the related summary_json issues array.';
comment on column public.codex_news_sources.raw_summary is
  'Short evidence summary derived from the source during Codex web collection.';

create index if not exists idx_codex_news_sources_summary
  on public.codex_news_sources (
    summary_date desc,
    summary_type,
    category,
    symbol
  );
create index if not exists idx_codex_news_sources_issue
  on public.codex_news_sources (
    summary_type,
    summary_date desc,
    issue_id
  );

alter table public.codex_news_sources enable row level security;

revoke all on public.codex_news_sources from anon, authenticated;
