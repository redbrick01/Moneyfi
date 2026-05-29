# 02 Derived Daily Returns

## Purpose

Sharpe Ratio와 벤치마크 비교는 일별 수익률 시계열이 필요합니다. 이 값은 원본 테이블을 수정하지 않고 분석용 파생 테이블에 저장합니다.

## Recommended Table

```sql
create table portfolio_daily_returns (
  id integer primary key,
  local_user_id text not null,
  return_date text not null,
  beginning_value_krw real,
  ending_value_krw real not null,
  portfolio_value_krw real not null,
  external_cash_flow_krw real not null default 0,
  daily_return real,
  data_quality text not null default 'complete',
  calculation_version integer not null default 1,
  created_at text not null,
  updated_at text not null,
  unique(local_user_id, return_date)
);
```

필드 원칙:

| 필드 | 의미 |
| --- | --- |
| `beginning_value_krw` | 전일 종료 포트폴리오 가치 |
| `ending_value_krw` | 당일 종료 포트폴리오 가치 |
| `portfolio_value_krw` | 화면 호환용 당일 포트폴리오 가치. `ending_value_krw`와 동일 |
| `external_cash_flow_krw` | 해당 일자의 외부 입출금 순액 |
| `daily_return` | 현금흐름 보정 일별 수익률 |
| `data_quality` | `complete`, `missing_snapshot`, `carried_forward`, `missing_fx` |
| `calculation_version` | 계산식 변경 시 재생성 판단용 버전 |

## Source Data

| 데이터 | 용도 |
| --- | --- |
| portfolio snapshots | 일별 포트폴리오 가치 |
| transaction ledger | 외부 입금/출금 계산 |
| exchange rates | USD 자산 KRW 환산 |

## Snapshot Gap Rule

일별 스냅샷이 없을 수 있으므로 누락 처리 기준을 명확히 둡니다.

| 상황 | 처리 |
| --- | --- |
| 전일/당일 스냅샷 모두 있음 | `complete` |
| 당일 스냅샷 없음 | 해당 일자 수익률 생성하지 않음 |
| 전일 스냅샷 없음 | `daily_return = null`, `data_quality = missing_snapshot` |
| 환율 없음 | 가장 가까운 이전 환율 사용 후 `data_quality = missing_fx` |
| 직전 스냅샷을 carry-forward한 경우 | `data_quality = carried_forward` |

1차 구현에서는 누락 일자를 억지로 보간하지 않습니다. 계산 가능한 날짜만 만들고, 관측치가 부족하면 UI에서 `데이터 부족`으로 표시합니다.

## Update Rule

파생 테이블은 재계산 가능해야 합니다.

허용:

- `portfolio_daily_returns` upsert
- 특정 기간 파생 row 삭제 후 재생성

금지:

- `assets` 업데이트
- `holdings` 업데이트
- `transaction_events` 업데이트
- `transaction_lines` 업데이트

## Failure Behavior

파생 데이터 생성 실패 시 기존 화면은 기존 금액 성과를 그대로 보여줘야 합니다.

표시 원칙:

- 파생 데이터 없음: `데이터 부족`
- 일부 날짜 누락: 계산 가능한 공통 날짜만 사용
- 스냅샷 부족: 수익률/Sharpe/MDD 숨김

## Required Tests

| 테스트 | 목적 |
| --- | --- |
| `derived_update_does_not_mutate_assets` | 원본 자산 불변 |
| `derived_update_does_not_mutate_holdings` | 보유 수량/평단 불변 |
| `derived_update_does_not_mutate_transaction_lines` | 원장 불변 |
| `missing_snapshot_marks_insufficient_data` | 0 표시 대신 데이터 부족 |
| `derived_row_keeps_beginning_and_ending_values` | 수익률 근거값 추적 가능 |
| `derived_row_marks_data_quality` | 누락/환율 fallback 상태 기록 |
