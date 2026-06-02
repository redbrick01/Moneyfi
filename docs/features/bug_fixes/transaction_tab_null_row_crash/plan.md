# Transaction Tab Null Row Crash Plan

## Bug Summary

거래 탭 검색/필터 영역 표시됨. 거래 목록 영역은 Flutter error widget으로 바뀌고 `type 'Null' is not a subtype of type 'String' of 'function result'` 표시.

## User Impact

- 사용자 거래 탭에서 거래 목록 못 봄.
- 거래 추가/수정/삭제 진입도 목록 row에서 막힐 수 있음.

## Reproduction Or Evidence

- 사용자 첨부 스크린샷: 거래 탭 `66/66건` 표시 후 목록 영역 런타임 타입 오류.
- 코드상 거래 탭은 `AppDatabase.fetchAssets()` 원장 row를 `TransactionItem`으로 만든 뒤 `TransactionsPage` row 렌더.

## Root Cause Hypothesis

원장 row 조회가 `te.title`, `te.source`, `tl.action`, `te.flow_category` 같은 표시/분류 문자열을 non-null로 읽음. schema default 있어도 기존 로컬 DB, 원격 sync 복원, 과거 migration row에 null 남으면 `row.read<String>(...)` 또는 generated getter가 화면 렌더 중 타입 오류 낼 수 있음.

## Fix Strategy

- 거래 탭/상세 거래내역 원장 조회 SQL에서 표시용 문자열 컬럼에 `COALESCE` fallback 적용.
- `flow_category`는 SQL + Dart normalize 양쪽에서 `internal` fallback 유지.
- 계산식, 저장 동작 변경 없음.

## Non-Goals

- 원장 계산 로직 변경.
- 거래 탭 레이아웃 변경.
- Supabase schema 추가 변경.

## Regression Test Plan

```bash
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risk And Rollback Notes

- fallback은 표시 안전성 목적. 정상 데이터에서는 기존 표시와 같아야 함.
- 원인 더 강하게 고정하려면 추후 nullable legacy fixture를 별도 migration smoke test로 추가.