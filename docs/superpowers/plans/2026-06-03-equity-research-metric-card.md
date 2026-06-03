# Equity Research Metric Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the equity research metric card readable on mobile by replacing raw database keys with user-facing labels, formatting values, and separating long text metrics from numeric tiles.

**Architecture:** Add a small presentation layer for `EquityResearchMetric` so formatting is testable outside widget internals. Keep the page responsible only for layout.

**Tech Stack:** Flutter, Dart, flutter_test.

---

### Task 1: Metric Presentation

**Files:**
- Create: `lib/services/equity_research_metric_presenter.dart`
- Create: `test/equity_research_metric_presenter_test.dart`

- [ ] Add failing tests for Korean labels, million-to-billion value formatting, percent formatting, and text-only metric classification.
- [ ] Implement `presentEquityResearchMetric`.

### Task 2: Metric Card Layout

**Files:**
- Modify: `lib/pages/equity_research_page.dart`

- [ ] Import the presenter.
- [ ] Render numeric metrics in a stable responsive two-column grid.
- [ ] Render text-only metrics as full-width panels below numeric metrics.
- [ ] Remove direct use of raw `metric.name` and `_metricValue`.

### Task 3: Verification

**Commands:**
- `dart format lib/services/equity_research_metric_presenter.dart lib/pages/equity_research_page.dart test/equity_research_metric_presenter_test.dart`
- `flutter test test/equity_research_metric_presenter_test.dart`
- `flutter analyze lib/pages/equity_research_page.dart lib/services/equity_research_service.dart lib/services/equity_research_metric_presenter.dart`
- `flutter test test/router_smoke_test.dart`
