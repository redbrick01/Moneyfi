# MONEYFY Docs

프로젝트 문서는 디자인 규칙, 기능 설계, 운영 절차를 빠르게 찾을 수 있도록 이 페이지에서 관리합니다.

## Start Here

| 문서 | 내용 |
| --- | --- |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조, 개발 흐름 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 역할 |
| [Document Inventory](document_inventory.md) | 저장소 전체 Markdown 문서 색인과 보관 규칙 |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 기능 설계, 구현, 검증, 보고서 작성 개발 규칙 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강용 단순 패치 절차 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현, 원인 분석, 회귀 테스트 중심 버그 픽스 절차 |
| [Data & Sync Flow](data_and_sync.md) | 로컬 Drift DB, 원장 모델, Supabase 동기화 흐름 |
| [Supabase Overview](supabase_overview.md) | Supabase 마이그레이션, Edge Functions, secrets, 운영 포인트 |

## Design & UI

| 문서 | 내용 |
| --- | --- |
| [Design System](design_system.md) | MONEYFY UI/UX 단일 기준 문서: 원칙, 토큰, 컴포넌트, 화면 패턴, QA, 메인 자산 카드 포맷 |
| [Brand Palette](brand/README.md) | 아이콘 블루 기반 브랜드/시맨틱 컬러 결정과 팔레트 산출물 |
| [Pill, Chip, Badge Token Plan](design/pill_chip_badge_token_plan.md) | 스크린샷 기준 pill/chip/badge 현재 상태와 토큰 정리 계획 |
| [Transaction Ledger Redesign](design/transaction_ledger_redesign.md) | 거래 내역 화면 개편 방향 |
| [Transaction History UI/UX Improvement Plan](design/transaction_history_ui_ux_improvement_plan.md) | 거래 내역 필터와 목록 UX 개선 계획 |

## Backend & Operations

| 문서 | 내용 |
| --- | --- |
| [Data & Sync Flow](data_and_sync.md) | 데이터 모델과 앱/서버 간 동기화 설계 |
| [Supabase Overview](supabase_overview.md) | Supabase 폴더와 원격 프로젝트 구성 요약 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | Supabase CLI, 환경 변수, 마이그레이션 운영 절차 |
| [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) | 디자인 시스템 적용, 스냅샷 계산 보정, 배포/검증 전체 보고서 |
| [Cash Snapshot Profit Fix Report](features/bug_fixes/cash_snapshot_profit_fix/test_report_20260524.md) | 현금 평가손익 0원 규칙 적용과 보정 검증 보고서 |

## Feature Work Docs

기능 작업 문서는 작업 성격에 따라 세 경로로 분리합니다.

| 분류 | 경로 | 기준 |
| --- | --- | --- |
| 새로운 기능 개발 | [features/new_feature_development](features/new_feature_development/README.md) | 새 화면, 새 사용자 기능, 주요 제품 경험 확장 |
| 단순 패치 | [features/simple_patches](features/simple_patches/README.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강, 정책 정리 |
| 버그 픽스 | [features/bug_fixes](features/bug_fixes/README.md) | 실행 실패, 깨진 화면, 잘못된 안내, 누락 파일 등 사용자 문제 수정 |

### New Feature Development

| 문서 | 내용 |
| --- | --- |
| [Investment Performance Docs](features/new_feature_development/investment_performance/README.md) | 원장 기반 투자성과 리포트 기능 계획, 검증 계획, 테스트 보고서 |
| [Transaction Management Page Plan](features/new_feature_development/transaction_management_page/plan.md) | 전체 거래 내역 전용 탭과 거래 CRUD 화면 계획 |
| [Transaction Management Page Verification Plan](features/new_feature_development/transaction_management_page/verification_test_plan.md) | 거래 관리 페이지 자동/수동 검증 계획 |
| [Transaction Management Page Test Report 2026-05-25](features/new_feature_development/transaction_management_page/test_report_20260525.md) | 거래 관리 페이지 구현 검증 결과 |
| [Transaction Management Page Implementation Report 2026-05-25](features/new_feature_development/transaction_management_page/implementation_report_20260525.md) | 거래 관리 페이지 구현 내용과 남은 위험 |
| [Transaction Event Rows Plan](features/new_feature_development/transaction_event_rows/plan.md) | 거래 탭을 원장 라인 대신 이벤트 단위 행으로 표시하는 계획 |
| [Transaction Event Rows Verification Plan](features/new_feature_development/transaction_event_rows/verification_test_plan.md) | 거래 이벤트 행 표시 검증 계획 |
| [Transaction Event Rows Test Report 2026-05-25](features/new_feature_development/transaction_event_rows/test_report_20260525.md) | 거래 이벤트 행 표시 구현 검증 결과 |
| [Transaction Form Ledger Layout Plan](features/new_feature_development/transaction_form_ledger_layout/plan.md) | 거래/현금 거래 폼을 원장 이벤트와 라인 대상 중심으로 재배치하는 계획 |
| [Transaction Form Ledger Layout Verification Plan](features/new_feature_development/transaction_form_ledger_layout/verification_test_plan.md) | 거래 폼 계좌 선택과 원장 재생성 검증 계획 |
| [Transaction Form Ledger Layout Test Report 2026-05-25](features/new_feature_development/transaction_form_ledger_layout/test_report_20260525.md) | 거래 폼 원장 레이아웃 구현 검증 결과 |
| [Transaction Event Flow Classification Plan](features/new_feature_development/transaction_event_flow_classification/plan.md) | 외부 입금/외부 출금/내부 거래를 원장 이벤트 schema로 명시하는 계획 |
| [Transaction Event Flow Classification Verification Plan](features/new_feature_development/transaction_event_flow_classification/verification_test_plan.md) | 거래 흐름 분류 schema와 UI 색상 검증 계획 |
| [Transaction Event Flow Classification Test Report 2026-05-25](features/new_feature_development/transaction_event_flow_classification/test_report_20260525.md) | 거래 흐름 분류 schema 구현 검증 결과 |
| [Transaction Event Flow Classification Implementation Report 2026-05-25](features/new_feature_development/transaction_event_flow_classification/implementation_report_20260525.md) | 거래 흐름 분류 schema 구현 내용과 배포 리스크 |
| [Portfolio Diagnosis Plan](features/new_feature_development/portfolio_diagnosis/plan.md) | 포트폴리오 MVP 분석 화면을 진단형 UX로 재설계하는 계획 |
| [Portfolio Diagnosis Verification Plan](features/new_feature_development/portfolio_diagnosis/verification_test_plan.md) | 포트폴리오 진단 리디자인 검증 계획 |
| [Portfolio Diagnosis Test Report 2026-05-24](features/new_feature_development/portfolio_diagnosis/test_report_20260524.md) | 포트폴리오 진단 리디자인 첫 batch 검증 결과 |
| [Profile Management Minimum Plan](features/new_feature_development/profile_management_minimum/plan.md) | My 화면 이름 수정/비밀번호 변경 최소 계정 관리 계획 |
| [Profile Management Minimum Verification Plan](features/new_feature_development/profile_management_minimum/verification_test_plan.md) | 프로필 관리 최소 구현 검증 절차 |
| [Profile Management Minimum Test Report 2026-05-24](features/new_feature_development/profile_management_minimum/test_report_20260524.md) | 프로필 관리 최소 구현 검증 결과 |
| [Risk-Adjusted Benchmark Performance Plan](features/new_feature_development/risk_adjusted_benchmark_performance/plan.md) | 리스크 조정 성과와 benchmark 비교 기능 계획 |
| [Risk-Adjusted Benchmark Performance Verification Plan](features/new_feature_development/risk_adjusted_benchmark_performance/verification_test_plan.md) | 리스크 조정 성과 기능 검증 계획 |
| [Sell Quantity Percentage Shortcuts Plan](features/new_feature_development/sell_quantity_percentage_shortcuts/plan.md) | 매도 수량 비율 shortcut 확장 계획 |
| [Transaction Percentage Shortcuts Expansion Plan](features/new_feature_development/transaction_percentage_shortcuts_expansion/plan.md) | 거래 비율 shortcut 확장 계획 |

### Simple Patches

| 문서 | 내용 |
| --- | --- |
| [Design Token Unification Docs](features/simple_patches/design_token_unification/README.md) | 디자인 토큰 통일화 최종 계획서 리스트와 구현 시작점 |
| [Design Token Unification Plan](features/simple_patches/design_token_unification/plan.md) | 디자인 수치와 legacy UI 스타일을 공통 토큰으로 점진 통일하는 계획 |
| [Design Token Unification Coverage Matrix](features/simple_patches/design_token_unification/plan_parts/00_coverage_matrix.md) | 전체 UI-bearing file, native/web visual asset의 stage 배정표 |
| [Design Token Unification Pre-Implementation Check](features/simple_patches/design_token_unification/pre_implementation_check_20260529.md) | 구현 전 커버리지, legacy 패턴, 첫 batch 범위 점검 |
| [Design Token Unification Verification Plan](features/simple_patches/design_token_unification/verification_test_plan.md) | 디자인 토큰 통일화 batch별 검증 기준 |
| [Sync Conflict Policy Plan](features/simple_patches/sync_conflict_policy/plan.md) | 여러 기기 수정 충돌 기준과 sync 정책 |
| [Sync Conflict Policy Verification Plan](features/simple_patches/sync_conflict_policy/verification_test_plan.md) | sync 충돌 정책 검증 절차 |
| [Sync Conflict Policy Test Report 2026-05-24](features/simple_patches/sync_conflict_policy/test_report_20260524.md) | sync 충돌 정책 구현 결과 |
| [Edge Function Auth Hardening Plan](features/simple_patches/edge_function_auth/plan.md) | Edge Function 사용자 인증 검증 강화 계획 |
| [Edge Function Auth Verification Plan](features/simple_patches/edge_function_auth/verification_test_plan.md) | Edge Function 인증 검증 테스트 계획 |
| [Edge Function Auth Test Report 2026-05-24](features/simple_patches/edge_function_auth/test_report_20260524.md) | Edge Function 인증 검증 강화 결과 |
| [Supabase RLS And Grants Hardening Plan](features/simple_patches/supabase_rls_hardening/plan.md) | 원격 DB 기준 client role 권한과 RLS 조합 최종 점검 계획 |
| [Supabase RLS And Grants Verification Plan](features/simple_patches/supabase_rls_hardening/verification_test_plan.md) | Supabase 권한/RLS 검증 절차 |
| [Supabase RLS And Grants Test Report 2026-05-24](features/simple_patches/supabase_rls_hardening/test_report_20260524.md) | Supabase 권한/RLS 점검 및 hardening 결과 |
| [Input Validation Hardening Plan](features/simple_patches/input_validation_hardening/plan.md) | 이메일/날짜/숫자/symbol 입력 검증 공통화 계획 |
| [Input Validation Hardening Verification Plan](features/simple_patches/input_validation_hardening/verification_test_plan.md) | 입력값 검증 공통화 검증 절차 |
| [Input Validation Hardening Test Report 2026-05-24](features/simple_patches/input_validation_hardening/test_report_20260524.md) | 입력값 검증 공통화 검증 결과 |
| [CI/CD Minimum Plan](features/simple_patches/ci_cd_minimum/plan.md) | GitHub Actions 기반 Flutter analyze/test 최소 CI 계획 |
| [CI/CD Minimum Verification Plan](features/simple_patches/ci_cd_minimum/verification_test_plan.md) | Flutter 최소 CI 검증 절차 |
| [CI/CD Minimum Test Report 2026-05-24](features/simple_patches/ci_cd_minimum/test_report_20260524.md) | Flutter 최소 CI 검증 결과 |
| [Ledger Numeric Regression Plan](features/simple_patches/ledger_numeric_regression/plan.md) | 원장/현금/환전/스냅샷 핵심 수치 계산 회귀 테스트 추가 계획 |
| [Ledger Numeric Regression Verification Plan](features/simple_patches/ledger_numeric_regression/verification_test_plan.md) | 원장/현금/환전/스냅샷 계산 회귀 검증 절차 |
| [Ledger Numeric Regression Test Report 2026-05-24](features/simple_patches/ledger_numeric_regression/test_report_20260524.md) | 원장/현금/환전/스냅샷 계산 회귀 테스트 추가 검증 결과 |
| [Transaction Tab UI Density Plan](features/simple_patches/transaction_tab_ui_density/plan.md) | 거래 탭 목록과 하단 탭 밀도 개선 계획 |
| [Transaction Tab UI Density Verification Plan](features/simple_patches/transaction_tab_ui_density/verification_test_plan.md) | 거래 탭 UI 밀도 패치 검증 절차 |
| [Transaction Tab UI Density Test Report 2026-05-25](features/simple_patches/transaction_tab_ui_density/test_report_20260525.md) | 거래 탭 UI 밀도 패치 검증 결과 |
| [Supabase Frontend-Only Hidden State Plan](features/simple_patches/supabase_frontend_only_hidden/plan.md) | Supabase 원격 DB와 Edge Function에서 숨김 상태 소유권 제거 계획 |
| [Supabase Frontend-Only Hidden State Verification Plan](features/simple_patches/supabase_frontend_only_hidden/verification_test_plan.md) | 원격 숨김 필드 제거 검증 절차 |
| [Supabase Frontend-Only Hidden State Test Report 2026-05-25](features/simple_patches/supabase_frontend_only_hidden/test_report_20260525.md) | 원격 숨김 필드 제거 검증 결과 |
| [App Database Modularization Plan](features/simple_patches/app_database_modularization/plan.md) | `app_database.dart` 비대화 1차 분리 계획 |
| [App Database Modularization Verification Plan](features/simple_patches/app_database_modularization/verification_test_plan.md) | DB 파일 구조 분리 검증 절차 |
| [App Database Modularization Test Report 2026-05-24](features/simple_patches/app_database_modularization/test_report_20260524.md) | DB 파일 구조 분리 검증 결과 |

### Bug Fixes

| 문서 | 내용 |
| --- | --- |
| [External API Fallbacks Plan](features/bug_fixes/external_api_fallbacks/plan.md) | KIS/OpenAI/Finnhub/Coinone 실패 시 캐시/샘플/명확한 오류 UI 보강 계획 |
| [External API Fallbacks Verification Plan](features/bug_fixes/external_api_fallbacks/verification_test_plan.md) | 외부 API 실패 fallback 검증 절차 |
| [External API Fallbacks Test Report 2026-05-24](features/bug_fixes/external_api_fallbacks/test_report_20260524.md) | 외부 API 실패 fallback 보강 검증 결과 |
| [Login Initial Stale Tab Data Plan](features/bug_fixes/login_initial_stale_tab_data/plan.md) | 로그인 직후 탭 화면에 이전/중간 데이터가 먼저 표시되는 문제 수정 계획 |
| [Login Initial Stale Tab Data Verification Plan](features/bug_fixes/login_initial_stale_tab_data/verification_test_plan.md) | 로그인 직후 탭 데이터 초기화 검증 절차 |
| [Login Initial Stale Tab Data Test Report 2026-05-25](features/bug_fixes/login_initial_stale_tab_data/test_report_20260525.md) | 로그인 직후 탭 데이터 초기화 수정 검증 결과 |
| [Login Sync Overlay Layout Plan](features/bug_fixes/login_sync_overlay_layout/plan.md) | 로그인 데이터 가져오기 오버레이 레이아웃 수정 계획 |
| [Login Sync Overlay Layout Verification Plan](features/bug_fixes/login_sync_overlay_layout/verification_test_plan.md) | 로그인 데이터 가져오기 오버레이 검증 절차 |
| [Login Sync Overlay Layout Test Report 2026-05-25](features/bug_fixes/login_sync_overlay_layout/test_report_20260525.md) | 로그인 데이터 가져오기 오버레이 수정 검증 결과 |
| [News Cache Staleness Plan](features/bug_fixes/news_cache_staleness/plan.md) | 뉴스 조회가 오래된 로컬 캐시에 고정되는 문제 수정 계획 |
| [News Cache Staleness Verification Plan](features/bug_fixes/news_cache_staleness/verification_test_plan.md) | 뉴스 캐시 freshness 및 서버 운영 검증 절차 |
| [News Cache Staleness Test Report 2026-05-24](features/bug_fixes/news_cache_staleness/test_report_20260524.md) | 뉴스 캐시 freshness 수정 검증 결과 |
| [Login Sync Failure UX Plan](features/bug_fixes/login_sync_failure_ux/plan.md) | 로그인 후 코어/뉴스/스냅샷 동기화 실패 안내 개선 계획 |
| [Login Sync Failure UX Verification Plan](features/bug_fixes/login_sync_failure_ux/verification_test_plan.md) | 로그인 동기화 실패 UX 검증 절차 |
| [Login Sync Failure UX Test Report 2026-05-24](features/bug_fixes/login_sync_failure_ux/test_report_20260524.md) | 로그인 동기화 실패 UX 검증 결과 |
| [Logout Stale Tab Data Plan](features/bug_fixes/logout_stale_tab_data/plan.md) | 로그아웃 후 탭 화면에 이전 계정 데이터가 남는 문제 수정 계획 |
| [Logout Stale Tab Data Verification Plan](features/bug_fixes/logout_stale_tab_data/verification_test_plan.md) | 로그아웃 후 탭 데이터 초기화 검증 절차 |
| [Logout Stale Tab Data Test Report 2026-05-25](features/bug_fixes/logout_stale_tab_data/test_report_20260525.md) | 로그아웃 후 탭 데이터 초기화 수정 검증 결과 |
| [Optional Local Config Plan](features/bug_fixes/optional_local_config/plan.md) | `assets/config.json` 누락에도 앱이 시작되도록 하는 설정 구조 개선 계획 |
| [Optional Local Config Verification Plan](features/bug_fixes/optional_local_config/verification_test_plan.md) | 로컬 설정 파일 optional 처리 검증 절차 |
| [Optional Local Config Test Report 2026-05-24](features/bug_fixes/optional_local_config/test_report_20260524.md) | 로컬 설정 파일 optional 처리 검증 결과 |
| [Transaction Pull Refresh Remote Sync Plan](features/bug_fixes/transaction_pull_refresh_remote_sync/plan.md) | 거래 탭 당겨서 새로고침 시 Supabase core data를 다시 내려받도록 하는 계획 |
| [Transaction Pull Refresh Remote Sync Verification Plan](features/bug_fixes/transaction_pull_refresh_remote_sync/verification_test_plan.md) | 거래 탭 수동 새로고침 remote pull 검증 절차 |
| [Transaction Pull Refresh Remote Sync Test Report 2026-05-25](features/bug_fixes/transaction_pull_refresh_remote_sync/test_report_20260525.md) | 거래 탭 수동 새로고침 remote pull 수정 검증 결과 |
| [Transaction Record Only Calculation And Supabase Start Plan](features/bug_fixes/transaction_record_only_calculation_sync/plan.md) | 기록전용 거래의 현재값 계산 제외와 분석 포함 정책, Supabase 로컬 마이그레이션 시작 오류 수정 계획 |
| [Transaction Record Only Calculation And Supabase Start Verification Plan](features/bug_fixes/transaction_record_only_calculation_sync/verification_test_plan.md) | 기록전용 거래 계산/분석 정책과 Supabase 시작 검증 절차 |
| [Transaction Record Only Calculation And Supabase Start Test Report 2026-05-25](features/bug_fixes/transaction_record_only_calculation_sync/test_report_20260525.md) | 기록전용 거래 계산/분석 정책과 Supabase 시작 오류 수정 검증 결과 |
| [Transaction Tab Null Row Crash Plan](features/bug_fixes/transaction_tab_null_row_crash/plan.md) | 거래 탭 목록 렌더링 중 nullable 원장 행으로 발생한 크래시 수정 계획 |
| [Transaction Tab Null Row Crash Verification Plan](features/bug_fixes/transaction_tab_null_row_crash/verification_test_plan.md) | 거래 탭 null 행 크래시 회귀 검증 절차 |
| [Transaction Tab Null Row Crash Test Report 2026-05-25](features/bug_fixes/transaction_tab_null_row_crash/test_report_20260525.md) | 거래 탭 null 행 크래시 수정 검증 결과 |
| [Crypto Sell Quantity Precision Plan](features/bug_fixes/crypto_sell_quantity_precision/plan.md) | 암호화폐 매도 수량 정밀도 수정 계획 |
| [Snapshot Detail Holdings Fix Report](features/bug_fixes/snapshot_detail_holdings_fix/implementation_report.md) | 스냅샷 상세 보유 행 표시 수정 보고서 |
| [Analysis Detail Back Navigation Report](features/bug_fixes/analysis_detail_back_navigation/implementation_report_20260526.md) | 분석 상세 화면 뒤로가기 수정 보고서 |
| [Ledger Realized PnL Moving Average Recompute Plan](features/bug_fixes/ledger_realized_pnl_moving_average_recompute/plan.md) | 이동평균 기준 실현손익 재계산 수정 계획 |
| [USD Realized PnL Currency Basis Plan](features/bug_fixes/usd_realized_pnl_currency_basis/plan.md) | USD 실현손익 통화 기준 보정 계획 |
| [USD Realized PnL Currency Basis Runbook](features/bug_fixes/usd_realized_pnl_currency_basis/operational_runbook.md) | USD 실현손익 보정 운영 절차 |

## Maintenance Rules

- 새 문서를 추가하면 이 인덱스에 링크를 함께 추가합니다.
- 저장소 전체 문서 위치를 바꾸거나 새 작업 묶음을 추가하면 [Document Inventory](document_inventory.md)도 함께 갱신합니다.
- 기능별 문서는 작업 성격에 따라 `docs/features/new_feature_development/<work>/`, `docs/features/simple_patches/<work>/`, `docs/features/bug_fixes/<work>/` 아래에 모읍니다.
- 공통 개발 규칙과 가이드는 `docs/guides/` 아래에 둡니다.
- 임시 문서는 관련 기능 폴더 안에서 `tmp_` prefix를 붙이고, 루트 인덱스에는 직접 연결하지 않습니다.
- 실행 가능한 절차는 명령어 블록을 포함합니다.
- 키, 토큰, 개인 계정 정보는 문서에 직접 적지 않습니다.
- 오래된 설계 문서는 삭제보다 `Archived` 섹션을 추가해 맥락을 남깁니다.
