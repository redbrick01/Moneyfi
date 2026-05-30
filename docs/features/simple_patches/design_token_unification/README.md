# Design Token Unification Docs

작성일: 2026-05-29

## Purpose

MONEYFY 앱의 색상, 폰트, 여백, 간격, 반경, 상태 표현을 공통 디자인 시스템 기준으로 통일하기 위한 최종 계획서 목록입니다.

구현자는 이 문서를 시작점으로 보고, 아래 순서대로 계획서와 검증 문서를 확인합니다.

## Final Plan List

| 순서 | 문서 | 역할 |
| ---: | --- | --- |
| 1 | [Main Plan](plan.md) | 전체 목표, non-goal, canonical replacement rule, batch 순서 |
| 2 | [Coverage Matrix](plan_parts/00_coverage_matrix.md) | 전체 UI-bearing Dart file과 native/web visual asset stage 배정 |
| 3 | [Pre-Implementation Check](pre_implementation_check_20260529.md) | 구현 전 최종 점검, legacy 패턴 수치, 첫 batch 범위 |
| 4 | [Verification Test Plan](verification_test_plan.md) | batch별 analyzer/test/manual QA 기준 |
| 5 | [Batch 02A Test Report](test_report_20260529_batch_02a.md) | 첫 구현 batch 변경/검증 결과 |
| 6 | [Batch 02C-1 Test Report](test_report_20260529_batch_02c_1.md) | chips/states/status/header batch 변경/검증 결과 |
| 7 | [Batch 02C-2 Test Report](test_report_20260529_batch_02c_2.md) | buttons/section shell batch 변경/검증 결과 |
| 8 | [Batch 02D Test Report](test_report_20260529_batch_02d.md) | ui_scaffold, icon, feedback, expandable batch 변경/검증 결과 |
| 9 | [Batch 02B Test Report](test_report_20260529_batch_02b.md) | moneyfy_ui compatibility layer 변경/검증 결과 |
| 10 | [Stage 03A Test Report](test_report_20260529_stage_03a.md) | 뉴스 요약 카드 batch 변경/검증 결과 |
| 11 | [Stage 03B Test Report](test_report_20260529_stage_03b.md) | analysis entry 영역 batch 변경/검증 결과 |
| 12 | [Stage 04A Test Report](test_report_20260529_stage_04a.md) | analysis 하단 카드 batch 변경/검증 결과 |
| 13 | [Stage 04B Test Report](test_report_20260529_stage_04b.md) | 투자성과/배당이자 분석 batch 변경/검증 결과 |
| 14 | [Stage 04C Test Report](test_report_20260529_stage_04c.md) | 연도별 자산분석 batch 변경/검증 결과 |
| 15 | [Stage 04D Test Report](test_report_20260529_stage_04d.md) | 포트폴리오 진단 MVP batch 변경/검증 결과 |
| 16 | [Stage 05A Test Report](test_report_20260529_stage_05a.md) | 자산 상세 화면 batch 변경/검증 결과 |
| 17 | [Stage 05B Test Report](test_report_20260529_stage_05b.md) | 보유 종목/현금 계좌 상세 화면 batch 변경/검증 결과 |
| 18 | [Stage 05C Test Report](test_report_20260529_stage_05c.md) | 입력 폼 계열 batch 변경/검증 결과 |
| 19 | [Stage 05D Test Report](test_report_20260529_stage_05d.md) | 거래 입력 폼 계열 batch 변경/검증 결과 |
| 20 | [Stage 05E Test Report](test_report_20260529_stage_05e.md) | 상세/폼 보조 UI 잔여 정리 및 Stage 05 재검증 결과 |
| 21 | [Stage 06A Test Report](test_report_20260529_stage_06a.md) | app shell/navigation/sync overlay batch 변경/검증 결과 |
| 22 | [Stage 06B Test Report](test_report_20260529_stage_06b.md) | portfolio/transaction/statistics 계열 batch 변경/검증 결과 |
| 23 | [Stage 06C Test Report](test_report_20260529_stage_06c.md) | auth/my 계열 및 progress indicator token batch 변경/검증 결과 |
| 24 | [Stage 06D Test Report](test_report_20260529_stage_06d.md) | brand/native/web asset consistency audit 변경/검증 결과 |
| 25 | [Stage 07 Test Report](test_report_20260529_stage_07.md) | legacy token retirement policy 및 reporting-only guardrail 변경/검증 결과 |
| 26 | [Stage 07 Follow-up Test Report](test_report_20260529_stage_07_followup.md) | snapshot detail holdout 및 transparent token cleanup 검증 결과 |
| 27 | [Pill, Chip, Badge Token Report](test_report_20260530_pill_chip_badge_tokens.md) | pill/chip/badge 공통 resolver와 compact label UI 토큰화 검증 결과 |

## Stage Plans

| Stage | 문서 | 구현 범위 |
| ---: | --- | --- |
| 00 | [Coverage Matrix](plan_parts/00_coverage_matrix.md) | 전체 UI 파일과 visual asset 누락 여부 확인 |
| 01 | [Audit And Guardrails](plan_parts/01_audit_and_guardrails.md) | legacy 패턴 수치화, 예외 기준, soft/hard guardrail |
| 02 | [Component Layer](plan_parts/02_component_layer.md) | 공용 rows, metrics, buttons, chips, states, scaffold |
| 03 | [News And Analysis Cards](plan_parts/03_news_and_analysis_cards.md) | 회사/시장 뉴스 카드와 분석 entry 영역 |
| 04 | [Analysis Page Family](plan_parts/04_analysis_page_family.md) | 자산 분석, 포트폴리오 분석, 투자 성과, 배당/이자 분석 |
| 05 | [Detail And Form Pages](plan_parts/05_detail_and_form_pages.md) | 상세 화면, 입력 폼, sheet, CTA |
| 06 | [Remaining App Surfaces](plan_parts/06_remaining_app_surfaces.md) | app shell, auth, my, portfolio, transaction, statistics, sync overlay, brand asset audit |
| 07 | [Legacy Token Retirement](plan_parts/07_legacy_token_retirement.md) | legacy token 축소, compatibility policy, CI guardrail 후보 |

## Implementation Start Point

첫 구현은 Stage 02 전체가 아니라 Batch 02A로 제한합니다.

Start files:

- `lib/components/transaction_history_list.dart`
- `lib/components/rows/snapshot_row.dart`
- `lib/components/rows/rebalance_row.dart`
- `lib/components/rows/allocation_legend_row.dart`
- `lib/components/metrics/metric_header.dart`
- `lib/components/metrics/metric_row.dart`

Do not start with:

- `lib/widgets/moneyfy_ui.dart`
- page-level files
- theme bridge files
- chart-heavy analysis pages
- form pages

## Required First-Batch Verification

```bash
flutter analyze lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

## Operating Rules

- 사용자-facing 레이아웃 리디자인은 하지 않습니다.
- 계산, DB, sync, auth, route 동작은 변경하지 않습니다.
- chart/canvas geometry는 예외로 두고 문서화합니다.
- 새 legacy pattern을 추가하지 않습니다.
- batch마다 제거한 legacy pattern과 남긴 예외를 test report에 기록합니다.
