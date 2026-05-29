# Stage 09 430dp P0 Screenshot Report

작성일: 2026-05-29

## Scope

Seeded rich-data P0 screenshot harness에 430dp 넓은 모바일 viewport를 추가했다.

대상:

- `test/design_md_screenshot_harness_test.dart`
- `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*430dp*.png`

## 변경 사항

### 430dp Cases

다음 화면에 430dp case를 추가했다.

| 화면 | artifact |
| --- | --- |
| Dashboard | `screenshots/after/dashboard_data_430dp_ts1_0.png` |
| Portfolio | `screenshots/after/portfolio_data_430dp_ts1_0.png` |
| Transactions | `screenshots/after/transactions_data_430dp_ts1_0.png` |
| Transaction form | `screenshots/after/transaction_form_keyboard_risk_430dp_ts1_0.png` |
| Asset detail | `screenshots/after/asset_detail_data_430dp_ts1_0.png` |
| Holding detail | `screenshots/after/holding_detail_data_430dp_ts1_0.png` |
| Cash account detail | `screenshots/after/cash_account_detail_data_430dp_ts1_0.png` |

### Test Labeling

동일 `fileStem`을 390dp와 430dp에서 함께 쓰기 때문에 test description에 width와 text scale을 포함했다.

예:

```text
design-md screenshot harness: dashboard_data 430dp ts1_0
```

## Visual Review

- Dashboard 430dp: summary card, asset rows, AI analysis card entry가 넓은 폭에서도 hierarchy를 유지함.
- Portfolio 430dp: donut, allocation rows, rebalancing rows가 과도하게 퍼지지 않고 amount/chip 정렬 유지.
- Transactions 430dp: search/filter/chip row와 transaction amount가 overlap 없이 표시됨.
- Transaction form 430dp: search input과 search icon button이 한 줄에서 안정적으로 배치됨.
- Asset detail 430dp: header action icons, amount, holding rows가 안정적으로 표시됨.
- Holding detail 430dp: metric grid가 2-column 구성을 유지하고 card padding이 과도해 보이지 않음.
- Cash account detail 430dp: transaction row trailing amount와 memo section이 안정적으로 표시됨.

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

- 430dp P0 screenshot coverage: pass.
- Screenshot harness smoke: pass.
- Screenshot capture artifact generation: pass.
- Guardrail, component smoke, page walkthrough, and full Flutter test suite: pass.
- Golden diff: pending.

## Remaining Work

- Snapshot detail loaded screenshot.
- Target allocation sheet loaded screenshot.
- Cash transaction form loaded screenshot.
- App shell / analysis hub capture mode mock 분리.
- Pixel-level golden diff 자동화.
