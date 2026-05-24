# Portfolio Diagnosis Temporary Development Report

이 문서는 `포트폴리오 진단` 리디자인 첫 개발 batch 결과를 검증 계획 수립용으로 요약합니다.

## Summary

`포트폴리오 MVP 분석` 사용자 노출 명칭을 `포트폴리오 진단`으로 바꾸고, 기존 기능 나열형 화면 위에 진단 요약과 주의 항목을 추가했습니다. 리밸런싱 섹션은 `조정 제안`으로 재구성해 목표 대비 축소 후보, 확대 후보, 정상 범위를 점검 정보로 보여주도록 바꿨습니다.

## Implemented Stages

| Stage | Status | Notes |
| --- | --- | --- |
| Documentation | Done | feature plan과 temporary execution plan 작성 |
| Entry rename | Done | 분석 탭 카드명을 `포트폴리오 진단`으로 변경 |
| Page rename | Done | 페이지 title/subtitle에서 MVP와 테스트 문구 제거 |
| Diagnosis header | Done | 상태 배지, 대표 문장, 핵심 지표 4개 추가 |
| Attention items | Done | 집중도, 최대 낙폭, 목표 비중 이탈, 성과 영향, 상위 1개 비중 추가 |
| Adjustment suggestions | Done | 리밸런싱을 조정 후보 UX로 변경 |
| Gauge alignment polish | Done | MDD/HHI 기준선, 마커, 기준값 라벨 정렬 보정 |
| Walkthrough test | Done | 분석 탭에서 포트폴리오 진단 진입 검증 추가 |

## Changed Files

| File | Change |
| --- | --- |
| `docs/features/new_feature_development/portfolio_diagnosis/plan.md` | 리디자인 계획서 작성 |
| `docs/features/new_feature_development/portfolio_diagnosis/tmp_execution_plan.md` | 임시 실행 계획 작성 후 검증 완료 단계에서 삭제 |
| `docs/README.md` | 영구 계획서 링크 추가 |
| `lib/pages/analysis_page.dart` | 분석 탭 진입 카드 문구 변경 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | 진단 요약, 주의 항목, 조정 제안 UX 추가 |
| `test/page_walkthrough_test.dart` | 포트폴리오 진단 진입 테스트 추가 |

## Data Layer Changes

DB, Drift query, Supabase Edge Function, sync 로직 변경은 없습니다.

새로 추가한 계산은 화면 내부 파생값입니다.

- 상위 3개 비중
- HHI score
- 목표 비중 최대 이탈
- 진단 상태 분류
- 주의 항목 리스트

## UI Changes

- `포트폴리오 MVP 분석`을 사용자-facing `포트폴리오 진단`으로 변경했습니다.
- 상단에 `진단 요약`을 배치했습니다.
- 기능 설명 문장 대신 상태 해석 문장을 먼저 보여줍니다.
- `주의가 필요한 항목` 섹션을 추가했습니다.
- `목표 비중 리밸런싱`을 `조정 제안`으로 이름과 문구를 바꿨습니다.
- `매수/매도`가 아니라 `축소 후보`, `확대 후보`, `정상 범위` 표현을 사용했습니다.
- 조정 제안 막대는 가운데 0선을 기준으로 부족/초과 방향이 갈라지도록 수정했습니다.
- HHI 게이지의 `1,000`, `1,800` 라벨은 서로 겹치지 않도록 기준선과 라벨을 분리하고 세로 위치를 엇갈리게 배치했습니다.
- MDD 게이지의 `5%`, `15%`, `30%` 기준값도 트랙 아래 독립 라벨 레이어로 분리했습니다.

## Tests Added Or Updated

- `test/page_walkthrough_test.dart`
  - 분석 탭에서 `포트폴리오 진단` 카드를 열 수 있는지 확인합니다.

## Verification Results So Far

Baseline before implementation:

```bash
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result: passed.

Implementation check:

```bash
flutter analyze lib/pages/analysis_page.dart lib/pages/portfolio_analysis_mvp_page.dart test/page_walkthrough_test.dart
flutter test test/page_walkthrough_test.dart
```

Result: passed.

Gauge polish check:

```bash
flutter analyze lib/pages/portfolio_analysis_mvp_page.dart
flutter test test/page_walkthrough_test.dart
```

Result: passed.

## Known Limitations

- 상세 분석 접힘 구조는 이번 batch에서 구현하지 않았습니다.
- 기간 선택은 없습니다.
- AI 기반 자연어 진단은 없습니다.
- 실제 반응형 시각 QA는 아직 수행하지 않았습니다.
- 기존 파일명 `portfolio_analysis_mvp_page.dart`와 클래스명 `PortfolioAnalysisMvpPage`는 호환성 유지를 위해 유지했습니다.

## Risk Notes

- 기존 화면 파일에 legacy `MoneyfyPalette` 사용이 많아 이번 batch도 같은 화면 내부 스타일 체계를 이어받았습니다. 추후 화면 분리 또는 design-system 전환 batch에서 정리하는 것이 좋습니다.
- 진단 상태 기준은 제품 검증 전 초기 규칙입니다. 실제 사용자 데이터로 기준값 조정이 필요할 수 있습니다.

## Follow-Up Items

- 실제 기기에서 MDD/HHI 게이지 시각 QA
- 상세 분석 영역 접힘 처리
- 성과 원인 영역을 `무엇이 자산을 움직였나요?` 흐름으로 통합
- 모바일 폭에서 긴 자산명과 큰 금액 시각 QA
- 기간 선택 추가
- AI 진단 문장 연결 검토
