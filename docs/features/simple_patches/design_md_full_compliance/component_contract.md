# Design-MD Component Contract

작성일: 2026-05-29

## 목적

MONEYFY 공용 UI 컴포넌트가 `docs/design_system.md`의 현행 Moneyfy design system 원칙을 모바일 앱 화면에서 일관되게 구현하도록 하는 canonical contract다.

이 문서는 `plan_parts/02_shared_component_contracts.md`의 산출물이며, P0/P1 화면 수정은 이 contract를 먼저 따른다.

## Shared Foundations

| 항목 | Contract |
| --- | --- |
| 색상 | `context.colors`, `Theme.of(context).colorScheme`, `VisualSpec`를 사용한다. 직접 hex/color literal은 design system/theme 외부에서 사용하지 않는다. |
| Typography | `context.typography`를 사용한다. `cardTitle`, `heroNumber`, `meta`, `caption`은 tabular figure가 포함된 MONEYFY number-safe text role이다. |
| Spacing | `context.spacing`, `context.cardPadding()`, `VisualSpec.surface`를 사용한다. |
| Radius | CTA/chip/search는 `context.radius.rPill`, input은 12dp 기준, card는 `VisualSpec.surface.radiusCard`, sheet/dialog는 24dp 기준이다. |
| Depth | shadow tier를 늘리지 않는다. 기본은 hairline border와 surface 차이로 계층을 만든다. |
| Semantics | positive/negative/warning은 text/icon/chart mark 중심으로 사용한다. container는 design system의 soft neutral container일 때만 허용한다. |

## Buttons

대상:

- `lib/components/buttons/app_buttons.dart`

Contract:

| Variant | 기준 |
| --- | --- |
| Primary | 44-48dp 이상 height, pill radius, primary blue background, on-primary text, loading spinner는 fixed size |
| Secondary | pill radius, soft/light surface, primary or ink foreground, 1px border 허용 |
| Ghost | transparent background, primary text/icon only |
| Destructive | transparent background, error text/icon only |
| Disabled | opacity/foreground로만 구분하고 layout shift 없음 |

현재 판정:

- `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, `AppDestructiveButton`은 `VisualSpec.icon.minTapTarget`, `context.typography.button`, `context.radius.rPill`을 사용한다.
- Loading state는 fixed progress size를 사용한다.
- Contract status: pass.

## Cards

대상:

- `lib/components/section_card.dart`
- `lib/components/cards/status_card.dart`
- `lib/components/headers/detail_header_card.dart`

Contract:

| Component | 기준 |
| --- | --- |
| SectionCard | white/soft surface, 1px hairline, radiusCard, no extra shadow |
| StatusCard | icon/title/body/action hierarchy 유지, primary action만 blue |
| DetailHeaderCard | product-ui-card-light 앱형 변형. title, hero number, secondary rows, footer meta 순서 유지 |

현재 판정:

- `SectionCard`는 `VisualSpec.surface.cardBase/cardRaised`, border width, radiusCard, `AppDivider`를 사용한다.
- `DetailHeaderCard`는 `SectionCardVariant.raised`와 `context.typography.heroNumber`를 사용한다.
- Contract status: pass.

## Rows

대상:

- `lib/components/rows/**`
- `lib/components/transaction_history_list.dart`

Contract:

| Row | 기준 |
| --- | --- |
| AssetRow | 44dp 이상 tap target, 기본 76dp minHeight, circular/icon leading, trailing amount는 number-safe role |
| TransactionRow | 64dp minHeight, type badge pill, trailing amount scale-down, amount/meta overflow 방지 |
| SnapshotRow | 64dp minHeight, trailing amount + delta alignment, single-line/stacked delta 모두 overflow 방지 |
| KeyValue/Metric/Rebalance/Allocation rows | label은 meta/body, value는 number-safe role, divider/hairline 일관 |

현재 판정:

- `AssetRow`, `TransactionRow`, `SnapshotRow`의 trailing amount는 `context.typography.cardTitle` 기반이다.
- `AppTypography.cardTitle`에는 `FontFeature.tabularFigures()`가 포함되어 있어 number-safe role로 간주한다.
- `TransactionRow`와 `AssetRow`는 `FittedBox(scaleDown)` 또는 width calculation으로 긴 금액 overflow를 방지한다.
- Contract status: pass.

주의:

- row type badge나 chip이 semantic container를 사용할 때 실제 화면에서 green/red filled badge처럼 보이면 Stage 03에서 조정한다.

## Chips

대상:

- `lib/components/chips/delta_chip.dart`
- `lib/components/chips/impact_chips.dart`

Contract:

| Chip | 기준 |
| --- | --- |
| DeltaChip | pill radius, compact option, tabular figure, semantic text color 중심 |
| ImpactChips | pill/compact row, icon + label alignment, overflow 방지 |
| Selected/filter chip | primary blue는 selected state에만 허용 |

현재 판정:

- `DeltaChip`은 tabular figure를 명시적으로 적용한다.
- `DeltaChip.vivid`는 positive/negative text와 soft semantic container를 사용한다. 현재 `VisualSpec`의 positive/negative container는 light mode에서 `#EEF0F3`라서 colored green/red fill은 아니다.
- Contract status: pass with visual follow-up.

Stage 03/04 확인:

- `vivid` chip이 실제 화면에서 semantic fill처럼 과도하게 보이는지 screenshot으로 확인한다.

## Icons

대상:

- `lib/components/icons/**`

Contract:

| Component | 기준 |
| --- | --- |
| AppIconButton | 44-48dp tap target, icon size token, tooltip 필수 |
| AppAvatar / LeadingBadge | circular or rounded plate, strong contrast, primary blue 남발 금지 |
| AppIcon | `VisualSpec.icon` semantic mapping 사용 |

현재 판정:

- Icon sizing과 tap target은 `VisualSpec.icon` 기준을 따른다.
- Contract status: pass.

## States

대상:

- `lib/components/states/**`
- `lib/components/feedback/app_snackbar.dart`

Contract:

| State | 기준 |
| --- | --- |
| Empty | calm icon, title/body/action hierarchy, primary action 하나만 blue |
| Retry/Error | error text/icon은 semantic text 중심, retry action은 primary/ghost hierarchy |
| Skeleton | neutral soft surfaces, layout size 안정 |
| Snackbar | floating nav inset 고려, semantic color 과다 사용 금지 |

현재 판정:

- Empty/retry/error/skeleton smoke test가 존재한다.
- Contract status: pass.

## Metrics

대상:

- `lib/components/metrics/**`

Contract:

| Component | 기준 |
| --- | --- |
| MetricHeader | primary text는 `heroNumber` 또는 number-safe title role |
| MetricRow | value는 number-safe role, label은 meta, long value overflow 방지 |

현재 판정:

- `MetricHeader`는 `heroNumber`/`cardTitle`를 사용한다.
- `MetricRow`는 `cardTitle`를 사용하며, `cardTitle`은 tabular figure 포함 role이다.
- Contract status: pass.

## Separators

대상:

- `lib/components/separators/app_divider.dart`

Contract:

| Component | 기준 |
| --- | --- |
| AppDivider | 1px hairline, `VisualSpec.surface.dividerInset`, local grouping에만 사용 |

현재 판정:

- `AppDivider`는 `VisualSpec.surface.dividerThickness`, `dividerInset`, `colorScheme.outlineVariant`를 사용한다.
- Contract status: pass.

## Scaffold

대상:

- `lib/ui_scaffold/**`
- `lib/widgets/moneyfy_ui.dart`

Contract:

| Component | 기준 |
| --- | --- |
| AppPageScaffold | horizontal inset, bottom CTA/safe area, form fixed CTA 안정 |
| MoneyfyPage compatibility | legacy wrapper는 유지하되 새 화면은 `AppPageScaffold` 또는 현재 page pattern 우선 |
| AppInsets | responsive horizontal padding이 360/390/430dp에서 안정적 |

현재 판정:

- `ui_component_smoke_test.dart`가 form fixed CTA와 `MoneyfyPage` scaffold background를 검증한다.
- Contract status: pass.

## Stage 02 Verdict

| 영역 | 판정 | 후속 |
| --- | --- | --- |
| Buttons | pass | P0 화면에서 ad-hoc CTA 발견 시 AppButtons로 전환 |
| Cards | pass | card nesting은 Stage 03 screenshot/manual QA에서 확인 |
| Rows | pass | transaction/asset amount는 `cardTitle` tabular role로 재분류 |
| Chips | pass with visual follow-up | `vivid` chip의 체감 fill 강도는 Stage 03/04에서 확인 |
| Icons | pass | platform asset은 Stage 04 별도 |
| States | pass | 화면별 empty/error/loading 배치는 Stage 03/04에서 확인 |
| Metrics | pass | 긴 값 overflow는 화면별 QA에서 확인 |
| Separators | pass | 과도한 section splitting은 화면별 QA에서 확인 |
| Scaffold | pass | bottom nav/form CTA safe area는 Stage 03에서 확인 |

## Verification

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/components lib/ui_scaffold lib/widgets/moneyfy_ui.dart
flutter test test/ui_component_smoke_test.dart
```
