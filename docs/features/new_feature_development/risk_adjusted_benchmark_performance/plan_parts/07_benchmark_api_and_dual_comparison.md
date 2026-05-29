# 07 Benchmark API And Dual Comparison

## Purpose

벤치마크 비교를 두 단계로 나눕니다.

1. 사용자가 기대하는 기간 양끝 비교
2. 기존 구현 의도였던 일별 시계열 비교

둘 다 API 가격 데이터가 필요하지만, 필요한 데이터의 양과 표시 위치가 다릅니다.

## User-Facing Rule

투자성과 분석의 기본 벤치마크/초과수익률은 선택 기간의 시작값과 끝값으로 계산합니다.

```text
benchmark_period_return =
  benchmark_end_value / benchmark_start_value - 1

excess_return =
  portfolio_period_return - benchmark_period_return
```

이 값은 사용자가 `올해`, `3개월`, `1개월` 같은 기간을 선택했을 때 가장 먼저 기대하는 비교입니다.

## Advanced Rule

기존 일별 공통 날짜 비교는 버리지 않습니다. 아래 용도로 분리합니다.

- 벤치마크 일별 누적 비교
- 추적 성과 분석
- 향후 차트/상관/베타 같은 시계열 분석

```text
benchmark_daily_return =
  benchmark_value_today / benchmark_value_previous_trading_day - 1

benchmark_time_series_return =
  compound(common_daily_benchmark_returns)
```

최소 공통 관측치 20개 조건은 이 고급 시계열 비교에만 적용합니다.

## API Data Requirement

| 항목 | 필요한 API 데이터 | 데이터 부족 기준 |
| --- | --- | --- |
| 기본 벤치마크 기간 수익률 | 기간 시작 이전/당일 최신 가격, 기간 종료 이전/당일 최신 가격 | 시작값 또는 끝값 없음 |
| 기본 초과수익률 | 포트폴리오 기간 수익률 + 벤치마크 기간 수익률 | 둘 중 하나 없음 |
| 일별 벤치마크 시계열 비교 | 선택 기간 전체 일별 가격 | 공통 일별 수익률 20개 미만 |
| Sharpe Ratio | 포트폴리오 일별 수익률 | 포트폴리오 일별 수익률 60개 미만 |

## API Provider Strategy

1차 구현은 무료/키 없는 지수 가격 API를 우선 검토합니다.

후보:

- Stooq CSV: S&P 500 지수 또는 ETF 가격 조회 후보
- Yahoo Finance chart endpoint: 비공식 endpoint라 실패 fallback 필요
- KIS 해외 시세: 이미 KIS 설정이 있지만 과거 지수 일봉 지원 범위 확인 필요

구현 메모:

- Stooq CSV endpoint는 실제 확인 시 apikey/captcha 안내로 응답해 1차 provider에서 제외했습니다.
- SP500 1차 provider는 Yahoo Finance chart endpoint `^GSPC`로 연결합니다.
- Yahoo endpoint는 공식 보장 API가 아니므로 실패 fallback과 cache 사용을 필수로 둡니다.

결정 원칙:

- API key 없이 안정적으로 동작하면 우선 사용합니다.
- 무료 API가 불안정하면 Supabase Edge Function에서 provider fallback을 관리합니다.
- 앱 클라이언트가 provider URL/파싱 규칙에 강하게 묶이지 않도록 service 계층을 둡니다.

## Architecture

### Local App

추가 service:

```text
BenchmarkPriceService
```

역할:

- 선택 기간에 필요한 벤치마크 가격 범위를 요청
- 로컬 `benchmark_prices` cache 조회
- 부족한 가격을 API로 fetch
- fetch 성공 시 로컬 `benchmark_prices`에 저장
- 실패 시 기존 cache만 사용하고 UI는 데이터 부족 표시

### Supabase

후속 선택지:

1. 클라이언트가 직접 API 호출 후 로컬 cache에만 저장
2. Supabase Edge Function이 API 호출 후 remote `benchmark_prices`에 저장
3. Cron job으로 주요 벤치마크를 매일 seed

권장:

- 1차: 클라이언트 직접 fetch + 로컬 저장
- 2차: Edge Function + remote cache
- 3차: Cron seed

이유:

- 현재 앱의 투자성과 화면은 로컬 Drift 데이터를 기준으로 계산합니다.
- remote cache부터 만들면 sync/권한/seed 정책이 커져 구현 범위가 커집니다.
- SP500 기본 비교는 로컬 API fetch만으로 먼저 해결할 수 있습니다.

## Data Model Changes

기존 `benchmark_prices` 테이블을 유지합니다.

추가 컬럼은 1차 구현에서는 만들지 않습니다.

필요 시 후속으로 고려:

| 컬럼 | 목적 |
| --- | --- |
| `provider_symbol` | API별 실제 ticker 저장 |
| `fetched_at` | API fetch 시점 |
| `data_status` | complete/partial/fallback |

## Benchmark Code Mapping

초기 mapping:

| 앱 코드 | 표시명 | API 후보 symbol |
| --- | --- | --- |
| SP500 | S&P 500 | `^SPX`, `^GSPC`, `SPY`, Stooq `^spx` 후보 |
| NASDAQ100 | NASDAQ 100 | `^NDX`, `QQQ` 후보 |
| KOSPI | KOSPI | KRX/KIS 후보 |
| KOSDAQ | KOSDAQ | KRX/KIS 후보 |

SP500을 우선 구현하고, 나머지는 같은 interface로 확장합니다.

## Calculation Changes

### New API

`AppDatabase`에 기간 양끝 비교 API를 추가합니다.

```text
compareBenchmarkPeriodReturn(...)
```

입력:

- `benchmarkCode`
- `from`
- `to`
- `localUserId`

동작:

- 선택 기간 안에서 포트폴리오 기간 수익률을 계산합니다.
- 벤치마크 시작값은 `from` 이하 또는 이후 가장 가까운 허용 범위 가격을 사용합니다.
- 벤치마크 끝값은 `to` 이하 가장 가까운 가격을 사용합니다.
- 시작값/끝값이 없으면 null을 반환합니다.

### Existing API

`compareBenchmarkToPortfolioReturns(...)`는 유지합니다.

역할을 이름/문서에서 명확히 합니다.

```text
compareBenchmarkDailySeriesReturns(...)
```

기존 API는 deprecate하거나 wrapper로 유지합니다.

## UI Changes

고급 성과 섹션 표시는 다음처럼 분리합니다.

| 라벨 | 계산 방식 | 데이터 부족 문구 |
| --- | --- | --- |
| 벤치마크 기간 수익률 | 기간 양끝 비교 | 시작/끝 가격 부족 |
| 초과수익률 | 포트폴리오 기간 수익률 - 벤치마크 기간 수익률 | 포트폴리오 또는 벤치마크 기간 수익률 부족 |
| 벤치마크 일별 비교 | 공통 일별 수익률 복리 | 공통 관측치 20개 미만 |
| Sharpe Ratio | 포트폴리오 일별 수익률 | 포트폴리오 일별 수익률 60개 미만 |

사용자 설명:

- 벤치마크 기간 수익률: 선택한 기간 동안 시장 기준이 얼마나 움직였는지 보여줍니다.
- 초과수익률: 내 포트폴리오 기간 수익률이 시장 기준보다 얼마나 높거나 낮았는지 보여줍니다.
- 벤치마크 일별 비교: 같은 날짜의 일별 수익률을 맞춰 더 정교하게 비교합니다.
- Sharpe Ratio: 수익이 변동성 대비 얼마나 효율적이었는지 보는 지표입니다.

## Failure Handling

- API 실패는 투자성과 화면 전체 실패로 전파하지 않습니다.
- API 실패 시 기존 cache로 계산을 시도합니다.
- cache도 없으면 `데이터 부족`과 짧은 이유를 표시합니다.
- API fetch 중에는 기존 금액 성과 카드는 즉시 표시되어야 합니다.

## Tests

### Unit

| 테스트 | 목적 |
| --- | --- |
| `benchmark_period_return_uses_boundary_prices` | 시작/끝 가격으로 기간 수익률 계산 |
| `benchmark_period_return_uses_nearest_previous_end_price` | 휴장일 끝 날짜 fallback |
| `benchmark_period_return_missing_start_is_insufficient` | 시작값 없으면 데이터 부족 |
| `benchmark_period_return_missing_end_is_insufficient` | 끝값 없으면 데이터 부족 |
| `daily_series_comparison_still_requires_common_observations` | 기존 일별 비교 조건 유지 |

### Service

| 테스트 | 목적 |
| --- | --- |
| `benchmark_service_fetches_missing_sp500_prices` | cache 누락 시 API 호출 |
| `benchmark_service_persists_fetched_prices` | fetch 성공 시 `benchmark_prices` 저장 |
| `benchmark_service_uses_cache_when_api_fails` | API 실패 시 cache fallback |
| `benchmark_service_does_not_mutate_holdings` | API fetch가 원본 보유자산 불변 |

### Widget

| 테스트 | 목적 |
| --- | --- |
| `benchmark_period_return_displays_with_two_prices` | 양끝 가격만 있어도 벤치마크 표시 |
| `benchmark_daily_series_can_be_insufficient_while_period_return_displays` | 일별 비교 부족이어도 기본 비교 표시 |
| `sharpe_explains_portfolio_daily_return_requirement` | Sharpe 데이터 부족 이유 표시 |

## Implementation Sequence

1. 기간 양끝 비교 계산 API와 테스트 추가
2. UI에서 벤치마크/초과수익률을 기간 양끝 방식으로 전환
3. 일별 공통 날짜 비교 라벨을 고급 시계열 비교로 분리
4. `BenchmarkPriceService` 추가
5. SP500 API provider 1개 연결
6. API 실패/cache fallback 테스트 추가
7. 필요 시 Supabase Edge Function/remote cache로 확장

## Release Gate

- 양끝 가격 2개만 있어도 벤치마크 기간 수익률이 표시되어야 합니다.
- 일별 공통 관측치가 20개 미만이어도 기본 벤치마크/초과수익률은 막히면 안 됩니다.
- Sharpe Ratio는 포트폴리오 일별 수익률 60개 미만이면 계속 데이터 부족이어야 합니다.
- API 실패가 기존 투자성과 금액 카드와 포트폴리오 원본 데이터를 깨면 안 됩니다.
- API fetch 전후 `assets`, `holdings`, `transaction_events`, `transaction_lines`는 불변이어야 합니다.
