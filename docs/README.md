# MONEYFY Docs

프로젝트 문서는 제품 기준, 설계 기준, 운영 절차, 작업 기록을 빠르게 찾도록 관리합니다.

## Start Here

| 문서 | 내용 |
| --- | --- |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조, 개발 흐름 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 책임 |
| [Document Inventory](document_inventory.md) | 저장소 전체 Markdown 색인과 보관 규칙 |
| [Data & Sync Flow](data_and_sync.md) | 로컬 Drift DB, 원장 모델, Supabase sync 흐름 |
| [Supabase Overview](supabase_overview.md) | Supabase migration, Edge Functions, 운영 포인트 |
| [Design System](design_system.md) | MONEYFY UI/UX 단일 기준 |

## Design & UI

| 문서 | 내용 |
| --- | --- |
| [Design System](design_system.md) | 원칙, 토큰, typography, component, 화면 패턴, QA |
| [Brand Palette](brand/README.md) | 브랜드/시맨틱 컬러 결정과 팔레트 산출물 |
| [Pill, Chip, Badge Token Plan](design/pill_chip_badge_token_plan.md) | pill/chip/badge 토큰 정리 계획 |
| [Transaction Ledger Redesign](design/transaction_ledger_redesign.md) | 거래 내역 화면 개편 방향 |
| [Transaction History UI/UX Improvement Plan](design/transaction_history_ui_ux_improvement_plan.md) | 거래 내역 필터와 목록 UX 개선 |

## Backend & Operations

| 문서 | 내용 |
| --- | --- |
| [Data & Sync Flow](data_and_sync.md) | 데이터 모델과 앱/서버 sync 설계 |
| [Supabase Overview](supabase_overview.md) | Supabase 폴더와 원격 프로젝트 구성 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | Supabase CLI, env, migration 운영 절차 |
| [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) | 초기 통합 구현 보고서 |

## Feature Work

작업 기록은 `plan.md` 중심으로 보관합니다. 오래된 implementation/test/verification report는 핵심만 plan 또는 category README에 병합하고 제거했습니다.

| 분류 | 인덱스 |
| --- | --- |
| 새로운 기능 개발 | [features/new_feature_development](features/new_feature_development/README.md) |
| 단순 패치 | [features/simple_patches](features/simple_patches/README.md) |
| 버그 픽스 | [features/bug_fixes](features/bug_fixes/README.md) |

## Process Guides

| 문서 | 기준 |
| --- | --- |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 새 기능 개발 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현 가능한 문제 수정과 회귀 검증 |

## Maintenance Rules

- 새 작업은 해당 category README와 [Document Inventory](document_inventory.md)를 함께 갱신합니다.
- 장기 기준 문서는 `docs/` 바로 아래 또는 도메인 폴더에 둡니다.
- 일회성 실행 리포트는 장기 보관하지 말고 `plan.md`에 핵심 결과만 병합합니다.
- 비밀값, 개인 계정 정보, service role key는 문서에 직접 적지 않습니다.
