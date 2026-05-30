# Font Weight Audit

작성일: 2026-05-30

## 목적

`FontWeight.w...` 직접 참조를 design-md 기반 token으로 전환하기 전에 사용처를 분류하고, 구현 후 남은 예외를 확인한다.

## Design-md Weight 기준

| 의미 | Token | Weight |
| --- | --- | ---: |
| 일반 본문, caption, display title | `AppFontWeights.regular` | 400 |
| 숫자 role, nav/subtle emphasis | `AppFontWeights.medium` | 500 |
| component title, button, chip, row primary | `AppFontWeights.semibold` | 600 |
| body-strong, 강한 selected/score emphasis | `AppFontWeights.bold` | 700 |

`w800/w900`은 기본 token으로 만들지 않고 제거 또는 예외 문서화 대상으로 분류한다.

## 구현 전 관찰

실행 명령:

```bash
rg -n "FontWeight\\.w|fontWeight:" lib test pubspec.yaml
rg -n "FontWeight\\.w800|FontWeight\\.w900" lib test
```

관찰 결과:

| 범주 | 내용 |
| --- | --- |
| Core typography | `AppTypography`, `AppTheme`, `MoneyfyTheme`에 직접 `FontWeight.w400/w500/w600` 사용 |
| Components | row primary, chip, badge, expandable label, news card label에 `w600` 반복 |
| Pages | dashboard/detail/analysis/form 화면에 `w600/w700` 반복 |
| Strong weight | `portfolio_analysis_mvp_page.dart`에 `w800` 1건 |
| No-op conditional | `asset_detail_page.dart`, `portfolio_dashboard_page.dart`에 `isSelected ? w600 : w600` 2건 |

## 구현 후 점검

실행 명령:

```bash
rg -n "FontWeight\\.w[0-9]+" lib test --glob "*.dart" --glob "!lib/design_system/font_weights.dart"
rg -n "FontWeight\\.w800|FontWeight\\.w900" lib test
rg -o "AppFontWeights\\.[a-z]+" lib --glob "*.dart" | sed 's/.*AppFontWeights\\.//' | sort | uniq -c
```

결과:

| 점검 | 결과 |
| --- | --- |
| token 정의 파일 외 직접 `FontWeight.w...` | 0건 |
| `FontWeight.w800/w900` | 0건 |
| no-op conditional weight | 제거 |
| `AppFontWeights.regular` | 12건 |
| `AppFontWeights.medium` | 1건 |
| `AppFontWeights.semibold` | 147건 |
| `AppFontWeights.bold` | 19건 |

## 예외 및 판단

| 항목 | 판단 |
| --- | --- |
| `lib/design_system/font_weights.dart`의 직접 `FontWeight.w...` | token 정의 파일이므로 허용 |
| `AppFontWeights.bold` in `portfolio_analysis_mvp_page.dart` | 기존 `w700` 강조와 `w800` 1건을 design-md 범위의 `bold`로 통일 |
| Mono 숫자 role + bold | 없음. `heroNumber`는 `AppFontWeights.medium` 유지 |
| 조건부 token weight | selected/unselected 의미가 다른 곳은 token 조건부 표현 유지 |

## 결론

앱 코드의 직접 `FontWeight.w...` 참조는 token 정의 파일을 제외하고 제거되었다. `w800`은 별도 token으로 승격하지 않고 `AppFontWeights.bold`로 완화했다.
