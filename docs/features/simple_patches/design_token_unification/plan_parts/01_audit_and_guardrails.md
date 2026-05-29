# 01 Audit And Guardrails

## Goal

남은 개별 디자인 수치 사용을 수치화하고, 기계적으로 바꿀 대상과 예외로 남길 대상을 구분합니다. 이 stage는 구현보다 추적성 확보가 목적입니다.

## Inputs

- `docs/design_system.md`
- `lib/design_system/`
- `lib/components/`
- `docs/features/simple_patches/design_token_unification/plan_parts/00_coverage_matrix.md`
- current grep output from `lib/**/*.dart`

## Audit Commands

Legacy pattern scan:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib --glob "*.dart"
```

Token usage scan:

```bash
rg -n "context\\.spacing|context\\.radius|context\\.typography|context\\.colors|VisualSpec|colorScheme" lib --glob "*.dart"
```

Optional count summary:

```bash
rg -o "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib --glob "*.dart" | sort | uniq -c
```

## Output

Create an audit snapshot:

```text
docs/features/simple_patches/design_token_unification/audit_YYYYMMDD.md
```

Required sections:

- total counts by pattern
- top files by legacy usage
- files excluded as chart/canvas-heavy
- first implementation batch proposal
- risks and manual QA targets

## Classification

| Bucket | Criteria | Action |
| --- | --- | --- |
| component | reusable UI in `lib/components/` | early tokenization |
| compatibility | `lib/widgets/moneyfy_ui.dart`, legacy helpers | defer to dedicated batch |
| news cards | company/market news summary cards | stage 03 |
| analysis pages | analysis family pages and charts | stage 04 |
| detail/forms | detail pages, form pages, sheets | stage 05 |
| remaining app surfaces | shell, auth, portfolio, transaction, statistics, account, overlay | stage 06 |
| brand/native assets | app icons, launch screen, web icons, native visual shells | stage 06 audit-only |
| chart/canvas exception | painter geometry, chart axis math, fixed graph dimensions | document exception |

## Allowed Direct Values

Allowed without replacement:

- `0`, `1`, `2` for border width, divider thickness, opacity math, index/loop logic
- chart/canvas geometry where the value is part of drawing math
- fixed domain row heights already documented in `docs/design_system.md`
- intrinsic asset/icon sizes
- values derived from tokens, such as `context.spacing.xs / 2`
- `EdgeInsets.zero`, `SizedBox.shrink()`

Needs review:

- `SizedBox(height: 4)`, `SizedBox(width: 10)`, `EdgeInsets.all(14)`
- `fontSize:` in UI widgets
- `Color(0x...)` outside design system/spec/theme files
- `BorderRadius.circular(16)` in page UI

## Guardrail Strategy

### Soft Guardrail

Early batches only record grep deltas in test reports.

Rules:

- no new arbitrary color/font/spacing in touched files
- audit count should trend down per batch
- intentional exceptions must be listed in test report

### Hard Guardrail

After legacy usage is reduced and stable, consider CI enforcement.

Candidates:

- grep check for new `Color(0x...)` outside design system/theme files
- grep check for new `fontSize:` outside typography/theme/chart exceptions
- grep check for new `MoneyfyPalette` in files touched after the cutoff date

## Acceptance Criteria

- audit snapshot exists
- first batch files are chosen
- allowed direct value policy is documented
- soft guardrail is ready for test reports
