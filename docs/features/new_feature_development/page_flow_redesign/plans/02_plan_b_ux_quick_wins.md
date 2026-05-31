# Plan B. UX Quick Wins

## 역할

라우팅 구조를 바꾸지 않고 현재 사용자 여정의 큰 마찰만 줄인다.

## 범위

- `PortfolioPage`에서 자산 상세 진입 추가.
- 거래 탭 계좌 없음 빈 상태에 `자산 추가` CTA 추가.
- 포트폴리오 빈 상태 문구에서 `Home` 직접 언급 제거.
- My 탭의 GPT용 DB 요약 복사 기능은 유지하되 명칭/묶음만 정돈.

## 제외

- route registry 추가.
- `go_router` 도입.
- 5탭 통합.
- 포트폴리오 진단 상세 구조 변경.

## 산출물

- 코드 변경.
- `docs/features/new_feature_development/page_flow_redesign/implementation_report_plan_b.md`
- 필요 시 `test_report_plan_b.md`

## 대상 파일

| 파일 | 역할 |
| --- | --- |
| `lib/pages/portfolio_page.dart` | 포트폴리오 탭 자산 상세 진입, 빈 상태 문구 수정 |
| `lib/pages/transactions_page.dart` | 계좌 없음 empty state에서 자산 추가 CTA 제공 |
| `lib/pages/my_page.dart` | GPT용 DB 요약 복사 액션 명칭/묶음 정돈 |
| `test/page_walkthrough_test.dart` | 포트폴리오/거래/My 변화에 대한 targeted widget test 후보 |
| `test/widget_test.dart` | 필요 시 shell smoke 또는 form smoke 보강 |

## 세부 작업

### B1. 포트폴리오 탭 자산 상세 진입

목표:

- 사용자가 `포트폴리오` 탭의 자산 비중/리밸런싱 영역에서 특정 자산을 발견했을 때 홈으로 돌아가지 않고 바로 `AssetDetailPage`로 이동할 수 있게 한다.

구현 후보:

- `portfolio_page.dart`에 `AssetDetailPage` import 추가.
- `_AllocationSectionCard`에 `ValueChanged<int>` 또는 `ValueChanged<_AllocationItem>` 형태의 상세 진입 콜백 추가.
- `AllocationLegendRow`의 현재 `onTap`은 선택 토글에 쓰이고 있으므로, 탭 동작을 바꿀 경우 차트 선택 UX와 충돌하지 않게 결정해야 한다.
- 권장안: legend row의 주 동작을 상세 진입으로 바꾸기보다, row 내부 trailing 또는 별도 icon button을 추가해 상세 진입을 제공한다.
- 대안: row tap은 상세 진입, donut slice tap은 선택 유지. 이 경우 선택/상세 역할 변경을 테스트와 UX 문구로 명확히 한다.
- 상세에서 돌아온 뒤 `PortfolioPage`는 `_pageFuture = _loadPortfolioPageData()`로 갱신한다.

주의:

- `AssetFormPage` edit route 구조는 건드리지 않는다.
- `AssetDetailPage` 내부의 holding/cash/transaction route는 건드리지 않는다.
- route registry나 named route helper를 만들지 않는다.

### B2. 거래 탭 계좌 없음 empty CTA

목표:

- 거래 탭에서 계좌가 없을 때 사용자가 막히지 않고 바로 첫 자산을 추가할 수 있게 한다.

구현 후보:

- `transactions_page.dart`에 `AssetFormPage` import 추가.
- `_TransactionsPageState`에 `_openAssetFormForEmptyState()` 추가.
- `data.entries.isEmpty && data.accounts.isEmpty`일 때 `EmptyStateCard`의 `actionLabel`을 `자산 추가`로 설정.
- `onAction`은 `AssetFormPage`를 `push<bool>`로 열고, `changed == true`면 `_pageFuture = _loadPageData()`로 갱신한다.
- 기존 `data.accounts.isEmpty`일 때 상단 `거래 추가` icon button 비활성화는 유지한다.

주의:

- 거래 유형 선택 sheet 구조는 바꾸지 않는다.
- `TransactionFormPage`/`CashTransactionFormPage`는 건드리지 않는다.
- 자산 추가 후 보유 종목/현금 계좌까지 이어지는 온보딩은 Plan F 범위다.

### B3. 포트폴리오 빈 상태 문구 수정

목표:

- 포트폴리오 탭에서 자산 추가 버튼을 제공하면서도 설명 문구가 `Home`으로 돌아가라고 오해시키지 않게 한다.

대상 문구:

- 현재: `Home에서 자산을 등록한 뒤 포트폴리오 비중과 리밸런싱을 확인하세요.`
- 후보: `자산을 등록한 뒤 포트폴리오 비중과 리밸런싱을 확인하세요.`

주의:

- Empty state 레이아웃이나 버튼 구조는 바꾸지 않는다.

### B4. My 탭 GPT용 DB 요약 복사 정돈

목표:

- 자주 쓰는 기능인 `내부 DB 요약 복사 (GPT)`를 숨기지 않고 접근성을 유지한다.
- 다만 내부 구현 도구처럼 보이는 이름을 사용 목적 중심으로 다듬는다.

구현 후보:

- title 후보: `GPT용 DB 요약 복사`
- subtitle 후보: `포트폴리오 분석에 쓸 요약 데이터를 클립보드에 복사해요`
- 성공 snackbar 후보: `GPT용 DB 요약을 클립보드에 복사했어요.`
- 현재 섹션 안에 유지하되, 가능하면 `데이터 활용` 또는 `GPT 연계` 소제목/묶음으로 분리한다.

주의:

- 기능을 숨기지 않는다.
- debug/profile 조건을 추가하지 않는다.
- 복사 payload 구조는 바꾸지 않는다.
- 계정/동기화 동작은 바꾸지 않는다.

## 건드리지 말 것

- `SnapshotDetailPage`
- `AnnualAssetAnalysisPage`
- 모든 form page의 edit route 구조
- `TransactionFormPage`
- `CashTransactionFormPage`
- `go_router`, `MaterialApp.router`, route registry/helper
- 5탭 통합
- 포트폴리오 진단 상세 구조

## 테스트 계획

자동 테스트 후보:

- `flutter analyze`
- `flutter test test/page_walkthrough_test.dart`
- 필요 시 `test/page_walkthrough_test.dart`에 아래 targeted widget test 추가:
  - 포트폴리오 탭 empty state 문구가 `Home에서`를 포함하지 않는지 확인.
  - 거래 탭 계좌 없음 empty state에서 `자산 추가` CTA가 보이는지 확인.
  - My 탭 로그인 상태 테스트가 어렵다면, 최소한 title/subtitle 문자열은 widget 단위 또는 별도 helper 분리 후 확인.

수동 QA:

- 포트폴리오 탭에서 자산 상세 진입 후 뒤로 돌아왔을 때 포트폴리오 탭이 유지되는지 확인.
- 거래 탭 빈 상태에서 `자산 추가`를 눌러 `AssetFormPage`가 열리는지 확인.
- 자산 추가 저장 후 거래 탭 데이터가 다시 로드되는지 확인.
- My 탭에서 GPT용 DB 요약 복사 기능이 계속 노출되고 기존처럼 복사되는지 확인.

## 회귀 위험

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| `AllocationLegendRow` tap 의미 변경으로 donut 선택 UX가 사라짐 | 중간 | row tap/상세 진입 역할을 명확히 분리하거나 테스트로 고정 |
| 거래 empty CTA가 자산만 만들고 거래 가능 상태까지 이어지지 않음 | 낮음 | Plan B에서는 첫 자산 추가까지만 범위로 명시, 후속 온보딩은 Plan F |
| My 탭 기능을 별도 묶음으로 옮기며 접근성이 떨어짐 | 중간 | My 탭에서 계속 1급 액션으로 보이게 유지 |
| `AssetFormPage` 저장 후 거래 탭 reload 누락 | 중간 | `changed == true`일 때 `_pageFuture = _loadPageData()` 확인 |

## 완료 체크리스트

- [x] `PortfolioPage`에서 자산 상세 진입이 가능하다.
- [x] 자산 상세에서 뒤로 돌아왔을 때 포트폴리오 탭 데이터가 갱신된다.
- [x] 거래 탭 계좌 없음 empty state에 `자산 추가` CTA가 표시된다.
- [x] 거래 탭의 계좌 있음 empty state는 기존 `거래 추가` CTA를 유지한다.
- [x] 포트폴리오 빈 상태 문구에서 `Home` 직접 언급이 제거된다.
- [x] GPT용 DB 요약 복사 기능은 My 탭에서 계속 빠르게 찾을 수 있다.
- [x] GPT용 DB 요약 복사 payload 구조는 변경되지 않는다.
- [x] `SnapshotDetailPage`, `AnnualAssetAnalysisPage`, form edit route, transaction form route를 건드리지 않았다.
- [x] `flutter analyze` 결과가 기록된다.
- [x] 관련 자동 테스트 또는 수동 QA 결과가 `test_report_plan_b.md` 또는 구현 리포트에 기록된다.

## 완료 조건

- 사용자는 홈을 거치지 않고 포트폴리오 탭에서 특정 자산 상세로 들어갈 수 있다.
- 계좌가 없는 거래 탭에서 자산 추가 폼으로 바로 진입할 수 있다.
- GPT용 DB 요약 복사 기능은 My 탭에서 계속 빠르게 찾을 수 있다.
- `flutter analyze`와 관련 테스트 또는 수동 QA 결과가 기록된다.
- 완료 후 다음 계획을 자동으로 시작하지 않는다.
