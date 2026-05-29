# Ledger Realized PnL Moving Average Recompute Plan

## Bug Summary

원격 ledger backfill은 legacy `transactions.realized_profit_amount` 값을 `transaction_lines.realized_pnl`로 복사했다. 그런데 과거 row 중 `realized_profit_amount`가 기본값 `0`으로 남아 있으면, 매도 거래의 실현손익과 `cost_basis_delta`가 잘못 이관된다.

이를 보정하기 위해 추가한 migration은 `transaction_lines`를 시간순으로 재생해 이동평균 원가를 복원하는 방향이었지만, 사용자가 과거 모든 거래를 입력했다고 볼 수 없으므로 그 전제 자체가 위험하다. 리뷰와 정책 재검토 결과 다음 위험이 확인됐다.

- 현재 상태 재계산에서 `snapshot_restore` line을 제외해 복원된 보유 수량/평균단가가 0으로 밀릴 수 있다.
- 원격 sync 충돌 기준인 `last_modified_at`을 갱신하지 않아, 이후 오래된 로컬 row가 서버 보정값을 다시 덮어쓸 수 있다.
- 첫 거래가 매도이거나 보유 수량보다 많이 매도된 legacy 데이터에서 실현손익이 과대 계산될 수 있다.
- 스냅샷이나 사용자 입력 원가 없이 전체 거래 재생만으로 보정하면, 누락된 과거 매수 때문에 실현손익이 크게 왜곡될 수 있다.

## User Impact

- 실현손익 분석 화면, 월별 성과, 종목별 성과 랭킹에서 과거 매도 손익이 0 또는 잘못된 값으로 표시될 수 있다.
- `cost_basis_delta`가 잘못되면 원장 기준 남은 원가와 `holdings.average_price`가 틀어져 평가손익까지 연쇄적으로 왜곡될 수 있다.
- snapshot restore로 복구된 사용자는 migration 적용 후 현재 보유 항목이 사라지거나 평균단가가 0으로 보일 수 있다.
- 서버 보정 직후 sync가 일어나면 클라이언트의 오래된 값이 서버 보정값을 되돌릴 수 있다.
- 과거 매수 내역이 누락된 사용자는 자동 보정으로 인해 실제보다 큰 실현이익이 기록될 수 있다.

## Reproduction Or Evidence

- `supabase/migrations/20260522094500_backfill_transaction_ledger_from_legacy.sql`은 `t.realized_profit_amount`를 그대로 `tl.realized_pnl`에 넣고, `cost_basis_delta`도 `gross_amount - realized_profit_amount`로 계산한다.
- `supabase/migrations/20260522090000_normalize_transaction_amounts.sql`은 `realized_profit_amount` 컬럼을 추가하지만 backfill update에서 값을 계산하지 않는다.
- 로컬 앱의 실현손익 계산은 매도 시 `unitPrice - averageCostBasis`에 수량을 곱한다.
- 로컬 상태 재계산과 최신 원격 reconcile 정책은 현재 상태에서 `history_display`, `record_only`만 제외하고 `snapshot_restore`는 포함한다.
- sync edge function은 `last_modified_at`으로 서버/클라이언트 충돌을 판정한다.

## Root Cause Hypothesis

legacy transaction table에는 매도 시점 평균단가가 저장되어 있지 않다. 따라서 단일 row update로 `realized_profit_amount`를 복구할 수 없다.

다만 보유 종목별 거래를 발생일/정렬순으로 처음부터 재생하는 방식은 모든 과거 거래가 입력되어 있다는 강한 전제가 필요하다. 실제 사용자는 앱 도입 이전 거래를 모두 입력하지 않았을 수 있으므로, 신뢰 가능한 스냅샷 또는 사용자 입력 원가를 우선해야 한다.

추가 migration 초안은 전체 재생 접근을 사용했고, 원장 source별 정책과 sync timestamp 정책도 기존 앱/원격 코드와 완전히 맞추지 못했다.

## Fix Strategy

Phase 1은 원격 보정 migration을 안전하게 만드는 작업이고, Phase 2는 신규/수정 매도 거래에서 사용자가 실현손익을 확정할 수 있게 하는 앱 UX 작업이다. Phase 1은 추측 보정을 줄이는 데 집중하고, Phase 2는 스냅샷/원장 anchor가 없는 사용자의 정상 입력 경로를 만든다.

1. `snapshot_restore` 정책 정정
   - 실현손익 재계산 대상 trade replay에서는 `snapshot_restore`, `history_display`, `record_only`를 제외한다.
   - 현재 보유 상태 재계산에서는 기존 정책과 동일하게 `history_display`, `record_only`만 제외한다.
   - `snapshot_restore` opening line은 현재 상태 복원 기준으로 포함해야 한다.

2. sync timestamp 보존
   - `transaction_lines` 보정 update에 `last_modified_at = now()`를 추가한다.
   - `holdings` 보정 update에도 `last_modified_at = now()`를 추가한다.
   - 기존 `updated_at = now()`도 유지한다.

3. 스냅샷 anchor 기반 자동 보정
   - 매도 거래 이전의 가장 가까운 스냅샷을 찾는다.
   - 기본 anchor는 `snapshot_date < sell.occurred_at`인 최신 스냅샷으로 한다. 같은 날 스냅샷은 거래 후 상태일 수 있으므로 자동 anchor로 쓰지 않는다.
   - 스냅샷 보유 row의 `total_purchase_amount / quantity`를 매도 전 기준 평균단가로 사용한다.
   - 스냅샷 이후부터 매도 직전까지의 ledger 거래만 재생해 평균단가를 조정한다.
   - 스냅샷 anchor가 없으면 원격 migration은 임의로 실현손익을 보정하지 않는다.

4. 매도 입력 UX 보강
   - 매도 거래 생성/수정 시 실현손익 계산 방식을 선택할 수 있는 창 또는 섹션을 추가한다.
   - 기본값은 `자동 계산`으로 둔다.
   - 자동 계산이 가능한 경우 현재 보유 평균단가 또는 스냅샷/원장 기준 평균단가를 사용한다.
   - 자동 계산 기준이 없거나 사용자가 실제 체결 손익을 알고 있으면 `직접 입력`을 선택해 실현손익을 입력할 수 있게 한다.
   - 직접 입력된 실현손익은 `transaction_lines.realized_pnl`과 legacy mirror의 `realized_profit_amount`에 저장한다.
   - 직접 입력 시 `cost_basis_delta = -(gross_amount - realized_pnl)`로 원가 차감을 맞춘다.

5. 사용자 입력값 추적
   - 직접 입력된 실현손익인지, 자동 계산된 실현손익인지 구분할 수 있는 저장 위치를 검토한다.
   - schema 변경을 최소화하려면 우선 `transaction_events.memo` 또는 별도 metadata column 없이 값만 저장할 수 있다.
   - 장기적으로는 `transaction_lines.realized_pnl_source` 같은 column을 추가해 `auto`, `manual`, `snapshot_anchor`를 구분하는 방안을 검토한다.

6. 매도 수량 clamp
   - 매도 적용 수량은 `least(abs(quantity_delta), greatest(quantity_before, 0))`로 제한한다.
   - 실현손익은 `gross_amount - average_cost_before * applied_sell_quantity`로 계산한다.
   - 원가 차감은 `-(average_cost_before * applied_sell_quantity)`로 계산한다.
   - 전량 매도 후 floating point dust 수준의 수량은 0으로 정리한다.

7. 원가 없는 매도 처리
   - 매도 직전 수량이 0 이하인 sell line은 자동으로 `gross_amount` 전체를 이익으로 보지 않는다.
   - 기본 정책은 `applied_sell_quantity = 0`, `computed_cost_basis_delta = 0`, `computed_realized_pnl = 0`으로 둔다.
   - 이 케이스는 사용자에게 직접 입력이 필요한 데이터로 분류한다.
   - migration 검증 쿼리에서 별도로 집계할 수 있게 한다.

8. migration 적용 범위 유지
   - legacy archive table에 의존하지 않는다.
   - 이미 존재하는 `transaction_lines`와 `transaction_events`만 사용한다.
   - 원격 migration은 확실한 anchor가 있는 row만 보정하고, 불확실한 row는 보수적으로 유지한다.

## Non Goals

- FIFO/LIFO 원가법을 도입하지 않는다. 현재 앱 정책인 이동평균 원가법을 유지한다.
- 이미 archive/drop 된 legacy `transactions` 테이블을 복원하지 않는다.
- 과거에 원장으로 이관되지 않은 거래를 새로 만들어내지 않는다.
- 스냅샷 수익률 자체를 재산출하지 않는다. 이번 수정은 ledger realized PnL과 현재 holdings 원가 보정에 집중한다.
- record-only 거래를 현재 상태 계산에 포함하지 않는다.
- 사용자가 직접 입력한 실현손익을 세무 신고용 확정값으로 보증하지 않는다. 앱 내 성과 계산용 값으로 취급한다.

## Regression Test Plan

로컬 앱 회귀:

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
git diff --check
```

SQL 리뷰 체크:

- trade replay 대상 source filter가 `snapshot_restore`, `history_display`, `record_only`를 제외한다.
- holdings state reconcile source filter가 `history_display`, `record_only`만 제외한다.
- 스냅샷 anchor가 없는 sell row는 원격 migration에서 임의 보정하지 않는다.
- `transaction_lines` update가 `cost_basis_delta`, `realized_pnl`, `updated_at`, `last_modified_at`을 갱신한다.
- `holdings` update가 `quantity`, `average_price`, `updated_at`, `last_modified_at`을 갱신한다.
- 마지막에 `public.recompute_asset_metrics(null)`를 호출한다.

SQL fixture 검증 케이스:

- 스냅샷 없이 `buy 100 * 5`, `sell 120 * 2`만 있는 legacy row는 원격 migration이 자동 보정하지 않는다.
- 스냅샷 anchor `quantity 5 / purchase 500` 이후 `sell 120 * 2`는 `realized_pnl = 40`, 남은 원가 `300`, 평균단가 `100`이 된다.
- 스냅샷 anchor `quantity 5 / purchase 500` 이후 `buy 200 * 5`, `sell 180 * 4`는 매도 직전 평균단가 `150`, `realized_pnl = 120`, 남은 수량 `6`, 남은 원가 `900`이 된다.
- `snapshot_restore opening_quantity 5 / cost_basis 500`만 있는 보유 항목은 state reconcile 후 수량 `5`, 평균단가 `100`을 유지한다.
- 첫 row가 sell인 데이터는 `realized_pnl`을 gross 전체 이익으로 만들지 않는다.
- 보유 수량보다 큰 sell은 현재 보유 수량까지만 원가 차감한다.
- `history_display`와 `record_only`는 현재 holdings state에 반영되지 않는다.

UI/DB 앱 테스트:

- 매도 거래 폼에서 자동 계산과 직접 입력을 선택할 수 있다.
- 자동 계산 기준이 없으면 직접 입력을 안내하거나 실현손익을 0으로 둘 수 있음을 명확히 보여준다.
- 직접 입력한 실현손익이 저장 후 거래 상세, 성과 요약, 월별 성과에 반영된다.
- 직접 입력한 실현손익으로 `cost_basis_delta`가 `-(gross_amount - realized_pnl)`에 맞게 저장된다.
- 직접 입력 값을 가진 매도 거래를 수정해도 사용자가 입력한 손익이 의도 없이 자동 계산값으로 덮이지 않는다.

## Risk And Rollback Notes

위험도는 중간이다. 원격 migration이 과거 원장 전체를 다시 쓰므로, SQL 로직 오류가 있으면 성과 분석과 현재 보유 평균단가에 직접 영향을 준다.

적용 전에는 Supabase backup 또는 PITR 가능 시점을 확인한다. 적용 후에는 다음 aggregate를 점검한다.

- 보정 전후 `sum(realized_pnl)` 변화
- 보정 전후 `sum(cost_basis_delta)` 변화
- `holdings.quantity`가 0이 아닌데 `average_price = 0`인 비정상 row
- source가 `snapshot_restore`뿐인 holdings의 수량/평균단가 유지 여부
- 스냅샷 anchor 없이 자동 보정되지 않은 sell row 수

문제가 생기면 DB backup/PITR로 되돌리는 것을 우선한다. 단순 down migration으로는 재계산 전 개별 `realized_pnl` 값을 복원할 수 없다.

## Open Questions

- 원가 없는 매도 row를 `0`으로 둘지, 사용자 입력 필요 목록으로 보여줄지 결정해야 한다.
- oversell row의 `gross_amount`를 실제 적용 수량 비율로 나눠 실현손익을 부분 계산할지, 현재 초안처럼 gross는 유지하고 원가만 clamp할지 확인이 필요하다.
- 서버 보정 후 모든 클라이언트가 pull sync를 강제하도록 UX 또는 운영 절차를 둘지 검토가 필요하다.
- 직접 입력 실현손익의 출처를 schema column으로 저장할지, 값만 저장할지 결정해야 한다.
