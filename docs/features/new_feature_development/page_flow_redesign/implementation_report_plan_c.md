# Plan C Implementation Report

## 상태

- 완료일: 2026-05-30
- 상태: 구현 완료
- 다음 계획 자동 착수: 하지 않음

## 구현 범위

### C1. Route 상수 추가

- `lib/navigation/moneyfy_routes.dart`를 추가했다.
- `MoneyfyRouteNames`에 shell/detail/analysis/auth/form route name을 등록했다.
- `MoneyfyRoutePaths`에 shell/detail/analysis/auth/form path와 id 기반 path builder를 등록했다.

### C2. Argument 타입 추가

- `AssetDetailRouteArgs`를 추가했다.
- `HoldingDetailRouteArgs`를 추가했다.
- `CashAccountDetailRouteArgs`를 추가했다.
- optional `assetClientId`, `holdingClientId`는 기존 상세 페이지 fallback 조회를 위해 그대로 보존했다.

### C3. Navigator 기반 helper 추가

- `lib/navigation/moneyfy_navigation.dart`를 추가했다.
- helper는 현재 구조와 동일하게 `Navigator.of(context).push(MaterialPageRoute(...))`를 사용한다.
- `RouteSettings.name`에는 미래 route path 기준 문자열을 넣었다.

### C4. 안전한 호출부 helper 적용

- 홈 자산 목록에서 `AssetDetailPage` 진입을 helper로 감쌌다.
- 포트폴리오 자산 비중에서 `AssetDetailPage` 진입을 helper로 감쌌다.
- 자산 상세의 투자 보유/현금 계좌 상세 진입을 helper로 감쌌다.
- 분석 탭의 포트폴리오 진단, 투자성과 분석, 배당/이자 분석 진입을 helper로 감쌌다.
- My 탭의 로그인/회원가입 진입을 helper로 감쌌다.

### C5. AppShellPage route 의미 정렬

- 6개 탭 `_NavItem`에 route name/path metadata를 추가했다.
- 탭 전환은 기존 indexed state를 유지했다.
- 기존 `bottom-tab-${item.label}` key는 변경하지 않았다.

### C6. 문서 갱신

- `route_matrix.md`에 Plan C 적용 결과를 추가했다.
- Plan C 체크리스트를 완료 상태로 갱신했다.
- 상위 `plan.md`에서 Plan C 상태를 완료로 변경했다.

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `lib/navigation/moneyfy_routes.dart` | route name/path/argument 타입 추가 |
| `lib/navigation/moneyfy_navigation.dart` | 현재 Navigator 기반 helper 추가 |
| `lib/pages/app_shell_page.dart` | 6탭 route metadata 추가 |
| `lib/pages/portfolio_dashboard_page.dart` | 자산 상세 진입 helper 적용 |
| `lib/pages/portfolio_page.dart` | 자산 상세 진입 helper 적용 |
| `lib/pages/asset_detail_page.dart` | 보유/현금 계좌 상세 진입 helper 적용 |
| `lib/pages/analysis_page.dart` | 분석 하위 페이지 진입 helper 적용 |
| `lib/pages/my_page.dart` | 로그인/회원가입 진입 helper 적용 |
| `docs/features/new_feature_development/page_flow_redesign/route_matrix.md` | Plan C 적용 결과 기록 |

## 범위 밖 미착수 확인

- `go_router` 의존성 추가: 미착수
- `MaterialApp.router` 전환: 미착수
- 5탭 통합: 미착수
- 탭 구조 변경: 미착수
- form edit/create helper 적용: 미착수
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage` named route 전환: 미착수
- `TransactionFormPage`, `CashTransactionFormPage` helper 전환: 미착수
- bottom sheet/dialog route화: 미착수

## 후속 후보

- Plan G에서 `MoneyfyRouteNames`/`MoneyfyRoutePaths`를 shell route 정의의 기준으로 사용한다.
- Plan I에서 form route의 `push<bool>` 반환, edit loader, ledger guard를 정리한 뒤 helper/named route로 전환한다.
- `page_walkthrough_test.dart`의 앱 셸 탭 key 탐색 실패는 별도 테스트 안정화 작업으로 확인한다.
