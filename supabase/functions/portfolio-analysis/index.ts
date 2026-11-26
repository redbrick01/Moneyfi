import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type Json = Record<string, unknown>;

function jsonResponse(payload: Json, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing ${name}`);
  }
  return value;
}

function requireBearerToken(request: Request): Response | null {
  const expectedToken = requireEnv("PORTFOLIO_FUNCTION_TOKEN");
  const authorization = request.headers.get("Authorization") ?? "";
  if (authorization !== `Bearer ${expectedToken}`) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  return null;
}

function toNumber(value: unknown, fallback = 0): number {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function deriveScoreAndRisk(summary: Json): { score: number; risk_level: string } {
  const total = toNumber(summary.total_valuation_krw, 1) || 1;
  const topPositions = Array.isArray(summary.top_positions) ? summary.top_positions : [];
  const firstPosition = topPositions[0] as Json | undefined;
  const topWeight = firstPosition ? (toNumber(firstPosition.valuation_krw) / total) * 100 : 0;
  const bySector = summary.by_sector as Record<string, number> | undefined;
  const byCurrency = summary.by_currency as Record<string, number> | undefined;
  const maxSectorWeight = Math.max(0, ...Object.values(bySector ?? {}).map((value) => toNumber(value))) / total * 100;
  const maxCurrencyWeight = Math.max(0, ...Object.values(byCurrency ?? {}).map((value) => toNumber(value))) / total * 100;

  let penalty = 0;
  if (topWeight > 40) penalty += 20;
  else if (topWeight > 25) penalty += 10;
  if (maxSectorWeight > 70) penalty += 20;
  else if (maxSectorWeight > 50) penalty += 10;
  if (maxCurrencyWeight > 90) penalty += 10;
  if (toNumber(summary.position_count) < 5) penalty += 15;
  else if (toNumber(summary.position_count) < 10) penalty += 5;

  const score = Math.max(0, Math.min(100, 85 - penalty));
  const risk_level = score >= 75 ? "??쓬" : score >= 55 ? "蹂댄넻" : "?믪쓬";
  return { score, risk_level };
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const unauthorized = requireBearerToken(request);
    if (unauthorized) return unauthorized;

    const supabase = createClient(
      requireEnv("SUPABASE_URL"),
      requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false } },
    );
    const url = new URL(request.url);
    const action = url.searchParams.get("action");

    if (request.method === "GET" && action === "list-users") {
      const { data, error } = await supabase
        .from("daily_portfolio_snapshots")
        .select("user_id,snapshot_date,total_valuation_amount,profit_rate")
        .order("user_id", { ascending: true })
        .order("snapshot_date", { ascending: false })
        .limit(1000);
      if (error) throw error;

      const latestByUser = new Map<string, Json>();
      for (const row of data ?? []) {
        const userId = String(row.user_id);
        if (!latestByUser.has(userId)) latestByUser.set(userId, { ...row, user_id: userId });
      }
      const users = [...latestByUser.values()].sort((left, right) => toNumber(right.total_valuation_amount) - toNumber(left.total_valuation_amount));
      return jsonResponse({ users });
    }

    if (request.method === "GET" && action === "portfolio") {
      let userId = url.searchParams.get("user_id");
      if (!userId) {
        const listResponse = await supabase
          .from("daily_portfolio_snapshots")
          .select("user_id,snapshot_date,total_valuation_amount")
          .order("user_id", { ascending: true })
          .order("snapshot_date", { ascending: false })
          .limit(1000);
        if (listResponse.error) throw listResponse.error;
        const latestByUser = new Map<string, Json>();
        for (const row of listResponse.data ?? []) {
          const rowUserId = String(row.user_id);
          if (!latestByUser.has(rowUserId)) latestByUser.set(rowUserId, row);
        }
        const firstUser = [...latestByUser.values()].sort((left, right) => toNumber(right.total_valuation_amount) - toNumber(left.total_valuation_amount))[0];
        userId = firstUser?.user_id ? String(firstUser.user_id) : null;
      }
      if (!userId) return jsonResponse({ error: "No portfolio users found" }, 404);

      const snapshotResponse = await supabase
        .from("daily_portfolio_snapshots")
        .select("id,user_id,snapshot_date,total_purchase_amount,total_valuation_amount,profit_amount,profit_rate")
        .eq("user_id", userId)
        .order("snapshot_date", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (snapshotResponse.error) throw snapshotResponse.error;
      if (!snapshotResponse.data) return jsonResponse({ error: "No snapshot found" }, 404);

      const itemsResponse = await supabase
        .from("daily_portfolio_snapshot_holding_items")
        .select("asset_id,asset_title,holding_id,holding_symbol,holding_name,currency_code,quantity,total_purchase_amount,total_valuation_amount,profit_amount,profit_rate")
        .eq("snapshot_id", snapshotResponse.data.id)
        .neq("quantity", 0)
        .order("total_valuation_amount", { ascending: false });
      if (itemsResponse.error) throw itemsResponse.error;

      const holdingIds = [...new Set((itemsResponse.data ?? []).map((row) => row.holding_id).filter(Boolean))];
      const currentPrices = new Map<string, unknown>();
      if (holdingIds.length > 0) {
        const holdingsResponse = await supabase.from("holdings").select("id,current_price").in("id", holdingIds);
        if (holdingsResponse.error) throw holdingsResponse.error;
        for (const row of holdingsResponse.data ?? []) currentPrices.set(String(row.id), row.current_price);
      }

      const { id: _snapshotId, ...snapshot } = snapshotResponse.data;
      const holdings = (itemsResponse.data ?? []).map((row) => ({
        asset_id: row.asset_id,
        asset_title: row.asset_title,
        holding_symbol: row.holding_symbol,
        holding_name: row.holding_name,
        currency_code: row.currency_code,
        quantity: row.quantity,
        total_purchase_amount: row.total_purchase_amount,
        total_valuation_amount: row.total_valuation_amount,
        profit_amount: row.profit_amount,
        profit_rate: row.profit_rate,
        current_price: currentPrices.get(String(row.holding_id)) ?? null,
      }));

      const cashAccountsResponse = await supabase
        .from("daily_portfolio_snapshot_cash_accounts")
        .select("asset_id,asset_title,cash_account_id,cash_account_name,currency_code,balance,note")
        .eq("snapshot_id", snapshotResponse.data.id)
        .neq("balance", 0)
        .order("balance", { ascending: false });
      if (cashAccountsResponse.error) throw cashAccountsResponse.error;

      const cashCurrencies = [...new Set((cashAccountsResponse.data ?? []).map((row) => String(row.currency_code ?? "KRW")).filter((currency) => currency !== "KRW"))];
      const exchangeRates = new Map<string, number>();
      for (const currency of cashCurrencies) {
        const rateResponse = await supabase
          .from("exchange_rates")
          .select("rate")
          .eq("currency_pair", `${currency}/KRW`)
          .order("recorded_at", { ascending: false })
          .limit(1)
          .maybeSingle();
        if (rateResponse.error) throw rateResponse.error;
        exchangeRates.set(currency, toNumber(rateResponse.data?.rate, 1));
      }
      const cash_accounts = (cashAccountsResponse.data ?? []).map((row) => {
        const currency = String(row.currency_code ?? "KRW");
        const rate = currency === "KRW" ? 1 : exchangeRates.get(currency) ?? 1;
        return { ...row, exchange_rate_to_krw: rate, balance_krw: toNumber(row.balance) * rate };
      });

      const eventsResponse = await supabase
        .from("transaction_events")
        .select("id,occurred_at,kind,title,memo,flow_category")
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("occurred_at", { ascending: false })
        .order("id", { ascending: false })
        .limit(50);
      if (eventsResponse.error) throw eventsResponse.error;

      const eventIds = (eventsResponse.data ?? []).map((row) => row.id);
      let lineRows: Json[] = [];
      if (eventIds.length > 0) {
        const linesResponse = await supabase
          .from("transaction_lines")
          .select("event_id,asset_id,holding_id,action,currency_code,quantity_delta,cash_delta,unit_price,gross_amount,fee_amount,tax_amount,realized_pnl,cost_basis_delta")
          .in("event_id", eventIds)
          .is("deleted_at", null)
          .order("sort_order", { ascending: true })
          .order("id", { ascending: true });
        if (linesResponse.error) throw linesResponse.error;
        lineRows = linesResponse.data ?? [];
      }

      const transactionHoldingIds = [...new Set(lineRows.map((row) => row.holding_id).filter(Boolean))];
      const transactionAssetIds = [...new Set(lineRows.map((row) => row.asset_id).filter(Boolean))];
      const holdingNames = new Map<string, Json>();
      const assetNames = new Map<string, Json>();

      if (transactionHoldingIds.length > 0) {
        const holdingMetaResponse = await supabase.from("holdings").select("id,symbol,name").in("id", transactionHoldingIds);
        if (holdingMetaResponse.error) throw holdingMetaResponse.error;
        for (const row of holdingMetaResponse.data ?? []) holdingNames.set(String(row.id), row);
      }
      if (transactionAssetIds.length > 0) {
        const assetMetaResponse = await supabase.from("assets").select("id,title").in("id", transactionAssetIds);
        if (assetMetaResponse.error) throw assetMetaResponse.error;
        for (const row of assetMetaResponse.data ?? []) assetNames.set(String(row.id), row);
      }

      const linesByEvent = new Map<string, Json[]>();
      for (const row of lineRows) {
        const eventId = String(row.event_id);
        const holdingMeta = row.holding_id ? holdingNames.get(String(row.holding_id)) : null;
        const assetMeta = row.asset_id ? assetNames.get(String(row.asset_id)) : null;
        const enrichedLine = { ...row, holding_symbol: holdingMeta?.symbol ?? null, holding_name: holdingMeta?.name ?? null, asset_title: assetMeta?.title ?? null };
        linesByEvent.set(eventId, [...(linesByEvent.get(eventId) ?? []), enrichedLine]);
      }
      const transactions = (eventsResponse.data ?? []).map((event) => ({ ...event, lines: linesByEvent.get(String(event.id)) ?? [] }));

      return jsonResponse({ snapshot, holdings, cash_accounts, transactions });
    }

    if (request.method === "POST" && action === "save-diagnosis") {
      const body = await request.json();
      const summary = (body.summary ?? {}) as Json;
      const positions = Array.isArray(body.positions) ? body.positions : [];
      const { score, risk_level } = deriveScoreAndRisk({ ...summary, top_positions: positions });
      const diagnosisJson = { ai_analysis: String(body.ai_analysis ?? ""), score, risk_level, generated_by: "portfolio_analysis.py" };
      const { error } = await supabase.from("portfolio_diagnosis_history").insert({
        user_id: body.user_id,
        model: body.model,
        analysis_source: "openai_model",
        used_fallback: false,
        score,
        risk_level,
        summary: String(body.ai_analysis ?? "").slice(0, 2000),
        normalized_portfolio: { summary, positions },
        diagnosis_json: diagnosisJson,
      });
      if (error) throw error;
      return jsonResponse({ ok: true });
    }

    return jsonResponse({ error: "Unsupported action" }, 400);
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});
