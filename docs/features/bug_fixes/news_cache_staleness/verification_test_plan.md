# News Cache Staleness Verification Test Plan

## Scope

뉴스 조회가 오래된 로컬 캐시에 고정되지 않고, stale cache 상태에서 원격 조회 경로로 진행되는지 검증한다.

## Automated Tests

```bash
flutter test test/external_api_fallback_test.dart
flutter analyze
```

검증 기준:

- 2026-05-21 `cached_at`을 가진 시장 뉴스 캐시는 2026-05-24 기준 stale로 판정된다.
- 6시간 이내 `cached_at`을 가진 시장 뉴스 캐시는 fresh로 판정된다.
- 2026-05-21 `cached_at`을 가진 종목 뉴스 캐시는 2026-05-24 기준 stale로 판정된다.
- 6시간 이내 `cached_at`을 가진 종목 뉴스 캐시는 fresh로 판정된다.
- 외부 API fallback payload 기존 테스트가 계속 통과한다.

## Manual QA

1. iOS 시뮬레이터 또는 실제 기기에서 2026-05-21 이전/당일 뉴스 캐시가 남은 상태를 준비한다.
2. 앱을 실행하고 로그인 후 분석 탭에 진입한다.
3. 시장 뉴스와 종목 뉴스가 원격 조회 후 최신 `summary_date` 또는 최신 `updated_at`으로 갱신되는지 확인한다.
4. 네트워크를 끄거나 Edge Function 실패를 유도한 뒤 분석 탭을 다시 열어 기존 캐시/fallback이 표시되는지 확인한다.
5. 분석 탭에서 pull-to-refresh를 실행해 `forceRefresh: true` 경로가 계속 최신 원격 조회를 수행하는지 확인한다.

## Backend Operations Check

서버 DB의 최신 요약 자체가 2026-05-21에 머문 경우 다음을 별도 확인한다.

```bash
supabase functions invoke fetch-market-news --linked --body '{"category":"general"}'
supabase functions invoke summarize-market-news --linked --body '{"category":"general"}'
supabase functions invoke fetch-company-news --linked --body '{}'
supabase functions invoke summarize-company-news --linked --body '{}'
```

검증 기준:

- `market_news_summaries.summary_date` 최신 값이 오늘 날짜로 생성된다.
- `company_news_summaries.summary_date` 최신 값이 대상 symbol별로 생성된다.
- 운영 cron/webhook이 있다면 위 함수들이 정해진 주기로 호출되고 있는지 로그에서 확인한다.

## Remaining Risk

클라이언트는 stale cache가 원격 호출을 막는 문제를 해결하지만, 원격 요약 생성 cron이 멈춘 경우에는 서버 운영 조치가 필요하다.
