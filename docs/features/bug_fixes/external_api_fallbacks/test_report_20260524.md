# External API Fallbacks Test Report 2026-05-24

## Summary

외부 API 실패 fallback 보강 결과를 기록한다. KIS/Coinone 기존 시세 fallback은 회귀 테스트로 확인하고, OpenAI/Finnhub 계열 요약과 포트폴리오 진단은 local fallback payload 테스트를 추가했다.

## Test Environment

- Date: 2026-05-24
- Workspace: `/Users/yw0410/Desktop/Project/MONEYFY`
- Platform: local Flutter/Dart toolchain

## Commands Run

```bash
dart format lib/services/market_news_summary_service.dart lib/services/company_news_summary_service.dart lib/services/portfolio_diagnosis_service.dart lib/widgets/market_news_summary_card.dart lib/widgets/company_news_summary_card.dart test/external_api_fallback_test.dart
flutter test test/external_api_fallback_test.dart
flutter test test/market_data_service_test.dart
flutter analyze
git diff --check
```

## Command Results

- `dart format ...`: passed after one SDK cache permission retry with escalation.
- `flutter test test/external_api_fallback_test.dart`: passed, 3 tests.
- `flutter test test/market_data_service_test.dart`: passed, 8 tests.
- `flutter analyze`: passed, no issues found.
- `git diff --check`: passed.

## Verification Against Plan

- Market news fallback payload is non-empty and parses into a visible card model.
- Company news fallback creates visible stock/coin items while excluding unsupported asset types.
- Portfolio diagnosis fallback keeps summary, score, risk, suggestions, uncertainty, and source populated.
- Existing KIS/Coinone fallback behavior remains covered by market data service tests.

## Manual QA Status

- Not run in this patch. API failure presentation behavior should still be checked in an emulator or device with failed/blocked external API responses.

## Responsive QA Status

- Not run in this patch.

## Acceptance Criteria Result

- Passed for automated verification.
- Manual API failure and responsive QA remain pending.

## Risk Assessment After Testing

- Residual risk is low for service payload regressions.
- Residual risk remains medium for exact presentation-screen behavior because emulator/device QA with forced API failures was not run.

## Follow-Up Recommendations

- Add injectable Supabase function client tests for exact HTTP status and payload failure paths.
- Add widget-level coverage for fallback cards on mobile width.

## Final Result

- Automated verification passed. Manual presentation QA remains a release checklist item.
