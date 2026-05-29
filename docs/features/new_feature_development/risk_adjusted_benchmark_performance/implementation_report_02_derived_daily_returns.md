# Implementation Report 02. Derived Daily Returns

## Summary

`02 Derived Daily Returns` 범위의 로컬 분석용 파생 테이블과 재생성 로직을 구현했습니다.

이번 단계는 기존 자산/보유/원장 데이터를 수정하지 않고, 스냅샷과 외부 현금흐름을 읽어서 `portfolio_daily_returns` 파생 row를 생성합니다.

## Implemented Files

| 파일 | 내용 |
| --- | --- |
| `lib/db/app_database_tables.dart` | `PortfolioDailyReturns` Drift 테이블 추가 |
| `lib/db/app_database.dart` | schema version 35, 테이블 ensure, 파생 수익률 재생성/조회 메서드 추가 |
| `lib/db/app_database_records.dart` | 외부 현금흐름 계산용 내부 record 추가 |
| `lib/db/app_database.g.dart` | Drift generated schema 갱신 |
| `test/portfolio_daily_returns_test.dart` | 파생 테이블, 수익률 생성, 데이터 품질, 원본 불변 테스트 추가 |

## Added API

| API | 역할 |
| --- | --- |
| `fetchPortfolioDailyReturns({localUserId, from, to})` | 생성된 일별 파생 수익률 조회 |
| `rebuildPortfolioDailyReturns({localUserId, from, to})` | 스냅샷/원장에서 파생 수익률 row 재생성 |

## Table Contract

`portfolio_daily_returns` 필드:

| 필드 | 의미 |
| --- | --- |
| `local_user_id` | 로컬 사용자 scope. MVP 기본값은 `local` |
| `return_date` | 수익률 기준일 |
| `beginning_value_krw` | 전일 종료 포트폴리오 가치 |
| `ending_value_krw` | 당일 종료 포트폴리오 가치 |
| `portfolio_value_krw` | 화면 호환용 당일 포트폴리오 가치 |
| `external_cash_flow_krw` | 외부 입출금 KRW 환산 순액 |
| `daily_return` | 현금흐름 보정 일별 수익률 |
| `data_quality` | `complete`, `missing_snapshot`, `missing_fx` |
| `calculation_version` | 계산식 버전. 현재 `1` |

## Calculation Behavior

- 당일 스냅샷의 `total_valuation_amount`를 `ending_value_krw`로 사용합니다.
- 전일 스냅샷이 있을 때만 `daily_return`을 계산합니다.
- 전일 스냅샷이 없으면 `daily_return = null`, `data_quality = missing_snapshot`으로 저장합니다.
- 외부 현금흐름은 `transaction_events.flow_category`가 `external_deposit` 또는 `external_withdrawal`인 ledger line만 사용합니다.
- 매수/매도 결제, 내부 이체, 환전은 외부 현금흐름에서 제외합니다.
- USD 외부 현금흐름은 line `fx_rate`를 우선 사용하고, 없으면 해당 일자 이전 환율 또는 최신 환율로 fallback합니다.

## Safety Decisions

- 원본 테이블은 읽기만 합니다.
- `assets`, `holdings`, `transaction_events`, `transaction_lines`에는 update/delete를 수행하지 않습니다.
- 재생성 시 삭제/삽입 대상은 `portfolio_daily_returns`에 한정합니다.
- 파생 데이터 생성 실패가 기존 투자성과 금액 계산을 변경하지 않도록 UI 연결은 아직 하지 않았습니다.

## Test Coverage

추가 테스트:

- `portfolio_daily_returns` 테이블 생성 확인
- 입금 제외 후 시장수익만 반영되는 일별 수익률 계산
- 전일 스냅샷 누락 시 `missing_snapshot` 처리
- USD 외부 현금흐름 환율 fallback KRW 환산
- 파생 재생성 후 holdings 수량/원가/평가금액 합계 불변
- 파생 재생성 후 transaction_lines row count 불변

## Verification

실행한 명령:

```bash
flutter test test/portfolio_daily_returns_test.dart
flutter test test/risk_adjusted_performance_calculator_test.dart
flutter analyze lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database_records.dart lib/utils/risk_adjusted_performance_calculator.dart test/portfolio_daily_returns_test.dart test/risk_adjusted_performance_calculator_test.dart
flutter test test/transaction_flow_test.dart
git diff --check
```

결과:

- 파생 수익률 테스트 통과
- 01 계산 계약 테스트 통과
- 관련 정적 분석 통과
- 기존 거래 흐름 회귀 테스트 통과
- whitespace check 통과

## Out Of Scope

이번 단계에서 제외한 항목:

- 벤치마크 가격 테이블
- 고급 성과 UI skeleton
- Supabase migration
- Edge Function sync payload 확장
- 외부 API 자동 연동
