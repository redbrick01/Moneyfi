# Stage 06 Screenshot Harness Report

작성일: 2026-05-29

## Scope

Design-MD full compliance의 실제 모바일 화면 점검을 위해 Flutter widget test 기반 screenshot harness를 추가했다.

대상:

- `test/design_md_screenshot_harness_test.dart`
- `docs/features/simple_patches/design_md_full_compliance/screenshots/after/`
- `verification_test_plan.md`
- `audit_matrix.md`

## Implementation

- 390dp 기본 모바일 viewport capture 후보를 등록했다.
- 360dp + text scale 1.3 overflow-risk 후보를 등록했다.
- 평소 test 실행에서는 PNG를 쓰지 않고 smoke만 수행한다.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1` 환경변수로 실행할 때만 PNG를 생성한다.
- screenshot filename은 `{screen}_{state}_{width}dp_ts{textScale}.png` 형식을 따른다.

## Capture Cases

| case | width | textScale | artifact |
| --- | ---: | ---: | --- |
| app shell | 390dp | 1.0 | `screenshots/after/app_shell_data_390dp_ts1_0.png` |
| dashboard | 390dp | 1.0 | `screenshots/after/dashboard_data_390dp_ts1_0.png` |
| transactions | 390dp | 1.0 | `screenshots/after/transactions_data_390dp_ts1_0.png` |
| transactions overflow-risk | 360dp | 1.3 | `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png` |
| transaction form keyboard-risk | 360dp | 1.3 | `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png` |
| asset detail | 390dp | 1.0 | `screenshots/after/asset_detail_data_390dp_ts1_0.png` |
| analysis hub | 390dp | 1.0 | `screenshots/after/analysis_hub_data_390dp_ts1_0.png` |
| portfolio diagnosis MVP | 390dp | 1.0 | `screenshots/after/portfolio_analysis_mvp_data_390dp_ts1_0.png` |
| statistics | 390dp | 1.0 | `screenshots/after/statistics_data_390dp_ts1_0.png` |
| company news card | 390dp | 1.0 | `screenshots/after/company_news_card_data_390dp_ts1_0.png` |
| market news card | 390dp | 1.0 | `screenshots/after/market_news_card_data_390dp_ts1_0.png` |

## Verification

```bash
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

## Result

- `flutter analyze test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 PNG artifacts generated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 204 tests.

추가 발견/수정:

- `company_news_card_data` capture 중 390dp에서 header meta가 6px overflow되는 visual risk를 발견했다.
- `CompanyNewsSummaryCard` header meta를 `Flexible` + ellipsis 처리로 수정해 390dp capture smoke를 통과시켰다.

판정:

- Stage 06 screenshot harness baseline은 pass.
- PNG artifact 생성 경로와 파일명 규칙은 동작 확인됨.
- Golden diff 자동 판정은 아직 pending.

## Limits

- Golden diff는 아직 연결하지 않았다.
- Flutter widget test의 focused input은 실제 OS keyboard 이미지를 렌더링하지 않는다.
- Data-backed 화면은 현재 test DB/local fallback 상태를 사용하므로 seeded rich data capture는 후속 과제다.
- Capture는 첫 viewport 기준이며, scroll continuation screenshot은 후속 과제다.
