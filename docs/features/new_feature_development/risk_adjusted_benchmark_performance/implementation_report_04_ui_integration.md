# Implementation Report 04. UI Integration

## Summary

`04 UI Integration` 범위로 `투자성과 분석` 화면에 고급 성과 섹션을 추가했습니다.

기존 금액 중심 성과 카드는 유지하고, 새 섹션에서는 입출금 보정 기간 수익률, 벤치마크, 초과수익률, 변동성, Sharpe Ratio, 최대 낙폭을 별도로 표시합니다. 데이터가 부족한 항목은 `데이터 부족`으로 표시합니다.

## Implemented Files

| 파일 | 내용 |
| --- | --- |
| `lib/pages/investment_performance_page.dart` | 고급 성과 카드, 지표 설명, 파생 수익률/벤치마크 데이터 연결 |
| `test/page_walkthrough_test.dart` | 고급 지표 설명 표시 widget test 추가 |

## UI Behavior

추가된 섹션:

- `고급 성과`
- `입출금 보정 기간 수익률`
- `벤치마크`
- `초과수익률`
- `변동성`
- `Sharpe Ratio`
- `최대 낙폭`

각 지표에는 사용자가 의미를 이해할 수 있도록 1-2줄 설명을 함께 표시합니다.

## Calculation Connection

화면 로딩 시:

1. 현재 기간 기준으로 `rebuildPortfolioDailyReturns`를 실행합니다.
2. `portfolio_daily_returns`에서 일별 수익률을 조회합니다.
3. 일별 수익률로 기간 수익률, 변동성, Sharpe Ratio를 계산합니다.
4. 포트폴리오 가치 시계열로 최대 낙폭을 계산합니다.
5. 기본 벤치마크 `SP500`과 공통 날짜 기준 비교를 수행합니다.

## Data States

| 상태 | 표시 |
| --- | --- |
| 파생 일별 수익률 없음 | 해당 지표 `데이터 부족` |
| 벤치마크 데이터 없음 | 벤치마크/초과수익률 `데이터 부족` |
| 20거래일 미만 | 변동성 `데이터 부족` |
| 60거래일 미만 | Sharpe Ratio `데이터 부족` |
| 최대 낙폭 계산 불가 | 최대 낙폭 `데이터 부족` |

## Label Separation

기존 `순 투자성과` 카드의 퍼센트는 `매수 원금 대비`입니다.

새 고급 성과 섹션의 퍼센트는 `입출금 보정 기간 수익률`입니다.

두 지표가 같은 `수익률`로 보이지 않도록 라벨을 분리했습니다.

## Safety Notes

- 기존 `assets`, `holdings`, `transaction_events`, `transaction_lines`는 수정하지 않습니다.
- 화면 로딩 중 쓰기 대상은 `portfolio_daily_returns` 파생 테이블에 한정됩니다.
- 벤치마크 데이터가 없어도 기존 투자성과 금액 카드와 다른 분석 섹션은 유지됩니다.

## Test Coverage

추가 테스트:

- 투자성과 분석 화면에 `고급 성과` 섹션이 표시되는지 확인
- `입출금 보정 기간 수익률` 라벨 표시 확인
- 벤치마크/Sharpe Ratio 설명 문구 표시 확인

## Verification

실행한 명령:

```bash
flutter analyze lib/pages/investment_performance_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart
flutter test test/widget_test.dart
flutter test test/portfolio_daily_returns_test.dart test/benchmark_data_test.dart
git diff --check
```

결과:

- 투자성과 화면 walkthrough/widget 테스트 통과
- 기존 widget test 통과
- 02 파생 수익률 테스트 통과
- 03 벤치마크 데이터 테스트 통과
- 관련 정적 분석 통과
- whitespace check 통과

## Out Of Scope

이번 단계에서 제외한 항목:

- 사용자가 벤치마크를 선택하는 UI
- 실제 벤치마크 seed 데이터 제공
- 외부 API 자동 연동
- Supabase migration 또는 sync payload 확장
- 고급 성과 차트
