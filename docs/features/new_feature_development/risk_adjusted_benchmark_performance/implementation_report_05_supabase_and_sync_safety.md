# Implementation Report 05 - Supabase And Sync Safety

## Summary

분석용 파생 데이터가 기존 자산/보유자산 원본을 덮어쓰지 않도록 로컬 동기화 보호선을 추가하고, Supabase 원격 DB에 분석용 파생 테이블을 적용했다.

## Implemented

- `portfolio_daily_returns`, `benchmark_prices`를 핵심 동기화 payload에서 제외하는 동작을 테스트로 고정했다.
- 서버/복원 데이터로 로컬을 교체할 때 오래된 `portfolio_daily_returns`만 삭제해 분석값을 재계산하도록 했다.
- `benchmark_prices`는 기준지수 가격 데이터라 복원 시 삭제하지 않도록 유지했다.
- 자산 수, 보유자산 수, 수량 합계, 평가액 합계, 매수원금 합계, 0값 분포를 비교하는 `SyncSafetySnapshot`/`SyncSafetyIssue`를 추가했다.
- Supabase 검토용 SQL 초안에 파생 테이블 2개, 인덱스, RLS, 롤백 SQL 주석을 추가했다.
- 원격 Supabase `Moneyfi` 프로젝트에 `portfolio_daily_returns`, `benchmark_prices` 테이블을 적용했다.
- Supabase Data API 접근을 위해 `authenticated` role grant를 추가했다.
- `portfolio_daily_returns` RLS 정책은 advisor 경고를 피하기 위해 `(select auth.uid())` 형태로 최적화했다.

## Safety Notes

- 이번 구현은 `assets`, `holdings`, `transaction_events`, `transaction_lines`에 대한 원격 `update/delete/truncate`를 만들지 않는다.
- 복원 시 원본 포트폴리오 데이터가 바뀌었는지 확인할 수 있도록 전후 스냅샷 비교 API를 제공한다.
- 기준지수 가격 원격 쓰기는 아직 클라이언트 경로로 열지 않았다. 필요하면 별도 seed/admin 경로 또는 service role 기반 동기화 정책으로 분리해야 한다.
- 원격 적용 전후 `assets` row count, `holdings` row count, 수량 합계, 매수원금 합계, 평균단가/환율 zero 분포가 유지됨을 확인했다.
- 평가액 합계는 적용 전후 약 40,141.5524원 차이가 있었으나, row count/수량/매수원금이 동일하고 이번 SQL이 `holdings.current_price`를 수정하지 않아 가격 데이터 변동으로 분리해 기록한다.

## Verification

- `flutter analyze lib/db/app_database.dart lib/db/app_database_records.dart test/transaction_flow_test.dart`
- `flutter test test/transaction_flow_test.dart`
- `flutter test test/risk_adjusted_remote_schema_draft_test.dart`
- `git diff --check`
- `supabase db query --linked --output json <preflight/postflight SQL>`
- Supabase MCP `apply_migration`: `add_risk_adjusted_performance_tables`
- Supabase MCP `apply_migration`: `optimize_risk_adjusted_performance_rls`
