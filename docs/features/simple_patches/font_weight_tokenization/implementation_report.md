# Font Weight Tokenization Implementation Report

작성일: 2026-05-30

## 요약

MONEYFY의 font weight 직접 참조를 `AppFontWeights` token으로 전환했다.

`regular/medium/semibold/bold`만 제공하며, design-md 범위 밖으로 강해지기 쉬운 `w800`은 별도 token으로 만들지 않고 `bold`로 완화했다. 스크린샷 artifact 재생성은 범위에서 제외했다.

## 구현 내용

| 항목 | 결과 |
| --- | --- |
| Font weight token | `lib/design_system/font_weights.dart`에 `AppFontWeights` 추가 |
| Token export | `context_extensions.dart`에서 `font_weights.dart` export |
| Typography role | `AppTypography`의 모든 `fontWeight`를 token 참조로 전환 |
| Theme | `AppTheme`, legacy `MoneyfyTheme`의 weight를 token 참조로 전환 |
| Components/pages | `lib/components/**`, `lib/pages/**`, `lib/widgets/**`의 직접 `FontWeight.w...`를 token 참조로 전환 |
| No-op conditional | `isSelected ? w600 : w600` 2건 제거 |
| Strong weight | `FontWeight.w800` 1건을 `AppFontWeights.bold`로 완화 |
| Guardrail | 직접 `FontWeight.w...` 탐지 rule과 self-test 추가 |
| Audit | `weight_audit.md` 작성 |

## Token 기준

| Token | Weight | 사용 기준 |
| --- | ---: | --- |
| `AppFontWeights.regular` | 400 | display, body, caption, unselected state |
| `AppFontWeights.medium` | 500 | 숫자 role, nav/subtle emphasis |
| `AppFontWeights.semibold` | 600 | title, button, chip, row primary |
| `AppFontWeights.bold` | 700 | strong emphasis, selected/score |

## Font Asset 매칭

| Family | 등록 weight | 구현 판단 |
| --- | --- | --- |
| SUIT | 400, 500, 600, 700 | 모든 token 사용 가능 |
| SUIT numeric role | 400, 500, 600, 700 | `heroNumber`는 `medium` 유지 |

## 하드코딩 점검 결과

실행 명령:

```bash
rg -n "FontWeight\\.w[0-9]+" lib test --glob "*.dart" --glob "!lib/design_system/font_weights.dart"
rg -n "FontWeight\\.w800|FontWeight\\.w900" lib test
```

결과:

| 점검 | 결과 |
| --- | --- |
| token 정의 파일 외 직접 `FontWeight.w...` | 0건 |
| `FontWeight.w800/w900` | 0건 |
| `font_weights.dart` 직접 `FontWeight.w...` | token 정의로 허용 |

## 검증 결과

아래 명령으로 검증했다.

| 명령 | 결과 |
| --- | --- |
| `dart format lib/design_system/font_weights.dart lib/design_system/context_extensions.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart ...` | 통과 |
| `flutter analyze lib/design_system/font_weights.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart lib/pages/transactions_page.dart lib/components/rows/transaction_row.dart` | 통과 |
| `tools/check_design_token_guardrails.sh` | 통과 |
| `tools/check_design_token_guardrails.sh --self-test` | 통과 |
| `flutter test test/ui_component_smoke_test.dart` | 통과, 7 tests |
| `flutter test test/page_walkthrough_test.dart` | 통과, 24 tests |
| `flutter analyze` | 통과 |
| `flutter test` | 통과, 214 tests |

## 완료 기준 확인

| 완료 기준 | 상태 |
| --- | --- |
| `AppFontWeights` token 추가 | 완료 |
| `AppTypography` 모든 weight token화 | 완료 |
| `AppTheme`, `MoneyfyTheme` 직접 `FontWeight.w...` 제거 | 완료 |
| SUIT asset weight와 token 사용처 충돌 없음 | 완료 |
| 공통 컴포넌트 반복 weight token화 | 완료 |
| 의미 없는 조건부 weight 제거 | 완료 |
| `w800/w900` 제거 또는 예외 문서화 | 완료 |
| guardrail self-test가 직접 font weight 회귀 탐지 | 완료 |

## 리스크와 주의사항

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 시각 밀도 변화 | 기존 `w800` 1건이 `bold`로 완화됨 | 주요 화면 수동 확인 |
| 조건부 weight 표현 | selected/unselected 상태는 token 조건부 표현으로 남음 | 직접 `FontWeight.w...`가 아니므로 허용 |
| export 의존 | 대부분 파일은 `context_extensions.dart` export로 token 접근 | 신규 파일은 `context_extensions.dart` 또는 `font_weights.dart` import 필요 |
