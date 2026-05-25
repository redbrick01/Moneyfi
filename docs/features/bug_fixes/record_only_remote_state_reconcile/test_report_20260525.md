# Record Only Remote State Reconcile Test Report - 2026-05-25

## Summary

기록용 거래는 현재 포트폴리오 상태에서 제외하고, 분석/스냅샷/거래 내역에는 유지하는 정책으로 원격 상태 보정 migration을 추가하고 linked Supabase DB에 적용했다.

## Reproduction Status

코드 조사로 재현 경로를 확인했다.

- 로컬 앱 상태 재계산은 `record_only`를 제외한다.
- 원격 `20260522143000_reconcile_state_from_transaction_ledger.sql`은 `record_only`를 제외하지 않아 원격 상태 보정 시 현재 보유/현금 상태가 오염될 수 있었다.

## Root Cause

기록용 거래 정책이 `transaction_events.source = 'record_only'`로 저장되지만, 원격 상태 재계산 SQL에 로컬 상태 재계산과 같은 `source` 제외 조건이 없었다.

## Fix Summary

- `supabase/migrations/20260525151000_exclude_record_only_from_remote_state_reconcile.sql` 추가.
- holdings 재계산에서 `history_display`, `record_only` 이벤트를 제외한다.
- cash_accounts 재계산에서 `history_display`, `record_only` 이벤트를 제외한다.
- 분석/스냅샷/거래 내역 조회는 변경하지 않아 기록용 거래 표시 정책을 유지했다.

## Commands Run

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
supabase db push
supabase db query --linked "select version from supabase_migrations.schema_migrations where version = '20260525151000';"
```

## Command Results

- `flutter test test/transaction_flow_test.dart`: passed, 52 tests.
- `flutter analyze`: passed, no issues found.
- `supabase db push`: passed. Applied `20260525151000_exclude_record_only_from_remote_state_reconcile.sql`.
- Remote migration verification query: passed. Returned version `20260525151000`.
- `supabase migration list` after push: inconclusive due temporary Supabase CLI login role authentication failures, but exact version verification query succeeded.

## Regression Coverage

- `record-only cash transaction stays out of cash balance`
- `record-only buy is visible but does not change holding or cash`
- 스냅샷과 거래 상세 원장 조회 관련 기존 테스트 전체 통과

## Manual QA Status

미수행. 원격 Supabase migration 적용과 catalog verification은 완료했다.

## Remaining Risk

- 운영 DB에 이미 오염된 holdings/cash_accounts 값은 migration 적용으로 보정된다.
- Supabase CLI `migration list`가 임시 login role 인증 실패를 냈으므로, 후속 원격 확인은 `schema_migrations` 직접 조회처럼 짧은 catalog query를 우선 사용한다.

## Final Result

현재 포트폴리오 상태 계산은 기록용 거래를 제외하고, 분석/스냅샷/거래 내역에는 기록용 거래를 유지하는 정책으로 정리됐다.
