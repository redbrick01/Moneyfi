# Font Family Tokenization Plan

작성일: 2026-05-30

## 목표

MONEYFY의 폰트 패밀리를 문자열 직접 참조가 아니라 디자인 시스템 토큰으로 관리한다.

이번 계획은 폰트 사이즈, 색상, spacing을 다시 조정하는 작업이 아니다. 이미 정리된 typography role과 size scale은 유지하고, `fontFamily`만 중앙 토큰으로 분리해 선택 폰트로 교체 가능하게 만든다.

## 선택 폰트

| 역할 | 폰트 | 용도 |
| --- | --- | --- |
| Sans | SUIT | 일반 본문, 제목, 버튼, chip, label |
| Display | SUIT | page title, section title, hero/summary title |
| Mono | SUIT | 금액, 수익률, 비율, 수량, tabular numeric role |

## 현재 상태

| 항목 | 현재 |
| --- | --- |
| App typography role | `lib/design_system/app_typography.dart`의 `AppTypography`에서 관리 |
| Font size token | `lib/design_system/tokens.dart`의 `AppFontSizes`에서 관리 |
| Font family token | 없음 |
| 실제 font family | `.SF Pro Display`, `.SF Pro Text` 직접 문자열 |
| Theme 기본 family | `AppTheme`, legacy `MoneyfyTheme`에서 직접 문자열 |
| pubspec font asset | 미등록 |
| screenshot harness font | macOS Korean system font를 `.SF Pro Text`, `.SF Pro Display`로 임시 로드 |

## 범위

### 포함

- 폰트 패밀리 토큰 추가.
- `AppTypography`와 `AppTheme`의 font family 참조를 토큰으로 전환.
- legacy `MoneyfyTheme`의 font family 참조를 토큰으로 전환.
- `pubspec.yaml`에 SUIT font asset 등록.
- screenshot harness가 새 font family를 로드하도록 변경.
- typography 관련 guardrail 또는 검색 기준 보강.

### 제외

- Typography size scale 재설계.
- 화면별 layout redesign.
- 색상/spacing/radius token 변경.
- Coinbase 전용 licensed font 사용.
- Golden diff 도입.

## 토큰 설계

권장 위치:

- 새 파일: `lib/design_system/font_families.dart`
- 또는 기존 `lib/design_system/tokens.dart`에 `AppFontFamilies` 추가

권장 형태:

```dart
class AppFontFamilies {
  const AppFontFamilies._();

  static const sans = 'SUIT';
  static const display = 'SUIT';
  static const mono = 'SUIT';
}
```

적용 원칙:

- `ThemeData.fontFamily`: `AppFontFamilies.sans`
- Page/title/body/button/caption role: `AppFontFamilies.sans` 또는 `display`
- 금액/수익률/비중/수량 role: `AppFontFamilies.mono`
- `FontFeature.tabularFigures()`는 유지한다. Mono font가 적용되지 않는 환경에서도 숫자 폭 안정성을 보조한다.

## 예상 수정 파일

| 파일 | 작업 |
| --- | --- |
| `lib/design_system/font_families.dart` | font family token 추가 |
| `lib/design_system/app_typography.dart` | 직접 font family 문자열 제거, token 참조 |
| `lib/design_system/app_theme.dart` | `ThemeData.fontFamily` token 참조 |
| `lib/theme/moneyfy_theme.dart` | legacy theme font family token 참조 |
| `pubspec.yaml` | font asset 등록 |
| `test/design_md_screenshot_harness_test.dart` | SUIT / Mono font load |
| `tools/check_design_token_guardrails.sh` | 직접 `.SF Pro` 문자열 탐지 후보 추가 |

## 하드코딩 / 독립 폰트 점검

폰트 토큰화 작업의 핵심 완료 조건은 특정 폰트를 등록하는 것이 아니라, 앱 전체에서 font family가 독립적으로 흩어져 있지 않음을 증명하는 것이다.

### 점검 대상

| 대상 | 점검 내용 |
| --- | --- |
| `lib/**` | `fontFamily`, `fontFamilyFallback`, `TextStyle(fontFamily: ...)` 직접 문자열 |
| `test/**` | screenshot/test 전용 font loader가 앱 토큰과 다른 family를 쓰는지 |
| `pubspec.yaml` | 등록된 font family 이름과 `AppFontFamilies` token 값 불일치 |
| `docs/**` | 구현 문서가 실제 token name과 다른 family를 안내하는지 |
| legacy theme | `lib/theme/moneyfy_theme.dart`가 새 token을 우회하는지 |
| platform/native | Android/iOS/web manifest가 font를 직접 지정하지는 않지만, launch/native text가 생기면 별도 점검 |

### 필수 검색 명령

```bash
rg -n "fontFamily|fontFamilyFallback|FontLoader|\\.SF Pro|SUIT|Inter|JetBrains|Geist|Pretendard|Noto|Roboto|AppleSDGothic|sans-serif|monospace" lib test pubspec.yaml
rg -n "fontFamily|FontLoader|\\.SF Pro|SUIT|Inter|JetBrains|Geist|Pretendard|Noto|Roboto|AppleSDGothic" docs/features/simple_patches docs/design_system.md
```

### 허용되는 예외

| 예외 | 조건 |
| --- | --- |
| `docs/design_system.md` | 원본 design-md 분석 문서이므로 Coinbase/Inter/JetBrains 대체 설명 유지 가능 |
| font token 정의 파일 | `AppFontFamilies` 안에서만 family string 직접 선언 가능 |
| `pubspec.yaml` | Flutter font 등록을 위해 family name 직접 선언 가능. 단 token 값과 일치해야 함 |
| screenshot harness | `FontLoader(AppFontFamilies.sans/display/mono)`처럼 token을 참조해야 함 |

### 통과 기준

- `lib/**`에서 `fontFamily:` 직접 문자열은 `AppFontFamilies.*` 참조만 남는다.
- `.SF Pro Text`, `.SF Pro Display` 문자열은 앱 코드에서 0건이다.
- screenshot harness가 앱 token과 다른 family alias를 만들지 않는다.
- `pubspec.yaml`의 family name과 `AppFontFamilies` 값이 문서에 기록된 이름과 일치한다.
- guardrail self-test가 font-family 직접 문자열 회귀를 탐지한다.

## Font Asset 배치안

```text
assets/fonts/
  suit/
    SUIT-Regular.ttf
    SUIT-Medium.ttf
    SUIT-SemiBold.ttf
    SUIT-Bold.ttf
```

`pubspec.yaml` 등록 예:

```yaml
flutter:
  fonts:
    - family: SUIT
      fonts:
        - asset: assets/fonts/suit/SUIT-Regular.ttf
          weight: 400
        - asset: assets/fonts/suit/SUIT-Medium.ttf
          weight: 500
        - asset: assets/fonts/suit/SUIT-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/suit/SUIT-Bold.ttf
          weight: 700
```

## 단계별 구현 순서

| 단계 | 작업 | 산출물 |
| ---: | --- | --- |
| 1 | SUIT font asset 확보 및 라이선스 확인 | `assets/fonts/**`, 라이선스 메모 |
| 2 | `AppFontFamilies` token 추가 | `font_families.dart` 또는 `tokens.dart` |
| 3 | `AppTypography`, `AppTheme`, `MoneyfyTheme` token 참조로 변경 | 직접 `.SF Pro` 문자열 제거 |
| 4 | 숫자 role에 mono family 적용 | `heroNumber`, amount row, metric numeric role 확인 |
| 5 | screenshot harness font loader 변경 | PNG artifact가 실제 font로 렌더링 |
| 6 | 하드코딩/독립 폰트 전수 점검 | 검색 결과와 예외 목록 |
| 7 | guardrail 보강 | 직접 font family 문자열 회귀 탐지 |
| 8 | screenshot 재생성 및 visual review | design-md screenshot artifact 업데이트 |

## 검증 방법

```bash
flutter analyze lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart test/design_md_screenshot_harness_test.dart
tools/check_design_token_guardrails.sh
rg -n "fontFamily|fontFamilyFallback|FontLoader|\\.SF Pro|SUIT|Inter|JetBrains|Geist|Pretendard|Noto|Roboto|AppleSDGothic|sans-serif|monospace" lib test pubspec.yaml
flutter test test/ui_component_smoke_test.dart
flutter test test/design_md_screenshot_harness_test.dart
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
flutter test
```

수동 확인:

- 360/390/430dp dashboard, transactions, detail, form screenshot.
- 긴 한글 종목명과 긴 원화 금액의 baseline alignment.
- SUIT 숫자 폭, line height, chip height 변화.
- 한글/영문/숫자 혼합 row에서 vertical alignment가 어색하지 않은지 확인.

## 완료 기준

- 앱 코드의 직접 `.SF Pro Text`, `.SF Pro Display` 참조가 제거됨.
- 모든 font family 참조가 `AppFontFamilies` token을 통한다.
- 하드코딩/독립 폰트 검색 결과가 허용 예외만 남긴다.
- `pubspec.yaml`에 SUIT asset이 등록됨.
- `AppTypography`의 숫자 role은 `AppFontFamilies.mono`를 사용한다.
- screenshot harness가 SUIT token font를 로드한다.
- `flutter analyze`, guardrail, UI smoke, screenshot harness, full `flutter test`가 통과한다.

## 리스크와 주의사항

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 폰트 파일 라이선스/출처 | 외부 폰트 파일을 repo에 포함해야 함 | SUIT 공식 배포물과 license 파일 포함 |
| 한글 line-height 변화 | SUIT는 SF Pro 대비 vertical metrics가 다를 수 있음 | screenshot harness로 주요 화면 재검수 |
| Mono 숫자 폭 증가 | 금액 column이 넓어져 row overflow 가능 | trailing slot, `FittedBox`, maxLines 확인 |
| 앱 크기 증가 | 폰트 asset 추가로 bundle size 증가 | 필요한 weight만 포함 |
| legacy theme drift | `MoneyfyTheme`가 남아 있어 일부 화면이 다른 family 사용 가능 | legacy theme도 token 참조로 통일 |

## 커밋 권장 단위

1. `docs: plan font family tokenization`
2. `feat: add SUIT font family tokens`
3. `chore: register SUIT font assets`
4. `test: refresh typography screenshot baselines`
