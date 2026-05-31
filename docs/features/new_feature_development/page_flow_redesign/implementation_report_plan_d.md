# Plan D Implementation Report

## 상태

- 완료일: 2026-05-30
- 상태: 구현 완료
- 다음 계획 자동 착수: 하지 않음

## 구현 범위

### D1. 명칭 통일

- 사용자 노출 대표명을 `포트폴리오 진단`으로 통일했다.
- 홈 카드, 포트폴리오 탭 진단 카드, 상세 화면의 주요 title/button에서 `AI 포트폴리오 분석` 표현을 제거했다.
- fallback suggestion의 재생성 안내도 `포트폴리오 진단` 표현으로 맞췄다.

### D2. 홈 인사이트 진입점 정리

- 홈 인사이트 preview는 더 이상 포트폴리오 탭 하단 진단 카드로 focus 이동하지 않는다.
- 홈 preview는 Plan C의 `openPortfolioDiagnosis()` helper를 통해 `PortfolioAnalysisMvpPage` 상세 진단으로 바로 이동한다.
- 기존 focus tick 상태와 `PortfolioPage.diagnosisFocusTick` 연결을 제거했다.

### D3. 포트폴리오 탭 생성 카드 역할 정리

- 포트폴리오 탭 진단 카드 title을 `포트폴리오 진단`으로 변경했다.
- 생성 전 문구와 버튼을 `포트폴리오 진단 생성`으로 정리했다.
- 생성 완료 상태에서 primary button은 `진단 새로 생성`으로 유지하고, secondary action으로 `상세 진단 보기`를 추가했다.
- 진단 출처 캡션을 `진단 출처: AI 모델` / `진단 출처: 규칙 기반`으로 정리했다.

### D4. 상세 진단 화면 문구 정리

- `PortfolioAnalysisMvpPage` subtitle을 상세 진단 성격에 맞게 조정했다.
- 자산 없음 empty state에서 내부 표현 `MVP 분석 구성`을 제거했다.
- class/file rename은 하지 않았다.

### D5. 상태 처리 위치

| 상태 | 처리 위치 |
| --- | --- |
| 자산 없음 | `PortfolioAnalysisMvpPage` empty state |
| 진단 캐시 없음 | `PortfolioPage._PortfolioDiagnosisSectionCard`의 생성 CTA |
| 생성 중 | `PortfolioPage._PortfolioDiagnosisSectionCard`의 loading button |
| 생성 완료 | `PortfolioPage._PortfolioDiagnosisSectionCard` summary/score/출처/생성일/재생성/상세 보기 |
| fallback 결과 | `PortfolioPage._PortfolioDiagnosisSectionCard` 출처 캡션, `PortfolioDiagnosisService` fallback 문구 |

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/pages/app_shell_page.dart` | 홈 진단 preview 진입을 상세 화면 push로 변경, focus tick 제거 |
| `lib/pages/portfolio_dashboard_page.dart` | 홈 인사이트 카드 title을 `포트폴리오 진단`으로 변경 |
| `lib/pages/portfolio_page.dart` | 진단 카드 명칭, 생성/재생성/상세 보기 액션 정리 |
| `lib/pages/portfolio_analysis_mvp_page.dart` | 상세 화면 subtitle과 empty state 문구 정리 |
| `lib/services/portfolio_diagnosis_service.dart` | fallback suggestion 문구 정리 |
| `docs/page_inventory_graph.md` | 진단 진입 그래프 갱신 |
| `docs/features/new_feature_development/page_flow_redesign/route_matrix.md` | Plan D 목적지 확정 내용 반영 |

## 범위 밖 미착수 확인

- 진단 알고리즘 변경: 미착수
- `PortfolioDiagnosisService` fetch/cache 정책 변경: 미착수
- Supabase edge function 변경: 미착수
- `go_router`/`MaterialApp.router` 전환: 미착수
- 분석/통계 탭 통합: 미착수
- 5탭 통합: 미착수
- form route 변경: 미착수
- GPT용 DB 요약 복사 기능 위치 변경: 미착수

## 후속 후보

- `PortfolioAnalysisMvpPage` class/file name은 상세 진단 역할에 맞춰 별도 리네임할 수 있지만, Plan D에서는 import churn을 피하기 위해 보류했다.
- `page_walkthrough_test.dart`의 앱 셸 탭 key 탐색 실패는 별도 테스트 안정화 작업으로 확인한다.
