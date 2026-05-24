# Edge Function Auth Verification Test Plan

## Scope

이번 검증은 JWT payload decode 제거, Supabase Auth 검증 적용, 사용자 scope 제한을 대상으로 합니다.

## Automated Checks

```bash
rg -n "decodeJwtSub|jwt_decode|invalid_jwt_parts|missing_sub|decode_failed" supabase/functions
deno check supabase/functions/_shared/auth.ts
deno check supabase/functions/sync-local-db/index.ts
deno check supabase/functions/get-sync-local-db/index.ts
deno check supabase/functions/get-portfolio-snapshots/index.ts
deno check supabase/functions/create-portfolio-snapshot/index.ts
deno check supabase/functions/fetch-company-news/index.ts
deno check supabase/functions/get-user-company-news-summaries/index.ts
```

## Manual QA Matrix

| Case | Expected result |
| --- | --- |
| Valid logged-in user token | 200 and data scoped to authenticated user |
| Missing Authorization header | 401 with `step: auth_verify` |
| Malformed bearer token | 401 with `step: auth_verify` |
| Expired or revoked token | 401 with `step: auth_verify` |
| `user_id` different from authenticated user | 403 with `step: user_scope` |
| Missing `SUPABASE_ANON_KEY` | 500 auth/env failure |

## Acceptance Criteria

- No Edge Function uses local JWT payload decode for user id trust.
- Service role client queries include authenticated user scope where user data is read or written.
- The app's existing Supabase function invocation path continues to pass the logged-in session token automatically.
