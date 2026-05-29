# Stage 07 P0 Visual Compliance Report

작성일: 2026-05-29

## Scope

Stage 06 screenshot artifact를 기준으로 P0 화면의 실제 visual compliance gap을 수정했다.

대상:

- `test/design_md_screenshot_harness_test.dart`
- `lib/ui_scaffold/app_page_scaffold.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*.png`

## Findings

### Harness Font Fidelity

초기 screenshot artifact에서 한글과 Material icon이 네모 glyph로 렌더링되어 visual audit 신뢰도가 낮았다.

수정:

- screenshot harness에 macOS Korean system font를 `.SF Pro Text`, `.SF Pro Display` family로 로드했다.
- Material icon font를 `MaterialIcons` family로 로드했다.

결과:

- `app_shell_data_390dp_ts1_0.png` 등 P0 artifact에서 한글과 icon이 정상 렌더링된다.

### AppPageScaffold Background

`PortfolioDashboardPage`, `TransactionsPage` 등 non-form `AppPageScaffold` 화면을 standalone route로 capture할 때 검은 fallback background가 노출됐다.

수정:

- non-form `AppPageScaffold`도 `Scaffold`로 감싸고 `Theme.of(context).scaffoldBackgroundColor`를 명시했다.

결과:

- `transactions_data_390dp_ts1_0.png`, `transactions_overflow_risk_360dp_ts1_3.png`가 white app background 위에 렌더링된다.
- pushed/detail route의 background fallback risk가 줄었다.

### Transaction Form Search Button

`transaction_form_keyboard_risk_360dp_ts1_3.png`에서 새 종목 검색 icon button이 black filled treatment로 보여 secondary tool action치고 너무 강했다.

수정:

- search icon button background를 `neutralSurfaceOverlay`로 변경했다.
- foreground는 `neutralText`, outline은 `neutralOutline`으로 조정했다.

결과:

- 검색 도구 버튼이 primary CTA보다 낮은 hierarchy로 보인다.

## Artifacts

- `screenshots/after/app_shell_data_390dp_ts1_0.png`
- `screenshots/after/dashboard_data_390dp_ts1_0.png`
- `screenshots/after/transactions_data_390dp_ts1_0.png`
- `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png`
- `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png`
- `screenshots/after/asset_detail_data_390dp_ts1_0.png`

## Verification

```bash
flutter analyze lib/ui_scaffold/app_page_scaffold.dart lib/pages/forms/transaction_form_page.dart test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

## Result

- `flutter analyze lib/ui_scaffold/app_page_scaffold.dart lib/pages/forms/transaction_form_page.dart test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, P0/P1 screenshot artifacts regenerated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 204 tests.

판정:

- P0 screenshot harness fidelity: pass.
- P0 scaffold background fallback: fixed.
- P0 transaction form search button hierarchy: fixed.
- P0 360dp + text scale 1.3 capture: pass.
- Loaded rich-data P0 screenshot: pending.

## Remaining Work

- DB-backed rich data seed를 넣은 P0 data-state screenshot.
- 430dp P0 screenshot 후보 추가.
- Asset/holding/cash detail의 loaded state screenshot.
- P0 screenshot golden diff 자동화.
