# Transaction Management Page Plan

## Product Goal

사용자, 자산/현금 계좌 상세 진입 없이 전체 거래 한곳에서 보고 추가/수정/삭제. 거래 많아도 검색/필터/정렬로 빠른 탐색.
과거 거래는 기록 보강용. 기본값은 포트폴리오 계산 미반영. 사용자가 명시 ON한 거래만 보유/현금/성과 계산 반영.

## Current Baseline

- 거래 내역은 보유 종목 상세, 현금 계좌 상세 섹션에만 노출.
- 투자 거래는 `TransactionFormPage`, 현금 거래는 `CashTransactionFormPage`에서 생성/수정.
- 삭제는 상세 화면 거래 행에서 `AppDatabase.deleteLedgerTransactionItem` + `SyncService.syncNow`.
- 전체 거래 목록 전용 탭/페이지 없음.
- 거래 탭 초기 구현은 전체 목록/CRUD 집중. 검색/필터/정렬 아직 없음.
- 기존 거래 저장 폼은 저장 즉시 보유 수량, 현금 잔액, 성과 원장 반영.

## Success Criteria

- 하단 내비게이션에서 거래 전용 화면 진입 가능.
- 모든 보유 종목/현금 계좌 거래, 날짜 최신순 표시.
- 거래 화면에서 거래 추가/수정/삭제 가능.
- 거래명, 계좌명, 자산명, 날짜, 유형 검색 가능.
- 전체/투자/현금/입금·수익/출금·매수 필터 가능.
- 최신순, 오래된순, 금액 큰순, 금액 작은순 정렬 가능.
- 거래 추가/수정 시 `포트폴리오 계산에 반영` 토글 제공. 기본 OFF.
- 계산 미반영 거래는 목록 표시, 보유 수량/평단/현금 잔액/성과 집계 영향 없음.
- 투자/현금 거래는 기존 폼과 DB API 재사용. 원장 정합성 유지.
- 데이터 교체, 로그아웃 정리, 원격 새로고침은 기존 탭 규칙 동일.

## Metric And Data Definitions

- 표시 대상: `AppDatabase.fetchAssets()` 반환 활성 자산의 활성 보유/현금 계좌 거래.
- 기본 정렬: `TransactionItem.date` 내림차순. 같은 날짜는 로드된 원장 순서 역순.
- 금액 정렬: 거래 탭 표시 KRW 환산 금액 기준.
- 계산 미반영 거래: `transaction_events.source = 'record_only'` 저장, 계산 쿼리 제외.
- 계산 미반영 거래도 표시용 `transaction_lines` 유지. 목록/검색/수정/삭제 가능.
- 투자 거래 금액은 보유 종목 통화/환율로 표시.
- 현금 거래 금액은 현금 계좌 통화/환율로 표시.
- 삭제는 기존 DB API 사용. 원장 이벤트와 연결된 legacy mirror 함께 soft delete.

## Proposed UX

- 하단 탭에 `거래` 추가.
- 화면 상단 액션 버튼으로 거래 추가.
- 추가 시 계좌 선택 바텀시트 표시. 투자 보유 종목 또는 현금 계좌 선택 후 대상별 기존 거래 폼 오픈.
- 거래 행 탭하면 수정 폼 오픈.
- 거래 행은 기존 상세 화면처럼 스와이프 삭제 지원.
- 거래 없으면 빈 상태 + 거래 추가 액션 표시.
- 목록 상단에 검색 입력, 필터 chip, 정렬 메뉴 배치.
- 검색/필터 결과 없으면 조건 초기화 액션 제공.
- 거래 폼에 계산 반영 여부 토글 배치. 기본 OFF. ON이면 기존 실제 거래로 저장.

## Data And API Changes

- DB schema 변경 없음.
- 신규 page-level view model은 `fetchAssets()` 결과 평탄화 사용.
- 기존 생성/수정/삭제 API 재사용.
- `createTransaction`과 `updateTransactionItem`은 계산 반영 여부 인자로 받아 `ledger` 또는 `record_only` 원장 이벤트 생성.
- 계산/성과/상태 parity 쿼리는 `record_only` source 제외.
- 별도 sync endpoint 변경 없음.

## Development Phases

1. 거래 관리 페이지 추가, 전체 거래 평탄화 모델 구현.
2. 계좌 선택 바텀시트와 기존 거래 폼 연결.
3. 거래 행 수정/삭제, 새로고침, 빈/오류/로딩 상태 구현.
4. 앱 셸 하단 탭 연결, 데이터 교체 scope 반영.
5. walkthrough 및 거래 흐름 테스트 보강.
6. 검색, 필터, 정렬 조회 state와 UI 추가.
7. 계산 반영 토글과 record-only 원장 저장 정책 추가.

## MVP Scope

- 전체 거래 목록, 추가, 수정, 삭제.
- 기존 투자/현금 거래 폼 재사용.
- 날짜 최신순 정렬.
- 검색, 필터, 정렬 조회.
- 기본 계산 미반영 거래 추가/수정.
- pull-to-refresh와 원격 sync 후 local reload.

## Out Of Scope

- 기간 선택, CSV export.
- 거래 bulk edit.
- 원장 라인 단위 고급 분해/병합 UI.
- 새로운 DB schema 또는 Supabase migration.

## Test Plan

- `flutter test test/page_walkthrough_test.dart`
- `flutter test test/transaction_flow_test.dart`
- `flutter analyze`
- 수동 QA: 거래 탭 진입, 추가 계좌 선택, 투자/현금 거래 수정, 삭제 확인.
- 수동 QA: 검색어, 필터, 정렬 조합별 결과 확인.
- 수동 QA: 계산 미반영 거래 추가 후 보유 수량/현금 잔액 불변 확인.

## Risks And Decisions

- 이체/환전처럼 한 이벤트가 여러 라인 만들면 행이 둘 이상 표시 가능. MVP는 기존 현금 상세 화면 표시 정책 유지.
- 직접 수정 불가 원장 라인은 기존 상세 화면과 같은 안내 문구 표시, 수정 폼 진입 차단.
- 하단 탭 6개로 좁은 화면 혼잡 가능. MVP는 짧은 `거래` 라벨과 아이콘 유지. 후속 UX에서 탭 재배치 검토.
- 기본값 계산 미반영이면 실제 거래 반영 누락 가능. 토글 라벨/설명 명확히 표시.

## Open Questions

- 이체/환전을 대표 행 하나로 묶을지.
- 거래 화면을 탭 대신 포트폴리오 또는 My 하위 페이지로 옮길지.

## Feasibility And Feedback

- 기존 `fetchAssets()`, `TransactionFormPage`, `CashTransactionFormPage`, `deleteLedgerTransactionItem` 재사용 가능. schema 변경 없이 구현 가능.
- 사용자 체감 효과 높음. 자산별 상세 화면 진입 단계 감소.
- 데이터 정확도 리스크 낮음. 단, 원장 기반 투자/현금 거래 편집 가능 조건은 상세 화면과 동일 유지 필요.
- UI 복잡도는 계좌 선택 바텀시트와 전체 거래 행에 집중. 검색/필터는 MVP 제외해 범위 고정.
- 첫 개발 batch: 페이지, 평탄화 모델, 앱 셸 탭 연결. 두 번째 batch: CRUD 액션과 테스트.