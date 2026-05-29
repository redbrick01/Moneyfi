# Final Polish Pass QA (Prompt 5/5)

## 1) 정렬 규칙 (10)
1. 페이지 좌우 패딩은 `AppInsets.pagePadding`의 `contentHorizontalPadding(16/20)`만 사용.
2. 섹션 간 수직 간격은 `context.spacing.sectionGap(24)`로 통일.
3. 카드 내부 패딩은 `context.cardPadding()`(16) 또는 dense(12)만 사용.
4. `Asset/Rebalance/Transaction/Settings` Row의 leading 슬롯 폭은 `48` 기준으로 고정.
5. Row title/subtitle는 좌측 baseline을 유지하고 subtitle 간격은 `xs/2`만 사용.
6. Row trailing 컬럼은 최소 폭을 고정해 금액 오른쪽 정렬 라인을 맞춤.
7. 리스트 divider는 `AppDivider`로만 사용하고 카드 내부 inset(기본 16) 정렬.
8. SectionHeader 높이는 `48`로 통일.
9. IconButton은 테마에서 최소 터치 `48x48`, 아이콘 `24`로 통일.
10. selection 상태는 border/shadow 대신 surface 단계 + 애니메이션으로 표현.

## 2) 모션 토큰 및 적용
- `fast: 150ms`, `base(normal): 200ms`, `slow: 240ms` (`AppMotion` 확장)
- 적용 포인트:
  - `ExpandableTile` expand/collapse: `AnimatedSize(200ms, easeOut)`
  - 거래 폼 조건부 필드(환전/이체): `AnimatedSwitcher(150ms) + AnimatedSize(200ms)`
  - Home 편집모드 trailing 액션: `AnimatedOpacity(150ms)`
  - Portfolio 범례 선택: `AnimatedContainer(150ms)`
  - Stats 캘린더 날짜 선택: `AnimatedContainer(150ms)`

## 3) 제스처 충돌 점검
- Reorderable + Slidable: Home 자산 리스트에서 편집 모드 시 `Slidable` 비활성(기존 유지), drag handle만 사용.
- 차트 드래그/스크롤: 통계 차트는 가로 드래그만 선택 인식, 스크롤과 충돌 최소화(기존 구조 유지).
- ExpandableTile: 내부는 `Column` 기반으로 유지하여 nested scroll 충돌 없음.

## 4) 다크모드 역할 조정
- `DeltaChip`: 배경을 `surfaceContainerHigh/Highest`로 내려 과채도 감소.
- `InlineError`: `errorContainer` 대신 `surfaceBase + outlineVariant`로 대비 안정화.
- `Skeleton`: `surfaceContainerHigh ↔ surfaceContainerHighest` 펄스로 번쩍임 완화.
- `IconButton` overlay: `onSurface` 기반 알파 오버레이로 라이트/다크 공통 가시성 확보.

## 5) Tooltip/Semantics 적용 (대표 10)
1. Home 정렬 메뉴 (`tooltip: 정렬`)
2. Home 자산 추가 (`tooltip: 자산 추가`)
3. Home 분석 새로고침 (`tooltip: 새로고침`)
4. Home 자산 숨김 토글 (`tooltip: 숨김/숨김 해제`)
5. Analysis 시장 요약 새로고침 (`tooltip: 새로고침`)
6. Analysis 캘린더 이전 달 (`tooltip: 이전 달`)
7. Analysis 캘린더 다음 달 (`tooltip: 다음 달`)
8. Stats 캘린더 이전 달 (`tooltip: 이전 달`)
9. Stats 캘린더 다음 달 (`tooltip: 다음 달`)
10. ExpandableTile semantics 상태 (`value: 확장됨/축소됨`)

## 6) SafeArea/Inset/키보드 코드 점검 위치
- `lib/ui_scaffold/app_insets.dart`
  - `bottomContentInset`: floating nav + safe area + gap 단일 계산
  - `pagePadding`: 탭 페이지에서 중복 inset 방지
- `lib/ui_scaffold/app_page_scaffold.dart`
  - 일반 페이지: `SafeArea + AppInsets.pagePadding` 1회 적용
  - 폼 페이지: `viewInsets` 반영 + 하단 CTA 접근성 유지
- `lib/pages/forms/cash_transaction_form_page.dart`
  - 이체 계좌 시트: `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)`

## 7) 기준 스냅샷 목록 (회귀 방지)
1. Home - 데이터 있음
2. Home - 자산 0 empty
3. Portfolio - 기본
4. Portfolio - 목표비중 시트 오픈
5. Analysis - 기본
6. Analysis - 타일 1개 확장
7. Stats - 월 선택 스트립 + 차트 선택 상태
8. Stats - 캘린더 선택 상태
9. My - 비로그인 / 로그인
10. My - 동기화 오버레이(성공/부분실패)
11. Detail - 종목 상세 + 거래 리스트
12. Form - 현금 거래 폼(환전/이체 조건부 필드)

## 8) 스냅샷 재현 방법
- 라이트/다크 각각 실행 후 동일 상태에서 캡처.
- 텍스트 스케일 `1.0`과 `1.3` 두 번 확인.
- 체크 포인트:
  - 카드/행 좌우 정렬선 일치
  - trailing 금액 오른쪽 정렬선 일치
  - 칩 높이/패딩 일관성
  - 상태 UI(loading/empty/error/success) 표현 일관성
  - 하단 네비/키보드와 CTA 겹침 없음
