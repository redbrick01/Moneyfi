# CI/CD Minimum Plan

## Product Goal

GitHub Actions에서 Flutter 정적 분석/test 자동 실행. 제출 전 기본 안정성 확보.

## Current Baseline

- 저장소에 `.github/workflows` CI 설정 없음.
- 로컬 개발 프로세스는 `flutter analyze`, `flutter test` 필요.
- Flutter SDK 버전 별도 `.fvmrc` 없음. `pubspec.yaml` Dart SDK 제약 `^3.11.1`.

## Success Criteria

- Push/Pull Request에서 CI 자동 실행.
- CI는 `flutter pub get`, `flutter analyze`, `flutter test` 순서 실행.
- 수동 실행용 `workflow_dispatch` 있음.
- GitHub token 권한 읽기 전용.
- Actions cache 사용해 반복 실행 비용 감소.

## Proposed Workflow

- Workflow file: `.github/workflows/flutter-ci.yml`
- Runner: `ubuntu-latest`
- Actions:
  - `actions/checkout@v4`
  - `subosito/flutter-action@v2`
- Commands:
  - `flutter --version`
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`

## Data/API Changes

- 앱 런타임, DB schema, Supabase 구성 변경 없음.
- GitHub Actions workflow만 추가.

## Development Phases

1. 기존 CI 설정/Flutter 버전 단서 확인.
2. 최소 GitHub Actions workflow 추가.
3. 문서/검증 계획 추가.
4. 로컬에서 `flutter analyze`, `flutter test`, `git diff --check`로 workflow 핵심 명령 검증.

## MVP Scope

- analyze/test 자동화만 포함.
- build artifact, 배포, release signing, coverage upload, secret 기반 배포 제외.

## Test Plan

```bash
flutter analyze
flutter test
git diff --check
```

## Risks And Decisions

- Flutter stable 최신 버전 사용. CI가 로컬 SDK보다 앞설 수 있음. 필요 시 후속으로 `.fvmrc`나 `flutter-version` pinning 추가.
- 전체 `flutter test`는 CI 시간이 로컬보다 길 수 있음. 제출 안정성 우선.
- GitHub Actions 첫 실행은 원격 push 이후 실제 확인 가능.

## Feasibility And Feedback

- 변경 범위 workflow/문서 한정. 앱 회귀 위험 낮음.
- 기존 개발 필수 명령과 CI 명령 일치.
- 후속으로 branch protection/required status check 연결하면 제출 안정성 증가.