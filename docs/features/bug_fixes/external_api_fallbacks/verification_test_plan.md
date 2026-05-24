# External API Fallbacks Verification Test Plan

## Scope

외부 API 실패 시 분석/발표 화면에 필요한 데이터가 비어 보이지 않도록 서비스 fallback, UI 빈 상태, 기존 시세 fallback 회귀를 검증한다.

## Quality Goals

- OpenAI/Finnhub 계열 요약 실패가 캐시 또는 local fallback으로 수렴한다.
- KIS/Coinone 실패 시 기존 보유 단가 기반 snapshot fallback이 유지된다.
- fallback payload는 실제 카드 parser에서 제목, 요약, 이슈, 리스크 문구를 만들 수 있다.
- fallback 데이터는 실제 원격 성공 cache를 덮어쓰지 않는다.

## Automated Test Plan

```bash
dart format lib/services/market_news_summary_service.dart lib/services/company_news_summary_service.dart lib/services/portfolio_diagnosis_service.dart lib/widgets/market_news_summary_card.dart lib/widgets/company_news_summary_card.dart test/external_api_fallback_test.dart
flutter test test/external_api_fallback_test.dart
flutter test test/market_data_service_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 네트워크가 불안정하거나 Edge Function이 실패하는 상태에서 분석 화면의 종합 뉴스 카드가 빈 카드가 아닌지 확인한다.
- 종목별 뉴스 카드가 캐시 또는 fallback 안내를 표시하는지 확인한다.
- 포트폴리오 진단 생성 실패 시 기본 점검 결과 또는 명확한 실패 메시지가 표시되는지 확인한다.
- 발표 화면에서 시장/종목/시세 영역이 레이아웃 깨짐 없이 표시되는지 확인한다.

## Responsive Checklist

- 모바일 너비에서 긴 fallback 문구가 카드 밖으로 넘치지 않는다.
- 종목별 뉴스 fallback 타일의 심볼, 제목, 날짜, 펼침 아이콘이 겹치지 않는다.
- 포트폴리오 진단 fallback 문구가 버튼과 겹치지 않는다.

## Acceptance Criteria

- 모든 자동 테스트 명령이 통과한다.
- 외부 API 실패 경로에서 캐시가 있으면 캐시를 우선 사용한다.
- 캐시가 없으면 local fallback 또는 명확한 빈 상태 UI가 표시된다.
- 실제 원격 성공 응답의 저장 로직은 유지된다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| fallback이 실제 최신 분석처럼 오해됨 | Medium | Medium | `fallback-local`, 불확실성, API 지연 문구 표시 |
| 종목 뉴스 fallback이 너무 많은 타일을 생성 | Low | Low | 최대 5개로 제한 |
| 캐시 오염 | Low | Medium | local fallback은 cache 저장 제외 |

## Future Test Expansion

- AuthService/Supabase function invoke를 주입 가능한 client로 분리해 HTTP status별 서비스 테스트를 추가한다.
- 화면 widget test로 empty/fallback 카드 렌더링을 스냅샷화한다.
