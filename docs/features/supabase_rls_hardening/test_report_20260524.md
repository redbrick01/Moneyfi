# Supabase RLS And Grants Test Report 2026-05-24

## Summary

원격 Supabase DB 기준으로 `anon`/`authenticated` grants, sequences, functions, RLS enablement, policies를 점검했고 최소 권한 migration을 추가했습니다.

## Remote Findings Before Patch

- `supabase migration list`에서 local/remote migration은 `20260524094000`까지 일치했습니다.
- 모든 public app table은 RLS enabled 상태였습니다.
- 사용자 데이터 테이블, snapshot table, ledger table, `portfolio_diagnosis_history`에 `anon`/`authenticated` `ALL` table grants가 남아 있었습니다.
- public sequences에 `anon`/`authenticated` `USAGE` grants가 남아 있었습니다.
- `public.set_updated_at()`에 `anon`/`authenticated` `EXECUTE` grant가 남아 있었습니다.
- own-row RLS policies가 `{public}` role로 설정되어 있었습니다.

## Changed Files

- `supabase/migrations/20260524195000_harden_client_grants_and_rls.sql`
- `docs/features/supabase_rls_hardening/plan.md`
- `docs/features/supabase_rls_hardening/verification_test_plan.md`
- `docs/features/supabase_rls_hardening/test_report_20260524.md`
- `docs/README.md`
- `docs/supabase_overview.md`

## Verification Results

| Check | Result |
| --- | --- |
| Remote migration list before patch | Passed, local/remote matched through `20260524094000` |
| Remote RLS state before patch | Passed, public app tables had RLS enabled |
| Remote table grant inspection before patch | Failed least privilege, broad grants found |
| Remote sequence grant inspection before patch | Failed least privilege, sequence grants found |
| Remote function grant inspection before patch | Failed least privilege, `set_updated_at()` execute grants found |
| `supabase db push` | Passed, applied `20260524195000_harden_client_grants_and_rls.sql` |
| `supabase migration list` after patch | Passed, local/remote include `20260524195000` |
| Remote table grant inspection after patch | Passed, only public news/rate `SELECT` grants remain |
| Remote sequence grant inspection after patch | Passed, no rows for `anon`/`authenticated` |
| Remote function grant inspection after patch | Passed, no rows for `anon`/`authenticated` |
| Remote RLS state after patch | Passed, public app tables still have RLS enabled |
| Remote policy inspection after patch | Passed, own-row policies target `{authenticated}` and public-read policies target `{anon,authenticated}` |

## Notes

- `supabase db diff --from migrations --to linked --schema public` failed while replaying an older migration because a temp table name already existed during the CLI diff replay. This did not block direct remote catalog inspection.
- Supabase CLI emitted an AVX support warning in this environment, but read-only queries completed.
