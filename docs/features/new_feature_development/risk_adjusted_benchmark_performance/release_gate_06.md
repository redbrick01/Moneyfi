# Release Gate 06 - Benchmark And Risk-Adjusted Performance

## Status

로컬 기능 구현은 릴리즈 후보 상태입니다. Supabase 원격 적용은 2026-05-29에 완료했습니다.

## Completed Gates

| Gate | Status | Evidence |
| --- | --- | --- |
| 계산 순수 함수 | Complete | `risk_adjusted_performance_calculator_test.dart` |
| 일별 수익률 파생 테이블 | Complete | `portfolio_daily_returns_test.dart` |
| 파생 생성 중 원본 불변 | Complete | `rebuild does not mutate source portfolio tables` |
| 벤치마크 가격/비교 기반 | Complete | `benchmark_data_test.dart` |
| 데이터 부족 UI | Complete | `page_walkthrough_test.dart` |
| 지표별 1-2줄 설명 | Complete | `investment_performance_page.dart`, `page_walkthrough_test.dart` |
| 동기화 payload 분리 | Complete | `core sync payload excludes derived analysis tables` |
| 원격 SQL destructive write 방지 | Complete | `risk_adjusted_remote_schema_draft_test.dart` |

## Remote Apply Result

원격 적용 결과:

- `portfolio_daily_returns`, `benchmark_prices` 테이블 생성 완료
- 두 테이블 RLS 활성화 완료
- `authenticated` role grant 적용 완료
- 원본 `assets`, `holdings`, `transaction_events`, `transaction_lines` 보정 update/delete 없음
- 적용 전후 `assets` row count, `holdings` row count, 수량 합계, 매수원금 합계, 평균단가/환율 zero 분포 유지 확인
- 적용 전후 평가액 합계는 가격 데이터 변화로 보이는 차이가 있어 별도 기록

## Rollout Order

1. 로컬 앱 릴리즈 후보 빌드에서 투자성과 분석 화면을 확인합니다.
2. 고급 성과 섹션이 데이터 부족 상태에서도 기존 금액 성과를 깨지 않는지 확인합니다.
3. 벤치마크 가격 데이터가 없는 사용자에게 `데이터 부족`이 표시되는지 확인합니다.
4. 원격 벤치마크 데이터 seed/admin 경로는 별도 기능으로 분리합니다.

## User-Facing Notes

- 기존 투자성과 금액은 그대로 유지됩니다.
- 새 고급 성과는 입금/출금 영향을 제거한 기간 수익률, 벤치마크 비교, 변동성, Sharpe Ratio, 최대 낙폭을 보여줍니다.
- 데이터가 부족하면 0으로 대체하지 않고 `데이터 부족`으로 표시합니다.
- Sharpe Ratio와 벤치마크는 사용자가 의미를 이해할 수 있도록 짧은 설명을 함께 보여줍니다.
