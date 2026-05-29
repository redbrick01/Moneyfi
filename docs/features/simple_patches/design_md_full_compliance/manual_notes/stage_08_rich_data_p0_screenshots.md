# Stage 08 Rich-Data P0 Screenshot Report

작성일: 2026-05-29

## Scope

DB-backed P0 화면을 실제 데이터가 있는 loaded state로 캡처하도록 screenshot harness를 보강했다.

대상:

- `test/design_md_screenshot_harness_test.dart`
- `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*.png`

## 변경 사항

### Deterministic Test Seed

Harness `setUpAll`에서 local test DB를 초기화하고 다음 데이터를 생성한다.

- 자산: 주식, 코인, 현금
- 보유: 삼성전자, Apple Inc., Bitcoin, 토스증권 위탁계좌
- 거래: 매수, 배당, 매도, 입금
- 목표 비중: 주식 62%, 코인 18%, 현금 20%

### Loaded-State Readiness

각 DB-backed 화면은 주요 텍스트가 나타날 때까지 기다린다.

| 화면 | ready 기준 |
| --- | --- |
| Dashboard | `주식` |
| Portfolio | `리밸런싱` |
| Transactions | `삼성전자` |
| Asset detail | `삼성전자` |
| Holding detail | `삼성전자` |
| Cash account detail | `토스증권 위탁계좌` |

Ready 기준이 충족되지 않으면 screenshot test가 실패한다.

### Capture Stability

- Drift/background DB Future를 위해 real-async settle을 여러 번 수행한다.
- `app_shell_data`, `analysis_hub_data`는 capture mode에서 PNG를 새로 쓰지 않는다. 두 화면은 child tab/service side effect가 많아 Stage 08에서는 smoke-only로 유지한다.
- Holding detail seed의 대표 symbol은 비워 remote news/ticker timer가 캡처 테스트에 들어오지 않도록 했다.

## Artifacts

- `screenshots/after/dashboard_data_390dp_ts1_0.png`
- `screenshots/after/portfolio_data_390dp_ts1_0.png`
- `screenshots/after/transactions_data_390dp_ts1_0.png`
- `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png`
- `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png`
- `screenshots/after/asset_detail_data_390dp_ts1_0.png`
- `screenshots/after/holding_detail_data_390dp_ts1_0.png`
- `screenshots/after/cash_account_detail_data_390dp_ts1_0.png`
- `screenshots/after/portfolio_analysis_mvp_data_390dp_ts1_0.png`
- `screenshots/after/statistics_data_390dp_ts1_0.png`
- `screenshots/after/company_news_card_data_390dp_ts1_0.png`
- `screenshots/after/market_news_card_data_390dp_ts1_0.png`

## Visual Review

- Dashboard: summary card와 asset list가 loaded data state로 캡처됨.
- Portfolio: allocation donut, allocation rows, rebalancing rows가 loaded data state로 캡처됨.
- Transactions: filter chips, row badges, long currency strings가 390dp에서 겹침 없이 표시됨.
- Transactions overflow-risk: 360dp + text scale 1.3에서 row title/amount/chip overlap 없음.
- Asset detail: header action icons, amount, holding rows가 loaded data state로 표시됨.
- Holding detail: header, metric grid, chart area가 loaded data state로 표시됨.
- Cash account detail: cash header, transaction row, memo section이 loaded data state로 표시됨.

## Verification

```bash
flutter analyze test/design_md_screenshot_harness_test.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

## Result

- Loaded rich-data P0 screenshot: pass.
- Screenshot harness smoke: pass.
- Screenshot capture artifact generation: pass.
- Guardrail, component smoke, page walkthrough, and full Flutter test suite: pass.
- Golden diff: pending.

## Remaining Work

- 430dp P0 screenshot 후보 추가.
- Snapshot detail, target allocation sheet, cash transaction form loaded screenshot 추가.
- App shell / analysis hub의 remote side effect를 mock으로 분리한 뒤 capture mode 재활성화.
- Pixel-level golden diff 자동화.
