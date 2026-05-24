alter table public.daily_portfolio_snapshot_items
  add column if not exists asset_client_id uuid;

alter table public.daily_portfolio_snapshot_holding_items
  add column if not exists asset_client_id uuid,
  add column if not exists holding_client_id uuid;

alter table public.daily_portfolio_snapshot_cash_accounts
  add column if not exists asset_client_id uuid,
  add column if not exists cash_account_client_id uuid;

update public.daily_portfolio_snapshot_items item
set asset_client_id = asset.client_id
from public.assets asset
where item.asset_client_id is null
  and item.asset_id = asset.id
  and item.user_id = asset.user_id;

update public.daily_portfolio_snapshot_holding_items item
set asset_client_id = asset.client_id
from public.assets asset
where item.asset_client_id is null
  and item.asset_id = asset.id
  and item.user_id = asset.user_id;

update public.daily_portfolio_snapshot_holding_items item
set holding_client_id = holding.client_id
from public.holdings holding
where item.holding_client_id is null
  and item.holding_id = holding.id
  and item.user_id = holding.user_id;

update public.daily_portfolio_snapshot_cash_accounts item
set asset_client_id = asset.client_id
from public.assets asset
where item.asset_client_id is null
  and item.asset_id = asset.id
  and item.user_id = asset.user_id;

update public.daily_portfolio_snapshot_cash_accounts item
set cash_account_client_id = account.client_id
from public.cash_accounts account
where item.cash_account_client_id is null
  and item.cash_account_id = account.id
  and item.user_id = account.user_id;

create index if not exists idx_snapshot_items_asset_client_id
  on public.daily_portfolio_snapshot_items (asset_client_id);

create index if not exists idx_snapshot_holdings_asset_client_id
  on public.daily_portfolio_snapshot_holding_items (asset_client_id);

create index if not exists idx_snapshot_holdings_holding_client_id
  on public.daily_portfolio_snapshot_holding_items (holding_client_id);

create index if not exists idx_snapshot_cash_accounts_asset_client_id
  on public.daily_portfolio_snapshot_cash_accounts (asset_client_id);

create index if not exists idx_snapshot_cash_accounts_cash_account_client_id
  on public.daily_portfolio_snapshot_cash_accounts (cash_account_client_id);
