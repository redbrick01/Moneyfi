create table public.rag_chat_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  question text not null check (char_length(btrim(question)) between 1 and 2000),
  status text not null default 'queued' check (status in ('queued','running','done','failed')),
  answer text not null default '',
  sources jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  claimed_at timestamptz,
  attempt integer not null default 0
);
create index rag_chat_user_history on public.rag_chat_requests(user_id, created_at desc);
create unique index rag_chat_one_active on public.rag_chat_requests(user_id)
  where status in ('queued','running');
create index rag_chat_pending on public.rag_chat_requests(created_at)
  where status in ('queued','running');

alter table public.rag_chat_requests enable row level security;
revoke all on public.rag_chat_requests from public, anon, authenticated;
grant select, insert (id, question) on public.rag_chat_requests to authenticated;
grant select, insert, update, delete on public.rag_chat_requests to service_role;
create policy rag_chat_read_own on public.rag_chat_requests for select
  to authenticated using (user_id = (select auth.uid()));
create policy rag_chat_ask on public.rag_chat_requests for insert
  to authenticated with check (user_id = (select auth.uid()));
alter publication supabase_realtime add table public.rag_chat_requests;

-- A restarted worker can reclaim an interrupted answer. The attempt number
-- fences late writes from the previous worker.
create function public.claim_rag_chat_request()
returns setof public.rag_chat_requests
language sql volatile security invoker set search_path = '' as $$
  with next_request as (
    select id from public.rag_chat_requests
    where status = 'queued' or (status = 'running' and claimed_at < now() - interval '4 minutes')
    order by created_at
    limit 1 for update skip locked
  )
  update public.rag_chat_requests q
  set status = 'running', claimed_at = now(), attempt = q.attempt + 1, answer = ''
  from next_request where q.id = next_request.id
  returning q.*;
$$;
revoke all on function public.claim_rag_chat_request() from public, anon, authenticated;
grant execute on function public.claim_rag_chat_request() to service_role;
