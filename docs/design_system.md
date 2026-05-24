# MONEYFY UI Release Rules

## 0) Brand Mood Lock (Apple-like Minimal + Financial Calm)
- Mood keywords: calm, minimal, trust, whitespace, restrained accent, iOS feeling.
- Accent policy: one accent only (`primary`), generated from fixed seed `#0066CC`.
- Neutral policy: use `surface` + `surfaceContainerLow/High/Highest`, avoid ad-hoc gray values.
- Status policy: use toned-down container roles (`secondary/error/tertiary container`) instead of vivid neon colors.
- Hierarchy policy: prioritize typography + spacing + surface levels over color noise.

## 1) Tokens
- Spacing: `context.spacing` only (`xs=8, sm=12, md=24, lg=24, xl=32, xxl=48, xxxl=80`)
- Responsive horizontal inset: `<=360dp` uses `14`, `361~430dp` uses `16`, wider screens use `24`
- Card padding: default `24`, dense `12`, mobile `<=430dp` uses `16`
- Radius: `context.radius` only (`rSm=8, rMd=11, rLg=18, rPill=9999`)
- Typography: `context.typography` roles only
- Motion: `context.motion` (`150~220ms`)

### Typography Scale (Fixed 8 Roles)
- `pageTitle`: 34 / w600 / h1.10 / -0.28
- `heroNumber`: 40 / w600 / h1.10 / -0.28 / tabular figures
- `sectionTitle`: 21 / w600 / h1.19 / 0.231
- `cardTitle`: 17 / w600 / h1.24 / -0.374 / tabular figures
- `body`: 17 / w400 / h1.47 / -0.374
- `meta`: 14 / w400 / h1.43 / -0.224 / tabular figures
- `caption`: 12 / w400 / h1.30
- `button`: 17 / w400 / h1.00 / -0.224

### Typography Role Mapping
- Page top title: `pageTitle`
- Section header title: `sectionTitle`
- Card inner title: `cardTitle`
- Body summary/description: `body`
- Date/update/model/hint/count: `meta` or `caption`
- Button label: `button`
- Chip/tag label: `meta` (`w500~w600` max)
- List row:
  - title: `cardTitle`
  - subtitle: `meta`
  - trailing amount: `cardTitle` (or stronger only when required)
  - trailing delta: `meta` + `DeltaChip`

### Financial Numeric Typography
- Currency, quantity, rate, percentage, and count values use tabular figures.
- Amount/rate columns are right-aligned.
- Long financial values scale down inside their own trailing slot instead of resizing the parent row.
- Positive/negative movement uses semantic text/container roles, never a second brand accent.

## 2) Surface / Card Rules
- Default content card: `SectionCard`
  - padding `24` (`dense` uses `12`, mobile card padding may resolve to `16`)
  - radius `18`
  - low elevation (0~1)
  - color: `VisualSpec.surface.cardBase`
- Hero / header emphasis: `DetailHeaderCard` or high container tone (`surfaceContainerHigh`)
- Border default: none. If needed: `outlineVariant` 1px only.
- Divider usage: `AppDivider` for in-card grouping only.

## 3) State Rules
- Loading: `SkeletonCard` / `SkeletonList`
- Empty: `EmptyStateCard`
- Error: `InlineError` + `RetryRow` (section-level first, snackbar is secondary)
- Success feedback: `SnackBar`

## 4) Insets / SafeArea
- Scroll pages: `AppPageScaffold` + `AppInsets.pagePadding()`
  - horizontal inset: `<=360dp` uses `14`, `361~430dp` uses `16`, wider screens use `24`
- Bottom overlap prevention: `AppInsets.bottomContentInset()`
- Form pages: `AppPageScaffold.form` with fixed bottom CTA and keyboard-safe inset
- Avoid duplicate bottom padding inside page content

## 5) Row Patterns
- Asset list: `AssetRow`
- Transactions: `TransactionRow`
- Expand/collapse content: `ExpandableTile`
- Key-value metrics: `KeyValueRow`

## 6) Component Finish Specs
- Buttons (`AppPrimaryButton` / `AppSecondaryButton` / `AppGhostButton` / `AppDestructiveButton`)
  - height `48`, radius `rPill`, horizontal padding `md(24)`, vertical padding `12`, text `typography.button`
  - loading spinner `16`, label width fixed (`Stack + Opacity`) to avoid layout shift
  - secondary uses tonal style (`FilledButton.tonal`), destructive uses text/error tone
  - pressed/hover/focus overlays are unified with low-alpha state color
- Chips (`DeltaChip` / `ImpactChips`)
  - min height `24`, pill radius `rPill`, horizontal padding `8`, vertical padding `4`, typography `meta`
  - `DeltaChip.compact` may be used in dense financial rows: min height `20`, horizontal padding `6`, vertical padding `2`, typography `caption`
  - delta sign (`+/-`) must exist in text, colors use `BrandColors` semantic text/container roles only
- Rows (`Asset` / `Rebalance` / `Transaction` / `Snapshot` / `Settings`)
  - min row height `56~72`, right-aligned trailing values, subtitle uses `meta`
  - icon badge size `36`, icon size `24` (20 allowed for tiny supporting icon only)
  - dense home asset rows may use icon badge `34`, icon `20`, and a narrowed leading slot `46`
  - tappable rows provide consistent ripple overlay (`WidgetStateProperty`)
- Icons
  - default icon size `24`, icon button touch target `48`
  - default color `onSurfaceVariant`, emphasis `primary`, destructive `error`

## 7) Accessibility Baseline
- Minimum tap target: 48dp
- Important icon actions must have `tooltip`
- Expand/collapse state should expose semantics where possible

## 8) Current Legacy Note
- Some legacy `MoneyfyPalette`/`MoneyfySpacing` usage still exists in old screens/widgets.
- New or refactored UI must not add new direct palette/hex/magic-number style code.
