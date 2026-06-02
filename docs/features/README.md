# Feature Work Docs

Feature docs keep current planning context, not every run log.

## Canonical Structure

| 분류 | 경로 | 남기는 문서 |
| --- | --- | --- |
| 새로운 기능 개발 | `new_feature_development/` | category README, each work `plan.md` |
| 단순 패치 | `simple_patches/` | category README, each work `plan.md` |
| 버그 픽스 | `bug_fixes/` | category README, each work `plan.md` |

## Cleanup Policy

- Keep `plan.md` as canonical work record.
- Fold implementation/test/verification highlights into plan or category README.
- Remove stale `implementation_report*.md`, `test_report*.md`, `verification_test_plan.md`, temporary reports, and `*.original.md` backups after review.
- Keep public/reference docs outside `docs/features` in original prose unless explicitly requested.

## Current Classification

| 분류 | 작업 |
| --- | --- |
| 새로운 기능 개발 | `investment_performance`, `investment_review_hub`, `page_flow_redesign`, `portfolio_diagnosis`, `profile_management_minimum`, `risk_adjusted_benchmark_performance`, `sell_quantity_percentage_shortcuts`, `transaction_event_flow_classification`, `transaction_event_rows`, `transaction_form_ledger_layout`, `transaction_management_page`, `transaction_percentage_shortcuts_expansion` |
| 단순 패치 | `app_database_modularization`, `ci_cd_minimum`, `design_md_full_compliance`, `design_token_unification`, `edge_function_auth`, `font_family_tokenization`, `font_weight_tokenization`, `input_validation_hardening`, `ledger_numeric_regression`, `supabase_frontend_only_hidden`, `supabase_rls_hardening`, `sync_conflict_policy`, `transaction_history_filter_redesign`, `transaction_tab_ui_density` |
| 버그 픽스 | `analysis_detail_back_navigation`, `cash_snapshot_profit_fix`, `crypto_sell_quantity_precision`, `external_api_fallbacks`, `ledger_realized_pnl_moving_average_recompute`, `login_initial_stale_tab_data`, `login_sync_failure_ux`, `login_sync_overlay_layout`, `logout_stale_tab_data`, `news_cache_staleness`, `optional_local_config`, `record_only_remote_state_reconcile`, `snapshot_detail_holdings_fix`, `transaction_pull_refresh_remote_sync`, `transaction_record_only_calculation_sync`, `transaction_tab_null_row_crash`, `usd_realized_pnl_currency_basis` |

## Process Guides

| 분류 | 프로세스 가이드 |
| --- | --- |
| 새로운 기능 개발 | [Development Process Guidelines](../guides/development_process_guidelines.md) |
| 단순 패치 | [Simple Patch Process Guidelines](../guides/simple_patch_process_guidelines.md) |
| 버그 픽스 | [Bug Fix Process Guidelines](../guides/bug_fix_process_guidelines.md) |

전체 저장소 문서 색인은 [Document Inventory](../document_inventory.md)를 참고합니다.
