# Transaction Event Flow Classification Plan

## Product Goal

거래 금액 색상 + 향후 분석 기준을 문자열 추론 말고 원장 이벤트 명시 분류로 판단. 포트폴리오 외부 유입 현금 = 외부 입금, 외부 유출 현금 = 외부 출금. 이체, 환전, 매수, 매도, 배당, 이자 등 나머지 = 포트폴리오 내부 트랜잭션.

## Current Baseline

- `transaction_events`는 `kind`, `source`만 있음. 외부 현금 흐름/내부 거래를 UI에서 `ledgerAction`/거래 유형 문자열로 추론.
- 거래 탭 + 상세 거래내역 row는 최근 패치로 `deposit`/`withdrawal` 액션만 색상 강조. DB 의미 고정 없음.
- sync payload + Supabase `transaction_events` schema도 외부/내부 흐름 분류 미전달.
- 기존 계산 쿼리는 `transaction_lines.action` + `transaction_events.source` 기준.

## Success Criteria

- 로컬 Drift `transaction_events`에 `flow_category` 추가.
- Supabase `transaction_events`에도 같은 `flow_category` 추가.
- 새 이벤트 생성 시 외부 입금 = `external_deposit`, 외부 출금 = `external_withdrawal`, 그 외 = `internal`.
- 기존 데이터는 migration/backfill로 같은 기준 채움.
- sync export/import + Edge Function upsert/download payload가 `flow_category` 보존.
- 거래 탭, 보유 상세, 현금 상세 금액 색상은 `TransactionItem.flowCategory` 기준.
- 원장 계산 결과 + record-only 계산 제외 정책 변경 없음.

## Metric And Data Definitions

`transaction_events.flow_category` 값:

- `external_deposit`: 포트폴리오 외부에서 현금 유입. 현금 `입금`/`deposit`만 해당.
- `external_withdrawal`: 포트폴리오 외부로 현금 유출. 현금 `출금`/`withdrawal`만 해당.
- `internal`: 포트폴리오 내부 이동 또는 자산 상태 변동. `cash_transfer`, `fx_exchange`, `trade`, `income`, `fee`, `tax`, `adjustment`, `opening_balance`, `record_only` 투자 이벤트 등.

UI 색상 기준:

- `external_deposit`: positive.
- `external_withdrawal`: negative.
- `internal`: 기본 텍스트 색.

## Proposed UX

- 화면 구성 변경 없음.
- 거래 row 금액 색상만 명시적 `flow_category` 기준.
- record-only 거래도 외부 입금/출금이면 색상은 외부 흐름 기준. 계산 반영 여부와 색상 의미 분리.

## Data And API Changes

- Local Drift
  - `TransactionEvents.flowCategory TEXT NOT NULL DEFAULT 'internal'`.
  - `schemaVersion` 증가.
  - migration helper로 기존 DB 컬럼 추가 + backfill.
  - `TransactionItem.flowCategory` 추가.
- Supabase
  - 새 migration으로 `public.transaction_events.flow_category text not null default 'internal'` 추가.
  - 기존 remote row backfill.
  - Fresh baseline migration에도 컬럼 반영.
- Sync
  - Flutter dirty payload에 `flow_category` 포함.
  - Flutter restore/import에서 누락 값은 `internal` fallback.
  - `sync-local-db` upsert allowlist + `get-sync-local-db` select/response에 `flow_category` 포함.

## Development Phases

1. 문서 + 검증 계획 작성.
2. 로컬 Drift schema, migration, model, event creation/update 경로 반영.
3. 표시 row 색상 기준을 `flowCategory`로 전환.
4. sync payload + Edge Function 반영.
5. Supabase migration/baseline 반영.
6. transaction flow 테스트 추가 + 자동 검증.
7. 임시 문서 삭제, 최종 보고서 작성.

## MVP Scope

- `flow_category` 컬럼 + 세 분류값만 추가.
- UI에 별도 배지/필터 추가 없음.
- 원격 migration 파일 추가. 이번 로컬 작업에서 원격 `supabase db push`는 자동 검증 후 별도 배포 판단으로 남김.

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

- Drift generated file 변경됨. `build_runner` 필요.
- 기존 row backfill 기준은 cash_flow 이벤트의 transaction line action 우선. 모호한 이벤트는 `internal`.
- 원격 DB migration 적용은 운영 작업. 로컬 코드 + 테스트 통과 뒤 별도 적용.
- 기존 sync payload 받는 서버가 새 컬럼 모르면 upsert 컬럼 오류 가능. Edge Function allowlist + remote migration은 같은 배포 묶음 필요.

## Open Questions

- 향후 배당/이자를 “외부 현금 유입”으로 볼지 “포트폴리오 내부 수익”으로 볼지 정책 바뀌면 `flow_category` 값 확장 필요. 이번 범위는 사용자 지정대로 입금/출금만 외부 흐름.

## Feasibility And Feedback

- 기존 `transaction_events.kind` + `transaction_lines.action` 유지하고 컬럼만 추가하면 계산 쿼리 영향 작음.
- UI가 액션 문자열 대신 이벤트 분류 읽으면 향후 환전/이체/매수/매도 색상 정책 안정.
- sync + Supabase schema를 함께 바꿔야 해서 단일 UI 패치보다 배포 순서 리스크 높음.
- 첫 batch는 로컬 schema + 테스트 통과 집중. 원격 적용은 test report에 별도 리스크로 남김.