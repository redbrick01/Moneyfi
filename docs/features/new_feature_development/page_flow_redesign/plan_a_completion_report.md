# Plan A Completion Report

## 범위

Plan A. 기준선/의존성 매트릭스만 진행했다. 코드 변경, route helper 추가, `go_router` 의존성 추가, UI 변경은 하지 않았다.

## 산출물

- `docs/features/new_feature_development/page_flow_redesign/route_matrix.md`
- `docs/features/new_feature_development/page_flow_redesign/test_coverage_matrix.md`

## 완료 조건 확인

| 완료 조건 | 결과 |
| --- | --- |
| 모든 주요 페이지가 `direct push 가능`, `named route 가능`, `extra 필요`, `사전 리팩터 필요` 중 하나로 분류된다. | 완료. `route_matrix.md`의 `주요 페이지 Route Feasibility`에 정리. |
| 모든 `push<bool>` 호출자가 저장 후 갱신 방식과 함께 기록된다. | 완료. `route_matrix.md`의 `push<bool> Dependency Matrix`에 정리. |
| 다음 세부 계획에서 건드릴 수 없는 화면이 명시된다. | 완료. `route_matrix.md`의 `다음 세부 계획에서 건드릴 수 없는 화면`에 정리. |
| 산출물 작성 후 다음 계획을 자동으로 시작하지 않는다. | 완료. Plan B 이상은 착수하지 않음. |

## 핵심 결론

- `AssetDetailPage`, `HoldingDetailPage`, `CashAccountDetailPage`는 id + optional clientId 기반 named route 전환이 비교적 쉽다.
- `SnapshotDetailPage`는 snapshot 객체와 item 리스트를 직접 받으므로 named route 전에 자체 loader 리팩터가 필요하다.
- `AnnualAssetAnalysisPage`는 snapshots/items 리스트를 받으므로 route path만으로는 부족하며 extra 또는 loader 리팩터가 필요하다.
- 모든 주요 form edit route는 객체 전달과 `push<bool>` 갱신 의존이 커서 Plan B/C에서 건드리면 안 된다.
- 현재 테스트는 탭 방문과 일부 페이지 렌더링은 커버하지만 route-level 테스트는 없다.

## 테스트

문서 산출물 작성 작업이므로 자동 테스트는 실행하지 않았다.

## 후속 후보

- Plan B 착수 전 `PortfolioPage`와 `TransactionsPage`에 추가할 targeted widget test 후보를 구체화할 수 있다.
- Plan C 착수 전 route registry 파일 위치와 helper API 형태를 별도 짧은 설계 메모로 정할 수 있다.

## 중지 지점

Plan A 완료 후 중지한다. 다음 계획은 사용자 명시 요청 전까지 착수하지 않는다.
