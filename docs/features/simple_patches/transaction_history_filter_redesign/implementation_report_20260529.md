# Transaction History Filter Redesign Implementation Report 2026-05-29

## Summary

거래 내역 화면의 상단 필터 영역을 `검색 + 빠른 필터 칩 + 상세 필터 BottomSheet` 구조로 재구성했다. 기존 기간 필터, 전체 거래 유형 필터, 정렬 메뉴는 상세 필터로 이동했고, 기본 화면에는 자주 쓰는 거래 유형만 빠른 필터로 노출하도록 조정했다.

## Implemented Scope

- 거래 화면 상단 검색창 유지.
- 빠른 필터 칩 추가: `전체`, `매수`, `매도`, `배당`, `입출금`.
- 기존 기간 필터를 상세 필터 BottomSheet로 이동.
- 기존 전체 거래 유형 필터를 상세 필터 BottomSheet로 이동.
- 기존 정렬 PopupMenuButton을 상세 필터 BottomSheet 내부 정렬 섹션으로 이동.
- 상세 필터 버튼을 `필터` 텍스트와 tune 아이콘으로 명확화.
- 상세 필터 적용 시 버튼 배지로 적용 조건 그룹 수 표시.
- 검색어/기간/유형/정렬 적용 상태를 요약 행으로 표시.
- 요약 행과 빈 결과 상태에서 조건 초기화 동작 유지.
- 계좌/자산 필터는 MVP 범위에 맞춰 BottomSheet 내 확장 슬롯만 추가.

## Changed Files

- `lib/pages/transactions_page.dart`
- `docs/design/transaction_history_ui_ux_improvement_plan.md`

## UI Changes

### Before

거래 화면 상단에 검색창, 기간 필터 strip, 거래 유형 필터 strip, 정렬 아이콘 버튼이 함께 노출되어 거래 리스트 시작 위치가 아래로 밀렸다.

### After

기본 화면은 다음 구조로 단순화했다.

```text
거래 검색 [필터]
[전체] [매수] [매도] [배당] [입출금]
적용 조건 요약 / 초기화
거래 리스트
```

상세 필터 BottomSheet는 다음 섹션을 제공한다.

- 기간
- 거래 유형
- 계좌
- 자산
- 정렬

계좌와 자산은 아직 실제 필터링을 적용하지 않고, 후속 구현 안내 문구를 표시한다.

## Behavior Notes

- 빠른 필터는 단일 선택이다.
- `입출금` 빠른 필터는 입금과 출금 계열 거래를 함께 조회한다.
- 빠른 필터 선택 시 기존 상세 거래 유형 선택 상태와 동기화한다.
- 상세 필터에서 빠른 필터로 표현할 수 없는 유형을 선택하면 빠른 필터는 `전체`로 돌아가고 요약 행에 상세 유형을 표시한다.
- BottomSheet에서 `결과 보기`를 눌러야 부모 화면 필터 상태에 반영된다.
- BottomSheet를 닫거나 취소하면 기존 필터 상태가 유지된다.
- `초기화`는 검색어, 기간, 거래 유형, 빠른 필터, 정렬을 기본값으로 되돌린다.

## Compatibility Result

- DB schema 변경 없음.
- sync 로직 변경 없음.
- 거래 추가, 수정, 삭제 흐름 변경 없음.
- 원장 이벤트 grouping 로직 변경 없음.
- 거래 row 금액 계산 및 표시 로직 변경 없음.
- 기존 `_TransactionPeriodFilter`, `_TransactionCategoryFilter`, `_TransactionSortMode`는 유지하고 UI 배치만 재구성했다.

## Verification Results

```bash
dart format lib/pages/transactions_page.dart
flutter analyze lib/pages/transactions_page.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

결과:

- `dart format lib/pages/transactions_page.dart`: 통과. sandbox에서는 Flutter SDK cache write 권한으로 1회 실패했고, approved rerun에서 통과했다.
- `flutter analyze lib/pages/transactions_page.dart`: 통과, no issues found.
- `flutter test test/page_walkthrough_test.dart`: 통과, 24 tests.
- `flutter analyze`: 통과, no issues found.
- `git diff --check`: 통과.

## Known Limitations

- 거래 유형 다중 선택은 아직 구현하지 않았다.
- 사용자 지정 기간은 아직 구현하지 않았다.
- 계좌 필터 실제 적용은 후속 범위다.
- 자산 필터 실제 적용은 후속 범위다.
- 실제 모바일 viewport 스크린샷 QA는 아직 수행하지 않았다.
- BottomSheet 내부 계좌/자산 섹션은 후속 구현 전까지 안내 영역으로만 동작한다.

## Follow-Up Items

- 거래 유형 다중 선택을 `Set<_TransactionCategoryFilter>` 기반으로 확장.
- 사용자 지정 기간 DateRangePicker 추가.
- `data.accounts` 기반 계좌 필터 적용.
- 자산명/티커 기반 자산 필터 적용.
- 작은 화면에서 검색창과 필터 버튼 폭, 빠른 필터 chip 줄바꿈 여부 수동 QA.
- 상세 필터 BottomSheet widget test 추가.

## Final Result

자동 검증 통과. 거래 내역 화면은 기본 조회 영역을 더 간결하게 만들고, 상세 조건은 BottomSheet로 분리한 MVP 상태로 구현 완료했다.
