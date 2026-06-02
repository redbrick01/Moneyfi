# News Cache Staleness Plan

## Bug Summary

iOS 뉴스 2026-05-21 뒤 데이터 안 보임. 시장 뉴스/종목 뉴스 요약 화면이 최신 Supabase Edge Function 응답 대신 낡은 로컬 Drift 캐시 계속 반환 가능.

## User Impact

- 분석 화면, 로그인 후 뉴스 준비 단계에서 최신 시장/종목 뉴스 요약 못 봄.
- 2026-05-21 캐시 가진 iOS 기기, 앱 재실행 후도 원격 조회 없이 같은 날짜 뉴스만 표시 가능.
- 투자 판단 보조 정보가 stale 상태 유지.

## Reproduction Or Evidence

- `lib/services/market_news_summary_service.dart`의 `fetchSummary()`는 `forceRefresh == false`이고 `summaryDate == null`이면 `fetchCachedSummary()` 결과 즉시 반환.
- `lib/services/company_news_summary_service.dart`의 `fetchUserSummaries()`도 캐시 목록 있으면 즉시 반환.
- 로컬 DB 테이블 `market_news_caches`, `company_news_caches`에는 `cached_at` 컬럼 이미 있음. 조회 경로에서 만료 검사 없음.
- 분석 화면 pull-to-refresh는 `forceRefresh: true` 사용. 일반 진입/로그인 준비 경로는 기본 조회라 오래된 캐시가 원격 호출 막음.
- `supabase/config.toml`에는 뉴스 수집/요약 함수 스케줄 없음. 서버 요약 생성은 별도 운영 cron/webhook이 최신 데이터 만들어야 함.

## Root Cause Hypothesis

주 원인: 클라이언트 뉴스 서비스 무기한 cache-first 정책. iOS 로컬 저장소에 2026-05-21 뉴스 캐시 남으면 앱은 캐시 존재만 보고 원격 `get-market-news-summary`, `get-user-company-news-summaries` Edge Function 호출 안 함.

보조 운영 리스크: 저장된 서버 요약 자체가 stale이면 클라이언트가 원격 재호출해도 최신 요약 못 받음. 이 경우 `fetch-market-news`/`fetch-company-news`, `summarize-market-news`/`summarize-company-news` cron 상태 별도 확인 필요.

## Fix Strategy

- 시장 뉴스 캐시에 6시간 freshness window 적용.
- 종목 뉴스 캐시에도 6시간 freshness window 적용.
- 캐시 stale이면 정상 조회 경로에서 원격 Edge Function 호출.
- 원격 실패 또는 Auth 초기화 실패 시 기존처럼 캐시/fallback 반환해 빈 화면 방지.
- `cached_at` 기반 freshness 판단 단위 테스트로 고정.

## Non-Goals

- Supabase 스케줄러 또는 외부 cron 인프라 새로 안 만듦.
- 뉴스 요약 스키마와 UI 레이아웃 변경 안 함.
- Finnhub/OpenAI 호출 정책 변경 안 함.

## Regression Test Plan

- `test/external_api_fallback_test.dart`에 시장 뉴스 stale/fresh cache 판정 테스트 추가.
- `test/external_api_fallback_test.dart`에 종목 뉴스 stale/fresh cache 판정 테스트 추가.
- `flutter test test/external_api_fallback_test.dart` 실행.
- `flutter analyze` 실행.

## Risk And Rollback Notes

- 6시간 넘은 캐시는 앱 진입 시 원격 호출 유발. Edge Function 호출량 증가 가능.
- 원격 장애 시 stale cache fallback 유지. 사용자 화면 안 빔.
- 문제 있으면 freshness 검사 추가 부분만 되돌려 이전 cache-first 동작 복구.