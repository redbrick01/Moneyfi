# 06 Screenshot Harness

## 목표

Stage 00-05에서 등록한 screenshot/golden 후보를 실제 Flutter widget test에서 재현 가능한 PNG capture 흐름으로 연결한다.

## 대상

| 영역 | 대상 |
| --- | --- |
| Test | `test/design_md_screenshot_harness_test.dart` |
| Artifacts | `docs/features/simple_patches/design_md_full_compliance/screenshots/after/*.png` |
| Docs | `audit_matrix.md`, `verification_test_plan.md`, `manual_notes/stage_06_screenshot_harness.md` |

## 구현 작업

1. Flutter widget test에서 360/390dp viewport를 강제한다.
2. text scale 1.0/1.3 후보를 분리한다.
3. P0/P1 대표 화면을 별도 screenshot case로 정의한다.
4. 평소 `flutter test`에서는 파일을 쓰지 않고 smoke만 수행한다.
5. `MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1`일 때만 PNG를 `screenshots/after/`에 생성한다.
6. screenshot harness가 아직 보장하지 못하는 영역을 문서화한다.

## Capture 후보

| 후보 | 폭 | textScale | 목적 |
| --- | ---: | ---: | --- |
| app shell | 390dp | 1.0 | floating tab/nav shell |
| dashboard | 390dp | 1.0 | home hierarchy |
| transactions | 390dp | 1.0 | row/badge/filter density |
| transactions overflow-risk | 360dp | 1.3 | text overflow risk |
| transaction form keyboard-risk | 360dp | 1.3 | form density/focus state |
| asset detail | 390dp | 1.0 | detail header/metrics |
| analysis hub | 390dp | 1.0 | P1 entry cards/news |
| portfolio diagnosis MVP | 390dp | 1.0 | status cards/long copy |
| statistics | 390dp | 1.0 | chart/table density |
| company news card | 390dp | 1.0 | long Korean news copy |
| market news card | 390dp | 1.0 | issue badge/card density |

## 실행

Smoke only:

```bash
flutter test test/design_md_screenshot_harness_test.dart
```

PNG capture:

```bash
MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS=1 flutter test test/design_md_screenshot_harness_test.dart
```

## 완료 기준

- screenshot harness smoke test가 통과한다.
- capture env를 켰을 때 PNG가 `screenshots/after/`에 생성된다.
- 최소 1개 360dp + text scale 1.3 후보가 포함된다.
- visual pass/fail을 자동 판정하지 않는 한계가 문서화된다.
