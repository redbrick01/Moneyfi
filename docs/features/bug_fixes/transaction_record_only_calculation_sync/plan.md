# Transaction Record Only Calculation And Supabase Start Plan

## Bug Summary

계산 미포함 거래는 로컬 원장에서 `transaction_events.source = 'record_only'`로 저장된다. 이 source는 현재 보유 수량과 현금 잔액 재계산에서는 제외되어야 하지만, 거래 이력 기반 분석에서는 계속 사용할 수 있어야 한다. 따라서 상태 재계산과 분석 집계의 의미를 테스트로 분리해 고정해야 한다.

또한 로컬 Supabase 스택 시작 중 마이그레이션 `20260522153000_rebuild_snapshot_restore_ledger_lines.sql`이 이전 마이그레이션과 같은 임시 테이블명 `latest_restore_snapshots`를 다시 생성해 `relation already exists` 오류로 중단된다.

## User Impact

- 사용자가 "계산 미포함"으로 저장하거나 운영 데이터 보정을 위해 `record_only`로 전환한 거래가 현재 포트폴리오 값을 흔들지 않으면서도 분석 화면의 과거 거래 근거로는 남아야 한다.
- 로컬 Supabase DB를 시작할 수 없어 거래 동기화, soft delete, 로컬/원격 DB 일치 여부를 직접 검증하기 어렵다.

## Reproduction Or Evidence

- `record-only buy is visible but does not change holding or cash` 테스트는 보유/현금 제외를 확인하며 성과 집계에는 `buyAmount = 500`을 기대한다. 이 동작을 명시적으로 검증해 이후 상태 재계산 필터와 분석 필터가 섞이지 않게 한다.
- `supabase start`는 `ERROR: relation "latest_restore_snapshots" already exists`로 실패했다.

## Root Cause Hypothesis

- 상태 재계산 SQL은 `record_only`를 제외해야 하지만, 분석 SQL은 `record_only`를 포함해야 한다. 두 정책이 회귀 테스트로 충분히 드러나 있지 않았다.
- 두 마이그레이션이 같은 DB 세션에서 같은 temp table 이름을 사용한다. PostgreSQL temp table은 같은 세션 안에서 후속 migration까지 남을 수 있어 두 번째 `create temp table latest_restore_snapshots as`가 실패한다.

## Fix Strategy

- 상태 재계산/parity 쿼리는 `record_only` 제외를 유지한다.
- 성과/분석/드릴다운 쿼리는 `record_only`를 포함하는 정책을 테스트로 고정한다.
- 기존 테스트에 통화별 성과와 drill-down 포함 검증을 추가해 기록전용 거래가 분석 데이터로 사용되는지 확인한다.
- 마이그레이션 `20260522153000_rebuild_snapshot_restore_ledger_lines.sql` 시작부에서 이전 temp table을 명시적으로 drop한다.

## Non-goals

- 원격 Supabase 운영 DB에 migration을 적용하지 않는다.
- 동기화 충돌 정책 자체를 바꾸지 않는다.
- 거래 폼 UI 구조나 입력 UX를 변경하지 않는다.

## Regression Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter test`
- `flutter analyze`
- `./gradlew :app:compileDebugKotlin`
- `deno check supabase/functions/sync-local-db/index.ts supabase/functions/get-sync-local-db/index.ts`
- 가능한 경우 `supabase start`로 로컬 마이그레이션 재검증

## Risk And Rollback Notes

위험은 낮음에서 중간이다. `record_only`의 의미가 화면의 현재 포트폴리오 계산 제외와 분석 데이터 보존으로 분리된다. 문제가 있으면 분석 테스트 추가분을 되돌리거나 분석 쿼리에 별도 옵션을 추가해 포함/제외를 선택하도록 확장한다.
