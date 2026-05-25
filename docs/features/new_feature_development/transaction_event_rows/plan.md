# Transaction Event Rows Plan

## Product Goal

거래 탭에서 사용자가 수행한 하나의 거래 이벤트를 하나의 행으로 표시한다. 매수/매도처럼 투자 라인과 현금 결제 라인이 함께 생기는 거래, 이체/환전처럼 여러 현금 라인이 생기는 거래가 중복 행처럼 보이지 않게 한다.

## Current Baseline

- 거래 탭은 `AppDatabase.fetchAssets()`의 보유/현금 계좌별 `TransactionItem`을 평탄화해서 표시한다.
- `TransactionItem`은 원장 `transaction_lines` 한 줄을 기준으로 만들어지고, `transaction_events`의 날짜/제목/분류를 조인해서 일부 필드만 가져온다.
- 그래서 하나의 `transaction_events.id`에 여러 `transaction_lines`가 있으면 거래 탭에 여러 행이 표시될 수 있다.
- 상세 화면의 보유/현금 거래내역은 계좌별 라인을 보여 주는 구조로 유지된다.

## Success Criteria

- 거래 탭에서 동일한 `ledgerEventId`를 가진 원장 라인은 하나의 행으로 합쳐진다.
- 투자 거래 이벤트는 투자 라인을 대표 행으로 보여 주고 현금 결제 라인은 중복 표시하지 않는다.
- 이체/환전 이벤트는 출금/source 라인을 대표 행으로 보여 주되 부제목에 관련 계좌들을 함께 보여 준다.
- 이벤트 단위 행의 삭제는 기존 `deleteLedgerTransactionItem`을 통해 이벤트 전체를 삭제한다.
- 직접 편집할 수 없는 이벤트는 기존 안내 문구를 보여 주고 편집 폼 진입을 막는다.

## Metric And Data Definitions

- 이벤트 키는 `TransactionItem.ledgerEventId`를 우선 사용한다.
- 원장 이벤트가 아닌 legacy 항목은 기존처럼 개별 행으로 둔다.
- 대표 행 우선순위는 투자 라인, 현금 유출 라인, 첫 번째 라인 순서다.
- 금액 정렬과 금액 표시는 대표 행의 표시 금액 기준이다.
- 검색 텍스트는 대표 행 정보와 같은 이벤트에 속한 계좌명/자산명을 포함한다.

## Proposed UX

- 거래 탭의 row 개수는 원장 이벤트 개수에 가까워진다.
- row 제목, 유형 배지, 금액은 대표 거래 라인 기준으로 표시한다.
- 부제목은 대표 계좌와 추가 관련 계좌 수를 표시한다.
- 거래 추가, 검색, 필터, 정렬, 스와이프 삭제 UI는 유지한다.

## Data And API Changes

- DB schema, Supabase migration, sync payload 변경은 없다.
- `fetchAssets()`와 상세 화면의 라인 기반 데이터 계약은 유지한다.
- 거래 탭 page-level view model에서만 원장 라인을 이벤트 단위로 그룹화한다.

## Development Phases

1. 거래 탭 entry 생성 후 `ledgerEventId` 기준 그룹화 helper를 추가한다.
2. 대표 라인 선택, 검색 텍스트, 부제목, slidable key를 이벤트 기준으로 조정한다.
3. 이벤트 그룹 동작을 고정하는 page-level grouping 회귀 테스트를 보강한다.
4. 포맷, 거래 흐름 테스트, walkthrough, analyzer를 실행한다.

## MVP Scope

- 거래 탭 목록 표시를 이벤트 단위로 변경한다.
- 삭제는 이벤트 전체 삭제를 유지한다.
- 수정은 대표 라인의 기존 폼 진입 가능 조건을 따른다.

## Out Of Scope

- 원장 상세 펼침 UI.
- 이벤트 편집 전용 신규 폼.
- 상세 화면 거래내역의 표시 정책 변경.
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

- 대표 라인 기준 금액은 이벤트의 모든 라인을 합산한 순현금흐름이 아니라 사용자가 입력한 거래 금액에 가까운 값이다. 거래 탭의 기존 표시 의미와 맞추기 위해 이 방식을 선택한다.
- 이체/환전의 타겟 계좌까지 한 행에서 완전한 문장으로 보여 주는 것은 후속 UI 개선으로 남긴다.
- 상세 화면은 계좌별 라인 맥락이 중요하므로 이번 범위에서 유지한다.
- 메모리 DB를 직접 주입한 widget test는 Flutter test platform 종료 stream과 충돌해 불안정했으므로, 같은 grouping helper를 경유하는 순수 회귀 테스트로 자동 검증한다.

## Open Questions

- 이벤트 행을 탭했을 때 장기적으로는 라인별 상세를 보여 주는 읽기 전용 sheet가 필요할 수 있다.

## Feasibility And Feedback

- page-level 그룹화만으로 구현 가능해 schema와 sync 리스크가 낮다.
- 기존 `TransactionItem.ledgerEventId`와 `deleteLedgerTransactionItem` 계약이 이벤트 단위 삭제를 이미 지원한다.
- 단점은 대표 라인의 편집 가능 조건에 의존한다는 점이다. 특히 복합 이벤트 전용 편집 UX는 아직 없으므로 직접 수정 불가 이벤트는 기존 차단 메시지로 처리한다.
- 첫 개발 batch는 거래 탭 view model과 row 렌더링 조정이다. 두 번째 batch는 page walkthrough 테스트 보강과 회귀 검증이다.
