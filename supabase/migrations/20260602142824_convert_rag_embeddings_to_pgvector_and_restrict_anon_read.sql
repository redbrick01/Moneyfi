create extension if not exists vector with schema extensions;

alter table public.rag_summary_embeddings
  add column if not exists embedding extensions.vector(1024);

update public.rag_summary_embeddings
set embedding = embedding_json::text::extensions.vector
where embedding is null
  and jsonb_typeof(embedding_json) = 'array'
  and jsonb_array_length(embedding_json) = 1024;

do $$
begin
  if exists (
    select 1
    from public.rag_summary_embeddings
    where embedding is null
    limit 1
  ) then
    raise exception 'rag_summary_embeddings.embedding contains nulls after backfill';
  end if;
end $$;

alter table public.rag_summary_embeddings
  alter column embedding set not null;

create index if not exists idx_rag_summary_embeddings_embedding_hnsw
  on public.rag_summary_embeddings
  using hnsw (embedding vector_cosine_ops);

revoke all on public.rag_summary_embeddings from anon, authenticated;
grant select on public.rag_summary_embeddings to authenticated;

drop policy if exists rag_summary_embeddings_public_read
  on public.rag_summary_embeddings;
drop policy if exists rag_summary_embeddings_authenticated_read
  on public.rag_summary_embeddings;

create policy rag_summary_embeddings_authenticated_read
on public.rag_summary_embeddings
for select
to authenticated
using (true);

revoke all on public.reddit_daily_report from anon, authenticated;
grant select on public.reddit_daily_report to authenticated;

drop policy if exists reddit_daily_report_public_read
  on public.reddit_daily_report;
drop policy if exists reddit_daily_report_authenticated_read
  on public.reddit_daily_report;

create policy reddit_daily_report_authenticated_read
on public.reddit_daily_report
for select
to authenticated
using (true);
