# MONEYFY Design System

이 문서가 MONEYFY 앱 UI/UX의 단일 기준 문서입니다.

통합일: 2026-05-29

기존에 흩어져 있던 `DESIGN.md`, `docs/design/getdesign_application_plan.md`, `docs/design/main_asset_card_format.md`, `docs/design/final_polish_pass.md`, `docs/design/ui_snapshot_targets.md`의 일반 디자인 규칙을 이 문서로 통합했습니다. 해당 legacy 디자인 문서는 삭제되었고, 기능별 화면 개편 계획은 각 feature 문서에 남깁니다. 새 화면이나 리팩터링 UI는 이 문서를 우선 기준으로 삼습니다.

## 1. Design Direction

MONEYFY는 투자와 자산 기록을 차분하게 읽는 금융 도구입니다. 시각 방향은 Apple-like minimal, financial calm, institutional trust를 섞되, 마케팅 사이트처럼 화려한 화면보다 반복 사용에 편한 앱 UI를 우선합니다.

Mobile-first 기준:

- 이 문서의 기본 판단 기준은 360~430dp 폭의 모바일 화면입니다.
- 넓은 화면/tablet/desktop-ish width는 모바일 규칙을 확장 적용합니다.
- 화면을 넓히기 위해 모바일 기준 typography를 viewport width로 키우지 않습니다.
- 모바일에서 한 화면에 많은 정보를 넣어야 할 때는 font 축소보다 row 구조, 접힘/펼침, dense component를 먼저 사용합니다.

핵심 무드:

- calm
- minimal
- trust
- whitespace
- restrained accent
- iOS feeling
- financial clarity

레퍼런스 적용 원칙:

| 레퍼런스 | 적용 | 피할 점 |
| --- | --- | --- |
| Apple | 표면 위계, SF Pro 감각, 여백, 낮은 chrome | 사진 중심 마케팅 tile, 과도한 대형 hero |
| Coinbase | 금융 row, 숫자 정렬, 자산/가격 셀 규율 | 새로운 브랜드 블루 추가, trading-heavy UI |
| Linear | 필터, 상태 chip, dense control, focus discipline | 보라색 accent, 개발도구 같은 어두운 기본 canvas |
| Revolut | 선택적 dark/premium emphasis | 다중 accent, 강한 gradient, 과도한 display type |

최종 방향:

- Base: MONEYFY의 Apple-like calm shell
- Financial data grammar: Coinbase-like row discipline
- Dense controls: Linear-like filter/status behavior
- Dark emphasis: Revolut-like special header only, sparingly

## 2. Source Of Truth

디자인 구현 기준 파일:

| 영역 | 파일 |
| --- | --- |
| Theme binding | `lib/design_system/app_theme.dart` |
| Context extensions | `lib/design_system/context_extensions.dart` |
| Typography roles | `lib/design_system/app_typography.dart` |
| Brand color roles | `lib/design_system/brand/brand_palette.dart` |
| Visual constants | `lib/design_system/spec/visual_spec.dart` |
| Spacing/radius/motion tokens | `lib/design_system/tokens.dart` |
| Page scaffold/insets | `lib/ui_scaffold/app_page_scaffold.dart`, `lib/ui_scaffold/app_insets.dart` |
| Cards/rows/chips/buttons/states | `lib/components/` |

새 UI에서는 다음을 우선 사용합니다.

- `context.spacing`
- `context.radius`
- `context.typography`
- `context.colors`
- `context.surfaces`
- `context.motion`
- `Theme.of(context).colorScheme`
- `VisualSpec` only for true spec constants
- reusable components in `lib/components/`

새 UI에서는 피합니다.

- 새 hard-coded hex color
- magic-number spacing/radius
- vivid positive/negative fill
- decorative gradients, orbs, bokeh, stock-like visual decoration
- repeated one-off row/card implementations when a component already exists

Token-to-code mapping:

| Design decision | Runtime token/API |
| --- | --- |
| Horizontal/page inset | `context.contentHorizontalPadding`, `AppInsets.pagePadding()` |
| Section/card gaps | `context.spacing.*`, `context.spacing.sectionGap` |
| Card padding | `context.cardPadding()`, `context.cardPadding(dense: true)` |
| Radius | `context.radius.*`, `VisualSpec.surface.radiusCard` |
| Text roles | `context.typography.*` |
| Semantic colors | `context.colors.*`, `context.surfaces.*` |
| Icon/progress/chart fixed specs | `VisualSpec.icon.*`, `VisualSpec.surface.*`, `VisualSpec.chart.*` |

## 3. Color Rules

Accent:

- Primary seed: `#0066CC`
- One primary accent only.
- Do not introduce a second brand blue or purple.

Neutral:

- Use Material surface roles: `surface`, `surfaceContainerLow`, `surfaceContainerHigh`, `surfaceContainerHighest`.
- Avoid ad-hoc gray values.
- Use surface levels, typography, spacing, and subtle borders for hierarchy before color.

Semantic movement:

- Positive/negative financial movement uses semantic text/container roles from `BrandColors`.
- Positive/negative states are functional, not decorative.
- Prefer colored text or low-tone chips over saturated red/green blocks.
- Delta text must include a sign when applicable.

Dark mode:

- Lower saturation for status containers.
- Use `surfaceContainerHigh/Highest` for subtle elevation.
- Avoid pure black as the default app surface except where platform/system context already provides it.
- Error UI should remain readable without vivid fills.

## 4. Token Rules

### Spacing

Use `context.spacing` only. Values below are the raw token values in `lib/design_system/tokens.dart`; some effective component values are responsive on mobile.

| Token | Value |
| --- | --- |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 24 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |
| `xxxl` | 80 |

Rules:

- Section gap: `context.spacing.sectionGap`.
- `md` and `lg` are currently both 24. Treat `md` as the default content/card padding token and `lg` as the semantic large-gap token.
- Card padding: `context.cardPadding()` or `context.cardPadding(dense: true)`.
- Effective mobile card padding:
  - `<=430dp`: 16
  - wider: 24
  - dense: 12
- Dense inner gaps may use `context.spacing.xs / 2`.
- Do not add duplicate page bottom padding.

### Insets

Use `AppPageScaffold` and `AppInsets.pagePadding()`.

Responsive horizontal inset:

| Width | Horizontal inset |
| --- | --- |
| `<=360dp` | 14 |
| `361~430dp` | 16 |
| wider | 24 |

Rules:

- General scroll pages: `AppPageScaffold` + `AppInsets.pagePadding()`.
- Form pages: `AppPageScaffold.form` with fixed bottom CTA and keyboard-safe inset.
- Bottom overlap prevention: `AppInsets.bottomContentInset()`.

### Radius

Use `context.radius` only.

| Token | Value |
| --- | --- |
| `rSm` | 8 |
| `rMd` | 11 |
| `rLg` | 18 |
| `rPill` | 9999 |

Cards use `VisualSpec.surface.radiusCard`.

### Motion

Use `context.motion`.

| Token | Intent |
| --- | --- |
| fast | 140ms |
| normal/base | 200ms |
| slow | 260ms |

Common use:

- Expand/collapse: `AnimatedSize` around 200ms, ease out.
- Conditional form fields: `AnimatedSwitcher` fast + `AnimatedSize` normal.
- Selection/hover/press: subtle fast surface or opacity transition.

## 5. Typography

Use `context.typography` roles only.

| Role | Spec |
| --- | --- |
| `pageTitle` | 34 / w600 / h1.10 / -0.28 |
| `heroNumber` | 40 / w600 / h1.10 / -0.28 / tabular figures |
| `sectionTitle` | 21 / w600 / h1.19 / 0.231 |
| `cardTitle` | 17 / w600 / h1.24 / -0.374 / tabular figures |
| `body` | 17 / w400 / h1.47 / -0.374 |
| `meta` | 14 / w400 / h1.43 / -0.224 / tabular figures |
| `caption` | 12 / w400 / h1.30 |
| `button` | 17 / w400 / h1.00 / -0.224 |

Role mapping:

| UI | Role |
| --- | --- |
| Page top title | `pageTitle` |
| Hero financial number | `heroNumber` |
| Section header | `sectionTitle` |
| Card/row title | `cardTitle` |
| Body explanation | `body` |
| Date, hint, count, subtitle | `meta` or `caption` |
| Button label | `button` |
| Chip/tag label | `meta`, max w500~w600 |

Mobile usage rules:

- `pageTitle` is for top-level mobile page titles only. Do not use it inside cards, sheets, compact panels, or repeated items.
- `heroNumber` is for the primary financial number in a summary/header area. Use it sparingly and wrap long amounts in a stable trailing/number slot.
- On 360dp screens, prefer `cardTitle`, `body`, `meta`, and `caption` for repeated rows and dense analysis content.
- If a long amount does not fit, scale the number inside its own slot with `FittedBox` or truncation strategy; do not reduce the global typography role.
- Do not create one-off `fontSize:` values. Add a token to `AppFontSizes` only when a repeated role genuinely needs it.

Financial numeric typography:

- Currency, quantity, rate, percentage, and count values use tabular figures.
- Amount/rate columns are right-aligned.
- Long financial values scale down inside their own trailing slot instead of resizing the parent row.
- Do not scale font size with viewport width.
- Letter spacing should come from typography roles, not ad-hoc per-widget values.

## 6. Surface And Card Rules

Default content card:

- Component: `SectionCard`
- Padding: `context.cardPadding()`
- Dense padding: `context.cardPadding(dense: true)`
- Radius: `VisualSpec.surface.radiusCard`
- Color: `VisualSpec.surface.cardBase`
- Border: `outlineVariant` through component defaults

Hero/header emphasis:

- Use `DetailHeaderCard`, `SectionCardVariant.raised`, or high container tone.
- Use sparingly for top summaries, not every section.

Do:

- Prefer restrained surface levels.
- Use `AppDivider` for in-card grouping.
- Keep cards as independent content units.

Do not:

- Put cards inside cards unless the inner card is a genuine repeated item or tool.
- Use decorative shadows or gradients to create hierarchy.
- Style every page section as a floating card if a full-width layout is clearer.

## 7. Components

### Buttons

Use `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, and `AppDestructiveButton`.

Rules:

- Height: 48.
- Radius: `rPill`.
- Horizontal padding: 24.
- Vertical padding: 12.
- Text: `context.typography.button`.
- Loading spinner: `VisualSpec.icon.progressIndicatorSize` / 20.
- Loading label width should stay fixed to avoid layout shift.
- Secondary uses tonal style.
- Destructive uses text/error tone.
- Press/hover/focus overlays use low-alpha state color.

### Chips

Use `DeltaChip`, `ImpactChips`, `ChoiceChip`, or local segmented controls based on intent.

Rules:

- Default chip min height: 24.
- Compact chip min height: 20.
- Pill radius: `rPill`.
- Delta sign must exist in text.
- Colors use semantic text/container roles only.
- Filter chips should not introduce a new accent family.

### Rows

Canonical row components:

| Use case | Component |
| --- | --- |
| Asset list | `AssetRow` |
| Transactions | `TransactionRow` |
| Snapshot | `SnapshotRow` |
| Settings | `SettingsActionRow` |
| Rebalance | `RebalanceRow` |
| Key-value metrics | `KeyValueRow` |
| Expand/collapse | `ExpandableTile` |

Row rules:

- Min height: 56~72.
- Leading icon badge default: 36, dense home asset rows may use 34.
- Icon size default: 24, dense/tiny support icon may use 20.
- Trailing amount is right-aligned.
- Subtitle uses `meta`.
- Tappable rows provide consistent ripple overlay.
- Trailing value slot should be stable and not shift the row.

### Icons

- Default icon size: 24.
- Icon button touch target: 48.
- Default color: `onSurfaceVariant`.
- Emphasis color: `primary`.
- Destructive color: `error`.
- Important icon actions must have `tooltip`.

## 8. State UI

Use section-level state first.

| State | Component |
| --- | --- |
| Loading | `SkeletonCard`, `SkeletonList` |
| Empty | `EmptyStateCard` |
| Error | `InlineError` + `RetryRow` |
| Success feedback | `SnackBar` |

Rules:

- Loading must preserve approximate layout shape.
- Empty states should explain why data is absent and what the user can do next.
- Error rows should offer retry where meaningful.
- Snackbar is secondary feedback, not a replacement for section-level error UI.

## 9. Page Patterns

### Scroll Pages

- Use `MoneyfyPage` or `AppPageScaffold`.
- Keep one page title.
- Keep section gap consistent.
- Do not duplicate page insets inside content.

### Financial Dashboards

Use this reading order:

1. Summary/cockpit: what happened?
2. Attribution: why did it happen?
3. Comparison/risk: was it good relative to a basis?
4. Trend/detail: where should the user inspect?
5. Excluded or supplementary flows: what should not be confused with performance?

### Analysis Pages

- Use dense controls only where they support repeated scanning.
- Prefer metric grids, compact rows, and low-tone chips.
- Do not make analysis pages look like marketing landing pages.
- Keep explanations short and close to the metric they clarify.

### Forms

- Use fixed bottom CTA pattern.
- Account for keyboard and safe area.
- Keep conditional fields animated and stable.
- Focus state uses one primary blue.

## 10. Main Asset Card Standard

This is a screen-specific standard for the Home asset card, kept here because it defines the app's primary mobile financial row grammar. General reusable rules should still live in sections 3~9 above.

Implementation file:

- `lib/pages/portfolio_dashboard_page.dart`

Layer structure:

1. Base plate
   - Background: `context.surfaces.surfaceRaised`
   - Radius: `VisualSpec.surface.radiusCard`
   - Shadow: `context.shadows.level3`
   - Padding: `context.cardPadding()`
2. Header
   - Left: `자산`
   - Right: sort button, divider, add asset button
3. Body card
   - `MoneyfySurfaceCard(variant: base, padding: EdgeInsets.zero)`

Sort options:

- `custom`: 기본순
- `profitRateDesc`: 수익률 높은순
- `profitRateAsc`: 수익률 낮은순
- `profitDesc`: 수익 높은순
- `profitAsc`: 수익 낮은순

Display rules:

- Visible asset: `isHidden == false`.
- Hidden asset: `isHidden == true`.
- If both visible and hidden assets exist, render a two-card stack.
- Hidden card first row is always an empty slot: `_HiddenAssetEmptySlot`.
- Overlap offset is based on `rowHeight(72)`.

Asset row format:

- Common component: `AssetRow`.
- Row height: 72.
- Leading slot: 46.
- Icon badge: 34 x 34.
- Icon size: 20.
- Right side:
  - amount text
  - non-cash profit amount + `DeltaChip(%)`
  - profit amount: `typography.caption`
  - return chip: `DeltaChip(compact: true)`
- Hidden row:
  - opacity: 0.6
  - blur: `ImageFilter.blur(sigmaX: 3.6, sigmaY: 3.6)`

Interactions:

- Reorder: `ReorderableDelayedDragStartListener`.
- Persist order: `AppDatabase.reorderAssets(assetIds)`.
- Swipe action: `Slidable` + `moneyfySingleSlideActionPane`.
- Action: hide / unhide.
- Hidden toggle: `AppDatabase.updateAssetHidden(id, !isHidden)`.
- After sort/hidden change, update local DB and call `SyncService.syncNow(...)` when possible.

States:

- Loading: `SkeletonList(rows: 4, rowHeight: 72, hasLeading: true, trailingLines: 2)`.
- Error: `InlineError + RetryRow`.
- Empty logged-in: `EmptyStateCard('자산이 아직 없어요')`.
- Empty logged-out: level-1 width + center alignment + CTA.

Must preserve:

- hidden empty slot + overlap calculation
- slide action + close on external tap
- optimistic drag reorder + failure rollback
- visible/hidden separated rendering

Documentation rule:

- If this section grows beyond the Home asset card's reusable grammar, move detailed implementation notes to a feature-specific document and keep only the common mobile card/row rules here.

## 11. Accessibility

- Minimum tap target: 48dp.
- Icon-only actions must have tooltip.
- Expand/collapse controls should expose semantics state where possible.
- Important numeric information must not be chart-only.
- Color must not be the only signal for gain/loss when surrounding text can clarify it.
- Text scale 1.3 must not cause incoherent overlap.

Representative tooltip/semantics targets:

1. Home sort menu: `정렬`
2. Home add asset: `자산 추가`
3. Refresh actions: `새로고침`
4. Home hidden toggle: `숨김/숨김 해제`
5. Calendar previous/next: `이전 달`, `다음 달`
6. ExpandableTile semantics: `확장됨/축소됨`

## 12. Gesture And Layout Collision Rules

- Reorderable + Slidable: disable `Slidable` during edit/reorder mode and expose drag handle only.
- Chart drag + page scroll: charts should restrict gesture intent and avoid hijacking vertical scroll.
- ExpandableTile: keep internal content `Column`-based to avoid nested scroll conflicts.
- Buttons, chips, labels, and financial values must not resize parent rows on hover/pressed/selection.
- Use stable dimensions for boards, grids, toolbars, counters, tiles, and trailing amount slots.

## 13. QA Checklist

Run static checks for touched UI files:

```bash
flutter analyze lib/design_system lib/components lib/pages
```

Focused UI smoke tests:

```bash
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

Visual QA:

- Check 360dp, 390dp, 430dp, tablet, and desktop-ish widths.
- Check light mode and selected dark-mode scenarios.
- Check text scale 1.0 and 1.3.
- Card and row horizontal alignment lines match.
- Trailing financial values align right and do not shift.
- Chips keep consistent height and padding.
- Loading/empty/error/success states are distinct.
- Bottom navigation, keyboard, and fixed CTAs do not overlap.
- Positive/negative states remain readable in light and dark mode.
- No new ad-hoc hex colors outside token files.

UI snapshot targets:

1. Home - data
2. Home - empty
3. Portfolio - default
4. Portfolio - target allocation sheet open
5. Analysis - default collapsed
6. Analysis - expanded tile
7. Stats - chart + selected month strip
8. Stats - calendar section
9. My - logged out
10. My - logged in
11. Detail - holding detail + transaction list
12. Form - cash transaction form with conditional exchange/transfer fields

Current regression setup:

- `test/ui_component_smoke_test.dart` provides widget-level smoke regression.
- Full page-level golden capture still needs deterministic fixture data and dedicated harnesses.

Suggested future golden command:

```bash
flutter test --update-goldens
flutter test
```

## 14. Legacy And Migration Rules

Legacy note:

- Page-level legacy palette/spacing/font-size guardrail is currently clean.
- `MoneyfyPalette` remains only as a theme bridge and deprecated compatibility dependency.
- `MoneyfySpacing` and `moneyfyValueColor` are deprecated compatibility APIs.
- `MoneyfySurfaceCard`, `MoneyfySectionCard`, and `moneyfySingleSlideActionPane` remain compatibility components until the remaining legacy page surfaces are retired.
- Do not remove legacy tokens in a risky big-bang refactor.
- New or refactored UI must not add new direct palette/hex/magic-number style code.

Migration rule for touched files:

- Prefer `context.colors`, `Theme.of(context).colorScheme`, `context.spacing`, `context.radius`, `context.typography`, `VisualSpec`, and component primitives.
- If touching a legacy screen, migrate only the local area needed for the task.
- Leave unrelated legacy styling alone unless it directly blocks consistency or correctness.

Track remaining legacy usage:

```bash
tools/check_design_token_guardrails.sh
```

The guardrail is reporting-only. It should become blocking only after the remaining compatibility exceptions are either migrated or explicitly allowed.

## 15. Feature-Specific Design Docs

Feature-specific design plans may remain separate when they describe product behavior or migration strategy rather than reusable UI rules.

Examples:

- `docs/design/transaction_ledger_redesign.md`
- `docs/design/transaction_history_ui_ux_improvement_plan.md`
- `docs/features/new_feature_development/**/plan.md`
- `docs/features/**/verification_test_plan.md`

When a feature-specific doc introduces a reusable design rule, move that rule back into this document.
