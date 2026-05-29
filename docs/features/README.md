# Feature Work Docs

기능 작업 문서는 작업 성격에 따라 세 경로로 보관합니다.

| 분류 | 경로 | 기준 |
| --- | --- | --- |
| 새로운 기능 개발 | `new_feature_development/` | 새 화면, 새 사용자 기능, 주요 제품 경험 확장 |
| 단순 패치 | `simple_patches/` | 구조 개선, 보안/품질 강화, 테스트/CI 보강, 정책 정리 |
| 버그 픽스 | `bug_fixes/` | 실행 실패, 깨진 화면, 잘못된 안내, 누락 파일 등 사용자 문제 수정 |

## Classification Notes

- 사용자에게 새로운 작업 흐름이나 화면을 제공하면 `new_feature_development`로 분류합니다.
- 기존 동작은 유지하면서 신뢰도, 보안, 구조, 운영성을 강화하면 `simple_patches`로 분류합니다.
- 사용자가 이미 겪을 수 있는 실패, 깨짐, 누락, 잘못된 안내를 바로잡으면 `bug_fixes`로 분류합니다.

## Process Guides

| 분류 | 프로세스 가이드 |
| --- | --- |
| 새로운 기능 개발 | [Development Process Guidelines](../guides/development_process_guidelines.md) |
| 단순 패치 | [Simple Patch Process Guidelines](../guides/simple_patch_process_guidelines.md) |
| 버그 픽스 | [Bug Fix Process Guidelines](../guides/bug_fix_process_guidelines.md) |

## Current Classification

| 분류 | 작업 |
| --- | --- |
| 새로운 기능 개발 | `investment_performance`, `portfolio_diagnosis`, `profile_management_minimum`, `risk_adjusted_benchmark_performance`, `sell_quantity_percentage_shortcuts`, `transaction_event_flow_classification`, `transaction_event_rows`, `transaction_form_ledger_layout`, `transaction_management_page`, `transaction_percentage_shortcuts_expansion` |
| 단순 패치 | `app_database_modularization`, `ci_cd_minimum`, `edge_function_auth`, `input_validation_hardening`, `ledger_numeric_regression`, `supabase_frontend_only_hidden`, `supabase_rls_hardening`, `sync_conflict_policy`, `transaction_tab_ui_density` |
| 버그 픽스 | `analysis_detail_back_navigation`, `cash_snapshot_profit_fix`, `crypto_sell_quantity_precision`, `external_api_fallbacks`, `ledger_realized_pnl_moving_average_recompute`, `login_initial_stale_tab_data`, `login_sync_failure_ux`, `login_sync_overlay_layout`, `logout_stale_tab_data`, `news_cache_staleness`, `optional_local_config`, `record_only_remote_state_reconcile`, `snapshot_detail_holdings_fix`, `transaction_pull_refresh_remote_sync`, `transaction_record_only_calculation_sync`, `transaction_tab_null_row_crash`, `usd_realized_pnl_currency_basis` |

전체 저장소 문서 색인은 [Document Inventory](../document_inventory.md)를 참고합니다.
