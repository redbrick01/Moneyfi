# Implementation Report 08: Yahoo IRX Risk-Free Rate

## Summary

Sharpe Ratio 계산에 Yahoo Finance `^IRX`를 이용한 미국 13주 T-Bill 무위험수익률 proxy를 반영했다.

## Changes

| 영역 | 변경 |
| --- | --- |
| API/cache | `BenchmarkPriceService`가 `US_13W_TBILL` 코드를 `^IRX`로 조회하고 `benchmark_prices`에 저장한다. |
| 데이터 표현 | `^IRX`의 `close` 값은 퍼센트 단위로 저장한다. 예: `5.25`는 연 5.25%다. |
| 계산 | Sharpe Ratio 계산 시 저장된 최신 `^IRX` 값을 `0.0525`처럼 연율 소수로 변환해 `riskFreeRate`에 전달한다. |
| UI | 고급 성과 카드에 `무위험수익률` 행을 추가하고, Sharpe 설명에 적용 기준을 표시한다. |
| fallback | `^IRX` 데이터를 가져오지 못하면 기존과 동일하게 0% 무위험수익률 기준으로 계산한다. |

## User-Facing Behavior

- 사용자는 고급 성과에서 Sharpe Ratio가 어떤 무위험수익률 기준으로 계산됐는지 볼 수 있다.
- `^IRX` 데이터가 있으면 미국 13주 T-Bill 기준이 반영된다.
- 네트워크/API 실패 시에도 화면은 깨지지 않고 0% 기준 fallback으로 유지된다.

## Verification

| 검증 | 결과 |
| --- | --- |
| `flutter analyze lib/services/benchmark_price_service.dart lib/pages/investment_performance_page.dart test/market_data_service_test.dart test/risk_adjusted_performance_calculator_test.dart test/page_walkthrough_test.dart` | 통과 |
| `flutter test test/market_data_service_test.dart test/risk_adjusted_performance_calculator_test.dart test/page_walkthrough_test.dart` | 통과 |

## Notes

- 이번 구현은 별도 table이나 migration을 추가하지 않고 기존 `benchmark_prices`를 재사용한다.
- `^IRX`는 USD 기반 proxy이므로 KRW 투자자의 정확한 무위험수익률은 추후 ECOS CD 91일물 등으로 분리할 수 있다.
