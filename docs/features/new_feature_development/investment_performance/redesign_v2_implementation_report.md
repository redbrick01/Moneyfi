# Investment Performance Redesign v2 Implementation Report

작성일: 2026-05-30

## Scope

`00~06` 계획서를 기준으로 `lib/pages/investment_performance_page.dart`의 화면 구조를 성과 대시보드형 IA로 재구성했다.

이번 구현 범위:

- 첫 화면 `성과 판단` 영역
- `참고 벤치마크` strip
- `성과 원인`
- `총자산 변화 검산`
- `월별 확정 성과`
- `종목별 기여도`
- `위험 해석`
- `데이터 기준/제외 항목`

## Commands

- `flutter analyze lib/pages/investment_performance_page.dart`: pass
- `flutter analyze lib/pages/investment_performance_page.dart test/page_walkthrough_test.dart`: pass
- `flutter test test/widget_test.dart`: pass
- `flutter test test/page_walkthrough_test.dart --plain-name "investment performance explains redesigned dashboard"`: pass

## Implementation Notes

- 기존 카드 나열 구조를 `성과 판단 -> 성과 원인 -> 총자산 변화 검산 -> 월별 확정 성과 -> 종목별 기여도 -> 위험 해석 -> 데이터 기준/제외 항목` 순서로 변경했다.
- `_InvestmentPerformanceViewModel`, `_MetricValue`, `_MetricUnavailableReason`, `_ReconciliationState`를 추가해 UI가 null 값을 직접 해석하지 않도록 했다.
- 기간 수익률은 입출금 보정 기준으로 상단 대표 지표에 배치했고, 순 투자성과 금액은 영향도 설명 지표로 낮췄다.
- S&P 500은 `참고 벤치마크`로 표시하고, 위험 해석 영역에서는 벤치마크 비교를 중복 표시하지 않는다.
- 월별 섹션은 `월별 확정 성과`로 이름을 바꾸고 `미실현 평가 변화는 포함하지 않습니다.`를 명시했다.
- 종목별 비용 배분은 도입하지 않고, 비용 미배분 caption을 표시했다.
- 스냅샷이 충분하면 총자산 변화 검산을 표시하고, 부족하면 성과와 외부 입출금 연결 fallback을 표시한다.

## Remaining Risks

- 실제 360/390/430dp 기기별 screenshot QA는 아직 수행하지 않았다.
- 스냅샷 시작/종료 선택 방식은 v2 구현에서 보수적으로 처리했으며, 더 정교한 기간 경계 선택은 후속 결정이 필요하다.
- 환율 없음 상태는 기존 `fetchLatestExchangeRate() ?? 1.0` 동작을 유지했다. 환율 unavailable 모델링은 별도 데이터 계약 확장이 필요하다.
