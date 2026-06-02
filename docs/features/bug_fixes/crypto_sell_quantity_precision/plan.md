# Crypto Sell Quantity Precision Fix Plan

## Bug Summary

가상화폐처럼 소수점 긴 보유 수량 종목에서, 화면 현재 보유 수량 그대로 매도 수량 입력해도 "매도 수량이 보유 수량보다 많습니다" 오류로 저장 실패.

## User Impact

- 사용자는 전량 매도 선택 인식하지만 거래 저장 실패.
- 보유 수량 표시가 실제 저장 수량보다 반올림되면, 화면 표시값 신뢰 어려움.
- 소수점 6~8자리 이상 코인 거래에서 잔량, 전량 매도, 거래 수정 UX 불안정.

## Reproduction Or Evidence

- `lib/db/app_database_calculations.dart`의 `_formatPlainNumber()`는 정수 아닌 값 `toStringAsFixed(3)`로 저장/표시 문자열 변환.
- `lib/models/asset_item.dart`의 `HoldingItem.quantityText`도 정수 아닌 보유 수량 `toStringAsFixed(3)` 표시.
- `lib/db/app_database.dart`의 `_ensureSufficientHoldingQuantityForSell()`은 `0.0000001` 기준으로 보유량 0 처리 또는 초과 매도 판정.
- 따라서 실제 보유 수량 `0.12345678`이어도 화면/거래 문자열이 `0.123`/`0.123457` 등으로 달라짐. 표시 수량을 전량 매도 입력에 쓰면 실제 검증 기준과 불일치.
- 이미 3자리 저장된 과거 거래 수량은 원 입력값 잃었을 수 있음. 이 수정은 신규/수정 거래 정밀도 손실 방지. 과거 손실 데이터 자동 복원 보장 없음.

## Root Cause Hypothesis

- 원장/거래 저장용 plain number formatter가 금액 중심 3자리 소수 포맷을 수량에도 재사용.
- 보유 수량 UI도 도메인별 수량 정밀도 고려 없이 3자리 고정 표시.
- 매도 가능 수량 검증은 double 비교에 고정 epsilon 사용. 일반 주식 수량엔 관대하지만, 8자리 이상 소수 자산엔 너무 크거나 부정확 가능.

## Fix Strategy

1. 수량/금액 formatter 분리
   - `_formatPlainNumber()` 무작정 확장 금지. 이 helper는 금액, 현금 거래, 거래 목록 표시, 원장 mirror까지 넓게 쓰여 blast radius 큼.
   - 수량 저장/표시에는 `formatQuantityPlain` 성격 전용 helper 도입.
   - 금액 저장/표시에는 기존 3자리 정책 유지 또는 별도 `formatAmountPlain` helper 사용.
   - 거래 생성/수정에서 `storedQuantity`는 수량 전용 formatter, `storedAmount`는 금액 전용 formatter 사용.

2. 수량 formatter 정책 확정
   - 정수는 기존처럼 소수점 없이 표시.
   - 소수는 trailing zero와 불필요한 `.` 제거.
   - 최대 scale은 우선 12자리. BTC 8자리와 double 노이즈 고려해 테스트 고정.
   - 100% 매도 값은 반올림으로 매도 가능 수량 초과하면 안 됨. 필요 시 percentage shortcut에서 내림 또는 tolerance-safe formatter 사용.

3. 보유 수량 표시 정밀도 개선
   - `HoldingItem.quantityText`를 3자리 고정에서 정밀도 보존 포맷으로 변경.
   - 정수는 기존처럼 정수 표시.
   - 소수는 수량 전용 formatter와 같은 정책 사용.

4. 매도 수량 검증 안정화
   - `_ensureSufficientHoldingQuantityForSell()`의 고정 epsilon을 tolerance helper로 분리.
   - 같은 helper를 legacy 재계산, ledger 재계산, 매도 가능 수량 비교에서 공유.
   - 전량 매도 시 `sellQuantity`가 `availableQuantity`와 실질적으로 같으면 허용.
   - `sellQuantity`가 `availableQuantity`를 tolerance보다 크게 초과하면 기존처럼 실패.
   - 검증 실패 메시지 매도/보유 수량도 새 formatter 사용해 실제 차이 표시.

5. 재계산 잔량 처리 기준 통합
   - `_recalculateHoldingFromTransactions()`와 `_recalculateHoldingFromLedgerLines()`의 `0.0000001` 잔량 0 처리 기준을 같은 tolerance helper로 통합.
   - 가상화폐 최소 단위보다 큰 기준으로 잔량 사라지지 않게 조정.
   - 전량 매도 뒤 발생 double 노이즈는 0 정리, 의미 있는 8자리 이하 잔량은 보존.

## Non-goals

- DB schema 변경 없음.
- double 기반 저장 구조를 decimal 패키지나 문자열 수량 저장으로 전면 교체 안 함.
- 외부 거래소 종목별 최소 주문 단위 모델링 안 함.
- 이미 3자리로 잘려 저장된 과거 수량을 원 입력값으로 복원 안 함.
- 매도 비중 빠른 선택 UI는 별도 기능 계획에서 처리.

## Regression Test Plan

```bash
dart format lib/db/app_database_calculations.dart lib/models/asset_item.dart lib/db/app_database.dart test/transaction_flow_test.dart test/asset_item_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/asset_item_test.dart
flutter analyze
git diff --check
```

추가할 테스트:

- 소수 8자리 보유 수량 매수 뒤 같은 수량 전량 매도 성공.
- 화면 표시용 `quantityText`가 `0.12345678`을 3자리로 줄이지 않음.
- 실제 보유보다 최소 허용 오차 초과한 큰 수량 매도하면 기존처럼 실패.
- 전량 매도 뒤 극소 잔량 처리 기준이 기대대로 0 또는 보존.
- legacy `transactions` 기반 생성/수정 경로와 ledger-backed 생성/수정 경로 모두 검증.
- record-only 투자 거래 표시 수량은 보존, 현재 보유 수량에는 미반영 기존 정책 유지.
- 금액 formatter가 의도치 않게 긴 소수 문자열 표시하지 않는지 기존 금액 테스트 확인.

## Risk And Rollback Notes

위험도 중간. 기존 공용 formatter 직접 확장 시 거래 금액, 현금 거래, 원장 표시 문자열 회귀 가능. 수량 전용 formatter 먼저 도입해 적용 범위 축소. 문제 발생 시 수량 formatter 적용 지점을 거래 수량 저장/보유 수량 표시로 더 제한해 롤백.

## Open Questions

- 수량 최대 표시 자릿수 8자리 vs 12자리 결정 필요.
- 금액도 소수 3자리 이상 보존해야 하는 자산군 있는지 확인 필요.
- 장기적으로 double 대신 decimal 기반 연산 도입할지 별도 기술 부채로 둘지 검토.
- tolerance 기준을 절대값으로 둘지, 수량 규모 기반 상대값도 함께 쓸지 결정 필요.