# Transaction Tab Null Row Crash Plan

## Bug Summary

거래 탭에서 검색/필터 영역은 표시되지만 거래 목록 영역이 Flutter error widget으로 바뀌며 `type 'Null' is not a subtype of type 'String' of 'function result'`가 표시된다.

## User Impact

- 사용자는 거래 탭에서 거래 목록을 볼 수 없다.
- 거래 추가/수정/삭제 진입도 목록 row에서 막힐 수 있다.

## Reproduction Or Evidence

- 사용자 첨부 스크린샷: 거래 탭 `66/66건` 표시 후 목록 영역에서 런타임 타입 오류 발생.
- 코드상 거래 탭은 `AppDatabase.fetchAssets()`의 원장 row를 `TransactionItem`으로 만든 뒤 `TransactionsPage` row를 그린다.

## Root Cause Hypothesis

원장 row 조회에서 `te.title`, `te.source`, `tl.action`, `te.flow_category` 같은 표시/분류 문자열을 non-null로 읽고 있다. schema default가 있어도 기존 로컬 DB, 원격 sync 복원, 과거 migration row에 null이 남아 있으면 `row.read<String>(...)` 또는 generated getter가 화면 렌더링 중 타입 오류를 일으킬 수 있다.

## Fix Strategy

- 거래 탭/상세 거래내역에 쓰이는 원장 조회 SQL에서 표시용 문자열 컬럼에 `COALESCE` fallback을 적용한다.
- `flow_category`는 SQL과 Dart normalize 양쪽에서 `internal` fallback을 유지한다.
- 계산식과 저장 동작은 변경하지 않는다.

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

- fallback은 표시 안전성 목적이며, 정상 데이터에서는 기존 표시와 동일해야 한다.
- 원인을 더 강하게 고정하려면 추후 nullable legacy fixture를 별도 migration smoke test로 추가한다.
