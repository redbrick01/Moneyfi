import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const FINNHUB_API_KEY = Deno.env.get("FINNHUB_API_KEY") ?? "";
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const MAX_NEWS_ROWS = 40;

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
    return true;
  }

  return req.headers.get("x-cron-secret") === CRON_SECRET;
}

function asCategory(value: unknown) {
  const normalized = typeof value === "string"
    ? value.trim().toLowerCase()
    : "";
  if (["general", "forex", "crypto", "merger"].includes(normalized)) {
    return normalized;
  }
  return "general";
}

function previous24HoursRange(now = new Date()) {
  const to = now;
  const from = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  return {
    from,
    to,
    fromIso: from.toISOString(),
    toIso: to.toISOString(),
  };
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

function asNewsRows(value: unknown): FinnhubNewsRow[] {
  if (!Array.isArray(value)) return [];
  return value.filter((row): row is FinnhubNewsRow =>
    !!row && typeof row === "object"
  );
}

function asNumber(value: unknown, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asString(value: unknown, fallback = "") {
  if (typeof value === "string") return value;
  if (value == null) return fallback;
  return String(value);
}

function asUnixSeconds(value: unknown): number | null {
  const unixSeconds = asNumber(value, 0);
  if (!Number.isFinite(unixSeconds) || unixSeconds <= 0) {
    return null;
  }
  return unixSeconds;
}

function toIsoFromUnixSeconds(value: unknown) {
  const unixSeconds = asUnixSeconds(value);
  if (unixSeconds == null) {
    return new Date().toISOString();
  }
  return new Date(unixSeconds * 1000).toISOString();
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);
    requireEnv("FINNHUB_API_KEY", FINNHUB_API_KEY);
    requireEnv("CRON_SECRET", CRON_SECRET);

    if (!isAuthorizedCronRequest(req)) {
      return jsonResponse({ ok: false, error: "Unauthorized" }, 401);
    }

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const url = new URL(req.url);
    const category = asCategory(
      body?.category ?? url.searchParams.get("category"),
    );

    const requestUrl = new URL("https://finnhub.io/api/v1/news");
    requestUrl.searchParams.set("category", category);
    requestUrl.searchParams.set("token", FINNHUB_API_KEY);

    const response = await fetch(requestUrl.toString(), {
      headers: { Accept: "application/json" },
    });

    if (!response.ok) {
      throw new Error(
        `Finnhub request failed: ${response.status} ${response.statusText}`,
      );
    }

    const payload = await response.json();
    const { from, to, fromIso, toIso } = previous24HoursRange();
    const fetchedRows = asNewsRows(payload).slice(0, MAX_NEWS_ROWS);
    let droppedInvalidDatetimeCount = 0;
    let droppedOutOfRangeCount = 0;
    const newsRows = fetchedRows.filter((row) => {
      const unixSeconds = asUnixSeconds(row.datetime);
      if (unixSeconds == null) {
        droppedInvalidDatetimeCount += 1;
        return false;
      }
      const publishedAt = new Date(unixSeconds * 1000);
      const inRange = publishedAt >= from && publishedAt <= to;
      if (!inRange) {
        droppedOutOfRangeCount += 1;
      }
      return inRange;
    });

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    const fetchedAt = new Date().toISOString();
    const upsertCandidates = newsRows.map((row) => ({
      finnhub_id: asNumber(row.id),
      category,
      news_datetime: toIsoFromUnixSeconds(row.datetime),
      headline: asString(row.headline),
      image_url: asString(row.image),
      related: asString(row.related),
      source: asString(row.source),
      summary: asString(row.summary),
      url: asString(row.url),
      fetched_at: fetchedAt,
      updated_at: fetchedAt,
      raw_payload: row,
    }));
    const upsertRows = upsertCandidates.filter((row) =>
      row.finnhub_id > 0 && row.headline.trim() && row.summary.trim() &&
      row.url.trim()
    );
    const droppedMissingRequiredCount = upsertCandidates.length -
      upsertRows.length;

    if (upsertRows.length > 0) {
      const { error } = await supabase
        .from("market_news")
        .upsert(upsertRows, { onConflict: "finnhub_id" });
      if (error) {
        throw new Error(`Failed to upsert market news: ${error.message}`);
      }
    }

    const { error: cleanupError } = await supabase
      .from("market_news")
      .delete()
      .eq("category", category)
      .lt("news_datetime", fromIso);

    if (cleanupError) {
      throw new Error(
        `Failed to clean old market news: ${cleanupError.message}`,
      );
    }

    return jsonResponse({
      ok: true,
      category,
      date: new Date().toISOString().slice(0, 10),
      from: fromIso,
      to: toIso,
      fetched_count: fetchedRows.length,
      in_24h_count: newsRows.length,
      dropped_invalid_datetime_count: droppedInvalidDatetimeCount,
      dropped_out_of_range_count: droppedOutOfRangeCount,
      dropped_missing_required_count: droppedMissingRequiredCount,
      valid_count: upsertRows.length,
      saved_count: upsertRows.length,
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
