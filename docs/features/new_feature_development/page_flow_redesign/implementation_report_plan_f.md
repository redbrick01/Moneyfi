# Plan F Implementation Report

## 상태

- 완료일: 2026-05-30
- 상태: 구현 완료
- 다음 계획 자동 착수: 하지 않음

## 구현 범위

### F1. 첫 입력 안내 정리

- 홈 empty state에서 첫 자산군 이후 보유 종목/현금 계좌를 추가해야 한다는 흐름을 안내했다.
- 포트폴리오 empty state에서 자산군 이후 보유 종목/현금 계좌를 추가해야 비중/리밸런싱을 볼 수 있음을 안내했다.

### F2. 거래 empty state 분리

- 계좌가 없을 때 title을 `거래를 기록할 계좌가 없어요`로 분리했다.
- 계좌 없음 상태는 자산군 생성 후 자산 상세에서 보유 종목/현금 계좌를 추가하도록 안내한다.
- 계좌가 있고 거래가 없는 상태는 기존 `거래 추가` CTA를 유지했다.

### F3. 자산 상세 empty CTA 추가

- 보유 종목 empty state에 `보유 종목 추가` CTA를 추가했다.
- 현금 계좌 empty state에 `현금 계좌 추가` CTA를 추가했다.
- 두 CTA 모두 기존 `_openHoldingForm` 흐름을 사용하며, 저장 후 기존 `_reloadDetail()` 구조를 유지한다.

### F4. 거래 유형/거래 폼 안내 보강

- 거래 유형 선택 시트에서 투자 거래는 보유 종목, 현금 거래는 현금 계좌가 필요하다고 안내한다.
- 선택 불가 tile은 필요한 선행 항목을 구체적으로 안내한다.
- 투자 거래 폼의 `대상 보유` 섹션에 보유 종목 선택 안내를 추가했다.
- 현금 거래 폼의 `대상 계좌` 섹션에 현금 계좌 선택 안내를 추가했다.

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/pages/portfolio_dashboard_page.dart` | 홈 empty state description 정리 |
| `lib/pages/portfolio_page.dart` | 포트폴리오 empty state description 정리 |
| `lib/pages/transactions_page.dart` | 거래 empty state 분리, 거래 유형 sheet 안내/disabled 문구 정리 |
| `lib/pages/asset_detail_page.dart` | 보유 종목/현금 계좌 empty CTA 추가 |
| `lib/pages/forms/transaction_form_page.dart` | 대상 보유 helper text 추가 |
| `lib/pages/forms/cash_transaction_form_page.dart` | 대상 계좌 helper text 추가 |
| `docs/page_inventory_graph.md` | 첫 입력 흐름 그래프 추가 |
| `docs/features/new_feature_development/page_flow_redesign/route_matrix.md` | Plan F form route 미전환 기록 |
| `docs/features/new_feature_development/page_flow_redesign/test_coverage_matrix.md` | Plan F 검증 기준 보강 |

## 유지한 구조

- `AssetFormPage`, `HoldingFormPage`, `CashAccountFormPage`, `TransactionFormPage`, `CashTransactionFormPage` route 구조 유지.
- `push<bool>` 저장 후 상위 reload 구조 유지.
- form edit loader 변경 없음.
- transaction ledger calculation 변경 없음.
- DB schema 변경 없음.

## 범위 밖 미착수 확인

- form named route 전환: 미착수
- `go_router`/`MaterialApp.router` 전환: 미착수
- 5탭 통합: 미착수
- 자동 wizard/강제 연속 입력 flow: 미착수
- 자산/보유/거래 데이터 모델 변경: 미착수

## 후속 후보

- Plan I에서 form route 전환을 다룰 때 첫 입력 flow의 route-level 테스트를 추가한다.
- `page_walkthrough_test.dart`와 `widget_test.dart`의 앱 셸 smoke 실패는 별도 테스트 안정화 작업으로 확인한다.
