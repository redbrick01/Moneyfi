# Plan H-Impl. 5탭 Shell 통합

## 역할

Plan H에서 결정한 5탭 통합을 실제 코드에 반영한다.

이 계획은 Plan H의 결정 산출물에 따른 별도 구현 계획이며, 사용자 승인 전에는 착수하지 않는다.

## 목표

하단 탭을 `홈`, `포트폴`, `거래`, `분석`, `My` 5개로 줄이고, 기존 `통계` 기능은 `분석` 영역의 진입점과 `/statistics` 호환 route로 보존한다.

## 범위

- `AppShellPage` destination에서 `통계` 탭 제거.
- `/statistics` route는 유지한다.
- `/statistics` 직접 진입 시 shell selected tab은 `분석`으로 매핑한다.
- `AnalysisPage`에 통계 진입 섹션 또는 compact entry를 추가한다.
- `StatisticsPage`는 기능 제거 없이 유지한다.
- router/page walkthrough/widget 테스트를 5탭 기준으로 갱신한다.

## 제외

- `StatisticsPage` 대규모 UI 재설계.
- snapshot detail id 기반 loader 전환.
- annual analysis id/period 기반 loader 전환.
- form named route 전환.
- My 탭 또는 `내부 DB 요약 복사 (GPT)` 기능 이동.
- auth redirect 정책 추가.

## 구현 단계

### H-Impl 1. Shell destination 축소

목표:

- 하단 탭을 5개로 줄인다.

구현:

- `AppShellPage._destinations`에서 `통계` 항목을 제거한다.
- `IndexedStack`에서 `StatisticsPage`를 하단 탭 child에서 제거한다.
- scroll controller index 매핑을 5탭 기준으로 정리한다.

완료 조건:

- 하단 탭 key가 `홈`, `포트폴`, `거래`, `분석`, `My` 5개만 존재한다.
- 기존 5개 탭의 selected state와 재탭 동작이 유지된다.

### H-Impl 2. `/statistics` 호환 route 보존

목표:

- 기존 `/statistics` 직접 진입을 깨지 않는다.

구현:

- router에서 `/statistics` route를 유지한다.
- `/statistics` 진입 시 `StatisticsPage`를 표시하되, shell selected tab은 `분석`으로 처리한다.
- 필요하면 `AppShellPage`가 `overrideBody` 또는 route mode를 받을 수 있게 한다.

완료 조건:

- `/statistics` 직접 진입이 동작한다.
- `/statistics` 화면에서도 하단 탭은 `분석`이 selected로 보인다.
- `MoneyfyRouteNames.statistics`와 `MoneyfyRoutePaths.statistics`는 삭제하지 않는다.

### H-Impl 3. 분석 탭 통계 진입점 추가

목표:

- 통계 탭 제거로 줄어든 발견성을 분석 탭에서 보완한다.

구현:

- `AnalysisPage`에 `통계`, `월말 스냅샷`, `연도별 분석` 성격의 진입점을 추가한다.
- 진입점은 `/statistics` route로 이동한다.
- 기존 투자성과/배당/이자/진단 진입점은 유지한다.

완료 조건:

- 분석 탭에서 통계 화면으로 이동할 수 있다.
- 통계 기능이 숨겨졌다는 느낌이 들지 않도록 화면 상단 또는 주요 card group에 배치한다.

### H-Impl 4. 테스트 갱신

목표:

- 5탭 구조와 `/statistics` 호환성을 자동 테스트로 보장한다.

필수:

- `flutter analyze`
- `flutter test test/router_smoke_test.dart`
- `flutter test test/page_walkthrough_test.dart`
- `flutter test test/widget_test.dart`

권장:

- `flutter test test/transaction_flow_test.dart`

완료 조건:

- router smoke가 5탭 직접 route와 `/statistics` 호환 route를 모두 확인한다.
- walkthrough가 `통계` 하단 탭을 기대하지 않는다.
- 분석 탭에서 통계 진입점 이동이 확인된다.

### H-Impl 5. 문서/리포트

목표:

- 실제 구현 결과와 남은 리스크를 기록한다.

산출물:

- `implementation_report_plan_h_impl.md`
- `test_report_plan_h_impl.md`
- `route_matrix.md` Plan H-Impl 적용 결과 갱신
- `test_coverage_matrix.md` 검증 결과 갱신
- `plan.md` 상태 갱신

완료 조건:

- 구현 범위와 제외 범위가 문서화된다.
- Plan I는 자동으로 시작하지 않는다.

## 중단 조건

- `/statistics` 호환 route를 유지하려면 snapshot loader 또는 statistics 대규모 재설계가 필요해지는 경우.
- 분석 탭이 과밀해져 통계 진입점이 오히려 더 찾기 어려워지는 경우.
- 5탭 전환 중 form route 또는 My 탭 기능 이동이 필요해지는 경우.

중단 조건을 만나면 구현을 확대하지 않고 보류 리포트를 작성한다.
