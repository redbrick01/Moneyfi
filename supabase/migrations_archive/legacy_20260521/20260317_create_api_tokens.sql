create table if not exists public.api_tokens (
  provider text primary key,
  access_token text not null,
  expires_at timestamp with time zone not null,
  updated_at timestamp with time zone not null default now()
);
