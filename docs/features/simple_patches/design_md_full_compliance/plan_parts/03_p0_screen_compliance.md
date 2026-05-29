# 03 P0 Screen Compliance

## 목표

사용자 주요 흐름에 해당하는 P0 화면을 모바일 design-md 기준에 맞춘다.

P0는 앱의 첫인상과 반복 사용 흐름에 직접 영향을 주므로, 360/390/430dp와 text scale 1.3에서 overflow 없이 동작해야 한다.

## 대상 화면

| Batch | 대상 파일 |
| --- | --- |
| P0-A Shell | `lib/pages/app_shell_page.dart`, `lib/ui_scaffold/**`, `lib/widgets/moneyfy_ui.dart` |
| P0-B Dashboard/Portfolio | `lib/pages/portfolio_dashboard_page.dart`, `lib/pages/portfolio_page.dart` |
| P0-C Transactions | `lib/pages/transactions_page.dart`, `lib/components/transaction_history_list.dart`, `lib/components/rows/transaction_row.dart` |
| P0-D Detail | `lib/pages/asset_detail_page.dart`, `lib/pages/holding_detail_page.dart`, `lib/pages/cash_account_detail_page.dart`, `lib/pages/snapshot_detail_page.dart` |
| P0-E Forms/Sheets | `lib/pages/forms/**`, `lib/pages/target_allocation_sheet.dart` |

## 구현 작업

1. 1단계의 `needs fix` 목록을 batch별로 묶는다.
2. 공용 컴포넌트 contract로 해결 가능한 항목은 페이지 ad-hoc 수정 대신 component 사용으로 전환한다.
3. 긴 금액, 긴 종목명, 긴 한글 라벨이 360dp에서 overflow되지 않도록 trailing width, wrap, maxLines, flex를 조정한다.
4. primary blue 남발, semantic filled background, card nesting을 제거하거나 예외 문서화한다.
5. sticky CTA, keyboard, safe area가 겹치지 않는지 확인한다.

## 화면별 세부 기준

### Shell

- bottom navigation은 selected item만 primary blue.
- 비활성 item은 muted gray.
- page scaffold inset과 bottom inset이 일관적이어야 한다.

### Dashboard / Portfolio

- 핵심 자산 금액은 calm number hierarchy.
- summary card와 asset row는 hairline/soft surface 중심.
- 수익률은 green/red text-only.
- chart legend는 모바일에서 줄바꿈 또는 스크롤 전략이 있어야 한다.

### Transactions

- filter/search/sort control은 pill 또는 icon control로 정리.
- 거래 row trailing 금액은 tabular/number role.
- swipe action color는 destructive/primary 역할이 분명해야 한다.

### Detail Pages

- detail header는 product-ui-card-light 변형으로 통일.
- metric grid와 key-value row가 같은 hierarchy를 가져야 한다.
- chart tooltip과 action icon이 화면 밖으로 나가지 않아야 한다.

### Forms / Sheets

- text input은 48dp height, 12dp radius, focus border primary blue.
- primary submit만 blue.
- percentage shortcut chip은 pill.
- keyboard와 bottom CTA가 겹치지 않아야 한다.

## 산출물

- P0 batch별 implementation report
- `screenshots/after/{screen}_{state}_{width}dp.png`
- `audit_matrix.md` P0 result 업데이트

## 검증

Batch별 파일 단위:

```bash
flutter analyze <changed files>
```

P0 batch 종료 시:

```bash
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

## 완료 기준

- P0 audit 항목이 pass 또는 승인된 exception.
- P0 화면이 360/390/430dp 중 최소 2개 폭과 text scale 1.3에서 overflow 없음.
- P0 audit row마다 after screenshot 또는 명시적 manual QA note가 있음.
- `page_walkthrough_test.dart`가 해당 batch의 주요 진입 경로를 커버하지 못하면 manual QA note에 보완 절차가 기록됨.
- 금액/비율/수익률이 number role 또는 tabular figure를 사용.
- primary blue와 semantic green/red 사용 범위가 design-md 기준을 벗어나지 않음.
