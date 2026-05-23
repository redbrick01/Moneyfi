# `test/` Guide

이 폴더는 MONEYFY의 Flutter 테스트를 담습니다. 현재 테스트는 UI smoke, 거래 흐름, sync overlay, market data service를 중심으로 구성되어 있습니다.

## Current Tests

| 파일 | 목적 |
| --- | --- |
| `transaction_flow_test.dart` | 자산, 보유, 거래, 현금 흐름의 핵심 동작 검증 |
| `market_data_service_test.dart` | 시세 API 응답 parsing과 fallback 검증 |
| `page_walkthrough_test.dart` | 주요 페이지가 최소 렌더링되는지 확인 |
| `ui_component_smoke_test.dart` | 공통 UI 컴포넌트 smoke test |
| `sync_overlay_test.dart` | 동기화 overlay UI 상태 확인 |
| `asset_item_test.dart` | asset model/helper 동작 확인 |
| `widget_test.dart` | 기본 widget test 진입점 |

## Commands

```bash
flutter test
flutter test test/transaction_flow_test.dart
flutter analyze
```

## When To Add Tests

- 거래, 원장, 현금 계좌 재계산 로직 변경
- Supabase sync payload 구조 변경
- 시장 데이터 parsing 변경
- 공통 컴포넌트 props나 표시 규칙 변경
- 화면 진입 시 필요한 데이터 조건 변경

테스트가 로컬 DB를 사용한다면 기존 테스트의 setup/teardown 패턴을 먼저 따르세요.
