# Document Inventory

이 문서는 MONEYFY 저장소의 Markdown 문서를 한곳에서 찾기 위한 색인입니다. 현재 폴더 구조를 기준으로 읽는 순서와 보관 위치를 정리합니다.

## Reading Order

| 순서 | 문서 | 목적 |
| --- | --- | --- |
| 1 | [Project Overview](project_overview.md) | 제품 목적, 핵심 기능, 런타임 구조 파악 |
| 2 | [Folder Guide](folder_guide.md) | 저장소 폴더별 책임 파악 |
| 3 | [Data & Sync Flow](data_and_sync.md) | 로컬 DB, 원장, Supabase sync 흐름 파악 |
| 4 | [Supabase Overview](supabase_overview.md) | 원격 schema, Edge Functions, 운영 포인트 파악 |
| 5 | [Design System](design_system.md) | MONEYFY UI/UX 단일 기준 파악 |
| 6 | [Implementation History](reports/implementation_history.md) | 제거된 과거 구현 계획의 압축 히스토리 확인 |

## Repository-Level Docs

| 경로 | 역할 |
| --- | --- |
| [../README.md](../README.md) | 프로젝트 소개, 실행 방법, 주요 문서 진입점 |
| [../assets/README.md](../assets/README.md) | 앱 asset과 로컬 config 예시 안내 |
| [../assets/fonts/README.md](../assets/fonts/README.md) | 앱 폰트 asset 안내 |
| [../lib/README.md](../lib/README.md) | Flutter 앱 소스 구조, 화면/서비스 map |
| [../supabase/README.md](../supabase/README.md) | Supabase 폴더 구조, 함수 그룹, 운영 명령 |
| [../test/README.md](../test/README.md) | 테스트 폴더와 테스트 작성 기준 |

## Core Product Docs

| 문서 | 역할 |
| --- | --- |
| [README](README.md) | `docs/`의 기본 진입점 |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 역할 |
| [Data & Sync Flow](data_and_sync.md) | Drift DB, 원장 모델, Supabase 동기화 |
| [Supabase Overview](supabase_overview.md) | Supabase migration, Edge Function, 운영 포인트 |
| [Supabase CLI Runbook](supabase_cli_runbook.md) | 원격 Supabase 운영 절차 |
| [Embedding Project Boundary](embedding_project_boundary.md) | 앱 repo와 별도 임베딩 연구 repo의 책임 경계 |

## Design And UI Docs

| 문서 | 역할 |
| --- | --- |
| [Design System](design_system.md) | UI/UX 단일 기준: 방향, 토큰, typography, component, 상태, 화면 패턴, QA |
| [Brand Palette](brand/README.md) | 브랜드/시맨틱 컬러 결정, 구현 팔레트, 팔레트 이미지 산출물 |

## Process Guides

| 문서 | 기준 |
| --- | --- |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 새 기능 개발 |
| [Simple Patch Process Guidelines](guides/simple_patch_process_guidelines.md) | 구조 개선, 보안/품질 강화, 테스트/CI 보강 |
| [Bug Fix Process Guidelines](guides/bug_fix_process_guidelines.md) | 재현 가능한 문제 수정과 회귀 검증 |

## Reports

| 문서 | 역할 |
| --- | --- |
| [Implementation History](reports/implementation_history.md) | Markdown Cleanup Phase 2에서 제거된 완료 구현 계획의 압축 색인 |
| [Implementation Report 2026-05-24](reports/implementation_report_20260524.md) | 2026-05-24 기준 통합 구현 보고서 |

## Maintenance Checklist

- 현재 동작은 source code, tests, Supabase migrations, canonical docs를 기준으로 확인합니다.
- 완료된 feature plan, Superpowers plan/spec, generated audit은 개별 Markdown으로 장기 보관하지 않습니다.
- 과거 구현 계획의 흔적이 필요하면 `docs/reports/implementation_history.md`에 짧게 남깁니다.
- 루트 성격의 장기 문서는 `docs/` 바로 아래에 두고, 비밀값, 개인 계정 정보, service role key는 문서에 적지 않습니다.
