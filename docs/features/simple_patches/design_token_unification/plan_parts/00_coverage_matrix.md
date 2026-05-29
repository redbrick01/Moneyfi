# 00 Coverage Matrix

## Goal

디자인 토큰 통일화 계획이 앱의 모든 UI 표면을 빠짐없이 다루는지 확인합니다. 이 문서는 구현 순서가 아니라 커버리지 체크리스트입니다.

## Scope Rule

`lib/**/*.dart` 중 화면, 컴포넌트, theme, scaffold, widget, form, sheet, visual state에 영향을 주는 파일은 모두 stage를 배정합니다.

계산, DB, sync, service, model 파일은 디자인 토큰 통일화 대상이 아닙니다. 단, 화면 표시 포맷에 영향을 주는 formatter는 visual QA에서 확인합니다.

## UI Coverage

| 영역 | 파일 | 담당 stage |
| --- | --- | --- |
| canonical design system | `lib/design_system/**` | Stage 01, Stage 07 |
| legacy theme bridge | `lib/theme/moneyfy_colors.dart`, `lib/theme/moneyfy_theme.dart` | Stage 07 |
| app bootstrap | `lib/main.dart` | Stage 06 |
| page scaffold | `lib/ui_scaffold/**` | Stage 02 |
| shared components | `lib/components/buttons/**`, `cards/**`, `chips/**`, `expandable/**`, `feedback/**`, `headers/**`, `icons/**`, `metrics/**`, `rows/**`, `section_card.dart`, `section_header.dart`, `separators/**`, `states/**`, `transaction_history_list.dart` | Stage 02 |
| compatibility widgets | `lib/widgets/moneyfy_ui.dart` | Stage 02B, Stage 07 |
| news widgets | `lib/widgets/company_news_summary_card.dart`, `lib/widgets/market_news_summary_card.dart` | Stage 03 |
| analysis entry | `lib/pages/analysis_page.dart` | Stage 03, Stage 04 |
| analysis family | `lib/pages/annual_asset_analysis_page.dart`, `dividend_interest_analysis_page.dart`, `investment_performance_page.dart`, `portfolio_analysis_mvp_page.dart` | Stage 04 |
| detail pages | `lib/pages/asset_detail_page.dart`, `cash_account_detail_page.dart`, `holding_detail_page.dart`, `snapshot_detail_page.dart` | Stage 05 |
| forms and sheets | `lib/pages/forms/**`, `lib/pages/target_allocation_sheet.dart` | Stage 05 |
| shell and nav | `lib/pages/app_shell_page.dart` | Stage 06 |
| home/portfolio surfaces | `lib/pages/portfolio_dashboard_page.dart`, `portfolio_page.dart` | Stage 06 |
| transaction/stat surfaces | `lib/pages/transactions_page.dart`, `statistics_page.dart` | Stage 06 |
| account/auth surfaces | `lib/pages/login_page.dart`, `signup_page.dart`, `my_page.dart` | Stage 06 |
| transient overlays | `lib/pages/sync_overlay.dart` | Stage 06 |

## Non-UI Code

아래 영역은 디자인 수치 통일화 대상에서 제외합니다.

- `lib/data/**`
- `lib/db/**`
- `lib/models/**`
- `lib/services/**`
- `lib/utils/input_validators.dart`
- calculation-only utilities such as `risk_adjusted_performance_calculator.dart`

Review-only:

- `lib/utils/display_currency.dart`
- `lib/utils/number_formatters.dart`
- `lib/components/formatters/number_format.dart`

이 formatter들은 색상/여백/폰트 대상은 아니지만, 표시 문자열 길이 변화가 row/button/card overflow를 만들 수 있으므로 관련 화면 QA에서 확인합니다.

## Design Assets And Native Surfaces

토큰화 대상은 아니지만 앱의 시각 일관성에 영향을 주므로 별도 확인합니다.

| 영역 | 파일 |
| --- | --- |
| app icon sources | `assets/app_icon_flat.svg`, `assets/icon/**` |
| web icon/favicon | `web/favicon.png`, `web/icons/**`, `web/manifest.json` |
| iOS app icon/launch | `ios/Runner/Assets.xcassets/**`, `ios/Runner/Base.lproj/LaunchScreen.storyboard` |
| macOS app icon/menu shell | `macos/Runner/Assets.xcassets/**`, `macos/Runner/Base.lproj/MainMenu.xib` |
| Android resources | `android/app/src/main/**` |

이 영역은 Flutter UI 토큰으로 치환하지 않습니다. Stage 06에서 brand asset consistency audit만 수행합니다.

## Coverage Verdict

기존 stage plan은 분석/상세/폼 중심으로 구성되어 있었고, 아래 표면이 명시적으로 빠져 있었습니다.

- app shell and navigation
- login/signup/my page
- portfolio dashboard and portfolio list
- statistics and transactions pages
- sync overlay
- theme bridge and UI scaffold
- app/native/web visual assets

Stage 06과 이 coverage matrix를 추가한 뒤에는 모든 UI-bearing Dart 파일이 stage에 배정됩니다. Native/web/app icon asset은 token unification 대상이 아니라 brand consistency audit 대상으로 분리합니다.

## Acceptance Criteria

- 새 UI 파일이 추가되면 이 matrix에 stage가 배정됩니다.
- `find lib -name "*.dart"` 기준 UI-bearing file 중 stage 미배정 파일이 없습니다.
- tokenization 대상과 review-only 대상이 구분됩니다.
