# Pill, Chip, Badge Token Plan

Updated: 2026-05-30

This plan documents the current pill-like UI state observed from the 2026-05-30 app screenshots and maps it to reusable Moneyfy design tokens. It is a planning document, not an implementation report.

## Goal

Moneyfy already uses pill-shaped UI for compact metadata, transaction categories, filters, and financial deltas. The goal is to make those usages consistent without turning primary actions or dense financial rows into overly rounded decorative UI.

The token cleanup should:

- Preserve the current calm finance dashboard look.
- Reuse existing brand, semantic, surface, typography, spacing, and radius tokens.
- Separate non-interactive badges from interactive filter chips.
- Keep profit/loss semantics readable while avoiding large colored fills.
- Prevent one-off local `Container` styles for every pill-like element.

## Current State From Screenshots

### Overall Visual Language

| Area | Current Observation | Existing Token Anchor |
| --- | --- | --- |
| Primary accent | Clear blue used for selected bottom nav, selected chip, chart emphasis | `VisualSpec.brand.primary` / `#3A6DFF` |
| Positive state | Bright green for gains and positive percent | `VisualSpec.brand.lightPositive` / `#00D47E` |
| Negative state | Coral red for losses and negative percent | `VisualSpec.brand.lightNegative` / `#FF4554` |
| Neutral surface | White cards on very soft gray section surfaces | `lightSurface`, `lightSurfaceContainer` |
| Soft pill surface | Pale gray pill backgrounds | `lightSurfaceHigh` / `#EEF0F3` |
| Border | Quiet gray outline for cards, filters, dividers | `lightOutlineVariant` / `#DEE1E6` |
| Text hierarchy | Black primary text, gray secondary metadata | `lightTextPrimary`, `lightTextSecondary` |
| Radius | Cards are rounded, pills are fully rounded | `AppRadius.rPill`, `VisualSpec.surface.radiusCard` |

### Pill-Like Components In Use

| Component | Examples | Role | Current Behavior |
| --- | --- | --- | --- |
| Ticker badge | `IONQ`, `NVDA`, `BTC` | Short identity metadata in news rows | Soft neutral fill, dark text, no strong border |
| Transaction type badge | `이체`, `출금`, `매도` | Transaction category in ledger rows | Soft neutral fill, muted text, subtle border |
| Filter chip | `전체`, `매수`, `매도`, `배당`, `입출금` | Interactive quick filter | Selected state uses blue border/text; unselected uses neutral border/text |
| Metric pill | `+43.7%`, `-16.5%`, `51.4%` | Compact numeric state | Neutral fill with semantic text color |
| Delta chip | Signed currency or percent in detail/dashboard rows | Profit/loss state | Implemented in `lib/components/chips/delta_chip.dart` with semantic text and neutral/semantic container |
| Impact chip | Small insight labels with icon | Compact explanation metadata | Implemented in `lib/components/chips/impact_chips.dart` with neutral or secondary container |

## Proposed Token Model

Do not introduce a fully separate visual language for pills. Add a small component-level spec that composes the existing global tokens.

## Feedback Summary

The plan direction is sound, but implementation needs tighter scope control. `context.radius.rPill` is used by many controls that are not badges or chips, including icon button surfaces, bottom navigation, form controls, and app buttons. This plan should not try to migrate every `rPill` usage.

Actionable feedback:

- Scope migration to compact label components first: ticker badges, transaction type badges, filter chips, metric pills, `DeltaChip`, and `ImpactChips`.
- Explicitly exclude pill-shaped buttons, bottom navigation selected tabs, search fields, and icon surfaces from the first pass.
- Add a style resolver before adding new widgets, otherwise new wrappers may repeat the same local styling problem.
- Keep `RawChip` and `ChoiceChip` behavior stable in the first implementation pass; only align their color, shape, typography, padding, and selected state.
- Treat accessibility as a first-class requirement because several filter chips currently use compact visual density and shrink-wrapped tap targets.

### Component Families

| Family | Interactive | Primary Use | Should Share |
| --- | --- | --- | --- |
| `MoneyfyBadge` | No | Ticker, transaction type, status metadata | Pill radius, neutral surfaces, compact typography |
| `MoneyfyFilterChip` | Yes | Quick filters, sheet filters, choice filters | Pill radius, outline states, selected brand state |
| `MoneyfyMetricPill` | No | Percent, ratio, signed compact values | Pill radius, semantic foreground, neutral surface |
| `DeltaChip` | No | Signed financial deltas | Existing behavior, aligned to metric pill tokens |

### Out Of Scope For This Plan

| Area | Reason |
| --- | --- |
| Bottom navigation selected capsule | Navigation has separate interaction, size, and safe-area rules |
| Primary/secondary/destructive buttons | Button shape belongs to button tokens and tap-target rules |
| Search fields | Search is an input/control surface, not a chip or badge |
| Icon button surfaces | Icon-only controls need icon button specs, not pill label specs |
| Sheet/dialog/card radius | Larger surface radius should be reviewed separately |
| Chart legend dots and chart geometry | Chart visuals are governed by chart specs |

### Size Tokens

| Token | Height | Horizontal Padding | Typography | Use |
| --- | ---: | ---: | --- | --- |
| `pill.sm` | `28` | `12` | `caption` or compact `meta` | Ticker badge, transaction type badge |
| `pill.md` | `32` | `14` | `meta` | Metric pill, impact chip |
| `pill.lg` | `36` to `40` | `16` | `button` or `meta` semibold | Filter chip |

Notes:

- Radius should use `context.radius.rPill`.
- Text should remain one line with ellipsis only where the surrounding row already constrains width.
- Minimum tap target for interactive chips should be reviewed separately from visual height. If visual height is below 44dp, the surrounding touch target must still be comfortable.

### Tone Tokens

| Tone | Background | Foreground | Border | Use |
| --- | --- | --- | --- | --- |
| `neutral` | `neutralSurfaceBase` / `lightSurfaceHigh` | `neutralTextPrimary` or `neutralTextMuted` | optional `neutralOutline` | Tickers, transaction categories |
| `primary` | white or primary container | `primary` | `primary` | Selected filters |
| `success` | neutral or positive container | `positiveOn` | optional positive/neutral outline | Positive metric/delta |
| `danger` | neutral or negative container | `negativeOn` | optional negative/neutral outline | Negative metric/delta |
| `warning` | neutral or warning container | `warningOn` | optional warning/neutral outline | Review-needed badges |

Current screenshots favor neutral gray backgrounds with semantic text. Keep that as the default. Use tinted semantic containers only when a state needs extra emphasis.

### Variant Tokens

| Variant | Fill | Border | Intended Use |
| --- | --- | --- | --- |
| `soft` | Neutral soft fill | Transparent or very subtle outline | Non-interactive badges and metric pills |
| `outline` | White fill | Neutral outline | Unselected filter chips |
| `selected` | White fill | Primary outline | Selected filter chips |
| `tonal` | Semantic or primary container | Matching low-emphasis outline | Rare emphasized status |

## Implementation Shape

Preferred structure:

```dart
enum MoneyfyPillSize { sm, md, lg }
enum MoneyfyPillTone { neutral, primary, success, danger, warning }
enum MoneyfyPillVariant { soft, outline, selected, tonal }
```

Add one reusable style resolver before introducing more widgets:

```dart
class MoneyfyPillStyle {
  const MoneyfyPillStyle({
    required this.height,
    required this.padding,
    required this.background,
    required this.foreground,
    required this.border,
    required this.textStyle,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color foreground;
  final Color border;
  final TextStyle textStyle;
}
```

Recommended home:

- Size and radius constants: `lib/design_system/spec/visual_spec.dart` under a new pill/chip spec.
- Theme-aware color resolution: extension/helper near `lib/design_system/context_extensions.dart` or a new component helper.
- Reusable widgets: `lib/components/chips/` after the style resolver exists.

### Resolver Requirements

The resolver should accept:

- `BuildContext`, so it can read theme extensions and support dark mode.
- `MoneyfyPillSize`, `MoneyfyPillTone`, and `MoneyfyPillVariant`.
- A selected or disabled state for interactive chips.
- An optional compact flag only if it maps to named size tokens.

The resolver should return:

- Height, padding, shape radius, border width, background, foreground, border color, and text style.
- No raw hex values outside token/spec source files.
- No direct `FontWeight.w...`; use `AppFontWeights`.

Avoid a resolver that only returns colors. The current inconsistency is also about height, padding, font weight, and border emphasis.

### Accessibility Requirements

Interactive chips may keep a compact visual height, but their tap behavior must stay comfortable:

- Prefer Material's default tap target unless the surrounding layout supplies adequate hit area.
- If using `MaterialTapTargetSize.shrinkWrap`, document why the row remains usable.
- Selected chips should not rely on color alone; icon/checkmark or border/weight change should remain available.
- Labels must survive Korean text, 360dp width, and text scale 1.3.

## Migration Plan

### Phase 1: Document And Audit

- Use this document as the baseline.
- Audit current pill-like code paths with `rg "rPill|Chip|Badge|Pill|RawChip|ChoiceChip" lib`.
- Classify each usage as badge, filter chip, metric pill, delta chip, icon button surface, or unrelated rounded control.
- Produce a short migration list that separates in-scope and out-of-scope `rPill` usage.

### Phase 2: Add Specs Only

- Add pill size tokens and variant naming without changing screen behavior.
- Keep the existing `DeltaChip` API stable.
- Avoid replacing every call site in the same patch.
- Add tests only where a resolver has logic worth protecting; visual parity remains screenshot/manual QA.

### Phase 3: Migrate Shared Components

- Align `DeltaChip` and `ImpactChips` to the new size/variant resolver.
- Add a reusable non-interactive badge widget for ticker and transaction type labels.
- Add a reusable filter chip style or wrapper for quick filters and filter sheets.

### Phase 4: Screen Cleanup

- Migrate transaction page quick filters and transaction type badges.
- Migrate news ticker badges.
- Migrate portfolio metric pills.
- Remove one-off local pill `Container` styles after each screen has visual parity.

## First Migration Candidates

| Priority | File | Current Pattern | Target |
| ---: | --- | --- | --- |
| 1 | `lib/components/chips/delta_chip.dart` | Local size, padding, border, semantic color logic | Use metric pill style resolver while preserving public API |
| 2 | `lib/components/chips/impact_chips.dart` | Local impact chip dimensions and colors | Use `pill.md` neutral/primary soft styles |
| 3 | `lib/components/rows/transaction_row.dart` | Local transaction type badge container | Replace with `MoneyfyBadge` using `pill.sm` neutral |
| 4 | `lib/widgets/company_news_summary_card.dart` | Local ticker badge container | Replace with `MoneyfyBadge` using `pill.sm` neutral emphasis |
| 5 | `lib/widgets/market_news_summary_card.dart` | Local source/ticker pill containers | Replace with shared badge styles |
| 6 | `lib/pages/transactions_page.dart` | `RawChip` quick filters and sheet filters | Apply shared filter chip style without changing filter logic |
| 7 | `lib/pages/investment_performance_page.dart` | Local `_StatusPill`, `_MetricPill`, `ChoiceChip` | Migrate after shared resolver proves stable |

Defer broad files like `portfolio_analysis_mvp_page.dart` until the shared components are stable. That page has many `rPill` usages and is likely to mix badges, controls, and layout-specific rounded surfaces.

## Guardrails

- Use pill UI for tags, badges, short metadata, filters, and compact metrics only.
- Do not use pill styling as the default primary button shape for every command.
- Do not use chart palette colors for pill UI outside chart/legend context.
- Keep semantic green/red mostly as text, icon, border, or small chip foreground.
- Avoid large filled success/error surfaces for ordinary profit/loss rows.
- Check Korean text at 360dp width and text scale 1.3.
- Keep chip labels short; long text belongs in row body copy, not in a pill.

## Verification

Run after implementation changes:

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/design_system/spec/visual_spec.dart
flutter analyze lib/components/chips/delta_chip.dart
flutter analyze lib/pages/transactions_page.dart
flutter test test/design_md_screenshot_harness_test.dart
flutter test test/page_walkthrough_test.dart
```

Manual screenshot review should include:

- Portfolio dashboard total asset card and asset list.
- Portfolio allocation chart legend and percentage pills.
- Transaction search/filter area and transaction rows.
- Analysis/news cards with ticker badges.
- Bottom navigation overlap at 360dp, 390dp, and 430dp.

## Open Decisions

| Decision | Recommendation |
| --- | --- |
| Should positive/negative pills use tinted backgrounds? | Default to neutral backgrounds with semantic text; allow `tonal` for emphasized states. |
| Should ticker and transaction type badges share the same widget? | Yes, with different foreground emphasis. |
| Should `ChoiceChip` be replaced? | Not immediately. First standardize its theme/wrapper, then migrate call sites. |
| Should `rPill` stay `100` or become `999`? | Keep `rPill` as the single token. The exact number is less important than using one source. |
| Should card radius increase to match screenshots? | Treat separately. This plan only scopes pill/chip/badge tokens. |
| Should transaction filter chips keep shrink-wrapped tap targets? | Review during implementation. Prefer preserving layout while avoiding uncomfortable hit targets. |
