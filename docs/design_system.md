# MONEYFY UI Release Rules

## 0) Brand Mood Lock (Apple-like Minimal)
- Mood keywords: calm, minimal, trust, whitespace, restrained accent, iOS feeling.
- Accent policy: one accent only (`primary`), generated from fixed seed `#0A84FF`.
- Neutral policy: use `surface` + `surfaceContainerLow/High/Highest`, avoid ad-hoc gray values.
- Status policy: use toned-down container roles (`secondary/error/tertiary container`) instead of vivid neon colors.
- Hierarchy policy: prioritize typography + spacing + surface levels over color noise.

## 1) Tokens
- Spacing: `context.spacing` only (`xs=8, sm=12, md=16, lg=20, xl=24, xxl=28, xxxl=32`)
- Radius: `context.radius` only (`rSm=8, rMd=12, rLg=16, rPill=999`)
- Typography: `context.typography` roles only
- Motion: `context.motion` (`150~220ms`)

### Typography Scale (Fixed 8 Roles)
- `pageTitle`: 28 / w600 / h1.20
- `heroNumber`: 32 / w600 / h1.10
- `sectionTitle`: 18 / w600 / h1.25
- `cardTitle`: 16 / w500 / h1.25
- `body`: 16 / w400 / h1.35
- `meta`: 13 / w400 / h1.30
- `caption`: 12 / w400 / h1.30
- `button`: 15 / w600 / h1.00

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

## 2) Surface / Card Rules
- Default content card: `SectionCard`
  - padding `16` (`dense` uses `12`)
  - radius `rMd`
  - low elevation (0~1)
  - color: `surfaceContainerLow`
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
  - height `48`, radius `rMd`, horizontal padding `md(16)`, text `typography.button`
  - loading spinner `16`, label width fixed (`Stack + Opacity`) to avoid layout shift
  - secondary uses tonal style (`FilledButton.tonal`), destructive uses text/error tone
  - pressed/hover/focus overlays are unified with low-alpha state color
- Chips (`DeltaChip` / `ImpactChips`)
  - height `28`, pill radius `rPill`, horizontal padding `10`, typography `meta`
  - delta sign (`+/-`) must exist in text, colors use scheme containers only
- Rows (`Asset` / `Rebalance` / `Transaction` / `Snapshot` / `Settings`)
  - min row height `56~72`, right-aligned trailing values, subtitle uses `meta`
  - icon badge size `36`, icon size `24` (20 allowed for tiny supporting icon only)
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
