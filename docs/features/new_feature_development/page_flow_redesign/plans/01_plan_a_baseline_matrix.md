# Plan A. 기준선/의존성 매트릭스

## 역할

실제 구현 전에 라우팅, 폼 갱신, 페이지 진입 의존성을 고정한다.

## 범위

- `Navigator.push`, `push<bool>`, `showModalBottomSheet`, 탭 간 콜백 목록화.
- route feasibility matrix 작성.
- `push<bool>` dependency matrix 작성.
- `SnapshotDetailPage`처럼 route 재조회가 어려운 화면 식별.
- 현재 테스트가 커버하는 페이지와 빠진 페이지 목록화.

## 제외

- UI 변경.
- route helper 추가.
- `go_router` 의존성 추가.

## 산출물

- `docs/features/new_feature_development/page_flow_redesign/route_matrix.md`
- `docs/features/new_feature_development/page_flow_redesign/test_coverage_matrix.md`

## 완료 조건

- 모든 주요 페이지가 `direct push 가능`, `named route 가능`, `extra 필요`, `사전 리팩터 필요` 중 하나로 분류된다.
- 모든 `push<bool>` 호출자가 저장 후 갱신 방식과 함께 기록된다.
- 다음 세부 계획에서 건드릴 수 없는 화면이 명시된다.
- 산출물 작성 후 다음 계획을 자동으로 시작하지 않는다.
