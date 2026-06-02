# Benchmark And Risk-Adjusted Performance Plan

MONEYFY `투자성과 분석`에 벤치마크 비교, 위험조정 성과 지표 추가 상위 계획.

세부 구현은 작업 단위 문서로 분리.

## Goal

사용자, 단순 손익 금액 말고 아래 질문 답 가능.

1. 같은 기간 시장보다 잘했나?
2. 수익, 변동성 대비 괜찮나?
3. 최대 하락 구간 얼마나 깊었나?
4. 입금/출금 때문에 수익률 왜곡 없나?

## Scope

1차 목표: `투자성과 분석` 안 고급 성과 섹션 추가.

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

현재 구조, 금액 중심 성과 충분. Sharpe Ratio, 벤치마크 비교엔 `일별 수익률 시계열` 필요.

## Implementation Parts

| Part | 문서 | 목적 |
| --- | --- | --- |
| 01 | Calculation Contract | 수익률, Sharpe, 변동성, MDD 계산식 고정 |
| 02 | Derived Daily Returns | 분석용 일별 수익률 파생 테이블 설계 |
| 03 | Benchmark Data | 벤치마크 가격 데이터 구조와 비교 규칙 |
| 04 | UI Integration | 투자성과 분석 화면 연결 방식 |
| 05 | Supabase And Sync Safety | 원격 적용 전 안전장치 |
| 06 | Rollout Plan | 구현 순서와 릴리즈 게이트 |
| 07 | Benchmark API And Dual Comparison | 기간 양끝 비교와 일별 시계열 비교 분리, API 연동 계획 |
| 08 | Yahoo IRX Risk-Free Rate | Yahoo `^IRX`로 무위험수익률 proxy 가져와 Sharpe Ratio 반영 |

## Recommended Sequence

1. 계산 순수 함수와 fixture 테스트 먼저 구현.
2. 로컬 분석용 파생 테이블 추가.
3. 고급 성과 섹션 데이터 부족 UI skeleton 먼저 연결.
4. 벤치마크 가격 테이블과 fixture 데이터 추가.
5. 전체 고급 성과 UI 연결.
6. 로컬 검증 뒤 Supabase 적용 여부 별도 판단.
7. 벤치마크 API 연결, 기본 기간 비교와 고급 일별 비교 분리.
8. Yahoo `^IRX` 무위험수익률 proxy를 Sharpe Ratio에 반영.

## Safety Principle

이 기능, 원본 데이터 수정 없음.

금지:

- `assets`, `holdings`, `transaction_events`, `transaction_lines` 보정 업데이트
- Supabase sync 중 빈 배열 또는 0 값으로 보유자산 overwrite
- 벤치마크 계산 실패를 기존 투자성과 화면 전체 실패로 전파

허용:

- 분석용 파생 테이블 생성
- 파생 테이블 재계산
- 데이터 부족 상태 표시

## Verification

검증 계획은 verification notes in this plan 따름.

핵심 게이트:

- 입금/출금이 수익률로 잡히지 않음
- 매수/매도 결제는 외부 현금흐름에 포함하지 않음
- Sharpe, 변동성, MDD 계산 테스트 통과
- 파생 데이터 생성 중 기존 보유자산 불변
- Supabase 원격 적용 전 destructive write 없음

## 세부 문서 병합 요약

### 핵심 계획

- calculation contract는 daily portfolio value, cash-flow adjusted daily return, cumulative return, volatility, Sharpe Ratio, max drawdown을 순수 함수와 fixture로 고정.
- derived daily returns는 분석용 파생 테이블 사용, snapshot gap rule과 recalculation failure behavior 명시.
- benchmark data는 초기 benchmark set, return rule, comparison rule, provider strategy 분리.
- UI integration은 고급 성과 요약, rate label separation, 데이터 부족 상태, copy rule 우선 연결.
- Supabase/sync safety는 remote scope, migration rule, sync rule, rollback preflight 별도 gate.
- rollout은 calculation only -> local derived data -> UI skeleton -> benchmark foundation -> full UI -> Supabase review 순서.
- API 확장은 기본 기간 비교와 고급 일별 비교 분리, Yahoo `^IRX`를 risk-free proxy로 Sharpe Ratio 반영.

### 구현 결과

- 01-08 implementation report로 calculation contract, derived returns, benchmark data, UI integration, Supabase safety, rollout gate, benchmark API, Yahoo IRX 단계별 완료.
- release gate 06은 benchmark/risk-adjusted performance 적용 상태, remote apply result, rollout order, user-facing note 정리.
- benchmark API provider는 UI 기본 비교와 고급 계산용 일별 series 요구사항 분리 방향 결정.

### 검증 핵심

- 입출금은 수익률로 잡지 않음. 매수/매도 결제는 외부 현금흐름으로 처리하지 않음.
- benchmark 누락, USD 중심 포트폴리오, 데이터 부족 기간을 manual QA scenario로 확인.
- 파생 데이터 생성 중 `assets`, `holdings`, `transaction_events`, `transaction_lines` 보정 업데이트 없음.
- remote 적용 전 destructive write, 빈 sync payload, 기존 투자성과 화면 전체 실패 전파 차단.