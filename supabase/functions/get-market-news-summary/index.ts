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

    let query = supabase
      .from("market_news_summaries")
      .select(
        "category, summary_date, model, news_count, summary_json, created_at, updated_at",
      )
      .eq("category", category)
      .order("summary_date", { ascending: false })
      .limit(1);

    if (summaryDate != null) {
      query = query.eq("summary_date", summaryDate);
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

    return jsonResponse({
      ok: true,
      category,
      summary_date: data.summary_date,
      found: true,
      model: data.model,
      news_count: data.news_count,
      created_at: data.created_at,
      updated_at: data.updated_at,
      summary: data.summary_json,
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
