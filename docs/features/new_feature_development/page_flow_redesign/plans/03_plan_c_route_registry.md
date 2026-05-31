# Plan C. Route Registry Baseline

## 역할

`go_router` 전환 전에 앱의 목적지 이름, path, argument 규칙, navigation helper 경계를 코드와 문서에 고정한다.

Plan C는 라우터 교체가 아니라 **현재 `Navigator.push(MaterialPageRoute...)` 구조를 유지한 채 라우팅 언어를 먼저 통일하는 기준선 작업**이다.

## 범위

- route name/path 상수 추가.
- route argument 타입 또는 builder 규칙 추가.
- 안전한 주요 목적지만 navigation helper로 감싼다.
- 분석/상세/인증처럼 객체 전달 없이 열 수 있거나 id 기반으로 열 수 있는 화면을 우선 등록한다.
- `AppShellPage`의 6개 탭 label과 route name/path 의미를 맞춘다.
- `route_matrix.md`의 Plan C 적용 여부를 갱신한다.

## 제외

- `go_router` 의존성 추가.
- `MaterialApp.router` 전환.
- browser/deep link 동작 추가.
- 5탭 통합.
- 탭 구조 변경.
- form edit route 전환.
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage`의 named route 전환.
- `TransactionFormPage`, `CashTransactionFormPage` helper 전환.
- bottom sheet/dialog를 route registry 대상으로 승격.

## 산출물

- route registry 코드.
- navigation helper 코드.
- route registry 문서.
- `docs/features/new_feature_development/page_flow_redesign/implementation_report_plan_c.md`
- `docs/features/new_feature_development/page_flow_redesign/test_report_plan_c.md`

## 대상 파일

| 파일 | 역할 |
| --- | --- |
| `lib/navigation/moneyfy_routes.dart` | route name/path/argument 규칙의 단일 출처 |
| `lib/navigation/moneyfy_navigation.dart` | 현재 `Navigator` 기반 helper |
| `lib/pages/app_shell_page.dart` | 탭 route 의미와 label 대응 확인 |
| `lib/pages/portfolio_dashboard_page.dart` | `AssetDetailPage` 진입 helper 적용 후보 |
| `lib/pages/portfolio_page.dart` | Plan B에서 추가한 `AssetDetailPage` 진입 helper 적용 후보 |
| `lib/pages/asset_detail_page.dart` | `HoldingDetailPage`, `CashAccountDetailPage` 진입 helper 적용 후보 |
| `lib/pages/analysis_page.dart` | 분석 하위 페이지 helper 적용 후보 |
| `lib/pages/my_page.dart` | `LoginPage`, `SignupPage` helper 적용 후보 |
| `docs/features/new_feature_development/page_flow_redesign/route_matrix.md` | Plan C 기준선 반영 |

## Route Registry 초안

### Shell Tabs

| route name | path | 현재 탭 label | page | Plan C 처리 |
| --- | --- | --- | --- | --- |
| `home` | `/` | `홈` | `PortfolioDashboardPage` | 상수 등록만 |
| `portfolio` | `/portfolio` | `포트폴` | `PortfolioPage` | 상수 등록만 |
| `transactions` | `/transactions` | `거래` | `TransactionsPage` | 상수 등록만 |
| `analysis` | `/analysis` | `분석` | `AnalysisPage` | 상수 등록만 |
| `statistics` | `/statistics` | `통계` | `StatisticsPage` | 상수 등록만 |
| `my` | `/my` | `My` | `MyPage` | 상수 등록만 |

주의:

- Plan C에서는 탭 클릭을 path 기반 이동으로 바꾸지 않는다.
- `AppShellPage`의 indexed tab 상태는 유지한다.
- 이 상수들은 Plan G의 shell route 정의를 위한 사전 계약이다.

### Detail Routes

| route name | path | argument | page | Plan C 처리 |
| --- | --- | --- | --- | --- |
| `assetDetail` | `/assets/:assetId` | `assetId`, optional `assetClientId` | `AssetDetailPage` | helper 적용 |
| `holdingDetail` | `/holdings/:holdingId` | `holdingId`, optional `holdingClientId` | `HoldingDetailPage` | helper 적용 |
| `cashAccountDetail` | `/cash-accounts/:holdingId` | `holdingId`, optional `holdingClientId` | `CashAccountDetailPage` | helper 적용 |

주의:

- path는 미래 `go_router` 기준을 고정하기 위한 문자열이다.
- 현재 구현은 계속 `MaterialPageRoute`를 사용한다.
- optional client id는 path가 아니라 argument 객체에 둔다.

### Analysis Routes

| route name | path | argument | page | Plan C 처리 |
| --- | --- | --- | --- | --- |
| `portfolioDiagnosis` | `/analysis/portfolio-diagnosis` | 없음 | `PortfolioAnalysisMvpPage` | helper 적용 |
| `investmentPerformance` | `/analysis/investment-performance` | 없음 | `InvestmentPerformancePage` | helper 적용 |
| `dividendInterest` | `/analysis/dividend-interest` | 없음 | `DividendInterestAnalysisPage` | helper 적용 |

주의:

- Plan D에서 명칭/진입점 통합이 예정되어 있으므로, Plan C에서는 현재 목적지 이름을 기준선으로 고정한다.
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage`는 객체 리스트 의존이 있어 Plan C helper 적용 대상에서 제외한다.

### Auth Routes

| route name | path | argument | page | Plan C 처리 |
| --- | --- | --- | --- | --- |
| `login` | `/login` | 없음 | `LoginPage` | helper 적용 |
| `signup` | `/signup` | 없음 | `SignupPage` | helper 적용 |

주의:

- 로그인 성공 후 `pop` 동작은 유지한다.
- 인증 guard 또는 redirect는 Plan G 이후 범위다.

### Form Routes

| route name | path | argument | page | Plan C 처리 |
| --- | --- | --- | --- | --- |
| `assetCreate` | `/assets/new` | 없음 | `AssetFormPage` | 상수 등록만 |
| `assetEdit` | `/assets/:assetId/edit` | `assetId` 후보 | `AssetFormPage` | 상수 등록만 |
| `holdingCreate` | `/assets/:assetId/holdings/new` | `assetId` | `HoldingFormPage` | 상수 등록만 |
| `holdingEdit` | `/holdings/:holdingId/edit` | `holdingId` 후보 | `HoldingFormPage` | 상수 등록만 |
| `cashAccountCreate` | `/assets/:assetId/cash-accounts/new` | `assetId` | `CashAccountFormPage` | 상수 등록만 |
| `cashAccountEdit` | `/cash-accounts/:holdingId/edit` | `holdingId` 후보 | `CashAccountFormPage` | 상수 등록만 |
| `transactionCreate` | `/holdings/:holdingId/transactions/new` | `assetId`, `holdingId` | `TransactionFormPage` | 상수 등록만 |
| `transactionEdit` | `/transactions/:transactionId/edit` | `transactionId` 후보 | `TransactionFormPage` | 상수 등록만 |
| `cashTransactionCreate` | `/cash-accounts/:holdingId/transactions/new` | `assetId`, `holdingId` | `CashTransactionFormPage` | 상수 등록만 |
| `cashTransactionEdit` | `/cash-transactions/:transactionId/edit` | `transactionId` 후보 | `CashTransactionFormPage` | 상수 등록만 |

주의:

- Form routes는 Plan C에서 helper 적용하지 않는다.
- `push<bool>` 반환, edit 객체 전달, ledger guard가 얽혀 있으므로 Plan I에서 구현한다.

## 코드 설계

### C1. Route 상수 추가

목표:

- route name/path를 문자열 흩어짐 없이 한 파일에서 관리한다.

구현:

- `lib/navigation/moneyfy_routes.dart` 추가.
- `MoneyfyRouteNames` static const class 추가.
- `MoneyfyRoutePaths` static const class 추가.
- path builder helper를 필요한 최소 범위로 추가한다.

예시:

```dart
abstract final class MoneyfyRouteNames {
  static const home = 'home';
  static const assetDetail = 'assetDetail';
}

abstract final class MoneyfyRoutePaths {
  static const home = '/';
  static const assetDetailPattern = '/assets/:assetId';

  static String assetDetail(int assetId) => '/assets/$assetId';
}
```

완료 조건:

- Plan C 대상 route name/path가 모두 상수로 존재한다.
- path builder는 id가 필요한 detail route에만 우선 제공한다.
- form route는 상수만 있고 helper 적용은 없다.

### C2. Argument 타입 추가

목표:

- optional id/client id 전달 규칙을 route helper에서 명확히 한다.

구현:

- `AssetDetailRouteArgs`
- `HoldingDetailRouteArgs`
- `CashAccountDetailRouteArgs`
- 필요 시 auth/analysis는 argument 없이 처리한다.

예시:

```dart
class AssetDetailRouteArgs {
  const AssetDetailRouteArgs({required this.assetId, this.assetClientId});

  final int assetId;
  final String? assetClientId;
}
```

완료 조건:

- detail route의 constructor argument가 helper argument 타입과 1:1로 대응한다.
- `assetClientId`, `holdingClientId` 같은 optional fallback id가 누락되지 않는다.

### C3. Navigator 기반 helper 추가

목표:

- 당장 라우터를 바꾸지 않고도 호출부가 route 의미를 쓰도록 만든다.

구현:

- `lib/navigation/moneyfy_navigation.dart` 추가.
- `MoneyfyNavigation` extension 또는 static helper 추가.
- 내부는 기존과 동일하게 `Navigator.of(context).push(MaterialPageRoute(...))`를 사용한다.
- 반환값이 필요한 route는 기존 반환 타입을 유지한다.

적용 helper 후보:

| helper | 반환 | 내부 page |
| --- | --- | --- |
| `openAssetDetail` | `Future<void>` | `AssetDetailPage` |
| `openHoldingDetail` | `Future<void>` | `HoldingDetailPage` |
| `openCashAccountDetail` | `Future<void>` | `CashAccountDetailPage` |
| `openPortfolioDiagnosis` | `Future<void>` | `PortfolioAnalysisMvpPage` |
| `openInvestmentPerformance` | `Future<void>` | `InvestmentPerformancePage` |
| `openDividendInterest` | `Future<void>` | `DividendInterestAnalysisPage` |
| `openLogin` | `Future<void>` | `LoginPage` |
| `openSignup` | `Future<void>` | `SignupPage` |

완료 조건:

- helper 내부 동작이 기존 `MaterialPageRoute` push와 동일하다.
- helper 적용 후 호출자의 refresh/reload 로직이 보존된다.
- form page helper는 만들지 않는다.

### C4. 안전한 호출부만 helper 적용

목표:

- route 의미를 코드에 심되, 위험한 form/edit 흐름은 건드리지 않는다.

적용 후보:

| 호출 위치 | 현재 대상 | Plan C 작업 |
| --- | --- | --- |
| `PortfolioDashboardPage` | `AssetDetailPage` | helper 적용 |
| `PortfolioPage` | `AssetDetailPage` | helper 적용 |
| `AssetDetailPage` | `HoldingDetailPage`, `CashAccountDetailPage` | helper 적용 |
| `AnalysisPage` | `PortfolioAnalysisMvpPage`, `InvestmentPerformancePage`, `DividendInterestAnalysisPage` | helper 적용 |
| `MyPage` | `LoginPage`, `SignupPage` | helper 적용 |

보류:

- `StatisticsPage`의 `SnapshotDetailPage`, `AnnualAssetAnalysisPage`
- `AnalysisPage`의 snapshot/annual analysis 진입
- 모든 form page 진입
- 거래 추가/수정 진입

완료 조건:

- 적용한 helper 호출부는 기존 페이지 도착/뒤로가기 동작이 동일하다.
- 적용하지 않은 호출부는 route matrix에 이유가 기록된다.

### C5. AppShellPage route 의미 정렬

목표:

- 탭 label, tab index, route name/path의 의미를 혼동 없이 맞춘다.

구현:

- `_NavItem` 또는 인접 구조에 route name/path를 추가할지 검토한다.
- Plan C에서는 탭 이동 방식을 바꾸지 않고 metadata만 추가한다.
- 현재 widget key `bottom-tab-${item.label}`는 유지한다.

완료 조건:

- 6개 탭이 route name/path와 문서상 1:1로 대응한다.
- 탭 전환 동작은 기존 index 기반 상태를 유지한다.

### C6. 문서 갱신

목표:

- route registry와 route matrix가 같은 기준을 말하게 한다.

구현:

- `route_matrix.md`에 Plan C 적용 대상/보류 대상을 표시한다.
- 구현 후 `implementation_report_plan_c.md` 작성.
- 검증 후 `test_report_plan_c.md` 작성.

완료 조건:

- 코드 route 상수와 문서 route name/path가 일치한다.
- 보류 route의 이유와 후속 계획이 명시된다.

### C7. 검증

목표:

- helper 래핑으로 기존 페이지 이동이 깨지지 않았는지 확인한다.

필수:

- `dart format lib/navigation lib/pages/app_shell_page.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/asset_detail_page.dart lib/pages/analysis_page.dart lib/pages/my_page.dart`
- `flutter analyze`

권장:

- `flutter test test/page_walkthrough_test.dart`

주의:

- 현재 Plan B 검증에서 `page_walkthrough_test.dart`의 `bottom-tab-홈` 탐색 실패가 기록되어 있다.
- Plan C 구현 전 또는 구현 중 해당 테스트가 계속 실패하면, Plan C 회귀인지 기존 테스트 안정성 이슈인지 구분해 `test_report_plan_c.md`에 기록한다.

## 건드리지 말 것

- `MaterialApp.router`
- `go_router`
- `pubspec.yaml` dependency
- `SnapshotDetailPage` 생성자 구조
- `AnnualAssetAnalysisPage` 생성자 구조
- `AssetFormPage`, `HoldingFormPage`, `CashAccountFormPage` edit flow
- `TransactionFormPage`, `CashTransactionFormPage`
- bottom sheet/dialog route화
- 5탭 통합

## 회귀 위험

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| helper가 기존 optional client id를 빠뜨림 | 상세 페이지 fallback 조회 실패 | argument 타입에 optional id를 명시하고 호출부에서 그대로 전달 |
| helper 적용 후 reload 위치가 달라짐 | 상세 복귀 후 데이터 미갱신 | helper는 push만 담당하고 호출자 reload 로직은 호출자에 남김 |
| 분석 route 이름이 Plan D에서 바뀜 | route 상수 churn | Plan C는 현재 목적지 기준선, Plan D 변경 시 route 이름 변경 리포트 작성 |
| form route를 성급히 helper화 | `push<bool>` 갱신/객체 edit 회귀 | Plan C에서는 form helper 금지 |
| 탭 metadata 추가 중 테스트 key 변경 | 워크스루 테스트 추가 실패 | `bottom-tab-${item.label}` key 유지 |

## 완료 체크리스트

- [x] `MoneyfyRouteNames`가 추가되어 Plan C 대상 route name을 모두 포함한다.
- [x] `MoneyfyRoutePaths`가 추가되어 Plan C 대상 path를 모두 포함한다.
- [x] detail route argument 타입이 optional client id를 보존한다.
- [x] `MoneyfyNavigation` helper가 현재 `Navigator` 기반으로 추가된다.
- [x] `AssetDetailPage`, `HoldingDetailPage`, `CashAccountDetailPage` 진입 중 안전한 호출부가 helper를 사용한다.
- [x] 분석 하위 페이지 진입 중 안전한 호출부가 helper를 사용한다.
- [x] `LoginPage`, `SignupPage` 진입 중 안전한 호출부가 helper를 사용한다.
- [x] form edit/create route는 helper 적용 없이 상수만 등록하거나 보류한다.
- [x] `SnapshotDetailPage`, `AnnualAssetAnalysisPage` route 구조는 변경하지 않는다.
- [x] `go_router`, `MaterialApp.router`, 5탭 통합을 건드리지 않는다.
- [x] `route_matrix.md`에 Plan C 적용/보류 결과가 반영된다.
- [x] `flutter analyze` 결과가 기록된다.
- [x] 관련 테스트 또는 테스트 실패 원인이 `test_report_plan_c.md`에 기록된다.

## 완료 조건

- 주요 페이지 route name/path가 코드와 문서에 동시에 존재한다.
- helper로 감싼 이동은 기존 push/pop 동작과 동일하다.
- helper 적용 후 호출자의 reload/refresh 책임이 유지된다.
- Plan C 범위 밖 route 전환을 하지 않았다.
- 검증 결과와 미해결 테스트 이슈가 문서에 기록된다.
- 완료 후 다음 계획을 자동으로 시작하지 않는다.
