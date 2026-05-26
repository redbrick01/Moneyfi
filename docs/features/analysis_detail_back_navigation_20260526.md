# Analysis Detail Back Navigation - 2026-05-26

## Background

During macOS manual testing of the Analysis tab, the detail pages could be opened from the Analysis entry cards but did not expose a reliable way to return to the Analysis list.

Affected pages:

- Portfolio Diagnosis
- Investment Performance
- Dividend/Interest Analysis

The issue made manual testing awkward because the app had to be restarted to continue moving between analysis detail pages.

## Change

`MoneyfyPage` now shows a leading back icon button when the current route can pop.

Implementation:

- File: `lib/widgets/moneyfy_ui.dart`
- Condition: `Navigator.canPop(context)`
- Action: `Navigator.of(context).maybePop()`
- Tooltip: `뒤로`

Because the Analysis detail pages use `MoneyfyPage`, the back button is now available automatically on all three pages. Root tab pages do not show the button because they cannot pop.

## Verification

Widget test coverage was updated in `test/page_walkthrough_test.dart`.

The analysis walkthrough test now verifies this flow for each Analysis detail page:

1. Open the detail page from the Analysis tab.
2. Assert that the `뒤로` button exists.
3. Tap the `뒤로` button.
4. Assert that the Analysis list is visible again.

Commands run:

```sh
flutter test test/page_walkthrough_test.dart
flutter analyze lib/widgets/moneyfy_ui.dart lib/pages/analysis_page.dart lib/pages/portfolio_analysis_mvp_page.dart lib/pages/investment_performance_page.dart lib/pages/dividend_interest_analysis_page.dart test/page_walkthrough_test.dart
```

Both commands passed.

## Related Findings

The same manual test pass also identified that test holdings using real symbols can be inflated by automatic market refresh. That issue is documented separately in the manual analysis report.
