# 03 Benchmark Data

## Purpose

포트폴리오 수익률을 같은 기간의 시장 기준과 비교합니다.

## Recommended Table

```sql
create table benchmark_prices (
  id integer primary key,
  benchmark_code text not null,
  price_date text not null,
  close_price real not null,
  adjusted_close_price real,
  currency_code text not null default 'KRW',
  fx_rate_to_krw real,
  source text,
  created_at text not null,
  updated_at text not null,
  unique(benchmark_code, price_date)
);
```

필드 원칙:

- 지수 데이터는 `close_price`만으로 충분할 수 있습니다.
- ETF나 사용자 선택 벤치마크로 확장할 경우 배당/분할 보정이 필요하므로 `adjusted_close_price`를 남겨둡니다.
- 수익률 계산은 `adjusted_close_price`가 있으면 우선 사용하고, 없으면 `close_price`를 사용합니다.

## Initial Benchmarks

| 코드 | 용도 |
| --- | --- |
| KOSPI | 국내 대형주 비교 |
| KOSDAQ | 국내 성장주 비교 |
| SP500 | 미국 대표지수 비교 |
| NASDAQ100 | 미국 성장주 비교 |

## Return Rule

```text
benchmark_daily_return =
  benchmark_effective_close_today / benchmark_effective_close_yesterday - 1
```

해외 벤치마크를 KRW 기준으로 비교할 때:

```text
benchmark_value_krw =
  close_price * fx_rate_to_krw
```

## Comparison Rule

포트폴리오와 벤치마크가 모두 있는 공통 날짜만 비교합니다.

```text
excess_return =
  portfolio_cumulative_return - benchmark_cumulative_return
```

최소 관측치:

| 지표 | 최소 공통 관측치 |
| --- | --- |
| 벤치마크 비교 | 20거래일 |
| 변동성 | 20거래일 |
| Sharpe Ratio | 60거래일 |
| Max Drawdown | 2개 이상 포트폴리오 가치 |

최소 관측치보다 적으면 값을 계산하지 않고 `데이터 부족`으로 표시합니다.

## Data Source Strategy

1차 구현:

- fixture 또는 수동 seed 데이터
- 데이터가 없으면 `데이터 부족`

후속 구현:

- 외부 API 자동 업데이트
- 실패 시 마지막 정상 데이터 유지
- 데이터 출처와 갱신 시점 기록

## Required Tests

| 테스트 | 목적 |
| --- | --- |
| `benchmark_comparison_uses_common_dates` | 공통 날짜만 비교 |
| `benchmark_missing_data_is_insufficient` | 누락 시 데이터 부족 표시 |
| `foreign_benchmark_can_convert_to_krw` | 해외 벤치마크 KRW 변환 |
| `benchmark_uses_adjusted_close_when_available` | 보정 종가 우선 사용 |
| `benchmark_requires_minimum_common_observations` | 최소 관측치 미만이면 데이터 부족 |
