# Plan H-Impl Implementation Report

## 요약

Plan H 결정에 따라 하단 탭을 `홈`, `포트폴`, `거래`, `분석`, `My` 5개로 통합했다. `통계` 기능은 제거하지 않고 `/statistics` 호환 route와 분석 탭의 진입 카드로 보존했다.

## 구현 내용

| 항목 | 결과 |
| --- | --- |
| Shell destination | `통계` 하단 탭 제거 |
| Shell page count | `IndexedStack`을 5탭 기준으로 정리 |
| `/statistics` route | `shellCompatiblePaths`에 남겨 직접 진입 보존 |
| selected tab mapping | `/statistics` 진입 시 `분석` 탭 selected 처리 |
| AnalysisPage | `통계` 진입 카드 추가 |
| Navigation helper | `context.openStatistics()` 추가, router 미존재 시 `Navigator.push` fallback 제공 |
| StatisticsPage | 기능 제거 없이 유지 |
| Tests | 5탭 shell과 `/statistics` compatibility 기준으로 갱신 |

## 제외 유지

- `StatisticsPage` 대규모 UI 재설계.
- `SnapshotDetailPage`, `AnnualAssetAnalysisPage` id 기반 loader 전환.
- form named route 전환.
- My 탭 또는 `내부 DB 요약 복사 (GPT)` 기능 이동.
- auth redirect 정책 추가.

## 완료 판단

- 하단 탭은 5개로 축소되었다.
- `/statistics` 직접 진입은 유지된다.
- `/statistics` 화면에서 하단 selected tab은 `분석`으로 처리된다.
- 분석 탭에서 통계 화면으로 진입할 수 있다.
- 통계 기능과 My 탭 GPT 유틸리티는 제거하거나 이동하지 않았다.
- Plan I는 시작하지 않았다.

## 후속 후보

- Plan I: form named route와 id 기반 edit loader 전환.
- Snapshot/annual analysis id 기반 loader 리팩터.
- 분석 탭 과밀도 점검 및 통계 진입 카드 배치 미세 조정.
