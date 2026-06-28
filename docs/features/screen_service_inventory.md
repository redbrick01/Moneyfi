# Screen And Service Inventory

## Purpose

This document maps MONEYFY screens and services to current feature ownership under `lib/features`.

## Feature Map

| Feature | Owned Files | Owner Path | Responsibility |
| --- | --- | --- | --- |
| Auth | `screens/login_page.dart`, `screens/signup_page.dart`, `screens/startup_gate.dart`, `services/auth_service.dart`, `services/app_data_lifecycle_service.dart` | `lib/features/auth/` | Authentication, session bootstrap, account data lifecycle. |
| Portfolio | `screens/portfolio_dashboard_page.dart`, `screens/portfolio_page.dart`, `screens/asset_detail_page.dart`, `screens/holding_detail_page.dart`, `screens/cash_account_detail_page.dart`, `screens/snapshot_detail_page.dart`, `screens/forms/asset_form_page.dart`, `screens/forms/holding_form_page.dart`, `screens/forms/cash_account_form_page.dart`, `services/market_data_service.dart`, `services/portfolio_diagnosis_service.dart`, `models/asset_item.dart`, `models/market_snapshot.dart` | `lib/features/portfolio/` | Portfolio dashboard, assets, holdings, cash accounts, snapshots, market refresh, diagnosis. |
| Transactions | `screens/transactions_page.dart`, `screens/forms/transaction_form_page.dart`, `screens/forms/cash_transaction_form_page.dart` | `lib/features/transactions/` | Transaction history and trade/cash transaction entry. |
| Analysis | `screens/analysis_page.dart`, `screens/annual_asset_analysis_page.dart`, `screens/dividend_interest_analysis_page.dart`, `screens/portfolio_analysis_mvp_page.dart`, `screens/investment_performance_page.dart`, `screens/investment_review_page.dart`, `screens/equity_research_page.dart`, `screens/reddit_post_summaries_page.dart`, `services/benchmark_price_service.dart`, `services/equity_research_metric_presenter.dart`, `services/equity_research_service.dart`, `services/reddit_post_summary_service.dart`, `services/company_news_summary_service.dart`, `services/market_news_summary_service.dart`, `services/gpt_db_summary_builder.dart`, `services/investment_performance/*`, `services/investment_review/*` | `lib/features/analysis/` | Analysis hub, research, investment review, performance, news, and AI summaries. |
| Sync | `screens/sync_overlay.dart`, `services/sync_service.dart` | `lib/features/sync/` | Local-first sync and sync UI status. |
| Account | `screens/my_page.dart`, `screens/statistics_page.dart` | `lib/features/account/` | My page, settings actions, and account-level stats. |
| Shell | `screens/app_shell_page.dart`, `screens/target_allocation_sheet.dart` | `lib/features/shell/` | Tab shell, lifecycle wiring, and app-level surfaces. |

## Shared Infrastructure

| Path | Responsibility |
| --- | --- |
| `lib/db/` | Drift tables, generated files, migrations, and query helpers. |
| `lib/navigation/` | Route names, paths, router, and navigation extensions. |
| `lib/components/` | Reusable visual components used by multiple features. |
| `lib/design_system/` | Theme, typography, tokens, and specs. |
| `lib/data/` | Static/shared seed data until a feature-specific owner is confirmed. |
