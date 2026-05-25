# Transaction Tab UI Density Test Report 2026-05-25

## Summary

거래 탭의 행 레이아웃, 금액 표시, 하단 탭 밀도, 계좌 선택 바텀시트 패치를 적용하고 화면 진입 테스트와 정적 분석을 실행했다. 이후 매수/매도 row 표시 금액을 거래 총액 기준으로 보정하고, 투자/현금 거래 입력 폼에 거래금액 프리뷰를 추가했다. 추가로 거래 금액 색상을 외부 입금/출금만 강조하고 내부 이체, 매수, 매도, 환전은 중립색으로 표시하도록 조정했다. 자동 검증은 모두 통과했다.

## Commands Run

```bash
dart format lib/pages/transactions_page.dart lib/pages/app_shell_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
dart format lib/pages/transactions_page.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
dart format lib/pages/transactions_page.dart lib/pages/app_shell_page.dart lib/pages/holding_detail_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart
flutter analyze
flutter test test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
git diff --check
dart format lib/pages/transactions_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/components/rows/transaction_row.dart
flutter analyze
flutter test test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
git diff --check
```

## Command Results

- `dart format ...`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다.
- `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
- `flutter analyze`: passed, no issues found.
- `git diff --check`: passed.
- Bottom sheet update rerun:
  - `dart format lib/pages/transactions_page.dart`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다.
  - `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
  - `flutter analyze`: passed, no issues found.
  - `git diff --check`: passed.
- Transaction amount preview/display rerun:
  - `dart format lib/pages/transactions_page.dart lib/pages/app_shell_page.dart lib/pages/holding_detail_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다.
  - Initial `flutter analyze` and `flutter test test/page_walkthrough_test.dart` caught a local variable/name collision in `cash_transaction_form_page.dart`; the variable was renamed and commands were rerun.
  - `flutter analyze`: passed, no issues found.
  - `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
  - `flutter test test/transaction_flow_test.dart`: passed, 49 tests.
  - `git diff --check`: passed.
- Transaction amount color rerun:
  - `dart format lib/pages/transactions_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/components/rows/transaction_row.dart`: sandbox에서는 Flutter SDK cache write 권한으로 실패했고, approved rerun에서 통과했다.
  - `flutter analyze`: passed, no issues found.
  - `flutter test test/page_walkthrough_test.dart`: passed, 19 tests.
  - `flutter test test/transaction_flow_test.dart`: passed, 49 tests.
  - `git diff --check`: passed.

## Compatibility Result

- 거래 생성, 수정, 삭제 연결은 변경하지 않았다.
- DB, sync, 원장 계산 API는 변경하지 않았다.
- 거래 탭과 보유 상세 거래내역 row는 `grossAmount`를 우선하고, 없으면 매수/매도/초기 수량 거래에서 `단가 * 수량`으로 표시 금액을 계산한다.
- 투자/현금 거래 폼의 거래금액 프리뷰는 읽기 전용 표시이며 저장 payload는 변경하지 않는다.
- 거래 금액 색상은 외부 `deposit`/`입금`만 positive, 외부 `withdrawal`/`출금`만 negative로 표시하고, 이체/환전/매수/매도/배당/이자 등은 기본 텍스트 색으로 표시한다.
- 하단 탭 라벨은 6개 탭 밀도 대응을 위해 `포트폴리오`에서 `포트폴`로 축약했다.
- 계좌 선택 바텀시트는 화면 높이 70%, 더 강한 dim, 명확한 헤더, compact list, safe-area 하단 여백을 사용한다.

## Manual QA Status

수동 QA는 아직 수행하지 않았다. 첨부 스크린샷과 같은 실제 기기 화면에서 거래명/계좌명 말줄임, 금액 폭, 하단 탭 라벨, 계좌 선택 바텀시트 하단 잘림, 폼 거래금액 프리뷰 실시간 갱신, 외부 입금/출금과 내부 거래 금액 색상 구분을 확인해야 한다.

## Risk Assessment

자동 테스트 기준 화면 진입, 원장 회귀, analyzer 위험은 낮다. 실제 픽셀 레이아웃은 수동 확인이 필요하다. USD 원천 거래는 거래 탭에서 KRW 환산 금액으로 표시되며 폼 프리뷰는 원천 통화 기준으로 표시되므로, 한 화면에서 두 기준을 함께 보여야 하면 보조 텍스트를 후속으로 추가할 수 있다.

## Follow-Up Recommendations

- 거래 행 source currency 보조 표시 검토.
- 하단 탭 6개 구성의 실제 iPhone viewport 스크린샷 QA.
- 거래 필터/검색 추가 시 row 정보 위계 재검토.

## Final Result

자동 검증 통과. 수동 기기 QA는 pending.
