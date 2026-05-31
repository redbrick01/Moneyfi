# 06. Responsive, Empty States, And QA

상태: 완료

## Role

v2 리디자인이 실제 화면에서 깨지지 않고, 데이터 부족 상태에서도 의미를 잃지 않도록 검증한다.

이 단계는 새 기능을 추가하는 단계가 아니라 품질 고정 단계다.

## Depends On

- [03_judgment_header.md](03_judgment_header.md)
- [04_attribution_and_reconciliation.md](04_attribution_and_reconciliation.md)
- [05_detail_sections_and_risk.md](05_detail_sections_and_risk.md)

## Scope

1. 360/390/430dp 모바일 viewport를 확인한다.
2. text scale 1.0/1.3을 확인한다.
3. 거래 없음, 일부 데이터 있음, 환율 없음, 벤치마크 없음, 스냅샷 없음 상태를 확인한다.
4. 기존 계산 회귀 테스트를 실행한다.
5. widget/page walkthrough 테스트를 보강한다.
6. visual QA 결과와 남은 리스크를 문서화한다.

## Out Of Scope

- 새 UI 섹션 추가
- 새 계산식 추가
- 디자인 컨셉 변경
- phase 0-5에서 완료된 구조 재논의
- 임의 follow-up 구현

## QA Boundary

이 phase는 구현물을 통과/보류로 판정하는 검증 단계다.

| 영역 | 이 phase에서 하는 일 | 이 phase에서 하지 않는 일 |
| --- | --- | --- |
| Responsive | viewport별 깨짐 확인, overflow 수정 | IA 순서 재구성 |
| Empty state | state별 copy/section 유지 확인 | 새 데이터 모델 추가 |
| Calculation regression | 기존 계산 결과 보존 확인 | 수익률 정의 변경 |
| Visual QA | 토큰/컴포넌트 준수 확인 | 새 디자인 문법 도입 |
| Test report | 실행 결과와 미해결 리스크 기록 | 임의 다음 phase 생성 |

QA 중 발견된 문제는 아래 기준으로만 처리한다.

| 발견 유형 | 처리 |
| --- | --- |
| 화면이 깨지는 결함 | 이 phase에서 수정 |
| copy가 01 계약과 다름 | 이 phase에서 수정 |
| view model state가 02 계약과 다름 | 이 phase에서 수정 |
| 계산 결과가 기존과 다름 | 원인 확인 후 회귀면 수정 |
| 더 좋아 보이는 새 시각화 아이디어 | follow-up으로 기록 |

## Required Input

검증 대상은 phase 03-05 구현이 완료된 `lib/pages/investment_performance_page.dart`다.

검증은 아래 문서를 기준으로 한다.

| Source | Purpose |
| --- | --- |
| [01_ia_and_copy_contract.md](01_ia_and_copy_contract.md) | 섹션 순서, copy, 데이터 부족 문구 |
| [02_report_view_model_contract.md](02_report_view_model_contract.md) | view model state와 unavailable reason |
| [03_judgment_header.md](03_judgment_header.md) | 첫 화면 판단 영역 |
| [04_attribution_and_reconciliation.md](04_attribution_and_reconciliation.md) | 성과 원인, 현금흐름/검산 |
| [05_detail_sections_and_risk.md](05_detail_sections_and_risk.md) | 월별, 종목별, 위험 해석 |
| `docs/design_system.md` | 디자인 시스템 기준 |
| `docs/features/simple_patches/design_md_full_compliance/component_contract.md` | 컴포넌트 사용 계약 |
| `lib/design_system/tokens.dart` | spacing/radius/color/typography token |
| `lib/widgets/moneyfy_ui.dart` | 기존 MONEYFY UI component |

## Responsive Verification Matrix

모바일 우선으로 아래 조합을 확인한다.

| Viewport | Text scale | Required checks |
| --- | --- | --- |
| 360dp | 1.0 | 첫 화면 header, period selector, benchmark strip, 주요 metric pair |
| 360dp | 1.3 | 긴 한글 문구, 기간 chip, holding row, risk tile overflow |
| 390dp | 1.0 | 기준 viewport 전체 flow, section spacing, mini chart |
| 390dp | 1.3 | header/action density, monthly row, reconciliation row |
| 430dp | 1.0 | 넓은 모바일에서 불필요한 여백/카드 느낌 과다 여부 |
| 430dp | 1.3 | table-like row의 wrap, metric label/value 충돌 여부 |

통과 기준:

- 가로 스크롤이 생기지 않는다.
- `RenderFlex overflow`가 발생하지 않는다.
- 긴 종목명, 긴 자산명, 긴 unavailable reason이 부모 영역을 밀어내지 않는다.
- period selector는 360dp에서도 탭 가능한 크기와 줄바꿈 규칙을 유지한다.
- first viewport에서 judgment header와 benchmark strip의 핵심 판단 정보가 보인다.
- 하단 부록성 `데이터 기준/제외 항목`은 첫 화면을 밀어내지 않는다.

## Empty And Partial State Matrix

각 상태는 section 자체를 숨기기보다, 가능한 경우 title과 이유를 유지한다.

| State | Expected UI | Must not happen |
| --- | --- | --- |
| 거래 없음 | 첫 화면에 분석 불가 이유, 하단 section별 empty copy | 빈 화면, exception, 0%를 정상 수익률처럼 표시 |
| 일부 거래만 있음 | 가능한 metric은 표시, 부족한 metric은 reason 표시 | 전체 report를 실패 처리 |
| 환율 없음 | 환산 필요한 값은 unavailable 또는 fallback reason 표시 | 임의 환율 적용 |
| benchmark 없음 | benchmark strip에 unavailable reason 표시 | S&P 500 대비 문구를 숨은 기본값으로 표시 |
| daily return 없음 | 위험 지표 tile에 데이터 부족 표시 | volatility/Sharpe를 0으로 표시 |
| snapshot 없음 | reconciliation은 fallback cash flow 연결로 표시 | 총자산 검산 성공처럼 표시 |
| 종목별 데이터 없음 | 종목별 기여도 empty copy 표시 | filter chip만 남은 빈 section |
| 월별 데이터 없음 | 월별 확정 성과 empty copy 표시 | mini chart 축만 표시 |

공통 copy 기준:

- 데이터 부족은 `없음`, `실패`, `0`을 섞어 쓰지 않는다.
- 사용자가 행동할 수 없는 상태에서는 과도한 지시형 문구를 쓰지 않는다.
- unavailable reason은 02 계약의 `MetricUnavailableReason`에서 온다.

## Design Compliance Check

모든 시각 요소는 기존 MONEYFY 디자인 시스템을 따른다.

| Check | Rule |
| --- | --- |
| Color | raw hex 금지, semantic positive/negative/neutral token 사용 |
| Spacing | 임의 `EdgeInsets` 값 추가 금지, 기존 spacing token/context 사용 |
| Radius | 자체 radius 값 추가 금지, token 또는 기존 component radius 사용 |
| Typography | 임의 font size/weight/letter spacing 추가 금지 |
| Component | 기존 `MoneyfyCard`, button/chip/selector 계열 우선 사용 |
| Card nesting | 카드 안 카드 금지 |
| Marketing hero | 대형 hero, 홍보형 composition 금지 |
| Chart | 판단 보조 수준의 compact chart만 허용 |
| Copy fit | 긴 한글 문구 overflow 금지 |

예외가 필요한 경우:

1. 예외 사유를 implementation report에 기록한다.
2. 임시값은 최소 범위로 제한한다.
3. 추후 token화 후보를 follow-up으로 남긴다.

## Test Plan

### Static Analysis

```sh
flutter analyze lib/pages/investment_performance_page.dart
```

통과 기준:

- analyzer error가 없다.
- 새 warning이 생기지 않는다.
- unused widget/helper가 남지 않는다.

### Unit Tests

대상:

- 기존 투자 성과 계산 test
- `_InvestmentPerformanceViewModel` mapping test
- `MetricValue` available/unavailable mapping test
- benchmark unavailable state test
- reconciliation available/fallback/unavailable state test
- risk unavailable reason mapping test

통과 기준:

- 기존 계산 결과가 변경되지 않는다.
- rate/amount 정의가 02 계약과 일치한다.
- null 또는 데이터 부족이 0으로 변환되지 않는다.

### Widget Tests

필수 scenario:

| Scenario | Required assertion |
| --- | --- |
| 정상 데이터 | judgment header, benchmark strip, attribution, reconciliation, monthly, holding, risk title 노출 |
| 거래 없음 | empty reason copy 노출, exception 없음 |
| benchmark 없음 | benchmark unavailable copy 노출 |
| 환율 없음 | 환산값 unavailable/fallback copy 노출 |
| snapshot 없음 | fallback reconciliation copy 노출 |
| text scale 1.3 | 주요 section pump 성공, overflow 로그 없음 |

### Page Walkthrough

가능하면 실제 page 수준 test를 추가한다.

확인 순서:

1. page 진입
2. 기간 selector 변경
3. benchmark strip 확인
4. 성과 원인 section 확인
5. 월별 section까지 scroll
6. 종목 filter/sort 변경
7. 위험 해석 section 확인
8. 데이터 기준 section 확인

통과 기준:

- selector 변경 후 report가 정상 갱신된다.
- filter/sort interaction 후 row layout이 깨지지 않는다.
- scroll 중 sticky/floating UI가 content를 가리지 않는다.

## Visual QA Checklist

구현 완료 후 아래 항목을 기록한다.

| Area | Check |
| --- | --- |
| First viewport | 판단 header, 수익률/금액 pair, benchmark strip이 한 화면에서 의미 있게 보임 |
| Attribution | positive/negative/neutral 색상이 semantic하게 읽힘 |
| Reconciliation | 총자산 변화와 현금흐름 연결이 표처럼 스캔 가능함 |
| Monthly | mini bar가 숫자 판단을 보조하고 과하게 크지 않음 |
| Holding | 긴 종목명과 통화 정보가 줄바꿈되어도 row가 안정적임 |
| Risk | 숫자와 해석 문장이 함께 보여 단순 숫자 나열처럼 보이지 않음 |
| Data basis | caveat가 하단 부록처럼 보이고 주요 판단을 방해하지 않음 |

## QA Report Format

QA 결과는 구현 report 또는 test report에 아래 형식으로 남긴다.

```md
## Investment Performance v2 QA

### Commands

- `flutter analyze lib/pages/investment_performance_page.dart`: pass/fail
- `{unit/widget test command}`: pass/fail

### Viewports

| Viewport | Text scale | Result | Note |
| --- | --- | --- | --- |
| 360dp | 1.0 | pass/fail | |
| 360dp | 1.3 | pass/fail | |
| 390dp | 1.0 | pass/fail | |
| 390dp | 1.3 | pass/fail | |
| 430dp | 1.0 | pass/fail | |
| 430dp | 1.3 | pass/fail | |

### Data States

| State | Result | Note |
| --- | --- | --- |
| 거래 없음 | pass/fail | |
| 일부 데이터 있음 | pass/fail | |
| 환율 없음 | pass/fail | |
| benchmark 없음 | pass/fail | |
| snapshot 없음 | pass/fail | |

### Remaining Risks

- 없음 또는 follow-up 항목
```

## Implementation Steps

1. 03-05 구현 결과가 문서 계약과 일치하는지 code review한다.
2. analyzer를 실행하고 오류를 수정한다.
3. unit test로 계산/view model mapping 회귀를 확인한다.
4. widget/page test로 주요 state와 interaction을 확인한다.
5. 360/390/430dp와 text scale 1.3에서 visual QA를 수행한다.
6. design md/token 위반 여부를 확인한다.
7. QA report를 남긴다.

## Completion Gate

- [x] `flutter analyze lib/pages/investment_performance_page.dart`를 필수 검증 command로 고정했다.
- [x] 관련 unit/widget/page walkthrough 테스트 범위를 정의했다.
- [x] 360/390/430dp viewport 검증 기준을 정의했다.
- [x] text scale 1.3에서 확인할 위험 영역을 정의했다.
- [x] 데이터 없음/일부 없음/벤치마크 없음/환율 없음/snapshot 없음 상태의 기대 UI를 정의했다.
- [x] design md/token 하드코딩 금지 기준을 QA 항목으로 고정했다.
- [x] QA 결과와 남은 리스크를 기록할 report format을 정의했다.

## Stop Rule

QA 중 발견된 새 아이디어를 바로 구현하지 않는다. completion gate를 막는 결함만 수정하고, 개선 아이디어는 follow-up으로 기록한다.

이 phase 완료 후에도 새 phase를 임의로 만들지 않는다. 구현 착수 여부는 별도 사용자 지시가 있을 때만 결정한다.
