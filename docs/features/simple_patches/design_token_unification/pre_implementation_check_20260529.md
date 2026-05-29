# Design Token Unification Pre-Implementation Check

점검일: 2026-05-29

## Verdict

구현 진행 가능.

단, 첫 구현 batch는 Stage 02 전체가 아니라 Batch 02A로 제한합니다. 현재 legacy 패턴이 넓게 분포되어 있어 대량 치환으로 시작하면 시각 회귀와 리뷰 부담이 커집니다.

## Coverage Check

`find lib -type f -name "*.dart"` 기준으로 UI-bearing Dart 파일은 `00_coverage_matrix.md`에 stage가 배정되어 있습니다.

확인된 보강 사항:

- shell/navigation: Stage 06
- auth/account: Stage 06
- portfolio/stat/transaction surfaces: Stage 06
- sync overlay: Stage 06
- theme bridge: Stage 07
- UI scaffold: Stage 02
- app/native/web visual assets: Stage 06 audit-only

Non-UI 파일은 token unification 대상에서 제외합니다.

## Legacy Pattern Snapshot

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib --glob "*.dart" --count-matches
```

총 legacy/design-direct pattern match: `1767`

Top concentration files:

| 파일 | match 수 | 담당 stage |
| --- | ---: | --- |
| `lib/pages/portfolio_analysis_mvp_page.dart` | 248 | Stage 04 |
| `lib/pages/holding_detail_page.dart` | 102 | Stage 05 |
| `lib/pages/portfolio_dashboard_page.dart` | 98 | Stage 06 |
| `lib/pages/forms/form_design.dart` | 90 | Stage 05 |
| `lib/widgets/market_news_summary_card.dart` | 69 | Stage 03 |
| `lib/pages/asset_detail_page.dart` | 66 | Stage 05 |
| `lib/pages/analysis_page.dart` | 58 | Stage 03/04 |
| `lib/theme/moneyfy_theme.dart` | 58 | Stage 07 |
| `lib/pages/statistics_page.dart` | 57 | Stage 06 |
| `lib/pages/snapshot_detail_page.dart` | 55 | Stage 05 |

Interpretation:

- 잔존량은 큽니다.
- 하지만 stage 배정은 되어 있으므로 구현은 작은 batch로 진행하면 됩니다.
- `lib/design_system/**`, `lib/theme/**`의 direct color/font는 canonical source 또는 bridge일 수 있어 무조건 제거 대상이 아닙니다.

## First Implementation Scope

Start with Batch 02A only:

- `lib/components/transaction_history_list.dart`
- `lib/components/rows/snapshot_row.dart`
- `lib/components/rows/rebalance_row.dart`
- `lib/components/rows/allocation_legend_row.dart`
- `lib/components/metrics/metric_header.dart`
- `lib/components/metrics/metric_row.dart`

Do not include in the first implementation batch:

- `lib/widgets/moneyfy_ui.dart`
- page-level files
- theme bridge files
- chart-heavy analysis pages
- form pages

## Implementation Rules

- No user-facing redesign in token unification batches.
- No route, DB, sync, calculation, auth behavior changes.
- Preserve public constructors unless a local callsite-only change is safer and documented.
- Leave chart/canvas geometry alone unless the value is clearly card/spacing/typography.
- Record intentional exceptions in the test report.

## Required Verification For Batch 02A

```bash
flutter analyze lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

Escalate to `flutter test` if:

- a component public API changes
- `SectionCard`, `MoneyfyPage`, or theme files are touched
- snapshot/transaction row behavior changes

## Known Worktree Note

현재 worktree에는 이전 문서 정리, 투자성과 분석 리디자인, 그리고 별도 변경 파일이 섞여 있습니다. 구현 시 기존 변경을 되돌리지 않고, Batch 02A 대상 파일만 좁게 수정합니다.

## Go/No-Go Checklist

- [x] 전체 UI-bearing Dart 파일 stage 배정 확인
- [x] native/web visual asset audit 대상 분리
- [x] legacy 패턴 수치화
- [x] 첫 구현 batch 축소
- [x] 검증 명령 확정
- [x] 대량 치환 금지 원칙 확정

