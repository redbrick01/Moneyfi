create extension if not exists pg_cron with schema extensions;

create or replace function public.cleanup_old_reddit_raw_sources(
  retention interval default interval '24 hours'
)
returns table(posts_trimmed integer, comments_deleted integer)
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.reddit_posts
  set body = ''
  where body <> ''
    and coalesce(posted_at, scraped_at) < now() - retention;
  get diagnostics posts_trimmed = row_count;

  delete from public.reddit_comments comments
  where exists (
    select 1
    from public.reddit_posts posts
    where posts.reddit_id = comments.post_reddit_id
      and coalesce(posts.posted_at, posts.scraped_at) < now() - retention
  );
  get diagnostics comments_deleted = row_count;

  return next;
end;
$$;

revoke all on function public.cleanup_old_reddit_raw_sources(interval)
from public, anon, authenticated;

grant execute on function public.cleanup_old_reddit_raw_sources(interval)
to service_role;

do $$
begin
  if exists (
    select 1
    from cron.job
    where jobname = 'cleanup_reddit_raw_sources_daily'
  ) then
    perform cron.unschedule('cleanup_reddit_raw_sources_daily');
  end if;
end;
$$;

select cron.schedule(
  'cleanup_reddit_raw_sources_daily',
  '0 0 * * *',
  $$select * from public.cleanup_old_reddit_raw_sources();$$
);
