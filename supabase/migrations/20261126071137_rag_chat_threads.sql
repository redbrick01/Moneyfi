alter table public.rag_chat_requests add column thread_id uuid;
-- Legacy clients used a single continuous conversation per user.
update public.rag_chat_requests set thread_id = user_id;
alter table public.rag_chat_requests alter column thread_id set default auth.uid(),
  alter column thread_id set not null;
grant insert(thread_id) on public.rag_chat_requests to authenticated;
create index rag_chat_thread_history on public.rag_chat_requests(user_id, thread_id, created_at, id);
create unique index rag_chat_one_active_per_thread on public.rag_chat_requests(user_id, thread_id)
  where status in ('queued','running');
drop index public.rag_chat_one_active;

create view public.rag_chat_threads with (security_invoker=true) as
select distinct on (user_id,thread_id) user_id, thread_id as id,
  left(question, 80) as title,
  max(created_at) over (partition by user_id,thread_id) as last_at
from public.rag_chat_requests
order by user_id,thread_id,created_at,id;
revoke all on public.rag_chat_threads from public,anon,authenticated;
grant select on public.rag_chat_threads to authenticated;
