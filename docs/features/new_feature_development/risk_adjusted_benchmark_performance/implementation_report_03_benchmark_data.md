# Implementation Report 03. Benchmark Data

## Summary

`03 Benchmark Data` 범위의 로컬 벤치마크 가격 테이블과 포트폴리오 대비 벤치마크 비교 API를 구현했습니다.

이번 단계는 외부 API 연동이나 UI 연결 없이, 수동 seed/fixture 데이터로 벤치마크 비교 계산 계약을 고정합니다.

## Implemented Files

| 파일 | 내용 |
| --- | --- |
| `lib/db/app_database_tables.dart` | `BenchmarkPrices` Drift 테이블 추가 |
| `lib/db/app_database.dart` | schema version 36, benchmark table ensure, 저장/조회/비교 API 추가 |
| `lib/db/app_database_records.dart` | `BenchmarkComparisonResult` record 추가 |
| `lib/db/app_database.g.dart` | Drift generated schema 갱신 |
| `test/benchmark_data_test.dart` | 벤치마크 가격, 공통 날짜 비교, 보정 종가, 해외 벤치마크 KRW 환산 테스트 추가 |

## Added API

| API | 역할 |
| --- | --- |
| `saveBenchmarkPrice(...)` | 벤치마크 가격 row 수동 저장/upsert |
| `fetchBenchmarkPrices({benchmarkCode, from, to})` | 벤치마크 가격 조회 |
| `compareBenchmarkToPortfolioReturns(...)` | `portfolio_daily_returns`와 벤치마크의 공통 날짜 누적 수익률 비교 |

## Table Contract

`benchmark_prices` 필드:

| 필드 | 의미 |
| --- | --- |
| `benchmark_code` | KOSPI, KOSDAQ, SP500, NASDAQ100 등 비교 기준 코드 |
| `price_date` | 가격 기준일 |
| `close_price` | 종가 |
| `adjusted_close_price` | 배당/분할 보정 종가. 있으면 우선 사용 |
| `currency_code` | 가격 원통화. 기본 KRW |
| `fx_rate_to_krw` | 해외 벤치마크 KRW 비교용 환율 |
| `source` | fixture, manual, API 등 데이터 출처 |

## Calculation Behavior

- 벤치마크 일별 수익률은 `effective_close_today / effective_close_yesterday - 1`로 계산합니다.
- `adjusted_close_price`가 0보다 크면 `close_price`보다 우선 사용합니다.
- 해외 벤치마크는 `effective_close * fx_rate_to_krw`로 KRW 기준 비교값을 만듭니다.
- KRW가 아닌 벤치마크에 환율이 없으면 해당 벤치마크 날짜는 비교에서 제외합니다.
- 포트폴리오와 벤치마크가 모두 일별 수익률을 가진 공통 날짜만 비교합니다.
- 기본 최소 공통 관측치는 20개입니다.

## Test Coverage

추가 테스트:

- `benchmark_prices` 테이블 생성 확인
- 포트폴리오와 벤치마크의 공통 날짜만 비교
- 공통 관측치 20개 미만이면 데이터 부족 처리
- `adjusted_close_price` 우선 사용
- USD 벤치마크를 KRW 기준으로 환산
- 벤치마크 데이터가 없으면 데이터 부족 처리

## Verification

실행한 명령:

```bash
flutter test test/benchmark_data_test.dart
flutter analyze lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database_records.dart test/benchmark_data_test.dart
flutter test test/portfolio_daily_returns_test.dart
flutter test test/risk_adjusted_performance_calculator_test.dart
flutter test test/transaction_flow_test.dart
git diff --check
```

결과:

- 벤치마크 데이터 테스트 통과
- 01 계산 계약 테스트 통과
- 02 파생 수익률 테스트 통과
- 기존 거래 흐름 회귀 테스트 통과
- 관련 정적 분석 통과
- whitespace check 통과

## Out Of Scope

이번 단계에서 제외한 항목:

- 외부 벤치마크 API 자동 수집
- 벤치마크 seed 데이터 번들링
- 투자성과 분석 UI 연결
- Sharpe/변동성/MDD UI 표시
- Supabase migration 또는 Edge Function 변경
