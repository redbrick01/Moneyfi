# 카드/패널 시각 문법 통일 08A-08E 검증 보고서

작성일: 2026-05-30

## 범위

계획서 `plan_parts/08_card_panel_visual_grammar.md`의 첫 구현 배치다.

이번 배치에서 다룬 범위:

- 08A 공용 표면 컴포넌트 일부
- 08B 영향 큰 페이지 카드 중 뉴스 카드
- 08E 잔여 표면 중 정렬 팝오버 메뉴 일부

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/components/panels/app_inner_panel.dart` | L2 내부 패널 공용 컴포넌트 추가 |
| `lib/components/panels/app_floating_menu_surface.dart` | L4 팝오버 메뉴 표면 공용 컴포넌트 추가 |
| `lib/widgets/company_news_summary_card.dart` | 외곽 카드를 `SectionCard`로 정리하고 내부 뉴스 타일을 `AppInnerPanel`로 정리 |
| `lib/widgets/market_news_summary_card.dart` | 외곽 카드를 `SectionCard`로 정리하고 요약/이슈/종합평가 패널을 `AppInnerPanel`로 정리 |
| `lib/pages/portfolio_dashboard_page.dart` | 자산 정렬 메뉴 껍데기를 `AppFloatingMenuSurface`로 교체 |
| `lib/pages/asset_detail_page.dart` | 보유 종목 정렬 메뉴 껍데기를 `AppFloatingMenuSurface`로 교체 |
| `test/ui_component_smoke_test.dart` | 신규 패널 표면 렌더 smoke test 추가 |
| `lib/components/panels/app_detail_section.dart` | 상세 화면 L1 섹션과 선택적 L2 내부 패널을 묶는 공용 컴포넌트 추가 |

추가 진행:

| 파일 | 변경 |
| --- | --- |
| `lib/pages/portfolio_dashboard_page.dart` | 자산/AI 분석 base plate를 `SectionCard` 기반 L1 문법으로 교체하고, 요약 펼침 상세를 `AppInnerPanel` 기반 L2 문법으로 정리 |
| `lib/pages/statistics_page.dart` | 중첩 카드처럼 보이던 통계 section base plate wrapper를 제거하고 각 section의 기존 `SectionCard`를 L1로 유지 |
| `lib/pages/asset_detail_page.dart` | `_CardSection` 구현을 `AppDetailSection`으로 위임 |
| `lib/pages/holding_detail_page.dart` | `_CardSection` 구현을 `AppDetailSection`으로 위임 |
| `lib/pages/cash_account_detail_page.dart` | `_CashCardSection` 구현을 `AppDetailSection`으로 위임 |
| `lib/components/metrics/app_metric_tile.dart` | 분석 화면 L3 지표 타일 공용 컴포넌트 추가 |
| `lib/pages/investment_performance_page.dart` | `_MiniMetricTile`, `_RiskMetricTile` 내부 표면을 `AppMetricTile`로 위임 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | `_MetricTile` 내부 표면을 `AppMetricTile`로 위임 |
| `lib/components/panels/app_sheet_surface.dart` | L5 바텀시트 표면과 핸들 공용 컴포넌트 추가 |
| `lib/pages/transactions_page.dart` | 거래 필터/거래 유형 선택 시트를 `AppSheetSurface`, `AppSheetHandle`로 교체 |
| `lib/pages/forms/form_design.dart` | 폼 선택 시트를 `AppSheetSurface`, `AppSheetHandle`로 교체 |
| `lib/pages/target_allocation_sheet.dart` | 목표 비중 시트의 기본 modal handle을 공용 `AppSheetSurface`, `AppSheetHandle`로 교체 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | 복합 분석 화면의 반복 내부 정보 행을 `AppInnerPanel(tone: raised)`로 연결 |
| `lib/design_system/spec/visual_spec.dart` | 라이트 테마 L1/L1-raised 카드 표면 대비를 높여 카드 위계가 눈에 보이도록 조정 |
| `lib/components/panels/app_inner_panel.dart` | L2 기본 내부 패널 배경을 L1 카드와 분리된 흰 표면으로 조정 |
| `lib/components/states/empty_state.dart` 외 현재 호출부 | `SectionCardVariant.raised`, `MoneyfySurfaceCardVariant.raised` 호출을 기본 섹션 카드 호출로 변경 |
| `card_panel_token_sample_20260530.svg` | 라이트 테마 카드 variant 3종처럼 보이던 샘플을 현재 앱 호출부 기준의 기본 섹션 카드 단일 적용으로 수정 |
| `lib/pages/portfolio_dashboard_page.dart` | AI 포트폴리오 분석 영역의 하단 외곽 `SectionCard` 레이어를 제거해 2단 레이어 규칙으로 정리 |
| `lib/pages/portfolio_page.dart` | 자산 비중/리밸런싱/포트폴리오 분석 카드의 바깥 `_PortfolioSectionBasePlate` 레이어를 제거해 중첩 카드 인상을 축소 |

## 시각 문법 적용

| 단계 | 적용 |
| --- | --- |
| L1 섹션 카드 | 뉴스 외곽 카드를 직접 `Container + BoxDecoration`에서 `SectionCard`로 교체 |
| L2 내부 패널 | 뉴스 요약/이슈/종합평가 항목을 `AppInnerPanel`로 교체 |
| L4 임시 부유 표면 | 정렬 메뉴 껍데기를 `AppFloatingMenuSurface`로 교체 |
| L1 대시보드/통계 카드 | 대시보드 직접 base plate는 `SectionCard` 기반으로 교체, 통계는 불필요한 외곽 wrapper를 제거해 중첩 카드 효과를 축소 |
| L2 대시보드 내부 패널 | 홈 요약 상세 영역을 `AppInnerPanel`로 교체 |
| L1 상세 섹션 | 상세 페이지의 반복 카드 섹션을 `AppDetailSection`으로 연결 |
| L2 상세 내부 패널 | 상세 섹션 body wrapper를 `AppInnerPanel` 기반으로 연결 |
| L3 분석 지표 타일 | 투자성과/포트폴리오 분석의 반복 지표 타일을 `AppMetricTile`로 연결 |
| L5 바텀시트 | 거래/폼 선택 시트의 상단 라운드 표면과 핸들을 `AppSheetSurface`, `AppSheetHandle`로 연결 |
| 잔여 내부 패널 | 복합 분석 화면의 반복 정보 행을 L2 내부 패널 문법으로 연결 |
| 표면 대비 | 라이트 테마에서 앱 배경과 L1 카드가 모두 흰색으로 붙어 보이던 문제를 줄이고, L1 카드와 L2 내부 패널의 배경 위계를 분리 |
| 기본 섹션 카드 단일화 | 현재 앱 호출부에서 `raised`, `outline`을 쓰지 않고 기본 섹션 카드 호출만 사용 |
| AI 분석 2단 레이어 | 제목/상태 배지는 평면 영역에 두고, 실제 분석 콘텐츠 카드만 L1로 유지해 3중 레이어 인상을 제거 |
| 자산 비중 2단 레이어 | 포트폴리오 화면 자산 비중 영역은 바깥 base plate 없이 실제 자산 비중 `SectionCard`만 렌더링 |
| 리밸런싱 2단 레이어 | 포트폴리오 화면 리밸런싱 영역은 바깥 base plate 없이 실제 리밸런싱 `SectionCard`만 렌더링 |
| 포트폴리오 분석 2단 레이어 | 포트폴리오 화면 AI 분석 영역은 바깥 base plate 없이 실제 분석 `SectionCard`만 렌더링 |

## 의도한 시각 변화

- 뉴스 외곽 카드가 다른 앱 섹션 카드와 같은 얇은 테두리 중심 문법을 따른다.
- 뉴스 내부 항목은 `radiusCard`와 shadow를 쓰는 중첩 카드가 아니라, 한 단계 낮은 `rMd` 내부 패널로 보인다.
- 정렬 메뉴는 일반 인페이지 카드가 아니라 부유 메뉴 표면으로 분리된다.

## 검증

통과:

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/components/panels/app_inner_panel.dart lib/components/panels/app_floating_menu_surface.dart lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_dashboard_page.dart lib/pages/asset_detail_page.dart test/ui_component_smoke_test.dart
flutter analyze lib/pages/portfolio_dashboard_page.dart lib/pages/statistics_page.dart
flutter analyze lib/components/panels/app_detail_section.dart lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart test/ui_component_smoke_test.dart
flutter analyze lib/components/metrics/app_metric_tile.dart lib/pages/investment_performance_page.dart lib/pages/portfolio_analysis_mvp_page.dart test/ui_component_smoke_test.dart
flutter analyze lib/components/panels/app_sheet_surface.dart lib/pages/transactions_page.dart lib/pages/forms/form_design.dart test/ui_component_smoke_test.dart
flutter analyze lib/pages/target_allocation_sheet.dart lib/pages/portfolio_analysis_mvp_page.dart lib/components/panels/app_sheet_surface.dart lib/components/panels/app_inner_panel.dart
flutter analyze lib/design_system/spec/visual_spec.dart lib/components/section_card.dart lib/components/panels/app_inner_panel.dart lib/components/metrics/app_metric_tile.dart test/ui_component_smoke_test.dart
flutter test test/ui_component_smoke_test.dart
```

결과:

- design token guardrail: clean
- analyzer: no issues
- `ui_component_smoke_test.dart`: all tests passed

보류:

- `asset_detail_page.dart`, `holding_detail_page.dart`, `cash_account_detail_page.dart` 상단 히어로 내부의 `context.shadows.level2` 패널은 상세 섹션 공통화 대상이 아니라 08D/후속 특수 히어로 표면 정리에서 다룬다.
- `portfolio_analysis_mvp_page.dart`의 복합 행 패널과 리스트형 원인/기여도 카드들은 단순 라벨/값 지표 타일이 아니므로 별도 08D 후속 배치에서 다룬다.

부분 실패:

```bash
flutter test test/page_walkthrough_test.dart
```

결과:

- 23개 테스트 중 22개 통과, 1개 실패
- 실패 테스트: `stage 1: app shell visits every bottom tab`
- 실패 내용: `bottom-tab-홈` key를 찾지 못함
- 이번 변경 범위는 뉴스 카드, 정렬 메뉴, 공용 패널 표면이라 app shell bottom tab key와 직접 관련 없음

## 남은 작업

- 상세 화면 상단 히어로 표면은 일반 섹션/내부 패널이 아니라 강조 영역이라, 실제 화면에서 튄다고 판단될 때 별도 조정
- 차트, 진행 바, 상태 배지처럼 표면이 아닌 장식 요소는 이번 카드/패널 통일 범위에서 제외
- `page_walkthrough_test.dart`의 app shell 탭 key 실패 원인 별도 확인
