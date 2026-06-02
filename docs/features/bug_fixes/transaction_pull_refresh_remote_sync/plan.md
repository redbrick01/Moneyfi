# Transaction Pull Refresh Remote Sync Plan

## Bug Summary

거래 탭 pull refresh: 화면 redraw만 함. Supabase core data pull 안 함. 원격 DB에 거래 원장 추가돼도 현재 거래 탭은 로컬 Drift DB 기존 데이터만 재읽음. 로컬 거래 원장 없으면 계속 빈 화면.

## User Impact

사용자 Supabase 거래내역 확인했는데 앱 거래 페이지는 "아직 거래 내역이 없어요" 표시. 앱 시작/로그인 sync 실패했거나 이후 원격 데이터 변경 시, 거래 탭에서 직접 복구 못 함.

## Reproduction Or Evidence

- `TransactionsPage._refreshPage()`는 `_loadPageData()`만 호출.
- `_loadPageData()`는 `AppDatabase.instance.fetchAssets()`로 로컬 DB만 읽음.
- 로컬 앱 DB: `assets`, `holdings`, `cash_accounts` 있음. `transaction_events`, `transaction_lines`는 0건.
- `get-sync-local-db` Edge Function 응답도 현재 계정 `transaction_events=0`, `transaction_lines=0`. 이번 수정 범위: 거래 탭 수동 refresh를 서버 pull에 연결만.

## Root Cause Hypothesis

거래 탭 pull-to-refresh가 로컬 reload 전용. 사용자 기대 "서버에서 다시 받기"와 실제 동작 불일치.

## Fix Strategy

- 거래 탭 refresh 시 `SyncService.instance.refreshFromServer(reason: 'transactions_page_pull_refresh')` 먼저 호출.
- 로그인/설정 미완료 등 sync 불가 상태면 기존처럼 로컬 reload만.
- 서버 refresh 성공/실패 무관하게 로컬 reload 실행. pull-to-refresh 멈추고 현재 로컬 상태 표시.
- 테스트 위해 `TransactionsPage`에 optional remote refresh callback 주입. production 기본은 기존 service singleton.

## Non-goals

- 원격 DB 실제 거래 원장 0건 문제 보정 안 함.
- Supabase Edge Function, migration, schema 변경 안 함.
- 거래 원장 표시 쿼리나 이벤트/라인 grouping 규칙 변경 안 함.

## Regression Test Plan

- `test/page_walkthrough_test.dart`에 거래 탭 pull-to-refresh가 remote refresh callback 호출 후 로컬 reload 완료하는 widget test 추가.
- `flutter analyze` 통과.
- 화면 진입 영향 있으므로 `flutter test test/page_walkthrough_test.dart` 실행.

## Risk And Rollback Notes

위험 낮음. 변경은 거래 탭 수동 refresh path 한정. 자동 startup/resume pull 경로 유지. 문제 시 `TransactionsPage._refreshPage()`에서 remote refresh 호출만 제거하면 기존 로컬 reload로 즉시 rollback.