# Edge Function Auth Test Report 2026-05-24

## Summary

Edge Function 인증을 `decodeJwtSub` 기반 payload read에서 `supabase.auth.getUser()` 기반 검증으로 변경했습니다.

## Changed Files

- `supabase/functions/_shared/auth.ts`
- `supabase/functions/sync-local-db/index.ts`
- `supabase/functions/get-sync-local-db/index.ts`
- `supabase/functions/get-portfolio-snapshots/index.ts`
- `supabase/functions/create-portfolio-snapshot/index.ts`
- `supabase/functions/fetch-company-news/index.ts`
- `supabase/functions/get-user-company-news-summaries/index.ts`
- `docs/supabase_overview.md`
- `docs/features/simple_patches/edge_function_auth/plan.md`
- `docs/features/simple_patches/edge_function_auth/verification_test_plan.md`
- `docs/features/simple_patches/edge_function_auth/test_report_20260524.md`

## Verification Results

| Check | Result |
| --- | --- |
| `rg -n "decodeJwtSub\|jwt_decode\|invalid_jwt_parts\|missing_sub\|decode_failed" supabase/functions` | Passed, no matches |
| `deno check supabase/functions/_shared/auth.ts` | Passed |
| `deno check supabase/functions/sync-local-db/index.ts` | Passed |
| `deno check supabase/functions/get-sync-local-db/index.ts` | Passed |
| `deno check supabase/functions/get-portfolio-snapshots/index.ts` | Passed |
| `deno check supabase/functions/create-portfolio-snapshot/index.ts` | Passed |
| `deno check supabase/functions/fetch-company-news/index.ts` | Passed |
| `deno check supabase/functions/get-user-company-news-summaries/index.ts` | Passed |

## Known Limitations

- Supabase local serve 또는 원격 배포 후 실제 token matrix 검증은 별도 환경에서 수행해야 합니다.
- 전체 사용자 대상 news/snapshot batch가 필요하면 user session auth와 분리된 cron/webhook 인증 설계가 필요합니다.
