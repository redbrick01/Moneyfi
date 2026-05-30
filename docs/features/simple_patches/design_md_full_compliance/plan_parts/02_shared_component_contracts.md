# 02 Shared Component Contracts

## 목표

화면별 수정에 앞서 button, card, row, chip, icon, state, scaffold의 design-md contract를 고정한다.

공용 컴포넌트 contract가 먼저 안정되어야 P0/P1 화면 수정을 ad-hoc 스타일 추가 없이 진행할 수 있다.

## 대상 파일

| 영역 | 파일 |
| --- | --- |
| Buttons | `lib/components/buttons/app_buttons.dart` |
| Cards | `lib/components/section_card.dart`, `lib/components/cards/status_card.dart`, `lib/components/headers/detail_header_card.dart` |
| Rows | `lib/components/rows/**`, `lib/components/transaction_history_list.dart` |
| Chips | `lib/components/chips/**` |
| Icons | `lib/components/icons/**` |
| States | `lib/components/states/**`, `lib/components/feedback/app_snackbar.dart` |
| Metrics | `lib/components/metrics/**` |
| Separators | `lib/components/separators/app_divider.dart` |
| Scaffold | `lib/ui_scaffold/**`, `lib/widgets/moneyfy_ui.dart` |

## Contract Checklist

| 컴포넌트 | 기준 |
| --- | --- |
| Primary button | 44dp 기본 높이, pill radius, Moneyfy primary `#3A6DFF`, pressed/disabled state 명확 |
| Large CTA | 56dp 높이, primary action에만 사용 |
| Secondary button | soft gray surface, ink text, pill radius |
| Tertiary action | transparent, primary blue text/icon only |
| Card | white/surface-soft, hairline 중심, 과도한 shadow 없음 |
| Detail header | product-ui-card-light 변형: calm number hierarchy, hairline, 충분한 padding |
| Row | 44dp 이상 tap target, list row는 56dp 이상, divider/hairline 일관 |
| Asset row | circular icon plate, trailing number role, semantic color text-only |
| Transaction row | leading/action/trailing alignment 안정, 긴 금액 overflow 없음 |
| Chip | pill radius, compact padding, selected state만 primary blue 또는 strong surface |
| Icon button | `VisualSpec.icon.minTapTarget` 또는 동등한 44-48dp target |
| State component | empty/loading/error/retry의 icon, copy, action hierarchy 일관 |
| Divider / separator | 1px hairline, inset 일관, card/row 경계에서 과도한 contrast 없음 |
| Scaffold | horizontal inset, bottom inset, safe area, page title spacing 일관 |

## 구현 작업

1. canonical contract 산출물은 `docs/features/simple_patches/design_md_full_compliance/component_contract.md`로 고정한다.
2. `audit_matrix.md`에서는 관련 component row가 `component_contract.md`를 링크한다.
3. P0 화면에서 반복 발견된 ad-hoc styling을 공용 컴포넌트 API로 흡수한다.
4. visual role만 수정하고 route, DB, 계산, sync 동작은 변경하지 않는다.
5. chart/canvas geometry는 이 단계에서 건드리지 않는다.

## 검증

```bash
flutter analyze lib/components lib/ui_scaffold lib/widgets/moneyfy_ui.dart
flutter test test/ui_component_smoke_test.dart
```

필요 시:

```bash
flutter test test/page_walkthrough_test.dart
```

## 완료 기준

- button, card, row, chip, icon, state, scaffold contract checklist가 모두 pass.
- divider/separator contract가 `component_contract.md`에 포함됨.
- 새 P0 화면 수정에서 ad-hoc button/card/row/chip을 추가하지 않아도 된다.
- `tools/check_design_token_guardrails.sh`가 clean을 유지한다.
