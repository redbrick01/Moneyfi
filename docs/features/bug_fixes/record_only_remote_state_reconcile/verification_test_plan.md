# Record Only Remote State Reconcile Verification Test Plan

## Scope

기록용 거래가 현재 포트폴리오 상태에는 영향을 주지 않고, 분석/스냅샷/거래 내역에는 계속 포함되는지 확인한다.

## Automated Tests

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
```

## Expected Automated Coverage

- 기록용 현금 거래는 현금 잔액을 바꾸지 않는다.
- 기록용 매수는 보유 수량과 결제 현금을 바꾸지 않는다.
- 기록용 거래는 거래 내역에 표시되고 `includeInCalculations == false`로 복원된다.
- 기존 분석/스냅샷 테스트는 기록용 거래 표시 정책을 유지한다.

## SQL Review Checklist

- 원격 holdings 보정 쿼리:
  - `transaction_lines.holding_id` 기준 합산
  - `tl.deleted_at is null`
  - `te.deleted_at is null`
  - `te.source NOT IN ('history_display', 'record_only')`
- 원격 cash_accounts 보정 쿼리:
  - `cash_accounts.base_balance + SUM(tl.cash_delta)`
  - `tl.deleted_at is null`
  - `te.deleted_at is null`
  - `te.source NOT IN ('history_display', 'record_only')`
- asset summary 보정:
  - `select public.recompute_asset_metrics(null);`

## Manual QA

1. 보유 종목에 `계산 반영 안 함` 매수 거래를 추가한다.
2. 거래 내역에는 거래가 표시되는지 확인한다.
3. 보유 수량, 평균단가, 결제 현금, 자산 평가금액이 변하지 않는지 확인한다.
4. 분석 화면과 스냅샷 상세 거래 목록에는 기록용 거래가 포함되는지 확인한다.
5. 현금 계좌에 기록용 입금/출금을 추가하고 현금 잔액이 변하지 않는지 확인한다.

## Remote Verification

원격 적용 후 제한된 검증 쿼리로 `record_only` 이벤트가 있는 계정의 holdings/cash_accounts 값이 `record_only` 제외 합산과 일치하는지 확인한다. 운영 데이터 조회 시 사용자 식별 정보와 거래명은 출력하지 않는다.
