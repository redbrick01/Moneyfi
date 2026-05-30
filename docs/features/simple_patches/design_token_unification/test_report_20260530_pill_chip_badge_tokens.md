# Pill, Chip, Badge Token Implementation Report

작성일: 2026-05-30

## Scope

스크린샷 기반 pill/chip/badge 정리 계획을 구현 가능한 공통 토큰 구조로 반영했다. 범위는 compact label UI에 한정했다.

포함:

- ticker badge
- transaction type badge
- filter chip
- metric/status pill
- `DeltaChip`
- `ImpactChips`

제외:

- bottom navigation selected capsule
- primary/secondary/destructive button shape
- search field
- icon button surface
- card, sheet, dialog radius
- chart geometry

## Changed Files

| 파일 | 변경 |
| --- | --- |
| `docs/design/pill_chip_badge_token_plan.md` | 스크린샷 기반 현재 상태, 피드백, migration plan 문서화 |
| `lib/design_system/spec/visual_spec.dart` | `VisualSpec.pill` 치수 토큰 추가 |
| `lib/components/chips/moneyfy_pill.dart` | `MoneyfyPillStyle`, size/tone/variant enum, `MoneyfyBadge` 추가 |
| `lib/components/chips/delta_chip.dart` | signed delta 표시를 pill resolver 기반으로 전환 |
| `lib/components/chips/impact_chips.dart` | impact chip 색상/치수/테두리를 pill resolver 기반으로 전환 |
| `lib/components/rows/transaction_row.dart` | 거래 타입 badge를 `MoneyfyBadge`로 전환 |
| `lib/widgets/company_news_summary_card.dart` | ticker/importance badge를 `MoneyfyBadge`로 전환 |
| `lib/widgets/market_news_summary_card.dart` | importance/impact/assessment badge를 `MoneyfyBadge`로 전환 |
| `lib/pages/transactions_page.dart` | quick filter/sheet filter `RawChip` 스타일을 pill resolver로 정리 |
| `lib/pages/investment_performance_page.dart` | date/filter `ChoiceChip`, status pill, metric pill을 pill resolver로 정리 |
| `docs/README.md`, `docs/document_inventory.md` | 새 계획서 링크 추가 |

## Implementation Notes

- `VisualSpec.pill`은 정적인 치수만 가진다.
- 색상, foreground, border, typography는 `MoneyfyPillStyle.resolve(BuildContext, ...)`에서 theme extension 기반으로 계산한다.
- `MoneyfyPillSize`는 `sm`, `md`, `lg`로 제한했다.
- `MoneyfyPillTone`은 `neutral`, `primary`, `success`, `danger`, `warning`으로 제한했다.
- `MoneyfyPillVariant`는 `soft`, `outline`, `selected`, `tonal`로 제한했다.
- `DeltaChip`의 public API는 유지했다.
- transaction filter의 `RawChip` 동작은 유지하고 visual style만 통일했다.
- investment performance의 `ChoiceChip` 동작은 유지하고 local wrapper로 visual style만 통일했다.

## Verification

실행 결과:

```bash
flutter analyze lib/design_system/spec/visual_spec.dart lib/components/chips/moneyfy_pill.dart lib/components/chips/delta_chip.dart lib/components/chips/impact_chips.dart lib/components/rows/transaction_row.dart lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/transactions_page.dart lib/pages/investment_performance_page.dart
```

Result: passed, no issues found.

```bash
tools/check_design_token_guardrails.sh
```

Result: passed, design token guardrail report clean.

```bash
flutter test test/ui_component_smoke_test.dart
```

Result: passed, 7 tests.

## Residual Risk

- No screenshot golden diff was run for this patch.
- Filter chips still preserve existing compact behavior in some rows; touch target comfort should be checked during device QA.
- Broad pages such as `portfolio_analysis_mvp_page.dart` still have unrelated `rPill` usages and should remain out of scope until a separate control/surface radius pass.

## Follow-Up

- Add focused screenshot QA for transaction filters, news badges, and investment performance chips.
- Consider a shared interactive filter chip widget after visual parity is confirmed.
- Continue avoiding migration of button/search/navigation capsules into pill badge tokens.
