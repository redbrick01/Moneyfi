# Test Coverage Matrix

Plan A 산출물. 현재 페이지/라우팅 개편과 관련된 테스트 커버리지를 정리했다.

## 주요 테스트 파일

| 테스트 파일 | 현재 커버리지 | 페이지 개편 관련성 |
| --- | --- | --- |
| `test/page_walkthrough_test.dart` | 탭 방문, 분석 진입 카드, 독립 페이지 1프레임 렌더, 일부 거래 폼 UI | 가장 중요. 라우팅/페이지 smoke 기준선. |
| `test/widget_test.dart` | 앱 shell smoke, 거래 폼 shortcut, 폼 UI 동작 | 폼 유지/저장 UI 회귀 기준. |
| `test/transaction_flow_test.dart` | 거래/ledger/db 계산/동기화 도메인 로직 | 폼 route 전환 후 저장 결과 회귀 기준. |
| `test/ui_component_smoke_test.dart` | 공통 UI 컴포넌트 smoke | 페이지 표면 변경 시 보조 기준. |
| `test/sync_overlay_test.dart` | SyncOverlay 상태 렌더 | 독립 navigation 대상 아님. |
| `test/profile_management_test.dart` | 비밀번호 변경 validation | My 탭 계정 액션 보조 기준. |
| `test/external_api_fallback_test.dart` | 뉴스/진단 fallback | 분석/진단 화면 데이터 fallback 보조 기준. |
| `test/benchmark_data_test.dart`, `test/portfolio_daily_returns_test.dart`, `test/risk_adjusted_*` | 성과/벤치마크 계산 | 투자성과 페이지 내부 계산 보조 기준. |

## Page Walkthrough Coverage

| 화면 | 현재 테스트 | 커버 수준 | 보강 필요 |
| --- | --- | --- | --- |
| `MoneyfyApp` / `AppShellPage` | `stage 1: app shell visits every bottom tab`, `Moneyfy app renders shell smoke test` | 중간 | router 전환 후 initial route와 tab persistence 추가. |
| `PortfolioDashboardPage` | AppShell 탭 방문으로 간접 확인 | 낮음 | 자산 상세 진입/자산 추가 CTA 테스트 필요. |
| `PortfolioPage` | AppShell 탭 방문, standalone 없음 | 낮음 | 자산 상세 진입, 목표 비중 sheet, 진단 카드 focus 테스트 필요. |
| `TransactionsPage` | standalone build, pull refresh, grouping unit test | 중간 | 계좌 없음 empty CTA, 거래 추가 sheet test 필요. |
| `AnalysisPage` | entry cards open child pages | 높음 | 진단 통합 후 목적지 단일성 테스트 필요. |
| `StatisticsPage` | AppShell 탭 방문만 확인 | 낮음 | 스냅샷 상세/연도 분석 진입 테스트 필요. |
| `MyPage` | AppShell 탭 방문, data scoped replacement tests | 중간 | GPT용 DB 요약 복사 액션 위치/명칭 테스트 필요. |
| `AssetDetailPage` | standalone first frame | 낮음 | edit/delete/holding row navigation은 미커버. |
| `HoldingDetailPage` | standalone first frame | 낮음 | edit/transaction form navigation은 미커버. |
| `CashAccountDetailPage` | standalone first frame | 낮음 | edit/cash transaction form navigation은 미커버. |
| `SnapshotDetailPage` | standalone first frame with object extra | 낮음 | route 재조회 전환 전까지 named route 테스트 불가. |
| `AnnualAssetAnalysisPage` | standalone first frame with object lists | 낮음 | 월별 row -> snapshot detail navigation 미커버. |
| `PortfolioAnalysisMvpPage` | Analysis entry card opens | 중간 | 홈/포트폴리오/분석 진입점 통합 후 보강 필요. |
| `InvestmentPerformancePage` | Analysis entry card, advanced metric copy test, standalone | 높음 | named route smoke 추가 필요. |
| `DividendInterestAnalysisPage` | Analysis entry card, standalone | 중간 | named route smoke 추가 필요. |
| `LoginPage` | standalone first frame | 낮음 | Login -> Signup navigation 미커버. |
| `SignupPage` | standalone first frame | 낮음 | signup success pop 미커버. |
| `AssetFormPage` | standalone first frame | 낮음 | save returns true 미커버. |
| `HoldingFormPage` | standalone first frame | 낮음 | save returns true, search 미커버. |
| `CashAccountFormPage` | standalone first frame | 낮음 | save returns true 미커버. |
| `TransactionFormPage` | standalone, market search, default include, shortcuts in widget tests | 중간 | route edit/load path 미커버. |
| `CashTransactionFormPage` | standalone, default include, shortcuts in widget tests | 중간 | route edit/load path 미커버. |

## Route-Level Test Gaps

라우터 전환 이후 추가해야 할 테스트:

| 테스트 | 목적 | 적용 시점 |
| --- | --- | --- |
| initial location smoke: `/home`, `/portfolio`, `/transactions`, `/insights`, `/statistics`, `/my` | 각 탭 route 직접 진입 확인 | Plan G |
| named route push/pop: `assetDetail`, `holdingDetail`, `cashAccountDetail` | 주요 상세 route 이동 확인 | Plan G |
| unknown route/error route | 잘못된 URL 처리 확인 | Plan G |
| tab persistence | 탭 전환 후 스크롤/상태 유지 확인 | Plan G |
| startup error route/state | `_StartupGate` 오류 흐름 보존 | Plan G |
| form save pop result | `push<bool>` 갱신 보존 | Plan I |
| snapshot route loader | `SnapshotDetailPage` 자체 로드 전환 확인 | 별도 리팩터 또는 Plan G 후보 |

## Plan별 최소 검증 기준

| 계획 | 최소 자동 테스트 | 수동 QA |
| --- | --- | --- |
| Plan A | 문서 산출물 검토 | 없음 |
| Plan B | `flutter analyze`, 관련 `page_walkthrough_test` 또는 targeted widget test | 포트폴리오 자산 상세 진입, 거래 empty CTA, My GPT 액션 확인 |
| Plan C | `flutter analyze`, `page_walkthrough_test`, `widget_test` shell smoke | helper 전환된 이동 push/pop 확인 |
| Plan D | `page_walkthrough_test` analysis entry, 신규 진단 통합 test | 홈/포트폴리오/분석 진단 진입 |
| Plan E | `flutter analyze`, `page_walkthrough_test` 탭/진입 smoke | 분석/통계 문구와 기존 진입 유지 |
| Plan F | `flutter analyze`, `transaction_flow_test`, 관련 widget form tests | 빈 DB 첫 자산/거래 생성 플로우 |
| Plan G | `flutter analyze`, `router_smoke_test`, `page_walkthrough_test`, `widget_test`, `transaction_flow_test` | 6탭 유지, route 직접 진입, detail/auth route smoke |
| Plan H-Impl | `flutter analyze`, `router_smoke_test`, `page_walkthrough_test`, `widget_test`, `transaction_flow_test` | 5탭 shell, `/statistics` 호환 route, 분석 탭 통계 진입점 |
| Plan H | 문서 결정 리뷰 | 없음 |
| Plan I | `flutter analyze`, `router_smoke_test`, `page_walkthrough_test`, `widget_test`, `transaction_flow_test` | form create route smoke, invalid route, 기존 edit/push 결과 보존 |

## 현재 커버리지 결론

- 현재 테스트는 탭 방문과 일부 주요 페이지 렌더링을 확인하지만, route-level 테스트는 없다.
- `AnalysisPage` 하위 페이지 진입은 비교적 잘 커버된다.
- `PortfolioPage`, `StatisticsPage`, 상세 페이지의 실제 navigation 행동은 약하다.
- 폼 저장 후 `push<bool>` 갱신은 코드상 핵심 의존성이지만 widget route 레벨 테스트는 부족하다.
- Plan B/C는 기존 테스트에 targeted widget test를 소량 추가하면 충분하다.
- Plan G/I는 반드시 route-level 테스트를 새로 추가해야 한다.
