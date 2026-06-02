# Transaction Form Ledger Layout Plan

## Product Goal

거래/현금 거래 추가·수정 폼에서 현재 입력 대상 보유 종목/현금 계좌 명확히 표시. 필요 시 대상 계좌 변경 가능. 폼 구조도 원장 모델 `transaction_events`, `transaction_lines` 개념에 맞춰 이벤트 정보, 라인 대상, 금액/수량, 계산 반영 순서로 재배치.

## Current Baseline

- 투자 거래 폼: 호출자 `assetId`/`holdingId`를 고정 대상처럼 사용.
- 현금 거래 폼: 원천 계좌 고정, 이체 target 계좌만 선택 가능.
- 수정 시 DB `_replaceLedgerTransactionItem`: 기존 원장 라인의 원래 holding/cash account 기준으로 새 이벤트 생성.
- 결과: 폼에 대상 계좌 변경 UI 없음. DB API도 새 대상 계좌 충분히 반영 못 함.

## Success Criteria

- 투자 거래 폼 상단에서 현재 보유 종목 명시, 같은 자산 내 다른 투자 보유로 변경 가능.
- 현금 거래 폼 상단에서 원천 현금 계좌 명시, 다른 현금 계좌로 변경 가능.
- 현금 이체는 계산 반영 여부와 무관하게 target 계좌 명확히 선택. source와 같은 계좌 제외.
- 수정 저장 시 새 source/target 선택이 원장 이벤트 재생성에 반영.
- 기존 생성/수정/삭제와 원장 계산 테스트 계속 통과.

## Metric And Data Definitions

- 투자 거래 line target = 선택된 투자 `HoldingItem.id`.
- 현금 입금/출금/환전 source line target = 선택된 cash holding id 절댓값인 `cash_account_id`.
- 현금 이체 source/target line target = 각각 선택된 source/target cash holding id.
- `TransactionItem.counterpartyHoldingId` = 폼에서 이체 target을 DB update API로 전달하는 로컬 모델 필드 only.

## Proposed UX

- 폼 섹션 순서:
  1. 원장 이벤트: 거래 유형, 계산 반영
  2. 대상 계좌: 보유 종목 또는 현금 source/target 선택
  3. 거래 내용: 날짜, 이름, 금액, 수량/환율
  4. 원장 미리보기: 이벤트/라인 기준 요약
- 선택 UI: 기존 pill/section 스타일 유지. 목록은 bottom sheet.
- 현금 거래 유형 `이체`면 record-only 입력 중에도 target 계좌 선택 필드 항상 표시. 저장 시 계산 반영 off면 현금 잔액 미반영. 그래도 사용자가 입력한 이체 이벤트 상대 계좌 맥락은 폼에서 확인 가능해야 함.
- 원장 미리보기: 실제 schema 의미 기준으로 이벤트, line action, 계좌, 금액/수량 변화 표시.

## Data And API Changes

- DB schema와 Supabase migration 변경 없음.
- `TransactionItem`에 optional `counterpartyHoldingId` 필드 추가.
- `_replaceLedgerTransactionItem`은 item의 `holdingId`, `assetId`, `counterpartyHoldingId` 우선 사용해 새 원장 이벤트 생성.
- 폼은 선택된 계좌 id를 저장 시 `createTransaction`, `createCashTransfer`, `createCashExchange`, `updateTransactionItem`에 전달.

## Development Phases

1. 모델/DB update API가 수정 시 새 source/target 계좌 사용 가능하게 변경.
2. 공통 계좌 선택 field/sheet를 폼 파일에 추가.
3. 투자 거래 폼을 원장 레이아웃으로 재배치, 보유 선택 적용.
4. 현금 거래 폼을 원장 레이아웃으로 재배치, source/target 선택 적용.
5. 거래 흐름 테스트와 walkthrough/analyze 실행.

## MVP Scope

- 투자 보유 변경.
- 현금 source 변경.
- 이체 target 변경.
- 원장 event/line 중심 레이아웃과 미리보기.

## Out Of Scope

- 이벤트 상세 펼침 화면.
- 환전 target 계좌 직접 선택. 현재 DB API는 source 통화의 반대 통화 계좌 자동 선택/생성.
- Supabase schema 변경.

## Test Plan

```bash
dart format lib/models/asset_item.dart lib/db/app_database.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- 계좌 변경 수정은 기존 이벤트 soft delete 후 새 이벤트 생성 정책 유지.
- 환전 target 직접 선택은 현재 API와 통화 규칙상 후속 과제.
- source/target 선택은 삭제 계좌와 숨김 상태 제외한 `fetchAssets()` 결과 기반.
- 이체 target field는 계산 반영 토글에 종속 안 함. 토글 off인 record-only 이체도 어느 계좌로 이체한 기록인지 확인 가능해야 함.

## Open Questions

- 향후 거래 이벤트 전용 편집 모델 분리 가능. line target 목록을 DB에서 직접 조회하는 API 생성 가능.

## Feasibility And Feedback

- 기존 replace 방식이 이벤트 재생성 모델이라 계좌 변경 반영 쉬움.
- 폼 레이아웃 변경은 사용자 체감 큼. DB schema 안 건드려 데이터 리스크 제한적.
- 최대 리스크: 수정 시 충분한 현금/보유 수량 검증이 새 계좌 기준으로 올바르게 동작하는지. 거래 흐름 테스트로 고정.