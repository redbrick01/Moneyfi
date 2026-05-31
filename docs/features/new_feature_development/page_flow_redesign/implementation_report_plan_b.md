# Plan B Implementation Report

## 상태

- 완료일: 2026-05-30
- 상태: 구현 완료
- 다음 계획 자동 착수: 하지 않음

## 구현 범위

### B1. 포트폴리오 탭 자산 상세 진입

- `PortfolioPage`에서 `AssetDetailPage`를 열 수 있는 상세 진입 콜백을 추가했다.
- `AllocationLegendRow`의 기존 탭 동작은 선택 토글로 유지했다.
- 각 비중 row의 trailing icon button을 통해 자산 상세로 진입한다.
- 상세에서 돌아오면 `_pageFuture = _loadPortfolioPageData()`로 포트폴리오 데이터를 다시 불러온다.

### B2. 거래 탭 계좌 없음 empty CTA

- 거래 데이터와 계좌가 모두 없는 상태에서도 `EmptyStateCard`에 `자산 추가` CTA가 표시되도록 했다.
- CTA는 `AssetFormPage`를 열고, 저장 결과가 `true`면 거래 탭 데이터를 다시 불러온다.
- 계좌가 있는 거래 empty state는 기존처럼 `거래 추가` CTA를 유지한다.

### B3. 포트폴리오 빈 상태 문구 수정

- 포트폴리오 빈 상태 설명에서 `Home` 직접 언급을 제거했다.
- 사용자는 현재 탭의 `자산 추가` 버튼으로 바로 다음 행동을 할 수 있다.

### B4. My 탭 GPT용 DB 요약 복사 정돈

- 기능은 My 탭에 그대로 유지했다.
- title을 `GPT용 DB 요약 복사`로 변경했다.
- subtitle을 `포트폴리오 분석에 쓸 요약 데이터를 클립보드에 복사해요`로 변경했다.
- 성공 snackbar를 `GPT용 DB 요약을 클립보드에 복사했어요.`로 변경했다.
- 복사 payload 구조는 변경하지 않았다.

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/pages/portfolio_page.dart` | 자산 상세 진입, 상세 복귀 후 reload, 포트폴리오 빈 상태 문구 수정 |
| `lib/pages/transactions_page.dart` | 계좌 없음 거래 empty state의 `자산 추가` CTA 추가 |
| `lib/pages/my_page.dart` | GPT용 DB 요약 복사 title/subtitle/snackbar 정돈 |
| `docs/features/new_feature_development/page_flow_redesign/plans/02_plan_b_ux_quick_wins.md` | 완료 체크리스트 갱신 |
| `docs/features/new_feature_development/page_flow_redesign/test_report_plan_b.md` | 검증 결과 기록 |

## 범위 밖 미착수 확인

- route registry 추가: 미착수
- `go_router` 도입: 미착수
- 5탭 통합: 미착수
- 포트폴리오 진단 상세 구조 변경: 미착수
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage`, form edit route, transaction form route 변경: 미착수

## 후속 후보

- 거래 탭에서 첫 자산 추가 후 보유 종목/현금 계좌 생성까지 안내하는 온보딩은 Plan F 범위로 남긴다.
- 앱 셸 워크스루 테스트의 `bottom-tab-홈` 탐색 실패는 Plan B 범위 밖 검증 이슈로 별도 확인이 필요하다.
