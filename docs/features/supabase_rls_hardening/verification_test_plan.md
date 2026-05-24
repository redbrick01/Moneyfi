# Supabase RLS And Grants Verification Test Plan

## Automated Remote Checks

```bash
supabase migration list
supabase db query --linked "select table_schema, table_name, grantee, privilege_type from information_schema.role_table_grants where table_schema='public' and grantee in ('anon','authenticated') order by table_name, grantee, privilege_type;"
supabase db query --linked "select object_schema, object_name, object_type, grantee, privilege_type from information_schema.role_usage_grants where object_schema='public' and grantee in ('anon','authenticated') order by object_name, grantee, privilege_type;"
supabase db query --linked "select n.nspname as schema, p.proname as function, pg_get_function_identity_arguments(p.oid) as args, r.rolname as grantee, x.privilege_type from pg_proc p join pg_namespace n on n.oid=p.pronamespace join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x on true join pg_roles r on r.oid=x.grantee where n.nspname='public' and r.rolname in ('anon','authenticated') order by p.proname, args, r.rolname, x.privilege_type;"
supabase db query --linked "select c.relname as table_name, c.relrowsecurity, c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p') order by c.relname;"
supabase db query --linked "select schemaname, tablename, policyname, roles, cmd, qual, with_check from pg_policies where schemaname='public' order by tablename, policyname;"
```

## Expected Results

- Table grants contain only `SELECT` for:
  - `company_news`
  - `company_news_summaries`
  - `exchange_rates`
  - `market_news`
  - `market_news_summaries`
- Sequence usage grants return no rows for `anon`/`authenticated`.
- Function grants return no rows for `anon`/`authenticated`.
- All public app tables keep RLS enabled.
- Own-row policies target `authenticated`, not `{public}`.
- Public read policies target `{anon,authenticated}`.

## Manual QA

- Login and run app sync refresh.
- Open market news summary.
- Open company news summary.
- Open portfolio diagnosis.
- Confirm Edge Function calls still use service role server path and do not require direct table grants.
