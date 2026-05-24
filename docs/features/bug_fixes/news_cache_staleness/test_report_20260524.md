# News Cache Staleness Test Report 2026-05-24

## Summary

iOS 뉴스 조회가 2026-05-21 캐시에 고정될 수 있는 cache-first 로직을 수정했다. 정상 조회에서는 6시간 이내 캐시만 즉시 반환하고, 그보다 오래된 캐시는 원격 Edge Function 조회를 시도한다.

## Reproduction Status

코드 경로상 재현 가능함을 확인했다. `MarketNewsSummaryService.fetchSummary()`와 `CompanyNewsSummaryService.fetchUserSummaries()`가 캐시 존재 여부만 보고 반환했으며, `cached_at` freshness 검사가 없었다.

## Root Cause

뉴스 캐시 테이블에는 `cached_at`이 있었지만 앱 서비스가 이를 사용하지 않았다. 그 결과 iOS 로컬 DB에 2026-05-21 캐시가 남으면 일반 조회 경로에서 원격 뉴스 API 호출이 차단되었다.

원격 Supabase도 함께 확인한 결과 서버 뉴스 파이프라인이 멈춰 있었다. `market_news_summaries`와 `company_news_summaries`의 최신 `summary_date`는 모두 2026-05-21이었고, `market_news`/`company_news` 원천 뉴스는 2026-05-20까지였다. pg_cron job은 `succeeded`로 기록됐지만 실제 `pg_net` 응답은 401이었고, 원인은 cron HTTP 호출에 Edge Function 플랫폼 JWT/내부 cron secret 인증 헤더가 없었던 것이다.

## Fix Summary

- 시장 뉴스 캐시에 6시간 freshness window를 적용했다.
- 종목 뉴스 캐시에 6시간 freshness window를 적용했다.
- stale cache는 정상 조회에서 원격 호출을 막지 않게 했다.
- 원격 실패 시 기존 캐시/fallback 반환은 유지했다.
- stale/fresh cache 판정 회귀 테스트를 추가했다.
- 원격 `CRON_SECRET`을 Supabase Edge Function secrets와 DB Vault에 추가했다.
- 뉴스 cron job을 anon JWT와 `x-cron-secret` 헤더, 300초 timeout을 사용하도록 재등록했다.
- cron용 뉴스 함수는 `CRON_SECRET`이 없거나 헤더가 맞지 않으면 401을 반환하도록 보강했다.
- `fetch-company-news`에 cron batch 경로를 추가해 로그인 사용자 1명 없이도 보이는 주식/코인 holdings 전체를 대상으로 수집할 수 있게 했다.

## Commands Run

```bash
dart format lib/services/market_news_summary_service.dart lib/services/company_news_summary_service.dart test/external_api_fallback_test.dart
flutter test test/external_api_fallback_test.dart
flutter analyze
git diff --check
git status --short
deno fmt supabase/functions/fetch-market-news/index.ts supabase/functions/fetch-company-news/index.ts supabase/functions/summarize-market-news/index.ts supabase/functions/summarize-company-news/index.ts
deno check supabase/functions/fetch-market-news/index.ts supabase/functions/fetch-company-news/index.ts supabase/functions/summarize-market-news/index.ts supabase/functions/summarize-company-news/index.ts
supabase functions deploy fetch-market-news fetch-company-news summarize-market-news summarize-company-news --use-api --jobs 1
```

## Command Results

- `dart format ...`: Passed. Initial sandbox run failed because Flutter SDK cache access was blocked, then passed with approved escalation.
- `flutter test test/external_api_fallback_test.dart`: Passed, 5 tests.
- `flutter analyze`: Passed, no issues found.
- `deno fmt ...`: Passed.
- `deno check ...`: Passed.
- `supabase secrets set CRON_SECRET=...`: Passed, value not printed.
- DB Vault `CRON_SECRET` creation: Passed, value not printed.
- `supabase functions deploy ...`: Passed. News functions deployed at 2026-05-24 12:24:37 UTC.
- Final function metadata check: Passed. Deployed news functions remain `verify_jwt: true`; cron requests pass platform auth with Vault `anon_key` and function auth with `x-cron-secret`.
- News pg_cron repair: Passed. Recreated `Market-News-Cron`, `Market-News-Cron2`, `Summarize-Market-News-Cron`, `Summarize-Market-News`, `Company-News-Cron`, and `Summarize-Company-News-Cron`.
- Manual `fetch-market-news` and `fetch-company-news` pg_net calls: Passed, HTTP 200.
- Manual `summarize-market-news` and `summarize-company-news` pg_net calls: Passed, HTTP 200.
- `git diff --check`: Passed.
- `git status --short`: Expected modified service/test/docs files plus new `docs/features/bug_fixes/news_cache_staleness/` docs.

## Regression Coverage

- 시장 뉴스 2026-05-21 stale cache 판정.
- 시장 뉴스 6시간 이내 fresh cache 판정.
- 종목 뉴스 2026-05-21 stale cache 판정.
- 종목 뉴스 6시간 이내 fresh cache 판정.
- 기존 외부 API fallback payload 테스트.

## Manual QA Status

원격 데이터 복구는 확인했다.

- `market_news` latest news date: 2026-05-23, updated at 2026-05-24 12:26:58 UTC.
- `company_news` latest news date: 2026-05-24, updated at 2026-05-24 12:26:59 UTC.
- `market_news_summaries` latest `summary_date`: 2026-05-24, updated at 2026-05-24 12:28:08 UTC.
- `company_news_summaries` latest `summary_date`: 2026-05-24, updated at 2026-05-24 12:28:36 UTC.

iOS 시뮬레이터/실기기에서 기존 로컬 캐시를 가진 상태로 분석 탭 진입과 pull-to-refresh는 아직 수동 확인이 필요하다.

## Remaining Risk

다음 cron 주기에서 401/timeout 없이 HTTP 200이 유지되는지 한 번 더 확인해야 한다. `pg_net` 응답 본문은 secret이나 내부 오류를 포함할 수 있어 기본 검증에서는 status/timestamp만 확인한다.

## Final Result

Passed for automated regression coverage and remote Supabase data recovery. Manual iOS QA and next scheduled cron run validation remain as follow-up checks.
