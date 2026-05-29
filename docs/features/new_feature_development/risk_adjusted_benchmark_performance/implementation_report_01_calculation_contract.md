# Implementation Report 01. Calculation Contract

## Summary

`01 Calculation Contract` 범위의 순수 계산 함수를 구현했습니다.

이번 단계는 DB, Supabase, UI를 변경하지 않고 벤치마크 비교와 위험조정 성과 계산에 필요한 산식만 고정합니다.

## Implemented Files

| 파일 | 내용 |
| --- | --- |
| `lib/utils/risk_adjusted_performance_calculator.dart` | 현금흐름 보정 수익률, 누적 수익률, 연율화 수익률, 변동성, Sharpe Ratio, MDD 계산 함수 추가 |
| `test/risk_adjusted_performance_calculator_test.dart` | 01 계획서의 계산 계약 테스트 추가 |
| `docs/features/new_feature_development/risk_adjusted_benchmark_performance/plan_parts/01_calculation_contract.md` | 변동성 계산이 샘플 표준편차 기준임을 명시 |

## Calculation Contracts

| 함수 | 계약 |
| --- | --- |
| `calculateCashFlowAdjustedDailyReturn` | 입금/출금을 외부 현금흐름으로 제외하고 일별 수익률 계산 |
| `calculateCumulativeReturn` | 일별 수익률을 복리로 연결 |
| `calculateAnnualizedReturn` | 일별 평균 수익률에 252를 곱해 연율화 |
| `calculateAnnualizedVolatility` | 일별 수익률의 샘플 표준편차를 `sqrt(252)`로 연율화 |
| `calculateSharpeRatio` | 연율화 수익률, 무위험 수익률, 연율화 변동성으로 계산 |
| `calculateMaxDrawdown` | running peak 기준 최대 낙폭과 고점/저점 위치 반환 |

## Important Decisions

- `Modified Dietz`가 아니라 계획서에 명시한 단순 일별 현금흐름 보정 방식을 구현했습니다.
- Sharpe Ratio는 기본 최소 관측치 60개를 요구합니다.
- 변동성이 0이거나 관측치가 부족하면 Sharpe Ratio는 `null`을 반환합니다.
- 전일 포트폴리오 가치가 0이면 일별 수익률은 `null`을 반환합니다.
- 변동성은 샘플 표준편차 기준으로 계산합니다.

## Test Coverage

추가 테스트:

- 입금만 있는 날 수익률 0%
- 출금만 있는 날 수익률 0%
- 시장가치 상승만 있는 날 수익률 반영
- 입금과 시장수익 동시 발생
- 출금과 시장손실 동시 발생
- 전일 가치 0 처리
- 누적 수익률 복리 계산
- 연율화 수익률 계산
- 연율화 변동성 계산
- 변동성 0인 Sharpe Ratio null 처리
- 최소 관측치 미만 Sharpe Ratio null 처리
- Sharpe Ratio 정상 계산
- running peak 기준 MDD 계산

## Verification

실행한 명령:

```bash
flutter test test/risk_adjusted_performance_calculator_test.dart
flutter analyze lib/utils/risk_adjusted_performance_calculator.dart test/risk_adjusted_performance_calculator_test.dart
```

결과:

- 테스트 통과
- 정적 분석 통과

## Out Of Scope

이번 단계에서 제외한 항목:

- `portfolio_daily_returns` 테이블 추가
- 스냅샷 기반 파생 데이터 생성
- 벤치마크 가격 테이블
- 투자성과 분석 UI 연결
- Supabase migration 또는 Edge Function 변경
