# Investment Review Hub Implementation Report

Date: 2026-05-31
Branch: `codex/investment-review-hub`
Worktree: `/Users/yw0410/Desktop/Project/MONEYFY/.worktrees/investment-review-hub`

## Summary

Implemented a local-first Investment Review Hub for MONEYFY. The feature adds:

- A dedicated `투자 회고` page with today, weekly, and monthly review periods.
- A daily review card on the portfolio dashboard.
- A new `투자 회고` entry point on the Analysis page, clearly separated from the existing portfolio diagnosis flow.
- Local deterministic review generation from Drift-backed ledger and portfolio performance data.
- A safe AI coach payload builder with AI disabled by default and no remote endpoint call in this first implementation.

## Scope Delivered

- Added investment review domain models and period resolution under `lib/services/investment_review/`.
- Added local snapshot aggregation that summarizes:
  - portfolio value
  - cost basis
  - unrealized P/L
  - realized P/L
  - income
  - return rate
  - buy, sell, income, and cash-flow activity counts
- Added deterministic Korean narrative copy with a low-data state.
- Added compact AI payload construction that avoids sending raw transaction rows.
- Added `InvestmentReviewPage` with segmented period selection.
- Added `InvestmentReviewHomeCard` to the dashboard.
- Added an Analysis page entry card using the current branch's existing `Navigator.push` navigation style.

## Review Fixes

- Investment review performance now aggregates ledger records by currency and converts USD amounts to KRW using the latest cached USD/KRW rate before formatting.
- Weekly and monthly review ranges now end at the review generation date instead of including future dates in the current week or month.

## Plan Adjustment

The written plan mentioned adding a `go_router` route. This clean worktree did not contain the navigation files from the parent workspace's unrelated dirty work, and the current app structure uses direct `Navigator.push` entries in the relevant pages.

To keep the feature aligned with the actual branch state, the Analysis entry and dashboard action now open `InvestmentReviewPage` through `MaterialPageRoute`.

## Verification

Fresh verification was run from the worktree on 2026-05-31.

| Command | Result |
| --- | --- |
| `flutter test test/investment_review_periods_test.dart test/investment_review_narrative_test.dart test/investment_review_snapshot_builder_test.dart test/investment_review_ai_coach_test.dart` | Passed |
| `flutter test test/page_walkthrough_test.dart --plain-name "stage 2: analysis entry cards open their child pages"` | Passed |
| `flutter test test/widget_test.dart --plain-name "investment review page"` | Passed, 2 tests |
| `flutter test test/widget_test.dart --plain-name "investment review home card shows headline and action"` | Passed |
| `flutter test test/widget_test.dart --plain-name "portfolio dashboard hides stale investment review while refreshing"` | Passed |
| `flutter analyze` | Passed, no issues found |

## Known Notes

- Full `test/widget_test.dart` and full `test/page_walkthrough_test.dart` runs have pre-existing local setup failures in this workspace related to app startup configuration/assets and old smoke assertions. The investment review targeted tests pass.
- AI coaching is intentionally represented as a safe payload/stub only. No remote AI endpoint is called yet.
- The parent workspace has unrelated dirty changes. This implementation was isolated in the `.worktrees/investment-review-hub` worktree.
