# Design-MD Full Compliance Audit Matrix

작성일: 2026-05-29

## 목적

MONEYFY 모바일 앱이 `docs/design_system.md`의 Coinbase design-md를 실제 화면 단위까지 준수하는지 점검하기 위한 기준 matrix다.

이 문서는 00단계 산출물이며, 이후 단계는 이 matrix의 `result`, `screenshotPath`, `nextAction`을 갱신한다.

## Matrix Schema

| 필드 | 설명 |
| --- | --- |
| `screen` | 화면/컴포넌트/asset 이름 |
| `file` | 대표 파일 또는 파일 glob |
| `route/state` | 탭, route, sheet/dialog, state 진입 조건 |
| `priority` | P0/P1/P2 |
| `widthDp` | 캡처/검증 폭. 기본 `360/390/430` |
| `textScale` | 기본 `1.0/1.3` |
| `checklist` | color/type/spacing/card/row/button/chip/chart/icon/state/asset/contract |
| `result` | `pending`, `pass`, `needs fix`, `exception` |
| `screenshotPath` | before/after screenshot 또는 manual note 경로 |
| `exceptionReason` | 예외 사유 |
| `nextAction` | 후속 단계 또는 산출물 |
| `auditMode` | `screen`, `component`, `contract`, `asset`, `audit-only` |

## Screenshot Rule

```text
docs/features/simple_patches/design_md_full_compliance/screenshots/
  before/{screen}_{state}_{width}dp.png
  after/{screen}_{state}_{width}dp.png
```

Manual QA note가 필요한 경우 같은 이름의 `.md` 파일을 사용한다.

## P0 Screen Matrix

| screen | file | route/state | priority | widthDp | textScale | checklist | result | screenshotPath | exceptionReason | nextAction | auditMode |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| App shell / floating tab bar | `lib/pages/app_shell_page.dart`, `lib/ui_scaffold/**`, `lib/widgets/moneyfy_ui.dart` | App start, bottom tabs selected/unselected, account replacement loading | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/button/icon/state | pending | `screenshots/before/app_shell_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-A | screen |
| Dashboard home | `lib/pages/portfolio_dashboard_page.dart` | Bottom tab `홈`, data/empty/loading states | P0 | 390/430 | 1.0 | color/type/spacing/card/row/button/chip/chart/icon/state | pass | `screenshots/after/dashboard_data_390dp_ts1_0.png`, `screenshots/after/dashboard_data_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 360 follow-up | screen |
| Portfolio list / diagnosis entry | `lib/pages/portfolio_page.dart` | Bottom tab `포트폴`, data/empty, diagnosis focus from home | P0 | 390/430 | 1.0 | color/type/spacing/card/row/button/chip/chart/icon/state | pass | `screenshots/after/portfolio_data_390dp_ts1_0.png`, `screenshots/after/portfolio_data_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 360 follow-up | screen |
| Transactions | `lib/pages/transactions_page.dart`, `lib/components/transaction_history_list.dart`, `lib/components/rows/transaction_row.dart` | Bottom tab `거래`, data/empty/filter/search/sort/swipe action | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/icon/state | pass | `screenshots/after/transactions_data_390dp_ts1_0.png`, `screenshots/after/transactions_data_430dp_ts1_0.png`, `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png` |  | Stage 09 430dp screenshot captured | screen |
| Asset detail | `lib/pages/asset_detail_page.dart` | From portfolio/dashboard asset row, data/chart/actions | P0 | 390/430 | 1.0 | color/type/spacing/card/row/button/chip/chart/icon/state | pass | `screenshots/after/asset_detail_data_390dp_ts1_0.png`, `screenshots/after/asset_detail_data_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 360 follow-up | screen |
| Holding detail | `lib/pages/holding_detail_page.dart` | From holding/asset row, data/chart/actions | P0 | 390/430 | 1.0 | color/type/spacing/card/row/button/chip/chart/icon/state | pass | `screenshots/after/holding_detail_data_390dp_ts1_0.png`, `screenshots/after/holding_detail_data_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 360 follow-up | screen |
| Cash account detail | `lib/pages/cash_account_detail_page.dart` | From cash account row, data/actions/history | P0 | 390/430 | 1.0 | color/type/spacing/card/row/button/chip/icon/state | pass | `screenshots/after/cash_account_detail_data_390dp_ts1_0.png`, `screenshots/after/cash_account_detail_data_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 360 follow-up | screen |
| Snapshot detail | `lib/pages/snapshot_detail_page.dart` | From dashboard/portfolio snapshot row, data/chart/detail rows | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/snapshot_detail_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-D | screen |
| Asset form | `lib/pages/forms/asset_form_page.dart`, `lib/pages/forms/form_design.dart` | Add/edit asset flow, validation/keyboard | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/chip/icon/state | pending | `screenshots/before/asset_form_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-E | screen |
| Holding form | `lib/pages/forms/holding_form_page.dart`, `lib/pages/forms/form_design.dart` | Add/edit holding flow, validation/keyboard | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/chip/icon/state | pending | `screenshots/before/holding_form_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-E | screen |
| Transaction form | `lib/pages/forms/transaction_form_page.dart`, `lib/pages/forms/form_design.dart` | Add/edit transaction flow, percentage shortcuts, validation/keyboard | P0 | 360/430 | 1.0/1.3 | color/type/spacing/card/button/chip/icon/state | pass | `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png`, `screenshots/after/transaction_form_keyboard_risk_430dp_ts1_0.png` |  | Stage 09 430dp screenshot captured; add 390 follow-up | screen |
| Cash account form | `lib/pages/forms/cash_account_form_page.dart`, `lib/pages/forms/form_design.dart` | Add/edit cash account flow, validation/keyboard | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/chip/icon/state | pending | `screenshots/before/cash_account_form_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-E | screen |
| Cash transaction form | `lib/pages/forms/cash_transaction_form_page.dart`, `lib/pages/forms/form_design.dart` | Add/edit cash transaction flow, validation/keyboard | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/chip/icon/state | pending | `screenshots/before/cash_transaction_form_keyboard_360dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-E | screen |
| Target allocation sheet | `lib/pages/target_allocation_sheet.dart` | From portfolio allocation action, sheet open/data/keyboard | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/icon/state | pending | `screenshots/before/target_allocation_sheet_data_390dp.png` |  | Stage 01 screenshot audit, Stage 03 P0-E | screen |

## P1 Screen Matrix

| screen | file | route/state | priority | widthDp | textScale | checklist | result | screenshotPath | exceptionReason | nextAction | auditMode |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Analysis hub | `lib/pages/analysis_page.dart` | Bottom tab `분석`, data/empty, analysis entry cards | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/analysis_hub_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-C | screen |
| Annual asset analysis | `lib/pages/annual_asset_analysis_page.dart` | From analysis hub, chart/table/empty | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/annual_asset_analysis_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-C | screen |
| Dividend/interest analysis | `lib/pages/dividend_interest_analysis_page.dart` | From analysis hub, chart/table/empty | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/dividend_interest_analysis_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-C | screen |
| Investment performance | `lib/pages/investment_performance_page.dart` | From analysis hub, benchmark/chart/table/error | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/investment_performance_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-C | screen |
| Portfolio diagnosis MVP | `lib/pages/portfolio_analysis_mvp_page.dart` | From analysis hub/portfolio focus, data/chart/recommendations | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/portfolio_analysis_mvp_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-C | screen |
| Statistics | `lib/pages/statistics_page.dart` | Bottom tab `통계`, data/empty/filter/chart/table | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/chart/icon/state | pending | `screenshots/before/statistics_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-A | screen |
| Login | `lib/pages/login_page.dart` | My/auth action, logged-out state, validation/loading/error | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/icon/state | pending | `screenshots/before/login_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-D | screen |
| Signup | `lib/pages/signup_page.dart` | Login signup action, validation/loading/error | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/icon/state | pending | `screenshots/before/signup_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-D | screen |
| My page | `lib/pages/my_page.dart` | Bottom tab `My`, logged-in/logged-out/account actions/destructive actions | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/row/button/chip/icon/state | pending | `screenshots/before/my_page_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-D | screen |
| Sync overlay | `lib/pages/sync_overlay.dart` | Sync progress/success/error overlay state | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/icon/state | pending | `screenshots/before/sync_overlay_loading_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-D | screen |
| Company news card | `lib/widgets/company_news_summary_card.dart` | Rendered in relevant asset/company context, loading/error/data | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/icon/state | pending | `screenshots/before/company_news_card_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-B | screen |
| Market news card | `lib/widgets/market_news_summary_card.dart` | Rendered in dashboard/market context, loading/error/data | P1 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/button/icon/state | pending | `screenshots/before/market_news_card_data_390dp.png` |  | Stage 01 screenshot audit, Stage 04 P1-B | screen |

## Component Contract Matrix

| screen | file | route/state | priority | widthDp | textScale | checklist | result | screenshotPath | exceptionReason | nextAction | auditMode |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Button contract | `lib/components/buttons/app_buttons.dart` | Primary/secondary/tertiary/loading/disabled variants | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/button/icon/contract | pending | `component_contract.md#buttons` |  | Stage 02 component contract | contract |
| Card contract | `lib/components/section_card.dart`, `lib/components/cards/status_card.dart`, `lib/components/headers/detail_header_card.dart` | Section/status/detail header variants | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/contract | pending | `component_contract.md#cards` |  | Stage 02 component contract | contract |
| Row contract | `lib/components/rows/**`, `lib/components/transaction_history_list.dart` | Asset/transaction/snapshot/settings/key-value/rebalance/allocation rows | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/row/icon/contract | pending | `component_contract.md#rows` |  | Stage 02 component contract | contract |
| Chip contract | `lib/components/chips/**` | Delta/impact/filter-like compact chips | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/chip/contract | pending | `component_contract.md#chips` |  | Stage 02 component contract | contract |
| Icon contract | `lib/components/icons/**` | Icon button/avatar/app icon/leading badge | P0 | 360/390/430 | 1.0/1.3 | color/spacing/icon/contract | pending | `component_contract.md#icons` |  | Stage 02 component contract | contract |
| State contract | `lib/components/states/**`, `lib/components/feedback/app_snackbar.dart` | Empty/retry/inline error/skeleton/snackbar states | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/button/icon/state/contract | pending | `component_contract.md#states` |  | Stage 02 component contract | contract |
| Metric contract | `lib/components/metrics/**` | Metric header/row values and labels | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/row/contract | pending | `component_contract.md#metrics` |  | Stage 02 component contract | contract |
| Separator contract | `lib/components/separators/app_divider.dart` | Divider/hairline variants | P0 | 360/390/430 | 1.0/1.3 | color/spacing/contract | pending | `component_contract.md#separators` |  | Stage 02 component contract | contract |
| Scaffold contract | `lib/ui_scaffold/**`, `lib/widgets/moneyfy_ui.dart` | Page scaffold/insets/legacy compatibility wrappers | P0 | 360/390/430 | 1.0/1.3 | color/type/spacing/card/state/contract | pending | `component_contract.md#scaffold` |  | Stage 02 component contract | contract |

## Audit-Only Source Matrix

| screen | file | route/state | priority | widthDp | textScale | checklist | result | screenshotPath | exceptionReason | nextAction | auditMode |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| App bootstrap/theme application | `lib/main.dart` | App start, `MoneyfyApp`, `StartupErrorApp`, text scaler | P1 | N/A | N/A | color/type/spacing/state/audit-only | pending | manual note |  | Stage 00 baseline, Stage 05 regression | audit-only |
| Design system source | `lib/design_system/**` | Tokens, typography, context extensions, visual/copy spec | P1 | N/A | N/A | color/type/spacing/card/chart/icon/contract | pending | `component_contract.md` |  | Stage 02 component contract, Stage 04 chart/icon | audit-only |
| Theme bridge | `lib/theme/**` | Legacy bridge and theme compatibility | P1 | N/A | N/A | color/type/contract/audit-only | pending | manual note |  | Stage 00 baseline, Stage 05 guardrail | audit-only |
| Number/display formatters | `lib/utils/display_currency.dart`, `lib/utils/number_formatters.dart`, `lib/components/formatters/number_format.dart` | Long currency/percent strings used by rows/cards/charts | P1 | 360/390/430 | 1.0/1.3 | type/row/card/chart/audit-only | pending | linked screen screenshots |  | Stage 01 screenshot audit | audit-only |
| Input validators | `lib/utils/input_validators.dart` | Form validation copy length and error state | P1 | 360/390/430 | 1.0/1.3 | type/state/audit-only | pending | linked form screenshots |  | Stage 03 P0-E forms | audit-only |

## Platform Asset Matrix

| screen | file | route/state | priority | widthDp | textScale | checklist | result | screenshotPath | exceptionReason | nextAction | auditMode |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Source app icon | `assets/app_icon_flat.svg`, `assets/icon/**` | Source asset diff/review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#source-app-icon` |  | Stage 04 P1-E | asset |
| Web visual assets | `web/manifest.json`, `web/index.html`, `web/icons/**`, `web/favicon.png` | Web manifest/theme/icon review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#web` |  | Stage 04 P1-E | asset |
| iOS visual assets | `ios/Runner/Assets.xcassets/**`, `ios/Runner/Info.plist`, `ios/Runner/Base.lproj/LaunchScreen.storyboard` | iOS icon/launch metadata review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#ios` |  | Stage 04 P1-E | asset |
| Android visual assets | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/**` | Android launcher/launch/theme review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#android` |  | Stage 04 P1-E | asset |
| macOS visual assets | `macos/Runner/Assets.xcassets/**`, `macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner/Base.lproj/MainMenu.xib` | macOS icon/app metadata review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#macos` |  | Stage 04 P1-E | asset |
| Linux visual metadata | `linux/runner/**` | Desktop metadata drift review | P1 | N/A | N/A | asset/color/icon | pending | `platform_asset_audit_report.md#linux` |  | Stage 04 P1-E | asset |

## 00단계 검증 결과

```bash
tools/check_design_token_guardrails.sh
rg -n "class .*Page|Widget build\\(" lib/pages lib/components lib/widgets --glob "*.dart"
```

결과:

- `tools/check_design_token_guardrails.sh`: clean.
- UI-bearing pages/components/widgets, audit-only source, formatter, platform asset 영역이 matrix에 배정됨.
- `screenshots/before/`와 `screenshots/after/` 폴더 생성됨.

## 다음 단계

1. Stage 01에서 P0 화면부터 before screenshot 또는 manual QA note를 채운다.
2. Stage 02에서 `component_contract.md`를 생성하고 component contract matrix를 갱신한다.
3. Stage 04에서 platform asset audit report를 작성한다.

## 01단계 진행 결과

```bash
tools/check_design_token_guardrails.sh
flutter test test/page_walkthrough_test.dart
```

결과:

- `tools/check_design_token_guardrails.sh`: clean.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- PNG screenshot harness는 아직 없어 실제 before screenshot은 생성하지 못함.
- `manual_notes/stage_01_mobile_screenshot_audit.md`에 캡처 재현 조건과 smoke coverage를 기록함.
- `manual_notes/needs_fix_20260529.md`에 code-assisted visual risk 후보를 기록함.

Stage 01 판정:

- 화면 진입 smoke: pass.
- 360/390/430dp visual screenshot audit: pending.
- 다음 단계에서 P0 화면부터 screenshot 또는 manual QA note를 채워야 함.

## 02단계 진행 결과

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/components lib/ui_scaffold lib/widgets/moneyfy_ui.dart
flutter test test/ui_component_smoke_test.dart
```

결과:

- `component_contract.md` 생성.
- 공용 button/card/row/chip/icon/state/metric/separator/scaffold contract를 canonical 기준으로 고정.
- Stage 01의 transaction/asset amount typography 후보는 `AppTypography.cardTitle`의 tabular figure 포함으로 contract pass 재분류.
- `DeltaChip.vivid`는 contract pass with visual follow-up으로 재분류.
- `tools/check_design_token_guardrails.sh`: clean.
- `flutter analyze lib/components lib/ui_scaffold lib/widgets/moneyfy_ui.dart`: passed, no issues.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.

## 03단계 진행 결과

Batch:

- P0-C Transactions

변경:

- `lib/pages/transactions_page.dart`의 거래 종류 badge background를 semantic positive/negative container에서 neutral surface로 통일.
- 거래 금액 semantic text color와 row layout은 유지.
- `TransactionRow` 공용 API 변경 없음.

검증:

```bash
dart format lib/pages/transactions_page.dart
flutter analyze lib/pages/transactions_page.dart
flutter test test/page_walkthrough_test.dart
tools/check_design_token_guardrails.sh
```

결과:

- `dart format lib/pages/transactions_page.dart`: passed. Flutter SDK cache write가 필요해 권한 상승으로 실행.
- `flutter analyze lib/pages/transactions_page.dart`: passed, no issues.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `tools/check_design_token_guardrails.sh`: clean.

주의:

- `lib/pages/transactions_page.dart`에는 기존 transaction filter redesign 변경이 함께 존재한다. 이번 Stage 03에서 의도한 P0 compliance 수정은 `_transactionTypeColor`의 badge background neutralization이다.

## 04단계 진행 결과

Batch:

- P1-B News Cards
- P1-C Analysis / Charts
- P1-E Icons / Platform Assets audit note

변경:

- `company_news_summary_card.dart`와 `market_news_summary_card.dart`의 중요도 pill background를 neutral surface로 통일.
- `portfolio_analysis_mvp_page.dart`의 diagnosis hero, HHI/MDD status pill background를 neutral surface로 통일.
- platform asset audit report 작성. Asset 파일 자체는 이번 Stage 04에서 수정하지 않음.

검증:

```bash
dart format lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart
flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart
flutter test test/page_walkthrough_test.dart
tools/check_design_token_guardrails.sh
git diff -- assets web ios android macos linux
```

결과:

- `dart format lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart`: passed. Flutter SDK cache write가 필요해 권한 상승으로 실행.
- `flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart`: passed, no issues.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `tools/check_design_token_guardrails.sh`: clean.
- `git diff -- assets web ios android macos linux`: platform asset diff reviewed and recorded in `platform_asset_audit_report.md`.

주의:

- Screenshot harness가 아직 없어 visual pass는 확정하지 않았다. Stage 05 또는 후속 manual QA에서 `company_news_card`, `market_news_card`, `portfolio_analysis_mvp` after screenshot을 채워야 한다.

## 05단계 진행 결과

Batch:

- Regression automation

변경:

- `tools/check_design_token_guardrails.sh --self-test` 추가.
- `verification_test_plan.md` 추가.
- `guardrail_hardening_proposal.md` 추가.
- `manual_notes/stage_05_regression_automation.md` 추가.

검증:

```bash
tools/check_design_token_guardrails.sh
tools/check_design_token_guardrails.sh --self-test
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

결과:

- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 193 tests.

Stage 05 판정:

- regression automation baseline: pass.
- guardrail self-test: pass.
- broad test regression: pass.
- screenshot/golden automation: pending. `verification_test_plan.md`의 후보 목록을 후속 구현 기준으로 사용한다.

## 06단계 진행 결과

Batch:

- Screenshot harness

변경:

- `test/design_md_screenshot_harness_test.dart` 추가.
- `plan_parts/06_screenshot_harness.md` 추가.
- `manual_notes/stage_06_screenshot_harness.md` 추가.
- `verification_test_plan.md`에 screenshot smoke/capture 명령과 artifact 목록 추가.

검증:

```bash
flutter analyze test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

결과:

- `flutter analyze test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 PNG artifacts generated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 204 tests.

추가 수정:

- `CompanyNewsSummaryCard` header meta overflow risk를 `Flexible` + ellipsis로 수정.

Stage 06 판정:

- screenshot harness smoke: pass.
- screenshot PNG capture: pass.
- 360dp + text scale 1.3 overflow-risk 후보: pass.
- golden diff automation: pending.

## 07단계 진행 결과

Batch:

- P0 visual compliance

변경:

- `test/design_md_screenshot_harness_test.dart`에 Korean system font와 Material icon font loading 추가.
- `AppPageScaffold` non-form 화면도 `Scaffold` 배경을 명시하도록 수정.
- `TransactionFormPage` 새 종목 검색 icon button을 black filled에서 neutral tonal treatment로 변경.
- P0 after screenshot artifact 재생성.

검증:

```bash
flutter analyze lib/ui_scaffold/app_page_scaffold.dart lib/pages/forms/transaction_form_page.dart test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

결과:

- `flutter analyze lib/ui_scaffold/app_page_scaffold.dart lib/pages/forms/transaction_form_page.dart test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, P0/P1 screenshot artifacts regenerated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 204 tests.

Stage 07 판정:

- P0 screenshot harness font/icon fidelity: pass.
- P0 standalone route background: fixed.
- P0 transaction form secondary tool button hierarchy: fixed.
- P0 360dp text scale 1.3 capture: pass.
- P0 loaded rich-data visual pass: pending. Seeded rich data screenshot이 필요하다.

## 08단계 진행 결과

Batch:

- Rich-data P0 screenshot baseline

변경:

- `test/design_md_screenshot_harness_test.dart`에 deterministic test DB seed를 추가.
- DB-backed P0 화면별 ready finder를 추가해 loaded data state가 아니면 test가 실패하도록 보강.
- Drift/background DB Future를 위해 repeated real-async settle 추가.
- Dashboard, portfolio, transactions, transaction form, asset detail, holding detail, cash account detail screenshot을 loaded data state로 재생성.
- `plan_parts/08_rich_data_p0_screenshots.md`와 `manual_notes/stage_08_rich_data_p0_screenshots.md` 추가.

검증:

```bash
flutter analyze test/design_md_screenshot_harness_test.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

결과:

- `flutter analyze test/design_md_screenshot_harness_test.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 14 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, rich-data screenshot artifacts regenerated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 207 tests.

Stage 08 판정:

- P0 loaded rich-data visual pass: pass for dashboard, portfolio, transactions, transaction form keyboard-risk, asset detail, holding detail, cash account detail.
- App shell / analysis hub capture: smoke-only exception. Remote/timer side effect mock 분리 후 재활성화한다.
- Golden diff automation: pending.

## 09단계 진행 결과

Batch:

- 430dp P0 screenshot baseline

변경:

- `test/design_md_screenshot_harness_test.dart`에 P0 rich-data 430dp screenshot case 7개 추가.
- 동일 fileStem의 390/430 케이스를 구분할 수 있도록 test description에 width와 text scale을 포함.
- 430dp after screenshot artifact 생성.
- `plan_parts/09_430dp_p0_screenshots.md`와 `manual_notes/stage_09_430dp_p0_screenshots.md` 추가.

검증:

```bash
flutter analyze test/design_md_screenshot_harness_test.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

결과:

- `flutter analyze test/design_md_screenshot_harness_test.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 21 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, 430dp screenshot artifacts generated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 214 tests.

Stage 09 판정:

- 430dp P0 visual baseline: pass for dashboard, portfolio, transactions, transaction form keyboard-risk, asset detail, holding detail, cash account detail.
- 360dp overflow-risk baseline: maintained from Stage 08.
- Golden diff automation: pending.
