create schema if not exists recovery_archive;

create temp table usd_currency_basis_identity_seed (
  asset_title text not null,
  holding_id bigint not null,
  symbol text not null,
  expected_average_price_krw double precision not null,
  average_price_source double precision not null,
  primary key (asset_title, holding_id)
) on commit drop;

insert into usd_currency_basis_identity_seed (
  asset_title,
  holding_id,
  symbol,
  expected_average_price_krw,
  average_price_source
) values
  ('주식', 8, 'SATL', 4690, 3.2925),
  ('주식', 3, 'IONQ', 39680, 28.3813),
  ('주식', 1, 'TSLA', 317648, 225.9928),
  ('주식', 4, 'PLTR', 104149, 74.4933),
  ('주식', 5, 'NVDA', 143943.642857143, 133.1379),
  ('+', 21, 'TSLA', 286663, 259.5674);

create table if not exists recovery_archive.holdings_before_usd_currency_basis_identity_fix_20260529
as
select
  now() as archived_at,
  seed.asset_title as seed_asset_title,
  seed.holding_id as seed_holding_id,
  seed.symbol as seed_symbol,
  seed.expected_average_price_krw,
  seed.average_price_source as seed_average_price_source,
  h.*
from usd_currency_basis_identity_seed seed
join public.holdings h
  on h.id = seed.holding_id
join public.assets a
  on a.id = h.asset_id
 and a.deleted_at is null
where a.title = seed.asset_title
  and h.symbol = seed.symbol
  and h.currency_code = 'USD'
  and h.deleted_at is null;

create table if not exists recovery_archive.usd_currency_basis_identity_fix_skipped_20260529
as
select
  now() as archived_at,
  seed.*,
  h.id as actual_holding_id,
  a.title as actual_asset_title,
  h.symbol as actual_symbol,
  h.name as actual_holding_name,
  h.currency_code as actual_currency_code,
  case
    when h.id is null then 'missing_holding_id'
    when a.title is distinct from seed.asset_title then 'asset_title_mismatch'
    when h.symbol is distinct from seed.symbol then 'symbol_mismatch'
    when h.currency_code is distinct from 'USD' then 'currency_mismatch'
    when h.deleted_at is not null then 'deleted_holding'
    else 'unknown'
  end as skip_reason
from usd_currency_basis_identity_seed seed
left join public.holdings h
  on h.id = seed.holding_id
left join public.assets a
  on a.id = h.asset_id
where h.id is null
  or a.title is distinct from seed.asset_title
  or h.symbol is distinct from seed.symbol
  or h.currency_code is distinct from 'USD'
  or h.deleted_at is not null;

with matched_seed as (
  select
    seed.holding_id,
    seed.expected_average_price_krw,
    seed.average_price_source
  from usd_currency_basis_identity_seed seed
  join public.holdings h
    on h.id = seed.holding_id
   and h.deleted_at is null
  join public.assets a
    on a.id = h.asset_id
   and a.deleted_at is null
  where a.title = seed.asset_title
    and h.symbol = seed.symbol
    and h.currency_code = 'USD'
)
update public.holdings h
set
  average_price = matched_seed.expected_average_price_krw,
  average_price_krw = matched_seed.expected_average_price_krw,
  average_price_source = matched_seed.average_price_source,
  average_purchase_fx_rate =
    matched_seed.expected_average_price_krw / matched_seed.average_price_source,
  cost_basis_krw =
    h.quantity * matched_seed.expected_average_price_krw,
  updated_at = now(),
  last_modified_at = now()
from matched_seed
where h.id = matched_seed.holding_id
  and h.deleted_at is null;
