# Implementation History

This document is the compact history index for completed Moneyfy implementation plans, specs, design explorations, and feature records that were removed during Markdown Cleanup Phase 2 on 2026-06-27.

Use current canonical docs for implementation details:
- `docs/project_overview.md`
- `docs/folder_guide.md`
- `docs/data_and_sync.md`
- `docs/supabase_overview.md`
- `docs/design_system.md`
- `docs/document_inventory.md`

## Major Feature History

| Area | Removed source docs | Current references |
| --- | --- | --- |
| Investment review hub | `docs/superpowers/plans/2026-05-31-investment-review-hub.md`, `docs/superpowers/specs/2026-05-31-investment-review-hub-design.md` | `lib/pages/investment_review_page.dart`, `lib/services/investment_review/`, `docs/project_overview.md` |
| Daily investment review | `docs/superpowers/plans/2026-06-01-daily-investment-review.md`, `docs/superpowers/specs/2026-06-01-daily-investment-review-design.md` | `lib/services/investment_review/`, `test/daily_investment_review_presenter_test.dart` |
| Investment performance | `docs/superpowers/plans/2026-06-01-investment-performance-redesign.md`, `docs/superpowers/specs/2026-06-01-investment-performance-redesign-design.md`, `docs/features/new_feature_development/investment_performance/plan.md` | `lib/pages/investment_performance_page.dart`, `test/investment_performance_judgment_test.dart` |
| Snapshot detail display | `docs/superpowers/plans/2026-06-02-snapshot-detail-display-rules.md`, `docs/superpowers/specs/2026-06-02-snapshot-detail-display-rules-design.md` | `lib/pages/snapshot_detail_page.dart`, `docs/data_and_sync.md` |
| Equity research metric card | `docs/superpowers/plans/2026-06-03-equity-research-metric-card.md` | `lib/services/equity_research_metric_presenter.dart`, `test/equity_research_metric_presenter_test.dart` |
| Weekly investment briefing | `docs/superpowers/plans/2026-06-07-weekly-investment-briefing.md` | `lib/pages/investment_review_page.dart`, `docs/project_overview.md` |
| News reports schema adaptation | `docs/superpowers/plans/2026-06-14-news-reports-schema-adaptation.md` | `supabase/migrations/`, `supabase/functions/`, `docs/supabase_overview.md` |

## Feature Record Groups Removed

| Group | Removed path | Current references |
| --- | --- | --- |
| Bug fixes | `docs/features/bug_fixes/` | Git history, tests under `test/`, canonical docs for affected areas |
| New feature development | `docs/features/new_feature_development/` | Current app code under `lib/`, service tests under `test/` |
| Simple patches | `docs/features/simple_patches/` | Current app code under `lib/`, `docs/design_system.md`, `docs/supabase_overview.md` |

## Archived Non-Markdown Artifacts

| Area | Archived source | Current path |
| --- | --- | --- |
| Risk-adjusted benchmark performance | Remote schema draft | `docs/reports/archived_artifacts/risk_adjusted_benchmark_performance/remote_schema_draft_05.sql` |
| USD realized PnL currency basis | Remote verification and rollback SQL | `docs/reports/archived_artifacts/usd_realized_pnl_currency_basis/remote_verification_and_rollback_06.sql` |
| Design token unification | Card panel SVG sample | `docs/reports/archived_artifacts/design_token_unification/card_panel_token_sample_20260530.svg` |

## Risk-Adjusted Benchmark Rollout Notes

The removed rollout docs recorded that Supabase 원격 적용은 2026-05-29에 완료. Safety review covered assets, holdings, 수량 합계, 매수원금 합계, zero 분포, and 데이터 부족 cases. The preserved SQL archive must not include destructive holdings rewrites such as `update holdings`, `delete from holdings`, or `truncate`.

## Design Explorations Removed

| Removed source doc | Current reference |
| --- | --- |
| `docs/design/pill_chip_badge_token_plan.md` | `docs/design_system.md`, `lib/design_system/`, `lib/components/` |
| `docs/design/transaction_history_ui_ux_improvement_plan.md` | `lib/pages/transactions_page.dart`, `docs/design_system.md` |
| `docs/design/transaction_ledger_redesign.md` | `docs/data_and_sync.md`, `lib/db/app_database.dart`, `supabase/migrations/` |

## Removed Generated Audits

| Removed source doc | Reason |
| --- | --- |
| `docs/page_flow_review.md` | Page-flow audits drift as screens change; regenerate when needed. |
| `docs/page_inventory_graph.md` | Page inventory graphs drift as routes/screens change; regenerate when needed. |

## Cleanup Principle

Completed plans are not canonical documentation. Keep current behavior in app code, tests, schema, and concise architecture docs. Use Git history for detailed old implementation checklists.
