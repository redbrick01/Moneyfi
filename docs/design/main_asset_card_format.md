# Main Asset Card Format (SSOT)

이 문서는 홈 페이지 자산 카드의 **단일 포맷 기준(SSOT)** 입니다.  
구현 기준 파일: `lib/pages/portfolio_dashboard_page.dart`

## 1) 구성 레이어
- 바닥 카드(Base Plate)
  - 배경: `context.surfaces.surfaceRaised`
  - 라운드: `VisualSpec.surface.radiusCard`
  - 그림자: `context.shadows.level3`
  - 내부 패딩: `context.cardPadding()`
- 헤더
  - 좌측: `자산`
  - 우측: 정렬 버튼, 구분선, 자산 추가 버튼
- 본문 카드(내부 카드)
  - `MoneyfySurfaceCard(variant: base, padding: EdgeInsets.zero)`

## 2) 정렬 옵션
- `custom` (기본순)
- `profitRateDesc` (수익률 높은순)
- `profitRateAsc` (수익률 낮은순)
- `profitDesc` (수익 높은순)
- `profitAsc` (수익 낮은순)

## 3) 자산 표시 규칙
- 표시 자산: `isHidden == false`
- 숨김 자산: `isHidden == true`
- 숨김/표시가 모두 존재하면 2중 카드 스택으로 렌더링
  - 앞 카드: 표시 자산 목록
  - 뒤 카드: 숨김 자산 목록
  - 숨김 카드 첫 행: 항상 빈 슬롯(`_HiddenAssetEmptySlot`)
  - 겹침 오프셋: `rowHeight(72)` 기준

## 4) 카드 행(Row) 포맷
- 공통 행 컴포넌트: `AssetRow`
- 행 높이: `72`
- 아이콘 슬롯: `46`
- 아이콘 박스: `34 x 34`
- 아이콘 크기: `20`
- 우측 값
  - 금액 텍스트
  - (현금 제외) 손익 금액 + `DeltaChip(%)`
  - 손익 금액 텍스트: `typography.caption`
  - 수익률 칩: `DeltaChip(compact: true)` (`minHeight=20`, `horizontal=6`, `vertical=2`, `typography.caption`)
- 숨김 행 표현
  - opacity: `0.6`
  - blur: `ImageFilter.blur(sigmaX: 3.6, sigmaY: 3.6)`

## 5) 인터랙션
- 길게 눌러 드래그 재정렬
  - `ReorderableDelayedDragStartListener`
  - 순서 저장: `AppDatabase.reorderAssets(assetIds)`
- 스와이프 액션(행)
  - `Slidable` + `moneyfySingleSlideActionPane`
  - 액션: 숨김 / 숨김 해제
- 숨김 토글
  - `AppDatabase.updateAssetHidden(id, !isHidden)`

## 6) empty / loading / error 상태
- Loading: `SkeletonList(rows: 4, rowHeight: 72, hasLeading: true, trailingLines: 2)`
- Error: `InlineError + RetryRow`
- Empty(로그인 후 기본): `EmptyStateCard('자산이 아직 없어요')`
- Empty(로그아웃 전용): 레벨1 폭 + 중앙 정렬 + CTA 버튼

## 7) 데이터 저장/동기화
- 정렬/숨김 변경 후
  - 로컬 DB 반영
  - `SyncService.syncNow(...)` 호출 (가능 시)

## 8) 재사용 시 필수 유지 사항
- 숨김 카드 빈 슬롯 + 오버랩 계산
- 슬라이드 액션 + 외부 탭 시 닫힘 동작
- 드래그 재정렬 낙관적 업데이트 + 실패 롤백
- 표시/숨김 분리 렌더링 규칙
