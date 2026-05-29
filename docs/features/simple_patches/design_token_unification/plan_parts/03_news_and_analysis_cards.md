# 03 News And Analysis Cards

## Goal

뉴스 요약 카드와 분석 entry 영역의 custom style을 디자인 시스템 기준으로 정리합니다. 이 영역은 직접 색상, 직접 font size, 직접 spacing이 많아 화면 인상 차이가 큰 편입니다.

## Target Files

- `lib/widgets/company_news_summary_card.dart`
- `lib/widgets/market_news_summary_card.dart`
- `lib/pages/analysis_page.dart`

## Replacement Rules

| Legacy | Replacement |
| --- | --- |
| direct card shell | `SectionCard` or `VisualSpec.surface.radiusCard` shell |
| severity vivid fills | semantic low-tone containers |
| `fontSize: 11/13/15/16/22` | `context.typography.caption/meta/cardTitle/sectionTitle` |
| direct padding 10/12/14/16 | `context.spacing.*` or `context.cardPadding()` |
| direct white/gray | `ColorScheme` or `context.colors` |

## Scope Boundaries

Keep:

- fetched data structure
- ranking/sorting logic
- summary text behavior
- card expansion/collapse behavior if present

Do not add:

- new chart
- new AI summarization behavior
- new network calls
- new filtering UX

## Visual Direction

- Cards should feel like calm financial summaries, not alert dashboards.
- Importance chips can use semantic color, but saturation must stay low.
- Long summary text should preserve scanability.
- Avoid nested cards unless each nested block is a real repeated item.

## Verification

Required:

```bash
flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/analysis_page.dart
flutter test test/page_walkthrough_test.dart
```

Recommended:

```bash
flutter test test/ui_component_smoke_test.dart
```

## Manual QA

- Analysis tab loads with market/company cards
- empty/no-news states remain readable
- importance/status chips are readable in light/dark mode
- no text overlap at 360dp and text scale 1.3
- card titles and section gaps match `docs/design_system.md`

## Acceptance Criteria

- no new direct colors or font sizes in touched card UI
- existing news content remains visible
- page walkthrough passes
