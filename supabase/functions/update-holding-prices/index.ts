import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type AssetType = "주식" | "코인" | "현금" | "펀드" | string;

type HoldingRow = {
  id: string | number;
  user_id: string;
  asset_type: AssetType;
  symbol: string;
  currency_code: string;
  exchange_code: string;
  hidden: boolean;
  deleted_at: string | null;
  current_price: number | null;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

const KIS_BASE_URL = Deno.env.get("KIS_BASE_URL") ??
  "https://openapi.koreainvestment.com:9443";
const KIS_APP_KEY = Deno.env.get("KIS_APP_KEY") ?? "";
const KIS_APP_SECRET = Deno.env.get("KIS_APP_SECRET") ?? "";
const KIS_STOCK_QUOTE_PATH = Deno.env.get("KIS_STOCK_QUOTE_PATH") ??
  "/uapi/domestic-stock/v1/quotations/inquire-price";
const KIS_STOCK_QUOTE_TR_ID = Deno.env.get("KIS_STOCK_QUOTE_TR_ID") ??
  "FHKST01010100";
const KIS_OVERSEAS_STOCK_QUOTE_PATH =
  Deno.env.get("KIS_OVERSEAS_STOCK_QUOTE_PATH") ??
    "/uapi/overseas-price/v1/quotations/price-detail";
const KIS_OVERSEAS_STOCK_QUOTE_TR_ID =
  Deno.env.get("KIS_OVERSEAS_STOCK_QUOTE_TR_ID") ?? "HHDFS76200200";
const KIS_FUND_QUOTE_PATH = Deno.env.get("KIS_FUND_QUOTE_PATH") ??
  "/uapi/etfetn/v1/quotations/inquire-price";
const KIS_FUND_QUOTE_TR_ID = Deno.env.get("KIS_FUND_QUOTE_TR_ID") ??
  "FHPST02400000";
const COINONE_TICKER_URL_TEMPLATE =
  Deno.env.get("COINONE_TICKER_URL_TEMPLATE") ??
    "https://api.coinone.co.kr/public/v2/ticker_utc_new/{quote}/{symbol}?additional_data=true";
const KIS_TOKEN_PROVIDER = "kis";

let kisAccessToken: string | null = null;
let kisAccessTokenExpiresAt: Date | null = null;

const jsonHeaders = { "Content-Type": "application/json" };

function isCashLikeHolding(row: HoldingRow) {
  const symbol = row.symbol.trim().toUpperCase();
  const currency = row.currency_code.trim().toUpperCase();
  return symbol.length > 0 && symbol === currency;
}

function isUsdHolding(row: HoldingRow) {
  return row.currency_code.trim().toUpperCase() === "USD";
}

function parseNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const normalized = value.replaceAll(",", "").trim();
    if (!normalized) return null;
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function nowIso() {
  return new Date().toISOString();
}

function hasMeaningfulPriceChange(
  previousPrice: number | null,
  nextPrice: number,
) {
  if (previousPrice == null) return true;
  return Math.abs(previousPrice - nextPrice) >= 0.000001;
}

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function isUsableToken(token: string | null, expiresAt: Date | null) {
  return !!token && !!expiresAt && Date.now() < expiresAt.getTime() - 60_000;
}

function isKisSuccess(json: Record<string, unknown>) {
  const rtCd = typeof json.rt_cd === "string" ? json.rt_cd.trim() : "";
  if (!rtCd) return true;
  return rtCd === "0" || rtCd === "0000";
}

function isKisAuthError(json: Record<string, unknown>) {
  const msgCd = typeof json.msg_cd === "string"
    ? json.msg_cd.toUpperCase()
    : "";
  const msg = typeof json.msg1 === "string" ? json.msg1.toLowerCase() : "";
  if (msgCd.startsWith("EGW")) return true;
  return msg.includes("token") ||
    msg.includes("auth") ||
    msg.includes("appkey") ||
    msg.includes("appsecret");
}

function kisOutput(json: Record<string, unknown>): Record<string, unknown> {
  return json.output && typeof json.output === "object"
    ? json.output as Record<string, unknown>
    : {};
}

async function loadStoredKisAccessToken(
  supabase: SupabaseClient<any>,
) {
  const { data, error } = await supabase
    .from("api_tokens")
    .select("access_token, expires_at")
    .eq("provider", KIS_TOKEN_PROVIDER)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to load stored KIS token: ${error.message}`);
  }

  if (!data?.access_token || !data?.expires_at) {
    return null;
  }

  const expiresAt = new Date(String(data.expires_at));
  if (!Number.isFinite(expiresAt.getTime())) {
    return null;
  }

  return {
    token: String(data.access_token),
    expiresAt,
  };
}

async function saveKisAccessToken(
  supabase: SupabaseClient<any>,
  token: string,
  expiresAt: Date,
) {
  const { error } = await supabase.from("api_tokens").upsert({
    provider: KIS_TOKEN_PROVIDER,
    access_token: token,
    expires_at: expiresAt.toISOString(),
    updated_at: nowIso(),
  }, {
    onConflict: "provider",
  });

  if (error) {
    throw new Error(`Failed to save KIS token: ${error.message}`);
  }
}

async function clearStoredKisAccessToken(
  supabase: SupabaseClient<any>,
) {
  kisAccessToken = null;
  kisAccessTokenExpiresAt = null;

  const { error } = await supabase
    .from("api_tokens")
    .delete()
    .eq("provider", KIS_TOKEN_PROVIDER);

  if (error) {
    throw new Error(`Failed to clear KIS token: ${error.message}`);
  }
}

async function issueKisAccessToken(supabase: SupabaseClient<any>) {
  requireEnv("KIS_APP_KEY", KIS_APP_KEY);
  requireEnv("KIS_APP_SECRET", KIS_APP_SECRET);

  if (isUsableToken(kisAccessToken, kisAccessTokenExpiresAt)) {
    return kisAccessToken;
  }

  const storedToken = await loadStoredKisAccessToken(supabase);
  if (storedToken && isUsableToken(storedToken.token, storedToken.expiresAt)) {
    kisAccessToken = storedToken.token;
    kisAccessTokenExpiresAt = storedToken.expiresAt;
    return storedToken.token;
  }

  const response = await fetch(`${KIS_BASE_URL}/oauth2/tokenP`, {
    method: "POST",
    headers: jsonHeaders,
    body: JSON.stringify({
      grant_type: "client_credentials",
      appkey: KIS_APP_KEY,
      appsecret: KIS_APP_SECRET,
    }),
  });

  if (!response.ok) {
    throw new Error(
      `KIS auth failed: ${response.status} ${await response.text()}`,
    );
  }

  const json = await response.json();
  const token = json["access_token"];
  if (typeof token !== "string" || !token) {
    throw new Error("KIS auth returned no access_token");
  }

  kisAccessToken = token;
  const expiresIn = parseNumber(json["expires_in"]);
  kisAccessTokenExpiresAt = expiresIn
    ? new Date(Date.now() + expiresIn * 1000)
    : new Date(Date.now() + 23 * 60 * 60 * 1000);
  await saveKisAccessToken(supabase, token, kisAccessTokenExpiresAt);

  return token;
}

async function kisGet(
  supabase: SupabaseClient<any>,
  path: string,
  trId: string,
  query: Record<string, string>,
  allowAuthRetry = true,
) {
  const token = await issueKisAccessToken(supabase);
  const url = new URL(`${KIS_BASE_URL}${path}`);
  for (const [key, value] of Object.entries(query)) {
    url.searchParams.set(key, value);
  }

  const response = await fetch(url, {
    headers: {
      "content-type": "application/json; charset=utf-8",
      "authorization": `Bearer ${token}`,
      "appkey": KIS_APP_KEY,
      "appsecret": KIS_APP_SECRET,
      "tr_id": trId,
      "custtype": "P",
    },
  });

  if (!response.ok) {
    if (
      allowAuthRetry && (response.status === 401 || response.status === 403)
    ) {
      await clearStoredKisAccessToken(supabase);
      return await kisGet(supabase, path, trId, query, false);
    }
    throw new Error(
      `KIS request failed: ${response.status} ${await response.text()}`,
    );
  }

  const json = await response.json() as Record<string, unknown>;
  if (!isKisSuccess(json)) {
    if (allowAuthRetry && isKisAuthError(json)) {
      await clearStoredKisAccessToken(supabase);
      return await kisGet(supabase, path, trId, query, false);
    }
    throw new Error(
      `KIS business failed: rt_cd=${String(json.rt_cd ?? "")} msg_cd=${
        String(json.msg_cd ?? "")
      } msg1=${String(json.msg1 ?? "")}`,
    );
  }

  return json;
}

async function fetchDomesticPrice(
  supabase: SupabaseClient<any>,
  row: HoldingRow,
) {
  const json = await kisGet(
    supabase,
    KIS_STOCK_QUOTE_PATH,
    KIS_STOCK_QUOTE_TR_ID,
    {
      FID_COND_MRKT_DIV_CODE: "J",
      FID_INPUT_ISCD: row.symbol,
    },
  );
  return parseNumber(kisOutput(json).stck_prpr);
}

async function fetchOverseasPrice(
  supabase: SupabaseClient<any>,
  row: HoldingRow,
) {
  const json = await kisGet(
    supabase,
    KIS_OVERSEAS_STOCK_QUOTE_PATH,
    KIS_OVERSEAS_STOCK_QUOTE_TR_ID,
    {
      AUTH: "",
      EXCD: row.exchange_code,
      SYMB: row.symbol,
    },
  );
  return parseNumber(kisOutput(json).last);
}

async function fetchFundPrice(
  supabase: SupabaseClient<any>,
  row: HoldingRow,
) {
  const json = await kisGet(
    supabase,
    KIS_FUND_QUOTE_PATH,
    KIS_FUND_QUOTE_TR_ID,
    {
      FID_COND_MRKT_DIV_CODE: "J",
      FID_INPUT_ISCD: row.symbol,
    },
  );
  return parseNumber(kisOutput(json).stck_prpr);
}

async function fetchCoinPrice(row: HoldingRow) {
  const url = COINONE_TICKER_URL_TEMPLATE
    .replaceAll("{symbol}", row.symbol.trim().toUpperCase())
    .replaceAll("{quote}", row.currency_code.trim().toUpperCase());

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(
      `Coinone request failed: ${response.status} ${await response.text()}`,
    );
  }

  const json = await response.json();
  const ticker = Array.isArray(json?.tickers) ? json.tickers[0] : null;
  return parseNumber(ticker?.last);
}

async function fetchCurrentPrice(
  supabase: SupabaseClient<any>,
  row: HoldingRow,
) {
  if (!row.symbol.trim() || row.hidden || isCashLikeHolding(row)) {
    return null;
  }

  if (row.asset_type === "코인") {
    return await fetchCoinPrice(row);
  }

  if (row.asset_type === "펀드") {
    return await fetchFundPrice(supabase, row);
  }

  if (isUsdHolding(row)) {
    if (!row.exchange_code.trim()) return null;
    return await fetchOverseasPrice(supabase, row);
  }

  return await fetchDomesticPrice(supabase, row);
}

function normalizeHoldingRow(row: Record<string, unknown>): HoldingRow {
  const asset = (row.assets ?? {}) as Record<string, unknown>;
  return {
    id: row.id as string | number,
    user_id: String(row.user_id ?? ""),
    asset_type: String(asset.asset_type ?? ""),
    symbol: String(row.symbol ?? ""),
    currency_code: String(row.currency_code ?? ""),
    exchange_code: String(row.exchange_code ?? ""),
    hidden: Boolean(row.hidden),
    deleted_at: row.deleted_at == null ? null : String(row.deleted_at),
    current_price: parseNumber(row.current_price),
  };
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const targetUserId = typeof body?.user_id === "string" && body.user_id
      ? body.user_id
      : null;

    let query = supabase
      .from("holdings")
      .select(
        "id, user_id, symbol, currency_code, exchange_code, hidden, deleted_at, current_price, assets!inner(asset_type)",
      )
      .is("deleted_at", null);

    if (targetUserId) {
      query = query.eq("user_id", targetUserId);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Failed to load holdings: ${error.message}`);
    }

    const holdings = (data ?? []).map((row) =>
      normalizeHoldingRow(row as Record<string, unknown>)
    );

    let updatedCount = 0;
    let skippedCount = 0;
    let recomputedAssetsCount = 0;
    const failures: Array<{ holding_id: string | number; error: string }> = [];

    for (const holding of holdings) {
      try {
        const price = await fetchCurrentPrice(supabase, holding);
        if (price == null) {
          skippedCount += 1;
          continue;
        }

        if (!hasMeaningfulPriceChange(holding.current_price, price)) {
          skippedCount += 1;
          continue;
        }

        const { error: updateError } = await supabase
          .from("holdings")
          .update({
            current_price: price,
            market_updated_at: nowIso(),
          })
          .eq("id", holding.id);

        if (updateError) {
          throw new Error(updateError.message);
        }

        updatedCount += 1;
      } catch (error) {
        failures.push({
          holding_id: holding.id,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    if (updatedCount > 0) {
      const { data: recomputeData, error: recomputeError } = await supabase.rpc(
        "recompute_asset_metrics",
        { target_user_id: targetUserId },
      );
      if (recomputeError) {
        failures.push({
          holding_id: "recompute_asset_metrics",
          error: recomputeError.message,
        });
      } else {
        const parsed = parseNumber(recomputeData);
        recomputedAssetsCount = parsed == null ? 0 : Math.trunc(parsed);
      }
    }

    const status = failures.length > 0 && updatedCount === 0 ? 500 : 200;

    return new Response(
      JSON.stringify({
        ok: failures.length === 0,
        processed_count: holdings.length,
        updated_count: updatedCount,
        skipped_count: skippedCount,
        recomputed_assets_count: recomputedAssetsCount,
        failures,
      }),
      {
        status,
        headers: jsonHeaders,
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: jsonHeaders,
      },
    );
  }
});
