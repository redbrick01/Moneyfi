# Transaction Form Ledger Layout Plan

## Product Goal

거래/현금 거래 추가·수정 폼에서 사용자가 현재 어떤 보유 종목 또는 현금 계좌에 대한 거래를 입력하는지 명확히 보고, 필요하면 대상 계좌를 바꿀 수 있게 한다. 폼 구조도 원장 모델의 `transaction_events`와 `transaction_lines` 개념에 맞춰 이벤트 정보, 라인 대상, 금액/수량, 계산 반영으로 재배치한다.

## Current Baseline

- 투자 거래 폼은 호출자가 넘긴 `assetId`/`holdingId`를 고정 대상처럼 사용한다.
- 현금 거래 폼은 원천 계좌를 고정하고, 이체의 target 계좌만 선택할 수 있다.
- 수정 시 DB의 `_replaceLedgerTransactionItem`은 기존 원장 라인의 원래 holding/cash account를 기준으로 새 이벤트를 만든다.
- 따라서 폼에서 대상 계좌를 바꿀 UI가 없고, DB API도 새 대상 계좌를 충분히 반영하지 않는다.

## Success Criteria

- 투자 거래 폼 상단에서 현재 보유 종목을 명시하고 같은 자산 안의 다른 투자 보유로 변경할 수 있다.
- 현금 거래 폼 상단에서 원천 현금 계좌를 명시하고 다른 현금 계좌로 변경할 수 있다.
- 현금 이체는 계산 반영 여부와 무관하게 target 계좌를 명확히 선택할 수 있고, source와 같은 계좌는 제외된다.
- 수정 저장 시 새 source/target 선택이 원장 이벤트 재생성에 반영된다.
- 기존 생성/수정/삭제와 원장 계산 테스트가 계속 통과한다.

## Metric And Data Definitions

- 투자 거래의 line target은 선택된 투자 `HoldingItem.id`다.
- 현금 입금/출금/환전의 source line target은 선택된 cash holding id의 절댓값인 `cash_account_id`다.
- 현금 이체의 source/target line target은 각각 선택된 source/target cash holding id다.
- `TransactionItem.counterpartyHoldingId`는 폼에서 이체 target을 DB update API로 전달하기 위한 로컬 모델 필드로만 사용한다.

## Proposed UX

- 폼 섹션 순서:
  1. 원장 이벤트: 거래 유형, 계산 반영
  2. 대상 계좌: 보유 종목 또는 현금 source/target 선택
  3. 거래 내용: 날짜, 이름, 금액, 수량/환율
  4. 원장 미리보기: 이벤트/라인 기준 요약
- 선택 UI는 기존 pill/section 스타일을 유지하고, 목록은 bottom sheet로 표시한다.
- 현금 거래 유형이 `이체`이면 record-only 입력 중에도 target 계좌 선택 필드를 항상 보여 준다. 저장 시 계산 반영이 꺼져 있으면 현금 잔액에는 반영하지 않지만, 사용자가 입력한 이체 이벤트의 상대 계좌 맥락은 폼에서 확인할 수 있어야 한다.
- 원장 미리보기는 실제 schema 의미에 맞춰 이벤트, line action, 계좌, 금액/수량 변화를 보여 준다.

## Data And API Changes

- DB schema와 Supabase migration 변경은 없다.
- `TransactionItem`에 optional `counterpartyHoldingId` 필드를 추가한다.
- `_replaceLedgerTransactionItem`은 item의 `holdingId`, `assetId`, `counterpartyHoldingId`를 우선 사용해 새 원장 이벤트를 생성한다.
- 폼은 선택된 계좌 id를 저장 시 `createTransaction`, `createCashTransfer`, `createCashExchange`, `updateTransactionItem`에 전달한다.

## Development Phases

1. 모델/DB update API가 수정 시 새 source/target 계좌를 사용할 수 있게 한다.
2. 공통 계좌 선택 field/sheet를 폼 파일에 추가한다.
3. 투자 거래 폼을 원장 레이아웃으로 재배치하고 보유 선택을 적용한다.
4. 현금 거래 폼을 원장 레이아웃으로 재배치하고 source/target 선택을 적용한다.
5. 거래 흐름 테스트와 walkthrough/analyze를 실행한다.

## MVP Scope

- 투자 보유 변경.
- 현금 source 변경.
- 이체 target 변경.
- 원장 event/line 중심 레이아웃과 미리보기.

## Out Of Scope

- 이벤트 상세 펼침 화면.
- 환전 target 계좌 직접 선택. 현재 DB API는 source 통화의 반대 통화 계좌를 자동 선택/생성한다.
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

- 계좌 변경 수정은 기존 이벤트를 soft delete하고 새 이벤트를 만드는 기존 정책을 유지한다.
- 환전 target 직접 선택은 현재 API와 통화 규칙상 후속 과제로 둔다.
- source/target 선택은 삭제된 계좌와 숨김 상태를 포함하지 않는 `fetchAssets()` 결과 기반으로 제공한다.
- 이체 target field는 계산 반영 토글에 종속시키지 않는다. 토글이 꺼진 record-only 이체도 사용자가 어느 계좌로 이체한 기록인지 확인할 수 있어야 하기 때문이다.

## Open Questions

- 향후에는 거래 이벤트 전용 편집 모델을 별도로 두고, line target 목록을 DB에서 직접 조회하는 API를 만들 수 있다.

## Feasibility And Feedback

- 기존 replace 방식이 이미 이벤트 재생성 모델이라 계좌 변경을 반영하기 쉽다.
- 폼 레이아웃 변경은 사용자 체감이 크지만 DB schema를 건드리지 않아 데이터 리스크는 제한적이다.
- 가장 큰 리스크는 수정 시 충분한 현금/보유 수량 검증이 새 계좌 기준으로 올바르게 동작하는지다. 거래 흐름 테스트로 고정한다.
