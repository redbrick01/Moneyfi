# Login Sync Failure UX Plan

## Product Goal

로그인 직후 코어 데이터, 뉴스, 스냅샷 동기화 중 일부가 실패해도 사용자가 현재 상태와 다음 행동을 명확히 이해하도록 안내한다.

## Current Baseline

- LoginPage는 코어 데이터, 뉴스, 스냅샷을 순서대로 처리하고 SyncOverlay에 단계 상태를 표시한다.
- 실패 문구는 "단계에서 실패했어요" 수준이라 사용자가 재시도해야 하는지, 앱을 계속 써도 되는지 알기 어렵다.
- 뉴스나 스냅샷처럼 부가 데이터만 실패해도 사용자가 LoginPage에 남을 수 있다.

## Success Criteria

- 코어 데이터 실패는 앱 시작에 필요한 데이터가 적용되지 않았음을 명확히 안내한다.
- 뉴스 실패는 자산/거래 데이터는 적용됐고 뉴스는 나중에 재동기화할 수 있음을 안내한다.
- 스냅샷 실패는 분석 차트/성과 일부가 최신이 아닐 수 있음을 안내한다.
- 코어 이후 단계 실패는 앱으로 이동할 수 있는 선택지를 제공한다.
- SyncOverlay의 실패 상세, 재시도 안내, 단계별 meta가 자동 테스트로 고정된다.

## Proposed UX

- 실패 카드에는 짧은 제목과 구체적 detail을 함께 표시한다.
- RetryRow에는 단계별 재시도 판단 기준을 표시한다.
- 코어 실패의 보조 버튼은 `닫기`로 유지한다.
- 뉴스/스냅샷 실패의 보조 버튼은 `앱으로 이동`으로 표시하고 LoginPage를 닫는다.

## Data/API Changes

- DB schema, Supabase Edge Function, sync payload 계약은 변경하지 않는다.
- LoginPage와 SyncOverlay의 UI copy 및 close behavior만 변경한다.

## Development Phases

1. LoginPage 동기화 단계와 SyncOverlay 표현 방식 확인.
2. 단계별 실패 copy 모델 추가.
3. SyncOverlay에 상세 문구, 재시도 문구, close label 주입 지원.
4. Widget/unit 테스트로 문구와 행동 기준 고정.
5. 문서와 검증 결과 업데이트.

## MVP Scope

- LoginPage post-login sync 실패 안내 개선.
- SyncOverlay의 optional copy prop 추가.
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

- 뉴스/스냅샷 실패는 코어 데이터가 이미 적용된 뒤라 앱 진입을 허용한다.
- 코어 데이터 실패는 로그인은 됐더라도 로컬 데이터가 비어 있을 수 있으므로 앱 진입보다 재시도를 우선 안내한다.
- 세부 실패 원인은 서비스가 bool/int로만 반환하므로 이번 patch에서는 사용자 행동 중심 copy로 해결한다.

## Feasibility And Feedback

- 기존 SyncOverlay 구조에 optional copy만 추가하면 되어 변경 범위가 작다.
- 정확한 서버 오류 분류까지 하려면 SyncService의 반환 타입 확장이 필요하므로 이번 MVP에서는 제외한다.
- 이후에는 네트워크 오류, 인증 만료, payload version mismatch를 구분하는 typed result로 확장할 수 있다.
