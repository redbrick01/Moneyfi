# Ledger Realized PnL Moving Average Recompute Plan

## Bug Summary

원격 ledger backfill이 legacy `transactions.realized_profit_amount`를 `transaction_lines.realized_pnl`로 복사. 과거 row에서 `realized_profit_amount` 기본값 `0` 남으면, 매도 실현손익 + `cost_basis_delta` 오이관.

추가 migration은 `transaction_lines` 시간순 재생해 이동평균 원가 복원하려 했음. 하지만 사용자가 과거 모든 거래 입력했다는 전제 위험. 리뷰 + 정책 재검토 결과 위험 확인.

- 현재 상태 재계산에서 `snapshot_restore` line 제외하면 복원 보유 수량/평균단가 0으로 밀릴 수 있음.
- 원격 sync 충돌 기준 `last_modified_at` 미갱신. 이후 오래된 로컬 row가 서버 보정값 다시 덮을 수 있음.
- 첫 거래 매도 or 보유 수량 초과 매도 legacy 데이터에서 실현손익 과대 계산 가능.
- 스냅샷/사용자 입력 원가 없이 전체 거래 재생만 하면, 누락 과거 매수 때문에 실현손익 크게 왜곡 가능.

## User Impact

- 실현손익 분석, 월별 성과, 종목별 성과 랭킹에서 과거 매도 손익 0 or 오표시.
- `cost_basis_delta` 오류면 원장 기준 남은 원가 + `holdings.average_price` 틀어짐. 평가손익까지 연쇄 왜곡.
- snapshot restore 복구 사용자는 migration 후 현재 보유 사라지거나 평균단가 0 표시 가능.
- 서버 보정 직후 sync 시 클라이언트 오래된 값이 서버 보정값 되돌릴 수 있음.
- 과거 매수 누락 사용자는 자동 보정 때문에 실제보다 큰 실현이익 기록 가능.

## Reproduction Or Evidence

- `supabase/migrations/20260522094500_backfill_transaction_ledger_from_legacy.sql`은 `t.realized_profit_amount` 그대로 `tl.realized_pnl`에 넣고, `cost_basis_delta`도 `gross_amount - realized_profit_amount`로 계산.
- `supabase/migrations/20260522090000_normalize_transaction_amounts.sql`은 `realized_profit_amount` 컬럼 추가하지만 backfill update에서 값 계산 안 함.
- 로컬 앱 실현손익 계산은 매도 시 `unitPrice - averageCostBasis`에 수량 곱함.
- 로컬 상태 재계산 + 최신 원격 reconcile 정책은 현재 상태에서 `history_display`, `record_only`만 제외하고 `snapshot_restore` 포함.
- sync edge function은 `last_modified_at`으로 서버/클라이언트 충돌 판정.

## Root Cause Hypothesis

legacy transaction table에는 매도 시점 평균단가 없음. 단일 row update로 `realized_profit_amount` 복구 불가.

종목별 거래를 발생일/정렬순으로 처음부터 재생하려면 모든 과거 거래 입력 전제 필요. 실제 사용자는 앱 도입 전 거래 모두 입력 안 했을 수 있음. 신뢰 가능한 스냅샷 or 사용자 입력 원가 우선 필요.

추가 migration 초안은 전체 재생 접근 사용. 원장 source별 정책 + sync timestamp 정책도 기존 앱/원격 코드와 불일치.

## Fix Strategy

Phase 1: 원격 보정 migration 안전화. Phase 2: 신규/수정 매도 거래에서 사용자가 실현손익 확정 가능하게 앱 UX 추가. Phase 1은 추측 보정 축소. Phase 2는 스냅샷/원장 anchor 없는 사용자 정상 입력 경로 제공.

1. `snapshot_restore` 정책 정정
   - 실현손익 재계산 trade replay 대상에서는 `snapshot_restore`, `history_display`, `record_only` 제외.
   - 현재 보유 상태 재계산에서는 기존 정책처럼 `history_display`, `record_only`만 제외.
   - `snapshot_restore` opening line은 현재 상태 복원 기준에 포함.

2. sync timestamp 보존
   - `transaction_lines` 보정 update에 `last_modified_at = now()` 추가.
   - `holdings` 보정 update에도 `last_modified_at = now()` 추가.
   - 기존 `updated_at = now()` 유지.

3. 스냅샷 anchor 기반 자동 보정
   - 매도 거래 이전 가장 가까운 스냅샷 찾기.
   - 기본 anchor는 `snapshot_date < sell.occurred_at` 최신 스냅샷. 같은 날 스냅샷은 거래 후 상태일 수 있어 자동 anchor 제외.
   - 스냅샷 보유 row의 `total_purchase_amount / quantity`를 매도 전 평균단가로 사용.
   - 스냅샷 이후부터 매도 직전까지 ledger 거래만 재생해 평균단가 조정.
   - 스냅샷 anchor 없으면 원격 migration은 임의 실현손익 보정 안 함.

4. 매도 입력 UX 보강
   - 매도 거래 생성/수정 시 실현손익 계산 방식 선택 창 or 섹션 추가.
   - 기본값은 `자동 계산`.
   - 자동 계산 가능 시 현재 보유 평균단가 or 스냅샷/원장 기준 평균단가 사용.
   - 자동 계산 기준 없거나 사용자가 실제 체결 손익 알면 `직접 입력` 선택해 실현손익 입력.
   - 직접 입력 실현손익은 `transaction_lines.realized_pnl` + legacy mirror `realized_profit_amount`에 저장.
   - 직접 입력 시 `cost_basis_delta = -(gross_amount - realized_pnl)`로 원가 차감 맞춤.

5. 사용자 입력값 추적
   - 직접 입력 실현손익인지, 자동 계산 실현손익인지 저장 위치 검토.
   - schema 변경 최소화 시 우선 `transaction_events.memo` or 별도 metadata column 없이 값만 저장 가능.
   - 장기적으로 `transaction_lines.realized_pnl_source` 같은 column 추가해 `auto`, `manual`, `snapshot_anchor` 구분 검토.

6. 매도 수량 clamp
   - 매도 적용 수량은 `least(abs(quantity_delta), greatest(quantity_before, 0))`로 제한.
   - 실현손익은 `gross_amount - average_cost_before * applied_sell_quantity`로 계산.
   - 원가 차감은 `-(average_cost_before * applied_sell_quantity)`로 계산.
   - 전량 매도 후 floating point dust 수준 수량은 0 정리.

7. 원가 없는 매도 처리
   - 매도 직전 수량 0 이하 sell line은 자동으로 `gross_amount` 전체를 이익 처리 안 함.
   - 기본 정책은 `applied_sell_quantity = 0`, `computed_cost_basis_delta = 0`, `computed_realized_pnl = 0`.
   - 이 케이스는 사용자 직접 입력 필요 데이터로 분류.
   - migration 검증 쿼리에서 별도 집계 가능하게 함.

8. migration 적용 범위 유지
   - legacy archive table 의존 안 함.
   - 이미 존재하는 `transaction_lines`와 `transaction_events`만 사용.
   - 원격 migration은 확실한 anchor 있는 row만 보정. 불확실 row는 보수 유지.

## Non Goals

- FIFO/LIFO 원가법 도입 안 함. 현재 앱 정책 이동평균 원가법 유지.
- 이미 archive/drop 된 legacy `transactions` 테이블 복원 안 함.
- 과거에 원장 이관 안 된 거래 새로 생성 안 함.
- 스냅샷 수익률 자체 재산출 안 함. 이번 수정은 ledger realized PnL + 현재 holdings 원가 보정 집중.
- record-only 거래 현재 상태 계산에 포함 안 함.
- 사용자가 직접 입력한 실현손익을 세무 신고용 확정값으로 보증 안 함. 앱 내 성과 계산용 값.

## Regression Test Plan

로컬 앱 회귀:

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
git diff --check
```

SQL 리뷰 체크:

- trade replay 대상 source filter가 `snapshot_restore`, `history_display`, `record_only` 제외.
- holdings state reconcile source filter가 `history_display`, `record_only`만 제외.
- 스냅샷 anchor 없는 sell row는 원격 migration에서 임의 보정 안 함.
- `transaction_lines` update가 `cost_basis_delta`, `realized_pnl`, `updated_at`, `last_modified_at` 갱신.
- `holdings` update가 `quantity`, `average_price`, `updated_at`, `last_modified_at` 갱신.
- 마지막에 `public.recompute_asset_metrics(null)` 호출.

SQL fixture 검증 케이스:

- 스냅샷 없이 `buy 100 * 5`, `sell 120 * 2`만 있는 legacy row는 원격 migration이 자동 보정 안 함.
- 스냅샷 anchor `quantity 5 / purchase 500` 이후 `sell 120 * 2`는 `realized_pnl = 40`, 남은 원가 `300`, 평균단가 `100`.
- 스냅샷 anchor `quantity 5 / purchase 500` 이후 `buy 200 * 5`, `sell 180 * 4`는 매도 직전 평균단가 `150`, `realized_pnl = 120`, 남은 수량 `6`, 남은 원가 `900`.
- `snapshot_restore opening_quantity 5 / cost_basis 500`만 있는 보유 항목은 state reconcile 후 수량 `5`, 평균단가 `100` 유지.
- 첫 row가 sell인 데이터는 `realized_pnl`을 gross 전체 이익으로 만들지 않음.
- 보유 수량 초과 sell은 현재 보유 수량까지만 원가 차감.
- `history_display`와 `record_only`는 현재 holdings state에 반영 안 됨.

UI/DB 앱 테스트:

- 매도 거래 폼에서 자동 계산과 직접 입력 선택 가능.
- 자동 계산 기준 없으면 직접 입력 안내 or 실현손익 0 가능함 명확히 표시.
- 직접 입력 실현손익이 저장 후 거래 상세, 성과 요약, 월별 성과에 반영.
- 직접 입력 실현손익으로 `cost_basis_delta`가 `-(gross_amount - realized_pnl)`에 맞게 저장.
- 직접 입력 값 가진 매도 거래 수정해도 사용자 입력 손익이 의도 없이 자동 계산값으로 덮이지 않음.

## Risk And Rollback Notes

위험도 중간. 원격 migration이 과거 원장 전체 다시 쓰므로, SQL 로직 오류 시 성과 분석 + 현재 보유 평균단가 직접 영향.

적용 전 Supabase backup or PITR 가능 시점 확인. 적용 후 다음 aggregate 점검.

- 보정 전후 `sum(realized_pnl)` 변화
- 보정 전후 `sum(cost_basis_delta)` 변화
- `holdings.quantity`가 0이 아닌데 `average_price = 0`인 비정상 row
- source가 `snapshot_restore`뿐인 holdings의 수량/평균단가 유지 여부
- 스냅샷 anchor 없이 자동 보정 안 된 sell row 수

문제 생기면 DB backup/PITR 우선. 단순 down migration으로는 재계산 전 개별 `realized_pnl` 값 복원 불가.

## Open Questions

- 원가 없는 매도 row를 `0`으로 둘지, 사용자 입력 필요 목록으로 보여줄지 결정 필요.
- oversell row의 `gross_amount`를 실제 적용 수량 비율로 나눠 실현손익 부분 계산할지, 현재 초안처럼 gross 유지 + 원가만 clamp할지 확인 필요.
- 서버 보정 후 모든 클라이언트 pull sync 강제 UX or 운영 절차 둘지 검토 필요.
- 직접 입력 실현손익 출처를 schema column으로 저장할지, 값만 저장할지 결정 필요.