# Plan I Test Report

## 실행 결과

| 명령 | 결과 | 메모 |
| --- | --- | --- |
| `dart format lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_router.dart lib/navigation/moneyfy_navigation.dart lib/pages/portfolio_dashboard_page.dart lib/pages/portfolio_page.dart lib/pages/transactions_page.dart lib/pages/asset_detail_page.dart lib/pages/holding_detail_page.dart lib/pages/cash_account_detail_page.dart test/router_smoke_test.dart` | 통과 | 수정 파일 포맷 완료 |
| `flutter analyze` | 통과 | `No issues found!` |
| `flutter test test/router_smoke_test.dart` | 통과 | form create route 및 invalid route smoke 추가 |
| `flutter test test/page_walkthrough_test.dart` | 통과 | 기존 page/form first-frame smoke 유지 |
| `flutter test test/widget_test.dart` | 통과 | form shortcut/widget regression |
| `flutter test test/transaction_flow_test.dart` | 통과 | ledger/domain regression |

## Router Smoke Coverage

| route | 확인 |
| --- | --- |
| `/assets/new` | `AssetFormPage` first frame |
| `/assets/-101/holdings/new` | `HoldingFormPage` first frame |
| `/assets/-101/cash-accounts/new` | `CashAccountFormPage` first frame |
| `/holdings/-102/transactions/new?assetId=-101&defaultName=...` | `TransactionFormPage` first frame |
| `/cash-accounts/-202/transactions/new?assetId=-201&defaultName=...` | `CashTransactionFormPage` first frame |
| `/holdings/-102/transactions/new` | invalid route error |

## 특이사항

- edit route는 Plan I에서 전환하지 않았다.
- create route 전환은 helper의 `Future<bool?>` 반환으로 기존 `changed == true` reload 조건을 보존한다.
- 거래 create route 직접 진입에는 `assetId` query가 필요하다. 누락 시 오류 화면으로 처리한다.
