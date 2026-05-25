# Transaction Pull Refresh Remote Sync Plan

## Bug Summary

거래 탭에서 당겨서 새로고침하면 화면은 다시 그려지지만 Supabase core data pull을 실행하지 않는다. 그래서 원격 DB에 거래 원장 데이터가 추가되어도 현재 거래 탭은 로컬 Drift DB에 이미 저장된 데이터만 다시 읽고, 로컬에 거래 원장이 없으면 계속 빈 상태를 보여준다.

## User Impact

사용자는 Supabase에 거래내역이 있다고 확인했는데 앱 거래 페이지에서는 "아직 거래 내역이 없어요" 상태를 보게 된다. 특히 앱 시작/로그인 동기화가 실패했거나 이후 원격 데이터가 바뀐 경우, 거래 탭에서 직접 복구할 방법이 없다.

## Reproduction Or Evidence

- `TransactionsPage._refreshPage()`는 `_loadPageData()`만 호출한다.
- `_loadPageData()`는 `AppDatabase.instance.fetchAssets()`로 로컬 DB만 읽는다.
- 로컬 앱 DB 확인 결과 `assets`, `holdings`, `cash_accounts`는 존재하지만 `transaction_events`, `transaction_lines`는 0건이었다.
- `get-sync-local-db` Edge Function 응답도 현재 계정에 대해 `transaction_events=0`, `transaction_lines=0`으로 반환되는 것을 확인했다. 이번 수정은 거래 탭의 수동 새로고침 동작을 서버 pull에 연결하는 범위로 한정한다.

## Root Cause Hypothesis

거래 탭 pull-to-refresh가 로컬 reload 전용으로 구현되어 있어, 사용자가 기대하는 "서버에서 다시 내려받기" 동작과 실제 동작이 다르다.

## Fix Strategy

- 거래 탭 새로고침 시 `SyncService.instance.refreshFromServer(reason: 'transactions_page_pull_refresh')`를 먼저 호출한다.
- 로그인/설정 미완료 등 동기화가 불가능한 상태에서는 기존처럼 로컬 reload만 수행한다.
- 서버 refresh 성공/실패와 무관하게 로컬 reload를 실행해 pull-to-refresh가 멈추고 현재 로컬 상태를 보여주도록 한다.
- 테스트를 위해 `TransactionsPage`에 선택적 remote refresh callback을 주입하되, production 기본 동작은 기존 service singleton을 사용한다.

## Non-goals

- 원격 DB에 실제 거래 원장이 0건인 문제를 보정하지 않는다.
- Supabase Edge Function, migration, schema를 변경하지 않는다.
- 거래 원장 표시 쿼리나 이벤트/라인 grouping 규칙을 바꾸지 않는다.

## Regression Test Plan

- `test/page_walkthrough_test.dart`에 거래 탭 pull-to-refresh가 remote refresh callback을 호출한 뒤 로컬 reload를 완료하는 widget test를 추가한다.
- `flutter analyze`로 정적 분석을 통과시킨다.
- 화면 진입 영향이 있으므로 `flutter test test/page_walkthrough_test.dart`를 실행한다.

## Risk And Rollback Notes

위험은 낮다. 변경은 거래 탭의 수동 refresh path에만 걸리며, 자동 startup/resume pull 경로는 유지된다. 문제가 생기면 `TransactionsPage._refreshPage()`에서 remote refresh 호출만 제거하면 기존 로컬 reload 동작으로 즉시 되돌릴 수 있다.
