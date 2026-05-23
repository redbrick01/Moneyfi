# MONEYFY

> 자산 현황, 포트폴리오, 통계, 스냅샷, AI 분석을 한 곳에서 관리하는 Flutter 기반 개인 자산 관리 앱입니다.

## Overview

MONEYFY는 로컬 DB와 Supabase 동기화를 함께 사용하는 자산 관리 앱입니다. 보유 자산과 거래 내역을 기반으로 총자산 변화, 월별 추이, 자산군 비중, 포트폴리오 진단을 빠르게 확인할 수 있도록 구성되어 있습니다.

처음 프로젝트를 보는 경우 아래 순서로 읽으면 전체 구조를 빠르게 잡을 수 있습니다.

1. [Project Overview](docs/project_overview.md)
2. [Folder Guide](docs/folder_guide.md)
3. [Data & Sync Flow](docs/data_and_sync.md)
4. [Supabase Overview](docs/supabase_overview.md)

## Features

- 총자산, 손익, 자산군 현황을 보여주는 대시보드
- 보유 자산, 현금 계좌, 거래 내역 관리
- 자산 탭 정렬, 드래그 재정렬, 스와이프 숨김/해제
- 일별 스냅샷 저장 및 상세 비교
- 통계 탭의 월별 추이, 캘린더, 월말 자산 확인
- AI 포트폴리오 분석 카드와 리스크 요약
- Supabase 기반 로그인, 동기화, 뉴스 요약 데이터 연동
- KIS API 기반 국내/해외/펀드 시세 조회

## Tech Stack

| Area | Stack |
| --- | --- |
| App | Flutter, Dart |
| Local DB | Drift, SQLite |
| Backend | Supabase |
| Storage | Flutter Secure Storage |
| UI | Material, MONEYFY design tokens |
| Tests | `flutter_test` |

## Project Structure

```text
.
├── android/              # Android platform project
├── assets/               # App assets and local config example
├── docs/                 # Design, runbook, and product notes
├── ios/                  # iOS platform project
├── lib/
│   ├── components/       # Reusable UI building blocks
│   ├── data/             # Static/sample data helpers
│   ├── db/               # Drift database and generated queries
│   ├── design_system/    # Brand/spec documentation assets
│   ├── models/           # App data models
│   ├── pages/            # Screen-level pages and forms
│   ├── services/         # Auth, sync, market data, summaries
│   ├── theme/            # Colors and app theme
│   ├── ui_scaffold/      # Shared app shell scaffolding
│   ├── utils/            # Utility helpers
│   └── widgets/          # Legacy/shared widgets
├── supabase/             # Supabase config, functions, migrations
├── test/                 # Widget, service, and flow tests
├── tools/                # Maintenance scripts
└── web/                  # Web target assets
```

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Create local config files

실제 키가 들어가는 파일은 git에 올리지 않습니다. 샘플 파일을 복사해서 로컬에서만 사용하세요.

```bash
cp assets/config.example.json assets/config.json
cp config.example.json config.json
```

`assets/config.json`:

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY"
}
```

`config.json` 또는 실행 시 `--dart-define`으로 KIS 값을 전달합니다.

```bash
flutter run \
  --dart-define=KIS_APP_KEY=YOUR_KIS_APP_KEY \
  --dart-define=KIS_APP_SECRET=YOUR_KIS_APP_SECRET
```

### 3. Run the app

```bash
flutter run
```

## Development

자주 쓰는 명령어입니다.

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

앱 아이콘을 다시 생성할 때:

```bash
./tools/generate_app_icons.sh
```

## Git Guide

이 저장소는 소스 코드, 문서, 샘플 설정 파일만 관리하고 로컬 산출물은 제외합니다.

- 커밋 대상: `lib/`, `test/`, `docs/`, `assets/config.example.json`, `config.example.json`, `pubspec.yaml`, platform project files
- 제외 대상: `build/`, `.dart_tool/`, `.idea/`, `ios/Pods/`, `macos/Pods/`, 실제 키가 들어간 `assets/config.json`, `config.json`
- 새 비밀값이 생기면 `.gitignore`에 먼저 추가한 뒤 파일을 생성하세요.

초기 원격 저장소 연결 예시:

```bash
git init
git add .
git commit -m "Initial MONEYFY project"
git branch -M main
git remote add origin YOUR_GIT_REMOTE_URL
git push -u origin main
```

## Documentation

- [Docs Index](docs/README.md)
- [Project Overview](docs/project_overview.md)
- [Folder Guide](docs/folder_guide.md)
- [Data & Sync Flow](docs/data_and_sync.md)
- [Supabase Overview](docs/supabase_overview.md)
- [Design System](docs/design_system.md)
- [Supabase CLI Runbook](docs/supabase_cli_runbook.md)
- [UI Snapshot Targets](docs/ui_snapshot_targets.md)

## Security Notes

- `SUPABASE_SERVICE_ROLE_KEY`는 앱, README, 클라이언트 설정 파일에 넣지 않습니다.
- `assets/config.json`과 `config.json`은 로컬 전용 파일입니다.
- 실수로 키를 커밋했다면 키를 폐기하고 재발급한 뒤 git history 정리를 진행하세요.
