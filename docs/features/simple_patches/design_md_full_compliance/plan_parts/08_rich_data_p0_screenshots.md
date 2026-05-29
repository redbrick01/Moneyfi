# Stage 08 Rich-Data P0 Screenshots

작성일: 2026-05-29

## 목적

Stage 06-07 screenshot harness를 empty/loading에 가까운 화면이 아니라 실제 DB-backed data state 기준선으로 확장한다.

## Scope

| 영역 | 대상 |
| --- | --- |
| Test | `test/design_md_screenshot_harness_test.dart` |
| Artifacts | `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*.png` |
| Docs | `audit_matrix.md`, `verification_test_plan.md`, `manual_notes/stage_08_rich_data_p0_screenshots.md` |

## 구현 항목

1. Screenshot harness 시작 시 test DB를 deterministic seed data로 초기화한다.
2. dashboard, portfolio, transactions, asset detail, holding detail, cash account detail이 loaded data state로 캡처되도록 readiness finder를 둔다.
3. Drift/background DB Future가 widget test fake async에 갇히지 않도록 real-async settle을 반복한다.
4. App shell과 analysis hub는 remote/timer side effect를 피하기 위해 smoke-only로 유지하고 capture artifact는 이전 Stage 07 기준선을 보존한다.
5. Rich-data artifact를 재생성하고 manual note와 verification baseline을 갱신한다.

## 산출물

- Seeded DB screenshot harness.
- Loaded P0 data-state PNG:
  - `screenshots/after/dashboard_data_390dp_ts1_0.png`
  - `screenshots/after/portfolio_data_390dp_ts1_0.png`
  - `screenshots/after/transactions_data_390dp_ts1_0.png`
  - `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png`
  - `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png`
  - `screenshots/after/asset_detail_data_390dp_ts1_0.png`
  - `screenshots/after/holding_detail_data_390dp_ts1_0.png`
  - `screenshots/after/cash_account_detail_data_390dp_ts1_0.png`
- Stage 08 manual QA note.

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
- Capture env를 켰을 때 rich-data P0 PNG가 생성된다.
- DB-backed P0 화면의 ready text가 발견되지 않으면 테스트가 실패한다.
- Dashboard summary card, asset list, portfolio allocation, transactions list, detail header가 loading skeleton이 아닌 data state로 캡처된다.

## 주의사항

- Test seed는 화면 캡처 fidelity 목적이다. 실제 사용자 데이터나 sync 상태를 모사하지 않는다.
- Holding detail의 remote news/ticker side effect를 피하기 위해 캡처 seed의 대표 holding symbol은 비워 둔다.
- App shell과 analysis hub는 여러 child tab/service를 함께 mount하므로 capture mode에서는 smoke-only로 둔다.
- Pixel-level golden diff는 아직 도입하지 않았다.
