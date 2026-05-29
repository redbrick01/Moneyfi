# 04 Analysis Page Family

## Goal

분석 페이지 family의 카드, row, metric, legend, chip 문법을 통일합니다. Chart/canvas 내부 geometry는 예외로 두고, 주변 UI chrome을 우선 토큰화합니다.

## Target Files

- `lib/pages/annual_asset_analysis_page.dart`
- `lib/pages/portfolio_analysis_mvp_page.dart`
- `lib/pages/investment_performance_page.dart`
- `lib/pages/dividend_interest_analysis_page.dart`

## Target Example

`lib/pages/investment_performance_page.dart`를 우선 기준 샘플로 둡니다.

좋은 패턴:

- `SectionCard` 기반 섹션
- `context.colors`, `context.typography`, `context.spacing`
- metric grid와 row 내부 `FittedBox` 사용
- semantic positive/negative color helper
- chart bars는 계산 geometry와 UI token을 분리

## Replacement Rules

| Area | Rule |
| --- | --- |
| page sections | `SectionCard`, consistent `context.spacing.sectionGap` |
| metric rows | `context.typography.cardTitle/meta/caption` |
| chips | `context.radius.rPill`, semantic low-tone colors |
| chart labels | typography token, neutral text muted |
| chart containers | `VisualSpec.surface.radiusCard`, `context.cardPadding()` |
| direct `MoneyfyPalette` | context/colorScheme replacement unless compatibility helper is retained |

## Chart Exceptions

Allowed:

- painter coordinates
- axis tick counts
- canvas stroke widths when graph readability depends on exact value
- chart point radius if tied to selected/unselected geometry

Must tokenize:

- chart card shell
- legend row UI
- tooltip typography/container
- axis label text style
- empty/error/loading states around chart

## Verification

Required per touched page:

```bash
flutter analyze <touched analysis page>
flutter test test/page_walkthrough_test.dart
```

If chart painter behavior is touched:

```bash
flutter test test/portfolio_daily_returns_test.dart test/risk_adjusted_performance_calculator_test.dart
```

## Manual QA

- each analysis page builds
- charts are nonblank
- chart labels do not overlap at 360dp
- metric values remain right-aligned
- text scale 1.3 does not break cards
- dark mode status colors remain readable

## Acceptance Criteria

- analysis pages share section/card/metric/chip grammar
- calculation output is unchanged
- chart geometry exceptions are documented in test report
