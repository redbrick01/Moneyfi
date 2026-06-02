# Login Sync Failure UX Plan

## Product Goal

로그인 직후 코어 데이터/뉴스/스냅샷 동기화 일부 실패해도 사용자: 현재 상태 + 다음 행동 명확히 앎.

## Current Baseline

- LoginPage: 코어 데이터 -> 뉴스 -> 스냅샷 순서 처리. SyncOverlay에 단계 상태 표시.
- 실패 copy: "단계에서 실패했어요" 수준. 사용자: 재시도 필요? 앱 계속 써도 됨? 모름.
- 뉴스/스냅샷 같은 부가 데이터만 실패해도 LoginPage에 남을 수 있음.

## Success Criteria

- 코어 데이터 실패: 앱 시작 필수 데이터 미적용 명확히 안내.
- 뉴스 실패: 자산/거래 데이터 적용됨. 뉴스 나중 재동기화 가능 안내.
- 스냅샷 실패: 분석 차트/성과 일부 최신 아닐 수 있음 안내.
- 코어 이후 단계 실패: 앱 이동 선택지 제공.
- SyncOverlay 실패 상세, 재시도 안내, 단계별 meta 자동 테스트 고정.

## Proposed UX

- 실패 카드: 짧은 제목 + 구체 detail 표시.
- RetryRow: 단계별 재시도 판단 기준 표시.
- 코어 실패 보조 버튼: `닫기` 유지.
- 뉴스/스냅샷 실패 보조 버튼: `앱으로 이동` 표시, LoginPage 닫음.

## Data/API Changes

- DB schema, Supabase Edge Function, sync payload 계약 변경 없음.
- LoginPage + SyncOverlay UI copy, close behavior만 변경.

## Development Phases

1. LoginPage 동기화 단계 + SyncOverlay 표현 확인.
2. 단계별 실패 copy 모델 추가.
3. SyncOverlay에 상세 문구, 재시도 문구, close label 주입 지원.
4. Widget/unit 테스트로 문구 + 행동 기준 고정.
5. 문서 + 검증 결과 업데이트.

## MVP Scope

- LoginPage post-login sync 실패 안내 개선.
- SyncOverlay optional copy prop 추가.
- `sync_overlay_test.dart` 업데이트.

## Test Plan

```bash
dart format lib/pages/login_page.dart lib/pages/sync_overlay.dart test/sync_overlay_test.dart
flutter test test/sync_overlay_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- 뉴스/스냅샷 실패: 코어 데이터 이미 적용됨. 앱 진입 허용.
- 코어 데이터 실패: 로그인 됐어도 로컬 데이터 비었을 수 있음. 앱 진입보다 재시도 우선.
- 세부 실패 원인: 서비스가 bool/int만 반환. 이번 patch는 사용자 행동 중심 copy로 해결.

## Feasibility And Feedback

- 기존 SyncOverlay 구조에 optional copy만 추가. 변경 범위 작음.
- 정확한 서버 오류 분류 필요하면 SyncService 반환 타입 확장 필요. 이번 MVP 제외.
- 이후 typed result로 네트워크 오류, 인증 만료, payload version mismatch 구분 가능.