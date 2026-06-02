# Optional Local Config Plan

## Product Goal

`assets/config.json` 없는 checkout/CI에서도 앱 빌드·시작 안 깨짐. 사용자 Supabase 설정 필요 이유 + 조치 방법 알게 함.

## Current Baseline

- `pubspec.yaml`이 `assets/config.json` 단일 파일 asset 등록.
- 실제 `assets/config.json`은 git 제외 로컬 secret 파일.
- 파일 없으면 Flutter asset bundling 단계 실패 가능.
- AuthService는 asset load 실패를 empty config 처리. 하지만 asset 자체 필수면 그 전 빌드 깨짐.

## Success Criteria

- `assets/config.json` 없어도 Flutter asset bundling 안 실패.
- AuthService는 설정 파일 누락을 empty config 처리 + setup message 남김.
- My 화면은 config 누락/비어 있음 상태에서 할 일 안내.
- README + assets guide가 optional config 구조 설명.
- `flutter analyze`, 관련 smoke test, `flutter test` 통과.

## Proposed UX

- Supabase 설정 없으면 기존처럼 로그인/동기화 비활성.
- My 화면에서 `assets/config.example.json` 복사해 `assets/config.json` 만들고 URL/Anon Key 채우라 안내.
- 설정 없어도 앱 시작.

## Data/API Changes

- DB schema, Supabase Edge Function, remote API 변경 없음.
- Flutter asset 등록을 `assets/config.json`에서 `assets/` 디렉터리로 변경.

## Development Phases

1. 현재 asset 등록 + AuthService config load 흐름 확인.
2. `pubspec.yaml` asset 등록 optional-friendly 구조로 변경.
3. AuthService/My 화면/README/assets guide 안내 문구 보강.
4. 로컬 analyze/test로 앱 시작 + asset bundle 회귀 확인.

## MVP Scope

- `assets/config.json` 누락 대응.
- startup 안내 + 문서 보강.
- 환경변수 기반 Supabase config 주입은 후속 과제.

## Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart
flutter analyze
flutter test test/widget_test.dart
flutter test
git diff --check
```

## Risks And Decisions

- `assets/` 디렉터리 전체 등록은 현재 작은 asset 폴더라 부담 낮음.
- 실제 secret 파일 `assets/config.json`은 계속 git 제외.
- Supabase 설정 없는 앱 사용 범위는 로컬 데이터/비로그인 기능 한정.

## Feasibility And Feedback

- 빌드 실패 원인을 pubspec asset 등록에서 제거. CI + 신규 checkout 안정성 상승.
- 기존 AuthService empty config 처리 유지. 런타임 변경 범위 작음.
- 후속 `--dart-define=SUPABASE_URL` 지원 시 배포 환경 유연성 더 좋음.