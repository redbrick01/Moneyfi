# Transaction Record Only Calculation And Supabase Start Plan

## Bug Summary

계산 미포함 거래는 로컬 원장에 `transaction_events.source = 'record_only'`로 저장. 이 source는 현재 보유 수량/현금 잔액 재계산에서 제외 필요. 단, 거래 이력 기반 분석에는 계속 사용 필요. 그래서 상태 재계산 의미와 분석 집계 의미를 테스트로 분리 고정 필요.

또 로컬 Supabase 스택 시작 중 migration `20260522153000_rebuild_snapshot_restore_ledger_lines.sql`이 이전 migration과 같은 temp table명 `latest_restore_snapshots` 재생성. `relation already exists` 오류로 중단.

## User Impact

- 사용자가 "계산 미포함" 저장하거나 운영 데이터 보정 위해 `record_only` 전환한 거래가 현재 포트폴리오 값 흔들면 안 됨. 그래도 분석 화면 과거 거래 근거로 남아야 함.
- 로컬 Supabase DB 시작 불가. 거래 동기화, soft delete, 로컬/원격 DB 일치 직접 검증 어려움.

## Reproduction Or Evidence

- `record-only buy is visible but does not change holding or cash` 테스트는 보유/현금 제외 확인. 성과 집계는 `buyAmount = 500` 기대. 이 동작 명시 검증해 이후 상태 재계산 필터와 분석 필터 혼합 방지.
- `supabase start`는 `ERROR: relation "latest_restore_snapshots" already exists`로 실패.

## Root Cause Hypothesis

- 상태 재계산 SQL은 `record_only` 제외 필요. 분석 SQL은 `record_only` 포함 필요. 두 정책이 회귀 테스트로 충분히 드러나지 않음.
- 두 migration이 같은 DB session에서 같은 temp table 이름 사용. PostgreSQL temp table은 같은 session 안에서 후속 migration까지 남을 수 있음. 그래서 두 번째 `create temp table latest_restore_snapshots as` 실패.

## Fix Strategy

- 상태 재계산/parity 쿼리는 `record_only` 제외 유지.
- 성과/분석/드릴다운 쿼리는 `record_only` 포함 정책을 테스트로 고정.
- 기존 테스트에 통화별 성과와 drill-down 포함 검증 추가. 기록전용 거래가 분석 데이터로 쓰이는지 확인.
- migration `20260522153000_rebuild_snapshot_restore_ledger_lines.sql` 시작부에서 이전 temp table 명시 drop.

## Non-goals

- 원격 Supabase 운영 DB에 migration 적용 안 함.
- 동기화 충돌 정책 변경 안 함.
- 거래 폼 UI 구조나 입력 UX 변경 안 함.

## Regression Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter test`
- `flutter analyze`
- `./gradlew :app:compileDebugKotlin`
- `deno check supabase/functions/sync-local-db/index.ts supabase/functions/get-sync-local-db/index.ts`
- 가능하면 `supabase start`로 로컬 migration 재검증

## Risk And Rollback Notes

위험 낮음~중간. `record_only` 의미는 현재 포트폴리오 계산 제외와 분석 데이터 보존으로 분리. 문제 있으면 분석 테스트 추가분 되돌림. 또는 분석 쿼리에 별도 옵션 추가해 포함/제외 선택 가능하게 확장.