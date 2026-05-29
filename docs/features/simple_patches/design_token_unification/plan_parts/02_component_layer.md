# 02 Component Layer

## Goal

작은 공용 컴포넌트부터 토큰 기준으로 정리해, 새 UI가 legacy 스타일을 다시 전파하지 않게 합니다.

`lib/widgets/moneyfy_ui.dart`는 파급이 큰 compatibility layer이므로 첫 batch에서 제외하고 별도 하위 batch로 다룹니다.

## Stage-Wide Target Files

Stage 02 전체 대상:

- `lib/ui_scaffold/app_insets.dart`
- `lib/ui_scaffold/app_page_scaffold.dart`
- `lib/components/buttons/app_buttons.dart`
- `lib/components/cards/status_card.dart`
- `lib/components/chips/delta_chip.dart`
- `lib/components/chips/impact_chips.dart`
- `lib/components/expandable/expandable_tile.dart`
- `lib/components/feedback/app_snackbar.dart`
- `lib/components/headers/detail_header_card.dart`
- `lib/components/icons/app_avatar.dart`
- `lib/components/icons/app_icon.dart`
- `lib/components/icons/app_icon_button.dart`
- `lib/components/icons/leading_badge.dart`
- `lib/components/section_card.dart`
- `lib/components/section_header.dart`
- `lib/components/separators/app_divider.dart`
- `lib/components/states/empty_state.dart`
- `lib/components/states/inline_error.dart`
- `lib/components/states/retry_row.dart`
- `lib/components/states/skeletons.dart`
- `lib/components/transaction_history_list.dart`
- `lib/components/rows/snapshot_row.dart`
- `lib/components/rows/rebalance_row.dart`
- `lib/components/rows/allocation_legend_row.dart`
- `lib/components/rows/asset_row.dart`
- `lib/components/rows/key_value_row.dart`
- `lib/components/rows/settings_action_row.dart`
- `lib/components/rows/transaction_row.dart`
- `lib/components/metrics/metric_header.dart`
- `lib/components/metrics/metric_row.dart`

Implementation start batch:

- `lib/components/transaction_history_list.dart`
- `lib/components/rows/snapshot_row.dart`
- `lib/components/rows/rebalance_row.dart`
- `lib/components/rows/allocation_legend_row.dart`
- `lib/components/metrics/metric_header.dart`
- `lib/components/metrics/metric_row.dart`

Defer:

- `lib/widgets/moneyfy_ui.dart`

## Replacement Rules

| Legacy | Replacement |
| --- | --- |
| `MoneyfyPalette.tertiaryText` | `context.colors.neutralTextMuted` or `ColorScheme.onSurfaceVariant` |
| `MoneyfyPalette.ink` | `context.colors.neutralText` or `ColorScheme.onSurface` |
| `MoneyfyPalette.surface` | `context.colors.neutralSurfaceBase` |
| `MoneyfyPalette.border` | `context.colors.neutralOutline` |
| direct `BorderRadius.circular(999)` | `context.radius.rPill` |
| direct spacing | nearest `context.spacing.*` |
| direct font size | `context.typography.*` |

## Batch Strategy

Batch 02A:

- small rows/metrics only
- start with the six-file implementation batch above
- no API changes
- preserve visual density

Batch 02C:

- buttons, chips, states, cards, headers, section shell

Batch 02D:

- UI scaffold and remaining low-risk icon/feedback/expandable components

Batch 02B:

- `moneyfy_ui.dart` compatibility helpers
- replace helper internals where possible without changing public widget names
- keep `moneyfyValueColor` behavior unless a dedicated replacement is introduced

## Non-Goals

- redesign row layouts
- change row heights
- remove `MoneyfyPalette` globally
- change public component constructor signatures unless unavoidable

## Verification

Required:

```bash
flutter analyze lib/components/transaction_history_list.dart lib/components/rows/snapshot_row.dart lib/components/rows/rebalance_row.dart lib/components/rows/allocation_legend_row.dart lib/components/metrics/metric_header.dart lib/components/metrics/metric_row.dart
flutter test test/ui_component_smoke_test.dart
```

If `moneyfy_ui.dart` is touched:

```bash
flutter analyze lib/widgets/moneyfy_ui.dart
flutter test test/page_walkthrough_test.dart
```

## Manual QA

- transaction rows still align trailing amount
- snapshot rows keep amount/rate readability
- rebalance rows retain semantic gain/loss color
- compact chips keep stable height

## Acceptance Criteria

- touched components do not introduce new legacy patterns
- existing row density is preserved
- smoke tests pass
