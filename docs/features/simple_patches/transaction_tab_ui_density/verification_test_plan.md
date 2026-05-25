# Transaction Tab UI Density Verification Test Plan

## Scope

- 거래 탭 row 레이아웃 밀도 개선.
- 거래 금액 KRW 중심 표시.
- 매수/매도 거래 row 표시 금액을 단가가 아닌 거래 총액 기준으로 보정.
- 거래 금액 색상을 외부 입금/출금만 강조하고 내부 거래는 중립색으로 표시.
- 거래 입력 폼에 읽기 전용 거래금액 프리뷰 추가.
- 하단 탭 라벨 밀도 개선.
- 화면 진입 및 정적 분석 회귀 확인.

## Automated Test Plan

```bash
flutter test test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 거래 탭에서 거래명과 계좌명이 스크린샷보다 덜 잘리는지 확인한다.
- 금액 영역이 과도하게 넓지 않은지 확인한다.
- USD 원천 거래도 거래 탭에서는 KRW 환산 금액으로 표시되는지 확인한다.
- 매수/매도 거래는 단가가 아니라 `단가 * 수량` 총액으로 표시되는지 확인한다.
- 외부 입금은 초록색, 외부 출금은 빨간색, 매수/매도/이체/환전은 검정색으로 표시되는지 확인한다.
- 투자 거래 폼에서 단가와 수량 입력 시 거래금액이 즉시 갱신되는지 확인한다.
- 현금 거래 폼에서 금액 입력 시 거래금액 프리뷰가 즉시 갱신되는지 확인한다.
- 하단 탭에서 `포트폴리오` 라벨 잘림이 사라졌는지 확인한다.

## Acceptance Criteria

- 거래 행 가운데 정보 영역이 기존보다 넓어진다.
- 금액은 모든 거래에서 KRW 기준으로 표시된다.
- 매수/매도 표시 금액은 `grossAmount`가 있으면 이를 우선하고, 없으면 단가와 수량의 곱을 사용한다.
- 금액 색상은 `deposit`/`입금`만 positive, `withdrawal`/`출금`만 negative, 나머지 거래 액션은 중립색이다.
- 입력 폼 거래금액 프리뷰는 저장 payload를 바꾸지 않는다.
- 하단 탭 라벨이 6개 구성에서도 겹치지 않는다.
- walkthrough, transaction flow, analyzer가 통과한다.

## Residual Risk

자동 테스트는 실제 픽셀 레이아웃을 보장하지 않는다. 스크린샷 기반 수동 QA가 필요하다.
