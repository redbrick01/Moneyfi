# News Reports Schema Adaptation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update Moneyfy's news API/app contract to read the new Supabase `public.news_reports` table while keeping the current Flutter news cards and local cache format working.

**Architecture:** Keep the Flutter service and widget surface mostly unchanged. Move schema adaptation into the read Edge Functions: map `news_reports.group_key = 'market:general'` to the existing market summary response, and map user holding symbols to `news_reports.group_key = SYMBOL` rows for company news cards. The API continues returning the current `summary` JSON shape so existing local cache tables do not need a migration.

**Tech Stack:** Flutter/Dart, `flutter_test`, Supabase Edge Functions on Deno, `@supabase/supabase-js@2`, Supabase Postgres.

---

## Current Findings

- Remote Supabase project: `Moneyfi` / `oeweumxfabobwlhzrzqk`.
- New table: `public.news_reports`.
- Important columns: `id`, `run_id`, `group_key`, `group_label`, `report_ko`, `final_insight_ko`, `article_count`, `high_count`, `max_importance_score`, `model`, `generated_at`, `synced_at`.
- Existing read APIs still query old tables:
  - `supabase/functions/get-market-news-summary/index.ts` reads `market_news_summaries`.
  - `supabase/functions/get-user-company-news-summaries/index.ts` reads `company_news_summaries`.
- Existing Flutter services/widgets expect:
  - Market: `summary.market_summary`, `summary.issues`, `summary.overall_assessment`.
  - Company: `summary.company_summary`, `summary.issues`, `summary.outlook`.
- Keep local cache contract unchanged:
  - `lib/services/market_news_summary_service.dart`
  - `lib/services/company_news_summary_service.dart`
  - `lib/db/app_database.dart` cache methods.

## File Structure

- Modify: `test/news_reports_schema_contract_test.dart`
  - New source-level contract tests for Edge Function table usage and response mapping.
- Modify: `supabase/functions/get-market-news-summary/index.ts`
  - Read latest `news_reports` row for `group_key = market:<category>`.
  - Convert row to existing market summary response shape.
- Modify: `supabase/functions/get-user-company-news-summaries/index.ts`
  - Keep authenticated holding lookup unchanged.
  - Read latest `news_reports` rows for holding symbols.
  - Convert rows to existing company summary item shape.
- Modify only if tests expose parser gaps: `lib/services/market_news_summary_service.dart`
  - Accept `generated_at`/`synced_at` aliases only if API cannot normalize them.
- Modify only if tests expose parser gaps: `lib/services/company_news_summary_service.dart`
  - Accept `generated_at`/`synced_at` aliases only if API cannot normalize them.

## Response Mapping

Market API row mapping:

```ts
{
  ok: true,
  category,
  summary_date: toDateOnly(row.generated_at ?? row.synced_at),
  found: true,
  model: row.model,
  news_count: row.article_count,
  created_at: row.generated_at ?? row.synced_at,
  updated_at: row.synced_at ?? row.generated_at,
  summary: {
    market_summary: row.final_insight_ko || row.report_ko,
    issues: [
      {
        id: row.id,
        title: row.group_label || row.group_key,
        summary: row.report_ko,
        importance: toLegacyImportance(row.max_importance_score),
        market_impact: {
          stocks: row.report_ko,
          bonds_rates: null,
          fx: null,
          crypto: null
        },
        uncertainty: false
      }
    ],
    overall_assessment: {
      key_risk: row.final_insight_ko,
      risk_assets: "주식, 코인 등 위험자산",
      safe_assets: "현금성 자산, 분산 포트폴리오"
    }
  }
}
```

Company API item mapping:

```ts
{
  symbol,
  asset_type: assetType,
  found: true,
  summary_date: toDateOnly(row.generated_at ?? row.synced_at),
  model: row.model,
  news_count: row.article_count,
  created_at: row.generated_at ?? row.synced_at,
  updated_at: row.synced_at ?? row.generated_at,
  summary: {
    company_summary: row.final_insight_ko || row.report_ko,
    issues: [
      {
        id: row.id,
        title: row.group_label || symbol,
        summary: row.report_ko,
        importance: toLegacyImportance(row.max_importance_score),
        sentiment: "neutral",
        uncertainty: false
      }
    ],
    outlook: {
      business_impact: row.final_insight_ko || row.report_ko,
      market_view: row.report_ko,
      watchpoint: `${symbol} 관련 후속 뉴스와 가격 반응`
    }
  }
}
```

Importance mapping:

```ts
function toLegacyImportance(score: unknown): 1 | 2 | 3 {
  const n = asNumber(score);
  if (n >= 80) return 3;
  if (n >= 50) return 2;
  return 1;
}
```

---

### Task 1: Add News Reports Contract Tests

**Files:**
- Create: `test/news_reports_schema_contract_test.dart`

- [ ] **Step 1: Write the failing contract test**

Create `test/news_reports_schema_contract_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final marketSource = File(
    'supabase/functions/get-market-news-summary/index.ts',
  ).readAsStringSync();
  final companySource = File(
    'supabase/functions/get-user-company-news-summaries/index.ts',
  ).readAsStringSync();

  test('market news summary reads and maps news_reports', () {
    expect(marketSource, contains('.from("news_reports")'));
    expect(marketSource, contains('group_key'));
    expect(marketSource, contains('market:${category}'));
    expect(marketSource, contains('report_ko'));
    expect(marketSource, contains('final_insight_ko'));
    expect(marketSource, contains('article_count'));
    expect(marketSource, contains('max_importance_score'));
    expect(marketSource, contains('toMarketSummaryPayload'));
    expect(marketSource, isNot(contains('.from("market_news_summaries")')));
  });

  test('company news summaries read and map news_reports by holding symbols', () {
    expect(companySource, contains('.from("news_reports")'));
    expect(companySource, contains('.in("group_key", symbols)'));
    expect(companySource, contains('report_ko'));
    expect(companySource, contains('final_insight_ko'));
    expect(companySource, contains('article_count'));
    expect(companySource, contains('max_importance_score'));
    expect(companySource, contains('toCompanySummaryItem'));
    expect(companySource, isNot(contains('.from("company_news_summaries")')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/news_reports_schema_contract_test.dart
```

Expected: FAIL because both Edge Functions still reference old summary tables and do not define `toMarketSummaryPayload` or `toCompanySummaryItem`.

- [ ] **Step 3: Commit the failing test only**

```bash
git add test/news_reports_schema_contract_test.dart
git commit -m "test: capture news reports schema contract"
```

---

### Task 2: Update Market News Read API

**Files:**
- Modify: `supabase/functions/get-market-news-summary/index.ts`
- Test: `test/news_reports_schema_contract_test.dart`

- [ ] **Step 1: Add helper functions**

Add these helpers after `asSummaryDate`:

```ts
function asNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(/,/g, "").trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function toDateOnly(value: unknown): string | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value.split("T")[0] || null;
  }
  return parsed.toISOString().split("T")[0];
}

function toLegacyImportance(score: unknown): 1 | 2 | 3 {
  const n = asNumber(score);
  if (n >= 80) return 3;
  if (n >= 50) return 2;
  return 1;
}

function toMarketSummaryPayload(
  row: Record<string, unknown>,
): Record<string, unknown> {
  const report = `${row.report_ko ?? ""}`.trim();
  const insight = `${row.final_insight_ko ?? ""}`.trim();
  const title = `${row.group_label ?? row.group_key ?? "종합 뉴스"}`.trim();

  return {
    market_summary: insight || report,
    issues: report.length === 0 ? [] : [
      {
        id: `${row.id ?? row.group_key ?? "market-news"}`,
        title,
        summary: report,
        importance: toLegacyImportance(row.max_importance_score),
        market_impact: {
          stocks: report,
          bonds_rates: null,
          fx: null,
          crypto: null,
        },
        uncertainty: false,
      },
    ],
    overall_assessment: {
      key_risk: insight,
      risk_assets: "주식, 코인 등 위험자산",
      safe_assets: "현금성 자산, 분산 포트폴리오",
    },
  };
}
```

- [ ] **Step 2: Replace old table query**

Replace the `market_news_summaries` query block with:

```ts
    const groupKey = `market:${category}`;
    let query = supabase
      .from("news_reports")
      .select(
        "id, group_key, group_label, report_ko, final_insight_ko, article_count, max_importance_score, model, generated_at, synced_at",
      )
      .eq("group_key", groupKey)
      .order("generated_at", { ascending: false, nullsFirst: false })
      .order("synced_at", { ascending: false })
      .limit(1);

    if (summaryDate != null) {
      query = query
        .gte("generated_at", `${summaryDate}T00:00:00.000Z`)
        .lt("generated_at", `${summaryDate}T23:59:59.999Z`);
    }

    const { data, error } = await query.maybeSingle();
```

- [ ] **Step 3: Replace response payload**

Replace the `if (!data)` and success response with:

```ts
    if (!data) {
      return jsonResponse({
        ok: true,
        category,
        summary_date: summaryDate,
        found: false,
        summary: null,
      });
    }

    const row = data as Record<string, unknown>;
    const timestamp = row.generated_at ?? row.synced_at;

    return jsonResponse({
      ok: true,
      category,
      summary_date: toDateOnly(timestamp),
      found: true,
      model: row.model,
      news_count: row.article_count,
      created_at: row.generated_at ?? row.synced_at,
      updated_at: row.synced_at ?? row.generated_at,
      summary: toMarketSummaryPayload(row),
    });
```

- [ ] **Step 4: Run focused test**

Run:

```bash
flutter test test/news_reports_schema_contract_test.dart
```

Expected: company test still FAILS, market test PASSES.

- [ ] **Step 5: Commit market API change**

```bash
git add supabase/functions/get-market-news-summary/index.ts
git commit -m "fix(news): read market reports from news_reports"
```

---

### Task 3: Update Company News Read API

**Files:**
- Modify: `supabase/functions/get-user-company-news-summaries/index.ts`
- Test: `test/news_reports_schema_contract_test.dart`

- [ ] **Step 1: Add helper functions**

Add these helpers after `toTimestamp`:

```ts
function toDateOnly(value: unknown): string | null {
  const text = asString(value);
  if (!text) return null;
  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) {
    return text.split("T")[0] || null;
  }
  return parsed.toISOString().split("T")[0];
}

function toLegacyImportance(score: unknown): 1 | 2 | 3 {
  const n = asNumber(score);
  if (n >= 80) return 3;
  if (n >= 50) return 2;
  return 1;
}

function selectLatestReportByGroupKey(
  rows: unknown[],
): Map<string, Record<string, unknown>> {
  const latestByGroupKey = new Map<string, Record<string, unknown>>();

  for (const rawRow of rows) {
    const row = (rawRow ?? {}) as Record<string, unknown>;
    const groupKey = asString(row.group_key).toUpperCase();
    if (!groupKey) continue;

    const current = latestByGroupKey.get(groupKey);
    if (!current) {
      latestByGroupKey.set(groupKey, row);
      continue;
    }

    const rowTs = Math.max(toTimestamp(row.generated_at), toTimestamp(row.synced_at));
    const currentTs = Math.max(
      toTimestamp(current.generated_at),
      toTimestamp(current.synced_at),
    );
    if (rowTs > currentTs) {
      latestByGroupKey.set(groupKey, row);
    }
  }

  return latestByGroupKey;
}

function toCompanySummaryItem({
  symbol,
  assetType,
  row,
}: {
  symbol: string;
  assetType: SupportedAssetType;
  row?: Record<string, unknown>;
}): Record<string, unknown> {
  if (!row) {
    return {
      symbol,
      asset_type: assetType,
      found: false,
    };
  }

  const report = `${row.report_ko ?? ""}`.trim();
  const insight = `${row.final_insight_ko ?? ""}`.trim();
  const timestamp = row.generated_at ?? row.synced_at;

  return {
    symbol,
    asset_type: assetType,
    found: true,
    summary_date: toDateOnly(timestamp),
    model: row.model,
    news_count: row.article_count,
    created_at: row.generated_at ?? row.synced_at,
    updated_at: row.synced_at ?? row.generated_at,
    summary: {
      company_summary: insight || report,
      issues: report.length === 0 ? [] : [
        {
          id: `${row.id ?? symbol}`,
          title: `${row.group_label ?? symbol}`,
          summary: report,
          importance: toLegacyImportance(row.max_importance_score),
          sentiment: "neutral",
          uncertainty: false,
        },
      ],
      outlook: {
        business_impact: insight || report,
        market_view: report,
        watchpoint: `${symbol} 관련 후속 뉴스와 가격 반응`,
      },
    },
  };
}
```

- [ ] **Step 2: Replace old summary query**

Replace the `company_news_summaries` query and `latestBySymbol` calculation with:

```ts
    const summariesResponse = await supabase
      .from("news_reports")
      .select(
        "id, group_key, group_label, report_ko, final_insight_ko, article_count, max_importance_score, model, generated_at, synced_at",
      )
      .in("group_key", symbols)
      .order("group_key", { ascending: true })
      .order("generated_at", { ascending: false, nullsFirst: false })
      .order("synced_at", { ascending: false });

    const summariesErrorMessage = extractSupabaseErrorMessage(
      summariesResponse,
    );
    if (summariesErrorMessage) {
      throw new Error(
        `Failed to load company summaries: ${summariesErrorMessage}`,
      );
    }

    const latestByGroupKey = selectLatestReportByGroupKey(
      extractSupabaseData(summariesResponse),
    );
```

- [ ] **Step 3: Replace item mapping**

Replace the `items = symbols.map(...)` block with:

```ts
    const items = symbols.map((symbol) =>
      toCompanySummaryItem({
        symbol,
        assetType: symbolAssetTypeMap.get(symbol) ?? "주식",
        row: latestByGroupKey.get(symbol),
      })
    );
```

- [ ] **Step 4: Remove obsolete selector**

Delete `selectLatestSummaryBySymbol` if no references remain.

- [ ] **Step 5: Run focused test**

Run:

```bash
flutter test test/news_reports_schema_contract_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit company API change**

```bash
git add supabase/functions/get-user-company-news-summaries/index.ts
git commit -m "fix(news): read company reports from news_reports"
```

---

### Task 4: Verify Flutter Parsing and Cache Compatibility

**Files:**
- Modify only if needed: `lib/services/market_news_summary_service.dart`
- Modify only if needed: `lib/services/company_news_summary_service.dart`
- Test: existing Flutter test suite

- [ ] **Step 1: Run news contract test**

Run:

```bash
flutter test test/news_reports_schema_contract_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run related source contract tests**

Run:

```bash
flutter test test/snapshot_sync_contract_test.dart test/sync_currency_basis_contract_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run full Flutter tests**

Run:

```bash
flutter test
```

Expected: PASS.

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no new issues.

- [ ] **Step 5: Commit any parser compatibility changes**

If no Flutter service changes were needed, skip this commit. If changes were needed:

```bash
git add lib/services/market_news_summary_service.dart lib/services/company_news_summary_service.dart
git commit -m "fix(news): tolerate report timestamp aliases"
```

---

### Task 5: Remote Smoke Verification

**Files:**
- No local file changes.

- [ ] **Step 1: Confirm remote schema still matches**

Use Supabase SQL against project `oeweumxfabobwlhzrzqk`:

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'news_reports'
order by ordinal_position;
```

Expected: includes `group_key`, `report_ko`, `final_insight_ko`, `article_count`, `max_importance_score`, `model`, `generated_at`, `synced_at`.

- [ ] **Step 2: Confirm market report exists**

Use Supabase SQL:

```sql
select group_key, group_label, article_count, model, generated_at, synced_at
from public.news_reports
where group_key = 'market:general'
order by generated_at desc nulls last, synced_at desc
limit 1;
```

Expected: one row when data has been generated; zero rows should make the API return `found: false`, not error.

- [ ] **Step 3: Confirm sample company reports exist**

Use Supabase SQL:

```sql
select group_key, group_label, article_count, model, generated_at, synced_at
from public.news_reports
where group_key in ('TSLA', 'PLTR')
order by group_key, generated_at desc nulls last, synced_at desc;
```

Expected: rows exist for symbols that have generated reports.

- [ ] **Step 4: Document deployment note**

Before deployment, note that these changed functions must be deployed:

```bash
supabase functions deploy get-market-news-summary
supabase functions deploy get-user-company-news-summaries
```

Deployment is not part of this local implementation unless explicitly requested.

---

## Self-Review

- Spec coverage: The plan covers Supabase schema verification, market read API adaptation, company read API adaptation, Flutter compatibility checks, and remote smoke checks.
- Placeholder scan: No TBD/TODO/fill-later instructions remain.
- Type consistency: Helper names match contract tests: `toMarketSummaryPayload`, `toCompanySummaryItem`; API response keys match existing Flutter parsers.
- Scope check: Existing summary generator functions are intentionally out of scope because the new `news_reports` table already contains generated report rows. If generation should also move to `news_reports`, that should be a separate plan.
