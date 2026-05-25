# Record Only Remote State Reconcile Plan

## Bug Summary

`계산 반영 안 함` 거래는 현재 포트폴리오 상태에는 영향을 주지 않아야 한다. 로컬 Drift 재계산은 `transaction_events.source = 'record_only'`를 제외하지만, 원격 Supabase 상태 재계산 migration에는 같은 필터가 없어 기록용 거래가 `holdings.quantity`, `holdings.average_price`, `cash_accounts.balance`에 섞일 수 있다.

## User Impact

- 사용자가 과거 거래 내역을 기록용으로 추가한 뒤 동기화/원격 재계산/복구 흐름을 거치면 현재 보유 수량, 평균단가, 현금 잔액, 자산 비중, 평가금액이 바뀐 것처럼 보일 수 있다.
- 거래 내역, 분석, 스냅샷에는 기록용 거래가 보여야 하므로 조회 전체에서 숨기면 안 된다.

## Reproduction Or Evidence

- 투자 거래 폼과 현금 거래 폼은 `includeInCalculations` 값을 `AppDatabase.createTransaction`/`updateTransactionItem`에 전달한다.
- `AppDatabase.createTransaction`은 `includeInCalculations == false`일 때 `source = 'record_only'` 원장 이벤트를 만든다.
- 로컬 상태 재계산 쿼리는 `te.source NOT IN ('history_display', 'record_only')`를 사용한다.
- `supabase/migrations/20260522143000_reconcile_state_from_transaction_ledger.sql`은 `transaction_lines`를 합산하면서 `record_only`를 제외하지 않는다.

## Root Cause Hypothesis

기록용 거래 정책이 `source = 'record_only'`로 표현되지만, 원격 상태 재계산 SQL이 로컬 상태 재계산 SQL과 같은 제외 조건을 공유하지 않아 정책이 분기되었다.

## Fix Strategy

- 새 Supabase migration을 추가해 원격 `holdings`와 `cash_accounts`를 활성 원장 기준으로 다시 보정한다.
- 보정 쿼리는 현재 포트폴리오 상태 계산에서 `history_display`, `record_only`를 제외한다.
- 분석/스냅샷/거래 내역 조회 코드는 변경하지 않는다. 기록용 거래가 분석과 스냅샷에 포함되어야 한다는 현재 정책을 유지한다.

## Non Goals

- 기록용 거래를 거래 내역에서 숨기지 않는다.
- 성과 분석, 배당/이자 분석, 스냅샷 거래 목록에서 `record_only`를 제외하지 않는다.
- 기존 dirty UI 파일은 수정하지 않는다.

## Regression Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter analyze`
- SQL migration을 코드 리뷰 기준으로 확인한다:
  - holdings 재계산 join에서 `te.source NOT IN ('history_display', 'record_only')`
  - cash_accounts 재계산 join에서 같은 제외 조건
  - 마지막에 `public.recompute_asset_metrics(null)`로 asset summary 재계산

## Risk And Rollback Notes

- 위험은 낮다. 변경 범위는 원격 상태 보정 migration 한 개다.
- 롤백이 필요하면 migration 적용 전 DB backup 또는 Supabase PITR 기준으로 되돌린다.
- 기록용 거래의 표시/분석/스냅샷 포함 정책은 유지되므로 해당 화면의 표시 변화는 없어야 한다.
