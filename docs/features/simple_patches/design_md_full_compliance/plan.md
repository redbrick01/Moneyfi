# Design-MD Full Compliance Plan

작성일: 2026-05-29

## 목표

MONEYFY 모바일 앱 전체 화면과 주요 컴포넌트가 `docs/design_system.md`의 현행 Moneyfy design system을 실제 화면 단위까지 준수하도록 개선한다.

이 계획은 단순 토큰 치환이 아니다. 이미 적용된 토큰 기반을 출발점으로 삼고, 모바일 화면에서 사용자가 실제로 보는 card, row, button, chip, chart, icon, platform asset의 형태와 밀도, 계층, 색 사용, 숫자 표현, 터치 타깃, 빈/오류/로딩 상태가 Moneyfy design system의 원칙과 어긋나는 지점을 찾아 수정한다.

## 기준 해석

`docs/design_system.md`는 2026-05-30부터 Moneyfy 앱 UI 기준의 단일 디자인 규칙 문서다. 이전 Coinbase 분석에서 가져온 절제된 금융 UI 문법은 아래처럼 Moneyfy 모바일 앱 기준으로 재해석한다.

| design-md 원칙 | MONEYFY 모바일 적용 기준 |
| --- | --- |
| 순백 canvas와 절제된 gray band | 페이지 바닥은 흰색 중심, 정보 묶음은 soft gray 또는 hairline card로 구분 |
| Primary blue는 드물게 사용 | 주요 CTA, 선택 상태, 핵심 링크에만 사용하고 장식/보조 강조에는 남발하지 않음 |
| 숫자는 mono/tabular | 금액, 수익률, 비중, 차트 tooltip 숫자는 tabular figure 또는 mono 역할 적용 |
| trading green/red는 text only | 상승/하락 의미는 텍스트와 작은 아이콘/라인으로만 표현하고 filled background는 피함 |
| pill CTA, full circle asset icon | 버튼/검색/chip은 pill, 자산 아이콘은 circular plate, 일반 card는 rounded container |
| hairline 중심 depth | 중첩 shadow나 과장된 elevation 없이 1px hairline과 표면 차이로 계층 구성 |
| editorial calm | 제목/수치의 과도한 bold, 촘촘한 여백, 과다한 강조 색을 줄임 |

## 현재 완료된 작업

기존 `design_token_unification` 작업으로 아래 기반은 완료된 상태다.

| 완료 영역 | 산출물/근거 | 상태 |
| --- | --- | --- |
| 전체 UI 파일 coverage matrix | `docs/features/simple_patches/design_token_unification/plan_parts/00_coverage_matrix.md` | 완료 |
| 색상/폰트/간격/반경 토큰 기반 | `lib/design_system/**`, `lib/theme/**`, `lib/components/**` | 완료 |
| 공용 컴포넌트 토큰화 | buttons, chips, rows, states, section card, scaffold | 완료 |
| news/analysis/detail/form/shell/account/portfolio/transaction/stat 화면 토큰화 | Stage 03-06 test reports | 완료 |
| legacy pattern cleanup | `tools/check_design_token_guardrails.sh` | 완료 |
| reporting-only CI guardrail | `.github/workflows/flutter-ci.yml` | 완료 |
| guardrail 현재 상태 | `tools/check_design_token_guardrails.sh` 결과 clean | 완료 |
| platform asset audit 1차 | Stage 06D report | 완료 |

## 미완료 작업

토큰 가드레일은 깨끗하지만, full compliance 관점에서는 아래 작업이 남아 있다.

| 미완료 영역 | 문제 유형 | 우선순위 |
| --- | --- | --- |
| 화면별 visual audit | 토큰 사용 여부가 아니라 실제 모바일 화면 인상이 design-md와 맞는지 미확인 | P0 |
| 모바일 밀도 재조정 | 360/390/430dp에서 card padding, row height, sticky CTA, chart legend overflow 확인 필요 | P0 |
| 숫자 typography 일관성 | 모든 금액/수익률/비중/차트 tooltip이 mono/tabular 역할을 쓰는지 화면 단위 확인 필요 | P0 |
| semantic color 사용 | green/red background, 과도한 status fill, primary blue 남발 여부 확인 필요 | P0 |
| chart 문법 | chart palette, grid, legend, tooltip, selected state가 Moneyfy의 restrained surface 문법과 맞는지 확인 필요 | P1 |
| icon/asset 문법 | 자산 glyph, app icon, leading badge, native/web icon 색상이 단일 brand voltage와 맞는지 2차 확인 필요 | P1 |
| empty/loading/error 상태 | state component가 각 화면에서 같은 tone, spacing, action hierarchy로 보이는지 확인 필요 | P1 |
| dark/sync/auth surface | 어두운 hero/overlay가 design-md의 surface-dark/elevated 문법으로 통일됐는지 확인 필요 | P1 |
| statistics/news surface | 통계 화면과 뉴스 요약 카드가 전체 화면 audit 범위에 명시적으로 포함되어야 함 | P1 |
| visual regression harness | 주요 화면 screenshot/golden 기준이 없어 회귀를 자동 탐지하기 어려움 | P2 |

## 화면/컴포넌트별 점검 항목

### App Shell / Navigation

- 대상: `lib/pages/app_shell_page.dart`, `lib/ui_scaffold/**`, `lib/widgets/moneyfy_ui.dart`
- 점검: bottom navigation 높이와 safe area, selected primary blue 사용량, nav label typography, page title hierarchy, scaffold horizontal inset, scroll bottom inset.
- 수정 방향: 모바일 최상위 shell은 white canvas, hairline boundary, selected item만 blue, 비활성 item은 muted gray.
- 우선순위: P0

### Dashboard / Portfolio

- 대상: `lib/pages/portfolio_dashboard_page.dart`, `lib/pages/portfolio_page.dart`
- 점검: hero number typography, summary card density, asset row divider, circular asset icon plate, 수익률 green/red text-only, chart/legend spacing, CTA blue 사용량.
- 수정 방향: 핵심 금액은 calm display, 보조 metric은 card title/body hierarchy, 행은 56dp 이상 tap target과 1px hairline 기준.
- 우선순위: P0

### Transactions

- 대상: `lib/pages/transactions_page.dart`, `lib/components/transaction_history_list.dart`, `lib/components/rows/transaction_row.dart`
- 점검: 거래 row의 leading/trailing alignment, 금액 mono/tabular, filter chip pill, search/sort control, swipe action color, empty/error state.
- 수정 방향: 거래 종류별 색 배경을 줄이고, 금액과 변화량은 semantic text color로 제한.
- 우선순위: P0

### Detail Pages

- 대상: `lib/pages/asset_detail_page.dart`, `lib/pages/holding_detail_page.dart`, `lib/pages/cash_account_detail_page.dart`, `lib/pages/snapshot_detail_page.dart`, `lib/components/headers/detail_header_card.dart`
- 점검: detail header card radius/padding, section spacing, metric grid, row density, sticky actions, chart tooltip, back/action icon buttons.
- 수정 방향: detail header는 product-ui-card-light처럼 흰 card + hairline + calm number hierarchy로 통일.
- 우선순위: P0

### Forms / Sheets

- 대상: `lib/pages/forms/**`, `lib/pages/target_allocation_sheet.dart`
- 점검: text input height 48, radius 12, focus border primary blue, label/helper/error typography, keyboard safe area, primary/secondary button hierarchy, percentage shortcut chip.
- 수정 방향: 입력 필드는 `text-input`, 검색/shortcut은 pill, primary submit만 blue.
- 우선순위: P0

### Analysis Family

- 대상: `lib/pages/analysis_page.dart`, `annual_asset_analysis_page.dart`, `dividend_interest_analysis_page.dart`, `investment_performance_page.dart`, `portfolio_analysis_mvp_page.dart`
- 점검: 분석 카드가 과도하게 장식적이지 않은지, chart palette와 legend, table/metric row, selected chip, empty data state, tooltip number role.
- 수정 방향: 분석 화면은 dashboard보다 조금 dense하되, chart fill/semantic color/background 사용은 절제.
- 우선순위: P1

### Statistics / Reports

- 대상: `lib/pages/statistics_page.dart`
- 점검: 통계 summary card, 기간/필터 chip, metric row, chart/table area, empty/loading state, 긴 기간 라벨과 긴 금액의 모바일 overflow.
- 수정 방향: dashboard/detail 화면과 같은 number hierarchy를 유지하되, 분석성 정보는 row/table 밀도를 보존한다. chart와 table은 hairline/soft surface 중심으로 정리하고 primary blue는 선택 상태에만 사용한다.
- 우선순위: P1

### News / Summary Cards

- 대상: `lib/widgets/company_news_summary_card.dart`, `lib/widgets/market_news_summary_card.dart`
- 점검: 뉴스 카드 heading hierarchy, source/date caption, summary body line-height, link/CTA blue 사용, loading/error/retry 상태, 긴 제목/한글 줄바꿈, card padding/radius.
- 수정 방향: 뉴스 카드는 feature-card가 아니라 앱 내부 정보 card로 취급한다. 흰 surface, hairline, calm typography를 유지하고 primary blue는 링크/명확한 action에만 제한한다.
- 우선순위: P1

### Auth / My / Sync Overlay

- 대상: `lib/pages/login_page.dart`, `signup_page.dart`, `my_page.dart`, `sync_overlay.dart`
- 점검: auth CTA hierarchy, brand blue 사용, form rhythm, account row icon, destructive action color, sync modal dark/elevated surface, progress indicator size.
- 수정 방향: 로그인/가입은 light hero-band 앱형 변형, sync overlay는 dark elevated card 문법 적용.
- 우선순위: P1

### Shared Components

- 대상: `lib/components/buttons/**`, `chips/**`, `rows/**`, `cards/**`, `states/**`, `icons/**`, `metrics/**`, `section_card.dart`, `section_header.dart`
- 점검: button height 44/56, pill radius, chip padding, card radius, row min height, divider inset, icon min tap target, state component action placement.
- 수정 방향: 화면별 예외보다 공용 컴포넌트 contract를 먼저 고정하고 페이지는 이를 사용.
- 우선순위: P0

### Charts

- 대상: `VisualSpec.chart`, chart painter/legend/tooltip 사용부 전체
- 점검: chart palette 8색, grid alpha, donut/line stroke, selected state, tooltip radius/padding, legend row height, semantic color background 금지.
- 수정 방향: chart geometry는 보존하되 visual role은 `VisualSpec.chart`로 통일하고 모바일 legend overflow를 방지.
- 우선순위: P1

### Icons / Platform Assets

- 대상: `lib/components/icons/**`, `assets/**`, `web/manifest.json`, iOS/macOS/Android icon resources
- 점검: app icon primary color, native theme color, web manifest color, icon stroke/fill, asset glyph circle, launcher foreground/background 대비.
- 수정 방향: current primary `#3A6DFF`를 단일 brand voltage로 유지하고, 플랫폼별 자동 생성물은 Flutter UI 토큰과 분리해 audit-only로 관리.
- 우선순위: P1

## 우선순위 정의

| 우선순위 | 의미 | 예시 |
| --- | --- | --- |
| P0 | design-md 준수의 핵심. 사용자 주요 흐름과 모든 모바일 폭에서 즉시 맞춰야 함 | shell, dashboard, 거래, 상세, 폼, 공용 row/button/card |
| P1 | 브랜드 완성도와 분석 사용성에 영향. P0 이후 같은 릴리스에서 마무리 권장 | analysis charts, auth/my/sync, icon/platform asset |
| P2 | 자동화와 장기 유지보수. 기능 출시를 막지는 않지만 회귀 방지에 필요 | screenshot/golden harness, CI hardening |

## 단계별 구현 순서

세부 구현 계획은 `plan_parts/` 아래 문서로 분리한다.

| 단계 | 세부 문서 | 목적 |
| ---: | --- | --- |
| 0 | [00_baseline_audit_matrix.md](plan_parts/00_baseline_audit_matrix.md) | 기준 고정, audit matrix schema, route/state/screenshot 규칙 확정 |
| 1 | [01_mobile_screenshot_audit.md](plan_parts/01_mobile_screenshot_audit.md) | 모바일 폭별 before screenshot audit와 needs-fix 목록 작성 |
| 2 | [02_shared_component_contracts.md](plan_parts/02_shared_component_contracts.md) | button/card/row/chip/icon/state/scaffold contract 보강 |
| 3 | [03_p0_screen_compliance.md](plan_parts/03_p0_screen_compliance.md) | shell, dashboard, portfolio, transactions, detail, forms P0 화면 수정 |
| 4 | [04_p1_surface_compliance.md](plan_parts/04_p1_surface_compliance.md) | statistics, news, analysis/chart, auth/my/sync, icon/platform asset P1 정리 |
| 5 | [05_regression_automation.md](plan_parts/05_regression_automation.md) | guardrail hardening, screenshot/golden 후보, walkthrough 보강 |

### 0단계. 기준 고정과 감사표 작성

- 범위: 문서/감사만 수행.
- 세부 문서: [00_baseline_audit_matrix.md](plan_parts/00_baseline_audit_matrix.md)
- 작업:
  - `docs/design_system.md`를 모바일 앱 적용 규칙으로 요약한다.
  - 전체 화면 목록과 route 진입 조건을 정리한다.
  - P0/P1 화면별 audit checklist를 만든다.
  - audit matrix schema를 고정한다: `screen`, `file`, `route/state`, `widthDp`, `textScale`, `checklist`, `result`, `screenshotPath`, `exceptionReason`, `nextAction`.
  - 기존 `design_token_unification` 완료 항목과 중복되지 않도록 scope를 고정한다.
- 산출물:
  - `docs/features/simple_patches/design_md_full_compliance/audit_matrix.md`
  - screenshot 저장 규칙: `docs/features/simple_patches/design_md_full_compliance/screenshots/{before|after}/{screen}_{state}_{width}dp.png`
- 검증:
  - 모든 `lib/pages/**/*.dart`와 주요 `lib/components/**`가 matrix에 배정됨.
  - `statistics_page.dart`, company/market news cards, platform assets가 P1 audit 대상으로 배정됨.
- 완료 기준:
  - UI-bearing 화면 누락 0개.
  - 각 화면의 route/state와 screenshot path가 재현 가능하게 기록됨.

### 1단계. 모바일 기준 screenshot audit

- 범위: 주요 화면 전체, 360/390/430dp.
- 세부 문서: [01_mobile_screenshot_audit.md](plan_parts/01_mobile_screenshot_audit.md)
- 작업:
  - page walkthrough 또는 수동 seed data로 화면 진입하되, audit matrix에 사용한 route/state를 기록한다.
  - 같은 화면은 `data`, `empty`, `loading`, `error` 중 적용 가능한 상태를 최소 1개 이상 캡처한다.
  - 각 화면에서 color, typography, spacing, radius, card, row, button, chip, chart, icon 불일치를 기록.
  - 토큰 가드레일로 잡히지 않는 시각 문제를 issue list로 분류.
- 산출물:
  - `audit_matrix.md`의 화면별 판정: pass / needs fix / exception
  - before screenshot set: `screenshots/before/{screen}_{state}_{width}dp.png`
- 검증:
  - `tools/check_design_token_guardrails.sh`
  - `flutter test test/page_walkthrough_test.dart`
- 완료 기준:
  - P0 화면의 needs-fix 항목이 파일/라인/컴포넌트 단위로 구체화됨.
  - 각 P0 화면은 360/390/430dp 중 최소 2개 폭의 before screenshot을 보유함.

### 2단계. 공용 컴포넌트 contract 보강

- 범위: button, chip, card, row, icon, state, scaffold.
- 세부 문서: [02_shared_component_contracts.md](plan_parts/02_shared_component_contracts.md)
- 작업:
  - `AppButton` 계열의 44/56 height, pill radius, disabled/pressed state 재확인.
  - `SectionCard`, `StatusCard`, `DetailHeaderCard`의 radius/padding/border/elevation 정책 정리.
  - `AssetRow`, `TransactionRow`, `MetricRow`, `KeyValueRow`의 min height, divider, trailing number role 정리.
  - icon button과 leading badge의 min tap target, circular plate, muted/primary role 정리.
- 산출물:
  - 공용 컴포넌트 수정 PR 단위 변경
  - `component_contract.md` 또는 `audit_matrix.md` 내 component contract 섹션
- 검증:
  - `flutter analyze lib/components lib/ui_scaffold lib/widgets/moneyfy_ui.dart`
  - `flutter test test/ui_component_smoke_test.dart`
  - 주요 row/button/chip 수동 QA
- 완료 기준:
  - button, card, row, chip, icon, state component contract checklist가 모두 pass.
  - 새 P0 화면 수정에서 ad-hoc button/card/row/chip을 추가하지 않고 기존 공용 contract로 해결 가능함.

### 3단계. P0 화면 수정

- 범위: shell, dashboard, portfolio, transactions, detail pages, forms/sheets.
- 세부 문서: [03_p0_screen_compliance.md](plan_parts/03_p0_screen_compliance.md)
- 작업:
  - 화면별 card nesting, row density, number typography, semantic color background, primary blue 남발을 수정.
  - 360dp에서 긴 원화/달러 금액과 긴 종목명이 overflow되지 않도록 trailing width와 wrapping을 조정.
  - sticky CTA와 keyboard/safe area 겹침을 확인한다.
- 산출물:
  - P0 화면 batch별 implementation report
  - after screenshot set: `screenshots/after/{screen}_{state}_{width}dp.png`
- 검증:
  - `flutter analyze` 대상 파일 단위
  - `flutter test test/page_walkthrough_test.dart`
  - 360/390/430dp 수동 확인
- 완료 기준:
  - P0 화면 audit 항목 pass.
  - green/red filled background와 불필요한 blue emphasis가 없음.
  - 금액/비율/수익률이 mono/tabular 역할로 보임.

### 4단계. P1 화면과 chart/icon/platform asset 정리

- 범위: analysis family, auth/my/sync overlay, charts, icons, platform assets.
- 세부 문서: [04_p1_surface_compliance.md](plan_parts/04_p1_surface_compliance.md)
- 작업:
  - chart legend/tooltip/selected state를 `VisualSpec.chart` 기준으로 정리.
  - analysis card hierarchy와 metric density를 dashboard/detail과 맞춘다.
  - auth/my/sync overlay의 dark/elevated surface와 CTA hierarchy를 점검.
  - launcher/web/native asset color와 manifest/theme color를 재확인한다.
- 산출물:
  - chart compliance report
  - platform asset audit report
  - statistics/news compliance report
  - after screenshot set: `screenshots/after/{screen}_{state}_{width}dp.png`
- 검증:
  - `flutter analyze lib/pages/analysis_page.dart lib/pages/annual_asset_analysis_page.dart lib/pages/dividend_interest_analysis_page.dart lib/pages/investment_performance_page.dart lib/pages/portfolio_analysis_mvp_page.dart lib/pages/statistics_page.dart lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/my_page.dart lib/pages/sync_overlay.dart lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart`
  - `flutter test test/page_walkthrough_test.dart`
  - platform asset diff review
- 완료 기준:
  - P1 화면 audit 항목 pass 또는 명시적 exception.
  - chart가 모바일에서 빈 화면/overflow 없이 렌더링.
  - statistics/news 화면과 카드가 before/after screenshot 또는 수동 QA 메모를 보유함.

### 5단계. 회귀 방지 자동화

- 범위: tooling/CI.
- 세부 문서: [05_regression_automation.md](plan_parts/05_regression_automation.md)
- 작업:
  - `tools/check_design_token_guardrails.sh`를 reporting-only에서 blocking 전환 가능한 수준으로 allowlist 정리.
  - 주요 화면 screenshot/golden 후보를 선정한다.
  - page walkthrough가 design-md 핵심 화면을 안정적으로 방문하도록 보강한다.
- 산출물:
  - `verification_test_plan.md`
  - CI guardrail hardening proposal
  - screenshot/golden 후보 목록
- 검증:
  - `tools/check_design_token_guardrails.sh`
  - `flutter test`
  - CI dry run
- 완료 기준:
  - 신규 legacy pattern 추가가 CI에서 탐지됨.
  - 최소 P0 화면은 자동 또는 반자동 screenshot 비교 대상이 됨.

## 검증 방법

### 정적 검증

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/components lib/widgets lib/pages lib/ui_scaffold
```

변경 범위가 좁으면 파일 단위 `flutter analyze`를 먼저 실행하고, P0 화면 batch가 끝날 때 넓은 analyze를 실행한다.

### 테스트

```bash
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

`flutter test`는 공용 컴포넌트 contract, theme, scaffold, form field, chart helper 변경이 섞인 batch에서 실행한다.

### 모바일 시각 QA

- 폭: 360dp, 390dp, 430dp.
- text scale: 1.0, 1.3.
- 상태: light/dark, empty/loading/error/data.
- 확인 항목:
  - 텍스트/숫자 overflow 없음.
  - 버튼과 row touch target 44dp 이상.
  - card 안에 card가 불필요하게 중첩되지 않음.
  - primary blue는 CTA/selected/link에만 제한.
  - green/red는 text/line 중심이고 background fill로 쓰이지 않음.
  - chart tooltip/legend가 화면 밖으로 나가지 않음.
  - keyboard와 sticky CTA가 겹치지 않음.

### 코드/화면 판정 기준

- 금액, 수익률, 비중, chart tooltip 숫자는 `context.typography`의 number 역할 또는 `FontFeature.tabularFigures()`가 적용된 TextStyle을 사용한다.
- primary blue는 primary CTA, selected state, 명확한 link/action에만 사용한다. 동일 화면에서 장식성 blue 강조가 반복되면 `needs fix`로 분류한다.
- positive/negative semantic color는 text, icon, chart line/slice에만 사용한다. filled background가 있으면 예외 사유를 기록하거나 제거한다.
- card는 불필요한 card-in-card 구조를 만들지 않는다. 반복 item card, modal/sheet, 명확한 framed tool은 예외로 허용한다.
- row/button/chip/icon tap target은 최소 44dp, 주요 icon button은 `VisualSpec.icon.minTapTarget` 또는 동등한 contract를 따른다.
- screenshot audit은 `screenshotPath`가 비어 있으면 pass로 판정하지 않는다. 단, platform asset audit처럼 screenshot이 부적절한 항목은 diff/review note를 남긴다.

### 산출물 검증

각 batch는 다음을 남긴다.

- 변경 파일 목록
- audit 항목 pass/fix/exception 상태
- before/after screenshot 또는 수동 QA 메모
- 실행한 analyze/test 명령과 결과
- 남은 리스크

## 완료 기준

전체 작업은 아래 조건을 모두 만족할 때 완료로 본다.

- `audit_matrix.md`의 P0/P1 항목이 pass 또는 승인된 exception 상태.
- `tools/check_design_token_guardrails.sh`가 clean.
- 주요 변경 파일 `flutter analyze` 통과.
- `flutter test test/ui_component_smoke_test.dart`와 `flutter test test/page_walkthrough_test.dart` 통과.
- P0 화면이 360/390/430dp와 text scale 1.3에서 overflow 없이 동작.
- 금액/비율/수익률/차트 숫자가 `context.typography`의 number 역할 또는 `FontFeature.tabularFigures()`가 적용된 TextStyle로 표시.
- Primary blue `#3A6DFF`는 primary CTA, selected state, link/action에 제한되고, semantic green/red는 text/icon/chart mark 중심으로 사용됨.
- app icon, web manifest, native theme color가 brand asset audit에서 pass.
- 남은 예외가 있다면 파일/컴포넌트/사유/재검토 조건이 문서화됨.

## 리스크와 주의사항

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 토큰 통과와 실제 화면 불일치 | guardrail clean이어도 화면 밀도/계층/강조가 design-md와 다를 수 있음 | screenshot audit을 P0로 수행 |
| 과도한 마케팅 문법 적용 | MONEYFY는 앱이므로 96px editorial spacing을 그대로 적용하면 모바일 사용성이 떨어짐 | 모바일 앱용 재해석 기준 유지 |
| 정보 밀도 손실 | 투자 앱은 숫자와 행이 많아 너무 넓은 여백은 사용성을 해칠 수 있음 | row/card 최소 규칙과 화면별 density를 함께 검증 |
| chart 회귀 | painter geometry를 토큰화하다가 chart가 깨질 수 있음 | geometry는 보수적으로 유지하고 visual role만 정리 |
| semantic color 오용 | green/red filled chip이나 warning background가 Moneyfy 원칙과 충돌할 수 있음 | text-only 원칙을 audit 항목에 포함 |
| 플랫폼 asset 자동 생성 차이 | iOS/Android/web icon은 Flutter UI 토큰과 동기화되지 않을 수 있음 | asset audit을 별도 산출물로 관리 |
| 사용자 변경 충돌 | 현재 워크트리에 다수 변경이 있음 | 관련 파일만 좁게 수정하고 기존 변경을 되돌리지 않음 |
| visual regression 자동화 부족 | 수동 QA가 누락되면 회귀를 놓칠 수 있음 | P2에서 screenshot/golden 후보를 추가 |

## 권장 batch 순서

1. `audit_matrix.md` 작성과 before screenshot 수집.
2. 공용 component contract 보강.
3. shell/dashboard/portfolio P0 수정.
4. transactions/detail/forms P0 수정.
5. statistics/news P1 수정.
6. analysis/chart P1 수정.
7. auth/my/sync/icon/platform asset P1 수정.
8. guardrail/golden/page walkthrough P2 보강.

각 batch는 3-6개 파일 내로 유지하고, 화면 family가 큰 경우 dashboard, transaction, detail, form처럼 사용 흐름별로 나눈다.
