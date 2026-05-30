# Font Family Tokenization Implementation Report

작성일: 2026-05-30

## 요약

폰트 패밀리를 직접 문자열이 아니라 `AppFontFamilies` 토큰으로 관리하도록 구현했다.

앱 기본 sans/display와 숫자 강조 role을 모두 SUIT로 전환했다. 기존 `.SF Pro Text`, `.SF Pro Display` 직접 참조는 앱 코드와 screenshot harness에서 제거했다.

## 구현 내용

| 항목 | 결과 |
| --- | --- |
| Font family token | `lib/design_system/font_families.dart`에 `AppFontFamilies.sans/display/mono` 추가 |
| Typography role | `AppTypography`의 모든 `fontFamily`가 token 참조로 전환 |
| Theme 기본 family | `AppTheme`, legacy `MoneyfyTheme` 모두 `AppFontFamilies.sans` 사용 |
| 숫자 강조 role | `heroNumber`의 `AppFontFamilies.mono`도 SUIT를 참조하도록 전환 |
| Font asset | SUIT 400/500/600/700 추가 |
| Font license/source | `assets/fonts/**/LICENSE.txt`, `assets/fonts/README.md` 추가 |
| Screenshot harness | macOS system font alias 대신 `FontLoader(AppFontFamilies.sans/mono)` 사용 |
| Guardrail | 직접/legacy font family 문자열 탐지 rule과 self-test 추가 |
| Screenshot artifact | design-md after screenshot 20개를 token font 렌더링으로 재생성 |

## 후속 수정

| 일자 | 내용 |
| --- | --- |
| 2026-05-30 | `heroNumber`의 이전 mono 렌더링에서 원화 기호가 깨지는 문제를 막기 위해 임시 fallback을 추가했다. |
| 2026-05-30 | 앱 sans/display font를 이전 한글 sans asset에서 SUIT로 교체하고, 미사용 이전 sans asset은 제거했다. |
| 2026-05-30 | 숫자 role도 SUIT로 통일하고, 미사용 mono asset과 pubspec font 등록 및 임시 fallback을 제거했다. |

## Font Asset 출처

| Family | Source | License |
| --- | --- | --- |
| SUIT | https://github.com/sun-typeface/SUIT/tree/main/fonts/static/ttf | SIL Open Font License 1.1 |

## 하드코딩 / 독립 폰트 점검 결과

실행 명령:

```bash
rg -n "fontFamily|fontFamilyFallback|FontLoader|\\.SF Pro|SUIT|Inter|JetBrains|Geist|Pretendard|Noto|Roboto|AppleSDGothic|sans-serif|monospace" lib test pubspec.yaml
rg -n "\\.SF Pro Text|\\.SF Pro Display|fontFamily: ['\"]|fontFamilyFallback: ['\"]" lib test
```

결과:

| 구분 | 결과 |
| --- | --- |
| `.SF Pro Text`, `.SF Pro Display` | 0건 |
| `fontFamily: '...'` 직접 문자열 | 0건 |
| `fontFamilyFallback: '...'` 직접 문자열 | 0건 |
| 앱 코드 font family | `AppFontFamilies.*` 참조만 남음 |
| test font loader | `FontLoader(family)`로 token 전달. `MaterialIcons` loader는 icon font 예외 |
| `pubspec.yaml` family | `SUIT`로 token 값과 일치 |

## 검증 결과

| 명령 | 결과 |
| --- | --- |
| `dart format lib/design_system/font_families.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart test/design_md_screenshot_harness_test.dart` | 통과 |
| `flutter analyze lib/design_system/font_families.dart lib/design_system/app_typography.dart lib/design_system/app_theme.dart lib/theme/moneyfy_theme.dart test/design_md_screenshot_harness_test.dart` | 통과 |
| `tools/check_design_token_guardrails.sh` | 통과 |
| `tools/check_design_token_guardrails.sh --self-test` | 통과 |
| `flutter test test/ui_component_smoke_test.dart` | 통과, 7 tests |
| `flutter test test/design_md_screenshot_harness_test.dart` | 통과, 21 tests |
| `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart` | 통과, 21 tests 및 screenshot 재생성 |
| `flutter test` | 통과, 214 tests |
| `flutter analyze lib/design_system/app_typography.dart lib/theme/moneyfy_theme.dart` | 후속 원화 fallback 수정 후 통과 |
| `flutter test test/ui_component_smoke_test.dart` | 후속 원화 fallback 수정 후 통과, 7 tests |
| `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart` | 후속 원화 fallback 수정 후 통과, 21 tests 및 screenshot 재생성 |

## 완료 기준 확인

| 완료 기준 | 상태 |
| --- | --- |
| 앱 코드의 직접 `.SF Pro Text`, `.SF Pro Display` 참조 제거 | 완료 |
| 모든 font family 참조가 `AppFontFamilies` token 경유 | 완료 |
| 하드코딩/독립 폰트 검색 결과가 허용 예외만 남음 | 완료 |
| `pubspec.yaml`에 SUIT asset 등록 | 완료 |
| 숫자 강조 role이 mono family 사용 | 완료 |
| screenshot harness가 SUIT token font를 로드 | 완료 |
| analyze, guardrail, screenshot harness, full test 통과 | 완료 |

## 리스크와 주의사항

| 리스크 | 상태 / 대응 |
| --- | --- |
| Bundle size 증가 | SUIT TTF 4개를 포함한다. 현재 필요한 weight만 등록했지만, 배포 크기 민감도가 높아지면 subset 검토 필요 |
| 숫자 폭 변화 | 숫자 role도 SUIT로 통일했다. mono 폭 고정 효과는 사라지므로 금액 column alignment는 주요 화면에서 계속 확인 필요 |
| FontLoader weight 매핑 | test `FontLoader`는 family 단위 로딩이다. 실제 앱 weight 매핑은 `pubspec.yaml`이 담당하고, screenshot harness는 렌더링 smoke 목적 |
| MaterialIcons 예외 | screenshot harness의 `FontLoader('MaterialIcons')`는 아이콘 렌더링용 예외로 유지 |

## 후속 권장

- 실제 iOS/Android 빌드에서 bundle size와 첫 화면 렌더링을 확인한다.
- 금액 row 전체에 mono를 확대 적용할지 별도 visual audit로 판단한다.
