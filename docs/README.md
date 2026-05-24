# MONEYFY Docs

프로젝트 문서는 디자인 규칙, 기능 설계, 운영 절차를 빠르게 찾을 수 있도록 이 페이지에서 관리합니다.

## Start Here

| 문서 | 내용 |
| --- | --- |
| [Project Overview](project_overview.md) | 앱 목적, 주요 기능, 런타임 구조, 개발 흐름 |
| [Folder Guide](folder_guide.md) | 루트 및 주요 하위 폴더별 역할 |
| [Development Process Guidelines](guides/development_process_guidelines.md) | 기능 설계, 구현, 검증, 보고서 작성 개발 규칙 |
| [Data & Sync Flow](data_and_sync.md) | 로컬 Drift DB, 원장 모델, Supabase 동기화 흐름 |
| [Supabase Overview](supabase_overview.md) | Supabase 마이그레이션, Edge Functions, secrets, 운영 포인트 |

## Design & UI

| 문서 | 내용 |
| --- | --- |
| [Design System](design_system.md) | MONEYFY UI 원칙, 색상, 컴포넌트 사용 규칙 |
| [getdesign Application Plan](getdesign_application_plan.md) | getdesign.md 기반 디자인 레퍼런스 적용 계획 |
| [Main Asset Card Format](main_asset_card_format.md) | 메인 자산 카드 표시 포맷 |
| [Transaction Ledger Redesign](transaction_ledger_redesign.md) | 거래 내역 화면 개편 방향 |
| [Investment Performance Docs](features/investment_performance/README.md) | 원장 기반 투자성과 리포트 기능 계획, 검증 계획, 테스트 보고서 |
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

## Maintenance Rules

- 새 문서를 추가하면 이 인덱스에 링크를 함께 추가합니다.
- 기능별 문서는 `docs/features/<feature>/` 아래에 모읍니다.
- 공통 개발 규칙과 가이드는 `docs/guides/` 아래에 둡니다.
- 임시 문서는 관련 기능 폴더 안에서 `tmp_` prefix를 붙이고, 루트 인덱스에는 직접 연결하지 않습니다.
- 실행 가능한 절차는 명령어 블록을 포함합니다.
- 키, 토큰, 개인 계정 정보는 문서에 직접 적지 않습니다.
- 오래된 설계 문서는 삭제보다 `Archived` 섹션을 추가해 맥락을 남깁니다.
