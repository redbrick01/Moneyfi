grant delete on public.rag_chat_requests to authenticated;
create policy rag_chat_delete_own on public.rag_chat_requests for delete
  to authenticated using (user_id = (select auth.uid()));
