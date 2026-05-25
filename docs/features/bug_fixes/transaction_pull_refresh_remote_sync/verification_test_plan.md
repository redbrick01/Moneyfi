# Transaction Pull Refresh Remote Sync Verification Test Plan

## Automated Tests

- `flutter analyze`
  - 정적 분석 오류가 없어야 한다.
- `flutter test test/page_walkthrough_test.dart`
  - 기존 거래 페이지 event grouping test가 유지되어야 한다.
  - 새 widget test에서 `RefreshIndicator`를 당겼을 때 remote refresh callback이 정확히 호출되어야 한다.

## Manual QA

- 로그인된 상태에서 거래 탭을 아래로 당겨 새로고침한다.
- 네트워크가 가능하면 `get-sync-local-db`를 통해 core data가 내려받아진 뒤 거래 탭이 로컬 데이터를 다시 읽어야 한다.
- 로그아웃 또는 Supabase 설정이 없는 상태에서는 새로고침이 실패 화면 없이 기존 로컬 reload로 종료되어야 한다.

## Acceptance Criteria

- 거래 탭 pull-to-refresh가 서버 pull을 시도한다.
- 서버 pull 실패 또는 비로그인 상태가 거래 탭 렌더링을 깨지 않는다.
- 기존 거래 생성/삭제 flow와 자동 startup/resume sync flow가 변경되지 않는다.
