# Portfolio Diagnosis Verification Test Plan

이 문서는 `포트폴리오 진단` 리디자인 첫 batch의 검증 계획입니다.

## Scope

검증 대상:

- 분석 탭 진입 카드명 변경
- 포트폴리오 진단 화면 진입
- 진단 요약 섹션 렌더링
- 주의가 필요한 항목 섹션 렌더링
- 조정 제안 섹션 렌더링
- 기존 분석 탭의 투자성과, 배당/이자 진입 회귀

검증 제외:

- DB migration
- Supabase function
- sync 동작
- 실제 주문 또는 리밸런싱 실행
- AI 진단 생성

## Quality Goals

| Goal | Criteria |
| --- | --- |
| Navigation safety | 분석 탭에서 포트폴리오 진단, 투자성과, 배당/이자 화면 진입이 깨지지 않음 |
| Copy quality | 사용자에게 MVP/테스트 화면 문구가 노출되지 않음 |
| Data safety | 기존 DB/API 계약 변경 없이 화면이 렌더링됨 |
| UI stability | 주요 컴포넌트 smoke test가 통과함 |
| Static quality | `flutter analyze`가 통과함 |

## Automated Test Plan

필수 실행:

```bash
flutter analyze
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

권장 전체 회귀:

```bash
flutter test
```

## Manual QA Plan

수동 확인 항목:

- 분석 탭 카드가 `포트폴리오 진단`으로 보이는지 확인합니다.
- 포트폴리오 진단 화면 상단에서 `진단 요약`이 먼저 보이는지 확인합니다.
- 자산이 없는 상태에서 빈 상태가 정상 표시되는지 확인합니다.
- 목표 비중이 없는 상태에서 `조정 제안`만 안내 상태로 보이는지 확인합니다.
- 스냅샷이 부족해도 전체 화면이 실패하지 않는지 확인합니다.
- `MVP`, `테스트 화면` 문구가 사용자 화면에 보이지 않는지 확인합니다.
- 다크 모드에서 상태 배지가 과도하게 튀지 않는지 확인합니다.

## Responsive Checklist

- 360dp 이하 폭에서 진단 문장이 잘리지 않는지 확인합니다.
- 긴 자산명이 조정 제안 row에서 금액과 겹치지 않는지 확인합니다.
- 큰 금액이 지표 카드 내부에서 parent width를 밀지 않는지 확인합니다.
- 주의 항목의 trailing 수치가 본문을 침범하지 않는지 확인합니다.

## Regression Test Commands

```bash
flutter analyze
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
flutter test
```

## Acceptance Criteria

| Criteria | Expected |
| --- | --- |
| Static analysis | No issues |
| Page walkthrough | All tests pass |
| UI component smoke | All tests pass |
| Full flutter test | All tests pass or known unrelated failures documented |
| Documentation | plan, verification plan, test report linked from `docs/README.md` |
| Temporary cleanup | `tmp_execution_plan.md` deleted after verification |

## Release Risk Matrix

| Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- |
| 진단 기준 과도/부족 | Medium | Medium | 문서에 초기 기준임을 명시하고 후속 데이터 검증 |
| UI overflow | Medium | Medium | FittedBox와 maxLines 사용, 수동 QA 항목으로 추적 |
| 기존 분석 탭 회귀 | High | Low | walkthrough test로 진입 검증 |
| 데이터 계산 회귀 | Medium | Low | DB/API 변경 없음 |

## Future Test Expansion

- 진단 기준 unit test 분리
- mock asset data로 진단 요약 문구 widget test 추가
- 모바일/태블릿 golden 또는 screenshot regression 추가
- 목표 비중 설정 여부별 조정 제안 fixture test 추가
