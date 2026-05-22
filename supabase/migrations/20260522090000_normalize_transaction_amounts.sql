alter table if exists public.transactions
  add column if not exists unit_price double precision not null default 0,
  add column if not exists quantity_value double precision not null default 0,
  add column if not exists gross_amount double precision not null default 0,
  add column if not exists cash_flow_amount double precision not null default 0,
  add column if not exists realized_profit_amount double precision not null default 0;

alter table if exists public.cash_transactions
  add column if not exists amount_value double precision not null default 0,
  add column if not exists cash_flow_amount double precision not null default 0;

update public.transactions
set
  unit_price = abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)),
  quantity_value = abs(coalesce(nullif(regexp_replace(quantity, '[^0-9.-]', '', 'g'), '')::double precision, 0)),
  gross_amount = case
    when type in ('매수', '매도', '초기') then
      abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)) *
      abs(coalesce(nullif(regexp_replace(quantity, '[^0-9.-]', '', 'g'), '')::double precision, 0))
    else abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0))
  end,
  cash_flow_amount = case
    when type = '매수' then -(
      abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)) *
      abs(coalesce(nullif(regexp_replace(quantity, '[^0-9.-]', '', 'g'), '')::double precision, 0))
    )
    when type in ('매도', '배당', '이자') then case
      when type = '매도' then
        abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)) *
        abs(coalesce(nullif(regexp_replace(quantity, '[^0-9.-]', '', 'g'), '')::double precision, 0))
      else abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0))
    end
    else 0
  end
where unit_price = 0
  and quantity_value = 0
  and gross_amount = 0
  and cash_flow_amount = 0;

update public.cash_transactions
set
  amount_value = abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)),
  cash_flow_amount = case
    when type in ('입금', '매도') then abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0))
    when type in ('출금', '매수') then -abs(coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0))
    when type in ('환전', '이체') then coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)
    else coalesce(nullif(regexp_replace(amount, '[^0-9.-]', '', 'g'), '')::double precision, 0)
  end
where amount_value = 0
  and cash_flow_amount = 0;

comment on column public.transactions.unit_price is
  'Normalized transaction unit price parsed from amount text.';
comment on column public.transactions.quantity_value is
  'Normalized trade quantity parsed from quantity text.';
comment on column public.transactions.gross_amount is
  'Normalized absolute transaction amount before cash-flow direction.';
comment on column public.transactions.cash_flow_amount is
  'Normalized signed cash flow: buys negative, sells/dividends/interest positive.';
comment on column public.transactions.realized_profit_amount is
  'Derived realized profit for sells using moving-average cost basis.';
comment on column public.cash_transactions.amount_value is
  'Normalized absolute cash transaction amount parsed from amount text.';
comment on column public.cash_transactions.cash_flow_amount is
  'Normalized signed cash account balance delta.';
