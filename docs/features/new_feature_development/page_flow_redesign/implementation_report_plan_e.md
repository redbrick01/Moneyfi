# Plan E Implementation Report

## 상태

- 완료일: 2026-05-30
- 상태: 구현 완료
- 다음 계획 자동 착수: 하지 않음

## 구현 범위

### E1. 분석 탭 역할 문구 정리

- `AnalysisPage`에 해석/성과/수입 중심 subtitle을 추가했다.
- 투자성과 분석 subtitle을 `실현손익 · 순투자성과 · 성과 기여`로 정리했다.
- 배당/이자 분석 subtitle을 `월별 수입 · 연 총합 · 종목별 수입`으로 정리했다.
- 분석 탭의 스냅샷 캘린더는 `스냅샷 참고 캘린더`와 `기록 기반 참고 지표` 표현으로 보조 진입임을 드러냈다.
- 분석 탭의 연도별 자산분석 카드에는 `통계 기준 연도별 비교` 표현을 추가했다.

### E2. 통계 탭 역할 문구 정리

- `StatisticsPage`에 `스냅샷과 기록을 기준으로 자산 흐름을 확인합니다.` subtitle을 추가했다.
- 월별 총자산 변화 섹션에 `월별 스냅샷 기록으로 총자산 흐름을 비교해요.` 설명을 추가했다.
- 연도별 자산 분석 설명을 `스냅샷 기록을 연도 단위로 비교해요.`로 정리했다.
- 스냅샷 캘린더에 `날짜별 저장 기록과 거래 흔적을 확인해요.` 설명을 추가했다.

### E3. 소속 기준 문서화

- `SnapshotDetailPage`의 primary 소속을 통계로 기록했다.
- `AnnualAssetAnalysisPage`의 primary 소속을 통계로 기록했다.
- 분석 탭의 스냅샷/연도별 진입은 보조 진입으로 유지했다.

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/pages/analysis_page.dart` | 분석 탭 subtitle, entry subtitle, 스냅샷/연도별 보조 진입 문구 정리 |
| `lib/pages/statistics_page.dart` | 통계 탭 subtitle, 월별/연도별/캘린더 설명 정리 |
| `lib/pages/annual_asset_analysis_page.dart` | title 띄어쓰기 정리 |
| `docs/page_inventory_graph.md` | 분석 보조 진입과 통계 primary 진입 구분 |
| `docs/features/new_feature_development/page_flow_redesign/route_matrix.md` | Snapshot/Annual primary 소속 기록 |
| `docs/features/new_feature_development/page_flow_redesign/test_coverage_matrix.md` | Plan E 검증 기준 보강 |

## 유지한 진입점

- `AnalysisPage` -> `PortfolioAnalysisMvpPage`
- `AnalysisPage` -> `InvestmentPerformancePage`
- `AnalysisPage` -> `DividendInterestAnalysisPage`
- `AnalysisPage` -> `SnapshotDetailPage`
- `AnalysisPage` -> `AnnualAssetAnalysisPage`
- `StatisticsPage` -> `SnapshotDetailPage`
- `StatisticsPage` -> `AnnualAssetAnalysisPage`

## 범위 밖 미착수 확인

- 5탭 통합: 미착수
- `StatisticsPage` 제거: 미착수
- `AnalysisPage`의 스냅샷/연도별 진입 삭제: 미착수
- `SnapshotDetailPage` loader/생성자 리팩터: 미착수
- `AnnualAssetAnalysisPage` loader/생성자 리팩터: 미착수
- 투자성과/배당/이자 계산 로직 변경: 미착수
- 뉴스 fetch/cache 정책 변경: 미착수
- `go_router`/`MaterialApp.router` 전환: 미착수

## 후속 후보

- Plan H 또는 별도 IA 결정에서 분석 탭의 스냅샷 보조 진입을 유지할지 제거할지 결정한다.
- `page_walkthrough_test.dart`의 앱 셸 탭 key 탐색 실패는 별도 테스트 안정화 작업으로 확인한다.
