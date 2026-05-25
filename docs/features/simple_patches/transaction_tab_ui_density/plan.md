# Transaction Tab UI Density Plan

## Patch Goal

거래 탭의 거래 행, 하단 탭, 계좌 선택 바텀시트 UI를 더 읽기 쉽게 조정한다. 기능과 데이터 흐름은 유지하면서 스크린샷에서 확인된 UI 밀도와 잘림 문제를 해결하고, 매수/매도 거래 표시 금액을 단가가 아닌 거래 총액 기준으로 맞춘다. 거래 금액 색상은 외부 입금/출금만 강조하고 내부 거래는 중립색으로 통일한다.

## Current Baseline

- 거래 탭 행은 공통 `TransactionRow`의 고정 3열 레이아웃을 사용한다.
- 왼쪽 거래 유형 배지와 오른쪽 금액 영역이 넓어 가운데 거래명/계좌명이 과도하게 말줄임 처리된다.
- 거래 금액은 source currency가 USD이면 달러로 표시되어, KRW 중심 화면에서 통화 표시가 혼란스러울 수 있다.
- 매수/매도 거래의 `amount`는 단가라서 거래 탭과 상세 거래내역 row에서 단가가 표시 금액처럼 보일 수 있다.
- 거래 금액 색상이 단순 `+/-` 부호 기준이라 매도, 매수, 이체, 환전 같은 내부 포트폴리오 거래도 수익/손실처럼 보일 수 있다.
- 거래 입력 폼은 단가와 수량을 입력해도 저장 전 총 거래금액을 바로 확인할 수 없다.
- 하단 탭이 6개가 되면서 `포트폴리오`가 잘린다.
- 거래 목록 카드는 넓은 row 높이 대비 정보량이 낮다.
- 거래 추가 계좌 선택 바텀시트의 높이, 제목 위계, 하단 padding, row 밀도, 배경 dim이 실제 기기 화면에서 어색하다.

## Non-Goals

- 거래 CRUD 저장 동작 변경.
- DB schema, sync, 원장 계산 변경.
- 거래 검색/필터 추가.
- 하단 탭 정보 구조 재설계.

## Files And Modules Affected

- `lib/pages/transactions_page.dart`
- `lib/pages/app_shell_page.dart`
- `lib/pages/holding_detail_page.dart`
- `lib/pages/cash_account_detail_page.dart`
- `lib/pages/forms/transaction_form_page.dart`
- `lib/pages/forms/cash_transaction_form_page.dart`
- `lib/components/rows/transaction_row.dart`
- `test/page_walkthrough_test.dart`
- `docs/README.md`
- `docs/features/simple_patches/README.md`

## Compatibility Promise

- 기존 거래 생성, 수정, 삭제 API 호출은 그대로 유지한다.
- 원장/현금 계산 결과는 변경하지 않는다.
- 앱 셸 탭 순서와 route-less navigation 구조는 유지한다.
- 매수/매도 row의 표시 금액만 `grossAmount` 또는 `단가 * 수량` 기준으로 보정하며 저장 payload는 유지한다.
- 금액 색상은 외부 입금은 positive, 외부 출금은 negative, 그 외 매수/매도/이체/환전 등은 기본 텍스트 색으로 표시한다.
- 입력 폼의 거래금액은 읽기 전용 프리뷰로만 제공한다.

## Test Plan

```bash
dart format lib/pages/transactions_page.dart lib/pages/app_shell_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/components/rows/transaction_row.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Rollback Notes

- 하단 탭 라벨을 축약하면 정보 명확성이 약간 낮아질 수 있다. 문제 시 라벨 정책만 되돌리면 된다.
- 거래 금액을 KRW 환산 중심으로 보여 주면 원천 통화 확인성이 낮아질 수 있다. 필요하면 후속으로 source amount를 보조 텍스트로 추가한다.
- 폼 거래금액 프리뷰는 저장 전 안내용이므로 환율/원천 통화 표시는 실제 계좌 통화 기준으로만 맞춘다.
- 거래 탭 전용 row를 쓰므로 공통 `TransactionRow` 변경 리스크는 없다.
- 계좌 선택 바텀시트를 화면 높이 70%로 고정해 작은 화면에서는 더 많은 항목이 보이지만, 실제 기기에서 헤더와 목록 균형 확인이 필요하다.

## Follow-Up Candidates

- 실제 기기에서 하단 6개 탭 반응형 QA.
- 계좌 선택 바텀시트 실제 iPhone viewport QA.
- 거래 행 source currency 보조 표시.
- 기간/유형 필터 추가.
