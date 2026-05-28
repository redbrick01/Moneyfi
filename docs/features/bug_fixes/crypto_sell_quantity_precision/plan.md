# Crypto Sell Quantity Precision Fix Plan

## Bug Summary

가상화폐처럼 소수점 아래 여러 자리까지 보유 수량이 있는 종목에서, 화면에 보이는 현재 보유 수량을 그대로 매도 수량으로 입력했는데도 "매도 수량이 보유 수량보다 많습니다" 오류로 저장되지 않는 문제가 있다.

## User Impact

- 사용자는 전량 매도를 선택했다고 인식하지만 거래 저장이 실패한다.
- 보유 수량 표시가 실제 저장 수량보다 반올림되어 보이면, 사용자가 화면 표시값을 신뢰하기 어렵다.
- 소수점 6~8자리 이상을 사용하는 코인 거래에서 잔량, 전량 매도, 거래 수정 UX가 불안정해진다.

## Reproduction Or Evidence

- `lib/db/app_database_calculations.dart`의 `_formatPlainNumber()`는 정수가 아닌 값을 `toStringAsFixed(3)`로 저장/표시용 문자열로 변환한다.
- `lib/models/asset_item.dart`의 `HoldingItem.quantityText`도 정수가 아닌 보유 수량을 `toStringAsFixed(3)`로 표시한다.
- `lib/db/app_database.dart`의 `_ensureSufficientHoldingQuantityForSell()`은 `0.0000001` 기준으로 보유량을 0 처리하거나 초과 매도를 판정한다.
- 따라서 실제 보유 수량이 `0.12345678`이어도 화면 또는 거래 문자열이 `0.123`/`0.123457` 등으로 달라질 수 있고, 사용자가 표시 수량을 전량 매도 입력으로 사용하면 실제 검증 기준과 어긋날 수 있다.
- 이미 3자리로 저장된 과거 거래 수량은 원래 입력값을 잃었을 수 있다. 이 수정은 신규/수정 거래의 정밀도 손실을 막는 것이며, 과거 손실 데이터의 자동 복원은 보장하지 않는다.

## Root Cause Hypothesis

- 원장/거래 저장에 쓰이는 plain number formatter가 금액 중심의 3자리 소수 포맷을 수량에도 재사용하고 있다.
- 보유 수량 UI도 수량의 도메인별 정밀도를 고려하지 않고 3자리로 고정 표시한다.
- 매도 가능 수량 검증은 double 기반 비교에 고정 epsilon을 사용한다. 이 값이 일반 주식 수량에는 관대하지만, 8자리 이상 소수 단위 자산에는 너무 크거나 부정확할 수 있다.

## Fix Strategy

1. 수량/금액 formatter 분리
   - `_formatPlainNumber()`를 무작정 확장하지 않는다. 이 helper는 금액, 현금 거래, 거래 목록 표시, 원장 mirror까지 넓게 쓰이므로 blast radius가 크다.
   - 수량 저장/표시에는 `formatQuantityPlain` 성격의 전용 helper를 도입한다.
   - 금액 저장/표시에는 기존 3자리 정책 유지 또는 별도 `formatAmountPlain` helper를 사용한다.
   - 거래 생성/수정에서 `storedQuantity`는 수량 전용 formatter를 사용하고, `storedAmount`는 금액 전용 formatter를 사용한다.

2. 수량 formatter 정책 확정
   - 정수는 기존처럼 소수점 없이 표시한다.
   - 소수는 trailing zero와 불필요한 `.`을 제거한다.
   - 최대 scale은 우선 12자리로 잡되, BTC 8자리와 double 노이즈를 모두 고려해 테스트로 고정한다.
   - 100% 매도에 쓰이는 값은 반올림으로 매도 가능 수량을 초과하지 않아야 한다. 필요한 경우 percentage shortcut에서는 내림 또는 tolerance-safe formatter를 사용한다.

3. 보유 수량 표시 정밀도 개선
   - `HoldingItem.quantityText`를 3자리 고정에서 정밀도 보존형 포맷으로 변경한다.
   - 정수는 기존처럼 정수로 표시한다.
   - 소수는 수량 전용 formatter와 같은 정책을 사용한다.

4. 매도 수량 검증 안정화
   - `_ensureSufficientHoldingQuantityForSell()`의 고정 epsilon을 tolerance helper로 분리한다.
   - 같은 helper를 legacy 재계산, ledger 재계산, 매도 가능 수량 비교에서 공유한다.
   - 전량 매도 시 `sellQuantity`가 `availableQuantity`와 실질적으로 같으면 허용한다.
   - `sellQuantity`가 `availableQuantity`를 tolerance보다 크게 초과하면 기존처럼 실패한다.
   - 검증 실패 메시지의 매도/보유 수량도 새 formatter를 사용해 사용자가 실제 차이를 볼 수 있게 한다.

5. 재계산 잔량 처리 기준 통합
   - `_recalculateHoldingFromTransactions()`와 `_recalculateHoldingFromLedgerLines()`의 `0.0000001` 잔량 0 처리 기준을 같은 tolerance helper로 통합한다.
   - 가상화폐 최소 단위보다 큰 기준으로 잔량이 사라지지 않도록 조정한다.
   - 전량 매도 뒤 발생하는 double 노이즈는 0으로 정리하되, 의미 있는 8자리 이하 잔량은 보존한다.

## Non-goals

- DB schema를 변경하지 않는다.
- double 기반 저장 구조를 decimal 패키지나 문자열 수량 저장으로 전면 교체하지 않는다.
- 외부 거래소의 종목별 최소 주문 단위까지 모델링하지 않는다.
- 이미 3자리로 잘려 저장된 과거 수량을 원래 입력값으로 복원하지 않는다.
- 매도 비중 빠른 선택 UI는 별도 기능 계획에서 다룬다.

## Regression Test Plan

```bash
dart format lib/db/app_database_calculations.dart lib/models/asset_item.dart lib/db/app_database.dart test/transaction_flow_test.dart test/asset_item_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/asset_item_test.dart
flutter analyze
git diff --check
```

추가할 테스트:

- 소수 8자리 보유 수량을 매수한 뒤 같은 수량을 전량 매도하면 성공한다.
- 화면 표시용 `quantityText`가 `0.12345678`을 3자리로 줄이지 않는다.
- 실제 보유보다 최소 허용 오차를 넘겨 큰 수량을 매도하면 기존처럼 실패한다.
- 전량 매도 뒤 남는 극소 잔량 처리 기준이 기대대로 0 또는 보존으로 정리된다.
- legacy `transactions` 기반 생성/수정 경로와 ledger-backed 생성/수정 경로를 모두 검증한다.
- record-only 투자 거래의 표시 수량은 보존하되 현재 보유 수량에는 반영되지 않는 기존 정책을 유지한다.
- 금액 formatter가 의도치 않게 긴 소수 문자열을 표시하지 않는지 기존 금액 테스트를 확인한다.

## Risk And Rollback Notes

위험도는 중간이다. 기존 공용 formatter를 직접 확장하면 거래 금액, 현금 거래, 원장 표시 문자열에 회귀가 생길 수 있으므로 수량 전용 formatter를 우선 도입해 적용 범위를 좁힌다. 문제가 생기면 수량 formatter 적용 지점을 거래 수량 저장/보유 수량 표시로 더 제한해 롤백한다.

## Open Questions

- 수량 최대 표시 자릿수를 8자리로 할지, 12자리로 할지 결정이 필요하다.
- 금액도 소수 3자리 이상을 보존해야 하는 자산군이 있는지 확인해야 한다.
- 장기적으로 double 대신 decimal 기반 연산을 도입할지 별도 기술 부채로 남길지 검토한다.
- tolerance 기준을 절대값으로 둘지, 수량 규모 기반 상대값을 함께 사용할지 결정해야 한다.
