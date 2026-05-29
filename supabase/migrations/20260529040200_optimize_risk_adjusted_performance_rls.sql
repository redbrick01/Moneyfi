drop policy if exists portfolio_daily_returns_own_rows
  on public.portfolio_daily_returns;

create policy portfolio_daily_returns_own_rows
  on public.portfolio_daily_returns
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
