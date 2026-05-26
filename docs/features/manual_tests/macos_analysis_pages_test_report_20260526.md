# macOS Analysis Pages Test Report - 2026-05-26

## Scope

- App: `/Users/yw0410/Desktop/Project/MONEYFY/build/macos/Build/Products/Release/moneyfy.app`
- Account: Supabase test account
- Timezone: Asia/Seoul
- Test time: 2026-05-26 10:57 KST
- Pages tested:
  - Analysis tab entry list
  - Portfolio Diagnosis
  - Investment Performance
  - Dividend/Interest Analysis

## Baseline Data

The account contains three visible assets and the manual transaction set created during the transaction flow test:

- Buy: Samsung Electronics, KRW 100,000, quantity 1
- Sell: Samsung Electronics, KRW 120,000, quantity 1
- Deposit: KRW 100,000
- Withdrawal: KRW 50,000
- Transfer: KRW 200,000 from stock cash to ETF/fund cash
- FX exchange: KRW 1,300 out, USD 1 in
- No dividend or interest transactions

Market prices refreshed while testing, so valuation and unrealized profit changed slightly between page visits. Transaction-derived values are stable.

## Analysis Tab

Result: Pass

Observed entries:

- Portfolio Diagnosis
- Investment Performance
- Dividend/Interest Analysis

The tab exposed all expected analysis pages. News cards loaded above the analysis entries.

## Portfolio Diagnosis

Result: Pass with UX issue

Observed values:

- Total value: KRW 121,619,174
- Return rate: +2888.0%
- Target drift: not configured
- Max drawdown: insufficient data
- Top asset share: 97.1%
- Top 3 share: 100.0%
- HHI: 9441, high concentration
- Performance contribution:
  - Test coin: +KRW 116,841,900, contribution 99.2%
  - Test stock: +KRW 818,200, contribution 0.7%
  - Test ETF/fund: -KRW 111,135, contribution 0.1%

Calculation checks:

- The risk state is reasonable because the test coin asset dominates the portfolio at about 97.1%.
- HHI around 9441 matches a portfolio where one asset accounts for nearly all value.
- Target drift correctly shows not configured because no allocation targets are set.
- Max drawdown correctly shows insufficient data because at least two snapshots are needed.
- Performance contribution ordering follows absolute profit impact.

UX issue:

- After entering this detail page, visible/clickable back navigation and common keyboard back shortcuts did not return to the Analysis tab in this macOS build. I had to restart the app to continue testing the next analysis page.

## Investment Performance

Result: Pass

Observed summary:

- Selected range: year to date
- Pure investment performance: +KRW 117,568,965
- Realized: +KRW 20,000
- Unrealized: +KRW 117,548,965
- Dividend/interest: KRW 0
- Cost: KRW 0

Observed performance breakdown:

- Realized profit: +KRW 20,000
- Unrealized profit: +KRW 117,548,965
- Dividend/interest: KRW 0
- Fee: KRW 0
- Tax: KRW 0
- Pure realized performance: +KRW 20,000
- Pure investment performance: +KRW 117,568,965
- Buy principal: KRW 100,000
- Sell proceeds: KRW 120,000

Calculation checks:

- Realized profit is correct: KRW 120,000 sell proceeds - KRW 100,000 cost basis = +KRW 20,000.
- Pure realized performance is correct: realized profit + income - fee - tax = 20,000 + 0 - 0 - 0.
- Pure investment performance is correct: pure realized performance + unrealized profit = 20,000 + 117,548,965 = 117,568,965.
- Buy principal and sell proceeds match the manual buy/sell transactions.

Observed excluded cash flows:

- External deposit: KRW 100,000
- External withdrawal: -KRW 50,000
- External net cash flow: +KRW 50,000
- Trade settlement cash flow: +KRW 20,000
- Internal movement: KRW 402,809

Calculation checks:

- External net cash flow is correct: 100,000 - 50,000 = 50,000.
- Trade settlement cash flow is correct: -100,000 buy settlement + 120,000 sell settlement = +20,000.
- Internal movement is correct with current FX rate:
  - Transfer out/in absolute movement: 200,000 + 200,000 = 400,000
  - FX out: 1,300
  - FX in: USD 1 * displayed USD/KRW 1,509.20 ~= 1,509
  - Total ~= 402,809

Observed rankings:

- Monthly realized performance for 2026-05: +KRW 20,000
- Realized profit ranking: Samsung Electronics, +KRW 20,000

These match the single sell transaction made during manual testing.

## Dividend/Interest Analysis

Result: Pass

Observed values:

- Total dividend/interest: KRW 0
- Dividend: KRW 0
- Interest: KRW 0
- Monthly average: KRW 0
- Record count: 0
- Monthly, yearly, source, and recent income sections show empty-state text.

Calculation check:

- This is correct because the test transaction set contains no dividend or interest lines.

## Notes

- Supabase CLI schema/value re-querying hit a temporary login/circuit-breaker error during this pass. The screen checks above were therefore validated against the app's visible state and the calculation formulas in `investment_performance_page.dart` and `portfolio_analysis_mvp_page.dart`.
- Market-derived values may move after refresh. Transaction-derived values such as realized profit, deposits, withdrawals, buy/sell amounts, and dividend/interest totals are stable.

## Overall Result

The analysis pages calculate correctly for the seeded test account and the manual buy/sell/deposit/withdrawal/transfer/exchange scenario.

Follow-up fix recommended:

- Restore or expose reliable back navigation from analysis detail pages on macOS.
