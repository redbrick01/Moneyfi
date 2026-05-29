# 05 Supabase And Sync Safety

## Purpose

Supabase 적용은 로컬 계산과 UI 검증이 끝난 뒤 진행합니다. 이 기능은 기존 사용자 자산을 건드리지 않는 것이 최우선입니다.

## Remote Scope

원격 적용 후보:

- `portfolio_daily_returns`
- `benchmark_prices`

원격 적용 제외:

- 기존 자산 보정
- 기존 보유자산 평단 보정
- 기존 원장 재계산

## Migration Rule

허용:

- 새 테이블 생성
- 새 인덱스 생성
- RLS policy 추가

금지:

- 원본 테이블 `update`
- 원본 테이블 `delete`
- 원본 테이블 `truncate`
- 원본 테이블 기본값을 0으로 채우는 보정

## Sync Rule

Edge Function은 파생 분석 데이터와 원본 포트폴리오 데이터를 분리해야 합니다.

방어:

- 파생 데이터 sync 실패가 원본 sync 실패로 번지지 않게 분리
- 빈 파생 데이터가 원본 holdings를 overwrite하지 않게 payload 분리
- 원본 자산 write 경로는 기존 검증 유지

## Preflight Checklist

원격 적용 전 확인:

- 로컬 테스트 통과
- 원격 SQL에 원본 테이블 destructive write 없음
- rollback SQL 준비
- Supabase 적용 전 현재 row count 확인
- 적용 전후 기존 assets/holdings row count 변화 없음 확인
- 적용 전후 holdings quantity 합계 변화 없음 확인
- 적용 전후 holdings valuation 합계 변화 없음 확인
- 적용 전후 holdings purchase amount 합계 변화 없음 확인
- 적용 전후 원화 평균단가, 원통화 평균단가, 평균 환율의 null/zero 급증 없음 확인

Row count만으로는 보유자산 0 밀림을 잡을 수 없습니다. row는 그대로인데 `quantity`, `average_price`, `valuation`만 0이 되는 사고를 막기 위해 핵심 합계와 null/zero 분포를 함께 비교합니다.

## Rollback

1차 rollback은 새 파생 테이블 제거 또는 비활성화 중심입니다.

원칙:

- 원본 자산 데이터 rollback이 필요 없는 구조로 만든다.
- 문제가 생기면 고급 성과 섹션만 숨길 수 있어야 한다.
- 기존 투자성과 금액 화면은 계속 동작해야 한다.
