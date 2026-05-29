# 06 Remaining App Surfaces

## Goal

분석/상세/폼 외의 앱 표면을 통일합니다. 이 stage는 사용자가 실제로 자주 지나가는 shell, auth, home, portfolio, transaction, statistics, account, overlay 화면을 빠짐없이 다룹니다.

## Target Files

- `lib/main.dart`
- `lib/pages/app_shell_page.dart`
- `lib/pages/portfolio_dashboard_page.dart`
- `lib/pages/portfolio_page.dart`
- `lib/pages/transactions_page.dart`
- `lib/pages/statistics_page.dart`
- `lib/pages/login_page.dart`
- `lib/pages/signup_page.dart`
- `lib/pages/my_page.dart`
- `lib/pages/sync_overlay.dart`

Brand asset consistency audit:

- `assets/app_icon_flat.svg`
- `assets/icon/**`
- `web/favicon.png`
- `web/icons/**`
- `web/manifest.json`
- `ios/Runner/Assets.xcassets/**`
- `macos/Runner/Assets.xcassets/**`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `macos/Runner/Base.lproj/MainMenu.xib`
- `android/app/src/main/**`

## Replacement Rules

| Area | Rule |
| --- | --- |
| shell/nav | use `ColorScheme`, `context.colors`, documented nav heights and insets |
| page background | use canonical scaffold/background token, no ad-hoc white/transparent surfaces |
| dashboard cards | use `SectionCard`, component rows, typography and spacing tokens |
| auth forms | use theme `InputDecorationTheme`, `AppPrimaryButton`, `context.spacing` |
| account/settings rows | use row components or tokenized row slots |
| transaction/stat pages | align with shared rows, chips, empty/error/loading states |
| sync overlay | use semantic status colors, motion tokens, stable overlay spacing |
| brand assets | verify source consistency; do not convert through Flutter design tokens |

## Batch Strategy

Batch 06A:

- `app_shell_page.dart`
- `main.dart`
- `sync_overlay.dart`

Batch 06B:

- `portfolio_dashboard_page.dart`
- `portfolio_page.dart`
- `transactions_page.dart`
- `statistics_page.dart`

Batch 06C:

- `login_page.dart`
- `signup_page.dart`
- `my_page.dart`

Batch 06D:

- app icon, launch, web icon, native shell asset consistency audit

## Scope Boundaries

Keep:

- navigation structure
- auth behavior
- transaction list behavior
- portfolio calculation/display logic
- sync lifecycle behavior
- native platform configuration

Do not change:

- route contracts
- auth/session persistence
- DB, sync, or transaction calculation behavior
- app icon artwork without a separate design decision

## Verification

Required:

```bash
flutter analyze lib/main.dart lib/pages/app_shell_page.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/statistics_page.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/my_page.dart lib/pages/sync_overlay.dart
flutter test test/page_walkthrough_test.dart
```

If auth UI is touched:

```bash
flutter test test/widget_test.dart
```

If transaction/stat surfaces are touched:

```bash
flutter test test/transaction_flow_test.dart
```

## Manual QA

- bottom navigation and top app surfaces keep selected/disabled state contrast
- portfolio dashboard cards do not overlap at 360dp and text scale 1.3
- transaction/stat filters, chips, trailing values stay aligned
- login/signup fields and CTA remain keyboard-safe
- my page settings/action rows keep touch target size
- sync overlay does not block or obscure primary navigation unexpectedly
- web/iOS/macOS app icons and launch surfaces use consistent brand source

## Acceptance Criteria

- all remaining app pages are assigned and reviewed
- no new arbitrary colors, font sizes, radii, or spacing in touched files
- brand assets are explicitly marked consistent or logged as follow-up
- page walkthrough still passes
