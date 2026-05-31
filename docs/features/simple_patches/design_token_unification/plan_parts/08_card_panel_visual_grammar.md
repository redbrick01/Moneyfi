# 08 카드/패널 시각 문법 통일

## 목표

토큰을 쓰고 있는지 확인하는 단계를 넘어서, 앱에 보이는 카드와 패널이 같은 제품 문법으로 보이도록 표면 위계를 통일한다.

현재 상태는 "대부분 토큰을 사용한다"는 기준에서는 통과지만, 화면별로 `SectionCard`, `MoneyfySurfaceCard`, 직접 `Container + BoxDecoration`, 내부 타일, 상태 패널이 섞여 있다. 그래서 사용자가 보기에는 카드 높이, 배경감, 테두리, 그림자, 내부 여백, 중첩 표면이 중구난방으로 느껴질 수 있다.

이 단계의 목표는 새 디자인을 만드는 것이 아니라, 같은 정보 위계에는 같은 표면 문법을 적용하는 것이다.

## 문제 정의

현재 사용자 관점에서 어긋나 보이는 주요 원인:

- 큰 섹션 카드와 내부 타일이 모두 "카드"처럼 보여 위계가 흐려진다.
- `surfaceBase`, `surfaceRaised`, `neutralSurfaceBase`, `neutralSurfaceRaised`, `ColorScheme.surfaceContainer*`가 비슷한 역할에 섞여 있다.
- 일부 화면은 `SectionCard`의 얇은 테두리 중심 문법을 쓰고, 일부 화면은 직접 `Container`와 그림자 단계를 쓴다.
- 뉴스 카드, 대시보드 카드, 상세 화면 카드 섹션이 비슷하지만 조금씩 다른 껍데기를 구현한다.
- 내부 패널이 `radiusCard`를 쓰는 곳과 `rMd/rLg`를 쓰는 곳이 섞여 중첩 카드처럼 보인다.
- 그림자 토큰은 비어 있거나 약하지만, 코드상 `level1/2/3` 단계가 여러 곳에 남아 있어 의도가 흐릿하다.

## 하지 않는 일

- 정보 구조, 화면 이동, 계산, 동기화, DB 동작 변경
- 모든 직접 `Container` 제거
- 차트/캔버스 계산용 좌표 통일
- 화면별 콘텐츠 재배치 또는 마케팅식 리디자인
- 한 번에 모든 페이지를 대규모로 교체

## 표면 단계

앞으로 카드/패널은 아래 5단계 중 하나로 분류한다.

| 단계 | 이름 | 역할 | 기준 구현 |
| --- | --- | --- | --- |
| L0 | 페이지 바탕 | 앱 배경, 스캐폴드, 스크롤 본문 | `AppPageScaffold`, `context.colors.neutralBackground` |
| L1 | 섹션 카드 | 화면의 주 정보 블록, 목록/차트/요약 카드 | `SectionCard` 또는 `MoneyfySurfaceCard` |
| L2 | 내부 패널 | L1 안의 하위 묶음, 요약 박스, 내장 행 그룹 | 새 보조 컴포넌트 또는 `rMd`와 얇은 테두리를 쓰는 토큰 기반 패널 |
| L3 | 지표 타일 | 숫자/상태/라벨을 담는 작은 반복 타일 | 새 보조 컴포넌트 또는 조밀한 여백을 쓰는 토큰 기반 타일 |
| L4 | 임시 부유 표면 | 바텀시트, 팝오버 메뉴, 다이얼로그성 임시 표면 | 시트/메뉴 보조 컴포넌트, `radiusSheet` 또는 상단 `rLg` |

## 시각 문법 규칙

### L1 섹션 카드

L1은 "한 화면에서 사용자가 카드로 인식하는 가장 큰 단위"다.

규칙:

- `SectionCard` 또는 `MoneyfySurfaceCard`를 우선 사용한다.
- 배경은 일반 카드에는 `VisualSpec.surface.cardBase`, 헤더/히어로처럼 강조가 필요한 카드에는 제한적으로 `cardRaised`를 쓴다.
- 반경은 `VisualSpec.surface.radiusCard`를 쓴다.
- 내부 여백은 `context.cardPadding()`을 쓴다.
- 테두리는 `SectionCard`의 1px hairline 기준을 따른다.
- 기본적으로 새 그림자를 추가하지 않는다. 떠 있는 표면이 아닌 인페이지 카드는 그림자 없이 계층을 만든다.
- 헤더 글자는 밀도에 따라 `context.typography.sectionTitle` 또는 `cardTitle`을 쓴다.

금지:

- L1 안에 또 다른 L1처럼 보이는 카드를 넣지 않는다.
- 명시적 상태/경고 표면이 아닌데 L1 전체를 semantic 색상 배경으로 채우지 않는다.
- 같은 L1 껍데기 안에서 `radiusCard`와 `rMd`를 임의로 섞지 않는다.

### L2 내부 패널

L2는 L1 내부에서 정보를 묶는 부드러운 보조 표면이다.

규칙:

- 배경은 부모 대비에 따라 `context.colors.neutralSurfaceRaised` 또는 `context.surfaces.surfaceBase`를 쓴다.
- 반경은 `context.radius.rMd`를 쓴다.
- 여백은 기본적으로 `context.spacing.sm + context.spacing.xs / 4`, 데이터 블록에는 `context.spacing.md`를 쓴다.
- 필요할 때만 `context.colors.neutralOutline` 기반의 낮은 대비 테두리를 쓴다.
- 그림자는 쓰지 않는다.

금지:

- 독립적인 L1 카드처럼 보이는 경우가 아니라면 `VisualSpec.surface.radiusCard`를 쓰지 않는다.
- 기본값으로 `context.cardPadding()`을 쓰지 않는다. 내부 패널이 큰 카드처럼 보이게 된다.

### L3 지표 타일

L3는 숫자, 지표, 상태 요약용 반복 타일이다.

규칙:

- 배경은 중립 표면만 쓴다.
- 반경은 `context.radius.rMd`를 쓴다.
- 여백은 조밀한 기준으로 잡는다.
- 인접 타일을 구분해야 할 때만 낮은 대비의 중립 테두리를 쓴다.
- 수익/손실/경고 같은 의미 색상은 텍스트, 아이콘, 작은 강조선에 우선 적용한다.
- 숫자 글자는 `context.typography.cardTitle`, `heroNumber` 또는 숫자 안정성이 있는 토큰 역할을 쓴다.

금지:

- 모든 타일 안에 독립 섹션 헤더처럼 보이는 제목 구조를 넣지 않는다.
- 큰 카드 여백을 쓰지 않는다.
- 수익/손실 타일 전체를 강한 semantic 배경으로 채우지 않는다.

### L4 임시 부유 표면

L4는 화면 위에 임시로 떠 있는 UI다.

규칙:

- 전체 바텀시트는 `VisualSpec.surface.radiusSheet`를 우선 고려한다.
- 앱의 조밀한 시트는 문서화된 경우 `context.radius.rLg` 상단 반경을 허용한다.
- 팝오버 메뉴는 `radiusCard`, 낮은 대비 테두리, 필요 시 `context.shadows.level1`을 쓴다.
- 다이얼로그는 테마 shape를 따른다.
- 핸들은 `context.radius.rPill`과 중립 outline/surface를 쓴다.

금지:

- 밀도 확인 없이 L1 섹션 카드를 팝오버 메뉴로 재사용하지 않는다.
- 일반 인페이지 카드에 부유 표면용 그림자를 쓰지 않는다.

## 추가할 공용 보조 컴포넌트

각 페이지가 `Container + BoxDecoration`을 반복해서 직접 만들지 않도록 작은 보조 컴포넌트를 추가한다.

| 컴포넌트 | 목적 | 위치 후보 |
| --- | --- | --- |
| `AppInnerPanel` | L2 내부 묶음 표면 | `lib/components/panels/app_inner_panel.dart` |
| `AppMetricTile` | L3 라벨/값 타일 | `lib/components/metrics/app_metric_tile.dart` 또는 기존 지표 컴포넌트 확장 |
| `AppFloatingMenuSurface` | 정렬/필터 팝오버 껍데기 | `lib/components/panels/app_floating_menu_surface.dart` |
| `AppSheetSurface` | 조밀한 바텀시트 껍데기와 핸들 | `lib/components/panels/app_sheet_surface.dart` |

API는 작게 유지한다.

- `child`
- 선택적 `padding`
- 선택적 `dense`
- 필요한 경우에만 선택 상태 인자
- 도메인 전용 속성은 넣지 않는다.

## 감사 분류 기준

입력 자료:

- `panel_card_token_audit_20260530.md`

직접 만든 카드성 `BoxDecoration`은 아래 기준으로 분류한다.

| 분류 | 조치 |
| --- | --- |
| L1 껍데기 | `SectionCard`/`MoneyfySurfaceCard`로 교체하거나, custom 유지 사유를 문서화 |
| L2 내부 패널 | `AppInnerPanel`로 교체하거나 L2 문법에 맞춤 |
| L3 지표 타일 | 중복이 있으면 `AppMetricTile`로 교체 |
| L4 부유 표면 | `AppFloatingMenuSurface`/`AppSheetSurface`로 교체하거나 부유 표면 문법에 맞춤 |
| 카드가 아닌 원자 요소 | 직접 토큰 기반 `Container` 유지 |

## 작업 흐름

### 08A 공용 표면 컴포넌트

대상 파일:

- `lib/components/section_card.dart`
- `lib/widgets/moneyfy_ui.dart`
- 신규 `lib/components/panels/**`
- 필요한 경우 일부 지표 컴포넌트 파일

작업:

1. `SectionCard` 변형이 L1에만 쓰이는지 기준을 확정한다.
2. `AppInnerPanel`을 추가한다.
3. `AppFloatingMenuSurface`를 추가한다.
4. 두 개 이상의 시트가 자연스럽게 공유할 수 있을 때만 `AppSheetSurface`를 추가한다.
5. 공용 컴포넌트 smoke test를 보강한다.

완료 기준:

- 새 보조 컴포넌트는 `context.colors`, `context.spacing`, `context.radius`, `VisualSpec.surface`만 사용한다.
- 보조 컴포넌트 API에 화면 전용 이름을 넣지 않는다.
- 기존 화면 밀도는 크게 바꾸지 않는다.

### 08B 영향 큰 페이지 카드

대상 파일:

- `lib/pages/portfolio_dashboard_page.dart`
- `lib/pages/statistics_page.dart`
- `lib/widgets/company_news_summary_card.dart`
- `lib/widgets/market_news_summary_card.dart`

작업:

1. L1처럼 동작하는 대시보드/통계 base plate를 공용 카드 문법으로 맞춘다.
2. 뉴스 외곽 카드 껍데기를 L1 문법으로 정규화한다.
3. 뉴스 항목 타일을 L2 문법으로 정규화한다.
4. 내부 항목이 외곽 카드와 같은 급으로 보이는 중첩 카드 효과를 줄인다.

완료 기준:

- 대시보드, 통계, 뉴스의 외곽 카드가 같은 계열로 보인다.
- 내부 뉴스 타일은 외곽 카드보다 한 단계 낮게 보인다.
- 긴 한국어 제목과 본문이 겹치거나 잘리지 않는다.

### 08C 상세 페이지 섹션

대상 파일:

- `lib/pages/asset_detail_page.dart`
- `lib/pages/holding_detail_page.dart`
- `lib/pages/cash_account_detail_page.dart`
- `lib/pages/snapshot_detail_page.dart`

작업:

1. `_CardSection`, `_CashCardSection` 등 유사한 상세 화면 껍데기를 공통 문법으로 맞춘다.
2. 상세 섹션 껍데기는 L1, 내부 body 묶음은 L2로 구분한다.
3. 행과 목록 밀도는 유지한다.
4. 내부 패널이 명확히 L2처럼 보이지 않는 카드 안 카드 구조를 줄인다.

완료 기준:

- 상세 페이지들이 각자 다른 카드 껍데기를 만든 것처럼 보이지 않는다.
- 헤더, trailing divider, 내부 body 여백이 일관된다.

### 08D 분석 화면과 지표 타일

대상 파일:

- `lib/pages/investment_performance_page.dart`
- `lib/pages/portfolio_analysis_mvp_page.dart`
- `lib/pages/annual_asset_analysis_page.dart`
- `lib/pages/dividend_interest_analysis_page.dart`

작업:

1. 반복되는 지표 타일 구조를 찾는다.
2. L3 타일의 여백, 반경, 테두리, semantic 색상 사용을 맞춘다.
3. 차트와 캔버스 계산용 geometry는 건드리지 않고 컨테이너 표면만 정리한다.
4. 상태/진단 패널은 semantic 색상을 넓은 배경이 아니라 강조 요소로 쓰게 한다.

완료 기준:

- 분석 화면의 지표 타일들이 서로 같은 계열로 보인다.
- 진단/상태 카드는 의미를 유지하면서 화면을 과하게 지배하지 않는다.

### 08E 시트, 메뉴, 잔여 표면

대상 파일:

- `lib/pages/transactions_page.dart`
- `lib/pages/forms/form_design.dart`
- `lib/pages/target_allocation_sheet.dart`
- 상세/대시보드의 정렬 메뉴 위젯
- `lib/pages/sync_overlay.dart`

작업:

1. 바텀시트 껍데기 반경, 핸들, 여백을 맞춘다.
2. 팝오버 메뉴 껍데기의 테두리와 반경을 맞춘다.
3. L4가 인페이지 L1 카드와 다르게 보이도록 한다.
4. 플랫폼/테마 bridge 예외는 문서화한다.

완료 기준:

- 필터/생성 시트가 같은 형태로 보인다.
- 정렬 메뉴가 일반 인페이지 카드가 아니라 떠 있는 메뉴처럼 보인다.

## 권장 작업 순서

1. `lib/components/panels/**` 보조 컴포넌트 추가
2. `lib/widgets/company_news_summary_card.dart`
3. `lib/widgets/market_news_summary_card.dart`
4. `lib/pages/portfolio_dashboard_page.dart`
5. `lib/pages/statistics_page.dart`
6. `lib/pages/asset_detail_page.dart`
7. `lib/pages/holding_detail_page.dart`
8. `lib/pages/cash_account_detail_page.dart`
9. `lib/pages/snapshot_detail_page.dart`
10. 분석 화면 지표 타일
11. 시트/메뉴 잔여 정리

## 검증

정적 검사:

```bash
tools/check_design_token_guardrails.sh
flutter analyze lib/components lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart
```

배치별 검사:

```bash
flutter analyze <changed files>
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
```

시각 QA:

- 360dp, 390dp, 430dp 모바일 폭
- light/dark mode
- text scale 1.0과 1.3
- 대시보드, 통계, 회사 뉴스, 시장 뉴스, 자산 상세, 보유 종목 상세, 현금 계좌 상세, 스냅샷 상세

수동 점검:

- L1 카드 외곽선이 페이지마다 일관적으로 보인다.
- L2 패널이 L1보다 한 단계 낮게 보인다.
- 지표 타일이 독립 섹션 카드처럼 보이지 않는다.
- 부유 메뉴/시트가 임시 표면으로 읽힌다.
- 의도하지 않은 카드 안 카드 구조가 없다.
- 긴 한국어 제목과 금액이 넘치지 않는다.
- 수익/손실 색상은 넓은 배경보다 텍스트/아이콘/작은 강조에 우선 적용된다.

## 가드레일 후속 작업

08단계 이후에는 페이지 단위 직접 `BoxDecoration` 중 아래 패턴을 포함하는 항목을 보고 전용으로 나열하는 가드레일을 추가한다.

- `VisualSpec.surface.radiusCard`
- `context.shadows`
- `context.cardPadding()`
- `context.surfaces.surfaceRaised`

초기에는 CI를 실패시키지 않는다. 새로 추가되는 L1처럼 보이는 custom 카드가 의도된 것인지 검토하기 위한 감사 목록으로만 사용한다.

## 되돌리기 기준

- 각 작업 흐름은 별도 commit 크기로 유지한다.
- 시각 회귀가 생기면 해당 작업 흐름만 되돌린다.
- 페이지 이동보다 공용 보조 컴포넌트를 먼저 추가해 부분 되돌리기가 쉽도록 한다.
- 모든 호출부가 안정되기 전에는 기존 wrapper를 삭제하지 않는다.
