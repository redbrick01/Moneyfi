# Implementation Report 04 - Trade Calculation Flow

## Scope

Implemented the USD/KRW cost-basis trade calculation flow from `plan_parts/04_trade_calculation_flow.md`.

This step updates new trade creation, edit replacement, record-only lines, and holding recalculation so source-currency and KRW cost basis stay separate.

## Implemented

- USD buy input support:
  - Added `매수 환율` field for USD buy transactions.
  - Defaults to the current USD/KRW rate already loaded into holdings when available.
  - Stores the buy line `fx_rate`.
  - Calculation-included USD buys require `tradeFxRate > 0`.
  - Record-only USD buys can still carry `fx_rate` without changing portfolio state.
- USD buy calculation:
  - `gross_amount` remains source-currency amount.
  - `cost_basis_source_delta = gross_amount`.
  - `cost_basis_delta = gross_amount * tradeFxRate`.
  - Holding weighted averages are recomputed from ledger sums:
    - `average_price_source = sourceCost / quantity`
    - `average_price_krw = krwCost / quantity`
    - `average_purchase_fx_rate = krwCost / sourceCost`
    - compatibility `average_price = average_price_krw`
- KRW buy calculation:
  - `cost_basis_delta = gross_amount`
  - `cost_basis_source_delta = gross_amount`
  - buy line `fx_rate = 1`, because KRW source currency and reporting currency are the same.
- USD sell calculation:
  - Auto sell uses `holding.averagePriceSource` for source-currency realized PnL.
  - Auto/manual sell use KRW average cost for `cost_basis_delta`.
  - Manual USD sell stores source-currency `realized_pnl`; source cost delta follows `-(gross_amount - realized_pnl)`.
- Opening ledger line:
  - Seeded USD holdings now create opening rows with source-currency unit price and source cost basis.
  - This prevents the first post-seed transaction from wiping source average back to zero.
- Transaction edit replacement:
  - Preserves `fxRate` through ledger-backed edit replacement.
- Transaction list:
  - Fetches `transaction_lines.fx_rate` into `TransactionItem`.

## Verification Cases

Added regression coverage in `test/transaction_flow_test.dart`:

- USD buy stores trade FX and recomputes weighted average FX.
- USD automatic sell uses source average for realized PnL.
- Calculation-included USD buy requires trade FX.
- USD manual sell source-currency behavior is covered by the 06 verification step.
- Existing KRW and mixed-currency transaction tests continue to pass.

## Verification

- `flutter analyze`
- `flutter test test/transaction_flow_test.dart`
- `flutter test test/widget_test.dart`
- `flutter test test/transaction_flow_test.dart test/widget_test.dart`

All verification commands passed.

## Remaining Work

- Correct historical USD sell rows using the seeded source averages.
- Deploy the schema, seed, sync-preserve, and corrective migrations in a controlled order.
