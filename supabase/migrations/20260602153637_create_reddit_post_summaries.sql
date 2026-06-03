create table if not exists public.reddit_post_summaries (
  post_reddit_id text primary key,
  subreddit text not null,
  title text not null,
  url text not null,
  score integer,
  comment_count integer,
  posted_at timestamptz,
  scraped_at timestamptz not null default now(),
  model text not null,
  is_valuable integer not null default 0,
  quality_label text not null,
  confidence double precision,
  tickers_json jsonb not null default '[]'::jsonb,
  title_ko text not null default '',
  post_summary_ko text not null default '',
  comments_summary_ko text not null default '',
  analysis_reasons_ko text not null default '',
  analyzed_at timestamptz not null default now(),
  importance_model text,
  importance_label text,
  importance_score integer,
  category_label text not null default '기타',
  importance_reasons_ko text not null default '',
  judged_at timestamptz,
  insight_model text,
  insight_ko text not null default '',
  insight_generated_at timestamptz,
  synced_at timestamptz not null default now()
);

create index if not exists idx_reddit_post_summaries_posted_at
  on public.reddit_post_summaries (posted_at desc);
create index if not exists idx_reddit_post_summaries_subreddit
  on public.reddit_post_summaries (subreddit, posted_at desc);
create index if not exists idx_reddit_post_summaries_importance
  on public.reddit_post_summaries (importance_score desc, posted_at desc);

alter table public.reddit_post_summaries enable row level security;

revoke all on public.reddit_post_summaries from anon, authenticated;
grant select on public.reddit_post_summaries to authenticated;

drop policy if exists "Authenticated users can read reddit post summaries"
  on public.reddit_post_summaries;

create policy "Authenticated users can read reddit post summaries"
on public.reddit_post_summaries
for select
to authenticated
using (true);
