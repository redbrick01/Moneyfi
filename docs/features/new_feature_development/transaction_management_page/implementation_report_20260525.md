# Transaction Management Page Implementation Report 2026-05-25

## Summary

전체 거래 내역을 별도 하단 탭에서 조회하고, 기존 투자/현금 거래 폼과 원장 삭제 API를 통해 CRUD할 수 있는 거래 관리 페이지를 추가했다.

## Implemented Stages

- 거래 관리 페이지와 전체 거래 row model 추가.
- 계좌 선택 바텀시트 추가.
- 기존 `TransactionFormPage`, `CashTransactionFormPage`를 create/edit에 연결.
- 기존 `deleteLedgerTransactionItem`과 sync를 삭제에 연결.
- 앱 셸 하단 탭에 `거래` 추가.
- walkthrough test에 거래 탭과 standalone page case 추가.
- 거래 검색 입력, 필터 chip, 정렬 메뉴 추가.
- 거래 폼 계산 반영 토글과 record-only 원장 저장 정책 추가.

## Changed Files

- `lib/pages/transactions_page.dart`
- `lib/pages/app_shell_page.dart`
- `test/page_walkthrough_test.dart`
- `docs/README.md`
- `docs/features/new_feature_development/README.md`
- `docs/features/new_feature_development/transaction_management_page/plan.md`
- `docs/features/new_feature_development/transaction_management_page/verification_test_plan.md`
- `docs/features/new_feature_development/transaction_management_page/test_report_20260525.md`

## Data Layer Changes

DB schema 변경은 없다. 새 화면은 `AppDatabase.fetchAssets()` 결과를 평탄화해 화면 전용 row model로 사용한다. 계산 미반영 거래는 기존 `transaction_events.source`에 `record_only`를 저장하고, 계산/성과/parity 쿼리에서 제외한다.

## UI Changes

- 하단 탭에 `거래`가 추가되었다.
- 거래 페이지는 로딩, 오류, 빈 상태, 전체 거래 목록을 제공한다.
- 거래 페이지는 검색, 전체/투자/현금/입금·수익/출금·매수 필터, 최신순/오래된순/금액순 정렬을 제공한다.
- 거래 폼은 `포트폴리오 계산에 반영` 토글을 제공하며 신규 거래 기본값은 OFF다.
- 계산 미반영 거래는 거래 목록에 `기록전용` 메타로 표시된다.
- `+` 액션으로 계좌 선택 바텀시트를 열고, 선택한 계좌 유형에 맞는 거래 폼으로 이동한다.
- 거래 행 탭으로 수정하고, 스와이프로 삭제할 수 있다.

## Tests Added Or Updated

- `page_walkthrough_test.dart`의 하단 탭 방문 목록에 `거래` 추가.
- `TransactionsPage` standalone first frame smoke case 추가.
- `transaction_flow_test.dart`에 계산 미반영 현금/매수 거래 회귀 테스트 추가.

## Verification Results

- `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
- `flutter test test/transaction_flow_test.dart`: passed, 47 tests.
- `flutter analyze`: passed, no issues found.
- Final rerun after the last code tweak: `flutter test test/page_walkthrough_test.dart` passed, `flutter analyze` passed.
- Query controls update: `flutter test test/page_walkthrough_test.dart` passed, `flutter analyze` passed, `git diff --check` passed.
- Record-only update: `flutter test test/transaction_flow_test.dart` passed, 49 tests; `flutter test test/page_walkthrough_test.dart` passed, 19 tests; `flutter analyze` passed; `git diff --check` passed.

## Known Limitations

- 기간 선택은 아직 없다.
- 수동/반응형 QA는 아직 수행하지 않았다.
- 계산 미반영 이체/환전은 표시용 단일 기록으로 저장된다. 실제 현금 계좌 간 이동/환전 반영은 토글 ON에서만 기존 연결 거래로 처리된다.
- 이체/환전은 기존 현금 상세 화면과 동일하게 원장 라인 기준으로 보일 수 있다.

## Risk Notes

하단 탭이 6개가 되면서 실제 작은 기기에서 시각 밀도가 높아질 수 있다. 자동 smoke에서는 문제 없지만 릴리스 전 수동 viewport 확인이 필요하다.

## Follow-Up Items

- 기간 필터 추가.
- 계좌 선택 바텀시트 widget test 추가.
- 이체/환전 대표 행 grouping 검토.
