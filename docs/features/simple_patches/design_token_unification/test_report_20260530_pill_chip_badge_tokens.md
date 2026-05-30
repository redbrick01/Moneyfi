# Pill, Chip, Badge 토큰 구현 보고서

작성일: 2026-05-30

## 범위

스크린샷 기반 pill/chip/badge 정리 계획을 구현 가능한 공통 토큰 구조로 반영했다. 범위는 compact label UI로 제한했다.

포함:

- ticker badge
- transaction type badge
- filter chip
- metric/status pill
- `DeltaChip`
- `ImpactChips`

제외:

- bottom navigation selected capsule
- primary/secondary/destructive button shape
- search field
- icon button surface
- card, sheet, dialog radius
- chart geometry

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `docs/design/pill_chip_badge_token_plan.md` | 스크린샷 기반 현재 상태, 피드백, migration plan 문서화 |
| `lib/design_system/spec/visual_spec.dart` | `VisualSpec.pill` 치수 토큰 추가 |
| `lib/components/chips/moneyfy_pill.dart` | `MoneyfyPillStyle`, size/tone/variant enum, `MoneyfyBadge` 추가 |
| `lib/components/chips/delta_chip.dart` | signed delta 표시를 pill resolver 기반으로 전환 |
| `lib/components/chips/impact_chips.dart` | impact chip 색상, 치수, 테두리를 pill resolver 기반으로 전환 |
| `lib/components/rows/transaction_row.dart` | 거래 타입 badge를 `MoneyfyBadge`로 전환 |
| `lib/widgets/company_news_summary_card.dart` | ticker/importance badge를 `MoneyfyBadge`로 전환 |
| `lib/widgets/market_news_summary_card.dart` | importance/impact/assessment badge를 `MoneyfyBadge`로 전환 |
| `lib/pages/transactions_page.dart` | quick filter/sheet filter `RawChip` 스타일을 pill resolver로 정리 |
| `lib/pages/investment_performance_page.dart` | date/filter `ChoiceChip`, status pill, metric pill을 pill resolver로 정리 |
| `docs/README.md`, `docs/document_inventory.md` | 새 계획서 링크 추가 |

## 구현 메모

- `VisualSpec.pill`은 정적인 치수만 가진다.
- 색상, foreground, border, typography는 `MoneyfyPillStyle.resolve(BuildContext, ...)`에서 theme extension 기반으로 계산한다.
- `MoneyfyPillSize`는 `sm`, `md`, `lg`로 제한했다.
- `MoneyfyPillTone`은 `neutral`, `primary`, `success`, `danger`, `warning`으로 제한했다.
- `MoneyfyPillVariant`는 `soft`, `outline`, `selected`, `tonal`로 제한했다.
- `DeltaChip`의 public API는 유지했다.
- transaction filter의 `RawChip` 동작은 유지하고 visual style만 통일했다.
- investment performance의 `ChoiceChip` 동작은 유지하고 local wrapper로 visual style만 통일했다.

## 검증

실행:

```bash
flutter analyze lib/design_system/spec/visual_spec.dart lib/components/chips/moneyfy_pill.dart lib/components/chips/delta_chip.dart lib/components/chips/impact_chips.dart lib/components/rows/transaction_row.dart lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/transactions_page.dart lib/pages/investment_performance_page.dart
```

결과: 통과, issue 없음.

실행:

```bash
tools/check_design_token_guardrails.sh
```

결과: 통과, design token guardrail report clean.

실행:

```bash
flutter test test/ui_component_smoke_test.dart
```

결과: 통과, 7 tests.

## 남은 위험

- 이 patch에서는 screenshot golden diff를 실행하지 않았다.
- 일부 filter chip은 기존 compact 동작을 유지한다. 실제 기기 QA에서 touch target comfort를 확인해야 한다.
- `portfolio_analysis_mvp_page.dart`처럼 넓은 화면 파일에는 badge가 아닌 `rPill` 사용처가 남아 있다. control/surface radius pass가 필요할 때 별도 작업으로 다룬다.

## 후속 작업

- 거래 filter, 뉴스 badge, 투자성과 chip에 대한 집중 screenshot QA를 추가한다.
- 시각 parity 확인 후 shared interactive filter chip widget 도입을 검토한다.
- button/search/navigation capsule은 pill badge token으로 migration하지 않는 원칙을 유지한다.

## 후속 구현 2026-05-30

전수조사 후 남은 compact text badge를 `MoneyfyBadge`로 추가 연결했다. control, input, navigation, progress/gauge geometry는 계획대로 제외했다.

추가 전환:

| 파일 | 변경 |
| --- | --- |
| `lib/pages/asset_detail_page.dart` | `_HeroDashChip` placeholder를 `MoneyfyBadge`로 전환 |
| `lib/pages/holding_detail_page.dart` | `_HoldingHeroDashChip` placeholder를 `MoneyfyBadge`로 전환 |
| `lib/pages/cash_account_detail_page.dart` | `_CashHeroDashChip` placeholder를 `MoneyfyBadge`로 전환 |
| `lib/pages/portfolio_dashboard_page.dart` | `_SummaryDashChip`, USD/KRW metadata pill, dashboard risk badge, simple Material `Chip` label을 `MoneyfyBadge`로 전환 |
| `lib/components/rows/allocation_legend_row.dart` | ratio badge를 `MoneyfyBadge`로 전환 |
| `lib/components/rows/snapshot_row.dart` | inline percent badge를 `MoneyfyBadge`로 전환 |
| `lib/pages/analysis_page.dart` | change-rate badge를 `MoneyfyBadge`로 전환 |
| `lib/pages/portfolio_page.dart` | `_RiskBadge`를 `MoneyfyBadge`로 전환 |
| `lib/pages/dividend_interest_analysis_page.dart` | transaction type badge를 `MoneyfyBadge`로 전환 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | diagnosis/count/level text label badge만 `MoneyfyBadge`로 전환 |
| `docs/design/pill_chip_badge_token_plan.md` | 후속 감사표, 제외 대상, 실행 순서, 체크리스트 추가 |

제외 유지:

- bottom navigation capsule
- search/input field
- button shape와 filter button count bubble
- icon-only control
- progress bar
- gauge track과 threshold marker
- bottom sheet drag handle

후속 검증:

```bash
flutter analyze lib/components/rows/allocation_legend_row.dart lib/components/rows/snapshot_row.dart lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/analysis_page.dart lib/pages/dividend_interest_analysis_page.dart lib/pages/portfolio_analysis_mvp_page.dart
```

결과: 통과, issue 없음.

```bash
tools/check_design_token_guardrails.sh
```

결과: 통과, design token guardrail report clean.

```bash
flutter test test/ui_component_smoke_test.dart
```

결과: 통과, 7 tests.
