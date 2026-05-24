# Ledger Numeric Regression Verification Test Plan

## Scope

원장, 현금, 환전, 스냅샷 표시 계산의 핵심 수치 회귀 테스트 추가를 검증합니다.

## Quality Goals

- 여러 거래 유형이 한 fixture에 섞여도 최종 state와 aggregate가 일치합니다.
- cash account client reference가 포함된 원격 snapshot payload가 로컬 row로 정확히 표시됩니다.
- 기존 transaction flow와 전체 Flutter 테스트가 계속 통과합니다.

## Automated Test Plan

| Command | Purpose |
| --- | --- |
| `flutter test test/transaction_flow_test.dart` | 원장/현금/환전/스냅샷 집중 회귀 테스트 |
| `flutter analyze` | 정적 분석 |
| `flutter test` | 전체 테스트 회귀 확인 |

## Manual QA Plan

- UI 변경이 없으므로 필수 수동 QA는 없습니다.
- 필요 시 샘플 데이터로 투자성과, 자산 상세, 스냅샷 상세 화면에서 동일 수치를 육안 확인합니다.

## Responsive Checklist

- 화면 레이아웃 변경 없음.
- 반응형 QA는 대상 아님.

## Regression Test Commands

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test
```

## Acceptance Criteria

- 복합 ledger regression test가 명시 기대값을 통과합니다.
- snapshot cash account regression test가 remap과 balance/currency 값을 통과합니다.
- `flutter analyze`와 `flutter test`가 통과합니다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| 복합 fixture 기대값 오류 | Low | Medium | 수식을 문서화하고 개별 state/aggregate를 함께 검증 |
| production 회귀 미포착 | Medium | Medium | 후속 서버 snapshot function integration test 추가 |
| 테스트 실행 시간 증가 | Low | Low | 기존 transaction flow 파일에 소수 테스트만 추가 |

## Future Test Expansion

- Edge Function `create-portfolio-snapshot` 산출 payload integration test
- 삭제/수정 후 복합 원장 aggregate 회귀 테스트
- 다중 통화 valuation KRW 환산 화면 테스트
