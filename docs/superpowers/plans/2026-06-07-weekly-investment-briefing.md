# Weekly Investment Briefing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a MONEYFY weekly investment briefing feature that combines the user's portfolio, cached MONEYFY news/Reddit/research data, fresh web-search market context, and an OpenAI model into a saved scenario-based report.

**Architecture:** Add a Supabase-backed report table and a `generate-weekly-investment-briefing` Edge Function that authenticates the user, loads portfolio/news/research context, calls OpenAI Responses API with `web_search`, validates structured JSON, stores the result, and returns it. Add a Flutter service and page under Analysis so the user can generate, refresh, and read the report without pasting JSON manually.

**Tech Stack:** Flutter/Dart, Supabase Flutter SDK, Supabase Edge Functions on Deno, Postgres migrations/RLS/RPC, OpenAI Responses API with structured output and web search, existing MONEYFY design components.

---

## MVP Scope

Build the first version as a manual "Generate weekly briefing" feature.

Included:
- One report per user per report week.
- Manual force refresh from the app.
- Supabase Edge Function calls OpenAI with web search.
- Server-side portfolio metric calculation.
- Stored JSON report plus metadata and token usage.
- App page renders the major sections from the generated JSON.
- Graceful fallback to latest cached report if generation fails.

Excluded from MVP:
- Scheduled automatic weekly generation.
- Push notifications.
- PDF export.
- Paid tier limits.
- Advanced charting.
- Intraday live market data.

## Existing Code To Reuse

- `supabase/functions/get-portfolio-diagnosis/index.ts`: auth verification, OpenAI Responses API usage, response validation, usage tracking, history cache pattern.
- `supabase/functions/get-market-news-summary/index.ts`: latest market summary lookup pattern.
- `supabase/functions/get-user-company-news-summaries/index.ts`: user holdings to company summary lookup pattern.
- `lib/services/market_news_summary_service.dart`: Flutter Edge Function service pattern and local cache fallback style.
- `lib/services/portfolio_diagnosis_service.dart`: remote invocation and model parsing style.
- `lib/pages/analysis_page.dart`: add the new entry card.
- `lib/navigation/moneyfy_routes.dart`, `lib/navigation/moneyfy_router.dart`, `lib/navigation/moneyfy_navigation.dart`: add route and navigation helper.
- `lib/components/*`, `lib/widgets/moneyfy_ui.dart`: existing cards, chips, section styling.

## File Structure

Create:
- `supabase/migrations/20260607120000_create_weekly_investment_briefings.sql`
  - Table, indexes, RLS, authenticated read policy, service-role write posture.
- `supabase/functions/generate-weekly-investment-briefing/index.ts`
  - Auth, data loading, metric calculation, OpenAI request, schema validation, persistence.
- `lib/services/weekly_investment_briefing_service.dart`
  - Flutter model classes and function invocation.
- `lib/pages/weekly_investment_briefing_page.dart`
  - Page UI for loading/generating/rendering report sections.
- `test/weekly_investment_briefing_service_test.dart`
  - Parser and fallback tests.
- `test/weekly_investment_briefing_page_test.dart`
  - Rendering smoke tests.

Modify:
- `lib/navigation/moneyfy_routes.dart`
  - Add route name/path.
- `lib/navigation/moneyfy_router.dart`
  - Register page.
- `lib/navigation/moneyfy_navigation.dart`
  - Add `openWeeklyInvestmentBriefing`.
- `lib/pages/analysis_page.dart`
  - Add "주간 투자 브리핑" entry card.
- `supabase/README.md`
  - Document required Edge Function secrets.

## Report JSON Contract

The Edge Function must return and store this shape:

```json
{
  "schema_version": 1,
  "report_date": "2026-06-07",
  "report_week_start": "2026-06-08",
  "report_week_end": "2026-06-12",
  "market_review": {
    "headline": "string",
    "index_moves": [
      {"name": "S&P 500", "weekly_return_pct": 0.0, "why_it_mattered": "string"}
    ],
    "rates_fx_commodities": [
      {"name": "US 10Y", "change": "string", "impact": "string"}
    ],
    "key_events": [
      {
        "title": "string",
        "what_happened": "string",
        "why_market_reacted": "string",
        "forward_meaning": "string"
      }
    ]
  },
  "next_week_events": [
    {
      "date": "2026-06-10",
      "event_name": "US CPI",
      "importance": 5,
      "why_important": "string",
      "market_consensus": "string",
      "positive_result_impact": "string",
      "negative_result_impact": "string"
    }
  ],
  "consensus": [
    {
      "topic": "Fed policy",
      "current_expectation": "string",
      "opposite_scenario": "string",
      "shock_probability": "low"
    }
  ],
  "market_outlook": {
    "bull": {
      "probability_pct": 25,
      "conditions": ["string"],
      "expected_flow": "string",
      "beneficiaries": ["string"],
      "losers": ["string"]
    },
    "base": {
      "probability_pct": 50,
      "conditions": ["string"],
      "expected_flow": "string"
    },
    "bear": {
      "probability_pct": 25,
      "conditions": ["string"],
      "expected_flow": "string",
      "beneficiaries": ["string"],
      "losers": ["string"]
    }
  },
  "portfolio_analysis": {
    "total_asset_krw": 0,
    "asset_class_weights": [{"label": "주식", "weight_pct": 0.0}],
    "holding_weights": [{"symbol": "NVDA", "name": "NVIDIA", "weight_pct": 0.0}],
    "country_weights": [{"country": "US", "weight_pct": 0.0}],
    "ai_related_weight_pct": 0.0,
    "single_stock_weight_pct": 0.0,
    "etf_weight_pct": 0.0,
    "cash_weight_pct": 0.0,
    "strengths": ["string"],
    "risks": ["string"],
    "concentration_risks": ["string"],
    "overweight_positions": ["string"],
    "missing_asset_classes": ["string"],
    "drawdown_weakness": "string",
    "rally_benefit": "string"
  },
  "portfolio_market_integration": [
    {
      "event": "CPI shock",
      "portfolio_sensitivity": "high",
      "expected_impact": "string",
      "reason": "string"
    }
  ],
  "action_scenarios": [
    {
      "scenario": "예상보다 좋은 CPI",
      "action": "buy",
      "orders": [{"symbol": "VOO", "amount_krw": 300000, "rationale": "string"}],
      "do_not_do": ["string"]
    }
  ],
  "daily_plan": [
    {
      "date_label": "수요일(CPI)",
      "watch": ["string"],
      "avoid": ["string"],
      "possible_buys": [{"symbol": "QQQ", "condition": "string", "amount_krw": 200000}]
    }
  ],
  "final_conclusion": {
    "market_state": "string",
    "portfolio_state": "string",
    "most_likely_scenario": "string",
    "most_dangerous_scenario": "string",
    "recommended_action": "string"
  },
  "if_i_were_doing_it": {
    "summary": "string",
    "actions": ["string"]
  },
  "disclaimer": "투자 조언이 아닌 시나리오 분석입니다."
}
```

Validation rules:
- Scenario probabilities must sum to 100.
- Importance must be 1 through 5.
- Amounts must be non-negative integers.
- The model may only recommend symbols present in current holdings, broad ETFs already present in research/news context, or cash/hold.
- If a required market item cannot be verified, the item value must be `"데이터 없음"` and the reason must be included.

---

### Task 1: Database Schema

**Files:**
- Create: `supabase/migrations/20260607120000_create_weekly_investment_briefings.sql`

- [ ] **Step 1: Write migration**

Create:

```sql
create table if not exists public.weekly_investment_briefings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  report_date date not null,
  week_start date not null,
  week_end date not null,
  model text not null default '',
  status text not null default 'completed'
    check (status in ('completed', 'failed')),
  report_json jsonb not null,
  source_snapshot jsonb not null default '{}'::jsonb,
  error_message text,
  input_tokens integer,
  output_tokens integer,
  total_tokens integer,
  reasoning_tokens integer,
  cached_input_tokens integer,
  usage_json jsonb,
  openai_request_id text,
  openai_response_id text,
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, week_start)
);

create index if not exists idx_weekly_investment_briefings_user_generated
on public.weekly_investment_briefings (user_id, generated_at desc);

create index if not exists idx_weekly_investment_briefings_user_week
on public.weekly_investment_briefings (user_id, week_start desc);

alter table public.weekly_investment_briefings enable row level security;

revoke all on public.weekly_investment_briefings from anon, authenticated;
grant select on public.weekly_investment_briefings to authenticated;

drop policy if exists "Users can read own weekly investment briefings"
on public.weekly_investment_briefings;

create policy "Users can read own weekly investment briefings"
on public.weekly_investment_briefings
for select
to authenticated
using ((select auth.uid()) = user_id);
```

- [ ] **Step 2: Verify migration syntax locally**

Run:

```bash
supabase db reset --local
```

Expected: database resets and migration applies without SQL errors. If local Supabase is unavailable, run the project migration validation command already used for this repo and record the failure reason in the task notes.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260607120000_create_weekly_investment_briefings.sql
git commit -m "feat: add weekly briefing storage"
```

### Task 2: Edge Function Data Loading And Portfolio Metrics

**Files:**
- Create: `supabase/functions/generate-weekly-investment-briefing/index.ts`

- [ ] **Step 1: Add function skeleton**

Implement these responsibilities in `index.ts`:
- Parse bearer token.
- Verify authenticated user with `supabase.auth.getUser(token)`.
- Create anon client for auth and service-role client for internal reads/writes.
- Parse request body:

```ts
type RequestBody = {
  force_refresh?: boolean;
  report_date?: string;
};
```

- Compute KST report date and next Monday-Friday week range.
- Return JSON errors with stable codes:

```json
{"ok": false, "error": "unauthorized"}
```

- [ ] **Step 2: Load source data**

Add functions:
- `loadPortfolio(adminClient, userId)`
  - Read `public.assets`, `public.holdings`, `public.cash_accounts` where `user_id = userId` and `deleted_at is null`.
- `loadLatestMarketSummary(adminClient)`
  - Read latest `public.market_news_summaries`.
- `loadLatestCompanySummaries(adminClient, symbols)`
  - Read latest `public.company_news_summaries` for current holding symbols.
- `loadLatestRedditReport(adminClient)`
  - Read latest `public.reddit_daily_report`.
- `loadLatestRedditPostSummaries(adminClient)`
  - Read top 10 latest valuable rows from `public.reddit_post_summaries`.
- `loadLatestResearchReports(adminClient, symbols)`
  - Read `equity_research.research_reports` joined to `equity_research.companies`.

- [ ] **Step 3: Calculate deterministic metrics**

Add a pure `buildPortfolioMetrics()` function that returns:

```ts
type PortfolioMetrics = {
  total_asset_krw: number;
  asset_class_weights: Array<{ label: string; weight_pct: number }>;
  holding_weights: Array<{ symbol: string; name: string; weight_pct: number }>;
  country_weights: Array<{ country: string; weight_pct: number }>;
  ai_related_weight_pct: number;
  single_stock_weight_pct: number;
  etf_weight_pct: number;
  cash_weight_pct: number;
  available_cash_krw: number;
};
```

Rules:
- Total asset is holdings market value plus cash balances converted to KRW using stored row values when available.
- ETF detection uses known ETF symbols and names containing `ETF`.
- AI-related detection uses symbols/tags from company summaries/research plus a conservative allowlist: `NVDA`, `MSFT`, `GOOGL`, `AVGO`, `AMD`, `TSM`, `PLTR`, `SMH`, `SOXX`, `QQQ`, `QTOP`, `QQQT`.
- Country detection uses `exchange_code`: Korean exchanges to `KR`, US exchanges and USD holdings to `US`, unknown to `기타`.

- [ ] **Step 4: Add function-level tests as pure helpers**

Because Supabase Edge Function tests are not currently established, keep calculations pure and export helper functions only behind a Deno test block if the repo has Deno test support. Otherwise, cover parsing in Flutter and verify the Edge Function via manual invocation in Task 8.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/generate-weekly-investment-briefing/index.ts
git commit -m "feat: load weekly briefing context"
```

### Task 3: OpenAI Web Search Generation And Persistence

**Files:**
- Modify: `supabase/functions/generate-weekly-investment-briefing/index.ts`
- Modify: `supabase/README.md`

- [ ] **Step 1: Add OpenAI configuration**

Use environment variables:

```ts
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const WEEKLY_BRIEFING_MODEL =
  Deno.env.get("WEEKLY_BRIEFING_MODEL") ?? "gpt-5.4-mini";
```

If `OPENAI_API_KEY` is missing, return the latest cached report if it exists; otherwise return HTTP 503 with:

```json
{"ok": false, "error": "openai_key_missing"}
```

- [ ] **Step 2: Build prompt**

The system prompt must instruct:
- Korean output.
- Scenario analysis, not investment advice.
- Use web search for latest market data and next-week events.
- Do not fabricate unavailable values.
- Use server-provided portfolio metrics as authoritative.
- Return only JSON matching the schema.

The user payload must include:
- `portfolio_metrics`
- `portfolio_holdings`
- `available_cash_krw`
- `market_news_summary`
- `company_news_summaries`
- `reddit_daily_report`
- `reddit_post_summaries`
- `equity_research_reports`
- `report_week`

- [ ] **Step 3: Call OpenAI Responses API**

Use:

```ts
const response = await fetch("https://api.openai.com/v1/responses", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${OPENAI_API_KEY}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: WEEKLY_BRIEFING_MODEL,
    input: [
      { role: "system", content: systemPrompt },
      { role: "user", content: JSON.stringify(userPayload) }
    ],
    tools: [{ type: "web_search" }],
    text: {
      format: {
        type: "json_schema",
        name: "weekly_investment_briefing",
        strict: true,
        schema: weeklyBriefingJsonSchema
      }
    }
  }),
});
```

- [ ] **Step 4: Validate generated JSON**

Add `validateBriefingShape(value)`:
- Ensures object.
- Ensures `schema_version === 1`.
- Ensures all major sections are present.
- Ensures probabilities sum to 100.
- Replaces invalid optional arrays with empty arrays.
- Throws for missing required final conclusion fields.

- [ ] **Step 5: Persist report**

Upsert into `public.weekly_investment_briefings` on `(user_id, week_start)`:
- `report_json`
- `source_snapshot`
- `model`
- OpenAI request/response IDs
- token usage fields
- `status = 'completed'`

On OpenAI failure:
- Insert or update a failed row with `status = 'failed'` and `error_message`.
- Return latest completed cached row if present.

- [ ] **Step 6: Document secrets**

Add to `supabase/README.md`:

```md
### Weekly investment briefing

Required Edge Function secrets:

- `OPENAI_API_KEY`
- `WEEKLY_BRIEFING_MODEL` optional, defaults to `gpt-5.4-mini`

The `generate-weekly-investment-briefing` function uses OpenAI Responses API with web search. It stores generated reports in `public.weekly_investment_briefings`.
```

- [ ] **Step 7: Commit**

```bash
git add supabase/functions/generate-weekly-investment-briefing/index.ts supabase/README.md
git commit -m "feat: generate weekly briefing with web search"
```

### Task 4: Flutter Service And Models

**Files:**
- Create: `lib/services/weekly_investment_briefing_service.dart`
- Create: `test/weekly_investment_briefing_service_test.dart`

- [ ] **Step 1: Write parser tests**

Add tests for:
- Parses full report.
- Defaults missing optional arrays to empty arrays.
- Rejects non-map response.
- Exposes generated metadata.

Use a sample map with:

```dart
const samplePayload = {
  'ok': true,
  'model': 'gpt-5.4-mini',
  'generated_at': '2026-06-07T12:00:00Z',
  'report': {
    'schema_version': 1,
    'report_date': '2026-06-07',
    'market_review': {'headline': '시장 요약', 'index_moves': [], 'rates_fx_commodities': [], 'key_events': []},
    'next_week_events': [],
    'consensus': [],
    'market_outlook': {
      'bull': {'probability_pct': 25, 'conditions': [], 'expected_flow': '', 'beneficiaries': [], 'losers': []},
      'base': {'probability_pct': 50, 'conditions': [], 'expected_flow': ''},
      'bear': {'probability_pct': 25, 'conditions': [], 'expected_flow': '', 'beneficiaries': [], 'losers': []}
    },
    'portfolio_analysis': {
      'total_asset_krw': 1000000,
      'asset_class_weights': [],
      'holding_weights': [],
      'country_weights': [],
      'ai_related_weight_pct': 0,
      'single_stock_weight_pct': 0,
      'etf_weight_pct': 0,
      'cash_weight_pct': 100,
      'strengths': [],
      'risks': [],
      'concentration_risks': [],
      'overweight_positions': [],
      'missing_asset_classes': [],
      'drawdown_weakness': '',
      'rally_benefit': ''
    },
    'portfolio_market_integration': [],
    'action_scenarios': [],
    'daily_plan': [],
    'final_conclusion': {
      'market_state': '중립',
      'portfolio_state': '현금 중심',
      'most_likely_scenario': '중립',
      'most_dangerous_scenario': 'CPI 쇼크',
      'recommended_action': '관망'
    },
    'if_i_were_doing_it': {'summary': '관망', 'actions': []},
    'disclaimer': '투자 조언이 아닌 시나리오 분석입니다.'
  }
};
```

- [ ] **Step 2: Implement service**

Create:
- `WeeklyInvestmentBriefingService`
- `WeeklyInvestmentBriefingResponse`
- `WeeklyInvestmentBriefingReport`
- nested value classes for sections used by UI.

Service method:

```dart
Future<WeeklyInvestmentBriefingResponse?> fetchBriefing({
  bool forceRefresh = false,
})
```

Invoke:

```dart
final response = await AuthService.client.functions.invoke(
  'generate-weekly-investment-briefing',
  body: <String, Object?>{'force_refresh': forceRefresh},
);
```

Return `null` if auth is not initialized, HTTP status is not 200, or payload shape is invalid.

- [ ] **Step 3: Run parser tests**

Run:

```bash
flutter test test/weekly_investment_briefing_service_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/services/weekly_investment_briefing_service.dart test/weekly_investment_briefing_service_test.dart
git commit -m "feat: add weekly briefing service"
```

### Task 5: Flutter Page UI

**Files:**
- Create: `lib/pages/weekly_investment_briefing_page.dart`
- Create: `test/weekly_investment_briefing_page_test.dart`

- [ ] **Step 1: Write page smoke test**

Test that a loaded report renders:
- final conclusion
- market headline
- portfolio total asset
- one action scenario

Use a test-only loader injected into `WeeklyInvestmentBriefingPage`.

- [ ] **Step 2: Implement page**

Page structure:
- `MoneyfyPage(title: '주간 투자 브리핑')`
- Top action row:
  - primary button `브리핑 생성`
  - secondary icon refresh button
- Metadata chip:
  - model
  - generated date
  - cached/live status if available
- Sections:
  - `이번 주 한 줄 결론`
  - `지난주 시장 정리`
  - `다음주 핵심 일정`
  - `시장 컨센서스`
  - `다음주 시나리오`
  - `내 포트폴리오 진단`
  - `시장 이벤트 민감도`
  - `CPI 시나리오별 대응`
  - `요일별 행동계획`
  - `내가 실제로 한다면`

UI rules:
- Use existing cards/components.
- Keep cards shallow; do not nest section cards inside cards.
- Use chips for importance and sensitivity.
- Amounts display with KRW formatting.
- Empty sections show compact `EmptyState`.

- [ ] **Step 3: Handle loading and errors**

States:
- Initial loading: skeleton card.
- No report: empty state with generate button.
- Generation in progress: disabled buttons and progress indicator.
- Failure: inline error plus latest cached report if returned by service.

- [ ] **Step 4: Run page tests**

Run:

```bash
flutter test test/weekly_investment_briefing_page_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/weekly_investment_briefing_page.dart test/weekly_investment_briefing_page_test.dart
git commit -m "feat: add weekly briefing page"
```

### Task 6: Navigation And Analysis Entry

**Files:**
- Modify: `lib/navigation/moneyfy_routes.dart`
- Modify: `lib/navigation/moneyfy_router.dart`
- Modify: `lib/navigation/moneyfy_navigation.dart`
- Modify: `lib/pages/analysis_page.dart`
- Modify: `test/router_smoke_test.dart`

- [ ] **Step 1: Add route constants**

In `MoneyfyRouteNames`:

```dart
static const weeklyInvestmentBriefing = 'weeklyInvestmentBriefing';
```

In `MoneyfyRoutePaths`:

```dart
static const weeklyInvestmentBriefing = '/analysis/weekly-briefing';
```

- [ ] **Step 2: Register route**

Import `weekly_investment_briefing_page.dart` in `moneyfy_router.dart` and add:

```dart
GoRoute(
  path: MoneyfyRoutePaths.weeklyInvestmentBriefing,
  name: MoneyfyRouteNames.weeklyInvestmentBriefing,
  builder: (context, state) => const WeeklyInvestmentBriefingPage(),
),
```

- [ ] **Step 3: Add navigation helper**

In `moneyfy_navigation.dart` add:

```dart
Future<void> openWeeklyInvestmentBriefing() {
  return push<void>(MoneyfyRoutePaths.weeklyInvestmentBriefing);
}
```

- [ ] **Step 4: Add analysis entry**

In `analysis_page.dart`, add the new card above `포트폴리오 진단`:

```dart
_AnalysisEntryCard(
  icon: Icons.event_note_rounded,
  title: '주간 투자 브리핑',
  subtitle: '시장 일정 · 포트폴리오 · CPI 시나리오',
  onTap: context.openWeeklyInvestmentBriefing,
),
```

- [ ] **Step 5: Extend router smoke test**

Add assertion that `MoneyfyRoutePaths.weeklyInvestmentBriefing` builds without throwing.

- [ ] **Step 6: Run navigation tests**

Run:

```bash
flutter test test/router_smoke_test.dart
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_router.dart lib/navigation/moneyfy_navigation.dart lib/pages/analysis_page.dart test/router_smoke_test.dart
git commit -m "feat: link weekly briefing from analysis"
```

### Task 7: Manual Edge Function Verification

**Files:**
- No source edits unless verification finds defects.

- [ ] **Step 1: Deploy or run function locally**

Preferred local command:

```bash
supabase functions serve generate-weekly-investment-briefing --env-file supabase/.env.local
```

Expected: function starts and logs no TypeScript syntax errors.

- [ ] **Step 2: Invoke with authenticated token**

Use the existing app session token or Supabase CLI local auth token. Request body:

```json
{"force_refresh": true}
```

Expected 200 response:

```json
{"ok": true, "report": {"schema_version": 1}}
```

- [ ] **Step 3: Verify persistence**

Run SQL:

```sql
select user_id, week_start, status, model, generated_at
from public.weekly_investment_briefings
order by generated_at desc
limit 5;
```

Expected: latest row has `status = 'completed'`.

- [ ] **Step 4: Verify RLS**

As authenticated user, select own rows succeeds. As anon, select returns no rows or permission error.

- [ ] **Step 5: Commit fixes only if needed**

```bash
git add supabase/functions/generate-weekly-investment-briefing/index.ts
git commit -m "fix: harden weekly briefing generation"
```

### Task 8: Full App Verification

**Files:**
- No source edits unless verification finds defects.

- [ ] **Step 1: Analyze touched Dart files**

Run:

```bash
flutter analyze lib/services/weekly_investment_briefing_service.dart lib/pages/weekly_investment_briefing_page.dart lib/pages/analysis_page.dart lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_router.dart lib/navigation/moneyfy_navigation.dart
```

Expected: no issues.

- [ ] **Step 2: Run focused tests**

Run:

```bash
flutter test test/weekly_investment_briefing_service_test.dart test/weekly_investment_briefing_page_test.dart test/router_smoke_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Run broader regression tests**

Run:

```bash
flutter test test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Manual UI pass**

Open app, go to:
- Analysis
- 주간 투자 브리핑
- Generate
- Refresh

Confirm:
- Buttons do not overflow on mobile width.
- Generated report sections are readable.
- Empty states are compact.
- Long Korean text wraps inside cards.
- The disclaimer is visible.

- [ ] **Step 5: Final commit**

```bash
git status --short
git add lib supabase test
git commit -m "feat: add AI weekly investment briefing"
```

## Cost And Model Defaults

MVP defaults:
- `WEEKLY_BRIEFING_MODEL = gpt-5.4-mini`
- Expected per generation: roughly `$0.20-$0.45` with 10-20 web searches and moderate output length.
- Use `force_refresh = false` by default so same-week generation returns cached report.
- Add a later quota table before making automatic daily generation.

## Rollout Notes

- Deploy migration first.
- Set Edge Function secrets before deployment:

```bash
supabase secrets set OPENAI_API_KEY=...
supabase secrets set WEEKLY_BRIEFING_MODEL=gpt-5.4-mini
```

- Deploy function:

```bash
supabase functions deploy generate-weekly-investment-briefing
```

- If generation fails in production, the app should still show the latest completed weekly report.

## Self-Review

Spec coverage:
- Latest market data: Task 3 web search.
- Portfolio metrics and weights: Task 2 deterministic metrics.
- Stored report: Task 1 and Task 3.
- App flow: Tasks 4-6.
- Verification: Tasks 7-8.

Residual risk:
- OpenAI web search availability and pricing may change; keep model and tool settings in environment variables.
- Market data from web search can be inconsistent across sources; the prompt requires verified values or `"데이터 없음"`.
- Edge Function Deno testing is not currently standardized in this repo; pure helper extraction should be added if this grows.

