# Feature Service Screen Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Organize the current Flutter app by feature so each screen, service, model, and supporting UI file has a clear service boundary.

**Architecture:** Keep shared infrastructure in `lib/db`, `lib/navigation`, `lib/design_system`, and `lib/components`, while introducing `lib/features/<feature>/` for feature-owned screens and services. Move files incrementally with compatibility exports when useful, update imports in small batches, and verify after each feature group.

**Tech Stack:** Flutter, Dart, Drift, Supabase Flutter, GoRouter, flutter_test.

---

## Target Feature Boundaries

| Feature | Screens | Services / Models | Notes |
| --- | --- | --- | --- |
| `auth` | `login_page.dart`, `signup_page.dart`, `startup_gate.dart` | `auth_service.dart`, `app_data_lifecycle_service.dart` | Owns session, login/signup, account bootstrap, data replacement flow. |
| `portfolio` | `portfolio_dashboard_page.dart`, `portfolio_page.dart`, `asset_detail_page.dart`, `holding_detail_page.dart`, `cash_account_detail_page.dart`, forms for asset/holding/cash account | `market_data_service.dart`, `portfolio_diagnosis_service.dart`, `asset_item.dart`, `market_snapshot.dart` | Owns the core asset/holding/account experience. |
| `transactions` | `transactions_page.dart`, `transaction_form_page.dart`, `cash_transaction_form_page.dart` | transaction-specific UI/data helpers currently embedded in pages | Owns transaction list and trade/cash transaction forms. |
| `analysis` | `analysis_page.dart`, `annual_asset_analysis_page.dart`, `dividend_interest_analysis_page.dart`, `portfolio_analysis_mvp_page.dart`, `investment_performance_page.dart`, `investment_review_page.dart`, `equity_research_page.dart`, `reddit_post_summaries_page.dart` | `benchmark_price_service.dart`, `equity_research_*`, `reddit_post_summary_service.dart`, `investment_performance/*`, `investment_review/*`, news summary services | Owns analytical screens, AI/news summaries, and research workflows. |
| `sync` | `sync_overlay.dart` | `sync_service.dart` | Owns local/remote sync orchestration. |
| `account` | `my_page.dart`, `statistics_page.dart` | account-level settings/summary helpers currently embedded in pages | Owns profile, account actions, and personal stats entry points. |
| `shell` | `app_shell_page.dart`, `target_allocation_sheet.dart` | none | Owns tab shell and app-level surfaces. |

Shared folders stay in place:

- `lib/db/`: Drift tables, generated files, migrations, and query helpers.
- `lib/navigation/`: Route names, paths, router, and navigation extensions.
- `lib/components/`: reusable visual components used by multiple features.
- `lib/design_system/`: theme, typography, tokens, and specs.
- `lib/data/`: static/shared seed data until a feature-specific owner is confirmed.

## Planned File Structure

```text
lib/
  features/
    account/
      screens/
      services/
    analysis/
      screens/
      services/
      services/investment_performance/
      services/investment_review/
    auth/
      screens/
      services/
    portfolio/
      models/
      screens/
      screens/forms/
      services/
    shell/
      screens/
    sync/
      screens/
      services/
    transactions/
      screens/
      screens/forms/
  components/
  db/
  design_system/
  navigation/
```

## Task 1: Write The Feature Inventory Document

**Files:**
- Create: `docs/features/screen_service_inventory.md`
- Modify: `lib/README.md`

- [ ] **Step 1: Create the screen/service inventory**

Create `docs/features/screen_service_inventory.md` with this structure:

```markdown
# Screen And Service Inventory

## Purpose

This document maps MONEYFY screens and services to feature ownership before files are moved into `lib/features`.

## Feature Map

| Feature | Current Files | New Owner Path | Responsibility |
| --- | --- | --- | --- |
| Auth | `lib/pages/login_page.dart`, `lib/pages/signup_page.dart`, `lib/pages/startup_gate.dart`, `lib/services/auth_service.dart`, `lib/services/app_data_lifecycle_service.dart` | `lib/features/auth/` | Authentication, session bootstrap, account data lifecycle. |
| Portfolio | `lib/pages/portfolio_dashboard_page.dart`, `lib/pages/portfolio_page.dart`, `lib/pages/asset_detail_page.dart`, `lib/pages/holding_detail_page.dart`, `lib/pages/cash_account_detail_page.dart`, `lib/pages/forms/asset_form_page.dart`, `lib/pages/forms/holding_form_page.dart`, `lib/pages/forms/cash_account_form_page.dart`, `lib/services/market_data_service.dart`, `lib/services/portfolio_diagnosis_service.dart`, `lib/models/asset_item.dart`, `lib/models/market_snapshot.dart` | `lib/features/portfolio/` | Portfolio dashboard, assets, holdings, cash accounts, market refresh, diagnosis. |
| Transactions | `lib/pages/transactions_page.dart`, `lib/pages/forms/transaction_form_page.dart`, `lib/pages/forms/cash_transaction_form_page.dart` | `lib/features/transactions/` | Transaction history and trade/cash transaction entry. |
| Analysis | `lib/pages/analysis_page.dart`, `lib/pages/annual_asset_analysis_page.dart`, `lib/pages/dividend_interest_analysis_page.dart`, `lib/pages/portfolio_analysis_mvp_page.dart`, `lib/pages/investment_performance_page.dart`, `lib/pages/investment_review_page.dart`, `lib/pages/equity_research_page.dart`, `lib/pages/reddit_post_summaries_page.dart`, `lib/services/benchmark_price_service.dart`, `lib/services/equity_research_metric_presenter.dart`, `lib/services/equity_research_service.dart`, `lib/services/reddit_post_summary_service.dart`, `lib/services/company_news_summary_service.dart`, `lib/services/market_news_summary_service.dart`, `lib/services/gpt_db_summary_builder.dart`, `lib/services/investment_performance/*`, `lib/services/investment_review/*` | `lib/features/analysis/` | Analysis hub, research, investment review, performance, news, and AI summaries. |
| Sync | `lib/pages/sync_overlay.dart`, `lib/services/sync_service.dart` | `lib/features/sync/` | Local-first sync and sync UI status. |
| Account | `lib/pages/my_page.dart`, `lib/pages/statistics_page.dart` | `lib/features/account/` | My page, settings actions, account-level stats. |
| Shell | `lib/pages/app_shell_page.dart`, `lib/pages/target_allocation_sheet.dart` | `lib/features/shell/` | Tab shell, lifecycle wiring, and app-level surfaces. |
```

- [ ] **Step 2: Update `lib/README.md`**

Add a short section pointing readers to `docs/features/screen_service_inventory.md` and naming `lib/features/<feature>` as the new owner for screen/service organization.

- [ ] **Step 3: Verify documentation**

Run:

```bash
test -f docs/features/screen_service_inventory.md
grep -n "lib/features" lib/README.md docs/features/screen_service_inventory.md
```

Expected: both files mention `lib/features`.

- [ ] **Step 4: Commit**

```bash
git add docs/features/screen_service_inventory.md lib/README.md
git commit -m "docs: map screens and services by feature"
```

## Task 2: Create Feature Folders And Move Auth + Sync First

**Files:**
- Create folders under `lib/features/auth` and `lib/features/sync`
- Move: `lib/pages/login_page.dart`
- Move: `lib/pages/signup_page.dart`
- Move: `lib/pages/startup_gate.dart`
- Move: `lib/pages/sync_overlay.dart`
- Move: `lib/services/auth_service.dart`
- Move: `lib/services/app_data_lifecycle_service.dart`
- Move: `lib/services/sync_service.dart`
- Modify imports in `lib/main.dart`, `lib/navigation/*`, `lib/pages/app_shell_page.dart`, and moved files.

- [ ] **Step 1: Move files**

```bash
mkdir -p lib/features/auth/screens lib/features/auth/services lib/features/sync/screens lib/features/sync/services
git mv lib/pages/login_page.dart lib/features/auth/screens/login_page.dart
git mv lib/pages/signup_page.dart lib/features/auth/screens/signup_page.dart
git mv lib/pages/startup_gate.dart lib/features/auth/screens/startup_gate.dart
git mv lib/pages/sync_overlay.dart lib/features/sync/screens/sync_overlay.dart
git mv lib/services/auth_service.dart lib/features/auth/services/auth_service.dart
git mv lib/services/app_data_lifecycle_service.dart lib/features/auth/services/app_data_lifecycle_service.dart
git mv lib/services/sync_service.dart lib/features/sync/services/sync_service.dart
```

- [ ] **Step 2: Update imports**

Replace old relative imports with package imports:

```dart
import 'package:moneyfy/features/auth/screens/login_page.dart';
import 'package:moneyfy/features/auth/screens/signup_page.dart';
import 'package:moneyfy/features/auth/screens/startup_gate.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';
import 'package:moneyfy/features/sync/screens/sync_overlay.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
```

Inside moved files, prefer package imports for shared infrastructure:

```dart
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
```

- [ ] **Step 3: Verify analysis**

Run:

```bash
flutter analyze
```

Expected: no missing import errors from the moved auth/sync files.

- [ ] **Step 4: Run focused tests**

```bash
flutter test test/profile_management_test.dart test/sync_overlay_test.dart test/snapshot_sync_contract_test.dart
```

Expected: all selected tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features lib/main.dart lib/navigation lib/pages test
git commit -m "refactor: move auth and sync into features"
```

## Task 3: Move Portfolio Screens, Models, And Services

**Files:**
- Move portfolio screens from `lib/pages`
- Move portfolio forms from `lib/pages/forms`
- Move `lib/models/asset_item.dart`
- Move `lib/models/market_snapshot.dart`
- Move `lib/services/market_data_service.dart`
- Move `lib/services/portfolio_diagnosis_service.dart`
- Modify route imports, screen imports, and tests.

- [ ] **Step 1: Move files**

```bash
mkdir -p lib/features/portfolio/screens/forms lib/features/portfolio/models lib/features/portfolio/services
git mv lib/pages/portfolio_dashboard_page.dart lib/features/portfolio/screens/portfolio_dashboard_page.dart
git mv lib/pages/portfolio_page.dart lib/features/portfolio/screens/portfolio_page.dart
git mv lib/pages/asset_detail_page.dart lib/features/portfolio/screens/asset_detail_page.dart
git mv lib/pages/holding_detail_page.dart lib/features/portfolio/screens/holding_detail_page.dart
git mv lib/pages/cash_account_detail_page.dart lib/features/portfolio/screens/cash_account_detail_page.dart
git mv lib/pages/forms/asset_form_page.dart lib/features/portfolio/screens/forms/asset_form_page.dart
git mv lib/pages/forms/holding_form_page.dart lib/features/portfolio/screens/forms/holding_form_page.dart
git mv lib/pages/forms/cash_account_form_page.dart lib/features/portfolio/screens/forms/cash_account_form_page.dart
git mv lib/models/asset_item.dart lib/features/portfolio/models/asset_item.dart
git mv lib/models/market_snapshot.dart lib/features/portfolio/models/market_snapshot.dart
git mv lib/services/market_data_service.dart lib/features/portfolio/services/market_data_service.dart
git mv lib/services/portfolio_diagnosis_service.dart lib/features/portfolio/services/portfolio_diagnosis_service.dart
```

- [ ] **Step 2: Update imports**

Use these canonical package imports:

```dart
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/models/market_snapshot.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_dashboard_page.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_page.dart';
import 'package:moneyfy/features/portfolio/screens/asset_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/cash_account_detail_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/asset_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/holding_form_page.dart';
import 'package:moneyfy/features/portfolio/screens/forms/cash_account_form_page.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/portfolio/services/portfolio_diagnosis_service.dart';
```

- [ ] **Step 3: Verify analysis**

```bash
flutter analyze
```

Expected: no missing import errors from portfolio files.

- [ ] **Step 4: Run focused tests**

```bash
flutter test test/asset_item_test.dart test/market_data_service_test.dart test/portfolio_allocation_color_test.dart test/portfolio_daily_returns_test.dart test/target_allocation_sheet_test.dart
```

Expected: all selected tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/portfolio lib/navigation lib/pages lib/components test
git commit -m "refactor: move portfolio into feature module"
```

## Task 4: Move Transactions

**Files:**
- Move: `lib/pages/transactions_page.dart`
- Move: `lib/pages/forms/transaction_form_page.dart`
- Move: `lib/pages/forms/cash_transaction_form_page.dart`
- Modify route imports and portfolio imports if forms depend on portfolio models/services.

- [ ] **Step 1: Move files**

```bash
mkdir -p lib/features/transactions/screens/forms
git mv lib/pages/transactions_page.dart lib/features/transactions/screens/transactions_page.dart
git mv lib/pages/forms/transaction_form_page.dart lib/features/transactions/screens/forms/transaction_form_page.dart
git mv lib/pages/forms/cash_transaction_form_page.dart lib/features/transactions/screens/forms/cash_transaction_form_page.dart
```

- [ ] **Step 2: Update imports**

Use these canonical package imports:

```dart
import 'package:moneyfy/features/transactions/screens/transactions_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/transaction_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
```

- [ ] **Step 3: Verify analysis**

```bash
flutter analyze
```

Expected: no missing import errors from transaction files.

- [ ] **Step 4: Run focused tests**

```bash
flutter test test/transaction_flow_test.dart
```

Expected: transaction flow tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions lib/navigation test
git commit -m "refactor: move transactions into feature module"
```

## Task 5: Move Analysis And Research Features

**Files:**
- Move analysis screens from `lib/pages`
- Move analysis services from `lib/services`
- Preserve existing `investment_review` and `investment_performance` subfolders under `lib/features/analysis/services`.

- [ ] **Step 1: Move files**

```bash
mkdir -p lib/features/analysis/screens lib/features/analysis/services
git mv lib/pages/analysis_page.dart lib/features/analysis/screens/analysis_page.dart
git mv lib/pages/annual_asset_analysis_page.dart lib/features/analysis/screens/annual_asset_analysis_page.dart
git mv lib/pages/dividend_interest_analysis_page.dart lib/features/analysis/screens/dividend_interest_analysis_page.dart
git mv lib/pages/portfolio_analysis_mvp_page.dart lib/features/analysis/screens/portfolio_analysis_mvp_page.dart
git mv lib/pages/investment_performance_page.dart lib/features/analysis/screens/investment_performance_page.dart
git mv lib/pages/investment_review_page.dart lib/features/analysis/screens/investment_review_page.dart
git mv lib/pages/equity_research_page.dart lib/features/analysis/screens/equity_research_page.dart
git mv lib/pages/reddit_post_summaries_page.dart lib/features/analysis/screens/reddit_post_summaries_page.dart
git mv lib/services/benchmark_price_service.dart lib/features/analysis/services/benchmark_price_service.dart
git mv lib/services/company_news_summary_service.dart lib/features/analysis/services/company_news_summary_service.dart
git mv lib/services/equity_research_metric_presenter.dart lib/features/analysis/services/equity_research_metric_presenter.dart
git mv lib/services/equity_research_service.dart lib/features/analysis/services/equity_research_service.dart
git mv lib/services/gpt_db_summary_builder.dart lib/features/analysis/services/gpt_db_summary_builder.dart
git mv lib/services/market_news_summary_service.dart lib/features/analysis/services/market_news_summary_service.dart
git mv lib/services/reddit_post_summary_service.dart lib/features/analysis/services/reddit_post_summary_service.dart
git mv lib/services/investment_performance lib/features/analysis/services/investment_performance
git mv lib/services/investment_review lib/features/analysis/services/investment_review
```

- [ ] **Step 2: Update imports**

Use these canonical package imports:

```dart
import 'package:moneyfy/features/analysis/screens/analysis_page.dart';
import 'package:moneyfy/features/analysis/screens/investment_review_page.dart';
import 'package:moneyfy/features/analysis/services/benchmark_price_service.dart';
import 'package:moneyfy/features/analysis/services/equity_research_service.dart';
import 'package:moneyfy/features/analysis/services/investment_review/daily_investment_review_repository.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_snapshot_builder.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
```

- [ ] **Step 3: Verify analysis**

```bash
flutter analyze
```

Expected: no missing import errors from analysis files.

- [ ] **Step 4: Run focused tests**

```bash
flutter test test/benchmark_data_test.dart test/daily_investment_review_presenter_test.dart test/daily_investment_review_repository_test.dart test/equity_research_metric_presenter_test.dart test/gpt_db_summary_builder_test.dart test/investment_performance_judgment_test.dart test/investment_review_ai_coach_test.dart test/investment_review_narrative_test.dart test/investment_review_periods_test.dart test/investment_review_snapshot_builder_test.dart test/news_report_layout_test.dart
```

Expected: all selected analysis tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/analysis lib/navigation test
git commit -m "refactor: move analysis into feature module"
```

## Task 6: Move Account And Shell Screens

**Files:**
- Move: `lib/pages/my_page.dart`
- Move: `lib/pages/statistics_page.dart`
- Move: `lib/pages/app_shell_page.dart`
- Move: `lib/pages/target_allocation_sheet.dart`
- Modify `lib/main.dart`, `lib/navigation/*`, and feature imports.

- [ ] **Step 1: Move files**

```bash
mkdir -p lib/features/account/screens lib/features/shell/screens
git mv lib/pages/my_page.dart lib/features/account/screens/my_page.dart
git mv lib/pages/statistics_page.dart lib/features/account/screens/statistics_page.dart
git mv lib/pages/app_shell_page.dart lib/features/shell/screens/app_shell_page.dart
git mv lib/pages/target_allocation_sheet.dart lib/features/shell/screens/target_allocation_sheet.dart
```

- [ ] **Step 2: Update imports**

Use these canonical package imports:

```dart
import 'package:moneyfy/features/account/screens/my_page.dart';
import 'package:moneyfy/features/account/screens/statistics_page.dart';
import 'package:moneyfy/features/shell/screens/app_shell_page.dart';
import 'package:moneyfy/features/shell/screens/target_allocation_sheet.dart';
```

- [ ] **Step 3: Verify analysis**

```bash
flutter analyze
```

Expected: no missing import errors from account or shell files.

- [ ] **Step 4: Run focused tests**

```bash
flutter test test/page_walkthrough_test.dart test/router_smoke_test.dart test/ui_component_smoke_test.dart
```

Expected: navigation and page smoke tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/account lib/features/shell lib/main.dart lib/navigation test
git commit -m "refactor: move account and shell screens into features"
```

## Task 7: Remove Empty Legacy Folders And Update Documentation

**Files:**
- Modify: `lib/README.md`
- Modify: `docs/folder_guide.md`
- Modify: `docs/project_overview.md`
- Modify: `docs/features/screen_service_inventory.md`
- Remove empty `lib/pages`, `lib/services`, and `lib/models` only if no files remain.

- [ ] **Step 1: Confirm legacy folders are empty**

```bash
find lib/pages lib/services lib/models -type f 2>/dev/null
```

Expected: no output, or only files intentionally retained as compatibility exports.

- [ ] **Step 2: Update documentation**

Update docs to describe:

```markdown
Feature-owned screens and services now live under `lib/features/<feature>/`.
Shared app infrastructure remains in `lib/db`, `lib/navigation`, `lib/components`, and `lib/design_system`.
```

- [ ] **Step 3: Run full verification**

```bash
flutter analyze
flutter test
```

Expected: analysis succeeds and all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib docs test
git commit -m "docs: describe feature-based app structure"
```

## Risk Controls

- Move one feature group at a time.
- Run `flutter analyze` after every group before moving the next one.
- Prefer package imports after moves to avoid fragile relative paths.
- Do not move `lib/db/app_database.g.dart`; it is generated and tightly coupled to Drift.
- Do not split large screen files during this pass unless required to fix imports. This plan is an ownership refactor, not a UI rewrite.
- Keep shared components in `lib/components` until a component is clearly used by only one feature.

## Final Verification

Run:

```bash
flutter analyze
flutter test
rg "package:moneyfy/pages|package:moneyfy/services|package:moneyfy/models|\\.\\./services|\\.\\./models|\\.\\./pages" lib test
```

Expected:

- `flutter analyze` passes.
- `flutter test` passes.
- The search command has no stale imports, except any intentionally retained compatibility export files.

## Self-Review

- Spec coverage: the plan covers document inventory, feature folder creation, screen moves, service moves, model moves, import updates, docs updates, and verification.
- Placeholder scan: no incomplete placeholder markers or open implementation placeholders remain.
- Type consistency: feature names and canonical paths are consistent across tasks.
