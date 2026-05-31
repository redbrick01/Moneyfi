# Route Matrix

Plan A 산출물. 현재 `Navigator.push`, `showModalBottomSheet`, `showDialog`, `push<bool>` 갱신 의존성을 기준으로 라우팅 전환 가능성을 분류했다.

## 분류 기준

| 분류 | 의미 |
| --- | --- |
| `direct push 가능` | 현재 직접 push 구조 유지가 적합하거나 route 전환 우선순위가 낮다. |
| `named route 가능` | id/query 기반으로 명시 route 전환이 비교적 쉽다. |
| `extra 필요` | 현재 객체 전체 또는 리스트를 생성자에서 받아 route path만으로는 부족하다. |
| `사전 리팩터 필요` | named route 전환 전에 데이터 재조회/상태 갱신 구조를 먼저 바꿔야 한다. |

## 주요 페이지 Route Feasibility

| 화면 | 현재 진입 | 전달 데이터 | 분류 | 메모 |
| --- | --- | --- | --- | --- |
| `AppShellPage` | `_StartupGate` 완료 후 `home` | 없음 | named route 가능 | Plan G 전까지 `_StartupGate` 초기화 책임 유지. |
| `StartupSplashPage` | `_StartupGate` 내부 상태 | 없음 | direct push 가능 | 독립 route보다 startup wrapper 상태가 적합. |
| `StartupErrorPage` | `_StartupGate` 내부 에러 | error string | direct push 가능 | route보다 초기화 에러 상태로 유지 권장. |
| `PortfolioDashboardPage` | 탭 루트 `홈` | scrollController, refresh tick | named route 가능 | Shell route child. |
| `PortfolioPage` | 탭 루트 `포트폴` | scrollController, focus tick, refresh tick | named route 가능 | Shell route child. |
| `TransactionsPage` | 탭 루트 `거래` | scrollController, refresh tick, optional test callback | named route 가능 | `remoteRefresh`는 test-only 성격이라 route 제외 가능. |
| `AnalysisPage` | 탭 루트 `분석` | scrollController, reselection tick, refresh tick | named route 가능 | Shell route child. |
| `StatisticsPage` | 탭 루트 `통계` | scrollController, refresh tick | named route 가능 | 6탭 유지 중 shell child. |
| `MyPage` | 탭 루트 `My` | scrollController | named route 가능 | Auth 상태별 내부 UI 유지. |
| `AssetDetailPage` | 홈 자산 목록 | `assetId`, optional `assetClientId` | named route 가능 | path `assetId`, query/extra `assetClientId`. |
| `HoldingDetailPage` | 자산 상세 투자 보유 행 | `holdingId`, optional `holdingClientId` | named route 가능 | path `holdingId`, query/extra `holdingClientId`. |
| `CashAccountDetailPage` | 자산 상세 현금 계좌 행 | `holdingId`, optional `holdingClientId` | named route 가능 | path `holdingId`, query/extra `holdingClientId`. |
| `SnapshotDetailPage` | 통계 primary, 분석 보조 진입, 연도별 분석 | `DailyPortfolioSnapshot`, `List<DailyPortfolioSnapshotItem>` | 사전 리팩터 필요 | Plan E 기준 primary 소속은 통계. `snapshotId` 또는 `snapshotDate` 기반 자체 로드로 바꿔야 안정적 named route 가능. |
| `AnnualAssetAnalysisPage` | 통계 primary, 분석 보조 진입 | `List<DailyPortfolioSnapshot>`, `List<DailyPortfolioSnapshotItem>` | extra 필요 | Plan E 기준 primary 소속은 통계. 연도/기간 기반 재조회 리팩터 전에는 extra 유지. |
| `PortfolioAnalysisMvpPage` | 홈/포트폴리오/분석의 포트폴리오 진단 상세 | 없음 | named route 가능 | Plan D에서 통합 진단 상세 목적지로 확정. |
| `InvestmentPerformancePage` | 분석 탭 진입 카드 | 없음 | named route 가능 | `/insights/performance` 후보. |
| `DividendInterestAnalysisPage` | 분석 탭 진입 카드 | 없음 | named route 가능 | `/insights/income` 후보. |
| `LoginPage` | My 탭/로그인 필요 UI | 없음 | named route 가능 | pop 기반 종료 동작 확인 필요. |
| `SignupPage` | My 탭/LoginPage | 없음 | named route 가능 | pop 기반 종료 동작 확인 필요. |
| `AssetFormPage` | 홈/포트폴리오/자산 상세 | optional `AssetItem` | 사전 리팩터 필요 | create는 route 가능, edit는 id 기반 재조회 또는 extra 필요. `push<bool>` 갱신 의존 큼. |
| `HoldingFormPage` | 자산 상세/보유 상세 | `assetId`, optional `HoldingItem` | 사전 리팩터 필요 | create는 route 가능, edit는 id 기반 재조회 또는 extra 필요. |
| `CashAccountFormPage` | 자산 상세/보유/현금 상세 | `assetId`, optional `HoldingItem` | 사전 리팩터 필요 | edit route에는 holding id 기반 재조회 필요. |
| `TransactionFormPage` | 거래 탭/보유 상세 | `assetId`, `holdingId`, optional `holdingClientId`, optional `TransactionItem`, defaultName | 사전 리팩터 필요 | `TransactionItem` edit와 `push<bool>` 갱신 의존이 커서 Plan I 대상. |
| `CashTransactionFormPage` | 거래 탭/현금 상세 | `assetId`, `holdingId`, optional `holdingClientId`, optional `TransactionItem`, defaultName | 사전 리팩터 필요 | `TransactionItem` edit와 `push<bool>` 갱신 의존이 커서 Plan I 대상. |
| `_TargetAllocationSheet` | 포트폴리오 목표 비중 | entries, controllers, onSave callback | direct push 가능 | bottom sheet 유지 권장. route 대상 아님. |
| `_TransactionKindPickerSheet` | 거래 추가 플로우 | account options | direct push 가능 | bottom sheet 유지 권장. route 대상 아님. |
| `_TransactionFilterSheet` | 거래 필터 | filter draft | direct push 가능 | bottom sheet 유지 권장. route 대상 아님. |
| `_MoneyfySelectionSheet` | 폼 공통 선택 | generic options/value | direct push 가능 | bottom sheet 유지 권장. route 대상 아님. |
| `SyncOverlay` | 앱 overlay | sync state | direct push 가능 | 독립 navigation 대상 아님. |

## Direct Push / Modal Surfaces

| 호출 위치 | 대상 | 반환 | 유지 판단 |
| --- | --- | --- | --- |
| `MyPage` | 설정 안내 bottom sheet | void | 유지. |
| `MyPage` | 로그인/회원가입 | void route push | named route 가능. |
| `MyPage` | 동기화/코어 데이터/이름/비밀번호/로그아웃 dialogs | bool/string/input | dialog 유지. |
| `TargetAllocationSheet` | 목표 비중 bottom sheet | `bool?` | bottom sheet 유지. |
| `TransactionsPage` | 거래 유형 선택 sheet | `_TransactionCreateKind?` | bottom sheet 유지. |
| `TransactionsPage` | 거래 필터 sheet | `_TransactionFilterDraft?` | bottom sheet 유지. |
| `forms/form_design.dart` | 공통 선택 sheet | generic selected value | bottom sheet 유지. |
| detail pages | 삭제 확인 dialogs | `bool?` | dialog 유지. |

## Plan C 적용 결과

Plan C에서는 `go_router`나 `MaterialApp.router`로 전환하지 않고, route name/path 상수와 현재 `Navigator` 기반 helper만 추가했다.

| 대상 | Plan C 결과 | 메모 |
| --- | --- | --- |
| Shell tabs | route name/path metadata 등록 | 6탭 indexed state와 `bottom-tab-${item.label}` key 유지 |
| `AssetDetailPage` | helper 적용 | `AssetDetailRouteArgs(assetId, assetClientId)`로 optional client id 보존 |
| `HoldingDetailPage` | helper 적용 | `HoldingDetailRouteArgs(holdingId, holdingClientId)`로 optional client id 보존 |
| `CashAccountDetailPage` | helper 적용 | `CashAccountDetailRouteArgs(holdingId, holdingClientId)`로 optional client id 보존 |
| `PortfolioAnalysisMvpPage` | helper 적용 | Plan D에서 홈/포트폴리오/분석의 통합 진단 상세 목적지로 확정 |
| `InvestmentPerformancePage` | helper 적용 | argument 없음 |
| `DividendInterestAnalysisPage` | helper 적용 | argument 없음 |
| `LoginPage` | helper 적용 | 로그인 성공 후 pop 동작 유지 |
| `SignupPage` | helper 적용 | 회원가입 후 기존 pop 동작 유지 |
| form pages | 상수만 등록, helper 보류 | `push<bool>`, edit 객체 전달, ledger guard 때문에 Plan I 대상 |
| `SnapshotDetailPage` | 보류 | snapshot 객체/list 전달 구조 유지 |
| `AnnualAssetAnalysisPage` | 보류 | snapshots/items list 전달 구조 유지 |

## Plan F 적용 결과

Plan F에서는 form route 구조를 전환하지 않고, 현재 `Navigator.push`와 `push<bool>` 기반 저장 후 reload 구조를 유지했다.

| 대상 | Plan F 결과 | 메모 |
| --- | --- | --- |
| 홈/포트폴리오 empty state | 첫 자산군 이후 보유 종목/현금 계좌 추가 흐름 안내 | `AssetFormPage` push 구조 유지 |
| 거래 empty state | 계좌 없음과 거래 없음 상태 문구/CTA 분리 | 계좌 없음은 `자산 추가`, 계좌 있음은 `거래 추가` 유지 |
| 자산 상세 보유/현금 empty state | 본문 CTA 추가 | 기존 header add icon과 `_openHoldingForm` reload 구조 유지 |
| 거래 유형 선택 sheet | 투자 거래/현금 거래 전제 조건 안내 | bottom sheet route화 없음 |
| 거래/현금 거래 폼 | 대상 보유/계좌 helper text 추가 | save/validation/ledger calculation 변경 없음 |

## Plan G 적용 결과

Plan G에서는 5탭 통합 없이 현재 6탭 구조를 `go_router`와 `MaterialApp.router` 기반으로 전환했다.

| 대상 | Plan G 결과 | 메모 |
| --- | --- | --- |
| `MoneyfyApp` | `MaterialApp.router` 전환 | theme, scroll behavior, text scale builder 유지 |
| startup flow | `StartupGate`로 분리 | 초기화, splash, error 책임 유지 |
| shell tabs | `/`, `/portfolio`, `/transactions`, `/analysis`, `/statistics`, `/my` route 등록 | 6탭 유지, `bottom-tab-*` key 유지 |
| `AppShellPage` | route path 기반 selected tab 동기화 | 같은 탭 재탭 시 기존 scroll-to-top/reselection 유지 |
| Plan C helper 대상 | `go_router` `push` 기반으로 전환 | router context가 없는 standalone 테스트/임베딩은 기존 `Navigator.push` fallback 유지 |
| detail routes | asset/holding/cash account 직접 route 등록 | optional client id는 query parameter로 보존 |
| analysis/auth routes | portfolio diagnosis, performance, income, login, signup route 등록 | auth redirect는 추가하지 않음 |
| form pages | 기존 `Navigator.push<bool>` 유지 | Plan I 대상으로 남김 |
| snapshot/annual analysis | 기존 객체/list 전달 구조 유지 | id 기반 loader 전환 없음 |

## Plan H-Impl 적용 결과

Plan H-Impl에서는 Plan H 결정에 따라 하단 탭을 5개로 줄이고, 기존 통계 기능은 `/statistics` 호환 route와 분석 탭 진입점으로 보존했다.

| 대상 | Plan H-Impl 결과 | 메모 |
| --- | --- | --- |
| Shell tabs | `홈`, `포트폴`, `거래`, `분석`, `My` 5탭으로 축소 | `통계` 하단 탭 key 제거 |
| `/statistics` route | 유지 | router shell 안에서 `StatisticsPage` 표시 |
| `/statistics` selected tab | `분석`으로 매핑 | 통계는 분석 영역의 호환 route로 취급 |
| `AnalysisPage` | `통계` 진입 카드 추가 | `월별 총자산 · 스냅샷 · 연도별 흐름` 안내 |
| `StatisticsPage` | 기능 제거 없이 유지 | snapshot/annual loader 전환 없음 |
| `MoneyfyRouteNames.statistics` / `MoneyfyRoutePaths.statistics` | 유지 | 기존 route compatibility 보존 |
| form pages | 변경 없음 | Plan I 대상으로 유지 |
| My tab | 변경 없음 | `내부 DB 요약 복사 (GPT)` 위치 유지 |

## Plan I 적용 결과

Plan I에서는 form create route를 `go_router` named route로 전환하고, edit route는 객체 전달/loader/ledger guard 위험 때문에 기존 push 구조로 보류했다.

| 대상 | Plan I 결과 | 메모 |
| --- | --- | --- |
| `AssetFormPage` create | `/assets/new` route 등록 및 helper 적용 | 홈/포트폴리오/거래 empty state 호출부 전환 |
| `AssetFormPage` edit | 기존 `Navigator.push<bool>` 유지 | `AssetItem` 객체 직접 전달 구조 보존 |
| `HoldingFormPage` create | `/assets/:assetId/holdings/new` route 등록 및 helper 적용 | 자산 상세 create CTA 전환 |
| `HoldingFormPage` edit | 기존 `Navigator.push<bool>` 유지 | `HoldingItem` edit 객체 재구성 loader 보류 |
| `CashAccountFormPage` create | `/assets/:assetId/cash-accounts/new` route 등록 및 helper 적용 | 자산 상세 현금 계좌 create CTA 전환 |
| `CashAccountFormPage` edit | 기존 `Navigator.push<bool>` 유지 | `HoldingItem` 기반 현금 계좌 edit loader 보류 |
| `TransactionFormPage` create | `/holdings/:holdingId/transactions/new?assetId=...` route 등록 및 helper 적용 | 거래/보유 상세 create 호출부 전환 |
| `TransactionFormPage` edit | 기존 `Navigator.push<bool>` 유지 | ledger-backed edit guard 보존 |
| `CashTransactionFormPage` create | `/cash-accounts/:holdingId/transactions/new?assetId=...` route 등록 및 helper 적용 | 거래/현금 상세 create 호출부 전환 |
| `CashTransactionFormPage` edit | 기존 `Navigator.push<bool>` 유지 | transfer/exchange paired ledger edit guard 보존 |
| invalid form route | 오류 화면 표시 | 거래 create route에서 `assetId` 누락 시 crash 없이 처리 |
| form result | `Future<bool?>` helper 반환 | 기존 `changed == true` reload 조건 유지 |

## `push<bool>` Dependency Matrix

| 호출자 | 대상 폼 | 저장 성공 반환 | 호출자 갱신 방식 | route 전환 위험 |
| --- | --- | --- | --- | --- |
| `PortfolioDashboardPage._openAssetForm` | `AssetFormPage` | `true` | `_markChanged()`로 refresh tick 증가 | 중간 |
| `PortfolioPage._openAssetForm` | `AssetFormPage` | `true` | `_pageFuture = _loadPortfolioPageData()` | 중간 |
| `AssetDetailPage._editAsset` | `AssetFormPage` | `true` | `_reloadDetail()` | 중간 |
| `AssetDetailPage._openHoldingForm` | `HoldingFormPage` or `CashAccountFormPage` | `true` | `_reloadDetail()` | 높음 |
| `HoldingDetailPage._editHolding` | `HoldingFormPage` or `CashAccountFormPage` | `true` | `_reloadHolding()` | 높음 |
| `HoldingDetailPage._openTransactionForm` | `TransactionFormPage` | `true` | `_reloadHolding()` | 높음 |
| `CashAccountDetailPage._editHolding` | `CashAccountFormPage` | `true` | `_reloadHolding()` | 높음 |
| `CashAccountDetailPage._openTransactionForm` | `CashTransactionFormPage` | `true` | `_reloadHolding()` | 높음 |
| `TransactionsPage._openTransactionForm` | `TransactionFormPage` or `CashTransactionFormPage` | `true` | `_pageFuture = _loadPageData()` | 높음 |

## 사전 리팩터 필요 화면

| 화면 | 이유 | 선행 작업 |
| --- | --- | --- |
| `SnapshotDetailPage` | 생성자에서 snapshot 객체와 item 리스트를 직접 받음 | `snapshotId` 또는 `snapshotDate`로 현재 snapshot/items를 자체 로드하는 생성자/loader 추가. |
| `AnnualAssetAnalysisPage` | 전체 snapshots/items 리스트를 직접 받음 | 연도/기간 또는 repository 기반 loader 추가 여부 결정. |
| `AssetFormPage` edit | `AssetItem` 객체 직접 전달 | `assetId` edit 생성자 또는 route extra 유지 전략 결정. |
| `HoldingFormPage` edit | `HoldingItem` 객체 직접 전달 | `holdingId` 기반 edit loader 추가. |
| `CashAccountFormPage` edit | `HoldingItem` 객체 직접 전달 | `holdingId` 기반 edit loader 추가. |
| `TransactionFormPage` edit | `TransactionItem` 객체 직접 전달, ledger edit guard 있음 | `transactionId`/`ledgerEventId` 기반 edit loader 및 guard 재검증. |
| `CashTransactionFormPage` edit | `TransactionItem` 객체 직접 전달, ledger edit guard 있음 | `transactionId`/`ledgerEventId` 기반 edit loader 및 guard 재검증. |

## 다음 세부 계획에서 건드릴 수 없는 화면

Plan B 또는 Plan C에서는 아래 화면의 route 구조를 바꾸지 않는다.

- `SnapshotDetailPage`
- `AnnualAssetAnalysisPage`
- 모든 form page의 edit route
- `TransactionFormPage`
- `CashTransactionFormPage`

이 화면들은 Plan A 기준 `사전 리팩터 필요` 또는 `extra 필요`로 분류되며, route 전환은 Plan G/I 또는 별도 리팩터에서만 다룬다.
