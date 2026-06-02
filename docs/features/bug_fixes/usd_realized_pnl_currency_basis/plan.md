# USD Realized PnL Currency Basis Fix Plan

## Purpose

투자 성과 화면 USD 매도 실현손익 버그 수정. 원화 평균단가를 USD 원가처럼 써서 손익 과대 계산. 대표: SATL 매도 `285 USD`인데 `realized_pnl = -140,415 USD` 저장, 화면 약 `-2.05억 원` 손실 표시.

한 번에 구현. 리뷰/적용은 기능 단위 분리.

## Split Plan

1. Currency Model
   - 원화 평균단가, 원통화 평균단가, 매수 평균 환율, 원장 원가 흐름 기준 정의.

2. Existing USD Seed Data
   - 기존 USD 보유분은 사용자 제공 원통화 평균단가만 백필.
   - 현재 환율/최신 스냅샷 환율로 원통화 평단 추정 금지.

3. Schema And Sync
   - Drift/Supabase schema, sync payload, edge functions 변경 범위 정리.

4. Trade Calculation Flow
   - 신규 USD 매수 시 매수 환율을 buy line 저장, holding 매수 평균 환율 누적 평균 갱신.
   - USD 매도/수동 실현손익 계산 규칙 포함.

5. Remote Corrective Migration And Safety
   - 기존 오염 원격 row를 forward-only corrective migration으로 보정.
   - 포트폴리오 0 wipe 방지 hard gate 추가.

6. Verification And Rollback
   - DB/unit/widget/SQL 검증, rollback 방식 정리.

## Implementation Order

1. Schema and model fields
2. Sync and edge functions
3. Local trade calculation changes
4. Tests for USD buy/sell and manual realized PnL
5. Corrective migration with dry-run preview
6. Remote apply and post-apply verification

## Non Goals

- FIFO/LIFO 도입 안 함.
- 기존 `holdings.average_price` 컬럼 삭제/원통화 평단 의미 변경 안 함.
- 기존 전체 포트폴리오 valuation 모델 교체 안 함.
- 사용자 수동 실현손익 입력값을 세무 신고 확정값으로 보증 안 함.
- 스냅샷 없는 과거 USD sell 추측 보정 안 함.

## Current Known Bad Row

- Holding: `SATELLOGIC (SATL)`
- Sell date: `2026-05-27`
- Sell gross: `30 * 9.5 = 285 USD`
- Stored `cost_basis_delta`: `-140,700`
- Stored `realized_pnl`: `-140,415`
- Stored `realized_pnl_source`: `snapshot_anchor`

Corrective migration은 이 row만 fix. unrelated holdings / `holdings.quantity` 변경 금지.

## 세부 문서 병합 요약

### 핵심 계획

- 통화 모델: `average_price`는 KRW 호환값 유지. USD 원통화 평단/원통화 원가/평균 매수 환율은 별도 필드.
- 기존 USD seed: 과거 USD 보유분은 seed 기준 source cost, KRW cost 역산. seed 매칭 실패 row 추측 보정 금지.
- schema/sync: local Drift, Supabase, sync payload, Edge Function contract 같은 방향 확장. destructive overwrite / 빈 배열 sync gate.
- 거래 계산: USD buy는 체결 환율을 buy line 저장, source/KRW cost 동시 누적. USD sell은 source realized PnL과 KRW cost basis 분리.
- 원격 보정: SATL 같은 기존 오염 row만 forward-only migration 보정. holding quantity, 무관 row 건드리지 않음.
- 검증/롤백: unit, DB, SQL, remote preflight 통과 후 적용. rollback은 새 migration/edge deploy 단위.

### 구현 결과

- currency model, existing seed data, schema/sync, trade calculation flow, remote corrective migration, verification/rollback 6단계 구현 리포트 작성.
- remote corrective migration: snapshot-anchor sell correction, seed matching, zero-wipe prevention, archive/skipped row 기록, asset metric recompute hardening 포함.
- remote apply는 2026-05-29 DB migrations와 Edge Functions 적용. SATL sell row, USD holdings seed, safety check 확인.
- operational runbook은 remote deployment order, pre/post apply check, rollback boundary 별도 절차로 보존.

### 검증 핵심

- USD manual sell은 source-currency realized PnL로 검증.
- KRW `cost_basis_delta`는 평균 KRW 평단 기준 감소. source cost는 source 평단 기준 감소.
- 수량 0 근처는 해당 holding 평균 필드만 zero 처리. broad holdings reconcile로 전체 wipe 금지.
- 원격 SQL 검증은 corrective row 수, seeded USD holdings, quantity 불변, archived/skipped rows 확인.