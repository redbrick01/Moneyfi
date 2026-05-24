# CI/CD Minimum Verification Test Plan

## Scope

GitHub Actions 최소 Flutter CI workflow와 로컬 검증 명령을 확인한다.

## Quality Goals

- Workflow YAML이 저장소에 추가되어 push/PR/manual trigger를 지원한다.
- CI 명령은 로컬 개발 프로세스 필수 명령과 일치한다.
- Workflow job은 읽기 권한만 사용한다.
- 로컬에서 `flutter analyze`와 `flutter test`가 통과한다.

## Automated Test Plan

```bash
flutter analyze
flutter test
git diff --check
```

## Manual QA Plan

- GitHub에 push한 뒤 Actions 탭에서 `Flutter CI` workflow가 실행되는지 확인한다.
- PR 생성 시 `Analyze and test` job이 표시되는지 확인한다.
- 실패 시 job log에서 `Analyze` 또는 `Test` 단계가 명확히 구분되는지 확인한다.

## Acceptance Criteria

- `.github/workflows/flutter-ci.yml`이 존재한다.
- Workflow가 `push`, `pull_request`, `workflow_dispatch`를 포함한다.
- Workflow가 `flutter analyze`와 `flutter test`를 실행한다.
- 로컬 `flutter analyze`, `flutter test`, `git diff --check`가 통과한다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| CI Flutter stable과 로컬 SDK 차이 | Medium | Medium | 후속으로 `.fvmrc` 또는 `flutter-version` pinning 검토 |
| 첫 원격 workflow 실행 미확인 | Medium | Low | test report에 원격 미확인 명시 |
| 전체 test 시간이 길어짐 | Low | Low | cache 활성화 |

## Future Test Expansion

- Branch protection에 `Analyze and test` required check 연결.
- `flutter test --coverage`와 coverage artifact upload 추가.
- Android/iOS build smoke job 추가.
