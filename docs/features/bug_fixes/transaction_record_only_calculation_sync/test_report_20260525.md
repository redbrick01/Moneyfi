# Transaction Record Only Calculation And Supabase Start Test Report 2026-05-25

## Summary

계산 미포함 거래가 현재 보유/현금 상태를 바꾸지 않으면서도 분석 데이터로는 계속 사용되는 정책을 회귀 테스트로 고정했다. 또한 로컬 Supabase 마이그레이션 시작 실패를 수정했다.

## Reproduction Status

- `record_only` 매수 거래 `단가 100`, `수량 5`가 보유/현금 상태에는 반영되지 않지만 성과 `buyAmount = 500`으로 집계되는 정책을 확인했다.
- `record_only` 배당 `7`이 배당/이자 분석 총합에 포함되어 총합이 `42`로 계산되는 정책을 확인했다.
- 수정 전 `supabase start`는 `latest_restore_snapshots` temp table 중복 생성으로 실패했다.

## Root Cause

- 상태 재계산 SQL과 분석 SQL의 `record_only` 처리 정책이 테스트 이름만으로 충분히 드러나지 않았다.
- 두 Supabase migration이 같은 DB 세션에서 같은 temp table 이름을 사용했다.

## Fix Summary

- 거래 회귀 테스트에 통화별 성과와 drill-down 포함 검증을 추가했다.
- 현재 보유/현금 상태 계산은 `record_only` 제외를 유지하고, 분석/성과 조회는 `record_only`를 포함하는 정책을 문서화했다.
- `20260522153000_rebuild_snapshot_restore_ledger_lines.sql` 시작부에 이전 temp table drop을 추가했다.
- bug fix 문서와 검증 계획을 추가했다.

## Commands Run

| 명령 | 결과 |
| --- | --- |
| `flutter test test/transaction_flow_test.dart` | Pass |
| `flutter test test/page_walkthrough_test.dart` | Pass |
| `deno check supabase/functions/sync-local-db/index.ts supabase/functions/get-sync-local-db/index.ts` | Pass |
| `supabase start` | Pass |
| `supabase db query "select count(*) as transaction_events_tables from information_schema.tables where table_schema = 'public' and table_name = 'transaction_events';"` | Pass, returned `1` |
| `flutter test` | Pass, 106 tests |
| `flutter analyze` | Pass |
| `./gradlew :app:compileDebugKotlin` | Pass |
| `supabase stop` | Pass |

## Regression Coverage

- Record-only investment buy remains visible in local transaction data.
- Record-only investment buy leaves holding quantity and settlement cash unchanged.
- Record-only investment buy is included in holding performance, portfolio performance, currency performance, and performance event drill-down.
- Record-only dividend is included in income analysis.
- Supabase migration chain now applies through local startup.

## Manual QA Status

Manual app UI QA was not run. The affected behavior is covered through Drift DB and widget/unit test paths. A final manual pass should create included/excluded transactions in the app and verify 거래, 분석, 통계 화면 values.

## Remaining Risk

- Remote production Supabase was not modified or queried.
- Budget-specific calculations were not found in the current automated coverage and should be checked manually if/when that feature has dedicated code paths.
- Local Supabase CLI prints a CPU/AVX warning and update notice, but startup and migration verification completed successfully.

## Final Result

Pass. The two reported blockers are fixed locally and covered by automated regression checks.
