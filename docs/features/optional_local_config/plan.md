# Optional Local Config Plan

## Product Goal

`assets/config.json`이 없는 checkout이나 CI 환경에서도 앱 빌드와 시작이 실패하지 않게 하고, 사용자가 Supabase 설정이 필요한 이유와 조치 방법을 알 수 있게 한다.

## Current Baseline

- `pubspec.yaml`이 `assets/config.json` 단일 파일을 asset으로 등록한다.
- 실제 `assets/config.json`은 git에 올리지 않는 로컬 secret 파일이다.
- 파일이 없는 환경에서는 Flutter asset bundling 단계에서 실패할 수 있다.
- AuthService는 asset load 실패를 empty config로 처리하지만, asset 자체가 필수이면 그 전에 빌드가 깨질 수 있다.

## Success Criteria

- `assets/config.json`이 없어도 Flutter asset bundling이 실패하지 않는다.
- AuthService는 설정 파일 누락을 empty config로 처리하고 setup message를 남긴다.
- My 화면은 config 누락/비어 있음 상태에서 해야 할 일을 안내한다.
- README와 assets guide가 optional config 구조를 설명한다.
- `flutter analyze`, 관련 smoke test, `flutter test`가 통과한다.

## Proposed UX

- Supabase 설정이 없으면 기존처럼 로그인/동기화 기능을 비활성화한다.
- My 화면에서 `assets/config.example.json`을 복사해 `assets/config.json`을 만들고 URL/Anon Key를 채우라는 안내를 표시한다.
- 설정이 없어도 앱 자체는 시작된다.

## Data/API Changes

- DB schema, Supabase Edge Function, remote API는 변경하지 않는다.
- Flutter asset 등록을 `assets/config.json`에서 `assets/` 디렉터리로 변경한다.

## Development Phases

1. 현재 asset 등록과 AuthService config load 흐름 확인.
2. `pubspec.yaml` asset 등록을 optional-friendly 구조로 변경.
3. AuthService/My 화면/README/assets guide 안내 문구 보강.
4. 로컬 analyze/test로 앱 시작 및 asset bundle 회귀 확인.

## MVP Scope

- `assets/config.json` 누락 대응.
- startup 안내와 문서 보강.
- 환경변수 기반 Supabase config 주입은 후속 과제로 둔다.

## Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart
flutter analyze
flutter test test/widget_test.dart
flutter test
git diff --check
```

## Risks And Decisions

- `assets/` 디렉터리 전체 등록은 현재 작은 asset 폴더에서는 부담이 낮다.
- 실제 secret 파일인 `assets/config.json`은 여전히 git에 올리지 않는다.
- Supabase 설정이 없는 상태의 앱 사용 범위는 로컬 데이터/비로그인 기능으로 제한된다.

## Feasibility And Feedback

- 빌드 실패 원인을 pubspec asset 등록에서 제거하므로 CI와 신규 checkout 안정성이 오른다.
- 기존 AuthService empty config 처리를 유지해 런타임 변경 범위가 작다.
- 후속으로 `--dart-define=SUPABASE_URL` 방식도 지원하면 배포 환경 유연성이 더 좋아진다.
