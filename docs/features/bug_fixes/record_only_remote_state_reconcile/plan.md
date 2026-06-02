# Record Only Remote State Reconcile Plan

## Bug Summary

`계산 반영 안 함` 거래는 현재 포트폴리오 상태 영향 없어야 함. 로컬 Drift 재계산은 `transaction_events.source = 'record_only'` 제외하지만, 원격 Supabase 상태 재계산 migration은 필터 없음. 기록용 거래가 `holdings.quantity`, `holdings.average_price`, `cash_accounts.balance`에 섞일 수 있음.

## User Impact

- 사용자가 과거 거래를 기록용으로 추가 후 동기화/원격 재계산/복구 흐름 거치면 현재 보유 수량, 평균단가, 현금 잔액, 자산 비중, 평가금액이 바뀐 것처럼 보일 수 있음.
- 거래 내역, 분석, 스냅샷에는 기록용 거래 보여야 함. 조회 전체 숨김 금지.

## Reproduction Or Evidence

- 투자 거래 폼과 현금 거래 폼은 `includeInCalculations` 값을 `AppDatabase.createTransaction`/`updateTransactionItem`에 전달.
- `AppDatabase.createTransaction`은 `includeInCalculations == false`이면 `source = 'record_only'` 원장 이벤트 생성.
- 로컬 상태 재계산 쿼리는 `te.source NOT IN ('history_display', 'record_only')` 사용.
- `supabase/migrations/20260522143000_reconcile_state_from_transaction_ledger.sql`은 `transaction_lines` 합산 때 `record_only` 제외 안 함.

## Root Cause Hypothesis

기록용 거래 정책은 `source = 'record_only'`로 표현됨. 원격 상태 재계산 SQL이 로컬 상태 재계산 SQL과 같은 제외 조건 공유 안 해 정책 분기됨.

## Fix Strategy

- 새 Supabase migration 추가해 원격 `holdings`와 `cash_accounts`를 활성 원장 기준 재보정.
- 보정 쿼리는 현재 포트폴리오 상태 계산에서 `history_display`, `record_only` 제외.
- 분석/스냅샷/거래 내역 조회 코드는 변경 안 함. 기록용 거래가 분석과 스냅샷에 포함되는 현재 정책 유지.

## Non Goals

- 기록용 거래를 거래 내역에서 숨기지 않음.
- 성과 분석, 배당/이자 분석, 스냅샷 거래 목록에서 `record_only` 제외 안 함.
- 기존 dirty UI 파일 수정 안 함.

## Regression Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter analyze`
- SQL migration 코드 리뷰:
  - holdings 재계산 join에서 `te.source NOT IN ('history_display', 'record_only')`
  - cash_accounts 재계산 join에서 같은 제외 조건
  - 마지막에 `public.recompute_asset_metrics(null)`로 asset summary 재계산

## Risk And Rollback Notes

- 위험 낮음. 변경 범위는 원격 상태 보정 migration 1개.
- 롤백 필요 시 migration 적용 전 DB backup 또는 Supabase PITR 기준 복구.
- 기록용 거래 표시/분석/스냅샷 포함 정책 유지. 해당 화면 표시 변화 없어야 함.