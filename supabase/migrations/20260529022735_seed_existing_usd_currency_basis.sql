create schema if not exists recovery_archive;

alter table public.holdings
  add column if not exists average_price_source double precision not null default 0,
  add column if not exists average_price_krw double precision not null default 0,
  add column if not exists average_purchase_fx_rate double precision not null default 1,
  add column if not exists cost_basis_krw double precision not null default 0;

create temp table usd_currency_basis_seed (
  asset_title text not null,
  holding_id bigint not null,
  symbol text not null,
  holding_name text not null,
  expected_quantity double precision not null,
  expected_average_price_krw double precision not null,
  average_price_source double precision not null,
  primary key (asset_title, holding_id)
) on commit drop;

insert into usd_currency_basis_seed (
  asset_title,
  holding_id,
  symbol,
  holding_name,
  expected_quantity,
  expected_average_price_krw,
  average_price_source
) values
  ('주식', 8, 'SATL', '새틀로직', 50, 4690, 3.2925),
  ('주식', 3, 'IONQ', '아이온큐', 16, 39680, 28.3813),
  ('주식', 1, 'TSLA', '테슬라', 2, 317648, 225.9928),
  ('주식', 4, 'PLTR', '팔란티어', 6, 104149, 74.4933),
  ('주식', 5, 'NVDA', '엔비디아', 7, 143943.642857143, 133.1379),
  ('+', 21, 'TSLA', '테슬라', 66, 286663, 259.5674);

create table if not exists recovery_archive.holdings_before_usd_currency_basis_seed_20260529
as
select
  now() as archived_at,
  seed.asset_title as seed_asset_title,
  seed.holding_id as seed_holding_id,
  seed.symbol as seed_symbol,
  seed.holding_name as seed_holding_name,
  seed.expected_quantity,
  seed.expected_average_price_krw,
  seed.average_price_source as seed_average_price_source,
  h.*
from usd_currency_basis_seed seed
join public.holdings h
  on h.id = seed.holding_id
join public.assets a
  on a.id = h.asset_id
where a.title = seed.asset_title
  and h.symbol = seed.symbol
  and h.name = seed.holding_name
  and h.currency_code = 'USD'
  and abs(coalesce(h.quantity, 0) - seed.expected_quantity) < 0.000001
  and abs(coalesce(h.average_price, 0) - seed.expected_average_price_krw) < 0.000001;

create table if not exists recovery_archive.usd_currency_basis_seed_skipped_20260529
as
select
  now() as archived_at,
  seed.*,
  h.id as actual_holding_id,
  a.title as actual_asset_title,
  h.symbol as actual_symbol,
  h.name as actual_holding_name,
  h.currency_code as actual_currency_code,
  h.quantity as actual_quantity,
  h.average_price as actual_average_price,
  case
    when h.id is null then 'missing_holding_id'
    when a.title is distinct from seed.asset_title then 'asset_title_mismatch'
    when h.symbol is distinct from seed.symbol then 'symbol_mismatch'
    when h.name is distinct from seed.holding_name then 'holding_name_mismatch'
    when h.currency_code is distinct from 'USD' then 'currency_mismatch'
    when abs(coalesce(h.quantity, 0) - seed.expected_quantity) >= 0.000001
      then 'quantity_mismatch'
    when abs(coalesce(h.average_price, 0) - seed.expected_average_price_krw) >= 0.000001
      then 'average_price_krw_mismatch'
    else 'unknown'
  end as skip_reason
from usd_currency_basis_seed seed
left join public.holdings h
  on h.id = seed.holding_id
left join public.assets a
  on a.id = h.asset_id
where h.id is null
  or a.title is distinct from seed.asset_title
  or h.symbol is distinct from seed.symbol
  or h.name is distinct from seed.holding_name
  or h.currency_code is distinct from 'USD'
  or abs(coalesce(h.quantity, 0) - seed.expected_quantity) >= 0.000001
  or abs(coalesce(h.average_price, 0) - seed.expected_average_price_krw) >= 0.000001;

with matched_seed as (
  select
    seed.holding_id,
    seed.expected_average_price_krw,
    seed.average_price_source,
    seed.expected_quantity
  from usd_currency_basis_seed seed
  join public.holdings h
    on h.id = seed.holding_id
  join public.assets a
    on a.id = h.asset_id
  where a.title = seed.asset_title
    and h.symbol = seed.symbol
    and h.name = seed.holding_name
    and h.currency_code = 'USD'
    and abs(coalesce(h.quantity, 0) - seed.expected_quantity) < 0.000001
    and abs(coalesce(h.average_price, 0) - seed.expected_average_price_krw) < 0.000001
)
update public.holdings h
set
  average_price = matched_seed.expected_average_price_krw,
  average_price_krw = matched_seed.expected_average_price_krw,
  average_price_source = matched_seed.average_price_source,
  average_purchase_fx_rate =
    matched_seed.expected_average_price_krw / matched_seed.average_price_source,
  cost_basis_krw =
    matched_seed.expected_quantity * matched_seed.expected_average_price_krw
from matched_seed
where h.id = matched_seed.holding_id;
