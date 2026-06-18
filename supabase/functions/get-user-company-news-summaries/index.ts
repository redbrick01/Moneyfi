import { createClient } from "npm:@supabase/supabase-js@2";
import { authenticateUser } from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

const SUPPORTED_ASSET_TYPES = new Set(["주식", "코인"]);
type SupportedAssetType = "주식" | "코인";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(/,/g, "").trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function extractSupabaseErrorMessage(result: unknown): string | null {
  if (!result || typeof result !== "object") return "Unknown Supabase response";
  const errorValue = (result as Record<string, unknown>).error;
  if (!errorValue || typeof errorValue !== "object") return null;
  const message = (errorValue as Record<string, unknown>).message;
  if (typeof message === "string" && message.trim().length > 0) {
    return message.trim();
  }
  return "Unknown Supabase error";
}

function extractSupabaseData(result: unknown): unknown[] {
  if (!result || typeof result !== "object") return [];
  const data = (result as Record<string, unknown>).data;
  return Array.isArray(data) ? data : [];
}

function extractAssetType(row: Record<string, unknown>): string {
  const assetValue = row.assets;
  if (Array.isArray(assetValue)) {
    for (const item of assetValue) {
      if (item && typeof item === "object") {
        const assetType = asString(
          (item as Record<string, unknown>).asset_type,
        );
        if (assetType) return assetType;
      }
    }
    return "";
  }

  if (assetValue && typeof assetValue === "object") {
    return asString((assetValue as Record<string, unknown>).asset_type);
  }

  return "";
}

function extractAssetDeleted(row: Record<string, unknown>): boolean {
  const assetValue = row.assets;
  if (Array.isArray(assetValue)) {
    return assetValue.some((item) => {
      if (!item || typeof item !== "object") return false;
      return Boolean((item as Record<string, unknown>).deleted_at);
    });
  }

  if (assetValue && typeof assetValue === "object") {
    return Boolean((assetValue as Record<string, unknown>).deleted_at);
  }

  return false;
}

function toTimestamp(value: unknown): number {
  const text = asString(value);
  if (!text) return Number.NEGATIVE_INFINITY;
  const parsed = Date.parse(text);
  return Number.isFinite(parsed) ? parsed : Number.NEGATIVE_INFINITY;
}

function toKstDateOnly(value: unknown): string | null {
  const text = asString(value);
  if (!text) return null;
  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) {
    return text.split("T")[0] || null;
  }
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(parsed);
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

    const rowGeneratedAtTs = toTimestamp(row.generated_at);
    const currentGeneratedAtTs = toTimestamp(current.generated_at);
    if (rowGeneratedAtTs > currentGeneratedAtTs) {
      latestByGroupKey.set(groupKey, row);
      continue;
    }
    if (rowGeneratedAtTs < currentGeneratedAtTs) {
      continue;
    }

    const rowSyncedAtTs = toTimestamp(row.synced_at);
    const currentSyncedAtTs = toTimestamp(current.synced_at);
    if (rowSyncedAtTs > currentSyncedAtTs) {
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
    summary_date: toKstDateOnly(timestamp),
    model: row.model,
    news_count: row.article_count,
    created_at: row.generated_at ?? row.synced_at,
    updated_at: row.synced_at ?? row.generated_at,
    summary: {
      company_summary: insight,
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

Deno.serve(async (req) => {
  try {
    const auth = await authenticateUser(
      req.headers.get("Authorization"),
      SUPABASE_URL,
      SUPABASE_ANON_KEY,
    );
    if (!auth.userId) {
      return jsonResponse(
        {
          ok: false,
          step: "auth_verify",
          reason: auth.reason,
        },
        auth.reason === "missing_auth_env" ? 500 : 401,
      );
    }

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return jsonResponse(
        {
          ok: false,
          step: "env_check",
          supabase_url_exists: !!SUPABASE_URL,
          anon_key_exists: !!SUPABASE_ANON_KEY,
          service_role_exists: !!SUPABASE_SERVICE_ROLE_KEY,
        },
        500,
      );
    }

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    const holdingsResponse = await supabase
      .from("holdings")
      .select(
        "symbol, quantity, deleted_at, assets!inner(asset_type, deleted_at)",
      )
      .eq("user_id", auth.userId)
      .is("deleted_at", null)
      .gt("quantity", 0);

    const holdingsErrorMessage = extractSupabaseErrorMessage(holdingsResponse);
    if (holdingsErrorMessage) {
      throw new Error(`Failed to load holdings: ${holdingsErrorMessage}`);
    }

    const symbolAssetTypeMap = new Map<string, SupportedAssetType>();
    for (const row of extractSupabaseData(holdingsResponse)) {
      const record = (row ?? {}) as Record<string, unknown>;
      const assetType = extractAssetType(record);
      const assetDeleted = extractAssetDeleted(record);
      if (
        assetDeleted === true ||
        asNumber(record.quantity) <= 0 ||
        !SUPPORTED_ASSET_TYPES.has(assetType)
      ) {
        continue;
      }

      const symbol = asString(record.symbol).toUpperCase();
      if (!symbol) continue;

      if (assetType === "코인") {
        symbolAssetTypeMap.set(symbol, "코인");
      } else if (!symbolAssetTypeMap.has(symbol)) {
        symbolAssetTypeMap.set(symbol, "주식");
      }
    }

    const symbols = Array.from(symbolAssetTypeMap.keys());

    if (symbols.length === 0) {
      return jsonResponse({
        ok: true,
        count: 0,
        items: [],
      });
    }

    const reportsResponse = await supabase
      .from("news_reports")
      .select(
        "id, group_key, group_label, report_ko, final_insight_ko, article_count, max_importance_score, model, generated_at, synced_at",
      )
      .in("group_key", symbols)
      .order("group_key", { ascending: true })
      .order("generated_at", { ascending: false });

    const summariesErrorMessage = extractSupabaseErrorMessage(
      reportsResponse,
    );
    if (summariesErrorMessage) {
      throw new Error(
        `Failed to load company summaries: ${summariesErrorMessage}`,
      );
    }

    const latestByGroupKey = selectLatestReportByGroupKey(
      extractSupabaseData(reportsResponse),
    );

    const items = symbols.map((symbol) => {
      const assetType = symbolAssetTypeMap.get(symbol) ?? "주식";
      return toCompanySummaryItem({
        symbol,
        assetType,
        row: latestByGroupKey.get(symbol),
      });
    });

    return jsonResponse({
      ok: true,
      count: items.filter((item) => item.found === true).length,
      items,
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
