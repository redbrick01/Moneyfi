# Transaction Management Page Verification Test Plan

## Scope

- 거래 전용 하단 탭 진입.
- 전체 거래 목록 렌더링.
- 계좌 선택 후 투자/현금 거래 추가 폼 진입.
- 거래 행 수정/삭제 동작 연결.
- 검색, 필터, 정렬 조회 UI 렌더링.
- 계산 미반영 기본 거래 저장 정책.
- 기존 원장/현금 재계산 회귀 보호.

## Quality Goals

- 새 페이지가 앱 셸 데이터 교체 scope와 같은 생명주기를 따른다.
- 기존 상세 화면의 CRUD 규칙과 동일하게 동작한다.
- 원장 기반 거래 생성, 수정, 삭제의 계산 결과가 회귀하지 않는다.
- 좁은 화면에서도 하단 탭 라벨과 거래 행 텍스트가 overflow 처리된다.
- 검색/필터/정렬은 DB schema나 원장 state를 변경하지 않는다.
- 계산 미반영 거래는 거래 목록에 남아야 하지만 원장 계산에는 영향을 주지 않아야 한다.

## Automated Test Plan

```bash
flutter test test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 하단 `거래` 탭으로 진입한다.
- 빈 계정에서 빈 상태가 표시되는지 확인한다.
- 투자 보유 종목이 있는 계정에서 `+` 버튼을 누르고 투자 거래 폼으로 이동하는지 확인한다.
- 현금 계좌가 있는 계정에서 `+` 버튼을 누르고 현금 거래 폼으로 이동하는지 확인한다.
- 거래 행 탭으로 수정 폼 진입을 확인한다.
- 거래 행 스와이프 삭제와 확인 dialog를 확인한다.
- 검색어 입력 시 거래명, 계좌명, 날짜, 유형 기준으로 결과가 줄어드는지 확인한다.
- 전체/투자/현금/입금·수익/출금·매수 필터를 전환한다.
- 최신순/오래된순/금액 큰순/금액 작은순 정렬을 전환한다.
- 신규 거래 폼에서 기본 토글이 꺼져 있는지 확인한다.
- 계산 미반영 매수/입금 추가 후 보유 수량 또는 현금 잔액이 변하지 않는지 확인한다.
- 토글을 켜고 저장한 거래는 기존처럼 보유/현금 계산에 반영되는지 확인한다.

## Responsive Checklist

- 좁은 모바일 폭에서 하단 6개 탭 라벨이 겹치지 않는다.
- 거래 행 title/subtitle/amount가 한 줄 말줄임으로 유지된다.
- 계좌 선택 바텀시트가 긴 계좌 목록에서 스크롤된다.
- 검색/필터/정렬 컨트롤이 좁은 화면에서 가로 스크롤 또는 줄바꿈으로 깨지지 않는다.

## Regression Test Commands

```bash
flutter test test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze
```

## Acceptance Criteria

- walkthrough test가 통과한다.
- transaction flow test가 통과한다.
- analyzer issue가 없다.
- 검색/필터/정렬 컨트롤이 거래 페이지 smoke test에서 first frame을 깨지 않는다.
- transaction flow test에 계산 미반영 거래가 원장 state에 영향을 주지 않는 회귀가 포함된다.
- 수동 QA 미수행 항목은 test report에 명시한다.

## Release Risk Matrix

| Risk | Impact | Mitigation |
| --- | --- | --- |
| 하단 탭 6개로 인한 혼잡 | Medium | 짧은 `거래` 라벨과 아이콘 사용, 텍스트 overflow 처리 |
| 원장 라인 편집 불가 조건 누락 | High | 상세 화면과 같은 `canOpen*FormFromLedger` 조건 사용 |
| 이체/환전 다중 라인 표시 혼동 | Low | MVP에서는 기존 현금 상세 표시 정책 유지 |

## Future Test Expansion

- 계좌 선택 바텀시트 상호작용 widget test.
- 거래 목록 정렬 fixture test.
- 검색/필터 조합 widget test.
- 이체/환전 대표 행 grouping test.
