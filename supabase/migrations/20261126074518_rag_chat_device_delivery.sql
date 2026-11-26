alter table public.rag_chat_requests
  add column device_id uuid,
  add column local_history jsonb check (
    local_history is null or (jsonb_typeof(local_history) = 'array'
      and jsonb_array_length(local_history) <= 3 and octet_length(local_history::text) <= 65536)
  );
grant insert(device_id, local_history) on public.rag_chat_requests to authenticated;
create index rag_chat_device_delivery on public.rag_chat_requests(user_id, device_id, id);
