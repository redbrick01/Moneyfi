# Moneyfy Design System

Updated: 2026-11-21

This is the entry point for Moneyfy UI policy and implementation. The Dart sources below own the runtime values. Update the relevant source, any public usage guidance in this document, and the platform metadata that consumes the changed value in the same change. Brand artwork and historical reports provide context.

## Direction

Moneyfy should feel like a calm personal finance product: white canvas, restrained dividers, clear financial hierarchy, and a fresh blue brand accent. The UI should stay dense enough for repeated portfolio work, but it should not become visually noisy through many unrelated colors.

Key principles:

- Primary brand color is icon blue, normalized to `#3A6DFF`.
- Color should communicate role first: brand, semantic state, neutral surface, chart category, or asset identity.
- Financial up/down semantics are text or icon accents, not filled warning cards.
- Most screens use white surfaces and quiet borders; heavy shadows and decorative gradients are avoided.
- Typography uses SUIT through app tokens. Direct font families, font weights, and page-level font sizes should not be introduced.
- Review dense layouts at 360, 390, and 430 logical pixels. Include text scale 1.3 and long Korean labels.

## Token Sources

| Area | Definition | Use in app UI |
| --- | --- | --- |
| Color roles and theme | [VisualSpec](../lib/design_system/spec/visual_spec.dart), [AppTheme](../lib/design_system/app_theme.dart), [BrandColors](../lib/design_system/brand/brand_palette.dart) | `context.colors`, `context.surfaces`, `Theme.of(context).colorScheme` |
| Typography and font registration | [AppTypography](../lib/design_system/app_typography.dart), [AppFontFamilies](../lib/design_system/font_families.dart), [AppFontWeights](../lib/design_system/font_weights.dart), [pubspec.yaml](../pubspec.yaml) | `context.typography`, Material text styles, `AppFontWeights` |
| Spacing, radius, card widths, elevation and shadows | [Theme extensions](../lib/design_system/tokens.dart), [VisualSpec.surface](../lib/design_system/spec/visual_spec.dart) | `context.spacing`, `context.radius`, `context.cardPadding()`, `context.contentHorizontalPadding` |
| Icons, interaction and motion | [VisualSpec.icon and motion](../lib/design_system/spec/visual_spec.dart) | [AppIcon and AppIconButton](../lib/components/icons), `context.motion` |
| Charts | [VisualSpec.chart](../lib/design_system/spec/visual_spec.dart), [MoneyfyChartPalette](../lib/design_system/chart_palette.dart) | Asset identity colors, allocation rank colors, and chart markers |
| Shared components and forms | [Components](../lib/components), [Form components](../lib/components/forms/form_design.dart), [Page scaffolds](../lib/ui_scaffold) | Reuse the matching component below |
| Layout and shell navigation | [AppInsets](../lib/ui_scaffold/app_insets.dart), [AppShellPage](../lib/features/shell/screens/app_shell_page.dart) | Safe area, content padding, and floating navigation |
| Reusable copy | [CopySpec](../lib/design_system/spec/copy_spec.dart) | Shared labels where defined |
| Platform assets | [Assets](../assets/README.md), [Web manifest](../web/manifest.json) | Native icons, launch assets, and installed web app metadata |

[Context extensions](../lib/design_system/context_extensions.dart) expose the registered theme tokens. [The app entry point](../lib/main.dart) currently selects the light theme. `AppTheme.dark` defines separate surface and text roles for dark-theme widget coverage.

## Brand Palette

| Token | Hex | Role |
| --- | --- | --- |
| Brand blue | `#3A6DFF` | Actions, links, light selection labels, web manifest, price chart, and first allocation slice |
| Brand red | `#E93A51` | Coral for losses, withdrawals, errors, destructive actions, and chart markers |
| Selection surface (light) | `#EBF0FF` | Selected pills, filters, and form choices |
| Selection surface and text (dark) | `#263861` / `#FFFFFF` | Selected pills and choices |
| On Primary | `#FFFFFF` | Text or icon on brand-blue fills |
| Warning fill | `#FFB800` | Bright warning surface paired with dark text |
| Success foreground (light / dark) | `#3A6DFF` / `#3A6DFF` | Blue for positive amounts, returns, and success |
| Warning foreground (light / dark) | `#9A4C06` / `#FFAA65` | Orange for warning text and icons |
| Primary text (light / dark) | `#111111` / `#FFFFFF` | Headlines, body text, and ordinary amounts |
| Secondary text (light / dark) | `#595959` / `#ADADAD` | Captions, labels, and metadata |
| Border | `#DEE1E6` | Default divider and outline |
| Soft Neutral | `#EEF0F3` | Subtle container, status container, icon plate |
| Surface Muted | `#F7F7F7` | Low-emphasis background band |
| Canvas | `#FFFFFF` | App background and card base |

See [brand artwork and palette references](brand/README.md) and the [pill reference sheet](design/pill_token_samples.svg).

## Color Rules

### Brand

- Use `ColorScheme.primary` or `context.colors.primary` for actions and links.
- Use the primary container and on-container pair for selection fills and labels.
- The brand seed is the source for the Material scheme, web metadata, and the main price series.

### Semantic State

- Use success, warning, and error tokens only for state communication.
- Success: positive returns, completed states, confirmation indicators.
- Warning: attention or review-needed states.
- Error: destructive actions, validation errors, negative returns.
- Semantic colors should usually appear as text, icon, border, or small accent. Avoid large filled cards unless the surface is intentionally a status container.

### Surface and Text

- Default page and card surfaces are white.
- Use `#F7F7F7` for low-emphasis bands or background sections.
- Use `#EEF0F3` for subtle containers, icon plates, and soft status containers.
- Use `#DEE1E6` for borders and dividers.
- Headings, headline figures and body text share the achromatic `onSurface` role. Captions and metadata use the gray `onSurfaceVariant` role.
- Selection and state labels use blue, coral, or orange from the product palette. Orange text uses a darker shade than its chart swatch. Exact brand blue text has 4.36:1 contrast on white and a lower ratio on tinted surfaces. Preserve the selection mark and signed amount alongside the color. Disabled states resolve opacity in the shared component.

### Chart and Asset Identity

- Reusable chart palettes are allowed because asset/category distinction needs more colors than the brand palette.
- Asset type colors are role-locked in `MoneyfyChartPalette.assetColors`.
- Individual asset colors may be derived from deterministic seeds through `MoneyfyChartPalette.colorForAsset`.
- Allocation shows up to six named slices in rank order. Remaining positions share the slate `#6A7A99` slice labeled 기타, and the full legend preserves individual access.
- The ranked palette uses blue `#3A6DFF`, orange `#DB6502`, violet `#9251EA`, green `#03A14A`, magenta `#C542AF`, and teal `#04A19B`. Individual asset colors also use brand red `#E93A51`.
- Transaction type badges use the neutral pill style. External deposits and withdrawals use the positive and negative foregrounds on the amount.
- Calendar pivot-day labels use the primary color and bold type. Price chart markers pair buy triangles, sell squares, and dividend circles with matching shapes in the selected-date labels.
- Positive and negative performance contributions use their semantic foreground for both the dot and the signed amount.

## Typography

Moneyfy uses SUIT for display, body, button, and numeric roles.

| Token | Family | Size | Weight | Line Height | Role |
| --- | --- | ---: | --- | ---: | --- |
| `pageTitle` | SUIT | 32 | regular | 1.12 | Page titles |
| `heroNumber` | SUIT | 36 | medium | 1.10 | Main financial number with tabular figures |
| `sectionTitle` | SUIT | 18 | semibold | 1.30 | Section headers |
| `cardTitle` | SUIT | 16 | semibold | 1.35 | Card and row title |
| `body` | SUIT | 16 | regular | 1.50 | Default body |
| `meta` | SUIT | 14 | regular | 1.43 | Metadata and helper text |
| `caption` | SUIT | 13 | regular | 1.30 | Compact labels |
| `button` | SUIT | 16 | semibold | 1.00 | Button labels |

Font tokens:

| Token | Value |
| --- | --- |
| `AppFontFamilies.sans` | `SUIT` |
| `AppFontFamilies.display` | `SUIT` |
| `AppFontFamilies.mono` | `SUIT` |
| `AppFontWeights.regular` | `FontWeight.w400` |
| `AppFontWeights.medium` | `FontWeight.w500` |
| `AppFontWeights.semibold` | `FontWeight.w600` |
| `AppFontWeights.bold` | `FontWeight.w700` |

Typography rules:

- Use `context.typography` or theme text styles for screen UI.
- Use `context.fontSizes` only when a reusable typography token does not fit.
- Use `AppFontWeights` instead of direct `FontWeight.w...`.
- Do not reference `.SF Pro`, Roboto, AppleSDGothic, Pretendard, or Noto directly in app UI.
- Letter spacing is `0` unless a specific token defines otherwise.
- Financial numbers should use tabular figures where available.

## Spacing and Surfaces

| Token | Value | Role |
| --- | ---: | --- |
| `xs` | 8 | Compact gaps |
| `sm` | 12 | Small internal spacing |
| `md` | 20 | Default card/content rhythm |
| `lg` | 24 | Page and grouped spacing |
| `xl` / `sectionGap` | 32 | Section separation |
| `xxl` | 48 | Large vertical separation |
| `xxxl` | 96 | Rare major separation |
| `pageTop` | 24 | Page top inset |
| `pageBottomInset` | 132 | Base inset used by `MoneyfyPage` and floating snackbars |

Responsive horizontal padding:

| Width | Padding |
| ---: | ---: |
| `<= 360dp` | 14 |
| `<= 430dp` | 16 |
| `> 430dp` | 24 |

Page padding via `AppInsets` adds system safe area, a 12dp default gap, and 72dp on pages with floating navigation. The shell uses the same navigation height.

Surface rules:

- Cards use `VisualSpec.surface.radiusCard` (`16`) unless a component has a documented reason.
- Sheets and dialogs use `VisualSpec.surface.radiusSheet` (`24`).
- Normal card padding is 16dp at widths up to 430dp and 20dp above 430dp. Dense card padding is 12dp.
- `SectionCard` uses the base or raised theme surface. In light theme these are `#F7F7F7` and `#EEF0F3`. Overlay surfaces use white.
- Rows should keep stable heights and avoid text overlap at 360dp and text scale 1.3.

## Component Rules

| Area | Standard implementation | Behavior |
| --- | --- | --- |
| Page layout | [AppPageScaffold](../lib/ui_scaffold/app_page_scaffold.dart), [MoneyfyPage](../lib/widgets/moneyfy_ui.dart) | Use `AppPageScaffold` for standard pages, with shared headers and insets. Existing analysis and detail pages also use `MoneyfyPage`. |
| Actions | [App buttons](../lib/components/buttons/app_buttons.dart) | Primary uses brand fill, secondary uses a neutral surface with a primary outline, and destructive uses error text. The shared button minimum height is 48dp. Plain theme-filled and outlined controls have a 44dp minimum visual height. |
| Edit forms | [MoneyfyFormScaffold, MoneyfyFormSection and selection controls](../lib/components/forms/form_design.dart) | Asset, holding, cash-account and transaction forms share input decoration, a keyboard-aware layout, and a fixed save action using `AppPrimaryButton`. |
| Cards and panels | [SectionCard](../lib/components/section_card.dart), [AppInnerPanel and AppSheetSurface](../lib/components/panels) | Choose base, raised, or outline by visual hierarchy. Use the shared sheet wrapper for modal surfaces. |
| Headers and financial rows | [SectionHeader](../lib/components/section_header.dart), [Rows](../lib/components/rows), [Metrics](../lib/components/metrics) | Keep leading identity and trailing numbers legible at narrow widths. Use tabular figures. |
| Pills and badges | [MoneyfyBadge and MoneyfyPillStyle](../lib/components/chips/moneyfy_pill.dart) | Sizes are 28, 32, and 36dp. Semantic accents are resolved by variant. |
| Feedback and empty states | [States](../lib/components/states), [AppSnackBar](../lib/components/feedback/app_snackbar.dart) | Use token colors for loading, empty, validation, and retry states. |
| News and research | [Shared news and research cards](../lib/widgets) | Preserve wrapping for long Korean titles and body copy. |
| Charts | [Chart spec](../lib/design_system/spec/visual_spec.dart) and [allocation legend](../lib/components/rows/allocation_legend_row.dart) | Tokenize recurring color and geometry. Per-chart axes, label placement, and data-dependent dimensions live with the feature. |

## Platform Assets

- Launcher and launch-screen assets belong to the platform that packages them. See the [iOS asset catalog](../ios/Runner/Assets.xcassets), [macOS asset catalog](../macos/Runner/Assets.xcassets), and [Android resources](../android/app/src/main/res).
- Keep the [web manifest](../web/manifest.json) synchronized with the brand seed and light canvas. The component smoke test compares both values with the Dart sources.

## Verification

Run the design checks and focused widget tests when changing shared UI.

```bash
tools/check_design_token_guardrails.sh --self-test
tools/check_design_token_guardrails.sh
flutter analyze
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
flutter test test/news_report_layout_test.dart test/holding_transaction_history_test.dart
```

[Flutter CI](../.github/workflows/flutter-ci.yml) fails on direct color definitions, unthemed palettes, direct font sizes, families and weights, removed token names, and common leading `EdgeInsets` spacing literals in app code. The check scans Dart source patterns. Review other literal dimensions by their role, especially component-local hit areas, icon geometry, and chart coordinates. Use shared tokens for recurring values that have the same purpose.

Use the widget tests for layout and behavior. The holding transaction history test exercises 360, 390, and 430dp at text scale 1.3. Native keyboard appearance, launch assets, and pixel-level comparison are manual checks.

## Audit Findings

| Difference found | Resolution |
| --- | --- |
| Legacy theme and palette duplicated active color and type definitions | Removed the unused theme, palette, spacing and signed-value APIs. Moved the still-used asset identity palette into the design system. |
| Transaction badge colors and one text weight bypassed the tokens | Standardized transaction badges on the neutral pill and switched the weight to `AppFontWeights.semibold`. |
| Statistics used Flutter's default light palette and an empty-series black | The total and fallback colors now come from the Moneyfy palette. |
| Card variants bypassed the registered surface roles. Documentation presented white as the base card color. | Cards now read `context.surfaces`. This document lists the active light-theme surfaces. |
| Shared edit forms set save-button size, shape and type locally | Forms now share the primary button with other app UI. |
| Common padding was repeated in snapshot rows and swipe actions | Snapshot rows reuse spacing tokens and swipe actions share one padding definition. |
| Documentation merged the two page inset strategies and referenced a missing screenshot harness | Listed both active strategies and linked existing layout tests. |
| The guardrail printed warnings while CI continued | CI now enforces the same checked patterns as the script self-test. |
| The pill reference sheet depicted soft and tonal with the base surface | Updated the reference to the raised surface used by the resolver. |
