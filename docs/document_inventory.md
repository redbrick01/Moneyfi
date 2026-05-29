# Document Inventory

이 문서는 MONEYFY 저장소의 Markdown 문서를 한곳에서 찾기 위한 전체 색인입니다. 문서 파일을 물리적으로 이동하지 않고, 기존 폴더 구조를 기준으로 읽는 순서와 보관 위치를 정리합니다.

## Reading Order

| 순서 | 문서 | 목적 |
| --- | --- | --- |
| 1 | [Project Overview](project_overview.md) | 제품 목적, 핵심 기능, 런타임 구조 파악 |
| 2 | [Folder Guide](folder_guide.md) | 저장소 폴더별 책임 파악 |
| 3 | [Data & Sync Flow](data_and_sync.md) | 로컬 DB, 원장, Supabase sync 흐름 파악 |
| 4 | [Supabase Overview](supabase_overview.md) | 원격 schema, Edge Functions, 운영 포인트 파악 |
| 5 | [Design System](design_system.md) | MONEYFY UI 원칙과 재사용 컴포넌트 규칙 파악 |
| 6 | [Feature Work Docs](features/README.md) | 기능/패치/버그 수정 작업 기록 탐색 |

## Repository-Level Docs

| 경로 | 역할 |
| --- | --- |
| [../README.md](../README.md) | 프로젝트 소개, 실행 방법, 주요 문서 진입점 |
| [../DESIGN.md](../DESIGN.md) | 외부 디자인 레퍼런스 기반 visual spec |
| [../assets/README.md](../assets/README.md) | 앱 asset과 로컬 config 예시 안내 |
| [../lib/README.md](../lib/README.md) | Flutter 앱 소스 구조, 화면/서비스 map |
| [../supabase/README.md](../supabase/README.md) | Supabase 폴더 구조, 함수 그룹, 운영 명령 |
| [../test/README.md](../test/README.md) | 테스트 폴더와 테스트 작성 기준 |
| [../ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](../ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) | Flutter 기본 launch image asset 안내 |
| [../Moneyfy_Reddit/README.md](../Moneyfy_Reddit/README.md) | Reddit mirror/analysis 보조 프로젝트 안내 |
| [../Moneyfy_Reddit/DESIGN.md](../Moneyfy_Reddit/DESIGN.md) | Reddit 보조 프로젝트 UI/UX 설계 |
| [../Moneyfy_Reddit/IMPROVEMENT_PLAN.md](../Moneyfy_Reddit/IMPROVEMENT_PLAN.md) | Reddit 보조 프로젝트 개선 계획 |
| [../Moneyfy_Reddit/REDESIGN_PLAN.md](../Moneyfy_Reddit/REDESIGN_PLAN.md) | Reddit 보조 프로젝트 재설계 계획 |
| [../Moneyfy_Reddit/WORKERIZATION_PLAN.md](../Moneyfy_Reddit/WORKERIZATION_PLAN.md) | Reddit 보조 프로젝트 worker 분리 계획 |

## Core Product Docs

| 문서 | 역할 |
| --- | --- |
| [README](README.md) | `docs/`의 기본 진입점 |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 역할 |
| [Data & Sync Flow](data_and_sync.md) | Drift DB, 원장 모델, Supabase 동기화 |
| [Supabase Overview](supabase_overview.md) | Supabase migration, Edge Function, 운영 포인트 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | 원격 Supabase 운영 절차 |
| [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) | 2026-05-24 기준 통합 구현 보고서 |

## Design And UI Docs

| 문서 | 역할 |
| --- | --- |
| [Design System](design_system.md) | UI 원칙, 색상, typography, component 규칙 |
| [getdesign Application Plan](design/getdesign_application_plan.md) | 디자인 레퍼런스 적용 계획 |
| [Main Asset Card Format](design/main_asset_card_format.md) | 메인 자산 카드 표시 포맷 |
| [Transaction Ledger Redesign](design/transaction_ledger_redesign.md) | 거래 내역 화면 개편 방향 |
| [UI Snapshot Targets](design/ui_snapshot_targets.md) | UI 회귀 확인 화면 목록 |
| [Final Polish Pass](design/final_polish_pass.md) | 최종 UI polish checklist |

## Process Guides

| 문서 | 기준 |
| --- | --- |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 새 기능 개발 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현 가능한 문제 수정과 회귀 검증 |

## Feature Work Collections

작업 단위 문서는 `plan.md`, `verification_test_plan.md`, `test_report_YYYYMMDD.md`, `implementation_report*.md`, `operational_runbook.md`, `release_gate*.md` 같은 역할별 파일명으로 정리합니다.

| 분류 | 인덱스 | 작업 폴더 |
| --- | --- | --- |
| 새로운 기능 개발 | [new_feature_development/README](features/new_feature_development/README.md) | `investment_performance`, `portfolio_diagnosis`, `profile_management_minimum`, `risk_adjusted_benchmark_performance`, `sell_quantity_percentage_shortcuts`, `transaction_event_flow_classification`, `transaction_event_rows`, `transaction_form_ledger_layout`, `transaction_management_page`, `transaction_percentage_shortcuts_expansion` |
| 단순 패치 | [simple_patches/README](features/simple_patches/README.md) | `app_database_modularization`, `ci_cd_minimum`, `edge_function_auth`, `input_validation_hardening`, `ledger_numeric_regression`, `supabase_frontend_only_hidden`, `supabase_rls_hardening`, `sync_conflict_policy`, `transaction_tab_ui_density` |
| 버그 픽스 | [bug_fixes/README](features/bug_fixes/README.md) | `analysis_detail_back_navigation`, `cash_snapshot_profit_fix`, `crypto_sell_quantity_precision`, `external_api_fallbacks`, `ledger_realized_pnl_moving_average_recompute`, `login_initial_stale_tab_data`, `login_sync_failure_ux`, `login_sync_overlay_layout`, `logout_stale_tab_data`, `news_cache_staleness`, `optional_local_config`, `record_only_remote_state_reconcile`, `snapshot_detail_holdings_fix`, `transaction_pull_refresh_remote_sync`, `transaction_record_only_calculation_sync`, `transaction_tab_null_row_crash`, `usd_realized_pnl_currency_basis` |
| 수동 테스트 | `features/manual_tests/` | macOS 거래 흐름, 분석 페이지 수동 테스트 계획/보고서 |
| 통합 보고서 | `reports/` | [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) |

## Feature Folder Rules

| 파일명 | 의미 |
| --- | --- |
| `plan.md` | 범위, 설계, 구현 단계 |
| `verification_test_plan.md` | 자동/수동 검증 계획 |
| `test_report_YYYYMMDD.md` | 실제 검증 결과 |
| `implementation_report*.md` | 구현 세부 내용과 잔여 리스크 |
| `plan_parts/` | 큰 작업을 여러 단계로 나눈 상세 계획 |
| `tmp_*.md` | 임시 개발 메모. 상위 인덱스에는 직접 연결하지 않음 |
| `operational_runbook.md` | 배포, 원격 적용, 운영 절차 |
| `release_gate*.md` | 릴리스 전 승인/차단 조건 |

## Maintenance Checklist

- 새 작업 폴더를 만들면 해당 분류의 README와 이 문서를 함께 갱신합니다.
- 새 기능은 `docs/features/new_feature_development/<work>/`에 둡니다.
- 구조 개선, 보안/품질 강화, 테스트/CI 보강은 `docs/features/simple_patches/<work>/`에 둡니다.
- 사용자에게 보이는 실패나 잘못된 계산 수정은 `docs/features/bug_fixes/<work>/`에 둡니다.
- 루트 성격의 장기 문서는 `docs/` 바로 아래에 두고, 일회성 작업 기록은 기능 폴더 안에 둡니다.
- 비밀값, 개인 계정 정보, service role key는 문서에 적지 않습니다.
