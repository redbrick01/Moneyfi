alter table if exists public.assets
  add column if not exists valuation_krw double precision not null default 0,
  add column if not exists purchase_krw double precision not null default 0,
  add column if not exists profit_krw double precision not null default 0,
  add column if not exists profit_rate double precision not null default 0,
  add column if not exists metrics_updated_at timestamp with time zone null;

comment on column public.assets.valuation_krw is
  'Derived total valuation in KRW from visible/non-deleted holdings.';

comment on column public.assets.purchase_krw is
  'Derived total purchase amount in KRW from visible/non-deleted holdings.';

comment on column public.assets.profit_krw is
  'Derived profit in KRW (valuation_krw - purchase_krw).';

comment on column public.assets.profit_rate is
  'Derived profit rate in percent. 0 when purchase_krw is 0.';

comment on column public.assets.metrics_updated_at is
  'Timestamp when derived asset metrics were last refreshed.';
