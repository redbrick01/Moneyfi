# Trade Calculation Flow

## Current Code Gap

현재 코드 확인 결과:

- 투자 매수/매도 라인은 `transaction_lines.fx_rate`를 채우지 않는다.
- `fx_rate`는 환전 라인에만 저장된다.
- `_createLedgerInvestmentWithLegacyMirror()`는 `holding.averagePrice`만 평균단가로 넘기고, 매수 당시 환율을 받지 않는다.
- 따라서 USD 매수 당시 환율 입력/저장/평단 갱신이 반드시 포함되어야 한다.

## USD Buy Input

- 거래 폼에서 USD holding의 `매수` 거래에는 `매수 환율` 입력 필드를 표시한다.
- 기본값은 `exchange_rates`의 최신 `USD/KRW` 또는 앱 현재 환율을 사용한다.
- 사용자는 실제 체결/환전 기준 환율로 수정할 수 있어야 한다.
- 계산 반영 USD 매수에서는 `매수 환율 > 0`을 필수로 검증한다.
- record-only USD 매수도 환율 입력을 허용한다. 단, portfolio quantity/cost state에는 반영하지 않는다.
- 기존 USD 매수 거래 수정 화면은 저장된 `transaction_lines.fx_rate`가 있으면 그 값을 기본값으로 사용한다.

## USD Buy Calculation

For a calculation-included USD buy:

- `gross_amount_source = unit_price_usd * quantity`
- `cost_basis_source_delta = gross_amount_source`
- `cost_basis_delta = gross_amount_source * trade_fx_rate`
- `realized_pnl = 0`
- buy line `fx_rate = trade_fx_rate`

Holding update:

- `new_quantity = old_quantity + buy_quantity`
- `old_source_cost = old_quantity * old_average_price_source`
- `new_source_cost = old_source_cost + gross_amount_source`
- `new_cost_basis_krw = old_cost_basis_krw + gross_amount_source * trade_fx_rate`
- `average_price_source = new_source_cost / new_quantity`
- `average_price_krw = new_cost_basis_krw / new_quantity`
- `average_purchase_fx_rate = new_cost_basis_krw / new_source_cost`
- `average_price = average_price_krw`

Important:

- `average_purchase_fx_rate` is a weighted average.
- It must not be overwritten with the latest buy's `trade_fx_rate`.

Example:

- Existing: 10 shares, source avg `$10`, KRW avg `₩14,000`, average FX `1,400`
- New buy: 10 shares at `$20`, trade FX `1,500`
- Source cost: `10 * 10 + 10 * 20 = 300 USD`
- KRW cost: `10 * 14,000 + 10 * 20 * 1,500 = 440,000 KRW`
- `average_price_source = 15 USD`
- `average_price_krw = 22,000 KRW`
- `average_purchase_fx_rate = 440,000 / 300 = 1,466.6667`

## KRW Buy Calculation

- `cost_basis_delta = gross_amount`
- `cost_basis_source_delta = gross_amount`
- `fx_rate = 1`
- `average_price_source = average_price_krw = average_price`
- `average_purchase_fx_rate = 1`

## USD Sell Calculation

Automatic sell:

- `averageCostBasisSource = holding.averagePriceSource`
- `averageCostBasisKrw = holding.averagePriceKrw`
- `realized_pnl = gross_amount_source - averageCostBasisSource * sellQuantity`
- `cost_basis_delta = -averageCostBasisKrw * sellQuantity`
- `cost_basis_source_delta = -averageCostBasisSource * sellQuantity`

Manual sell:

- User input `realized_pnl` is source-currency amount.
- KRW sell: input is KRW.
- USD sell: input is USD.
- USD manual sell must not compute `cost_basis_delta = -(gross_amount - realized_pnl)`.
- Instead, `cost_basis_delta = -average_price_krw * sellQuantity`.
- `cost_basis_source_delta = -(gross_amount - realized_pnl)`.

## Holding Recalculation

- Quantity: `sum(quantity_delta)`
- KRW cost: `sum(cost_basis_delta)`
- Source cost: `sum(cost_basis_source_delta)`
- If quantity is effectively zero:
  - `average_price_source = 0`
  - `average_price_krw = 0`
  - `average_purchase_fx_rate = 0` for USD, `1` for KRW
- Otherwise:
  - `average_price_source = source_cost / quantity`
  - `average_price_krw = cost_basis_krw / quantity`
  - `average_purchase_fx_rate = source_cost == 0 ? 0 : cost_basis_krw / source_cost`
- `average_price = average_price_krw`

When quantity is effectively zero, average fields should be zeroed only for that affected holding, never by a broad holdings reconcile.
