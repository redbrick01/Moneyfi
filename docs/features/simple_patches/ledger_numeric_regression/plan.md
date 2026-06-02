# Ledger Numeric Regression Plan

## Product Goal

원장, 현금 계좌, 환전, 스냅샷 표시 계산 섞여도 핵심 수치 안 흔들리게 회귀 테스트 추가.

## Current Baseline

- `test/transaction_flow_test.dart`는 입금, 출금, 이체, 환전, 매수/매도, 스냅샷 표시 각각 검증.
- 여러 거래 유형이 한 계정 묶음에서 연속 발생할 때 최종 현금 잔액, 보유 수량, 실현손익, 현금흐름 bucket, 스냅샷 cash row 동시 일치 검증하는 복합 테스트 부족.
- 서버 스냅샷은 `importRemotePortfolioSnapshots`로 들어옴. 로컬 on-device snapshot 생성 비활성.

## Success Criteria

- KRW 현금, USD 환전 현금, 주식 보유, 외부 입출금, 내부 이체, 환전, 매매가 한 fixture에서 계산.
- 최종 holdings/cash state와 normalized ledger parity 일치.
- portfolio performance aggregate의 realized, external, internal, settlement 금액 기대값 고정.
- snapshot import/display가 cash account client reference와 USD 환율 값 보존.

## Metric And Data Definitions

- `realizedPnl`: 매도 실현손익 합계.
- `pureRealizedPerformance`: `realizedPnl + incomeAmount - feeAmount - taxAmount`.
- `externalCashFlowAmount`: 입금, 출금, opening cash의 signed net.
- `tradeSettlementCashFlowAmount`: 매매 settlement 현금흐름.
- `internalCashMovementAmount`: 이체와 환전 양쪽 line의 절대값 합.
- snapshot cash rows: 원격 payload의 cash account row를 로컬 cash account client id로 remap한 표시용 현금 계좌 수치.

## Proposed UX

사용자-facing UI 변경 없음. 수치 회귀 테스트만 보강.

## Data And API Changes

DB schema, sync payload, public API 변경 없음. 기존 `AppDatabase` test fixture 사용.

## Development Phases

1. 기존 transaction flow 테스트 baseline 확인
2. 복합 원장/현금/환전 fixture 회귀 테스트 추가
3. 원격 snapshot import/display 현금 row 회귀 테스트 추가
4. targeted/full verification 실행
5. 임시 문서 정리와 test report 작성

## MVP Scope

- `test/transaction_flow_test.dart`에 계산 회귀 테스트 추가.
- production 계산 로직 변경 없음.
- 원격 Supabase DB 검증 제외.

## Test Plan

- `flutter test test/transaction_flow_test.dart`
- `flutter analyze`
- `flutter test`

## Risks And Decisions

- `internalCashMovementAmount`는 이체/환전 양쪽 line 절대값 모두 더함. 순액 아님, 활동량 metric.
- 스냅샷 생성은 서버 책임. 로컬 계산 테스트는 import/display remap과 보존 값 집중.
- production 코드 변경 없이 테스트만 추가. 회귀 발견 시 별도 수정 패치 필요 가능.

## Open Questions

- 실제 운영 스냅샷 payload 추가 조합은 Supabase function integration test로 확장 가능.

## Feasibility And Feedback

- 기존 in-memory Drift 테스트 구조 그대로 사용. 구현 난이도 낮음.
- 복합 fixture는 개별 테스트보다 실패 원인 파악 어렵지만, 핵심 수치 동시 파손 회귀 빠르게 잡음.
- 첫 batch는 로컬 DB 계산과 import/display 집중. 서버 function 산출물 검증은 후속 범위.