# MONEYFY Docs

프로젝트 문서는 디자인 규칙, 기능 설계, 운영 절차를 빠르게 찾을 수 있도록 이 페이지에서 관리합니다.

## Start Here

| 문서 | 내용 |
| --- | --- |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조, 개발 흐름 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 역할 |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 기능 설계, 구현, 검증, 보고서 작성 개발 규칙 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강용 단순 패치 절차 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현, 원인 분석, 회귀 테스트 중심 버그 픽스 절차 |
| [Data & Sync Flow](data_and_sync.md) | 로컬 Drift DB, 원장 모델, Supabase 동기화 흐름 |
| [Supabase Overview](supabase_overview.md) | Supabase 마이그레이션, Edge Functions, secrets, 운영 포인트 |

## Design & UI

| 문서 | 내용 |
| --- | --- |
| [Design System](design_system.md) | MONEYFY UI 원칙, 색상, 컴포넌트 사용 규칙 |
| [getdesign Application Plan](getdesign_application_plan.md) | getdesign.md 기반 디자인 레퍼런스 적용 계획 |
| [Main Asset Card Format](main_asset_card_format.md) | 메인 자산 카드 표시 포맷 |
| [Transaction Ledger Redesign](transaction_ledger_redesign.md) | 거래 내역 화면 개편 방향 |
| [UI Snapshot Targets](ui_snapshot_targets.md) | UI 회귀 확인용 주요 화면 목록 |
| [Final Polish Pass](final_polish_pass.md) | 최종 UI 다듬기 체크리스트 |

## Backend & Operations

| 문서 | 내용 |
| --- | --- |
| [Data & Sync Flow](data_and_sync.md) | 데이터 모델과 앱/서버 간 동기화 설계 |
| [Supabase Overview](supabase_overview.md) | Supabase 폴더와 원격 프로젝트 구성 요약 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | Supabase CLI, 환경 변수, 마이그레이션 운영 절차 |
| [Implementation Report 2026-05-24](implementation_report_20260524.md) | 디자인 시스템 적용, 스냅샷 계산 보정, 배포/검증 전체 보고서 |
| [Cash Snapshot Profit Fix Report](cash_snapshot_profit_fix_report.md) | 현금 평가손익 0원 규칙 적용과 보정 검증 보고서 |

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
| [Portfolio Diagnosis Plan](features/new_feature_development/portfolio_diagnosis/plan.md) | 포트폴리오 MVP 분석 화면을 진단형 UX로 재설계하는 계획 |
| [Portfolio Diagnosis Verification Plan](features/new_feature_development/portfolio_diagnosis/verification_test_plan.md) | 포트폴리오 진단 리디자인 검증 계획 |
| [Portfolio Diagnosis Test Report 2026-05-24](features/new_feature_development/portfolio_diagnosis/test_report_20260524.md) | 포트폴리오 진단 리디자인 첫 batch 검증 결과 |
| [Profile Management Minimum Plan](features/new_feature_development/profile_management_minimum/plan.md) | My 화면 이름 수정/비밀번호 변경 최소 계정 관리 계획 |
| [Profile Management Minimum Verification Plan](features/new_feature_development/profile_management_minimum/verification_test_plan.md) | 프로필 관리 최소 구현 검증 절차 |
| [Profile Management Minimum Test Report 2026-05-24](features/new_feature_development/profile_management_minimum/test_report_20260524.md) | 프로필 관리 최소 구현 검증 결과 |

### Simple Patches

| 문서 | 내용 |
| --- | --- |
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
| [App Database Modularization Plan](features/simple_patches/app_database_modularization/plan.md) | `app_database.dart` 비대화 1차 분리 계획 |
| [App Database Modularization Verification Plan](features/simple_patches/app_database_modularization/verification_test_plan.md) | DB 파일 구조 분리 검증 절차 |
| [App Database Modularization Test Report 2026-05-24](features/simple_patches/app_database_modularization/test_report_20260524.md) | DB 파일 구조 분리 검증 결과 |

### Bug Fixes

| 문서 | 내용 |
| --- | --- |
| [External API Fallbacks Plan](features/bug_fixes/external_api_fallbacks/plan.md) | KIS/OpenAI/Finnhub/Coinone 실패 시 캐시/샘플/명확한 오류 UI 보강 계획 |
| [External API Fallbacks Verification Plan](features/bug_fixes/external_api_fallbacks/verification_test_plan.md) | 외부 API 실패 fallback 검증 절차 |
| [External API Fallbacks Test Report 2026-05-24](features/bug_fixes/external_api_fallbacks/test_report_20260524.md) | 외부 API 실패 fallback 보강 검증 결과 |
| [News Cache Staleness Plan](features/bug_fixes/news_cache_staleness/plan.md) | 뉴스 조회가 오래된 로컬 캐시에 고정되는 문제 수정 계획 |
| [News Cache Staleness Verification Plan](features/bug_fixes/news_cache_staleness/verification_test_plan.md) | 뉴스 캐시 freshness 및 서버 운영 검증 절차 |
| [News Cache Staleness Test Report 2026-05-24](features/bug_fixes/news_cache_staleness/test_report_20260524.md) | 뉴스 캐시 freshness 수정 검증 결과 |
| [Login Sync Failure UX Plan](features/bug_fixes/login_sync_failure_ux/plan.md) | 로그인 후 코어/뉴스/스냅샷 동기화 실패 안내 개선 계획 |
| [Login Sync Failure UX Verification Plan](features/bug_fixes/login_sync_failure_ux/verification_test_plan.md) | 로그인 동기화 실패 UX 검증 절차 |
| [Login Sync Failure UX Test Report 2026-05-24](features/bug_fixes/login_sync_failure_ux/test_report_20260524.md) | 로그인 동기화 실패 UX 검증 결과 |
| [Optional Local Config Plan](features/bug_fixes/optional_local_config/plan.md) | `assets/config.json` 누락에도 앱이 시작되도록 하는 설정 구조 개선 계획 |
| [Optional Local Config Verification Plan](features/bug_fixes/optional_local_config/verification_test_plan.md) | 로컬 설정 파일 optional 처리 검증 절차 |
| [Optional Local Config Test Report 2026-05-24](features/bug_fixes/optional_local_config/test_report_20260524.md) | 로컬 설정 파일 optional 처리 검증 결과 |

## Maintenance Rules

- 새 문서를 추가하면 이 인덱스에 링크를 함께 추가합니다.
- 기능별 문서는 작업 성격에 따라 `docs/features/new_feature_development/<work>/`, `docs/features/simple_patches/<work>/`, `docs/features/bug_fixes/<work>/` 아래에 모읍니다.
- 공통 개발 규칙과 가이드는 `docs/guides/` 아래에 둡니다.
- 임시 문서는 관련 기능 폴더 안에서 `tmp_` prefix를 붙이고, 루트 인덱스에는 직접 연결하지 않습니다.
- 실행 가능한 절차는 명령어 블록을 포함합니다.
- 키, 토큰, 개인 계정 정보는 문서에 직접 적지 않습니다.
- 오래된 설계 문서는 삭제보다 `Archived` 섹션을 추가해 맥락을 남깁니다.
