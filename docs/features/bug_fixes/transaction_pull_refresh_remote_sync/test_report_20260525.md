# Transaction Pull Refresh Remote Sync Test Report 2026-05-25

## Summary

거래 탭 pull-to-refresh가 로컬 DB reload만 수행하던 문제를 수정했다. 이제 사용자가 거래 탭에서 당겨서 새로고침하면 Supabase core data pull을 먼저 시도한 뒤 로컬 거래 목록을 다시 읽는다.

## Reproduction Status

수정 전 코드 경로에서 `TransactionsPage._refreshPage()`는 `_loadPageData()`만 호출했다. 따라서 거래 탭 수동 새로고침은 `SyncService.refreshFromServer()`를 실행하지 않았다.

로컬 앱 DB 확인 결과 `assets=5`, `holdings=15`, `cash_accounts=7`이지만 `transaction_events=0`, `transaction_lines=0`이었다. 원격 `get-sync-local-db` 응답도 현재 계정에 대해 거래 원장 0건을 반환했다. 이번 수정은 원격에 거래 원장이 존재할 때 수동 새로고침으로 내려받을 수 있도록 클라이언트 refresh 경로를 연결하는 범위다.

## Root Cause

거래 탭의 pull-to-refresh handler가 서버 동기화 service를 호출하지 않고 로컬 데이터만 다시 읽었다.

## Fix Summary

- `TransactionsPage`에 수동 refresh 시 remote core data pull을 먼저 실행하는 경로를 추가했다.
- production 기본값은 `SyncService.instance.refreshFromServer(reason: 'transactions_page_pull_refresh')`를 사용한다.
- 테스트에서는 선택적 `remoteRefresh` callback으로 pull-to-refresh 동작을 deterministic하게 검증한다.
- 서버 pull 실패나 비로그인 상태에서는 기존처럼 로컬 reload가 완료되도록 했다.

## Commands Run

```bash
dart format lib/pages/transactions_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
```

## Command Results

- `dart format lib/pages/transactions_page.dart test/page_walkthrough_test.dart`: passed. Sandbox에서는 Flutter SDK cache 권한으로 실패했으나 승인된 rerun에서 통과했다.
- `flutter test test/page_walkthrough_test.dart`: passed, 22 tests.
- `flutter analyze`: passed, no issues found.

## Regression Coverage

- 새 widget test가 거래 탭 pull-to-refresh에서 remote refresh callback이 호출되는지 검증한다.
- 기존 거래 이벤트 grouping test와 거래/폼/주요 화면 smoke test가 유지된다.

## Manual QA Status

앱 UI에서 직접 pull-to-refresh를 조작하는 수동 QA는 수행하지 않았다. 자동 widget test로 `RefreshIndicator` drag 경로를 검증했다.

## Remaining Risk

현재 원격 Edge Function 응답 자체가 `transaction_events=0`, `transaction_lines=0`인 계정 상태라면, 새로고침 기능이 동작해도 거래 탭에는 계속 빈 상태가 표시된다. 이 경우 원격 거래 원장이 실제로 어떤 테이블 또는 archive schema에 남아 있는지 별도 데이터 보정 작업이 필요하다.

## Final Result

완료. 거래 탭 당겨서 새로고침은 이제 Supabase core data pull을 시도한 뒤 로컬 거래 목록을 다시 렌더링한다.
