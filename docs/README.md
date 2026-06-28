# MONEYFY Docs

프로젝트 문서는 제품 기준, 설계 기준, 운영 절차를 빠르게 찾도록 관리합니다. 완료된 작업 계획은 개별 문서로 장기 보관하지 않고, 필요한 히스토리만 [Implementation History](reports/implementation_history.md)에 압축해 둡니다.

## Start Here

| 문서 | 내용 |
| --- | --- |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조, 개발 흐름 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 책임 |
| [Document Inventory](document_inventory.md) | 저장소 Markdown 색인과 보관 규칙 |
| [Data & Sync Flow](data_and_sync.md) | 로컬 Drift DB, 원장 모델, Supabase sync 흐름 |
| [Supabase Overview](supabase_overview.md) | Supabase migration, Edge Functions, 운영 포인트 |
| [Design System](design_system.md) | MONEYFY UI/UX 단일 기준 |

## Design & UI

| 문서 | 내용 |
| --- | --- |
| [Design System](design_system.md) | 원칙, 토큰, typography, component, 화면 패턴, QA |
| [Brand Palette](brand/README.md) | 브랜드/시맨틱 컬러 결정과 팔레트 산출물 |

## Backend & Operations

| 문서 | 내용 |
| --- | --- |
| [Data & Sync Flow](data_and_sync.md) | 데이터 모델과 앱/서버 sync 설계 |
| [Supabase Overview](supabase_overview.md) | Supabase 폴더와 원격 프로젝트 구성 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | Supabase CLI, env, migration 운영 절차 |

## History

| 문서 | 내용 |
| --- | --- |
| [Implementation History](reports/implementation_history.md) | 정리된 과거 구현 계획/스펙/기능 기록 색인 |
| [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) | 초기 통합 구현 보고서 |

Historical implementation plans were consolidated into `docs/reports/implementation_history.md`. Current behavior should be read from canonical docs, source code, tests, and Supabase migrations rather than old task plans.

## Process Guides

| 문서 | 기준 |
| --- | --- |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 새 기능 개발 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현 가능한 문제 수정과 회귀 검증 |

## Maintenance Rules

- 장기 기준 문서는 `docs/` 바로 아래 또는 도메인 폴더에 둡니다.
- 완료된 task plan은 개별 파일로 보관하지 않고 `docs/reports/implementation_history.md`에 요약합니다.
- 비밀값, 개인 계정 정보, service role key는 문서에 직접 적지 않습니다.
