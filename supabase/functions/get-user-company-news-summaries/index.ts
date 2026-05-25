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

function selectLatestSummaryBySymbol(
  rows: unknown[],
): Map<string, Record<string, unknown>> {
  const latestBySymbol = new Map<string, Record<string, unknown>>();

  for (const rawRow of rows) {
    const row = (rawRow ?? {}) as Record<string, unknown>;
    const symbol = asString(row.symbol).toUpperCase();
    if (!symbol) continue;

    const current = latestBySymbol.get(symbol);
    if (!current) {
      latestBySymbol.set(symbol, row);
      continue;
    }

    const rowSummaryDateTs = toTimestamp(row.summary_date);
    const currentSummaryDateTs = toTimestamp(current.summary_date);
    if (rowSummaryDateTs > currentSummaryDateTs) {
      latestBySymbol.set(symbol, row);
      continue;
    }
    if (rowSummaryDateTs < currentSummaryDateTs) {
      continue;
    }

    const rowUpdatedAtTs = toTimestamp(row.updated_at);
    const currentUpdatedAtTs = toTimestamp(current.updated_at);
    if (rowUpdatedAtTs > currentUpdatedAtTs) {
      latestBySymbol.set(symbol, row);
    }
  }

  return latestBySymbol;
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

    const summariesResponse = await supabase
      .from("company_news_summaries")
      .select(
        "symbol, summary_date, model, news_count, summary_json, created_at, updated_at",
      )
      .in("symbol", symbols)
      .order("symbol", { ascending: true })
      .order("summary_date", { ascending: false });

    const summariesErrorMessage = extractSupabaseErrorMessage(
      summariesResponse,
    );
    if (summariesErrorMessage) {
      throw new Error(
        `Failed to load company summaries: ${summariesErrorMessage}`,
      );
    }

    const latestBySymbol = selectLatestSummaryBySymbol(
      extractSupabaseData(summariesResponse),
    );

    const items = symbols.map((symbol) => {
      const assetType = symbolAssetTypeMap.get(symbol) ?? "주식";
      const row = latestBySymbol.get(symbol);
      if (!row) {
        return {
          symbol,
          asset_type: assetType,
          found: false,
        };
      }

      return {
        symbol,
        asset_type: assetType,
        found: true,
        summary_date: row.summary_date,
        model: row.model,
        news_count: row.news_count,
        created_at: row.created_at,
        updated_at: row.updated_at,
        summary: row.summary_json,
      };
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
