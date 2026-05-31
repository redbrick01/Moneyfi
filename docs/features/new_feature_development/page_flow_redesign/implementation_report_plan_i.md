# Plan I Implementation Report

## 요약

Plan I에서는 form create flow를 `go_router` named route로 전환했다. 기존 `push<bool>` 저장 결과 의미는 `Future<bool?>` helper로 보존했고, 호출자의 `changed == true` reload 구조는 유지했다.

edit route는 무리해서 전환하지 않았다. 현재 edit form은 `AssetItem`, `HoldingItem`, `TransactionItem` 객체를 직접 전달하고, 거래 edit은 ledger-backed guard와 paired transfer/exchange 로직이 얽혀 있어 id 기반 loader 없이 전환하면 위험하다.

## 구현 내용

| 항목 | 결과 |
| --- | --- |
| asset create | `/assets/new` route 등록, `openAssetCreate()` helper 추가 |
| holding create | `/assets/:assetId/holdings/new` route 등록, `openHoldingCreate()` helper 추가 |
| cash account create | `/assets/:assetId/cash-accounts/new` route 등록, `openCashAccountCreate()` helper 추가 |
| transaction create | `/holdings/:holdingId/transactions/new?assetId=...` route 등록, `openTransactionCreate()` helper 추가 |
| cash transaction create | `/cash-accounts/:holdingId/transactions/new?assetId=...` route 등록, `openCashTransactionCreate()` helper 추가 |
| result contract | helper가 `Future<bool?>`를 반환하고 기존 reload 조건 유지 |
| router fallback | router context가 없는 standalone/test 환경에서는 기존 `Navigator.push<bool>` fallback 유지 |
| invalid route | 거래 create route의 `assetId` 누락 시 오류 화면 표시 |
| caller conversion | 홈/포트폴리오/거래 empty, 자산 상세 create, 보유/현금 상세 거래 create 호출부 전환 |

## 보류한 범위

| 보류 대상 | 이유 |
| --- | --- |
| asset edit route | `AssetItem` 객체 직접 전달 구조 유지가 더 안전함 |
| holding edit route | `HoldingItem` 전체 edit 객체 재구성 loader 필요 |
| cash account edit route | 현금 계좌도 `HoldingItem` 기반 edit loader 필요 |
| transaction edit route | ledger-backed edit guard 재검증 필요 |
| cash transaction edit route | transfer/exchange paired ledger 재조회와 guard 필요 |

## 완료 판단

- 선택한 create form routes가 named route로 등록되었다.
- 저장 성공 결과는 기존처럼 `true`로 pop되고, 호출자 reload 조건은 유지된다.
- edit route는 전환하지 않고 기존 push 구조로 보존했다.
- 잘못된 거래 create route는 crash 없이 오류 화면을 표시한다.
- Plan I 이후 후속 작업은 문서에만 남겼고 자동 착수하지 않았다.

## 후속 후보

- form edit id 기반 loader 리팩터.
- transaction edit route 전환 전 ledger event/line loader 설계.
- route-level save result test 보강.
