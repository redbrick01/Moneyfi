# Sync Conflict Policy Verification Test Plan

## Automated Checks

```bash
deno check supabase/functions/sync-local-db/index.ts
deno check supabase/functions/get-sync-local-db/index.ts
flutter test test/transaction_flow_test.dart
```

## Manual QA

- Device A와 Device B가 같은 자산명을 수정합니다.
- 더 늦은 `last_modified_at`을 가진 변경이 원격에 남는지 확인합니다.
- 오래된 변경을 push한 기기에서 해당 row dirty가 바로 해제되지 않는지 확인합니다.
- 다음 pull 이후 서버 우선 row가 로컬에 반영되는지 확인합니다.

## Acceptance Criteria

- 같은 `client_id` row의 충돌은 `last_modified_at` 비교로 결정됩니다.
- 서버 최신 row를 오래된 client payload가 덮어쓰지 않습니다.
- accepted row만 dirty 해제됩니다.
- 기존 ledger-only payload restore 테스트가 통과합니다.
