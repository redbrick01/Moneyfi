# Benchmark And Risk-Adjusted Performance Plan

이 문서는 MONEYFY의 `투자성과 분석`에 벤치마크 비교와 위험조정 성과 지표를 추가하기 위한 상위 계획서입니다.

세부 구현은 작업 단위별 문서로 분리합니다.

## Goal

사용자가 단순 손익 금액뿐 아니라 아래 질문에 답할 수 있게 합니다.

1. 같은 기간 시장보다 잘했는가?
2. 수익이 변동성 대비 괜찮았는가?
3. 가장 깊게 빠진 구간은 어느 정도였는가?
4. 입금/출금 때문에 수익률이 왜곡되지 않았는가?

## Scope

1차 목표는 `투자성과 분석` 안에 고급 성과 섹션을 추가하는 것입니다.

포함:

- 현금흐름 보정 기간 수익률
- 벤치마크 누적 수익률
- 초과수익률
- 변동성
- Sharpe Ratio
- 최대 낙폭
- 데이터 부족 상태

제외:

- 외부 API 자동 연동
- 모든 벤치마크 실데이터 백필
- Supabase 원격 적용 즉시 진행
- 투자 조언성 문구

## Current Baseline

| 영역 | 현재 상태 |
| --- | --- |
| 화면 | `lib/pages/investment_performance_page.dart` |
| 대표 성과 | 순 투자성과 |
| 수익률 | 매수 원금 대비 순 투자성과율 |
| 실현손익 | 원장 `realized_pnl` 기반 |
| 미실현손익 | 기간 시작 전 최신 스냅샷 대비 현재 평가손익 변화 |
| 현금흐름 | 외부 입출금, 매매 결제, 내부 이동 분리 |
| 통화 | 화면 집계 시 KRW 기준 환산 |

현재 구조는 금액 중심 성과에는 충분하지만, Sharpe Ratio와 벤치마크 비교에는 `일별 수익률 시계열`이 추가로 필요합니다.

## Implementation Parts

| Part | 문서 | 목적 |
| --- | --- | --- |
| 01 | [Calculation Contract](plan_parts/01_calculation_contract.md) | 수익률, Sharpe, 변동성, MDD 계산식 고정 |
| 02 | [Derived Daily Returns](plan_parts/02_derived_daily_returns.md) | 분석용 일별 수익률 파생 테이블 설계 |
| 03 | [Benchmark Data](plan_parts/03_benchmark_data.md) | 벤치마크 가격 데이터 구조와 비교 규칙 |
| 04 | [UI Integration](plan_parts/04_ui_integration.md) | 투자성과 분석 화면 연결 방식 |
| 05 | [Supabase And Sync Safety](plan_parts/05_supabase_and_sync_safety.md) | 원격 적용 전 안전장치 |
| 06 | [Rollout Plan](plan_parts/06_rollout_plan.md) | 구현 순서와 릴리즈 게이트 |
| 07 | [Benchmark API And Dual Comparison](plan_parts/07_benchmark_api_and_dual_comparison.md) | 기간 양끝 비교와 일별 시계열 비교를 분리하고 API 연동 계획 수립 |
| 08 | [Yahoo IRX Risk-Free Rate](plan_parts/08_yahoo_irx_risk_free_rate.md) | Yahoo `^IRX`로 무위험수익률 proxy를 가져와 Sharpe Ratio에 반영 |

## Recommended Sequence

1. 계산 순수 함수와 fixture 테스트를 먼저 구현합니다.
2. 로컬 분석용 파생 테이블을 추가합니다.
3. 고급 성과 섹션의 데이터 부족 UI skeleton을 먼저 붙입니다.
4. 벤치마크 가격 테이블과 fixture 데이터를 추가합니다.
5. 전체 고급 성과 UI를 연결합니다.
6. 로컬 검증이 끝난 뒤 Supabase 적용 여부를 별도 판단합니다.
7. 벤치마크 API를 연결하고 기본 기간 비교와 고급 일별 비교를 분리합니다.
8. Yahoo `^IRX` 무위험수익률 proxy를 Sharpe Ratio에 반영합니다.

## Safety Principle

이 기능은 원본 데이터를 수정하지 않습니다.

금지:

- `assets`, `holdings`, `transaction_events`, `transaction_lines` 보정 업데이트
- Supabase sync 중 빈 배열 또는 0 값으로 보유자산 overwrite
- 벤치마크 계산 실패를 기존 투자성과 화면 전체 실패로 전파

허용:

- 분석용 파생 테이블 생성
- 파생 테이블 재계산
- 데이터 부족 상태 표시

## Verification

검증 계획은 [verification_test_plan.md](verification_test_plan.md)를 따릅니다.

핵심 게이트:

- 입금/출금이 수익률로 잡히지 않음
- 매수/매도 결제는 외부 현금흐름에 포함하지 않음
- Sharpe, 변동성, MDD 계산 테스트 통과
- 파생 데이터 생성 중 기존 보유자산 불변
- Supabase 원격 적용 전 destructive write 없음
