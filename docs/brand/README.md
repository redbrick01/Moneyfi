# Moneyfy Brand Palette

Updated: 2026-05-30

This folder stores palette artifacts generated during the icon color and app color audit. The implementation source remains the Flutter design system; this document records the human-readable brand decision.

## Current Palette

| Group | Token | Hex | Role |
| --- | --- | --- | --- |
| Core Brand | Primary | `#3A6DFF` | Main brand action, selected states, links, primary chart slice |
| Core Brand | Primary Active | `#2DA4FF` | Pressed/active brand state |
| Core Brand | Mint Accent | `#00E5B5` | Brand accent reference only; not currently a broad UI token |
| Core Brand | Deep Trust | `#1E293B` | Brand reference neutral; app UI currently uses `#0A0B0D` as ink |
| Semantic | Success | `#00D47E` | Positive returns and success states |
| Semantic | Warning | `#FFB800` | Attention state |
| Semantic | Error | `#FF4554` | Negative returns, validation error, destructive action |
| Soft System | Info Soft | `#E3F5FF` | Reference soft info surface; current app container is `#EEF0F3` unless promoted |
| Soft System | Mint Soft | `#E0FBF0` | Reference soft mint surface; current app avoids extra surface colors unless needed |

## Implementation Palette

| Token | Hex | Source |
| --- | --- | --- |
| `MoneyfyPalette.primary` | `#3A6DFF` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.primaryActive` | `#2DA4FF` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.success` | `#00D47E` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.warning` | `#FFB800` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.error` | `#FF4554` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.textPrimary` | `#0A0B0D` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.textSecondary` | `#5B616E` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.textTertiary` | `#7C828A` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.border` | `#DEE1E6` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.softNeutral` | `#EEF0F3` | `lib/theme/moneyfy_colors.dart` |
| `MoneyfyPalette.bgSurfaceMuted` | `#F7F7F7` | `lib/theme/moneyfy_colors.dart` |

## Artifacts

- `moneyfy_color_palette.svg`
- `moneyfy_color_palette.png`
- `moneyfy_current_app_color_audit.svg`
- `moneyfy_current_app_color_audit.png`
- `moneyfy_wordmark_weights.svg`
- `wordmark/moneyfy_wordmark_400.svg`
- `wordmark/moneyfy_wordmark_500.svg`
- `wordmark/moneyfy_wordmark_600.svg`
- `wordmark/moneyfy_wordmark_700.svg`

## Wordmark Drafts

The current text-logo exploration uses the exact text `Moneyfy`.

| Variant | Weight | Usage hypothesis |
| --- | ---: | --- |
| `moneyfy_wordmark_400.svg` | 400 | Quiet editorial mark, may be too light for small UI |
| `moneyfy_wordmark_500.svg` | 500 | Balanced app header candidate |
| `moneyfy_wordmark_600.svg` | 600 | Strong default brand candidate |
| `moneyfy_wordmark_700.svg` | 700 | Splash/app-store style candidate, may be heavy in navigation |

Color assignment is fixed across all variants:

- `M`: `#3A6DFF`
- `f`: `#00D47E`
- other letters: `#0A0B0D`

## Rules

- Primary and icon blue are unified. Do not create a separate app-wide `iconBlue` token.
- Reference colors such as mint accent, deep trust, info soft, and mint soft must be promoted through design review before becoming reusable app tokens.
- Chart and asset colors remain independent because category distinction needs more than the brand and semantic palette.
