# Existing USD Seed Data

## Policy

기존 USD holding은 현재 DB에 원화 평균단가만 신뢰 가능한 값으로 남아 있다. 원통화 평균단가는 사용자가 제공한 증권사/원장 기준 값을 사용한다.

기존 데이터 백필에서 현재 환율이나 최신 스냅샷 환율로 원통화 평단을 추정하지 않는다.

## Backfill Formula

- `average_price_krw = existing average_price`
- `average_price_source = user-provided source average`
- `average_purchase_fx_rate = average_price_krw / average_price_source`
- `cost_basis_krw = quantity * average_price_krw`

## Seed Values

| Asset | Symbol | Name | Holding ID | Qty | KRW Avg | Source Avg | Avg Buy FX |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 주식 | SATL | 새틀로직 | 8 | 50 | 4,690 | 3.2925 | 1,424.449506 |
| 주식 | IONQ | 아이온큐 | 3 | 16 | 39,680 | 28.3813 | 1,398.103681 |
| 주식 | TSLA | 테슬라 | 1 | 2 | 317,648 | 225.9928 | 1,405.566903 |
| 주식 | PLTR | 팔란티어 | 4 | 6 | 104,149 | 74.4933 | 1,398.098889 |
| 주식 | NVDA | 엔비디아 | 5 | 7 | 143,943.642857 | 133.1379 | 1,081.162035 |
| + | TSLA | 테슬라 | 21 | 66 | 286,663 | 259.5674 | 1,104.387531 |

## Matching Policy

- Match by current remote `holding.id` first for this corrective migration.
- Also verify `asset.title`, `symbol`, `name`, `currency_code = 'USD'`, and `quantity` before update.
- Do not symbol-match TSLA globally because `주식/TSLA` and `+/TSLA` have different source averages.
- If any seed row does not match exactly, skip that row and report it instead of guessing.

## Missing Seed Policy

- Seed가 없는 USD holding은 `average_price_source = 0`, `average_purchase_fx_rate = 0`으로 둔다.
- Seed가 없는 USD holding은 자동 실현손익 계산을 금지한다.
- 사용자가 직접 실현손익을 입력할 수 있는 경로를 유지한다.
