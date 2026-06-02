# External API Fallbacks Plan

## Product Goal

KIS, Coinone, Finnhub, OpenAI 등 외부 API 실패해도 발표/분석 화면 빈 카드, 깨짐 없음. 사용자 항상 캐시, 기본 샘플 안내, 명확 오류 문구 중 하나 확인.

## Current Baseline

- KIS/Coinone 시세 조회는 `HoldingMarketSnapshot.fallback`으로 현재 보유 단가 기반 표시 유지.
- 시장 뉴스 요약, 종목 뉴스 요약은 예외 시 캐시 사용. HTTP 비정상 응답이나 `ok=false` 응답은 빈 결과 가능.
- 포트폴리오 AI 진단은 일부 실패 경로에서 캐시 없이 `null` 반환, 새 진단 생성 실패 UI로 이동 가능.
- 뉴스 카드 빈 상태 문구는 데이터 없음과 외부 API 실패 구분 어려움.

## Success Criteria

- 시장 뉴스 요약 실패: `cache -> local fallback`.
- 종목 뉴스 요약 실패: `cache -> visible holdings 기반 local fallback`.
- 포트폴리오 진단 실패: `cache -> rule-based local fallback`.
- KIS/Coinone 기존 snapshot fallback 회귀 테스트 유지.
- 빈 카드 남아도 외부 API 또는 캐시 부재 설명 문구 표시.

## Proposed UX

- 캐시 있으면 기존 데이터와 업데이트 메타 표시.
- 캐시 없으면 `fallback-local` 모델 메타와 기본 점검 안내 표시.
- 실제 보유 종목 없거나 표시 가능 종목 없으면 명확한 빈 상태 문구 표시.

## Data/API Changes

- 원격 API 계약, DB schema 변경 없음.
- fallback payload는 로컬 런타임 생성, 캐시 저장 없음.
- 실제 원격 성공 응답만 기존 cache table 저장.

## Development Phases

1. 실패 경로 조사: market/company news, portfolio diagnosis, market data fallback 확인.
2. 서비스 보강: 비정상 응답과 예외를 같은 fallback 경로로 정리.
3. UI 빈 상태 보강: 외부 API 실패와 캐시 부재 설명 문구 적용.
4. 테스트 추가: fallback payload가 카드 파서와 진단 UI에 충분한 데이터 제공 검증.
5. 문서화 및 검증: 실행 명령과 미수행 수동 QA 기록.

## MVP Scope

- Flutter 서비스와 카드 문구 변경.
- 로컬 fallback payload builder 추가.
- 단위 테스트 추가.
- 외부 API mock 서버, Supabase Edge Function 변경 제외.

## Test Plan

- `dart format`으로 변경 Dart 파일 포맷.
- `flutter test test/external_api_fallback_test.dart`.
- `flutter test test/market_data_service_test.dart`.
- `flutter analyze`.
- `git diff --check`.

## Risks And Decisions

- local fallback은 최신 투자 판단 아님. `fallback-local` 메타와 불확실성 문구 명시.
- fallback payload는 캐시 저장 안 함. 실제 원격 성공 데이터 오염 방지.
- 종목 뉴스 fallback은 표시 가능 주식/코인 보유 심볼 최대 5개만 생성.

## Feasibility And Feedback

- 기존 서비스 cache helper와 카드 파서 재사용. 변경 범위 작음.
- 원격 Edge Function 계약 불변. 배포 리스크 낮음.
- 수동 발표 화면 확인은 별도 QA 필요. 자동 테스트로 빈 payload 회귀 고정 가능.