# MONEYFY getdesign.md Application Plan

## 1. Current Design Grammar

MONEYFY is already close to an Apple-like, calm financial utility UI.

- Platform: Flutter + Material 3.
- Source of truth:
  - `DESIGN.md`: Apple-inspired analysis is already installed.
  - `docs/design_system.md`: local release rules.
  - `lib/design_system/spec/visual_spec.dart`: color, surface, chart, icon, motion constants.
  - `lib/design_system/app_theme.dart`: Material theme binding.
  - `lib/design_system/app_typography.dart`: typography roles.
  - `lib/components/*`: reusable cards, rows, buttons, chips, states.
- Mood: calm, minimal, trust, whitespace, restrained accent, iOS feeling.
- Palette:
  - Primary action blue: `#0066CC`.
  - Light app canvas: `#F5F5F7`.
  - Surface ladder: white, `#FAFAFC`, `#F0F0F0`.
  - Ink: `#1D1D1F`, secondary `#333333`, tertiary `#7A7A7A`.
  - Dark ladder: black plus `#252527`, `#272729`, `#2A2A2C`.
  - Semantic colors are present but should stay functional, not brand-like.
- Typography:
  - SF Pro Text / Display.
  - Small fixed role set: page title, hero number, section title, card title, body, meta, caption, button.
  - Numbers already use tabular figures in `AppTypography`.
- Shape and spacing:
  - Cards: 18px radius in `VisualSpec.surface.radiusCard`.
  - Sheets/dialogs: 18px.
  - Inputs: 11px/12px-ish radius depending on source.
  - Pill buttons and icon buttons use full radius.
  - Page spacing is compact mobile-first, with generous section gaps.
- Components:
  - `SectionCard` is the main card primitive.
  - `AssetRow`, `TransactionRow`, `KeyValueRow`, `MetricRow`, `DeltaChip`, `ImpactChips`, `EmptyStateCard`, `InlineError`, `RetryRow`, and skeletons form the product UI grammar.
  - Financial rows are right-aligned, fixed-height, and designed to avoid layout shifts.

## 2. Local Drift To Fix Before Adding New References

The codebase has a strong design direction, but some docs and implementation values disagree.

- `docs/design_system.md` says the accent seed is `#0A84FF`, while implementation and root `DESIGN.md` use `#0066CC`.
- `docs/design_system.md` lists smaller type roles (`pageTitle` 28, `heroNumber` 32), while `AppTypography` currently uses 34 and 40.
- `docs/design_system.md` says buttons use 48 height, radius `rMd`, typography 15/w600; `AppTheme` defaults to 44 height, pill radius, typography 17/w400.
- `AppRadius.standard()` defines `rMd = 11`, while docs say `rMd = 12`.
- Legacy `MoneyfyPalette` / `MoneyfySpacing` use is still widespread. This is acceptable as compatibility, but new UI should consume `context.*`, `VisualSpec`, and component primitives.

Before importing any new DESIGN.md, lock these discrepancies so future references do not cause churn.

## 3. getdesign.md Candidates

### Primary Reference: Coinbase

Use `Coinbase` as the main financial-product reference.

- Why it fits:
  - Clean blue identity and institutional financial trust.
  - One blue action color, white canvas, restrained gray surfaces.
  - Asset rows, price cells, semantic up/down values, and circular asset icons are directly relevant.
  - It recommends color-only positive/negative movement instead of filled red/green blocks, which matches MONEYFY's restraint.
- Apply:
  - Adopt the "institutional calm" row grammar for assets, holdings, transactions, and market/news tables.
  - Add or document a numeric style rule: all currency, quantity, rates, and percentages should use tabular figures.
  - Keep positive/negative as text or low-tone chips, not loud backgrounds.
  - Preserve one action blue; do not introduce Coinbase's exact blue as a second accent.
- Do not apply:
  - Full marketing hero bands.
  - Large 80px display type.
  - Licensed Coinbase fonts.

Suggested command if we want the raw reference later:

```sh
npx getdesign@latest add coinbase
```

### Existing Base Reference: Apple

Keep Apple as the base interaction and surface grammar.

- Why it fits:
  - MONEYFY already uses Apple-like colors, SF Pro, white/parchment surfaces, low chrome, pill actions, and calm hierarchy.
  - It keeps the app from becoming a loud trading dashboard.
- Apply:
  - Maintain the single blue interactive color.
  - Keep surface hierarchy subtle.
  - Continue using SF Pro and compact typographic roles.
  - Use dark surfaces only as occasional emphasis, not the default experience.
- Do not apply:
  - Photography-first marketing layouts.
  - Oversized product-tile sections.
  - Decorative product showcase patterns.

### Secondary Reference: Revolut

Use Revolut only for optional premium/dark emphasis screens.

- Why it fits:
  - Digital banking feel, precise fintech tone, strong dark-mode polish.
  - Useful for portfolio diagnosis, asset detail hero, or premium summary cards.
- Apply:
  - Borrow its dark surface ladder idea for specific hero/header cards.
  - Use color-blocked depth rather than drop shadows.
  - Consider one "featured insight" card style using dark surface inversion.
- Do not apply:
  - Saturated multi-accent palette.
  - Heavy gradients.
  - Oversized 80px+ marketing typography.

### Tertiary Reference: Linear

Use Linear as a density and state-control reference for operational screens.

- Why it fits:
  - Precise, minimal, data-friendly UI.
  - Strong status pill, filter chip, panel, and focus-ring behavior.
- Apply:
  - Filter/sort controls, status pills, segmented states, dense list panels.
  - Optional microcopy and label discipline for analysis pages.
- Do not apply:
  - Purple accent as brand color.
  - Near-black default canvas for the whole app.
  - Developer-tool visual language.

### Not Recommended As Core

- Wise: friendly money-transfer language is appealing, but vivid lime and heavy display type would fight MONEYFY's current Apple-blue, iOS-like identity.
- Stripe: gradients and lightweight premium marketing language would add unnecessary color/style drift.
- Binance/Kraken: too trading-floor/crypto-specific and visually louder than MONEYFY's trust-first app direction.

## 4. Application Strategy

### Phase 1. Token And Documentation Lock

Goal: make local design truth unambiguous before new styling work.

- Update `docs/design_system.md` to match implementation or intentionally change implementation to match docs.
- Decide final primary seed: keep `#0066CC` unless there is a product reason to move back to `#0A84FF`.
- Decide final radius scale: normalize `rMd` to 12 or update docs to 11.
- Decide final button grammar:
  - Product app default: 44 or 48 height.
  - Primary/secondary: pill or medium-radius.
  - Typography: 17/w400 Apple-like or 15-16/w600 app-control-like.
- Add a "financial numeric typography" rule:
  - Use tabular figures for all numeric financial values.
  - Right-align amount/rate columns.
  - Never let amount text resize parent rows.

### Phase 2. Component Contract Upgrade

Goal: encode selected Coinbase/Linear patterns into primitives.

- `AssetRow`
  - Keep current stable width calculations.
  - Document amount, delta, and subtitle slots as the canonical financial row pattern.
  - Ensure amount and percent use tabular figures and predictable trailing alignment.
- `DeltaChip`
  - Keep compact variant for dense rows.
  - Confirm positive/negative colors use semantic text/container roles only.
  - Avoid saturated fill unless representing strong error/success state.
- `SectionCard`
  - Keep low-border, no-shadow card behavior.
  - Consider explicit `financialTable` or `denseList` variant only if repeated layout pressure appears.
- Buttons
  - Decide whether app buttons follow Apple pill grammar or doc-stated 48/rMd grammar.
  - Keep loading label width fixed to prevent shift.
- Inputs
  - Keep 48dp-ish touch target.
  - Focus state should use one blue outline/ring.

### Phase 3. Screen-Level Application

Apply reference patterns where they naturally map to the product.

- Portfolio dashboard:
  - Keep Apple base and Coinbase asset-row discipline.
  - Reduce any ad-hoc color or custom spacing still using legacy palette where touched.
- Asset detail / holding detail:
  - Use Coinbase-style financial data rows and price-change text.
  - Optional dark header inversion only for one top summary area.
- Analysis pages:
  - Use Linear-like dense filter/status controls.
  - Convert ad-hoc status cards into reusable chip/metric rows where practical.
- News summary cards:
  - Avoid colorful severity blocks unless semantically necessary.
  - Use low-tone containers and consistent meta typography.
- Forms:
  - Keep Apple/M3 field calmness.
  - Use one focus blue and standardized bottom CTA behavior.

### Phase 4. Legacy Palette Retirement

Goal: prevent future style drift without forcing a risky big-bang refactor.

- Do not remove `MoneyfyPalette` immediately.
- For files touched during feature work, migrate local color/spacing calls to:
  - `Theme.of(context).colorScheme`
  - `context.spacing`
  - `context.radius`
  - `context.typography`
  - `VisualSpec` only for true spec constants.
- Track remaining legacy usage with:

```sh
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\." lib
```

### Phase 5. Verification

- Run analyzer for touched files:

```sh
flutter analyze lib/design_system lib/components lib/pages
```

- Run focused UI smoke tests:

```sh
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

- Visual QA checklist:
  - No overlapping text on 360dp, 390dp, 430dp, tablet, and desktop-ish widths.
  - Asset/transaction rows do not shift when values become long.
  - Positive/negative states remain readable in light and dark mode.
  - Buttons and icon actions meet 48dp effective touch target.
  - No new ad-hoc hex colors outside token files.

## 5. Recommended Final Direction

Use this blend:

- Base: Apple-inspired MONEYFY system already present.
- Financial trust and row grammar: Coinbase.
- Dark/premium emphasis: Revolut, sparingly.
- Dense controls/status: Linear, sparingly.

The best design outcome is not a new imported theme. It is MONEYFY's existing calm Apple-like shell, upgraded with Coinbase-grade financial data discipline.

