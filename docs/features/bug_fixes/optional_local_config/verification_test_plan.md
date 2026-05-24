# Optional Local Config Verification Test Plan

## Scope

`assets/config.json` 누락 대응을 위한 Flutter asset 등록, runtime 안내, 문서 변경을 검증한다.

## Quality Goals

- `pubspec.yaml`이 secret 파일 단일 등록에 의존하지 않는다.
- 앱 smoke test가 asset bundle 문제 없이 통과한다.
- 설정 누락 상태에서 사용자 안내가 명확하다.

## Automated Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart
flutter analyze
flutter test test/widget_test.dart
flutter test
git diff --check
```

## Manual QA Plan

- 로컬에서 `assets/config.json`을 임시로 제거한 상태로 `flutter run` 또는 `flutter test test/widget_test.dart`를 확인한다.
- My 화면에서 Supabase 설정 안내 문구가 보이는지 확인한다.
- `assets/config.json`을 다시 만든 뒤 로그인/동기화 기능이 기존처럼 동작하는지 확인한다.

## Acceptance Criteria

- `pubspec.yaml` asset entry가 `assets/` 디렉터리를 등록한다.
- AuthService setup message가 config 누락 조치를 설명한다.
- README와 `assets/README.md`가 optional config 구조를 설명한다.
- 로컬 자동 검증 명령이 통과한다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| assets 디렉터리 전체 등록으로 불필요 파일 포함 | Low | Low | 현재 asset 폴더는 작고 secret 파일은 git 제외 |
| config 누락 상태에서 로그인 기대 혼란 | Medium | Low | My 화면과 README에 명확히 안내 |
| 실제 파일 제거 테스트 미수행 | Medium | Low | test report에 수동 QA로 남김 |

## Future Test Expansion

- `--dart-define` 기반 Supabase 설정 fallback 추가.
- AuthService config loader를 주입 가능하게 분리해 누락/invalid JSON 단위 테스트 추가.
