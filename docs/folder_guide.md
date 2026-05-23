# Folder Guide

이 문서는 MONEYFY 저장소의 폴더가 어떤 책임을 갖는지 설명합니다. 생성 산출물이나 플랫폼 기본 파일까지 모두 깊게 읽기보다, 먼저 아래 주요 폴더를 중심으로 보면 됩니다.

## Root

| 경로 | 역할 |
| --- | --- |
| `README.md` | 프로젝트 첫 안내와 실행 방법 |
| `pubspec.yaml` | Flutter 의존성, SDK 버전, asset 선언 |
| `analysis_options.yaml` | Dart/Flutter lint 설정 |
| `assets/` | 앱 아이콘, 예시 설정, 런타임 config asset |
| `docs/` | 제품, 설계, 운영 문서 |
| `lib/` | Flutter 앱의 실제 Dart 소스 |
| `supabase/` | 원격 DB 마이그레이션과 Edge Functions |
| `test/` | 위젯, 서비스, 데이터 흐름 테스트 |
| `tools/` | 유지보수 스크립트 |
| `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` | Flutter 플랫폼별 프로젝트 |

## `lib/`

`lib/`는 앱 구현의 중심입니다. 자세한 안내는 [lib/README.md](../lib/README.md)를 참고하세요.

| 경로 | 역할 |
| --- | --- |
| `lib/main.dart` | 앱 초기화와 최상위 MaterialApp |
| `lib/db/` | Drift 로컬 DB, 테이블, 마이그레이션, 쿼리 |
| `lib/pages/` | 화면 단위 UI와 화면별 상태 |
| `lib/pages/forms/` | 자산, 보유, 거래, 현금 계좌 입력 폼 |
| `lib/services/` | 인증, 동기화, 시세, 뉴스, AI 진단 연동 |
| `lib/models/` | 화면과 서비스가 공유하는 모델 |
| `lib/components/` | 재사용 UI 컴포넌트 |
| `lib/widgets/` | 기존 공용 위젯과 뉴스 카드 |
| `lib/design_system/` | theme extension, 토큰, 브랜드 팔레트 |
| `lib/theme/` | 레거시/보조 테마 값 |
| `lib/ui_scaffold/` | 공통 페이지 scaffold |
| `lib/utils/` | 표시 통화 등 유틸리티 |

## `supabase/`

`supabase/`는 서버 측 변경의 기준입니다. 자세한 안내는 [supabase/README.md](../supabase/README.md)와 [Supabase Overview](supabase_overview.md)를 참고하세요.

| 경로 | 역할 |
| --- | --- |
| `supabase/config.toml` | 로컬 Supabase CLI 설정 |
| `supabase/migrations/` | 현재 원격 schema를 재현하는 SQL migration |
| `supabase/migrations_archive/` | 과거 migration 보관본 |
| `supabase/functions/` | Deno 기반 Edge Functions |
| `supabase/.temp/` | 로컬 CLI 링크 메타데이터, git 관리 제외 대상 |

## `docs/`

설계와 운영 맥락을 남기는 폴더입니다.

| 문서 | 역할 |
| --- | --- |
| `project_overview.md` | 제품과 앱 구조 입문 |
| `data_and_sync.md` | 로컬 DB, 원장, 동기화 흐름 |
| `supabase_overview.md` | Supabase schema와 함수 구성 |
| `design_system.md` | MONEYFY UI 원칙과 컴포넌트 규칙 |
| `supabase_cli_runbook.md` | CLI로 원격 Supabase 운영하는 절차 |

## Platform Folders

Flutter가 생성한 플랫폼 프로젝트입니다. 일반 기능 개발은 대부분 `lib/`에서 끝나지만, 아래 작업은 플랫폼 폴더를 봐야 합니다.

| 경로 | 주로 수정하는 경우 |
| --- | --- |
| `android/` | Android 권한, Gradle 설정, 패키지 설정 |
| `ios/` | iOS 권한, signing, storyboard, asset catalog |
| `macos/` | macOS 권한, entitlements, CocoaPods |
| `web/` | manifest, favicon, web icon |
| `linux/`, `windows/` | 데스크톱 빌드 설정 |

## Generated And Local Folders

아래 폴더는 사람이 직접 편집하는 대상이 아닙니다.

| 경로 | 설명 |
| --- | --- |
| `build/` | Flutter 빌드 산출물 |
| `.dart_tool/` | Dart/Flutter 도구 캐시 |
| `ios/Pods/`, `macos/Pods/` | CocoaPods 산출물 |
| `lib/db/app_database.g.dart` | Drift generated code. 수동 수정하지 않습니다. |

## Where To Start By Task

| 작업 | 먼저 볼 곳 |
| --- | --- |
| 새 화면 추가 | `lib/pages/`, `lib/components/`, `lib/design_system/` |
| DB 필드 추가 | `lib/db/app_database.dart`, `supabase/migrations/`, `sync_service.dart` |
| Supabase 함수 수정 | `supabase/functions/`, `lib/services/` |
| 디자인 조정 | `docs/design_system.md`, `lib/design_system/`, `lib/components/` |
| 테스트 추가 | `test/README.md`, 기존 `test/*_test.dart` |
| 앱 아이콘 갱신 | `assets/`, `tools/generate_app_icons.sh` |
