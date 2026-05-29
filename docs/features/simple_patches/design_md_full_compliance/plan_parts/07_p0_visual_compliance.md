# 07 P0 Visual Compliance

## 목표

Stage 06 screenshot harness로 생성한 P0 모바일 화면을 기준으로 실제 design-md 위반을 수정한다.

## 대상

| 영역 | 대상 |
| --- | --- |
| P0 shell/tab | `app_shell_data_390dp_ts1_0.png` |
| P0 transactions | `transactions_data_390dp_ts1_0.png`, `transactions_overflow_risk_360dp_ts1_3.png` |
| P0 forms | `transaction_form_keyboard_risk_360dp_ts1_3.png` |
| P0 detail | `asset_detail_data_390dp_ts1_0.png` |
| Shared scaffold | `lib/ui_scaffold/app_page_scaffold.dart` |
| Harness fidelity | `test/design_md_screenshot_harness_test.dart` |

## 구현 작업

1. P0 screenshot artifact가 실제 한글/아이콘 glyph로 렌더링되는지 확인한다.
2. standalone route와 pushed/detail 화면의 background가 design-md app background를 칠하는지 확인한다.
3. P0 form에서 primary action이 아닌 icon tool button이 과하게 강조되지 않는지 확인한다.
4. 360dp + text scale 1.3 overflow-risk screenshot에서 title/action/input/button overlap을 확인한다.
5. 수정 후 screenshot artifact를 재생성하고 결과를 문서화한다.

## 완료 기준

- P0 screenshot harness가 한글/Material icon을 정상 렌더링한다.
- standalone AppPageScaffold 화면이 검은 fallback background에 노출되지 않는다.
- secondary/tool icon button이 primary CTA보다 강한 filled treatment를 사용하지 않는다.
- 360dp + text scale 1.3 P0 후보가 overflow exception 없이 capture된다.
- `flutter analyze`, screenshot harness, guardrail, P0 walkthrough가 통과한다.
