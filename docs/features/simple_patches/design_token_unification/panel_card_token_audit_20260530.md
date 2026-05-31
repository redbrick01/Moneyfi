# Panel And Card Token Audit - 2026-05-30

## Scope

앱 화면에 보이는 카드/패널성 표면을 `lib/pages`, `lib/widgets`, `lib/components` 기준으로 전수 확인했다.

검사 대상:

- 공용 카드 컴포넌트: `SectionCard`, `MoneyfySurfaceCard`, `MoneyfySectionCard`, `StatusCard`, `DetailHeaderCard`
- 카드/패널처럼 보이는 직접 `Container` + `BoxDecoration`
- modal sheet/dialog/panel 표면
- 내부 metric tile, info panel, menu card, news tile처럼 카드 안에서 반복되는 소형 surface

제외 대상:

- 순수 icon badge, chart dot, progress marker, separator, skeleton primitive처럼 카드/패널이 아닌 장식/상태 원자
- design-system/theme 내부 토큰 정의 파일

## Static Check Summary

| Check | Result |
| --- | --- |
| `tools/check_design_token_guardrails.sh` | pass |
| `SectionCard`/`MoneyfySurfaceCard`/wrapper 사용처 | 91 matches |
| `BoxDecoration` 사용처 | 115 matches |
| `Color(0x...)` 또는 `Colors.*` outside design system/theme | 0 matches |
| 직접 numeric `BorderRadius.circular(...)` outside token/theme bridge | 5 app-surface candidates |

## Verdict

전체 카드/패널 표면은 토큰에 연결되어 있다. 신규 직접 색상, 직접 폰트, legacy palette/spacing 위반은 없다.

아래 직접 숫자 radius 잔여 예외는 후속 정리에서 `context.radius` 또는 `VisualSpec`로 치환했다.

## Canonical Components

| Component | Token connection | Status |
| --- | --- | --- |
| `SectionCard` | `VisualSpec.surface.cardBase/cardRaised`, `VisualSpec.surface.radiusCard`, `VisualSpec.surface.borderWidth`, `context.cardPadding()` | pass |
| `MoneyfySurfaceCard` | `SectionCard` wrapper | pass |
| `MoneyfySectionCard` | `MoneyfySurfaceCard` wrapper | pass |
| `StatusCard` | `SectionCardVariant.raised`, `context.spacing`, `context.radius.rMd`, `context.colors` | pass |
| `DetailHeaderCard` | `SectionCardVariant.raised`, `context.cardPadding()`, `context.typography.heroNumber` | pass |
| `EmptyStateCard` | `SectionCard` wrapper for standalone variant | pass |

## Large Surface Coverage

| Area | Representative files | Pattern | Status |
| --- | --- | --- | --- |
| Dashboard/home cards | `portfolio_dashboard_page.dart` | `MoneyfySurfaceCard`, `SectionCard`, direct base plates using `VisualSpec.surface.radiusCard`, `context.cardPadding`, `context.surfaces`, `context.shadows` | pass |
| Portfolio page cards | `portfolio_page.dart` | `SectionCard`; nested diagnosis blocks use `context.surfaces`, `context.radius`, `context.spacing` | pass |
| Transaction query/filter panels | `transactions_page.dart` | query panel uses `SectionCard`; sheets use theme surface + `context.radius.rLg`; option panels use theme/context tokens | pass |
| Statistics cards | `statistics_page.dart` | main sections use `SectionCard` or base plate with `VisualSpec.surface.radiusCard`; chart tooltip/legend use chart/context tokens | pass |
| Analysis hub cards | `analysis_page.dart` | `SectionCard`, `MoneyfySectionCard`, `MoneyfySurfaceCard`; empty panels use context tokens | pass |
| Annual analysis cards | `annual_asset_analysis_page.dart` | `MoneyfySurfaceCard`; inner panels use `context.colors`, `context.radius`, `context.spacing` | pass |
| Portfolio diagnosis MVP cards | `portfolio_analysis_mvp_page.dart` | section wrapper uses `SectionCard`; hero/metric/risk panels use context surface/radius/border tokens | pass |
| Investment performance cards | `investment_performance_page.dart` | main cards use `SectionCard`; metric tiles use context surface/radius/border tokens | pass |
| Dividend/interest cards | `dividend_interest_analysis_page.dart` | `_IncomeSectionCard` delegates to `SectionCard`; small transaction panels use context tokens | pass |
| Detail pages | `asset_detail_page.dart`, `holding_detail_page.dart`, `cash_account_detail_page.dart`, `snapshot_detail_page.dart` | main sections use `MoneyfySurfaceCard`, `MoneyfySectionCard`, `DetailHeaderCard`, or direct base plates with `VisualSpec.surface.radiusCard` | pass with minor numeric-radius cleanup |
| Auth/account cards | `login_page.dart`, `signup_page.dart`, `my_page.dart` | `SectionCard`, `StatusCard`, tokenized sheet/dialog surfaces | pass |
| News cards | `company_news_summary_card.dart`, `market_news_summary_card.dart` | direct card shells use `context.surfaces`, `VisualSpec.surface.radiusCard`, `context.cardPadding`, `context.shadows` | pass |
| Forms and sheets | `forms/form_design.dart`, form pages, `target_allocation_sheet.dart` | info/ledger panels and sheets use context color/radius/spacing tokens | pass |
| Sync overlay | `sync_overlay.dart` | overlay panel uses context color/radius/spacing tokens | pass |

## Direct Container Surfaces That Are Still Tokenized

These are not violations because they deliberately build specialized panels instead of using `SectionCard`, while still sourcing color, radius, spacing, and shadow from tokens.

| Surface | File | Token usage |
| --- | --- | --- |
| News summary shells and inner news tiles | `lib/widgets/company_news_summary_card.dart`, `lib/widgets/market_news_summary_card.dart` | `context.surfaces`, `VisualSpec.surface.radiusCard`, `context.cardPadding`, `context.shadows` |
| Dashboard/statistics section base plates | `lib/pages/portfolio_dashboard_page.dart`, `lib/pages/statistics_page.dart` | `context.surfaces.surfaceRaised`, `VisualSpec.surface.radiusCard`, `context.cardPadding`, `context.shadows.level3` |
| Detail page `_CardSection` variants | `lib/pages/asset_detail_page.dart`, `lib/pages/holding_detail_page.dart`, `lib/pages/cash_account_detail_page.dart` | `context.surfaces`, `VisualSpec.surface.radiusCard`, `context.cardPadding`, `context.shadows` |
| Metric/info/risk tiles | `investment_performance_page.dart`, `portfolio_analysis_mvp_page.dart`, `forms/form_design.dart` | `context.colors`, `context.radius.rMd/rLg`, `context.spacing`, token borders |
| Sheet containers and handles | `transactions_page.dart`, `forms/form_design.dart`, `target_allocation_sheet.dart` | `Theme/ColorScheme` surface, `context.radius.rLg/rPill`, `context.spacing` |

## Minor Cleanup Completed

| Priority | File | Lines | Issue | Suggested token |
| --- | --- | ---: | --- | --- |
| P3 | `lib/pages/snapshot_detail_page.dart` | 699, 1268 | embedded snapshot row used direct `12` radius | fixed: `context.radius.rMd` |
| P3 | `lib/pages/snapshot_detail_page.dart` | 1180 | row ink radius used direct `16` | fixed: `VisualSpec.surface.radiusCard` |
| P3 | `lib/pages/snapshot_detail_page.dart` | 1296 | symbol pill used direct `999` | fixed: `context.radius.rPill` |
| P3 | `lib/pages/statistics_page.dart` | 1159 | legend swatch used direct `4` radius | fixed: `context.radius.rSm / 2` |
| P3 | `lib/theme/moneyfy_theme.dart`, `lib/design_system/app_theme.dart` | theme bridge | pill radius uses direct `999/9999` | acceptable in theme bridge, but `context.radius.rPill` cannot be used there |

## Notes

- `BoxDecoration` count is high because many entries are small tokens-backed tiles, chart labels, handles, icon badges, and skeletons rather than independent cards.
- No direct app-level hex colors were found outside the design system/theme.
- Remaining direct pill radii in theme bridges are acceptable because `BuildContext` token extensions are not available there.
