# 06 Rollout Plan

## Phase 1. Calculation Only

작업:

- 수익률 계산 순수 함수 추가
- 누적 수익률 함수 추가
- 변동성, Sharpe, MDD 함수 추가
- fixture 테스트 추가

완료 기준:

- 입금/출금 보정 테스트 통과
- Sharpe/MDD 계산 테스트 통과
- UI/DB 변경 없음

## Phase 2. Local Derived Data

작업:

- 로컬 `portfolio_daily_returns` 테이블 추가
- 스냅샷/원장 기반 파생 생성기 추가
- 원본 테이블 불변 테스트 추가

완료 기준:

- 파생 데이터 생성 후 holdings 불변
- 스냅샷 부족 시 데이터 부족

## Phase 3. UI Data-Insufficient Skeleton

작업:

- 고급 성과 섹션 skeleton 추가
- 파생 데이터 없음 상태 표시
- 기존 금액 성과 카드와 라벨 충돌 제거

완료 기준:

- 벤치마크/파생 데이터가 없어도 화면이 깨지지 않음
- `매수 원금 대비`와 `입출금 보정 기간 수익률` 라벨이 분리됨

## Phase 4. Benchmark Foundation

작업:

- 로컬 `benchmark_prices` 테이블 추가
- fixture 또는 seed 데이터 추가
- 공통 날짜 비교 테스트 추가

완료 기준:

- 벤치마크 없음 상태 처리
- KRW/USD 벤치마크 비교 규칙 고정

## Phase 5. Full UI Integration

작업:

- 고급 성과 요약 카드 추가
- 벤치마크 비교 섹션 추가
- 위험조정 지표 섹션 추가

완료 기준:

- 기존 투자성과 금액 카드 유지
- 데이터 부족 상태 표시
- widget test 통과

## Phase 6. Supabase Review

작업:

- 원격 migration 초안 작성
- sync payload 분리 검토
- rollback 문서 작성

완료 기준:

- destructive write 없음
- 기존 자산 row count 불변 검증 가능
- 기존 holdings 핵심 합계 불변 검증 가능
- 사용자 승인 후 원격 적용

## Release Gate

아래 조건을 모두 만족해야 다음 단계로 넘어갑니다.

- `flutter test test/widget_test.dart`
- `flutter test test/transaction_flow_test.dart`
- `flutter analyze lib/pages/investment_performance_page.dart`
- `git diff --check`
- 파생 갱신 중 기존 assets/holdings 불변 테스트
- Supabase 적용 전 SQL 리뷰 완료
