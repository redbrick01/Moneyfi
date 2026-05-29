# USD Realized PnL Currency Basis Fix Plan

## Purpose

투자 성과 화면에서 USD 매도 실현손익이 원화 평균단가를 USD 원가처럼 사용해 과대 계산되는 문제를 수정한다. 대표 사례는 SATL 매도 `285 USD`에 대해 `realized_pnl = -140,415 USD`가 저장되어 화면에 약 `-2.05억 원` 손실로 표시된 건이다.

이번 수정은 한 번에 구현하되, 리뷰와 적용은 기능 단위로 나눈다.

## Split Plan

1. [Currency Model](plan_parts/01_currency_model.md)
   - 원화 평균단가, 원통화 평균단가, 매수 평균 환율, 원장 원가 흐름의 기준을 정의한다.

2. [Existing USD Seed Data](plan_parts/02_existing_usd_seed_data.md)
   - 기존 USD 보유분은 사용자가 제공한 원통화 평균단가로만 백필한다.
   - 현재 환율이나 최신 스냅샷 환율로 원통화 평단을 추정하지 않는다.

3. [Schema And Sync](plan_parts/03_schema_and_sync.md)
   - Drift/Supabase schema, sync payload, edge functions 변경 범위를 정리한다.

4. [Trade Calculation Flow](plan_parts/04_trade_calculation_flow.md)
   - 신규 USD 매수 시 매수 당시 환율을 buy line에 저장하고, holding의 매수 평균 환율을 누적 평균으로 갱신한다.
   - USD 매도/수동 실현손익 계산 규칙도 포함한다.

5. [Remote Corrective Migration And Safety](plan_parts/05_remote_corrective_migration_and_safety.md)
   - 기존 잘못된 원격 row를 forward-only corrective migration으로 보정한다.
   - 지난번처럼 포트폴리오가 0으로 밀리는 문제를 막는 hard gate를 둔다.

6. [Verification And Rollback](plan_parts/06_verification_and_rollback.md)
   - DB/unit/widget/SQL 검증과 rollback 방식을 정리한다.

## Implementation Order

1. Schema and model fields
2. Sync and edge functions
3. Local trade calculation changes
4. Tests for USD buy/sell and manual realized PnL
5. Corrective migration with dry-run preview
6. Remote apply and post-apply verification

## Non Goals

- FIFO/LIFO 도입은 하지 않는다.
- 기존 `holdings.average_price` 컬럼을 이번에 삭제하거나 원통화 평단으로 의미 변경하지 않는다.
- 기존 전체 포트폴리오 valuation 모델을 갈아엎지 않는다.
- 사용자의 수동 실현손익 입력값을 세무 신고용 확정값으로 보증하지 않는다.
- 스냅샷 없는 과거 USD sell을 추측 보정하지 않는다.

## Current Known Bad Row

- Holding: `SATELLOGIC (SATL)`
- Sell date: `2026-05-27`
- Sell gross: `30 * 9.5 = 285 USD`
- Stored `cost_basis_delta`: `-140,700`
- Stored `realized_pnl`: `-140,415`
- Stored `realized_pnl_source`: `snapshot_anchor`

Corrective migration must fix this row without touching unrelated holdings or changing any `holdings.quantity`.
