import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function decodeJwtSub(authHeader: string | null) {
  try {
    if (!authHeader) {
      return { userId: null, reason: "missing_auth_header" };
    }

    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    const parts = token.split(".");
    if (parts.length < 2) {
      return { userId: null, reason: "invalid_jwt_parts" };
    }

    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(
      base64.length + (4 - (base64.length % 4)) % 4,
      "=",
    );
    const payload = JSON.parse(atob(padded));

    return {
      userId: typeof payload.sub === "string" ? payload.sub : null,
      reason: typeof payload.sub === "string" ? "ok" : "missing_sub",
    };
  } catch (error) {
    return {
      userId: null,
      reason: `decode_failed:${
        error instanceof Error ? error.message : String(error)
      }`,
    };
  }
}

function parseNumber(value: unknown, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

type SyncTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";

async function ensureClientIds(
  supabase: SupabaseClient<any>,
  table: SyncTable,
  userId: string,
) {
  const { data, error } = await supabase
    .from(table)
    .select("id, client_id")
    .eq("user_id", userId);

  if (error) {
    throw new Error(`${table} client_id preload failed: ${error.message}`);
  }

  for (const row of data ?? []) {
    const currentClientId = typeof row.client_id === "string"
      ? row.client_id.trim()
      : "";
    if (currentClientId.length > 0) continue;

    const id = parseNumber(row.id, -1);
    if (id < 0) continue;
    const nextClientId = crypto.randomUUID();
    const { error: updateError } = await supabase
      .from(table)
      .update({ client_id: nextClientId })
      .eq("user_id", userId)
      .eq("id", id);
    if (updateError) {
      throw new Error(
        `${table} client_id backfill failed: ${updateError.message}`,
      );
    }
  }
}

Deno.serve(async (req) => {
  try {
    const decoded = decodeJwtSub(req.headers.get("Authorization"));
    if (!decoded.userId) {
      return jsonResponse(
        {
          ok: false,
          step: "jwt_decode",
          reason: decoded.reason,
        },
        401,
      );
    }

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return jsonResponse(
        {
          ok: false,
          step: "env_check",
          supabase_url_exists: !!SUPABASE_URL,
          service_role_exists: !!SUPABASE_SERVICE_ROLE_KEY,
        },
        500,
      );
    }

    const userId = decoded.userId;
    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    await Promise.all([
      ensureClientIds(supabase, "assets", userId),
      ensureClientIds(supabase, "holdings", userId),
      ensureClientIds(supabase, "cash_accounts", userId),
      ensureClientIds(supabase, "transaction_events", userId),
      ensureClientIds(supabase, "transaction_lines", userId),
    ]);

    const [
      assetsResult,
      holdingsResult,
      cashAccountsResult,
      transactionEventsResult,
      transactionLinesResult,
    ] = await Promise.all([
      supabase
        .from("assets")
        .select(
          "id, client_id, asset_type, title, alias, hidden, currency_code, value, change, icon_code_point, quantity_label, quantity_value, average_label, average_value, note, sort_order",
        )
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
      supabase
        .from("holdings")
        .select(
          "id, client_id, asset_id, hidden, currency_code, market_updated_at, exchange_code, name, symbol, quantity, average_price, current_price, note, sort_order",
        )
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
      supabase
        .from("cash_accounts")
        .select(
          "id, client_id, asset_id, hidden, currency_code, name, base_balance, balance, note, sort_order",
        )
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
      supabase
        .from("transaction_events")
        .select(
          "id, client_id, occurred_at, kind, title, memo, source, legacy_source_table, legacy_source_id, sort_order",
        )
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("occurred_at", { ascending: true })
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
      supabase
        .from("transaction_lines")
        .select(
          "id, client_id, event_id, asset_id, holding_id, cash_account_id, legacy_source_table, legacy_source_id, action, currency_code, quantity_delta, cash_delta, unit_price, gross_amount, fee_amount, tax_amount, cost_basis_delta, realized_pnl, fx_rate, sort_order",
        )
        .eq("user_id", userId)
        .is("deleted_at", null)
        .order("event_id", { ascending: true })
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
    ]);

    if (assetsResult.error) {
      throw new Error(`assets load failed: ${assetsResult.error.message}`);
    }
    if (holdingsResult.error) {
      throw new Error(`holdings load failed: ${holdingsResult.error.message}`);
    }
    if (cashAccountsResult.error) {
      throw new Error(
        `cash_accounts load failed: ${cashAccountsResult.error.message}`,
      );
    }
    if (transactionEventsResult.error) {
      throw new Error(
        `transaction_events load failed: ${transactionEventsResult.error.message}`,
      );
    }
    if (transactionLinesResult.error) {
      throw new Error(
        `transaction_lines load failed: ${transactionLinesResult.error.message}`,
      );
    }

    const assetRows = (assetsResult.data ?? []).map((row) => ({
      client_id: typeof row.client_id === "string" ? row.client_id : "",
      asset_type: String(row.asset_type ?? "주식"),
      title: String(row.title ?? ""),
      alias: String(row.alias ?? ""),
      hidden: Boolean(row.hidden),
      currency_code: String(row.currency_code ?? "KRW"),
      value: String(row.value ?? ""),
      change: String(row.change ?? ""),
      icon_code_point: parseNumber(row.icon_code_point),
      quantity_label: String(row.quantity_label ?? ""),
      quantity_value: String(row.quantity_value ?? ""),
      average_label: String(row.average_label ?? ""),
      average_value: String(row.average_value ?? ""),
      note: String(row.note ?? ""),
      sort_order: parseNumber(row.sort_order),
    }));

    const assetClientByServerId = new Map<number, string>();
    for (const [index, row] of (assetsResult.data ?? []).entries()) {
      const id = parseNumber(row.id, -1);
      const clientId = assetRows[index]?.client_id;
      if (id >= 0 && clientId) {
        assetClientByServerId.set(id, clientId);
      }
    }

    const holdingRows = (holdingsResult.data ?? []).map((row) => ({
      client_id: typeof row.client_id === "string" ? row.client_id : "",
      asset_client_id:
        assetClientByServerId.get(parseNumber(row.asset_id, -1)) ?? null,
      hidden: Boolean(row.hidden),
      currency_code: String(row.currency_code ?? "KRW"),
      market_updated_at: row.market_updated_at == null
        ? null
        : String(row.market_updated_at),
      exchange_code: String(row.exchange_code ?? ""),
      name: String(row.name ?? ""),
      symbol: String(row.symbol ?? ""),
      quantity: parseNumber(row.quantity),
      average_price: parseNumber(row.average_price),
      current_price: parseNumber(row.current_price),
      note: String(row.note ?? ""),
      sort_order: parseNumber(row.sort_order),
    }));

    const holdingClientByServerId = new Map<number, string>();
    for (const [index, row] of (holdingsResult.data ?? []).entries()) {
      const id = parseNumber(row.id, -1);
      const clientId = holdingRows[index]?.client_id;
      if (id >= 0 && clientId) {
        holdingClientByServerId.set(id, clientId);
      }
    }

    const cashAccountRows = (cashAccountsResult.data ?? []).map((row) => ({
      client_id: typeof row.client_id === "string" ? row.client_id : "",
      asset_client_id:
        assetClientByServerId.get(parseNumber(row.asset_id, -1)) ?? null,
      hidden: Boolean(row.hidden),
      currency_code: String(row.currency_code ?? "KRW"),
      name: String(row.name ?? ""),
      base_balance: parseNumber(row.base_balance),
      balance: parseNumber(row.balance),
      note: String(row.note ?? ""),
      sort_order: parseNumber(row.sort_order),
    }));

    const cashAccountClientByServerId = new Map<number, string>();
    for (const [index, row] of (cashAccountsResult.data ?? []).entries()) {
      const id = parseNumber(row.id, -1);
      const clientId = cashAccountRows[index]?.client_id;
      if (id >= 0 && clientId) {
        cashAccountClientByServerId.set(id, clientId);
      }
    }

    const transactionEventRows = (transactionEventsResult.data ?? []).map((
      row,
    ) => ({
      client_id: typeof row.client_id === "string" ? row.client_id : "",
      occurred_at: String(row.occurred_at ?? ""),
      kind: String(row.kind ?? ""),
      title: String(row.title ?? ""),
      memo: String(row.memo ?? ""),
      source: String(row.source ?? "manual"),
      legacy_source_table: row.legacy_source_table == null
        ? null
        : String(row.legacy_source_table),
      legacy_source_id: row.legacy_source_id == null
        ? null
        : parseNumber(row.legacy_source_id),
      sort_order: parseNumber(row.sort_order),
    }));

    const transactionEventClientByServerId = new Map<number, string>();
    for (const [index, row] of (transactionEventsResult.data ?? []).entries()) {
      const id = parseNumber(row.id, -1);
      const clientId = transactionEventRows[index]?.client_id;
      if (id >= 0 && clientId) {
        transactionEventClientByServerId.set(id, clientId);
      }
    }

    const transactionLineRows = (transactionLinesResult.data ?? []).map((
      row,
    ) => ({
      client_id: typeof row.client_id === "string" ? row.client_id : "",
      event_client_id:
        transactionEventClientByServerId.get(parseNumber(row.event_id, -1)) ??
          null,
      asset_client_id:
        assetClientByServerId.get(parseNumber(row.asset_id, -1)) ?? null,
      holding_client_id:
        holdingClientByServerId.get(parseNumber(row.holding_id, -1)) ?? null,
      cash_account_client_id:
        cashAccountClientByServerId.get(parseNumber(row.cash_account_id, -1)) ??
          null,
      legacy_source_table: row.legacy_source_table == null
        ? null
        : String(row.legacy_source_table),
      legacy_source_id: row.legacy_source_id == null
        ? null
        : parseNumber(row.legacy_source_id),
      action: String(row.action ?? ""),
      currency_code: String(row.currency_code ?? "KRW"),
      quantity_delta: parseNumber(row.quantity_delta),
      cash_delta: parseNumber(row.cash_delta),
      unit_price: parseNumber(row.unit_price),
      gross_amount: parseNumber(row.gross_amount),
      fee_amount: parseNumber(row.fee_amount),
      tax_amount: parseNumber(row.tax_amount),
      cost_basis_delta: parseNumber(row.cost_basis_delta),
      realized_pnl: parseNumber(row.realized_pnl),
      fx_rate: row.fx_rate == null ? null : parseNumber(row.fx_rate),
      sort_order: parseNumber(row.sort_order),
    }));

    return jsonResponse({
      ok: true,
      payload_version: 4,
      schema_mode: "ledger_only_delta",
      user_id: userId,
      assets: assetRows,
      holdings: holdingRows,
      cash_accounts: cashAccountRows,
      transaction_events: transactionEventRows,
      transaction_lines: transactionLineRows,
    });
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        step: "catch",
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
