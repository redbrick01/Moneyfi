# Transaction Event Rows Plan

## Product Goal

거래 탭: 사용자 거래 이벤트 1개 = 행 1개. 매수/매도 투자+현금 결제 라인, 이체/환전 다중 현금 라인 중복 행처럼 안 보이게 함.

## Current Baseline

- 거래 탭은 `AppDatabase.fetchAssets()` 보유/현금 계좌별 `TransactionItem` 평탄화해 표시.
- `TransactionItem`은 원장 `transaction_lines` 1줄 기준 생성, `transaction_events` 날짜/제목/분류 조인해 일부 필드만 가져옴.
- 그래서 같은 `transaction_events.id`에 여러 `transaction_lines` 있으면 거래 탭에 여러 행 표시 가능.
- 상세 화면 보유/현금 거래내역은 계좌별 라인 구조 유지.

## Success Criteria

- 거래 탭에서 같은 `ledgerEventId` 원장 라인 1행으로 병합.
- 투자 거래 이벤트는 투자 라인 대표 행, 현금 결제 라인 중복 숨김.
- 이체/환전 이벤트는 출금/source 라인 대표 행, 부제목에 관련 계좌 함께 표시.
- 이벤트 단위 삭제는 기존 `deleteLedgerTransactionItem`로 이벤트 전체 삭제.
- 직접 편집 불가 이벤트는 기존 안내 문구 표시, 편집 폼 진입 차단.

## Metric And Data Definitions

- 이벤트 키는 `TransactionItem.ledgerEventId` 우선.
- 원장 이벤트 아닌 legacy 항목은 기존처럼 개별 행.
- 대표 행 우선순위: 투자 라인, 현금 유출 라인, 첫 번째 라인.
- 금액 정렬/표시는 대표 행 표시 금액 기준.
- 검색 텍스트는 대표 행 정보 + 같은 이벤트 계좌명/자산명 포함.

## Proposed UX

- 거래 탭 row 수는 원장 이벤트 수에 가까워짐.
- row 제목, 유형 배지, 금액은 대표 거래 라인 기준.
- 부제목은 대표 계좌 + 추가 관련 계좌 수 표시.
- 거래 추가, 검색, 필터, 정렬, 스와이프 삭제 UI 유지.

## Data And API Changes

- DB schema, Supabase migration, sync payload 변경 없음.
- `fetchAssets()`와 상세 화면 라인 기반 데이터 계약 유지.
- 거래 탭 page-level view model에서만 원장 라인 이벤트 단위 그룹화.

## Development Phases

1. 거래 탭 entry 생성 후 `ledgerEventId` 기준 grouping helper 추가.
2. 대표 라인 선택, 검색 텍스트, 부제목, slidable key 이벤트 기준 조정.
3. 이벤트 그룹 동작 고정 page-level grouping 회귀 테스트 보강.
4. 포맷, 거래 흐름 테스트, walkthrough, analyzer 실행.

## MVP Scope

- 거래 탭 목록 표시를 이벤트 단위로 변경.
- 삭제는 이벤트 전체 삭제 유지.
- 수정은 대표 라인의 기존 폼 진입 가능 조건 따름.

## Out Of Scope

- 원장 상세 펼침 UI.
- 이벤트 편집 전용 신규 폼.
- 상세 화면 거래내역 표시 정책 변경.
- DB schema 또는 remote sync 변경.

## Test Plan

```bash
dart format lib/pages/transactions_page.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- 대표 라인 기준 금액은 이벤트 모든 라인 합산 순현금흐름 아님. 사용자가 입력한 거래 금액에 가까움. 거래 탭 기존 표시 의미 맞추려 선택.
- 이체/환전 타겟 계좌까지 한 행에서 완전 문장 표시하는 것은 후속 UI 개선.
- 상세 화면은 계좌별 라인 맥락 중요하므로 이번 범위 유지.
- 메모리 DB 직접 주입 widget test는 Flutter test platform 종료 stream과 충돌해 불안정. 같은 grouping helper 경유 순수 회귀 테스트로 자동 검증.

## Open Questions

- 이벤트 행 탭 시 장기적으로 라인별 상세 읽기 전용 sheet 필요 가능.

## Feasibility And Feedback

- page-level 그룹화만으로 구현 가능. schema/sync 리스크 낮음.
- 기존 `TransactionItem.ledgerEventId`와 `deleteLedgerTransactionItem` 계약이 이벤트 단위 삭제 이미 지원.
- 단점: 대표 라인 편집 가능 조건 의존. 복합 이벤트 전용 편집 UX 아직 없음. 직접 수정 불가 이벤트는 기존 차단 메시지 처리.
- 첫 개발 batch: 거래 탭 view model + row 렌더링 조정. 두 번째 batch: page walkthrough 테스트 보강 + 회귀 검증.