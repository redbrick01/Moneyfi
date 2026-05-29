# 08 Yahoo IRX Risk-Free Rate

## Purpose

Sharpe Ratio 계산에 무위험수익률을 반영합니다.

1차 구현은 현재 이미 붙인 Yahoo Finance chart endpoint를 재사용해 `^IRX`를 가져옵니다.

`^IRX`는 미국 13-week Treasury Bill yield proxy입니다. KRW 포트폴리오의 완전한 원화 무위험수익률은 아니지만, 별도 ECOS API 키 없이 빠르게 현실적인 기준금리를 반영할 수 있습니다.

## Scope

포함:

- Yahoo `^IRX` 금리 데이터 fetch
- 로컬 cache 저장
- Sharpe Ratio 계산에 연율 무위험수익률 반영
- UI에 기준금리 출처와 fallback 상태 표시

제외:

- 한국은행 ECOS CD 91일 연동
- 통화별 무위험수익률 자동 선택
- Supabase remote risk-free rate sync
- 금리 곡선 전체 관리

## Data Source

API:

```text
Yahoo Finance chart endpoint
symbol = ^IRX
```

의미:

```text
13-week Treasury Bill yield
```

주의:

- Yahoo endpoint는 공식 보장 API가 아닙니다.
- 응답 실패 시 기존 cache를 사용합니다.
- cache도 없으면 기존처럼 무위험수익률 0%로 fallback합니다.
- UI에는 “미국 13주 T-Bill 기준”이라고 표시해야 합니다.

## Data Model

1차 구현에서는 별도 DB table을 추가하지 않고 `benchmark_prices`를 재사용합니다.

저장 규칙:

| 필드 | 값 |
| --- | --- |
| `benchmark_code` | `US_13W_TBILL` |
| `price_date` | 금리 기준일 |
| `close_price` | 연율 금리 값 |
| `currency_code` | `PERCENT` |
| `source` | `yahoo:^IRX` |

Yahoo `^IRX` 값이 `5.25`라면 `5.25%` 연율로 해석합니다.

## Calculation Rule

현재 Sharpe Ratio는 다음 구조입니다.

```text
Sharpe = (annualized_return - risk_free_rate) / annualized_volatility
```

변경 후:

```text
risk_free_rate =
  latest available ^IRX close / 100
```

예:

```text
^IRX close = 5.25
risk_free_rate = 0.0525
```

기간 중 금리가 여러 개 있으면 1차 구현에서는 선택 기간의 종료일 이하 최신 금리를 사용합니다.

후속 개선:

- 기간 평균 무위험수익률
- 일별 초과수익률 기반 Sharpe
- KRW 포트폴리오에는 ECOS CD 91일 우선 적용

## Service Changes

`BenchmarkPriceService`를 확장합니다.

추가 API:

```text
ensureRiskFreeRates(from, to)
fetchLatestRiskFreeRate(to)
```

동작:

1. 로컬 `benchmark_prices`에서 `US_13W_TBILL` cache를 조회합니다.
2. 기간 종료일 이하 최신 금리가 있으면 사용합니다.
3. 없으면 Yahoo `^IRX`를 fetch합니다.
4. fetch 성공 시 `benchmark_prices`에 저장합니다.
5. fetch 실패 시 `null` 반환합니다.

## UI Changes

Sharpe Ratio 설명을 보강합니다.

기존:

```text
변동성 대비 성과를 보는 지표입니다.
```

변경:

```text
미국 13주 T-Bill 금리를 무위험수익률 기준으로 반영한 변동성 대비 성과입니다.
```

fallback 문구:

```text
무위험수익률 데이터가 없으면 0% 기준으로 계산합니다.
```

표시 옵션:

```text
무위험수익률 5.25% (^IRX)
```

## Safety Notes

- `benchmark_prices`만 갱신합니다.
- `assets`, `holdings`, `transaction_events`, `transaction_lines`는 변경하지 않습니다.
- Yahoo API 실패가 투자성과 화면 전체 실패로 전파되면 안 됩니다.
- 무위험수익률이 없더라도 Sharpe Ratio 계산은 기존 0% 기준 fallback으로 유지합니다.

## Tests

### Unit/Service

| 테스트 | 목적 |
| --- | --- |
| `risk_free_rate_fetches_irx_from_yahoo` | `^IRX` chart 응답을 연율 금리로 저장 |
| `risk_free_rate_uses_latest_on_or_before_end_date` | 종료일 이하 최신 금리 선택 |
| `risk_free_rate_returns_null_when_api_and_cache_missing` | API/cache 모두 없으면 null |
| `risk_free_rate_does_not_mutate_portfolio_sources` | 원본 포트폴리오 테이블 불변 |

### Calculation

| 테스트 | 목적 |
| --- | --- |
| `sharpe_ratio_subtracts_risk_free_rate` | Sharpe 계산에 연율 무위험수익률 반영 |
| `sharpe_ratio_falls_back_to_zero_when_risk_free_missing` | 금리 없으면 기존 계산 유지 |

### Widget

| 테스트 | 목적 |
| --- | --- |
| `investment_performance_shows_risk_free_rate_source` | UI에 기준금리 출처 표시 |
| `investment_performance_explains_zero_risk_free_fallback` | fallback 설명 표시 |

## Implementation Sequence

1. `US_13W_TBILL` 상수와 `^IRX` provider mapping 추가
2. `BenchmarkPriceService`에 risk-free fetch/cache API 추가
3. `AppDatabase`에 종료일 이하 최신 금리 조회 API 추가
4. `_loadAdvancedPerformanceReport`에서 금리 fetch 후 Sharpe에 전달
5. UI에 무위험수익률 값/출처/fallback 설명 추가
6. 테스트 추가
7. 보고서 문서화

## Release Gate

- `^IRX` 값이 있으면 Sharpe Ratio가 기존 0% 기준과 다르게 계산되어야 합니다.
- `^IRX` API가 실패해도 화면 전체가 실패하면 안 됩니다.
- 금리 기준이 USD proxy임을 UI/문서에 명시해야 합니다.
- KRW 정밀 기준금리는 후속 ECOS CD 91일 작업으로 남깁니다.
