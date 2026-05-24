# News Cache Staleness Plan

## Bug Summary

iOS에서 뉴스 조회 시 2026-05-21 이후 데이터가 표시되지 않는 문제가 보고되었다. 앱의 시장 뉴스와 종목 뉴스 요약 화면이 최신 Supabase Edge Function 응답 대신 오래된 로컬 Drift 캐시를 계속 반환할 수 있다.

## User Impact

- 사용자는 분석 화면과 로그인 후 뉴스 준비 단계에서 최신 시장/종목 뉴스 요약을 보지 못한다.
- 2026-05-21에 저장된 캐시가 있는 iOS 기기는 앱 재실행 후에도 원격 조회 없이 같은 날짜의 뉴스만 표시될 수 있다.
- 투자 판단 보조 정보가 오래된 상태로 유지된다.

## Reproduction Or Evidence

- `lib/services/market_news_summary_service.dart`의 `fetchSummary()`는 `forceRefresh == false`이고 `summaryDate == null`이면 `fetchCachedSummary()` 결과를 즉시 반환했다.
- `lib/services/company_news_summary_service.dart`의 `fetchUserSummaries()`도 캐시 목록이 비어 있지 않으면 즉시 반환했다.
- 로컬 DB 테이블 `market_news_caches`, `company_news_caches`에는 `cached_at` 컬럼이 이미 있지만, 조회 경로에서 만료 여부를 검사하지 않았다.
- 분석 화면 pull-to-refresh는 `forceRefresh: true`를 사용하지만, 일반 진입/로그인 준비 경로는 기본 조회를 사용하므로 오래된 캐시가 원격 호출을 막는다.
- `supabase/config.toml`에는 뉴스 수집/요약 함수의 스케줄 설정이 없어서, 서버 요약 생성은 별도 운영 cron/webhook이 최신 데이터를 만들어야 한다.

## Root Cause Hypothesis

주 원인은 클라이언트 뉴스 서비스의 무기한 cache-first 정책이다. iOS 로컬 저장소에 2026-05-21 뉴스 캐시가 남아 있으면 앱은 캐시 존재만 확인하고 원격 `get-market-news-summary`, `get-user-company-news-summaries` Edge Function을 호출하지 않는다.

보조 운영 리스크로, 저장된 서버 요약 자체가 오래되면 클라이언트가 원격을 다시 호출해도 최신 요약을 받을 수 없다. 이 경우 `fetch-market-news`/`fetch-company-news`와 `summarize-market-news`/`summarize-company-news` cron 상태를 별도로 확인해야 한다.

## Fix Strategy

- 시장 뉴스 캐시에 6시간 freshness window를 적용한다.
- 종목 뉴스 캐시에도 6시간 freshness window를 적용한다.
- 캐시가 stale이면 정상 조회 경로에서 원격 Edge Function을 호출한다.
- 원격 실패 또는 Auth 초기화 실패 시에는 기존처럼 캐시/fallback을 반환해 빈 화면을 피한다.
- `cached_at` 기반 freshness 판단을 단위 테스트로 고정한다.

## Non-Goals

- Supabase 스케줄러 또는 외부 cron 인프라를 새로 만들지 않는다.
- 뉴스 요약 스키마와 UI 레이아웃은 변경하지 않는다.
- Finnhub/OpenAI 호출 정책은 변경하지 않는다.

## Regression Test Plan

- `test/external_api_fallback_test.dart`에 시장 뉴스 stale/fresh cache 판정 테스트를 추가한다.
- `test/external_api_fallback_test.dart`에 종목 뉴스 stale/fresh cache 판정 테스트를 추가한다.
- `flutter test test/external_api_fallback_test.dart`를 실행한다.
- `flutter analyze`를 실행한다.

## Risk And Rollback Notes

- 6시간보다 오래된 캐시는 앱 진입 시 원격 호출을 유발하므로 Edge Function 호출량이 증가할 수 있다.
- 원격 장애 시 stale cache fallback은 유지되어 사용자 화면은 비지 않는다.
- 문제가 있으면 freshness 검사 추가 부분만 되돌리면 이전 cache-first 동작으로 복구된다.
