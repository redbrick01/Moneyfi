# Crypto Sell Quantity Precision Test Report 2026-05-28

## Summary

가상화폐처럼 소수점 6~8자리 이상 수량을 가진 보유 종목에서 전량 매도 시 보유 수량 초과 오류가 발생할 수 있는 문제를 수정했다. 수량 저장/표시 formatter를 금액 formatter와 분리하고, 매도 검증과 보유 수량 재계산에 같은 수량 tolerance 정책을 적용했다.

## Reproduction Status

- 기존 수량 저장 formatter는 정수가 아닌 값을 3자리 소수로 고정해 `0.12345678` 같은 수량을 보존하지 못했다.
- 기존 보유 수량 표시도 3자리 소수로 잘려, 사용자가 화면 표시 수량을 전량 매도 입력으로 신뢰하기 어려웠다.
- 기존 매도 검증과 재계산은 `0.0000001` 고정 기준을 사용해 코인 최소 단위급 수량에서 잔량/전량 매도 판정이 거칠었다.

## Root Cause

- 금액 중심의 `_formatPlainNumber()`가 거래 수량 저장에도 재사용되고 있었다.
- `HoldingItem.quantityText`가 수량 도메인 정밀도를 고려하지 않고 3자리로 표시했다.
- 매도 가능 수량 비교, legacy 보유 재계산, ledger 보유 재계산이 같은 의미의 수량 tolerance를 별도 상수 없이 직접 사용했다.

## Fix Summary

- `lib/utils/number_formatters.dart`를 추가해 수량 전용 formatter와 tolerance helper를 분리했다.
- `storedQuantity`는 `formatPlainQuantity()`를 사용하고, `storedAmount`는 기존 금액 포맷 정책을 유지하는 wrapper를 사용하도록 변경했다.
- `HoldingItem.quantityText`가 수량 전용 formatter를 사용하도록 변경했다.
- 매도 초과 검증 메시지도 수량 전용 formatter를 사용해 실제 비교 수량을 더 정확히 보여 준다.
- legacy/ledger 재계산의 dust quantity 정리 기준을 수량 tolerance helper로 통합했다.
- 이미 3자리로 잘려 저장된 과거 거래 수량은 자동 복구하지 않는다.

## Commands Run

| 명령 | 결과 |
| --- | --- |
| `dart format lib/db/app_database_calculations.dart lib/models/asset_item.dart lib/db/app_database.dart test/transaction_flow_test.dart test/asset_item_test.dart lib/utils/number_formatters.dart` | Pass |
| `flutter test test/transaction_flow_test.dart` | Pass, 55 tests |
| `flutter test test/asset_item_test.dart` | Pass, 2 tests |
| `flutter analyze` | Pass |
| `git diff --check` | Pass |

## Regression Coverage

- 소수 8자리 수량 `0.12345678` 매수 후 같은 수량 전량 매도가 성공한다.
- 거래 내역의 매수/매도 수량 문자열이 `0.12345678`로 보존된다.
- `HoldingItem.quantityText`가 `0.12345678`을 3자리로 줄이지 않는다.
- 보유 수량보다 tolerance를 넘겨 큰 수량을 매도하면 `StateError`로 실패한다.
- `0.1 + 0.2 - 0.3` 같은 double dust 잔량은 전량 매도 후 0으로 정리된다.
- 기존 거래 흐름 테스트 전체가 통과해 매수/매도, 현금 정산, ledger parity, snapshot transaction 목록 회귀를 확인했다.

## Manual QA Status

Manual app UI QA는 실행하지 않았다. 이번 변경은 Drift DB 거래 흐름과 모델 formatter 테스트로 검증했다. 앱에서 최종 확인할 때는 코인 보유 종목을 만들고 `0.12345678` 매수 후 같은 수량 매도, 보유 상세/거래 목록의 수량 표시를 확인하면 된다.

## Remaining Risk

- 이미 과거에 3자리로 잘려 저장된 거래 수량은 원래 입력값을 복원할 수 없다.
- 수량 formatter는 최대 12자리 고정 후 trailing zero를 제거한다. 12자리보다 더 작은 단위가 필요한 자산이 생기면 formatter scale 정책을 다시 조정해야 한다.
- 금액 formatter는 기존 3자리 정책을 유지했다. 금액 자체도 더 긴 소수 정밀도가 필요한 자산군은 별도 작업으로 다뤄야 한다.

## Final Result

Pass. 신규/수정 거래의 코인급 소수 수량 보존과 전량 매도 검증 안정화가 자동 테스트로 확인되었다.
