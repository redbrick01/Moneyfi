# Ledger Numeric Regression Plan

## Product Goal

원장, 현금 계좌, 환전, 스냅샷 표시 계산이 함께 섞인 상황에서도 사용자가 보는 핵심 수치가 흔들리지 않도록 회귀 테스트를 추가합니다.

## Current Baseline

- `test/transaction_flow_test.dart`는 입금, 출금, 이체, 환전, 매수/매도, 스냅샷 표시를 개별적으로 검증합니다.
- 여러 거래 유형이 한 계정 묶음에서 연속으로 발생했을 때 최종 현금 잔액, 보유 수량, 실현손익, 현금흐름 bucket, 스냅샷 cash row가 동시에 일치하는지 검증하는 복합 테스트는 부족합니다.
- 서버 스냅샷은 `importRemotePortfolioSnapshots`로 들어오며 로컬 on-device snapshot 생성은 비활성화되어 있습니다.

## Success Criteria

- KRW 현금, USD 환전 현금, 주식 보유, 외부 입출금, 내부 이체, 환전, 매매가 한 fixture에서 계산됩니다.
- 최종 holdings/cash state와 normalized ledger parity가 일치합니다.
- portfolio performance aggregate의 realized, external, internal, settlement 금액이 기대값으로 고정됩니다.
- snapshot import/display가 cash account client reference와 USD 환율 값을 보존합니다.

## Metric And Data Definitions

- `realizedPnl`: 매도 실현손익 합계입니다.
- `pureRealizedPerformance`: `realizedPnl + incomeAmount - feeAmount - taxAmount`입니다.
- `externalCashFlowAmount`: 입금, 출금, opening cash의 signed net입니다.
- `tradeSettlementCashFlowAmount`: 매매 settlement 현금흐름입니다.
- `internalCashMovementAmount`: 이체와 환전 양쪽 line의 절대값 합입니다.
- snapshot cash rows: 원격 payload의 cash account row를 로컬 cash account client id로 remap한 표시용 현금 계좌 수치입니다.

## Proposed UX

사용자-facing UI 변경은 없습니다. 수치 회귀 테스트만 보강합니다.

## Data And API Changes

DB schema, sync payload, public API 변경은 없습니다. 기존 `AppDatabase` test fixture를 사용합니다.

## Development Phases

1. 기존 transaction flow 테스트 baseline 확인
2. 복합 원장/현금/환전 fixture 회귀 테스트 추가
3. 원격 snapshot import/display 현금 row 회귀 테스트 추가
4. targeted/full verification 실행
5. 임시 문서 정리와 test report 작성

## MVP Scope

- `test/transaction_flow_test.dart`에 계산 회귀 테스트를 추가합니다.
- production 계산 로직은 변경하지 않습니다.
- 원격 Supabase DB 검증은 범위에서 제외합니다.

## Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter analyze`
- `flutter test`

## Risks And Decisions

- `internalCashMovementAmount`는 이체/환전 양쪽 line의 절대값을 모두 더하므로 순액이 아니라 활동량 metric입니다.
- 스냅샷 생성은 서버 책임이므로 로컬 계산 테스트는 import/display remap과 보존 값에 집중합니다.
- production 코드 변경 없이 테스트만 추가하므로 회귀 발견 시 별도 수정 패치가 필요할 수 있습니다.

## Open Questions

- 실제 운영 스냅샷 payload의 추가 조합은 Supabase function integration test로 확장할 수 있습니다.

## Feasibility And Feedback

- 기존 in-memory Drift 테스트 구조를 그대로 사용하므로 구현 난이도는 낮습니다.
- 복합 fixture는 개별 테스트보다 실패 원인 파악이 어렵지만, 핵심 수치가 함께 깨지는 회귀를 빠르게 잡는 장점이 큽니다.
- 첫 batch는 로컬 DB 계산과 import/display에 집중하고, 서버 function 산출물 검증은 후속 범위로 남깁니다.
