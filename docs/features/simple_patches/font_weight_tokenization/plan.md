# Font Weight Tokenization Plan

작성일: 2026-05-30

## 목표

MONEYFY의 `FontWeight.w400/w500/w600/w700` 직접 참조를 디자인 시스템 토큰으로 관리하고, design-md 기준을 벗어나기 쉬운 `w800/w900` 사용처는 제거 또는 예외 문서화 대상으로 분리한다.

이번 계획은 폰트 패밀리, 폰트 사이즈, 색상, spacing을 다시 조정하는 작업이 아니다. SUIT 적용 상태를 유지하면서, 굵기만 design-md의 typography weight 기준에 맞춰 중앙화한다.

## Design-md 근거

`docs/design_system.md`의 typography hierarchy는 다음 weight를 명시한다.

| Design-md role | Weight | 의미 |
| --- | ---: | --- |
| Display / title-lg | 400 | 큰 제목은 차분한 regular weight 유지 |
| title-md / title-sm | 600 | 컴포넌트 제목, 리스트 primary |
| body-md / body-sm / caption | 400 | 일반 본문과 보조 텍스트 |
| body-strong | 700 | 강조 본문 |
| caption-strong | 600 | badge, pill label |
| number-display | 500 | 숫자 표기, tabular numeric |
| button | 600 | CTA button |
| nav-link | 500 | navigation label |

핵심 원칙:

- display weight는 400을 유지한다.
- 일반 body/caption은 400을 기본값으로 둔다.
- UI label, button, component title은 600을 기본 강조값으로 둔다.
- 숫자 role은 500을 우선 기준으로 둔다.
- 700 이상은 명확한 강조 목적이 있을 때만 제한적으로 사용한다.

## 현재 상태

| 항목 | 현재 |
| --- | --- |
| Font family token | `AppFontFamilies` 존재 |
| Font size token | `AppFontSizes` 존재 |
| Font weight token | 없음 |
| Typography role weight | `AppTypography` 내부에서 `FontWeight.w400/w500/w600` 직접 지정 |
| Legacy theme weight | `MoneyfyTheme` 내부에서 직접 지정 |
| 컴포넌트/page override | `fontWeight: FontWeight.w600/w700/w800` 직접 사용 다수 |
| Guardrail | font family/font size 직접 사용은 점검하나 font weight는 아직 점검하지 않음 |

## 현재 직접 참조 분포

필수 점검 명령:

```bash
rg -n "FontWeight\\.w|fontWeight:" lib test pubspec.yaml
```

2026-05-30 기준 관찰:

| 위치 | 경향 |
| --- | --- |
| `lib/design_system/app_typography.dart` | role 기준 weight 직접 선언 |
| `lib/design_system/app_theme.dart` | navigation label 등 theme-level override |
| `lib/theme/moneyfy_theme.dart` | legacy theme weight 직접 선언 |
| `lib/components/**` | row primary, chip, badge, status text에 `w600` 다수 |
| `lib/pages/**` | 화면별 selected state, section label, amount, chart label에 `w600/w700/w800` 다수 |
| `test/**` | 직접 weight 사용은 거의 없거나 검증 대상 아님 |

## 범위

### 포함

- font weight token 추가.
- `AppTypography`, `AppTheme`, `MoneyfyTheme`의 weight를 token 참조로 전환.
- 공통 컴포넌트의 반복 weight override를 token 참조로 전환.
- 주요 페이지의 의미가 명확한 weight override를 token 참조로 전환.
- `w800` 등 design-md 기준을 벗어난 강한 weight 사용처를 점검하고, 유지/완화 근거를 기록.
- guardrail에 font weight 직접 참조 리포트 추가.

### 제외

- 폰트 패밀리 재선정.
- 폰트 사이즈/line-height/letter-spacing 재설계.
- 모든 `copyWith(fontWeight: ...)` 제거를 한 번에 강제.
- Flutter SDK 내부, generated DB code, test fixture까지 강제 토큰화.
- Golden diff 도입.
- 이미지 artifact 재생성 및 이미지 기반 검증.

## 토큰 설계

권장 위치:

- 새 파일: `lib/design_system/font_weights.dart`
- 또는 typography 관련 토큰을 모으는 파일이 생기면 해당 파일로 이동

권장 형태:

```dart
import 'package:flutter/material.dart';

class AppFontWeights {
  const AppFontWeights._();

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
}
```

적용 의미:

| Token | 값 | 사용 기준 |
| --- | ---: | --- |
| `regular` | 400 | display, body, caption, unselected state |
| `medium` | 500 | nav label, subtle emphasis, 숫자 role 후보 |
| `semibold` | 600 | section/card title, button, chip selected, row primary |
| `bold` | 700 | body-strong, high-priority selected state, 강한 score/grade |

숫자 role은 한 번에 단정하지 않는다. 큰 금액 hero, row 금액, 작은 metric 숫자를 audit 단계에서 분리하고, SUIT의 실제 weight asset 등록 상태와 overflow 위험을 함께 확인한다. `w800`은 기본 토큰에 넣지 않는다. 필요하다면 `extraBold`를 바로 추가하지 말고 사용처별로 design-md 위반 여부를 먼저 판단한다.

## Font Asset Weight 매칭

현재 font asset 등록 상태를 기준으로 token 사용 가능 범위를 같이 관리한다.

| Family | 등록 weight | token 사용 원칙 |
| --- | --- | --- |
| SUIT | 400, 500, 600, 700 | `regular/medium/semibold/bold` 사용 가능 |

완료 시 `pubspec.yaml`의 weight 등록과 `AppFontWeights` 값이 충돌하지 않는지 확인한다.

## 예상 수정 파일

| 파일 | 작업 |
| --- | --- |
| `lib/design_system/font_weights.dart` | `AppFontWeights` token 추가 |
| `lib/design_system/app_typography.dart` | role weight를 token 참조로 변경 |
| `lib/design_system/app_theme.dart` | theme-level weight override를 token 참조로 변경 |
| `lib/theme/moneyfy_theme.dart` | legacy theme weight를 token 참조로 변경 |
| `lib/components/**` | 공통 컴포넌트의 반복 weight override 전환 |
| `lib/pages/**` | 주요 화면의 의미 명확한 override 전환 |
| `tools/check_design_token_guardrails.sh` | 직접 `FontWeight.w...` 리포트 추가 |
| `docs/features/simple_patches/font_weight_tokenization/*` | 구현 보고서와 예외 목록 작성 |

## 하드코딩 / 독립 weight 점검

폰트 weight 토큰화의 완료 조건은 token 파일을 만드는 것이 아니라, 굵기 정책이 역할별 의미를 갖고 추적 가능해지는 것이다.

### 점검 대상

| 대상 | 점검 내용 |
| --- | --- |
| `lib/design_system/**` | token 정의 파일 외 직접 `FontWeight.w...`가 남는지 |
| `lib/theme/**` | legacy theme가 token을 우회하는지 |
| `lib/components/**` | row/chip/button/card label weight가 token 의미와 맞는지 |
| `lib/pages/**` | 화면별 selected/amount/chart label weight override가 token 의미와 맞는지 |
| `test/**` | test 전용 widget이 독립 weight 정책을 갖는지 |
| generated code | `lib/db/app_database.g.dart` 등은 검색에서 제외 가능 |

### 필수 검색 명령

```bash
rg -n "FontWeight\\.w|fontWeight:" lib test pubspec.yaml
rg -n "FontWeight\\.w800|FontWeight\\.w900" lib test
rg -n -P "fontWeight: (?!AppFontWeights)" lib --glob "*.dart"
```

마지막 명령은 PCRE lookahead가 필요한 환경에서 `-P`를 사용한다. 미지원 환경에서는 첫 번째 검색 결과를 수동 분류한다.

### 허용 예외

| 예외 | 조건 |
| --- | --- |
| `lib/design_system/font_weights.dart` | token 정의를 위해 직접 `FontWeight.w...` 선언 가능 |
| 외부/generated code | Drift generated file 등 사람이 직접 관리하지 않는 파일 |
| 임시 미전환 페이지 | 구현 단계 중 예외 목록에 파일/라인/사유를 기록한 경우 |
| Flutter 기본 API | `FontWeight.values` 같은 enum/utility 접근이 생기면 별도 검토 |

## 단계별 구현 순서

| 단계 | 작업 | 산출물 |
| ---: | --- | --- |
| 1 | 직접 weight 사용처 전수 검색 및 분류 | `weight_audit.md` |
| 2 | `AppFontWeights` token 추가 | `lib/design_system/font_weights.dart` |
| 3 | `AppTypography`, `AppTheme`, `MoneyfyTheme` 전환 | 핵심 typography role weight 중앙화 |
| 4 | 의미 없는 조건부 weight 정리 | `isSelected ? w600 : w600` 같은 no-op 제거 |
| 5 | 공통 컴포넌트 전환 | `lib/components/**` 직접 weight 감소 |
| 6 | 주요 페이지 전환 | dashboard, transactions, detail, analysis 주요 weight token화 |
| 7 | `w700/w800` 강한 weight 사용처 검토 | 유지/완화 결정과 예외 목록 |
| 8 | guardrail 보강 | 직접 `FontWeight.w...` 리포트 및 self-test |
| 9 | 구현 보고서 작성 | `implementation_report.md` |

## 우선순위

| 우선순위 | 대상 | 이유 |
| --- | --- | --- |
| P0 | `AppTypography`, `AppTheme`, `MoneyfyTheme` | 앱 전역 typography contract |
| P0 | 거래 페이지 검색/필터/row 관련 weight | 사용자가 체감한 폰트 적용 영역이며 design-md compliance 핵심 화면 |
| P1 | 공통 rows/chips/cards/components | 여러 화면에 퍼지는 반복 UI |
| P1 | dashboard/detail/analysis 주요 숫자와 label | 주요 화면과 공통 typography 영향 범위 |
| P2 | 페이지 내부의 희소한 특수 label | 시각 영향이 좁고 예외 판단 가능 |
| P2 | `w800` 사용처 | 강한 강조가 필요한지 별도 UX 판단 필요 |

## 검증 방법

```bash
dart format lib/design_system/font_weights.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart
flutter analyze lib/design_system/font_weights.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart
tools/check_design_token_guardrails.sh
tools/check_design_token_guardrails.sh --self-test
rg -n "FontWeight\\.w|fontWeight:" lib test pubspec.yaml
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

수동 확인:

- 거래 페이지 상단 제목, 검색창, 필터 버튼, quick filter chip.
- 360/390/430dp에서 selected chip이 과하게 진해 보이지 않는지.
- 숫자 role이 SUIT + medium weight에서 깨지거나 뭉개지지 않는지.
- `w700`을 유지한 강조 텍스트가 design-md의 calm tone을 깨지 않는지.
- dark mode에서 semibold/bold 텍스트가 번져 보이지 않는지.

## 완료 기준

- `AppFontWeights` token이 존재하고 `regular/medium/semibold/bold`를 제공한다.
- `AppTypography`의 모든 `fontWeight`가 `AppFontWeights.*`를 사용한다.
- `AppTheme`, `MoneyfyTheme`의 직접 `FontWeight.w...`가 제거된다.
- `pubspec.yaml`에 등록된 SUIT weight와 token 사용처가 충돌하지 않는다.
- 공통 컴포넌트의 반복적인 `FontWeight.w600/w700`이 token 참조로 전환된다.
- 의미 없는 조건부 weight 표현이 제거된다.
- 남은 직접 `FontWeight.w...`는 generated/외부/명시 예외 목록으로만 설명된다.
- `w800/w900` 사용처는 제거되거나 명확한 예외 사유가 문서화된다.
- guardrail self-test가 직접 font weight 회귀를 탐지한다.
- analyze, guardrail, UI smoke, page walkthrough, full test가 통과한다.

## 리스크와 주의사항

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 시각 밀도 변화 | `w700/w800`을 낮추면 일부 카드/차트의 강조가 약해질 수 있음 | 주요 화면 수동 확인과 walkthrough test |
| 과도한 guardrail | 모든 `FontWeight.w...`를 즉시 실패 처리하면 특수 케이스 개발이 막힐 수 있음 | 1차는 리포트형, P0/P1 완료 후 `design_system/theme/components`만 실패형으로 승격 |
| SUIT weight 체감 차이 | SF Pro 대비 SUIT의 semibold가 더 진하게 보일 수 있음 | `semibold` 사용처를 role 기준으로 재검토 |
| selected state 혼선 | 선택 상태에 `w700`을 쓰던 UI가 `semibold`로 약해질 수 있음 | selected는 색/배경/icon과 함께 판단 |
| legacy theme drift | `MoneyfyTheme`가 남아 일부 화면이 다른 weight 정책 사용 가능 | legacy theme도 token 참조로 전환 |

## 커밋 권장 단위

1. `docs: plan font weight tokenization`
2. `docs: add font weight audit report`
3. `feat: add font weight tokens`
4. `refactor: tokenize typography weights`
5. `refactor: tokenize component font weights`
