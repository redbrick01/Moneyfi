-- Keep the latest quote when a device edits another field on the same instrument.
create or replace function public.preserve_newer_holding_quote()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if old.market_updated_at is not null
    and (new.market_updated_at is null or new.market_updated_at < old.market_updated_at)
    and (new.symbol, new.currency_code, new.exchange_code)
        is not distinct from (old.symbol, old.currency_code, old.exchange_code) then
    new.current_price := old.current_price;
    new.market_updated_at := old.market_updated_at;
  end if;
  return new;
end;
$$;
revoke all on function public.preserve_newer_holding_quote() from public, anon, authenticated;
create trigger holdings_preserve_newer_quote before update of current_price, market_updated_at
on public.holdings for each row execute function public.preserve_newer_holding_quote();

create function public.snapshot_target_users()
returns table(user_id uuid) language sql stable security invoker set search_path = '' as $$
  select distinct a.user_id from public.assets a where a.deleted_at is null
$$;
revoke all on function public.snapshot_target_users() from public, anon, authenticated;
grant execute on function public.snapshot_target_users() to service_role;

create function public.replace_portfolio_snapshot(
  p_user_id uuid, p_snapshot_date date, p_header jsonb,
  p_items jsonb, p_holdings jsonb, p_cash_accounts jsonb
) returns bigint language plpgsql security invoker set search_path = '' as $$
declare
  snapshot_key bigint;
begin
  if jsonb_array_length(p_items) is null or jsonb_array_length(p_items) = 0 then
    raise exception 'A portfolio snapshot requires at least one asset';
  end if;

  -- The unique user/date key serializes replacements and preserves the header ID.
  insert into public.daily_portfolio_snapshots
    (user_id, snapshot_date, total_purchase_amount, total_valuation_amount,
     profit_amount, profit_rate, exchange_rate, created_at)
  select p_user_id, p_snapshot_date, h.total_purchase_amount, h.total_valuation_amount,
         h.profit_amount, h.profit_rate, h.exchange_rate, now()
  from jsonb_populate_record(null::public.daily_portfolio_snapshots, p_header) h
  on conflict (user_id, snapshot_date) do update set
    total_purchase_amount = excluded.total_purchase_amount,
    total_valuation_amount = excluded.total_valuation_amount,
    profit_amount = excluded.profit_amount, profit_rate = excluded.profit_rate,
    exchange_rate = excluded.exchange_rate, created_at = excluded.created_at
  returning id into snapshot_key;

  delete from public.daily_portfolio_snapshot_cash_accounts where snapshot_id = snapshot_key;
  delete from public.daily_portfolio_snapshot_holding_items where snapshot_id = snapshot_key;
  delete from public.daily_portfolio_snapshot_items where snapshot_id = snapshot_key;

  insert into public.daily_portfolio_snapshot_items
    (user_id, snapshot_id, asset_id, asset_client_id, asset_title, total_purchase_amount,
     total_valuation_amount, profit_amount, profit_rate, holding_count)
  select p_user_id, snapshot_key, i.asset_id, i.asset_client_id, i.asset_title,
         i.total_purchase_amount, i.total_valuation_amount, i.profit_amount, i.profit_rate, i.holding_count
  from jsonb_populate_recordset(null::public.daily_portfolio_snapshot_items, p_items) i;

  insert into public.daily_portfolio_snapshot_holding_items
    (user_id, snapshot_id, asset_id, asset_client_id, asset_title, holding_id, holding_client_id,
     holding_name, holding_symbol, currency_code, quantity, total_purchase_amount,
     total_valuation_amount, profit_amount, profit_rate)
  select p_user_id, snapshot_key, i.asset_id, i.asset_client_id, i.asset_title, i.holding_id,
         i.holding_client_id, i.holding_name, i.holding_symbol, i.currency_code, i.quantity,
         i.total_purchase_amount, i.total_valuation_amount, i.profit_amount, i.profit_rate
  from jsonb_populate_recordset(null::public.daily_portfolio_snapshot_holding_items, p_holdings) i;

  insert into public.daily_portfolio_snapshot_cash_accounts
    (user_id, snapshot_id, asset_id, asset_client_id, asset_title, cash_account_id,
     cash_account_client_id, cash_account_name, currency_code, balance, note)
  select p_user_id, snapshot_key, i.asset_id, i.asset_client_id, i.asset_title, i.cash_account_id,
         i.cash_account_client_id, i.cash_account_name, i.currency_code, i.balance, i.note
  from jsonb_populate_recordset(null::public.daily_portfolio_snapshot_cash_accounts, p_cash_accounts) i;
  return snapshot_key;
end;
$$;
revoke all on function public.replace_portfolio_snapshot(uuid,date,jsonb,jsonb,jsonb,jsonb)
  from public, anon, authenticated;
grant execute on function public.replace_portfolio_snapshot(uuid,date,jsonb,jsonb,jsonb,jsonb)
  to service_role;

create table if not exists public.news_reports (
  id text primary key, run_id text not null, group_key text not null, group_label text not null,
  report_ko text not null default '', final_insight_ko text not null default '',
  article_count integer not null default 0, high_count integer not null default 0,
  max_importance_score integer not null default 0, model text not null,
  generated_at timestamptz, synced_at timestamptz not null default now(),
  unique (run_id, group_key)
);
create index if not exists idx_news_reports_generated_at on public.news_reports(generated_at desc);
create index if not exists idx_news_reports_group_key on public.news_reports(group_key);
alter table public.news_reports enable row level security;
revoke all on public.news_reports from public, anon, authenticated;
grant all on public.news_reports to service_role;

do $$
declare
  price_job bigint;
begin
  if to_regclass('public.reddit_posts') is null or to_regclass('public.reddit_comments') is null then
    perform cron.alter_job(job_id := jobid, active := false)
      from cron.job where jobname = 'cleanup_reddit_raw_sources_daily' and active;
  end if;
  select jobid into price_job from cron.job where jobname = 'update-holding-prices-every-10-min';
  if price_job is not null then
    perform cron.alter_job(job_id := price_job, command := $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
          || '/functions/v1/update-holding-prices',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'anon_key'),
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'CRON_SECRET')
        ), body := '{}'::jsonb, timeout_milliseconds := 300000);
    $job$);
  end if;
end;
$$;
