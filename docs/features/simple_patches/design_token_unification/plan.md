# Design Token Unification Plan

작성일: 2026-05-29

## Patch Goal

MONEYFY UI 코드에서 색상, 폰트, 여백, 간격, 반경, 상태 표현을 공통 디자인 시스템 토큰으로 점진 통일합니다.

목표는 화면을 새로 디자인하는 것이 아니라, 이미 존재하는 `docs/design_system.md`와 `lib/design_system/` 토큰을 실제 코드 전반에 일관되게 적용해 유지보수성과 시각 일관성을 높이는 것입니다.

## Current Baseline

공통 시스템은 이미 존재합니다.

| 영역 | 공통 기준 |
| --- | --- |
| 색상/표면 | `VisualSpec`, `BrandColors`, `ColorScheme` |
| 폰트 | `context.typography`, `AppTypography` |
| 여백/간격 | `context.spacing`, `context.cardPadding()` |
| 반경 | `context.radius`, `VisualSpec.surface.radiusCard` |
| 모션 | `context.motion`, `VisualSpec.motion` |
| 컴포넌트 | `SectionCard`, `AssetRow`, `TransactionRow`, `DeltaChip`, `AppButtons`, state components |
| 문서 기준 | `docs/design_system.md` |

하지만 오래된 화면과 일부 위젯에는 개별 수치가 남아 있습니다.

대표 잔존 패턴:

- `MoneyfyPalette` / `MoneyfySpacing`
- `Color(0x...)`, `Colors.white`, `Colors.transparent`
- `fontSize: 15`, `fontSize: 22` 같은 직접 폰트 크기
- `const SizedBox(height: 10)`, `const SizedBox(width: 14)`
- `EdgeInsets.all(14)`, `EdgeInsets.symmetric(horizontal: 10, vertical: 5)`
- `BorderRadius.circular(16)`, `BorderRadius.circular(999)`

대표 잔존 영역:

| 영역 | 상태 |
| --- | --- |
| `lib/design_system/`, `lib/components/buttons`, `lib/components/chips` | 비교적 토큰화됨 |
| row/state/header 공용 컴포넌트 | 대체로 토큰화됨, 일부 legacy color helper 잔존 |
| `lib/widgets/company_news_summary_card.dart` | 직접 spacing/font/color 다수 |
| `lib/widgets/market_news_summary_card.dart` | 직접 spacing/font/color 다수 |
| `lib/pages/annual_asset_analysis_page.dart` | chart/layout 직접 수치 다수 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | custom analysis UI 수치 다수 |
| detail/form pages | 일부 직접 수치와 legacy palette 혼재 |

## Non-Goals

v1 통일화에서 하지 않는 것:

- 전체 화면 시각 리디자인
- 모든 `SizedBox`와 `EdgeInsets`를 무조건 제거
- chart geometry, canvas painter 내부 좌표, platform-required size까지 토큰화
- `MoneyfyPalette` 즉시 삭제
- 대규모 파일 이동 또는 public API 변경
- 기능별 UX 흐름 변경

허용되는 직접 수치:

- chart/canvas 계산용 geometry
- animation interpolation 내부 값
- platform/icon asset intrinsic size
- domain-specific fixed row height가 이미 문서화된 경우
- Flutter/M3 기본 API에서 의도를 명확히 하는 0, 1, 2 같은 최소값

## Compatibility Promise

- 사용자-facing 기능은 변경하지 않습니다.
- 표시 값, 계산, DB, sync, route 구조는 변경하지 않습니다.
- 시각적 변화는 토큰 기준에 맞춘 작은 정렬/색상/간격 조정으로 제한합니다.
- 각 batch는 독립적으로 리뷰/테스트 가능해야 합니다.
- 기존 사용자 변경 파일은 되돌리지 않습니다.

## Canonical Rules

새 코드와 리팩터링된 코드는 아래 기준을 따릅니다.

| 기존 패턴 | 대체 기준 |
| --- | --- |
| `MoneyfyPalette.primary` | `Theme.of(context).colorScheme.primary` 또는 `context.colors.primary` |
| `MoneyfyPalette.surface` | `context.colors.neutralSurfaceBase` 또는 `SectionCard` |
| `MoneyfyPalette.positive/negative` | `context.colors.positiveOn/negativeOn` |
| `MoneyfyPalette.successBg/errorBg` | `context.colors.positiveContainer/negativeContainer` |
| `fontSize:` | `context.typography.*` 또는 필요한 경우 `context.fontSizes.*` |
| `SizedBox(height: 10)` | nearest `context.spacing.*` |
| `EdgeInsets.all(14)` | `context.spacing.*`, `context.cardPadding()`, component padding |
| `BorderRadius.circular(16)` | `context.radius.*` or `VisualSpec.surface.radiusCard` |
| ad-hoc cards | `SectionCard`, `DetailHeaderCard`, `StatusCard`, state components |

## Workstreams

세부 실행 계획은 stage별 문서로 분리합니다.

| Stage | 문서 | 목적 |
| --- | --- | --- |
| 00 | [Coverage Matrix](plan_parts/00_coverage_matrix.md) | 전체 UI-bearing file과 design asset의 stage 배정 확인 |
| 01 | [Audit And Guardrails](plan_parts/01_audit_and_guardrails.md) | legacy 패턴 현황을 수치화하고 soft/hard guardrail 기준 확정 |
| 02 | [Component Layer](plan_parts/02_component_layer.md) | 작은 공용 컴포넌트부터 토큰 기준으로 정리 |
| 03 | [News And Analysis Cards](plan_parts/03_news_and_analysis_cards.md) | 뉴스 카드와 분석 entry 영역의 직접 수치 제거 |
| 04 | [Analysis Page Family](plan_parts/04_analysis_page_family.md) | 분석 페이지 family의 card/row/chip/legend 통일 |
| 05 | [Detail And Form Pages](plan_parts/05_detail_and_form_pages.md) | 상세/폼 화면의 header, row, CTA, form spacing 통일 |
| 06 | [Remaining App Surfaces](plan_parts/06_remaining_app_surfaces.md) | shell, auth, home, portfolio, transaction, statistics, account, overlay 통일 |
| 07 | [Legacy Token Retirement](plan_parts/07_legacy_token_retirement.md) | legacy token 축소와 CI/문서 guardrail 단계화 |

## Suggested Batch Order

권장 batch:

1. audit snapshot과 soft guardrail
2. 작은 공용 row/chip/card 보조 컴포넌트
3. 뉴스 요약 카드
4. 분석 페이지 family
5. detail/form pages
6. remaining app surfaces
7. legacy guardrail hardening

각 batch는 작게 유지합니다. 한 batch에서 3~6개 파일 이상을 넘기면 visual QA와 리뷰 부담이 커집니다.

## Target Example Screens

토큰 사용이 비교적 좋은 기준 샘플:

| 화면/컴포넌트 | 이유 |
| --- | --- |
| `lib/pages/investment_performance_page.dart` | 최근 리디자인에서 `context.colors`, `context.typography`, `context.spacing`, `SectionCard` 중심으로 구성 |
| `lib/components/buttons/app_buttons.dart` | button token, loading width, pill radius, semantic overlay 기준 |
| `lib/components/chips/delta_chip.dart` | semantic positive/negative roles와 compact chip 규칙 적용 |
| `lib/components/rows/transaction_row.dart` | row slot, trailing width, typography token 사용 기준 |

새 batch는 위 파일들의 문법을 우선 참고합니다.

## Verification Plan

### Audit Commands

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib --glob "*.dart"
```

토큰 사용 확인:

```bash
rg -n "context\\.spacing|context\\.radius|context\\.typography|context\\.colors|VisualSpec|colorScheme" lib --glob "*.dart"
```

### Static Checks

파일 단위:

```bash
flutter analyze <changed files>
```

넓은 batch:

```bash
flutter analyze lib/design_system lib/components lib/widgets lib/pages
```

### Automated Tests

공용 UI:

```bash
flutter test test/ui_component_smoke_test.dart
```

화면 진입 영향:

```bash
flutter test test/page_walkthrough_test.dart
```

넓은 영향:

```bash
flutter test
```

### Manual QA

각 batch에서 확인합니다.

- 360dp, 390dp, 430dp, tablet-ish width에서 overlap 없음
- light/dark mode에서 positive/negative/status 색상 가독성 유지
- text scale 1.0 / 1.3에서 trailing amount, chip, button text가 깨지지 않음
- row height와 trailing alignment가 유지됨
- chart/canvas가 빈 화면이 되지 않음
- form CTA와 keyboard/safe area가 겹치지 않음

## Risks

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 시각 회귀 | 숫자는 같지만 spacing/color가 달라져 화면 인상이 바뀔 수 있음 | batch별 screenshot/manual QA |
| 과도한 기계 치환 | chart geometry나 특수 layout까지 토큰화하면 깨질 수 있음 | 예외 기준 유지 |
| legacy helper 의존 | `moneyfyValueColor` 같은 helper가 `MoneyfyPalette`에 묶여 있음 | helper를 대체하거나 compatibility로 유지 |
| 테스트 미감지 | widget smoke는 미세 시각 차이를 잡지 못함 | 주요 화면 수동 QA와 추후 golden |
| 범위 팽창 | 리디자인과 토큰 통일이 섞일 수 있음 | user-facing layout 변경은 별도 feature plan으로 분리 |

## Rollback Notes

- 각 batch는 독립 commit 단위로 나눌 수 있어야 합니다.
- 시각 회귀가 발생하면 해당 batch만 되돌립니다.
- `docs/design_system.md`의 canonical token 규칙은 되돌리지 않습니다.
- 계산/DB/sync와 무관한 작업이므로 data rollback은 필요하지 않습니다.

## Follow-Up Candidates

- 디자인 토큰 사용 grep을 CI check로 추가
- 주요 화면 golden test harness 추가
- `MoneyfyPalette` compatibility layer 축소
- chart/analysis component library 분리
- typography role coverage 보강
