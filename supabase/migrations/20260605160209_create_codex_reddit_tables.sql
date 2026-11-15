create table if not exists public.codex_reddit_posts (
  reddit_post_id text primary key,
  subreddit text not null,
  title text not null,
  permalink text not null,
  author text,
  posted_at timestamptz,
  comment_count integer not null default 0,
  body text not null default '',
  collected_at timestamptz not null default now(),
  collection_status text not null default 'collected',
  block_reason text
);

create index if not exists codex_reddit_posts_subreddit_posted_at_idx
  on public.codex_reddit_posts (subreddit, posted_at desc);

create table if not exists public.codex_reddit_comments (
  reddit_comment_id text primary key,
  reddit_post_id text not null,
  author text,
  body text not null default '',
  score integer,
  posted_at timestamptz,
  collected_at timestamptz not null default now(),
  constraint codex_reddit_comments_post_fk
    foreign key (reddit_post_id)
    references public.codex_reddit_posts (reddit_post_id)
    on delete cascade
);

create index if not exists codex_reddit_comments_post_posted_at_idx
  on public.codex_reddit_comments (reddit_post_id, posted_at asc);

create table if not exists public.codex_reddit_post_summaries (
  reddit_post_id text primary key,
  summary_text text not null default '',
  summary_lines integer not null default 4
    check (summary_lines >= 4),
  summary_author text not null default 'codex',
  summarized_at timestamptz not null default now(),
  constraint codex_reddit_post_summaries_post_fk
    foreign key (reddit_post_id)
    references public.codex_reddit_posts (reddit_post_id)
    on delete cascade
);

create table if not exists public.codex_reddit_comment_summaries (
  reddit_comment_id text primary key,
  reddit_post_id text not null,
  summary_text text not null default '',
  summary_lines integer not null default 4
    check (summary_lines >= 4),
  summary_author text not null default 'codex',
  summarized_at timestamptz not null default now(),
  constraint codex_reddit_comment_summaries_comment_fk
    foreign key (reddit_comment_id)
    references public.codex_reddit_comments (reddit_comment_id)
    on delete cascade,
  constraint codex_reddit_comment_summaries_post_fk
    foreign key (reddit_post_id)
    references public.codex_reddit_posts (reddit_post_id)
    on delete cascade
);

create table if not exists public.codex_reddit_collection_runs (
  run_id text primary key,
  started_at timestamptz not null,
  finished_at timestamptz,
  status text not null,
  posts_collected integer not null default 0,
  comments_collected integer not null default 0,
  post_summaries_saved integer not null default 0,
  comment_summaries_saved integer not null default 0,
  supabase_synced integer not null default 0,
  error_message text
);

alter table public.codex_reddit_posts enable row level security;
alter table public.codex_reddit_comments enable row level security;
alter table public.codex_reddit_post_summaries enable row level security;
alter table public.codex_reddit_comment_summaries enable row level security;
alter table public.codex_reddit_collection_runs enable row level security;
