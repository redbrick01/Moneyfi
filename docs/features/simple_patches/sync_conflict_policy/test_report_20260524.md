# Sync Conflict Policy Test Report 2026-05-24

## Summary

Core sync 충돌 정책을 `last_modified_at` 기반 last-writer-wins로 고정하고, 서버가 수락한 row만 local dirty를 해제하도록 변경했습니다.

## Changed Files

- `supabase/migrations/20260524195600_add_sync_last_modified_conflict_columns.sql`
- `supabase/functions/sync-local-db/index.ts`
- `supabase/functions/get-sync-local-db/index.ts`
- `lib/db/app_database.dart`
- `lib/services/sync_service.dart`
- `docs/data_and_sync.md`
- `docs/features/simple_patches/sync_conflict_policy/plan.md`
- `docs/features/simple_patches/sync_conflict_policy/verification_test_plan.md`
- `docs/features/simple_patches/sync_conflict_policy/test_report_20260524.md`

## Verification Results

| Check | Result |
| --- | --- |
| `deno check supabase/functions/sync-local-db/index.ts` | Passed |
| `deno check supabase/functions/get-sync-local-db/index.ts` | Passed |
| `flutter test test/transaction_flow_test.dart` | Passed, 44 tests |
| `flutter analyze` | Passed, no issues |

## Known Limitations

- 정책은 클라이언트 timestamp를 기준으로 하므로 기기 시간이 크게 어긋난 경우 완전한 causality를 보장하지 않습니다.
- Supabase migration은 로컬 패치로 추가했으며, 원격 적용은 별도 배포 단계에서 수행해야 합니다.
