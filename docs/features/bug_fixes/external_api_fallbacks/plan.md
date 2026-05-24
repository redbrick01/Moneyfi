# External API Fallbacks Plan

## Product Goal

KIS, Coinone, Finnhub, OpenAI 등 외부 API가 실패해도 발표 화면과 분석 화면이 빈 카드나 깨진 상태로 보이지 않게 한다. 사용자는 캐시, 기본 샘플 안내, 명확한 오류 문구 중 하나를 항상 확인할 수 있어야 한다.

## Current Baseline

- KIS/Coinone 시세 조회는 `HoldingMarketSnapshot.fallback`으로 현재 보유 단가 기반 표시를 유지한다.
- 시장 뉴스 요약과 종목 뉴스 요약은 예외 발생 시 캐시를 사용하지만, HTTP 비정상 응답이나 `ok=false` 응답에서는 빈 결과로 끝날 수 있다.
- 포트폴리오 AI 진단은 일부 실패 경로에서 캐시 없이 `null`을 반환해 새 진단 생성 실패 UI로 떨어질 수 있다.
- 뉴스 카드의 빈 상태 문구는 데이터 없음과 외부 API 실패를 구분하기 어렵다.

## Success Criteria

- 시장 뉴스 요약 실패는 `cache -> local fallback` 순서로 처리한다.
- 종목 뉴스 요약 실패는 `cache -> visible holdings 기반 local fallback` 순서로 처리한다.
- 포트폴리오 진단 실패는 `cache -> rule-based local fallback` 순서로 처리한다.
- KIS/Coinone 기존 snapshot fallback 회귀 테스트는 유지한다.
- 빈 카드가 남는 경우에도 외부 API 또는 캐시 부재를 설명하는 문구가 표시된다.

## Proposed UX

- 캐시가 있으면 기존 데이터와 업데이트 메타를 그대로 보여준다.
- 캐시가 없으면 `fallback-local` 모델 메타와 함께 기본 점검 안내를 보여준다.
- 실제 보유 종목이 없거나 표시 가능한 종목이 없으면 명확한 빈 상태 문구를 보여준다.

## Data/API Changes

- 원격 API 계약이나 DB schema는 변경하지 않는다.
- fallback payload는 로컬 런타임에서 생성하며 캐시에 저장하지 않는다.
- 실제 원격 성공 응답만 기존 cache table에 저장한다.

## Development Phases

1. 실패 경로 조사: market/company news, portfolio diagnosis, market data fallback 확인.
2. 서비스 보강: 비정상 응답과 예외를 같은 fallback 경로로 정리.
3. UI 빈 상태 보강: 외부 API 실패와 캐시 부재를 설명하는 문구 적용.
4. 테스트 추가: fallback payload가 카드 파서와 진단 UI에 충분한 데이터를 제공하는지 검증.
5. 문서화 및 검증: 실행 명령과 미수행 수동 QA를 기록.

## MVP Scope

- Flutter 서비스와 카드 문구 변경.
- 로컬 fallback payload builder 추가.
- 단위 테스트 추가.
- 외부 API mock 서버나 Supabase Edge Function 변경은 제외한다.

## Test Plan

- `dart format`으로 변경 Dart 파일 포맷.
- `flutter test test/external_api_fallback_test.dart`.
- `flutter test test/market_data_service_test.dart`.
- `flutter analyze`.
- `git diff --check`.

## Risks And Decisions

- local fallback은 최신 투자 판단이 아니므로 `fallback-local` 메타와 불확실성 문구를 명시한다.
- fallback payload는 캐시에 저장하지 않아 실제 원격 성공 데이터를 오염시키지 않는다.
- 종목 뉴스 fallback은 표시 가능한 주식/코인 보유 심볼 최대 5개만 만든다.

## Feasibility And Feedback

- 기존 서비스의 cache helper와 카드 파서를 재사용하므로 변경 범위가 작다.
- 원격 Edge Function 계약을 바꾸지 않아 배포 리스크가 낮다.
- 수동 발표 화면 확인은 별도 QA가 필요하지만, 자동 테스트로 빈 payload 회귀는 고정할 수 있다.
