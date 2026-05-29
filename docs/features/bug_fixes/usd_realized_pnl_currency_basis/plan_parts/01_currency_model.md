# Currency Model

## Root Cause

현재 앱 모델은 USD holding의 `average_price`와 `purchaseAmount`를 원화 기준으로 다룬다.

- `HoldingItem.purchaseAmount = quantity * averagePrice`
- `HoldingItem.valuationAmount = quantity * currentPrice * exchangeRate`
- 기존 코드 주석: `USD holdings store averagePrice in KRW, while currentPrice is fetched in USD.`

반면 투자 원장 거래 금액은 source currency 기준으로 저장된다.

- USD 매도 `gross_amount = 285`
- `currency_code = USD`
- 성과 화면은 `currency_code = USD` 금액을 원화로 환산한다.

문제는 snapshot `total_purchase_amount`가 원화 기준인데 이를 USD 원가처럼 써서 발생했다.

SATL snapshot 예:

- `snapshot_date = 2026-05-26`
- `quantity = 50`
- `total_purchase_amount = 234,500`
- `234,500 / 50 = 4,690 KRW`
- 이 `4,690 KRW`를 `4,690 USD`처럼 사용해 `30 * 4,690 = 140,700 USD` 원가가 만들어졌다.

## Holding Fields

1. `holdings.average_price`
   - 기존 앱 정책 유지 및 하위 호환.
   - KRW holding: KRW 단가.
   - USD holding: KRW 단가.
   - 신규 코드에서는 직접 계산 기준으로 쓰지 않고 명시 컬럼을 우선한다.

2. `holdings.average_price_source`
   - 신규 컬럼.
   - 원통화 평균단가.
   - KRW holding: KRW 평단.
   - USD holding: USD 평단.
   - 매도 실현손익, 거래 입력 검증, 증권사 체결내역 대조에 사용한다.

3. `holdings.average_price_krw`
   - 신규 컬럼.
   - 명시적 원화 평균단가.
   - 기존 `average_price`와 같은 값을 유지하되 신규 코드에서는 이 값을 우선 사용한다.

4. `holdings.average_purchase_fx_rate`
   - 신규 컬럼.
   - 매수 평균 환율.
   - USD holding: `average_price_krw / average_price_source`.
   - KRW holding: `1`.
   - 개별 매수 당시 환율을 그대로 복사하는 값이 아니다.
   - 누적 원화 원가를 누적 원통화 원가로 나눈 가중 평균 환율이다.

5. `holdings.cost_basis_krw`
   - 신규 컬럼.
   - 총 원화 원가.
   - 원화 포트폴리오 평가손익 계산의 source of truth로 사용한다.
   - `average_price_krw = cost_basis_krw / quantity`로 재계산된다.

## Ledger Fields

1. `transaction_lines.gross_amount`
   - 거래 입력 통화 기준 금액.
   - USD 매수/매도는 USD.

2. `transaction_lines.cost_basis_delta`
   - KRW 원가 흐름.
   - USD holding도 KRW 원가 차감값을 저장한다.
   - `holdings.cost_basis_krw` 재계산용이다.

3. `transaction_lines.cost_basis_source_delta`
   - 신규 컬럼.
   - 원통화 원가 흐름.
   - KRW holding에서는 `cost_basis_delta`와 동일하다.
   - USD holding에서는 USD 원가 차감값이다.
   - `holdings.average_price_source` 재계산용이다.

4. `transaction_lines.realized_pnl`
   - `currency_code` 기준 금액.
   - USD 매도는 USD 실현손익.
   - KRW 매도는 KRW 실현손익.

5. `transaction_lines.fx_rate`
   - USD buy line에는 매수 당시 환율을 저장한다.
   - 이는 holding 평균 환율을 덮어쓰는 값이 아니라, 원장 원가 흐름 계산의 입력값이다.

## Invariants

- KRW 거래에서는 `cost_basis_delta = -(gross_amount - realized_pnl)` 관계가 유지된다.
- USD 거래에서는 위 관계가 `cost_basis_delta`에는 성립하지 않는다.
- Buy/opening line의 원가 delta는 양수다.
  - `cost_basis_source_delta = gross_amount`
  - `cost_basis_delta = gross_amount * fx_rate` for USD
- Sell line의 원가 delta는 음수다.
  - `cost_basis_source_delta = -(gross_amount - realized_pnl)`
  - `cost_basis_delta = -average_price_krw * sell_quantity` for USD
- `average_purchase_fx_rate = sum(cost_basis_delta) / sum(cost_basis_source_delta)`.
- `average_purchase_fx_rate`는 마지막 매수 환율이 아니라 누적 평균 환율이다.
