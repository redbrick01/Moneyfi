# Implementation Report 04: UI Integration

## Scope

The investment performance page shows advanced metrics only when enough derived data is available. Existing basic performance cards remain available if advanced metrics are unavailable.

## UI Contract

- Show cash-flow adjusted return separately from money-based profit and loss.
- Show benchmark return and excess return when benchmark rows exist.
- Show volatility, Sharpe Ratio, and max drawdown with 데이터 부족 states.
- Avoid investment advice language; copy remains factual and diagnostic.

## Safety

Advanced metric loading must not make the existing investment performance page fail as a whole.
