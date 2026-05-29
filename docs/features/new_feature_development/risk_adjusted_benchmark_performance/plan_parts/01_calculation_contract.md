# 01 Calculation Contract

## Purpose

벤치마크 비교와 위험조정 성과의 계산식을 먼저 고정합니다. UI나 DB보다 계산 계약을 먼저 테스트로 묶어야 이후 화면과 Supabase 동기화가 흔들리지 않습니다.

## Daily Portfolio Value

```text
portfolio_value_krw =
  cash_value_krw
  + holding_market_value_krw
```

원칙:

- 일자 종료 시점 기준입니다.
- KRW 기준을 기본으로 합니다.
- USD 자산은 일자별 환율이 있으면 해당 환율을 쓰고, 없으면 가장 가까운 이전 환율로 fallback합니다.

## Cash-Flow Adjusted Daily Return

```text
daily_return =
  (ending_value - beginning_value - external_cash_flow) / beginning_value
```

| 항목 | 의미 |
| --- | --- |
| `beginning_value` | 전일 종료 포트폴리오 가치 |
| `ending_value` | 당일 종료 포트폴리오 가치 |
| `external_cash_flow` | 외부 입금은 양수, 외부 출금은 음수 |

중요:

- 입금은 수익이 아닙니다.
- 출금은 손실이 아닙니다.
- 매수/매도 결제와 내부 이동은 외부 현금흐름이 아닙니다.

MVP 한계:

- 이 방식은 `Modified Dietz`가 아니라 단순 일별 현금흐름 보정 방식입니다.
- 외부 입금/출금이 하루 중 언제 발생했는지는 반영하지 않습니다.
- 일별 스냅샷만 있는 현재 구조에서는 이 방식을 1차 기준으로 사용하고, 향후 거래 시각 기반 수익률이 필요하면 별도 Phase로 분리합니다.

## Cumulative Return

```text
cumulative_return =
  product(1 + daily_return) - 1
```

일별 수익률을 복리로 연결합니다.

## Volatility

```text
annualized_volatility =
  stddev(daily_returns) * sqrt(252)
```

1차 구현은 일별 기준이며, `stddev`는 샘플 표준편차를 사용합니다. 월별 기준으로 바꾸는 경우 `sqrt(12)`를 사용해야 하므로 별도 옵션으로 분리합니다.

## Sharpe Ratio

Sharpe Ratio에는 연율화 수익률과 연율화 변동성을 사용합니다.

MVP의 연율화 수익률:

```text
annualized_portfolio_return =
  mean(daily_returns) * 252
```

장기적으로는 누적 수익률 기반 CAGR 방식도 검토할 수 있지만, 1차 구현은 일별 평균 수익률 기반으로 고정합니다.

```text
sharpe_ratio =
  (annualized_portfolio_return - risk_free_rate) / annualized_volatility
```

MVP 기본값:

- 무위험 수익률은 `0%`
- 관측치가 60거래일 미만이면 `데이터 부족`
- 변동성이 0이면 null

## Max Drawdown

```text
drawdown_today =
  portfolio_value_today / running_peak_value - 1

max_drawdown =
  min(drawdown_today)
```

고점 대비 가장 깊게 하락한 비율입니다.

## Required Tests

| 테스트 | 기대 |
| --- | --- |
| 입금만 있는 날 | 수익률 0% |
| 출금만 있는 날 | 수익률 0% |
| 시장가치만 상승 | 수익률 양수 |
| 전일 가치 0 | null 또는 데이터 부족 |
| 입금과 시장수익 동시 발생 | 외부 현금흐름 제외 후 시장수익만 반영 |
| 출금과 시장손실 동시 발생 | 외부 현금흐름 제외 후 시장손실만 반영 |
| +10%, -10% | 누적 수익률 -1% |
| 일별 평균수익률 0.1% | 연율화 수익률 25.2% |
| 변동성 0 | Sharpe null |
| 100, 120, 90, 130 | MDD -25% |
