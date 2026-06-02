# Transaction Tab UI Density Plan

## Patch Goal

거래 탭 행, 하단 탭, 계좌 선택 바텀시트 UI 읽기 쉽게 조정. 기능/데이터 흐름 유지. 스크린샷상 UI 밀도/잘림 문제 해결. 매수/매도 표시 금액은 단가 말고 거래 총액 기준. 거래 금액 색상은 외부 입금/출금만 강조, 내부 거래는 중립색.

## Current Baseline

- 거래 탭 행은 공통 `TransactionRow` 고정 3열 레이아웃 사용.
- 왼쪽 거래 유형 배지, 오른쪽 금액 영역 넓음. 가운데 거래명/계좌명 과도한 말줄임.
- 거래 금액은 source currency가 USD면 달러 표시. KRW 중심 화면에서 통화 혼란 가능.
- 매수/매도 거래 `amount`는 단가. 거래 탭/상세 거래내역 row에서 단가가 표시 금액처럼 보일 수 있음.
- 거래 금액 색상은 단순 `+/-` 부호 기준. 매도, 매수, 이체, 환전 같은 내부 포트폴리오 거래도 수익/손실처럼 보일 수 있음.
- 거래 입력 폼은 단가/수량 입력해도 저장 전 총 거래금액 즉시 확인 불가.
- 하단 탭 6개로 증가. `포트폴리오` 잘림.
- 거래 목록 카드는 row 높이 대비 정보량 낮음.
- 거래 추가 계좌 선택 바텀시트 높이, 제목 위계, 하단 padding, row 밀도, 배경 dim이 실제 기기 화면에서 어색함.

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

- 기존 거래 생성, 수정, 삭제 API 호출 유지.
- 원장/현금 계산 결과 변경 없음.
- 앱 셸 탭 순서와 route-less navigation 구조 유지.
- 매수/매도 row 표시 금액만 `grossAmount` 또는 `단가 * 수량` 기준 보정. 저장 payload 유지.
- 금액 색상은 외부 입금 positive, 외부 출금 negative, 그 외 매수/매도/이체/환전 등 기본 텍스트 색.
- 입력 폼 거래금액은 읽기 전용 프리뷰만 제공.

## Test Plan

```bash
dart format lib/pages/transactions_page.dart lib/pages/app_shell_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart lib/components/rows/transaction_row.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Rollback Notes

- 하단 탭 라벨 축약 시 정보 명확성 약간 저하 가능. 문제 시 라벨 정책만 rollback.
- 거래 금액 KRW 환산 중심 표시 시 원천 통화 확인성 저하 가능. 필요 시 source amount 보조 텍스트 추가.
- 폼 거래금액 프리뷰는 저장 전 안내용. 환율/원천 통화 표시는 실제 계좌 통화 기준만 맞춤.
- 거래 탭 전용 row 사용. 공통 `TransactionRow` 변경 리스크 없음.
- 계좌 선택 바텀시트 화면 높이 70% 고정. 작은 화면에서 더 많은 항목 표시. 실제 기기에서 헤더/목록 균형 확인 필요.

## Follow-Up Candidates

- 실제 기기 하단 6개 탭 반응형 QA.
- 계좌 선택 바텀시트 실제 iPhone viewport QA.
- 거래 행 source currency 보조 표시.
- 기간/유형 필터 추가.