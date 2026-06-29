# Transactions Load More Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 20th-based period grouping for transactions with a load-more button.

**Architecture:** `TransactionsPage` keeps ownership of filtering and sorting, then derives visible 20th-based periods for rendering. Test-only asset injection keeps the widget test deterministic without changing production data loading.

**Tech Stack:** Flutter, Dart widget tests, existing MONEYFY UI components.

---

### Task 1: Add a Failing Widget Test

**Files:**
- Modify: `test/widget_test.dart`

- [ ] Add an import for `moneyfy/features/transactions/screens/transactions_page.dart`.
- [ ] Add a widget test that creates one asset with a holding containing five transactions through `AssetItem`/`HoldingItem` model objects.
- [ ] Use dates around the 20th boundary: 2026-06-20 through 2026-07-19 for the latest period, 2026-05-20 through 2026-06-19 for the older period, and 2026-05-19 for a still-hidden period.
- [ ] Pump `TransactionsPage` with `assetsFutureForTesting`.
- [ ] Expect the latest period label and its rows to be visible, the older period rows to be hidden, and the load-more button to read `이전 기간 더 보기`.
- [ ] Tap the button and expect the older period label and rows to become visible while the still-older period remains hidden.

### Task 2: Implement Paged Rendering

**Files:**
- Modify: `lib/features/transactions/screens/transactions_page.dart`

- [ ] Keep the constructor parameter for test asset injection.
- [ ] Add `_visiblePeriodLimit` state initialized to one visible period.
- [ ] Reset `_visiblePeriodLimit` when search/filter/sort data changes.
- [ ] Render only entries whose 20th-based period is included in the visible period set.
- [ ] Add a full-width `이전 기간 더 보기` button when hidden periods remain.

### Task 3: Add 20th-Based Period Headers

**Files:**
- Modify: `lib/features/transactions/screens/transactions_page.dart`

- [ ] Insert a compact period header before the first row of each 20th-based period.
- [ ] Format labels as `2026년 6월 20일 ~ 7월 19일`.
- [ ] Use existing theme typography and divider spacing.
- [ ] Keep row tap and delete behavior unchanged.

### Task 4: Verify

**Files:**
- Test: `test/widget_test.dart`

- [ ] Run `flutter test test/widget_test.dart`.
- [ ] Run `dart format lib/features/transactions/screens/transactions_page.dart test/widget_test.dart`.
