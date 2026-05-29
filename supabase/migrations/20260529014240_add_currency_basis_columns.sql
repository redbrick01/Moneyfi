alter table public.holdings
  add column if not exists average_price_source double precision not null default 0,
  add column if not exists average_price_krw double precision not null default 0,
  add column if not exists average_purchase_fx_rate double precision not null default 1,
  add column if not exists cost_basis_krw double precision not null default 0;

alter table public.transaction_lines
  add column if not exists cost_basis_source_delta double precision not null default 0;

update public.holdings
set
  average_price_source = case
    when currency_code = 'USD' then average_price_source
    when average_price_source = 0 then average_price
    else average_price_source
  end,
  average_price_krw = case
    when average_price_krw = 0 then average_price
    else average_price_krw
  end,
  average_purchase_fx_rate = case
    when currency_code = 'USD' and average_price_source > 0
      and average_purchase_fx_rate = 0
      then average_price_krw / average_price_source
    when currency_code = 'USD' and average_price_source > 0
      then average_purchase_fx_rate
    when currency_code = 'USD' then 0
    else 1
  end,
  cost_basis_krw = case
    when cost_basis_krw = 0 then quantity * average_price
    else cost_basis_krw
  end;

update public.transaction_lines
set cost_basis_source_delta = cost_basis_delta
where cost_basis_source_delta = 0
  and coalesce(currency_code, 'KRW') <> 'USD';

comment on column public.holdings.average_price_source is
  'Average unit cost in the holding source currency. USD holdings use USD; KRW holdings use KRW.';
comment on column public.holdings.average_price_krw is
  'Average unit cost in KRW. Kept in sync with average_price for compatibility.';
comment on column public.holdings.average_purchase_fx_rate is
  'Weighted average purchase FX rate, derived from total KRW cost divided by total source-currency cost.';
comment on column public.holdings.cost_basis_krw is
  'Remaining total cost basis in KRW.';
comment on column public.transaction_lines.cost_basis_source_delta is
  'Cost-basis delta in the holding source currency. Sell rows are negative.';
