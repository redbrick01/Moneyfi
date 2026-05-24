import { createClient } from "npm:@supabase/supabase-js@2";
import { authenticateUser } from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const jsonHeaders = { "Content-Type": "application/json" };

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function logStep(message: string, details?: Record<string, unknown>) {
  if (details) {
    console.log(`[get-portfolio-snapshots] ${message}`, details);
    return;
  }
  console.log(`[get-portfolio-snapshots] ${message}`);
}

function parseNumber(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_ANON_KEY", SUPABASE_ANON_KEY);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);

    const auth = await authenticateUser(
      req.headers.get("Authorization"),
      SUPABASE_URL,
      SUPABASE_ANON_KEY,
    );
    const url = new URL(req.url);
    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};

    if (!auth.userId) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Unauthorized",
          step: "auth_verify",
          reason: auth.reason,
        }),
        {
          status: auth.reason === "missing_auth_env" ? 500 : 401,
          headers: jsonHeaders,
        },
      );
    }

    const requestedUserId =
      (typeof body?.user_id === "string" && body.user_id.trim()
        ? body.user_id.trim()
        : null) ??
        (url.searchParams.get("user_id")?.trim() || null);

    if (requestedUserId && requestedUserId !== auth.userId) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Forbidden",
          step: "user_scope",
        }),
        { status: 403, headers: jsonHeaders },
      );
    }

    const targetUserId = auth.userId;

    const limitParam = typeof body?.limit === "number"
      ? body.limit
      : Number(url.searchParams.get("limit") ?? body?.limit ?? 0);
    const limit = Number.isFinite(limitParam) && limitParam > 0
      ? Math.min(Math.trunc(limitParam), 365)
      : null;

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    logStep("Loading snapshots", {
      user_id: targetUserId,
      limit,
    });

    let snapshotQuery = supabase
      .from("daily_portfolio_snapshots")
      .select(
        "id, snapshot_date, total_purchase_amount, total_valuation_amount, profit_amount, profit_rate, exchange_rate, created_at, user_id",
      )
      .eq("user_id", targetUserId)
      .order("snapshot_date", { ascending: true });

    if (limit != null) {
      snapshotQuery = snapshotQuery.limit(limit);
    }

    const { data: snapshots, error: snapshotError } = await snapshotQuery;
    if (snapshotError) {
      throw new Error(`Failed to load snapshots: ${snapshotError.message}`);
    }

    const snapshotRows = snapshots ?? [];
    const snapshotIds = snapshotRows.map((row) => Number(row.id)).filter(
      Number.isFinite,
    );
    const snapshotDates = snapshotRows.map((row) =>
      String(row.snapshot_date ?? "")
    );

    if (snapshotIds.length === 0) {
      return new Response(
        JSON.stringify({
          ok: true,
          user_id: targetUserId,
          snapshot_count: 0,
          snapshots: [],
        }),
        { status: 200, headers: jsonHeaders },
      );
    }

    const [itemsResult, holdingItemsResult, cashAccountsResult, notesResult] =
      await Promise.all([
        supabase
          .from("daily_portfolio_snapshot_items")
          .select(
            "id, snapshot_id, asset_id, asset_client_id, asset_title, total_purchase_amount, total_valuation_amount, profit_amount, profit_rate, holding_count, user_id",
          )
          .eq("user_id", targetUserId)
          .in("snapshot_id", snapshotIds)
          .order("snapshot_id", { ascending: true })
          .order("asset_title", { ascending: true }),
        supabase
          .from("daily_portfolio_snapshot_holding_items")
          .select(
            "id, snapshot_id, asset_id, asset_client_id, asset_title, holding_id, holding_client_id, holding_name, holding_symbol, currency_code, quantity, total_purchase_amount, total_valuation_amount, profit_amount, profit_rate, user_id",
          )
          .eq("user_id", targetUserId)
          .in("snapshot_id", snapshotIds)
          .order("snapshot_id", { ascending: true })
          .order("asset_title", { ascending: true })
          .order("holding_name", { ascending: true }),
        supabase
          .from("daily_portfolio_snapshot_cash_accounts")
          .select(
            "id, snapshot_id, asset_id, asset_client_id, asset_title, cash_account_id, cash_account_client_id, cash_account_name, currency_code, balance, note, user_id",
          )
          .eq("user_id", targetUserId)
          .in("snapshot_id", snapshotIds)
          .order("snapshot_id", { ascending: true })
          .order("asset_title", { ascending: true })
          .order("cash_account_name", { ascending: true }),
        supabase
          .from("snapshot_notes")
          .select("snapshot_date, note, user_id, created_at, updated_at")
          .eq("user_id", targetUserId)
          .in("snapshot_date", snapshotDates),
      ]);

    if (itemsResult.error) {
      throw new Error(
        `Failed to load snapshot items: ${itemsResult.error.message}`,
      );
    }
    if (holdingItemsResult.error) {
      throw new Error(
        `Failed to load snapshot holding items: ${holdingItemsResult.error.message}`,
      );
    }
    if (cashAccountsResult.error) {
      throw new Error(
        `Failed to load snapshot cash accounts: ${cashAccountsResult.error.message}`,
      );
    }
    if (notesResult.error) {
      throw new Error(
        `Failed to load snapshot notes: ${notesResult.error.message}`,
      );
    }

    const itemsBySnapshotId = new Map<number, Array<Record<string, unknown>>>();
    for (const row of itemsResult.data ?? []) {
      const snapshotId = Number(row.snapshot_id);
      const list = itemsBySnapshotId.get(snapshotId) ?? [];
      list.push({
        id: Number(row.id),
        snapshot_id: snapshotId,
        asset_id: row.asset_id == null ? null : Number(row.asset_id),
        asset_client_id: row.asset_client_id == null
          ? null
          : String(row.asset_client_id),
        asset_title: String(row.asset_title ?? ""),
        total_purchase_amount: parseNumber(row.total_purchase_amount),
        total_valuation_amount: parseNumber(row.total_valuation_amount),
        profit_amount: parseNumber(row.profit_amount),
        profit_rate: parseNumber(row.profit_rate),
        holding_count: Number(row.holding_count ?? 0),
      });
      itemsBySnapshotId.set(snapshotId, list);
    }

    const holdingItemsBySnapshotId = new Map<
      number,
      Array<Record<string, unknown>>
    >();
    for (const row of holdingItemsResult.data ?? []) {
      const snapshotId = Number(row.snapshot_id);
      const list = holdingItemsBySnapshotId.get(snapshotId) ?? [];
      list.push({
        id: Number(row.id),
        snapshot_id: snapshotId,
        asset_id: row.asset_id == null ? null : Number(row.asset_id),
        asset_client_id: row.asset_client_id == null
          ? null
          : String(row.asset_client_id),
        asset_title: String(row.asset_title ?? ""),
        holding_id: row.holding_id == null ? null : Number(row.holding_id),
        holding_client_id: row.holding_client_id == null
          ? null
          : String(row.holding_client_id),
        holding_name: String(row.holding_name ?? ""),
        holding_symbol: String(row.holding_symbol ?? ""),
        currency_code: String(row.currency_code ?? "KRW"),
        quantity: parseNumber(row.quantity),
        total_purchase_amount: parseNumber(row.total_purchase_amount),
        total_valuation_amount: parseNumber(row.total_valuation_amount),
        profit_amount: parseNumber(row.profit_amount),
        profit_rate: parseNumber(row.profit_rate),
      });
      holdingItemsBySnapshotId.set(snapshotId, list);
    }

    const cashAccountsBySnapshotId = new Map<
      number,
      Array<Record<string, unknown>>
    >();
    for (const row of cashAccountsResult.data ?? []) {
      const snapshotId = Number(row.snapshot_id);
      const list = cashAccountsBySnapshotId.get(snapshotId) ?? [];
      list.push({
        id: Number(row.id),
        snapshot_id: snapshotId,
        asset_id: row.asset_id == null ? null : Number(row.asset_id),
        asset_client_id: row.asset_client_id == null
          ? null
          : String(row.asset_client_id),
        asset_title: String(row.asset_title ?? ""),
        cash_account_id: row.cash_account_id == null
          ? null
          : Number(row.cash_account_id),
        cash_account_client_id: row.cash_account_client_id == null
          ? null
          : String(row.cash_account_client_id),
        cash_account_name: String(row.cash_account_name ?? ""),
        currency_code: String(row.currency_code ?? "KRW"),
        balance: parseNumber(row.balance),
        note: String(row.note ?? ""),
      });
      cashAccountsBySnapshotId.set(snapshotId, list);
    }

    const notesByDate = new Map<string, Record<string, unknown>>();
    for (const row of notesResult.data ?? []) {
      const snapshotDate = String(row.snapshot_date ?? "");
      notesByDate.set(snapshotDate, {
        snapshot_date: snapshotDate,
        note: String(row.note ?? ""),
        created_at: row.created_at == null ? null : String(row.created_at),
        updated_at: row.updated_at == null ? null : String(row.updated_at),
      });
    }

    const responseSnapshots = snapshotRows.map((row) => {
      const snapshotId = Number(row.id);
      const snapshotDate = String(row.snapshot_date ?? "");
      return {
        id: snapshotId,
        snapshot_date: snapshotDate,
        total_purchase_amount: parseNumber(row.total_purchase_amount),
        total_valuation_amount: parseNumber(row.total_valuation_amount),
        profit_amount: parseNumber(row.profit_amount),
        profit_rate: parseNumber(row.profit_rate),
        exchange_rate: parseNumber(row.exchange_rate),
        created_at: row.created_at == null ? null : String(row.created_at),
        note: notesByDate.get(snapshotDate)?.note ?? "",
        items: itemsBySnapshotId.get(snapshotId) ?? [],
        holding_items: holdingItemsBySnapshotId.get(snapshotId) ?? [],
        cash_accounts: cashAccountsBySnapshotId.get(snapshotId) ?? [],
      };
    });

    logStep("Loaded snapshots", {
      user_id: targetUserId,
      snapshot_count: responseSnapshots.length,
    });

    return new Response(
      JSON.stringify({
        ok: true,
        user_id: targetUserId,
        snapshot_count: responseSnapshots.length,
        snapshots: responseSnapshots,
      }),
      { status: 200, headers: jsonHeaders },
    );
  } catch (error) {
    logStep("Request failed", {
      error: error instanceof Error ? error.message : String(error),
    });

    return new Response(
      JSON.stringify({
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
