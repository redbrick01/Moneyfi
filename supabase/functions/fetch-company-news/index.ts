import { createClient } from "npm:@supabase/supabase-js@2";
import { authenticateUser } from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const FINNHUB_API_KEY = Deno.env.get("FINNHUB_API_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const SUPPORTED_ASSET_TYPES = new Set(["주식", "코인"]);
const MAX_FETCH_DAYS = 2;
const MAX_NEWS_PER_SYMBOL = 5;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function isAuthorizedCronRequest(req: Request) {
  if (!CRON_SECRET) {
    return false;
  }

  return req.headers.get("x-cron-secret") === CRON_SECRET;
}

function asString(value: unknown, fallback = "") {
  if (typeof value === "string") return value;
  if (value == null) return fallback;
  return String(value);
}

function asNumber(value: unknown, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asPositiveInt(value: unknown, fallback: number, max: number) {
  const parsed = asNumber(value, fallback);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }
  return Math.min(Math.trunc(parsed), max);
}

type FinnhubNewsRow = {
  category?: unknown;
  datetime?: unknown;
  headline?: unknown;
  id?: unknown;
  image?: unknown;
  related?: unknown;
  source?: unknown;
  summary?: unknown;
  url?: unknown;
};

type TargetSymbol = {
  symbol: string;
  assetType: "주식" | "코인";
};

function asNewsRows(value: unknown): FinnhubNewsRow[] {
  if (!Array.isArray(value)) return [];
  return value.filter((row): row is FinnhubNewsRow =>
    !!row && typeof row === "object"
  );
}

function toIsoFromUnixSeconds(value: unknown) {
  const unixSeconds = asNumber(value, 0);
  if (unixSeconds <= 0) {
    return new Date().toISOString();
  }
  return new Date(unixSeconds * 1000).toISOString();
}

function formatDate(date: Date) {
  return date.toISOString().slice(0, 10);
}

function buildDateRange(days: number) {
  const now = new Date();
  const to = formatDate(now);
  const fromDate = new Date(now);
  fromDate.setUTCDate(fromDate.getUTCDate() - days);
  const from = formatDate(fromDate);
  return { from, to };
}

function extractAssetType(row: Record<string, unknown>): string {
  const assetValue = row.assets;
  if (Array.isArray(assetValue)) {
    for (const item of assetValue) {
      if (item && typeof item === "object") {
        const assetType = asString((item as Record<string, unknown>).asset_type)
          .trim();
        if (assetType) return assetType;
      }
    }
    return "";
  }

  if (assetValue && typeof assetValue === "object") {
    return asString((assetValue as Record<string, unknown>).asset_type).trim();
  }

  return "";
}

function extractAssetHidden(row: Record<string, unknown>): boolean {
  const assetValue = row.assets;
  if (Array.isArray(assetValue)) {
    return assetValue.some((item) => {
      if (!item || typeof item !== "object") return false;
      return (item as Record<string, unknown>).hidden === true;
    });
  }

  if (assetValue && typeof assetValue === "object") {
    return (assetValue as Record<string, unknown>).hidden === true;
  }

  return false;
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

function relatedIncludesSymbol(related: unknown, symbol: string) {
  const normalizedSymbol = symbol.trim().toUpperCase();
  if (!normalizedSymbol) return false;
  const tokens = asString(related)
    .toUpperCase()
    .split(/[^A-Z0-9]+/)
    .map((token) => token.trim())
    .filter((token) => token.length > 0);
  return tokens.includes(normalizedSymbol);
}

function headlineOrSummaryIncludesSymbol(row: FinnhubNewsRow, symbol: string) {
  const normalizedSymbol = symbol.trim().toUpperCase();
  if (!normalizedSymbol) return false;
  const headline = asString(row.headline).toUpperCase();
  const summary = asString(row.summary).toUpperCase();
  return headline.includes(normalizedSymbol) ||
    summary.includes(normalizedSymbol);
}

function dateKeyFromUnixSeconds(value: unknown) {
  const unixSeconds = asNumber(value, 0);
  if (unixSeconds <= 0) return "";
  return formatDate(new Date(unixSeconds * 1000));
}

async function fetchStockNews(
  symbol: string,
  range: { from: string; to: string },
) {
  const requestUrl = new URL("https://finnhub.io/api/v1/company-news");
  requestUrl.searchParams.set("symbol", symbol);
  requestUrl.searchParams.set("from", range.from);
  requestUrl.searchParams.set("to", range.to);
  requestUrl.searchParams.set("token", FINNHUB_API_KEY);

  const response = await fetch(requestUrl.toString(), {
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    throw new Error(
      `Finnhub request failed for ${symbol}: ${response.status} ${response.statusText}`,
    );
  }

  const payload = await response.json().catch(() => []);
  return asNewsRows(payload);
}

async function fetchCryptoNewsFeed() {
  const requestUrl = new URL("https://finnhub.io/api/v1/news");
  requestUrl.searchParams.set("category", "crypto");
  requestUrl.searchParams.set("token", FINNHUB_API_KEY);

  const response = await fetch(requestUrl.toString(), {
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    throw new Error(
      `Finnhub crypto request failed: ${response.status} ${response.statusText}`,
    );
  }

  const payload = await response.json().catch(() => []);
  return asNewsRows(payload);
}

function filterCryptoNewsBySymbol(
  rows: FinnhubNewsRow[],
  symbol: string,
  range: { from: string; to: string },
) {
  return rows.filter((row) => {
    const dateKey = dateKeyFromUnixSeconds(row.datetime);
    if (!dateKey || dateKey < range.from || dateKey > range.to) {
      return false;
    }

    return relatedIncludesSymbol(row.related, symbol) ||
      headlineOrSummaryIncludesSymbol(row, symbol);
  });
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_ANON_KEY", SUPABASE_ANON_KEY);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);
    requireEnv("FINNHUB_API_KEY", FINNHUB_API_KEY);

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const url = new URL(req.url);
    const cronRequest = isAuthorizedCronRequest(req);
    const auth = cronRequest
      ? { userId: null as string | null, reason: "cron_secret" }
      : await authenticateUser(
        req.headers.get("Authorization"),
        SUPABASE_URL,
        SUPABASE_ANON_KEY,
      );
    if (!cronRequest && !auth.userId) {
      return jsonResponse(
        {
          ok: false,
          step: "auth_verify",
          reason: auth.reason,
        },
        auth.reason === "missing_auth_env" ? 500 : 401,
      );
    }

    const days = asPositiveInt(
      body?.days ?? url.searchParams.get("days"),
      MAX_FETCH_DAYS,
      MAX_FETCH_DAYS,
    );
    const limit = asPositiveInt(
      body?.limit ?? url.searchParams.get("limit"),
      MAX_NEWS_PER_SYMBOL,
      MAX_NEWS_PER_SYMBOL,
    );
    const range = buildDateRange(days);

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    let holdingsQuery = supabase
      .from("holdings")
      .select(
        "symbol, currency_code, quantity, hidden, deleted_at, assets!inner(asset_type, hidden, deleted_at)",
      );
    if (!cronRequest) {
      holdingsQuery = holdingsQuery.eq("user_id", auth.userId);
    }

    const { data: holdings, error: holdingsError } = await holdingsQuery;

    if (holdingsError) {
      throw new Error(`Failed to load holdings: ${holdingsError.message}`);
    }

    const targetsBySymbol = new Map<string, TargetSymbol>();
    for (const row of holdings ?? []) {
      const record = row as Record<string, unknown>;
      const symbol = asString(record.symbol).trim().toUpperCase();
      if (!symbol) continue;

      const assetType = extractAssetType(record);
      if (!SUPPORTED_ASSET_TYPES.has(assetType)) continue;
      if (
        record.hidden === true ||
        Boolean(record.deleted_at) ||
        extractAssetHidden(record) ||
        extractAssetDeleted(record) ||
        asNumber(record.quantity) <= 0
      ) {
        continue;
      }

      const currencyCode = asString(record.currency_code).trim().toUpperCase();
      if (assetType !== "코인" && currencyCode !== "USD") continue;

      if (assetType === "코인") {
        targetsBySymbol.set(symbol, { symbol, assetType: "코인" });
      } else if (!targetsBySymbol.has(symbol)) {
        targetsBySymbol.set(symbol, { symbol, assetType: "주식" });
      }
    }

    const targets = Array.from(targetsBySymbol.values());
    const symbols = targets.map((target) => target.symbol);

    if (symbols.length === 0) {
      return jsonResponse({
        ok: true,
        from: range.from,
        to: range.to,
        symbol_count: 0,
        saved_count: 0,
      });
    }

    const fetchedAt = new Date().toISOString();
    const upsertRows: Array<Record<string, unknown>> = [];
    const failures: Array<{ symbol: string; reason: string }> = [];
    const cryptoTargets = targets.filter((target) =>
      target.assetType === "코인"
    );
    let cryptoFeed: FinnhubNewsRow[] | null = null;

    if (cryptoTargets.length > 0) {
      try {
        cryptoFeed = await fetchCryptoNewsFeed();
      } catch (error) {
        const reason = error instanceof Error ? error.message : String(error);
        for (const target of cryptoTargets) {
          failures.push({ symbol: target.symbol, reason });
        }
      }
    }

    for (const target of targets) {
      try {
        const rawRows = target.assetType === "코인"
          ? filterCryptoNewsBySymbol(cryptoFeed ?? [], target.symbol, range)
          : await fetchStockNews(target.symbol, range);
        const newsRows = rawRows
          .sort((a, b) => asNumber(b.datetime) - asNumber(a.datetime))
          .slice(0, limit);

        upsertRows.push(
          ...newsRows.map((row) => ({
            symbol: target.symbol,
            finnhub_id: asNumber(row.id),
            news_datetime: toIsoFromUnixSeconds(row.datetime),
            headline: asString(row.headline),
            image_url: asString(row.image),
            category: asString(row.category),
            related: asString(row.related),
            source: asString(row.source),
            summary: asString(row.summary),
            url: asString(row.url),
            fetched_at: fetchedAt,
            updated_at: fetchedAt,
            raw_payload: row,
          })).filter((row) =>
            row.finnhub_id > 0 && row.headline.trim() && row.summary.trim() &&
            row.url.trim()
          ),
        );
      } catch (error) {
        failures.push({
          symbol: target.symbol,
          reason: error instanceof Error ? error.message : String(error),
        });
      }
    }

    const { error: deleteError } = await supabase
      .from("company_news")
      .delete()
      .not("finnhub_id", "is", null);
    if (deleteError) {
      throw new Error(`Failed to clear company news: ${deleteError.message}`);
    }

    if (upsertRows.length > 0) {
      const { error } = await supabase
        .from("company_news")
        .insert(upsertRows);
      if (error) {
        throw new Error(`Failed to insert company news: ${error.message}`);
      }
    }

    return jsonResponse({
      ok: failures.length === 0,
      symbols,
      from: range.from,
      to: range.to,
      per_symbol_limit: limit,
      symbol_count: symbols.length,
      saved_count: upsertRows.length,
      failure_count: failures.length,
      failures,
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
