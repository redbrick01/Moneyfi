# Login Sync Failure UX Verification Test Plan

## Scope

LoginPage 로그인 후 동기화 실패 UX와 SyncOverlay failure state copy를 검증한다.

## Quality Goals

- 사용자가 실패 단계별로 무엇을 확인해야 하는지 알 수 있다.
- 코어 데이터 실패와 뉴스/스냅샷 실패의 심각도가 구분된다.
- 작은 화면에서도 실패 상세, 재시도, 보조 버튼이 잘리지 않는다.
- 기존 LoginPage smoke test가 계속 통과한다.

## Automated Test Plan

```bash
dart format lib/pages/login_page.dart lib/pages/sync_overlay.dart test/sync_overlay_test.dart
flutter test test/sync_overlay_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 코어 데이터 실패를 강제로 만들고 `닫기`, `재시도`, 상세 안내 문구를 확인한다.
- 뉴스 단계 실패를 강제로 만들고 `앱으로 이동` 버튼과 My 재동기화 안내를 확인한다.
- 스냅샷 단계 실패를 강제로 만들고 분석 차트 최신성 안내를 확인한다.
- 성공 경로의 기존 `로그인됐어요` flow가 유지되는지 확인한다.

## Responsive Checklist

- 짧은 viewport에서 SyncOverlay가 스크롤되고 버튼이 잘리지 않는다.
- 긴 상세 문구가 error card 밖으로 넘치지 않는다.
- 단계 row meta가 한 줄을 넘어가도 아이콘과 겹치지 않는다.

## Regression Test Commands

```bash
flutter test test/sync_overlay_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
```

## Acceptance Criteria

- SyncOverlay failure test가 단계별 detail/retry/close label을 확인한다.
- LoginPage standalone smoke test가 통과한다.
- 정적 분석이 통과한다.
- 수동 QA 미수행 항목은 test report에 남긴다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| 뉴스/스냅샷 실패 후 앱 이동이 혼란스러움 | Low | Medium | detail에 코어 데이터 적용 여부와 My 재동기화 안내 명시 |
| 코어 실패 후 앱 진입 기대 | Medium | Medium | 코어 실패는 `닫기`와 재시도 중심으로 유지 |
| 문구가 작은 화면에서 길어짐 | Medium | Low | 기존 SyncOverlay scroll container 유지 |

## Future Test Expansion

- SyncService를 typed result로 확장한 뒤 네트워크/인증/schema mismatch별 문구 테스트를 추가한다.
- LoginPage 전체 로그인 flow를 mock Auth/Sync service로 widget test한다.
