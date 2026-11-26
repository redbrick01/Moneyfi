create function public.collect_legacy_chat(p_device uuid) returns void
language sql security definer set search_path='' as $$
  update public.rag_chat_requests r set device_id=p_device
  where p_device is not null and r.user_id=(select auth.uid()) and r.device_id is null
    and not exists (select 1 from public.rag_chat_requests active
      where active.user_id=r.user_id and active.thread_id=r.thread_id
        and active.status in ('queued','running'));
$$;
revoke all on function public.collect_legacy_chat(uuid) from public,anon;
grant execute on function public.collect_legacy_chat(uuid) to authenticated;
