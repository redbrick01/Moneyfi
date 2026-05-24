# CI/CD Minimum Plan

## Product Goal

GitHub Actions에서 Flutter 정적 분석과 테스트를 자동 실행해 제출 전 기본 안정성을 확보한다.

## Current Baseline

- 저장소에 `.github/workflows` CI 설정이 없다.
- 로컬 개발 프로세스는 `flutter analyze`와 `flutter test` 실행을 요구한다.
- Flutter SDK 버전은 별도 `.fvmrc`가 없고 `pubspec.yaml`의 Dart SDK 제약은 `^3.11.1`이다.

## Success Criteria

- Push와 Pull Request에서 CI가 자동 실행된다.
- CI는 `flutter pub get`, `flutter analyze`, `flutter test`를 순서대로 실행한다.
- 수동 실행을 위한 `workflow_dispatch`가 있다.
- GitHub token 권한은 읽기 전용으로 제한한다.
- Actions cache를 사용해 반복 실행 비용을 낮춘다.

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

- 앱 런타임, DB schema, Supabase 구성은 변경하지 않는다.
- GitHub Actions workflow만 추가한다.

## Development Phases

1. 기존 CI 설정과 Flutter 버전 단서 확인.
2. 최소 GitHub Actions workflow 추가.
3. 문서와 검증 계획 추가.
4. 로컬에서 `flutter analyze`, `flutter test`, `git diff --check`로 workflow 명령과 동일한 핵심 명령 검증.

## MVP Scope

- analyze/test 자동화만 포함한다.
- build artifact, 배포, release signing, coverage upload, secret 기반 배포는 제외한다.

## Test Plan

```bash
flutter analyze
flutter test
git diff --check
```

## Risks And Decisions

- Flutter stable 최신 버전을 사용하므로 CI가 로컬 SDK보다 앞설 수 있다. 필요하면 후속으로 `.fvmrc`나 `flutter-version` pinning을 추가한다.
- 전체 `flutter test`는 로컬보다 CI 시간이 길 수 있으나 제출 안정성 확보가 우선이다.
- GitHub Actions 첫 실행은 원격 push 이후에만 실제 확인할 수 있다.

## Feasibility And Feedback

- 변경 범위가 workflow와 문서에 한정되어 앱 회귀 위험이 낮다.
- 기존 개발 프로세스의 필수 명령과 CI 명령이 일치한다.
- 후속 단계에서 branch protection과 required status check를 연결하면 제출 안정성이 더 높아진다.
