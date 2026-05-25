# Transaction Event Flow Classification Plan

## Product Goal

거래 금액 색상과 향후 분석 기준을 문자열 추론이 아니라 원장 이벤트의 명시적 분류로 판단한다. 포트폴리오 외부에서 들어온 현금은 외부 입금, 포트폴리오 외부로 나간 현금은 외부 출금으로 저장하고, 이체, 환전, 매수, 매도, 배당, 이자 등 나머지는 포트폴리오 내부 트랜잭션으로 분류한다.

## Current Baseline

- `transaction_events`는 `kind`, `source`만 가지고 있어 외부 현금 흐름과 내부 거래를 UI에서 `ledgerAction`/거래 유형 문자열로 추론한다.
- 거래 탭과 상세 거래내역 row는 최근 패치로 `deposit`/`withdrawal` 액션만 색상 강조하지만, DB에 의미가 고정되어 있지 않다.
- sync payload와 Supabase `transaction_events` schema도 외부/내부 흐름 분류를 전달하지 않는다.
- 기존 계산 쿼리는 `transaction_lines.action`과 `transaction_events.source`를 기준으로 동작한다.

## Success Criteria

- 로컬 Drift `transaction_events`에 `flow_category`가 추가된다.
- Supabase `transaction_events`에도 같은 `flow_category`가 추가된다.
- 새 이벤트 생성 시 외부 입금은 `external_deposit`, 외부 출금은 `external_withdrawal`, 그 외는 `internal`로 저장된다.
- 기존 데이터는 migration/backfill로 동일 기준에 맞게 채워진다.
- sync export/import와 Edge Function upsert/download payload가 `flow_category`를 보존한다.
- 거래 탭, 보유 상세, 현금 상세 금액 색상은 `TransactionItem.flowCategory`를 기준으로 판단한다.
- 원장 계산 결과와 record-only 계산 제외 정책은 변경하지 않는다.

## Metric And Data Definitions

`transaction_events.flow_category` 값:

- `external_deposit`: 포트폴리오 외부에서 현금이 들어오는 이벤트. 현금 `입금`/`deposit`만 해당한다.
- `external_withdrawal`: 포트폴리오 외부로 현금이 나가는 이벤트. 현금 `출금`/`withdrawal`만 해당한다.
- `internal`: 포트폴리오 내부 이동 또는 자산 상태 변동. `cash_transfer`, `fx_exchange`, `trade`, `income`, `fee`, `tax`, `adjustment`, `opening_balance`, `record_only` 투자 이벤트 등이 해당한다.

UI 색상 기준:

- `external_deposit`: positive.
- `external_withdrawal`: negative.
- `internal`: 기본 텍스트 색.

## Proposed UX

- 화면 구성은 바꾸지 않는다.
- 거래 row 금액 색상만 명시적 `flow_category` 기준으로 결정한다.
- record-only 거래도 외부 입금/출금으로 기록한 경우 색상은 외부 흐름 기준을 따른다. 계산 반영 여부와 색상 의미는 분리한다.

## Data And API Changes

- Local Drift
  - `TransactionEvents.flowCategory TEXT NOT NULL DEFAULT 'internal'`.
  - `schemaVersion` 증가.
  - migration helper로 기존 DB에 컬럼 추가 및 backfill.
  - `TransactionItem.flowCategory` 추가.
- Supabase
  - 새 migration으로 `public.transaction_events.flow_category text not null default 'internal'` 추가.
  - 기존 remote row backfill.
  - Fresh baseline migration에도 컬럼 반영.
- Sync
  - Flutter dirty payload에 `flow_category` 포함.
  - Flutter restore/import에서 누락 값은 `internal`로 fallback.
  - `sync-local-db` upsert allowlist와 `get-sync-local-db` select/response에 `flow_category` 포함.

## Development Phases

1. 문서와 검증 계획 작성.
2. 로컬 Drift schema, migration, model, event creation/update 경로 반영.
3. 표시 row 색상 기준을 `flowCategory`로 전환.
4. sync payload와 Edge Function 반영.
5. Supabase migration/baseline 반영.
6. transaction flow 테스트 추가 및 자동 검증.
7. 임시 문서 삭제, 최종 보고서 작성.

## MVP Scope

- `flow_category` 컬럼과 세 가지 분류값만 추가한다.
- UI에는 별도 배지나 필터를 추가하지 않는다.
- 원격 migration 파일은 추가하지만, 이번 로컬 작업에서 원격 `supabase db push`는 자동 검증 후 별도 배포 판단으로 남긴다.

## Test Plan

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database.g.dart lib/models/asset_item.dart lib/pages/transactions_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/components/rows/transaction_row.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- Drift generated file이 변경되므로 `build_runner` 실행이 필요하다.
- 기존 row backfill 기준은 cash_flow 이벤트의 transaction line action을 우선한다. 모호한 이벤트는 `internal`로 둔다.
- 원격 DB migration 적용은 운영 작업이므로, 로컬 코드와 테스트가 통과한 뒤 별도 적용한다.
- 기존 sync payload를 받는 서버가 새 컬럼을 모르면 upsert에서 컬럼 오류가 날 수 있으므로 Edge Function allowlist와 remote migration이 같은 배포 묶음이어야 한다.

## Open Questions

- 향후 배당/이자를 “외부 현금 유입”으로 볼지 “포트폴리오 내부 수익”으로 볼지 제품 정책이 바뀌면 `flow_category` 값 확장이 필요하다. 이번 범위에서는 사용자가 지정한 대로 입금/출금만 외부 흐름으로 본다.

## Feasibility And Feedback

- 기존 `transaction_events.kind`와 `transaction_lines.action`을 유지하면서 컬럼만 추가하면 계산 쿼리 영향이 작다.
- UI가 액션 문자열 대신 이벤트 분류를 읽으면 향후 환전/이체/매수/매도 색상 정책이 안정된다.
- sync와 Supabase schema를 함께 바꿔야 하므로 단일 UI 패치보다 배포 순서 리스크가 높다.
- 첫 batch는 로컬 schema와 테스트를 통과시키는 것에 집중하고, 원격 적용은 test report에 별도 리스크로 남긴다.
