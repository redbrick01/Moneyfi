# Design Token Unification Verification Test Plan

작성일: 2026-05-29

## Scope

이 검증 계획은 디자인 토큰 통일화 batch마다 적용합니다. 목표는 사용자 기능을 유지하면서 색상, 폰트, 간격, 반경, 상태 표현이 `docs/design_system.md`와 `lib/design_system/` 기준으로 수렴하는지 확인하는 것입니다.

## Required Checks Per Batch

각 stage는 아래 세부 계획을 함께 따릅니다.

- [01 Audit And Guardrails](plan_parts/01_audit_and_guardrails.md)
- [02 Component Layer](plan_parts/02_component_layer.md)
- [03 News And Analysis Cards](plan_parts/03_news_and_analysis_cards.md)
- [04 Analysis Page Family](plan_parts/04_analysis_page_family.md)
- [05 Detail And Form Pages](plan_parts/05_detail_and_form_pages.md)
- [06 Remaining App Surfaces](plan_parts/06_remaining_app_surfaces.md)
- [07 Legacy Token Retirement](plan_parts/07_legacy_token_retirement.md)

### 1. Static Analysis

변경 파일 단위:

```bash
flutter analyze <changed files>
```

공용 컴포넌트 또는 넓은 UI batch:

```bash
flutter analyze lib/design_system lib/components lib/widgets lib/pages
```

### 2. Focused Widget Tests

공용 UI 컴포넌트를 바꾼 경우:

```bash
flutter test test/ui_component_smoke_test.dart
```

화면 진입, section title, empty/error/loading 문구에 영향이 있는 경우:

```bash
flutter test test/page_walkthrough_test.dart
```

### 3. Full Test Escalation

아래 중 하나에 해당하면 전체 테스트를 실행합니다.

- 공용 component API 변경
- `MoneyfyPage`, `SectionCard`, row component, form component 변경
- 여러 page family에 걸친 batch
- analyzer는 통과했지만 widget smoke에서 layout warning이 있었던 경우

```bash
flutter test
```

## Manual QA Matrix

| 항목 | 확인 |
| --- | --- |
| Width 360dp | 버튼, chip, trailing amount overlap 없음 |
| Width 390/430dp | 기본 모바일 레이아웃 안정 |
| Tablet-ish width | card/grid spacing 과밀 또는 과도한 stretch 없음 |
| Text scale 1.3 | 긴 금액, 긴 한글 label, chip text 깨짐 없음 |
| Light mode | neutral surface ladder와 status color 가독성 |
| Dark mode | status container 과채도/저대비 없음 |
| Loading state | skeleton 또는 placeholder가 layout shape 유지 |
| Empty state | 안내 문구와 CTA hierarchy 유지 |
| Error state | `InlineError + RetryRow` 또는 section-level error 유지 |
| Form page | keyboard/safe area/CTA overlap 없음 |
| Chart page | chart nonblank, label overlap 없음 |

## Audit Reports

각 batch test report에는 아래를 기록합니다.

- 변경한 파일
- 제거한 legacy 패턴 수 또는 대표 예
- 의도적으로 남긴 예외
- 실행한 analyzer/test 명령
- 수동 QA 결과
- 남은 리스크

## Acceptance Criteria

- 변경 batch가 `docs/design_system.md`의 canonical rules를 따릅니다.
- 신규 direct hex, 신규 `MoneyfyPalette` 사용, 신규 arbitrary font size가 늘지 않습니다.
- 사용자-facing 기능, 계산, DB, sync 동작이 바뀌지 않습니다.
- 관련 analyzer/test가 통과합니다.
- 수동 QA에서 overlap, unreadable color, unstable row alignment가 발견되지 않습니다.
