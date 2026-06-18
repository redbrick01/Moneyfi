import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function asCategory(value: unknown): "general" | "forex" | "crypto" | "merger" {
  const normalized = asString(value);
  if (normalized === "general") return "general";
  if (normalized === "forex") return "forex";
  if (normalized === "crypto") return "crypto";
  if (normalized === "merger") return "merger";
  return "general";
}

function asSummaryDate(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
    return null;
  }

  return normalized;
}

function asNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(/,/g, "").trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function toKstDateOnly(value: unknown): string | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(parsed);
}

function kstDateToUtcRange(
  date: string,
): { startIso: string; endIso: string } {
  const [year, month, day] = date.split("-").map((part) => Number(part));
  return {
    startIso: new Date(
      Date.UTC(year, month - 1, day, -9, 0, 0, 0),
    ).toISOString(),
    endIso: new Date(
      Date.UTC(year, month - 1, day + 1, -9, 0, 0, 0),
    ).toISOString(),
  };
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
    market_summary: insight,
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
  };
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const url = new URL(req.url);
    const category = asCategory(
      body?.category ?? url.searchParams.get("category"),
    );
    const summaryDate = asSummaryDate(
      body?.summary_date ?? url.searchParams.get("summary_date"),
    );

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

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
      const { startIso, endIso } = kstDateToUtcRange(summaryDate);
      query = query
        .gte("generated_at", startIso)
        .lt("generated_at", endIso);
    }

    const { data, error } = await query.maybeSingle();

    if (error) {
      throw new Error(`Failed to load market news summary: ${error.message}`);
    }

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
      summary_date: toKstDateOnly(timestamp),
      found: true,
      model: row.model,
      news_count: row.article_count,
      created_at: row.generated_at ?? row.synced_at,
      updated_at: row.synced_at ?? row.generated_at,
      summary: toMarketSummaryPayload(row),
    });
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
