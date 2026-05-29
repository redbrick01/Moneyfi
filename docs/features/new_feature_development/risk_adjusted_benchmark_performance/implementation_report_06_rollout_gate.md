# Implementation Report 06 - Rollout Gate

## Summary

`06 Rollout Plan` 범위로 릴리즈 게이트 문서를 추가하고, 01-05 산출물이 빠지지 않았는지 확인하는 문서 검증 테스트를 추가했다.

## Implemented

- 로컬 릴리즈 후보 상태와 Supabase 원격 적용 보류 조건을 `release_gate_06.md`에 정리했다.
- 완료된 게이트와 근거 테스트를 표로 연결했다.
- 운영 Supabase 적용 전 필요한 row count, 핵심 합계, 평균단가/환율 null-zero 분포 확인 항목을 명시했다.
- 사용자에게 보이는 변화와 `데이터 부족` 처리 원칙을 문서화했다.
- 릴리즈 문서와 01-06 구현 보고서, Supabase 초안 문서가 존재하고 핵심 문구를 포함하는지 검증하는 테스트를 추가했다.

## Safety Notes

- Supabase 원격 DB 적용은 2026-05-29에 완료했다.
- 원격 적용 전후 preflight/postflight로 원본 포트폴리오 핵심 합계를 비교했다.
- 릴리즈 게이트 문서는 원본 포트폴리오 테이블 보정 update/delete를 허용하지 않는다.

## Verification

- `flutter analyze test/risk_adjusted_rollout_docs_test.dart`
- `flutter test test/risk_adjusted_rollout_docs_test.dart`
- `flutter test test/widget_test.dart test/page_walkthrough_test.dart test/risk_adjusted_performance_calculator_test.dart test/portfolio_daily_returns_test.dart test/benchmark_data_test.dart test/risk_adjusted_remote_schema_draft_test.dart`
- `flutter test test/transaction_flow_test.dart`
- `flutter analyze lib/pages/investment_performance_page.dart lib/db/app_database.dart lib/db/app_database_records.dart`
- `git diff --check`
