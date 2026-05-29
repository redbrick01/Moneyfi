# Stage 09 430dp P0 Screenshots

작성일: 2026-05-29

## 목적

Stage 08에서 구축한 seeded rich-data screenshot 기준선을 430dp 넓은 모바일 폭으로 확장한다. 430dp는 좁은 폭 overflow보다 card width, row hierarchy, whitespace balance, trailing amount alignment를 확인하는 보조 기준이다.

## Scope

| 영역 | 대상 |
| --- | --- |
| Test | `test/design_md_screenshot_harness_test.dart` |
| Artifacts | `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*430dp*.png` |
| Docs | `audit_matrix.md`, `verification_test_plan.md`, `manual_notes/stage_09_430dp_p0_screenshots.md` |

## 구현 항목

1. P0 rich-data 화면에 430dp screenshot case를 추가한다.
2. Test description에 width/text scale을 포함해 동일 fileStem의 390/430 케이스를 구분한다.
3. Capture artifact naming은 기존 규칙을 유지한다.
4. 생성된 430dp PNG를 눈검수하고 matrix를 갱신한다.

## 산출물

- 430dp P0 screenshot cases.
- 430dp loaded data-state PNG:
  - `screenshots/after/dashboard_data_430dp_ts1_0.png`
  - `screenshots/after/portfolio_data_430dp_ts1_0.png`
  - `screenshots/after/transactions_data_430dp_ts1_0.png`
  - `screenshots/after/transaction_form_keyboard_risk_430dp_ts1_0.png`
  - `screenshots/after/asset_detail_data_430dp_ts1_0.png`
  - `screenshots/after/holding_detail_data_430dp_ts1_0.png`
  - `screenshots/after/cash_account_detail_data_430dp_ts1_0.png`

## 검증

```bash
flutter analyze test/design_md_screenshot_harness_test.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

## 완료 기준

- Harness smoke run이 통과한다.
- Capture env를 켰을 때 430dp PNG가 생성된다.
- 430dp dashboard, portfolio, transactions, transaction form, asset detail, holding detail, cash account detail이 loaded data state로 캡처된다.
- 430dp artifact에서 card width, row amount, chip, action icon, input/button layout의 명백한 overlap이 없다.

## 주의사항

- 430dp는 iPhone Plus/Max 계열에 가까운 넓은 모바일 폭 기준이다.
- 360dp + text scale 1.3 overflow-risk는 기존 Stage 08 artifact를 유지한다.
- 430dp golden diff는 아직 도입하지 않았다.
