# Design Token Unification Plan

작성일: 2026-05-29

## Patch Goal

MONEYFY UI 코드 색상, 폰트, 여백, 간격, 반경, 상태 표현을 공통 디자인 시스템 토큰으로 점진 통일.

새 디자인 아님. 이미 있는 `docs/design_system.md`, `lib/design_system/` 토큰을 코드 전반에 일관 적용. 유지보수성 + 시각 일관성 높임.

## Current Baseline

공통 시스템 이미 있음.

| 영역 | 공통 기준 |
| --- | --- |
| 색상/표면 | `VisualSpec`, `BrandColors`, `ColorScheme` |
| 폰트 | `context.typography`, `AppTypography` |
| 여백/간격 | `context.spacing`, `context.cardPadding()` |
| 반경 | `context.radius`, `VisualSpec.surface.radiusCard` |
| 모션 | `context.motion`, `VisualSpec.motion` |
| 컴포넌트 | `SectionCard`, `AssetRow`, `TransactionRow`, `DeltaChip`, `AppButtons`, state components |
| 문서 기준 | `docs/design_system.md` |

오래된 화면/일부 위젯에 개별 수치 남음.

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
| `lib/design_system/`, `lib/components/buttons`, `lib/components/chips` | 꽤 토큰화 |
| row/state/header 공용 컴포넌트 | 대체로 토큰화, 일부 legacy color helper 남음 |
| `lib/widgets/company_news_summary_card.dart` | 직접 spacing/font/color 많음 |
| `lib/widgets/market_news_summary_card.dart` | 직접 spacing/font/color 많음 |
| `lib/pages/annual_asset_analysis_page.dart` | chart/layout 직접 수치 많음 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | custom analysis UI 수치 많음 |
| detail/form pages | 직접 수치 + legacy palette 섞임 |

## Non-Goals

v1에서 안 함:

- 전체 화면 시각 리디자인
- 모든 `SizedBox`와 `EdgeInsets` 강제 제거
- chart geometry, canvas painter 내부 좌표, platform-required size까지 토큰화
- `MoneyfyPalette` 즉시 삭제
- 대규모 파일 이동 또는 public API 변경
- 기능별 UX 흐름 변경

허용 직접 수치:

- chart/canvas 계산용 geometry
- animation interpolation 내부 값
- platform/icon asset intrinsic size
- domain-specific fixed row height가 이미 문서화된 경우
- Flutter/M3 기본 API에서 의도 명확한 0, 1, 2 같은 최소값

## Compatibility Promise

- 사용자-facing 기능 변경 없음.
- 표시 값, 계산, DB, sync, route 구조 변경 없음.
- 시각 변화는 토큰 기준 작은 정렬/색상/간격 조정만.
- 각 batch 독립 리뷰/테스트 가능.
- 기존 사용자 변경 파일 되돌리지 않음.

## Canonical Rules

새 코드/리팩터링 코드 기준:

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

세부 계획은 stage별 문서로 분리.

| Stage | 문서 | 목적 |
| --- | --- | --- |
| 00 | Coverage Matrix | 전체 UI-bearing file + design asset stage 배정 확인 |
| 01 | Audit And Guardrails | legacy 패턴 수치화, soft/hard guardrail 기준 확정 |
| 02 | Component Layer | 작은 공용 컴포넌트부터 토큰 정리 |
| 03 | News And Analysis Cards | 뉴스 카드 + 분석 entry 직접 수치 제거 |
| 04 | Analysis Page Family | 분석 페이지 family card/row/chip/legend 통일 |
| 05 | Detail And Form Pages | 상세/폼 header, row, CTA, form spacing 통일 |
| 06 | Remaining App Surfaces | shell, auth, home, portfolio, transaction, statistics, account, overlay 통일 |
| 07 | Legacy Token Retirement | legacy token 축소 + CI/문서 guardrail 단계화 |
| 08 | 카드/패널 시각 문법 통일 | 토큰 연결 후 카드/패널 표면 위계 + 시각 문법 통일 |

## Suggested Batch Order

권장 batch:

1. audit snapshot과 soft guardrail
2. 작은 공용 row/chip/card 보조 컴포넌트
3. 뉴스 요약 카드
4. 분석 페이지 family
5. detail/form pages
6. remaining app surfaces
7. legacy guardrail hardening

각 batch 작게. 한 batch 3~6개 파일 넘으면 visual QA/리뷰 부담 큼.

## Target Example Screens

토큰 사용 좋은 기준 샘플:

| 화면/컴포넌트 | 이유 |
| --- | --- |
| `lib/pages/investment_performance_page.dart` | 최근 리디자인. `context.colors`, `context.typography`, `context.spacing`, `SectionCard` 중심 |
| `lib/components/buttons/app_buttons.dart` | button token, loading width, pill radius, semantic overlay 기준 |
| `lib/components/chips/delta_chip.dart` | semantic positive/negative roles + compact chip 규칙 |
| `lib/components/rows/transaction_row.dart` | row slot, trailing width, typography token 기준 |

새 batch는 위 파일 문법 우선 참고.

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

각 batch 확인:

- 360dp, 390dp, 430dp, tablet-ish width에서 overlap 없음
- light/dark mode에서 positive/negative/status 색상 가독성 유지
- text scale 1.0 / 1.3에서 trailing amount, chip, button text 안 깨짐
- row height와 trailing alignment 유지
- chart/canvas 빈 화면 아님
- form CTA와 keyboard/safe area 안 겹침

## Risks

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 시각 회귀 | 숫자 같아도 spacing/color 달라 화면 인상 바뀜 | batch별 screenshot/manual QA |
| 과도한 기계 치환 | chart geometry나 특수 layout까지 토큰화하면 깨짐 | 예외 기준 유지 |
| legacy helper 의존 | `moneyfyValueColor` 같은 helper가 `MoneyfyPalette`에 묶임 | helper 대체하거나 compatibility 유지 |
| 테스트 미감지 | widget smoke는 미세 시각 차이 못 잡음 | 주요 화면 수동 QA + 추후 golden |
| 범위 팽창 | 리디자인과 토큰 통일 섞일 수 있음 | user-facing layout 변경은 별도 feature plan |

## Rollback Notes

- 각 batch는 독립 commit 단위 가능해야 함.
- 시각 회귀 발생 시 해당 batch만 revert.
- `docs/design_system.md` canonical token 규칙은 revert 안 함.
- 계산/DB/sync 무관 작업. data rollback 불필요.

## Follow-Up Candidates

- 디자인 토큰 사용 grep을 CI check로 추가
- 주요 화면 golden test harness 추가
- `MoneyfyPalette` compatibility layer 축소
- chart/analysis component library 분리
- typography role coverage 보강

## 세부 문서 병합 요약

### 핵심 계획

- coverage matrix로 UI, non-UI, design asset/native surface 범위 먼저 분리.
- audit/guardrail은 soft check 시작. 예외 + compatibility layer 줄인 뒤 hard guardrail 전환.
- component layer → news/analysis cards → analysis family → detail/form pages → remaining app surfaces 순서로 token migration.
- legacy token retirement는 직접 색상/spacing/type helper 줄임. compatibility layer는 안정화 전까지 보수 유지.
- card/panel visual grammar는 L1 section card, L2 inner panel, L3 metric tile, temporary floating surface 구분.

### 구현/테스트 결과

- Batch 02A-02D와 Stage 03A-07 follow-up까지 단계별 test report 작성.
- Stage 08A-08E는 card/panel visual grammar 적용. panel/card token audit로 canonical component와 남은 직접 container surface 구분.
- pill/chip/badge token 작업은 상태/필터/태그 계열 컴포넌트를 token role 기준 정리.
- pre-implementation check는 legacy pattern snapshot, first implementation scope, required verification 고정.

### 검증 핵심

- 각 batch는 `flutter analyze`, focused widget tests, 필요 시 `flutter test`로 escalated verification 수행.
- manual QA는 360/390/430dp, tablet-ish width, light/dark, text scale 1.3, row/trailing alignment, chart nonblank, form safe area 확인.
- 남은 risk는 visual regression, over-mechanical replacement, legacy helper dependency, screenshot/golden 부족.