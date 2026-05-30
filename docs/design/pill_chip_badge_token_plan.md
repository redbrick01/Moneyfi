# Pill, Chip, Badge 토큰 계획

최종 업데이트: 2026-05-30

이 문서는 2026-05-30 앱 스크린샷에서 확인한 pill 형태 UI의 현재 상태를 정리하고, 이를 재사용 가능한 Moneyfy 디자인 토큰과 연결하기 위한 계획을 기록한다. 구현 보고서가 아니라 설계와 감사 기준 문서다.

## 목표

Moneyfy는 compact metadata, 거래 유형, 필터, 금융 수치 변화 표현에 이미 pill 형태 UI를 사용하고 있다. 목표는 주요 액션이나 밀도 높은 금융 row를 과하게 둥근 장식 UI로 만들지 않으면서, pill 계열 사용처를 일관된 토큰으로 정리하는 것이다.

토큰 정리의 기준:

- 현재의 차분한 금융 대시보드 인상을 유지한다.
- 기존 brand, semantic, surface, typography, spacing, radius 토큰을 재사용한다.
- 비상호작용 badge와 상호작용 filter chip을 구분한다.
- 손익 의미는 읽기 쉽게 유지하되, 큰 색상 fill은 피한다.
- pill 형태마다 로컬 `Container` 스타일을 반복하지 않는다.

## 스크린샷 기준 현재 상태

### 전체 시각 언어

| 영역 | 현재 관찰 | 기존 토큰 기준 |
| --- | --- | --- |
| Primary accent | 하단 탭 선택, 선택 chip, 차트 강조에 선명한 blue 사용 | `VisualSpec.brand.primary` / `#3A6DFF` |
| Positive state | 수익과 양수 percent에 밝은 green 사용 | `VisualSpec.brand.lightPositive` / `#00D47E` |
| Negative state | 손실과 음수 percent에 coral red 사용 | `VisualSpec.brand.lightNegative` / `#FF4554` |
| Neutral surface | 아주 연한 회색 섹션 위에 white card 배치 | `lightSurface`, `lightSurfaceContainer` |
| Soft pill surface | 옅은 회색 pill 배경 | `lightSurfaceHigh` / `#EEF0F3` |
| Border | 카드, 필터, divider에 조용한 gray outline 사용 | `lightOutlineVariant` / `#DEE1E6` |
| Text hierarchy | 검정 primary text, 회색 secondary metadata | `lightTextPrimary`, `lightTextSecondary` |
| Radius | 카드는 rounded, pill은 full rounded | `AppRadius.rPill`, `VisualSpec.surface.radiusCard` |

### 사용 중인 Pill 계열 컴포넌트

| 컴포넌트 | 예시 | 역할 | 현재 동작 |
| --- | --- | --- | --- |
| Ticker badge | `IONQ`, `NVDA`, `BTC` | 뉴스 row의 짧은 식별 metadata | soft neutral fill, dark text, 강한 border 없음 |
| Transaction type badge | `이체`, `출금`, `매도` | 원장 row의 거래 유형 | soft neutral fill, muted text, subtle border |
| Filter chip | `전체`, `매수`, `매도`, `배당`, `입출금` | 상호작용 quick filter | 선택 상태는 blue border/text, 미선택은 neutral border/text |
| Metric pill | `+43.7%`, `-16.5%`, `51.4%` | compact numeric state | neutral fill + semantic text color |
| Delta chip | 상세/대시보드 row의 signed currency/percent | 손익 상태 | `lib/components/chips/delta_chip.dart`에서 semantic text와 neutral/semantic container 사용 |
| Impact chip | 아이콘이 붙은 짧은 insight label | compact explanation metadata | `lib/components/chips/impact_chips.dart`에서 neutral 또는 secondary container 사용 |

## 제안 토큰 모델

pill만을 위한 완전히 별도의 시각 언어를 만들지 않는다. 기존 전역 토큰을 조합하는 작은 component-level spec을 추가한다.

## 피드백 요약

계획의 방향은 맞지만 구현 범위 제어가 중요하다. `context.radius.rPill`은 badge나 chip이 아닌 icon button surface, bottom navigation, form control, app button 등에도 쓰이고 있다. 이 계획은 모든 `rPill` 사용처를 migration 대상으로 삼지 않는다.

실행 피드백:

- 먼저 compact label component만 migration한다: ticker badge, transaction type badge, filter chip, metric pill, `DeltaChip`, `ImpactChips`.
- pill 형태 button, bottom navigation selected tab, search field, icon surface는 첫 pass에서 명시적으로 제외한다.
- 새 widget을 늘리기 전에 style resolver를 추가한다. 그렇지 않으면 wrapper마다 로컬 스타일 반복 문제가 다시 생긴다.
- 첫 구현 pass에서는 `RawChip`, `ChoiceChip`의 동작을 유지하고 color, shape, typography, padding, selected state만 맞춘다.
- 여러 filter chip이 compact visual density와 shrink-wrapped tap target을 쓰고 있으므로 접근성을 별도 기준으로 본다.

### 컴포넌트 패밀리

| 패밀리 | 상호작용 | 주요 용도 | 공유 기준 |
| --- | --- | --- | --- |
| `MoneyfyBadge` | 아니오 | Ticker, 거래 유형, 상태 metadata | Pill radius, neutral surface, compact typography |
| `MoneyfyFilterChip` | 예 | Quick filter, sheet filter, choice filter | Pill radius, outline state, selected brand state |
| `MoneyfyMetricPill` | 아니오 | Percent, ratio, signed compact value | Pill radius, semantic foreground, neutral surface |
| `DeltaChip` | 아니오 | Signed financial delta | 기존 동작 유지, metric pill token에 정렬 |

### 이 계획의 제외 범위

| 영역 | 이유 |
| --- | --- |
| Bottom navigation selected capsule | Navigation은 별도의 interaction, size, safe-area 규칙을 가진다. |
| Primary/secondary/destructive button | Button shape은 button token과 tap-target 규칙이 소유한다. |
| Search field | Search는 input/control surface이지 chip이나 badge가 아니다. |
| Icon button surface | Icon-only control은 icon button spec이 필요하다. |
| Sheet/dialog/card radius | 큰 surface radius는 별도로 검토한다. |
| Chart legend dot과 chart geometry | Chart visual은 chart spec이 관리한다. |

### Size Token

| 토큰 | 높이 | 가로 padding | Typography | 용도 |
| --- | ---: | ---: | --- | --- |
| `pill.sm` | `28` | `12` | `caption` 또는 compact `meta` | Ticker badge, transaction type badge |
| `pill.md` | `32` | `14` | `meta` | Metric pill, impact chip |
| `pill.lg` | `36` to `40` | `16` | `button` 또는 `meta` semibold | Filter chip |

메모:

- Radius는 `context.radius.rPill`을 사용한다.
- 텍스트는 한 줄을 유지한다. 주변 row가 이미 너비를 제한하는 경우에만 ellipsis를 허용한다.
- 상호작용 chip의 최소 tap target은 visual height와 별도로 검토한다. visual height가 44dp보다 작다면 주변 hit area가 편안해야 한다.

### Tone Token

| Tone | Background | Foreground | Border | 용도 |
| --- | --- | --- | --- | --- |
| `neutral` | `neutralSurfaceBase` / `lightSurfaceHigh` | `neutralTextPrimary` 또는 `neutralTextMuted` | optional `neutralOutline` | Ticker, 거래 유형 |
| `primary` | white 또는 primary container | `primary` | `primary` | 선택된 filter |
| `success` | neutral 또는 positive container | `positiveOn` | optional positive/neutral outline | 양수 metric/delta |
| `danger` | neutral 또는 negative container | `negativeOn` | optional negative/neutral outline | 음수 metric/delta |
| `warning` | neutral 또는 warning container | `warningOn` | optional warning/neutral outline | 검토 필요 badge |

현재 스크린샷은 neutral gray background + semantic text를 선호한다. 이를 기본값으로 유지한다. 상태를 더 강조해야 할 때만 semantic tinted container를 허용한다.

### Variant Token

| Variant | Fill | Border | 용도 |
| --- | --- | --- | --- |
| `soft` | Neutral soft fill | Transparent 또는 아주 약한 outline | 비상호작용 badge, metric pill |
| `outline` | White fill | Neutral outline | 미선택 filter chip |
| `selected` | White fill | Primary outline | 선택된 filter chip |
| `tonal` | Semantic 또는 primary container | Matching low-emphasis outline | 드물게 강조되는 status |

## 구현 형태

권장 구조:

```dart
enum MoneyfyPillSize { sm, md, lg }
enum MoneyfyPillTone { neutral, primary, success, danger, warning }
enum MoneyfyPillVariant { soft, outline, selected, tonal }
```

새 widget을 늘리기 전에 하나의 재사용 가능한 style resolver를 추가한다.

```dart
class MoneyfyPillStyle {
  const MoneyfyPillStyle({
    required this.height,
    required this.padding,
    required this.background,
    required this.foreground,
    required this.border,
    required this.textStyle,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color foreground;
  final Color border;
  final TextStyle textStyle;
}
```

권장 위치:

- Size와 radius 상수: `lib/design_system/spec/visual_spec.dart`의 새 pill/chip spec
- Theme-aware color resolution: `lib/design_system/context_extensions.dart` 근처 또는 새 component helper
- Reusable widgets: style resolver가 생긴 뒤 `lib/components/chips/`

### Resolver 요구사항

resolver는 다음을 받아야 한다.

- `BuildContext`: theme extension을 읽고 dark mode를 지원하기 위해 필요하다.
- `MoneyfyPillSize`, `MoneyfyPillTone`, `MoneyfyPillVariant`
- 상호작용 chip을 위한 selected 또는 disabled state
- named size token에 매핑되는 경우에만 optional compact flag 허용

resolver는 다음을 반환해야 한다.

- height, padding, shape radius, border width, background, foreground, border color, text style
- token/spec source 외부에 raw hex 없음
- 직접 `FontWeight.w...` 사용 없음. `AppFontWeights`를 사용한다.

색만 반환하는 resolver는 피한다. 현재 불일치는 색뿐 아니라 height, padding, font weight, border emphasis에도 있다.

### 접근성 요구사항

상호작용 chip은 compact visual height를 유지할 수 있지만 tap 동작은 편안해야 한다.

- 주변 layout이 충분한 hit area를 제공하지 않는다면 Material 기본 tap target을 우선한다.
- `MaterialTapTargetSize.shrinkWrap`을 쓰는 경우 row가 여전히 사용하기 편한 이유를 문서화한다.
- 선택 chip은 색상만으로 상태를 전달하지 않는다. icon/checkmark 또는 border/weight 변화가 남아 있어야 한다.
- 한국어 label은 360dp width와 text scale 1.3에서도 버텨야 한다.

## Migration 계획

### Phase 1: 문서화와 감사

- 이 문서를 baseline으로 사용한다.
- `rg "rPill|Chip|Badge|Pill|RawChip|ChoiceChip" lib`로 현재 pill 계열 code path를 감사한다.
- 각 사용처를 badge, filter chip, metric pill, delta chip, icon button surface, unrelated rounded control로 분류한다.
- in-scope와 out-of-scope `rPill` 사용처를 분리한 짧은 migration list를 만든다.

### Phase 2: Spec만 추가

- 화면 동작을 바꾸지 않고 pill size token과 variant 이름을 추가한다.
- 기존 `DeltaChip` API는 유지한다.
- 한 patch에서 모든 call site를 교체하지 않는다.
- resolver에 보호할 로직이 있을 때만 테스트를 추가한다. 시각 parity는 screenshot/manual QA로 확인한다.

### Phase 3: Shared Component Migration

- `DeltaChip`과 `ImpactChips`를 새 size/variant resolver에 맞춘다.
- ticker와 transaction type label을 위한 비상호작용 badge widget을 추가한다.
- quick filter와 filter sheet를 위한 reusable filter chip style 또는 wrapper를 추가한다.

### Phase 4: 화면 정리

- 거래 페이지 quick filter와 거래 유형 badge를 migration한다.
- 뉴스 ticker badge를 migration한다.
- 포트폴리오 metric pill을 migration한다.
- 화면별 시각 parity를 확인한 뒤 로컬 pill `Container` 스타일을 제거한다.

## 1차 Migration 후보

| 우선순위 | 파일 | 현재 패턴 | 목표 |
| ---: | --- | --- | --- |
| 1 | `lib/components/chips/delta_chip.dart` | 로컬 size, padding, border, semantic color logic | public API를 유지하면서 metric pill style resolver 사용 |
| 2 | `lib/components/chips/impact_chips.dart` | 로컬 impact chip 치수와 색상 | `pill.md` neutral/primary soft style 사용 |
| 3 | `lib/components/rows/transaction_row.dart` | 로컬 transaction type badge container | `MoneyfyBadge` + `pill.sm` neutral로 교체 |
| 4 | `lib/widgets/company_news_summary_card.dart` | 로컬 ticker badge container | `MoneyfyBadge` + `pill.sm` neutral emphasis로 교체 |
| 5 | `lib/widgets/market_news_summary_card.dart` | 로컬 source/ticker pill container | shared badge style로 교체 |
| 6 | `lib/pages/transactions_page.dart` | `RawChip` quick filter와 sheet filter | filter logic은 유지하고 shared filter chip style 적용 |
| 7 | `lib/pages/investment_performance_page.dart` | 로컬 `_StatusPill`, `_MetricPill`, `ChoiceChip` | shared resolver 안정화 후 migration |

`portfolio_analysis_mvp_page.dart`처럼 넓은 파일은 shared component가 안정화될 때까지 미룬다. 이 파일은 `rPill` 사용처가 많고 badge, control, layout-specific rounded surface가 섞여 있다.

## Guardrail

- pill UI는 tag, badge, 짧은 metadata, filter, compact metric에만 사용한다.
- 모든 command의 기본 primary button shape으로 pill styling을 쓰지 않는다.
- chart/legend context 밖의 pill UI에 chart palette color를 사용하지 않는다.
- semantic green/red는 대부분 text, icon, border, small chip foreground로만 사용한다.
- 일반 profit/loss row에 큰 success/error filled surface를 쓰지 않는다.
- 360dp width와 text scale 1.3에서 한국어 텍스트를 확인한다.
- Chip label은 짧게 유지한다. 긴 텍스트는 pill이 아니라 row body copy에 둔다.

## 검증

구현 변경 후 실행:

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/design_system/spec/visual_spec.dart
flutter analyze lib/components/chips/delta_chip.dart
flutter analyze lib/pages/transactions_page.dart
flutter test test/design_md_screenshot_harness_test.dart
flutter test test/page_walkthrough_test.dart
```

수동 screenshot review 대상:

- 포트폴리오 대시보드 총자산 카드와 자산 목록
- 포트폴리오 비중 차트 legend와 percentage pill
- 거래 검색/filter 영역과 거래 row
- 분석/뉴스 카드의 ticker badge
- 360dp, 390dp, 430dp에서 bottom navigation overlap

## 열린 결정 사항

| 결정 | 권장 |
| --- | --- |
| positive/negative pill에 tinted background를 쓸 것인가? | 기본은 neutral background + semantic text. 강조 상태에만 `tonal` 허용 |
| ticker와 transaction type badge를 같은 widget으로 공유할 것인가? | 예. foreground emphasis만 다르게 둔다. |
| `ChoiceChip`을 교체할 것인가? | 즉시 교체하지 않는다. 먼저 theme/wrapper를 표준화한 뒤 call site를 migration한다. |
| `rPill`을 `100`으로 유지할 것인가, `999`로 바꿀 것인가? | 단일 token으로 유지한다. 정확한 숫자보다 한 source를 쓰는 것이 중요하다. |
| card radius를 스크린샷에 맞춰 키울 것인가? | 별도 작업으로 다룬다. 이 계획은 pill/chip/badge token만 다룬다. |
| transaction filter chip의 shrink-wrapped tap target을 유지할 것인가? | 구현 중 검토한다. layout은 유지하되 불편한 hit target은 피한다. |

## 후속 감사 계획

이 섹션은 첫 token 구현 후 최종 후속 계획과 현재 진행도를 기록한다. 핵심 규칙:

`MoneyfyBadge` 또는 `MoneyfyPillStyle`은 compact text label에만 사용한다. control, input field, navigation capsule, progress bar, chart/gauge geometry는 pill badge token system으로 migration하지 않는다.

### 현재 연결 상태

| 분류 | 상태 | 메모 |
| --- | --- | --- |
| 뉴스 ticker와 importance badge | 연결 완료 | `MoneyfyBadge` 사용 |
| 거래 row type badge | 연결 완료 | `MoneyfyBadge` 사용 |
| 거래 quick filter와 filter sheet chip | 연결 완료 | `RawChip` 동작을 유지하면서 `MoneyfyPillStyle.resolve` 사용 |
| 투자성과 date/filter/status/metric chip | 연결 완료 | `MoneyfyPillStyle.resolve` 또는 `MoneyfyBadge` 사용 |
| `DeltaChip` | 연결 완료 | public API 유지, 내부 style은 pill token으로 resolve |
| `ImpactChips` | 연결 완료 | 내부 style은 pill token으로 resolve |
| 남은 compact text badge | 연결 완료 | 후속 migration 완료. 아래 체크리스트 참고 |
| Button, search field, navigation, progress/gauge geometry | 제외 | badge/chip token 대상이 아님 |

### Migration 체크리스트

텍스트 label badge 자체만 migration한다. 주변 progress bar, gauge track, drag handle, button, input outline은 migration하지 않는다.

| 완료 | 우선순위 | 파일 | 대상 | 결과 |
| --- | ---: | --- | --- | --- |
| [x] | 1 | `lib/pages/asset_detail_page.dart` | `_HeroDashChip` placeholder | `MoneyfyBadge(label: '-', size: sm, variant: outline)` |
| [x] | 2 | `lib/pages/holding_detail_page.dart` | `_HoldingHeroDashChip` placeholder | `MoneyfyBadge(label: '-', size: sm, variant: outline)` |
| [x] | 3 | `lib/pages/cash_account_detail_page.dart` | `_CashHeroDashChip` placeholder | `MoneyfyBadge(label: '-', size: sm, variant: outline)` |
| [x] | 4 | `lib/pages/portfolio_dashboard_page.dart` | `_SummaryDashChip` placeholder | `MoneyfyBadge(label: '-', size: sm, variant: outline)` |
| [x] | 5 | `lib/components/rows/allocation_legend_row.dart` | ratio badge | `MoneyfyBadge(size: sm, variant: outline)` |
| [x] | 6 | `lib/components/rows/snapshot_row.dart` | inline percent badge | `MoneyfyBadge(size: sm, variant: outline)` + semantic text override |
| [x] | 7 | `lib/pages/analysis_page.dart` | change-rate badge | `MoneyfyBadge(size: sm, variant: outline)` + semantic text override |
| [x] | 8 | `lib/pages/portfolio_dashboard_page.dart` | USD/KRW metadata pill | `MoneyfyBadge(size: md, variant: soft)` |
| [x] | 9 | `lib/pages/portfolio_page.dart` | `_RiskBadge` | `MoneyfyBadge(size: sm)` + 기존 semantic background/text override |
| [x] | 10 | `lib/pages/portfolio_dashboard_page.dart` | `_DashboardDiagnosisBadge` | `MoneyfyBadge(size: md)` + 기존 semantic background/text override |
| [x] | 11 | `lib/pages/dividend_interest_analysis_page.dart` | transaction type badge | `MoneyfyBadge(size: sm, tone: warning, variant: tonal)` |
| [x] | 12 | `lib/pages/portfolio_dashboard_page.dart` | Material `Chip` label | `MoneyfyBadge(size: sm)`로 교체 |
| [x] | 13 | `lib/pages/portfolio_analysis_mvp_page.dart` | diagnosis label badge | `MoneyfyBadge(size: sm, variant: outline)` |
| [x] | 14 | `lib/pages/portfolio_analysis_mvp_page.dart` | count/metric text badge | `MoneyfyBadge(size: sm, variant: outline)` |
| [x] | 15 | `lib/pages/portfolio_analysis_mvp_page.dart` | level badge | `MoneyfyBadge(size: sm, variant: tonal)` + 기존 semantic override |

진행도: compact text badge migration 대상 15개 중 15개 완료.

### 명시적 제외 대상

후속 patch에서 다음 사용처는 migration하지 않는다.

| 영역 | 예시 | 이유 |
| --- | --- | --- |
| Bottom navigation | `app_shell_page.dart` selected capsule | Navigation control이지 compact metadata가 아니다. |
| Button | `app_buttons.dart`, transaction filter button | Button token과 tap target 규칙이 소유한다. |
| Search/input field | transaction search field, form field | Input decoration token이 소유한다. |
| Icon-only control | `MoneyfyIconButtonSurface` | Icon button spec이 소유한다. |
| Progress bar | allocation, target allocation, dividend/interest progress | Data visualization geometry다. |
| Gauge track과 threshold marker | `portfolio_analysis_mvp_page.dart` gauge sections | Chart/gauge geometry이지 badge UI가 아니다. |
| Bottom sheet drag handle | transaction filter sheet handle | Sheet affordance이지 metadata가 아니다. |
| 작은 count bubble | transaction filter active count | notification/count badge다. 필요하면 별도 검토한다. |

### 최종 실행 순서

1. [x] 구현 전 audit section 추가
2. [x] placeholder dash chip 먼저 migration
3. [x] numeric 및 metadata badge migration
4. [x] risk, transaction type, simple Material `Chip` label migration
5. [x] `portfolio_analysis_mvp_page.dart` 안의 text label badge만 migration
6. [x] 검증 실행
7. [x] 구현 보고서에 실제 완료/보류 상태 반영

커밋 분리 권장:

- Commit 1: placeholder, numeric, metadata badge
- Commit 2: risk/type badge와 `portfolio_analysis_mvp_page.dart` text label badge

현재 실제 상태: 후속 patch 구현은 완료됐지만 아직 커밋 전이다. 범위가 compact text badge로 제한됐고 검증이 통과했으므로 하나의 follow-up commit으로 묶어도 된다.

### 후속 검증

후속 구현 후 실행:

```bash
flutter analyze lib/components/rows/allocation_legend_row.dart lib/components/rows/snapshot_row.dart lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/analysis_page.dart lib/pages/dividend_interest_analysis_page.dart lib/pages/portfolio_analysis_mvp_page.dart
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
```

현재 결과:

- [x] `flutter analyze ...` 통과
- [x] `tools/check_design_token_guardrails.sh` 통과
- [x] `flutter test test/ui_component_smoke_test.dart` 통과

수동 QA 초점:

- asset, holding, cash account, dashboard hero section의 dash placeholder chip
- 360dp와 text scale 1.3에서 ratio 및 change-rate badge
- `MoneyfyBadge` 전환 후에도 risk badge의 의미가 유지되는지 확인
- `portfolio_analysis_mvp_page.dart`의 gauge는 text label badge 외에는 시각 변화가 없어야 함
