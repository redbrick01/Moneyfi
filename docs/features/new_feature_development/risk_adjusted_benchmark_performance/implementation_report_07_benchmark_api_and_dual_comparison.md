# Implementation Report 07 - Benchmark API And Dual Comparison

## Summary

벤치마크 비교를 사용자 기대에 맞게 기간 양끝 비교로 전환하고, SP500 가격을 API로 가져와 로컬 `benchmark_prices`에 캐시하는 1차 구현을 추가했다.

기존 일별 공통 날짜 비교는 제거하지 않고 고급 시계열 비교용 API로 유지했다.

## Implemented

- `BenchmarkPeriodComparisonResult`를 추가했다.
- `compareBenchmarkPeriodReturn(...)`을 추가해 선택 기간의 벤치마크 시작값/끝값으로 기간 수익률을 계산한다.
- `compareBenchmarkToPortfolioReturns(...)`는 기존 일별 공통 날짜 비교용으로 유지했다.
- `BenchmarkPriceService`를 추가했다.
- SP500은 Yahoo Finance chart endpoint의 `^GSPC` 가격을 가져와 로컬 `benchmark_prices`에 저장한다.
- 투자성과 분석 화면의 `벤치마크`, `초과수익률`은 기간 양끝 비교 결과를 사용하도록 변경했다.
- 일별 공통 관측치가 20개 미만이어도 양끝 벤치마크 가격과 포트폴리오 기간 수익률이 있으면 기본 벤치마크/초과수익률은 표시될 수 있다.

## Provider Decision

Stooq CSV endpoint도 검토했으나 현재 CSV 다운로드 응답이 apikey/captcha 안내로 떨어졌다. 그래서 1차 구현은 User-Agent를 포함한 Yahoo Finance chart endpoint를 사용한다.

Yahoo endpoint는 공식 보장 API가 아니므로 실패할 수 있다. 실패 시 기존 cache만 사용하고, cache도 부족하면 UI는 `데이터 부족`을 표시한다.

## User-Facing Behavior

- 벤치마크 기간 수익률: 선택한 기간의 시작값과 끝값으로 계산한다.
- 초과수익률: 포트폴리오 입출금 보정 기간 수익률에서 벤치마크 기간 수익률을 뺀 값이다.
- Sharpe Ratio: 기존처럼 포트폴리오 일별 수익률 60개 이상이 필요하다.
- API 실패는 투자성과 금액 카드 전체 실패로 전파하지 않고, 벤치마크 항목만 cache/데이터 부족 상태로 처리한다.

## Safety Notes

- API fetch는 `benchmark_prices`만 갱신한다.
- `assets`, `holdings`, `transaction_events`, `transaction_lines`는 변경하지 않는다.
- Supabase remote `benchmark_prices` 자동 seed/sync는 아직 연결하지 않았다.

## Verification

- `flutter analyze lib/services/benchmark_price_service.dart lib/db/app_database.dart lib/db/app_database_records.dart lib/pages/investment_performance_page.dart test/benchmark_data_test.dart test/market_data_service_test.dart test/page_walkthrough_test.dart`
- `flutter test test/benchmark_data_test.dart test/market_data_service_test.dart test/page_walkthrough_test.dart`
- `flutter test test/widget_test.dart test/transaction_flow_test.dart`
- `git diff --check`
- Manual smoke: Yahoo chart endpoint responded with SP500 JSON when `User-Agent: Mozilla/5.0` was included.
