# Design-MD Full Compliance Verification Test Plan

작성일: 2026-05-29
최종 업데이트: 2026-05-30

## 목적

MONEYFY의 design-md full compliance 작업이 일회성 정리에 그치지 않도록 정적 guardrail, smoke walkthrough, manual QA, screenshot/golden 후보를 운영한다.

## Required Commands

### Always

```bash
tools/check_design_token_guardrails.sh
tools/check_design_token_guardrails.sh --self-test
flutter test test/design_md_screenshot_harness_test.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

### Batch-Specific Analyze

```bash
flutter analyze <changed dart files>
```

### Broad Verification

```bash
flutter test
```

`flutter test`는 공용 컴포넌트, scaffold, app theme, chart helper, form flow, route behavior가 함께 바뀐 batch에서 실행한다.

### Screenshot Capture

```bash
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
```

기본 `flutter test test/design_md_screenshot_harness_test.dart`는 PNG를 쓰지 않는 smoke run이다. 위 환경변수를 켠 경우에만 `screenshots/after/`에 capture artifact를 생성한다.

## Guardrail Policy

현재 CI의 `Design token guardrail report`는 reporting-only다.

| 항목 | 현재 상태 | 다음 조건 |
| --- | --- | --- |
| `tools/check_design_token_guardrails.sh` | clean이면 success, match가 있어도 exit 0 | 팀 합의 후 blocking 전환 가능 |
| `--self-test` | sample string 기반 탐지 검증, repo 파일 오염 없음 | CI 추가 후보 |
| CI step | `continue-on-error: true` | 최소 1회 reporting-only 기간 유지 후 blocking 검토 |

Blocking 전환 전 조건:

- allowlist가 안정적이다.
- chart geometry, platform asset, Flutter intrinsic values 예외가 문서화되어 있다.
- `--self-test`가 CI에서 안정적으로 통과한다.
- `docs/design_system.md`에 정의된 current primary `#3A6DFF`, SUIT font family, `AppFontWeights` 사용 규칙이 code guardrail과 일치한다.

## Screenshot / Golden Candidates

| 우선순위 | 후보 | 폭 | 이유 | 현재 상태 |
| ---: | --- | --- | --- | --- |
| 1 | dashboard data state | 390dp | 홈 첫인상, hero number, card hierarchy | seeded artifact |
| 2 | transactions data state | 390dp | row, badge, amount, filter controls | seeded artifact |
| 3 | transactions overflow-risk | 360dp | badge/title/amount 충돌 위험 | seeded artifact |
| 4 | transaction form keyboard-safe state | 360dp | input/CTA/keyboard safe area | seeded artifact |
| 5 | asset / holding / cash detail data state | 390dp | detail header, metrics, chart/action icons | seeded artifact |
| 6 | portfolio diagnosis MVP | 390dp | status hero, HHI/MDD badges, long analysis copy | candidate |
| 7 | statistics chart/table | 390dp | chart legend/table density | candidate |
| 8 | company/market news card | 390dp | news badge, long Korean title/body | candidate |
| 9 | P0 rich-data wide viewport | 430dp | 넓은 모바일 card width, whitespace, trailing alignment | seeded artifact |

현재 harness artifact:

- `screenshots/after/app_shell_data_390dp_ts1_0.png`
- `screenshots/after/dashboard_data_390dp_ts1_0.png`
- `screenshots/after/dashboard_data_430dp_ts1_0.png`
- `screenshots/after/transactions_data_390dp_ts1_0.png`
- `screenshots/after/transactions_data_430dp_ts1_0.png`
- `screenshots/after/transactions_overflow_risk_360dp_ts1_3.png`
- `screenshots/after/transaction_form_keyboard_risk_360dp_ts1_3.png`
- `screenshots/after/transaction_form_keyboard_risk_430dp_ts1_0.png`
- `screenshots/after/asset_detail_data_390dp_ts1_0.png`
- `screenshots/after/asset_detail_data_430dp_ts1_0.png`
- `screenshots/after/holding_detail_data_390dp_ts1_0.png`
- `screenshots/after/holding_detail_data_430dp_ts1_0.png`
- `screenshots/after/cash_account_detail_data_390dp_ts1_0.png`
- `screenshots/after/cash_account_detail_data_430dp_ts1_0.png`
- `screenshots/after/portfolio_data_390dp_ts1_0.png`
- `screenshots/after/portfolio_data_430dp_ts1_0.png`
- `screenshots/after/analysis_hub_data_390dp_ts1_0.png`
- `screenshots/after/portfolio_analysis_mvp_data_390dp_ts1_0.png`
- `screenshots/after/statistics_data_390dp_ts1_0.png`
- `screenshots/after/company_news_card_data_390dp_ts1_0.png`
- `screenshots/after/market_news_card_data_390dp_ts1_0.png`

## Manual QA Requirements

Screenshot harness가 준비되기 전에는 manual QA note를 산출물로 남긴다.

필수 기록:

- 도구/기기: simulator, physical device, in-app browser, Flutter test 등
- viewport: 360/390/430dp 중 실제 폭
- text scale: 1.0 또는 1.3
- seed data: local DB, test fixture, manual seed, empty state
- route/state: tab, pushed page, sheet/dialog, keyboard state
- 결과: pass / needs fix / exception
- 후속: 파일/컴포넌트/단계

## Walkthrough Coverage

`test/page_walkthrough_test.dart`가 현재 확인하는 범위:

- app shell bottom tabs: `홈`, `포트폴`, `거래`, `분석`, `통계`, `My`
- analysis hub child navigation: portfolio diagnosis, investment performance, dividend/interest analysis
- standalone first frame: asset detail, holding detail, cash account detail, asset form, holding form, cash account form, transaction form, cash transaction form, transactions, login, signup, investment performance, dividend/interest analysis, annual asset analysis, snapshot detail
- transaction form: market item search, calculation switch
- transactions: grouping and pull refresh smoke

Missing visual coverage:

- Golden diff assertion.
- Real OS keyboard screenshot.
- Seeded rich-data screenshot for snapshot detail, target allocation sheet, and cash transaction form.
- platform generated icon visual diff.

## Completion Criteria

- Guardrail clean.
- Guardrail self-test passed.
- `design_md_screenshot_harness_test.dart` passed.
- `ui_component_smoke_test.dart` passed.
- `page_walkthrough_test.dart` passed.
- `flutter test` passed for broad verification batches.
- P0 screenshot/golden candidates are registered.
- At least one 360dp overflow-risk candidate is registered.
- Remaining visual gaps are documented as manual QA or future screenshot harness work.

## Latest Baseline

2026-05-29 Stage 05 기준:

- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 193 tests.

이 baseline은 visual screenshot/golden을 대체하지 않는다. 실제 design-md 화면 준수 완료 판정은 P0/P1 screenshot 또는 manual QA note가 함께 채워져야 한다.

2026-05-29 Stage 06 기준:

- `flutter analyze test/design_md_screenshot_harness_test.dart lib/widgets/company_news_summary_card.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, 11 PNG artifacts generated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 204 tests.

Stage 06부터 screenshot artifact는 생성되지만, pixel-level golden diff는 아직 수행하지 않는다.

2026-05-29 Stage 07 기준:

- P0 screenshot harness는 Korean system font와 Material icon font를 로드한다.
- P0 non-form route background fallback은 `AppPageScaffold`에서 scaffold background를 명시해 방지한다.
- Transaction form secondary search button은 neutral tonal hierarchy를 사용한다.
- `flutter test`: passed, 204 tests.

Loaded rich-data screenshot과 golden diff는 아직 후속 과제다.

2026-05-29 Stage 08 기준:

- `test/design_md_screenshot_harness_test.dart`가 deterministic DB seed를 생성한다.
- DB-backed P0 화면은 ready text가 나타나야 pass한다.
- Dashboard, portfolio, transactions, transaction form, asset detail, holding detail, cash account detail screenshot이 loaded data state로 생성된다.
- `app_shell_data`, `analysis_hub_data`는 remote/timer side effect를 피하기 위해 capture mode에서 smoke-only로 유지한다.
- `flutter analyze test/design_md_screenshot_harness_test.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 14 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, rich-data PNG artifacts regenerated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 207 tests.

Golden diff와 일부 sheet/form/detail loaded state는 아직 후속 과제다.

2026-05-29 Stage 09 기준:

- P0 rich-data 화면에 430dp viewport screenshot case를 추가했다.
- Test description에 width/text scale을 포함해 390/430 케이스를 구분한다.
- 430dp artifacts: dashboard, portfolio, transactions, transaction form, asset detail, holding detail, cash account detail.
- `flutter analyze test/design_md_screenshot_harness_test.dart`: passed, no issues.
- `flutter test test/design_md_screenshot_harness_test.dart`: passed, 21 tests.
- `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart`: passed, 430dp PNG artifacts generated.
- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 214 tests.

Golden diff, real OS keyboard screenshot, snapshot/detail/sheet 추가 coverage는 아직 후속 과제다.

2026-05-30 Design Token Refresh 기준:

- Brand primary는 app icon blue 계열의 `#3A6DFF`로 통합했다.
- Brand active는 `#2DA4FF`, success는 `#00D47E`, warning은 `#FFB800`, error는 `#FF4554`로 정리했다.
- SUIT font family와 `AppFontWeights`를 token source로 분리했다.
- Direct `fontFamily`, legacy font family name, direct `FontWeight.w...`, direct `fontSize:` 탐지를 guardrail에 포함했다.
- Obsolete launcher icon assets and duplicate icon sources were removed.
- Design compliance screenshot artifacts were regenerated for the current token state.
- `flutter analyze`: passed, no issues.
