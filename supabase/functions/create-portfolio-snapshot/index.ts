import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { authenticateUser } from "../_shared/auth.ts";

type AssetRow = {
  id: number;
  client_id: string;
  asset_type: string;
  title: string;
  alias: string;
  hidden: boolean;
  currency_code: string;
  value: string;
  user_id: string;
};

type HoldingRow = {
  id: number;
  client_id: string;
  asset_id: number;
  hidden: boolean;
  currency_code: string;
  name: string;
  symbol: string;
  quantity: number;
  average_price: number;
  current_price: number;
  note: string;
  user_id: string;
};

type CashAccountRow = {
  id: number;
  client_id: string;
  asset_id: number;
  hidden: boolean;
  currency_code: string;
  name: string;
  balance: number;
  note: string;
  user_id: string;
};

type SnapshotHoldingSummary = {
  assetId: number;
  assetClientId: string;
  assetTitle: string;
  holdingId: number | null;
  holdingClientId: string;
  holdingName: string;
  holdingSymbol: string;
  currencyCode: string;
  quantity: number;
  totalPurchaseAmount: number;
  totalValuationAmount: number;
  profitAmount: number;
  profitRate: number;
};

type SnapshotCashAccountSummary = {
  assetId: number;
  assetClientId: string;
  assetTitle: string;
  cashAccountId: number;
  cashAccountClientId: string;
  cashAccountName: string;
  currencyCode: string;
  balance: number;
  note: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const USD_KRW_RATE_URL = Deno.env.get("USD_KRW_RATE_URL") ??
  "https://m.search.naver.com/p/csearch/content/qapirender.nhn?key=calculator&pkid=141&q=%ED%99%98%EC%9C%A8&where=m&u1=keb&u6=standardUnit&u7=0&u3=USD&u4=KRW&u8=down&u2=1";
const jsonHeaders = { "Content-Type": "application/json" };

type SupabaseResponse<T> = {
  data: T;
  error: { message?: string } | null;
};

function logStep(message: string, details?: Record<string, unknown>) {
  if (details) {
    console.log(`[create-portfolio-snapshot] ${message}`, details);
    return;
  }
  console.log(`[create-portfolio-snapshot] ${message}`);
}

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function ensureSupabaseResponse<T>(
  response: SupabaseResponse<T> | undefined,
  context: string,
) {
  if (!response) {
    throw new Error(`Empty Supabase response: ${context}`);
  }
  return response;
}

function parseNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const normalized = value.replaceAll(",", "").trim();
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function parseDisplayAmount(text: string) {
  const normalized = text.replace(/[^0-9.\-]/g, "");
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function convertQuotedAmountToKrw(
  amount: number,
  currencyCode: string,
  snapshotExchangeRate: number,
) {
  return currencyCode.toUpperCase() === "USD"
    ? amount * snapshotExchangeRate
    : amount;
}

function normalizeDate(date: Date) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return kst.toISOString().slice(0, 10);
}

function defaultSnapshotDate() {
  const now = new Date();
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  kst.setUTCDate(kst.getUTCDate() - 1);
  return kst.toISOString().slice(0, 10);
}

async function loadLatestExchangeRateFromDb(supabase: SupabaseClient<any>) {
  const response = ensureSupabaseResponse(
    await supabase
      .from("exchange_rates")
      .select("rate")
      .eq("currency_pair", "USD/KRW")
      .order("recorded_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    "loadLatestExchangeRateFromDb",
  );
  const { data, error } = response;

  if (error) {
    throw new Error(`Failed to load exchange rate: ${error.message}`);
  }

  return parseNumber(data?.rate) || 1;
}

function extractUsdKrwRate(json: Record<string, unknown>): number | null {
  const country = json["country"];
  if (Array.isArray(country) && country.length >= 2) {
    const krw = country[1];
    if (krw && typeof krw === "object" && "value" in krw) {
      const rate = parseNumber((krw as Record<string, unknown>)["value"]);
      return rate > 0 ? rate : null;
    }
  }

  const rates = json["rates"];
  if (rates && typeof rates === "object" && "KRW" in rates) {
    const rate = parseNumber((rates as Record<string, unknown>)["KRW"]);
    return rate > 0 ? rate : null;
  }

  const conversionRates = json["conversion_rates"];
  if (
    conversionRates && typeof conversionRates === "object" &&
    "KRW" in conversionRates
  ) {
    const rate = parseNumber(
      (conversionRates as Record<string, unknown>)["KRW"],
    );
    return rate > 0 ? rate : null;
  }

  const quotes = json["quotes"];
  if (quotes && typeof quotes === "object" && "USDKRW" in quotes) {
    const rate = parseNumber((quotes as Record<string, unknown>)["USDKRW"]);
    return rate > 0 ? rate : null;
  }

  const result = json["result"];
  if (typeof result === "number" && Number.isFinite(result) && result > 0) {
    return result;
  }

  if (typeof result === "string") {
    const rate = parseNumber(result);
    return rate > 0 ? rate : null;
  }

  return null;
}

async function fetchLatestExchangeRate(supabase: SupabaseClient<any>) {
  if (!USD_KRW_RATE_URL.trim()) {
    return await loadLatestExchangeRateFromDb(supabase);
  }

  try {
    logStep("Fetching USD/KRW rate from API", { url: USD_KRW_RATE_URL });
    const response = await fetch(USD_KRW_RATE_URL, {
      headers: { Accept: "application/json" },
    });

    if (!response.ok) {
      throw new Error(
        `FX API failed: ${response.status} ${await response.text()}`,
      );
    }

    const json = await response.json();
    if (!json || typeof json !== "object" || Array.isArray(json)) {
      throw new Error("FX API returned non-object JSON");
    }

    const rate = extractUsdKrwRate(json as Record<string, unknown>);
    if (rate == null) {
      throw new Error("FX API response missing USD/KRW rate");
    }

    const saveResponse = ensureSupabaseResponse(
      await supabase.from("exchange_rates").insert({
        currency_pair: "USD/KRW",
        rate,
        recorded_at: new Date().toISOString(),
        source: "api",
      }),
      "fetchLatestExchangeRate.saveExchangeRate",
    );
    const { error: saveError } = saveResponse;

    if (saveError) {
      throw new Error(`Failed to save exchange rate: ${saveError.message}`);
    }

    logStep("Fetched USD/KRW rate from API", { rate });
    return rate;
  } catch (error) {
    logStep("Falling back to stored USD/KRW rate", {
      error: error instanceof Error ? error.message : String(error),
    });
    return await loadLatestExchangeRateFromDb(supabase);
  }
}

function resolveTargetUserIds(authUserId: string) {
  return [authUserId];
}

async function loadAssets(supabase: SupabaseClient<any>, userId: string) {
  const response = ensureSupabaseResponse(
    await supabase
      .from("assets")
      .select(
        "id, client_id, asset_type, title, alias, hidden, currency_code, value, user_id",
      )
      .eq("user_id", userId)
      .eq("hidden", false)
      .is("deleted_at", null)
      .order("sort_order", { ascending: true }),
    "loadAssets",
  );
  const { data, error } = response;

  if (error) {
    throw new Error(`Failed to load assets: ${error.message}`);
  }

  return (data ?? []).map((row) => ({
    id: Number(row.id),
    client_id: String(row.client_id ?? ""),
    asset_type: String(row.asset_type ?? ""),
    title: String(row.title ?? ""),
    alias: String(row.alias ?? ""),
    hidden: Boolean(row.hidden),
    currency_code: String(row.currency_code ?? "KRW"),
    value: String(row.value ?? "0"),
    user_id: String(row.user_id ?? ""),
  })) as AssetRow[];
}

async function loadHoldings(supabase: SupabaseClient<any>, userId: string) {
  const response = ensureSupabaseResponse(
    await supabase
      .from("holdings")
      .select(
        "id, client_id, asset_id, hidden, currency_code, name, symbol, quantity, average_price, current_price, note, user_id",
      )
      .eq("user_id", userId)
      .is("deleted_at", null)
      .order("sort_order", { ascending: true }),
    "loadHoldings",
  );
  const { data, error } = response;

  if (error) {
    throw new Error(`Failed to load holdings: ${error.message}`);
  }

  return (data ?? []).map((row) => ({
    id: Number(row.id),
    client_id: String(row.client_id ?? ""),
    asset_id: Number(row.asset_id),
    hidden: Boolean(row.hidden),
    currency_code: String(row.currency_code ?? "KRW"),
    name: String(row.name ?? ""),
    symbol: String(row.symbol ?? ""),
    quantity: parseNumber(row.quantity),
    average_price: parseNumber(row.average_price),
    current_price: parseNumber(row.current_price),
    note: String(row.note ?? ""),
    user_id: String(row.user_id ?? ""),
  })) as HoldingRow[];
}

async function loadCashAccounts(supabase: SupabaseClient<any>, userId: string) {
  const response = ensureSupabaseResponse(
    await supabase
      .from("cash_accounts")
      .select(
        "id, client_id, asset_id, hidden, currency_code, name, balance, note, user_id",
      )
      .eq("user_id", userId)
      .is("deleted_at", null)
      .order("sort_order", { ascending: true }),
    "loadCashAccounts",
  );
  const { data, error } = response;

  if (error) {
    throw new Error(`Failed to load cash accounts: ${error.message}`);
  }

  return (data ?? []).map((row) => ({
    id: Number(row.id),
    client_id: String(row.client_id ?? ""),
    asset_id: Number(row.asset_id),
    hidden: Boolean(row.hidden),
    currency_code: String(row.currency_code ?? "KRW"),
    name: String(row.name ?? ""),
    balance: parseNumber(row.balance),
    note: String(row.note ?? ""),
    user_id: String(row.user_id ?? ""),
  })) as CashAccountRow[];
}

function buildHoldingSummary(
  holding: HoldingRow,
  asset: AssetRow,
  assetTitle: string,
  snapshotExchangeRate: number,
): SnapshotHoldingSummary {
  // USD holdings store average_price in KRW and current_price in USD.
  // Snapshot profit must therefore convert only the current valuation side.
  const purchaseAmount = holding.quantity * holding.average_price;
  const valuationAmount = convertQuotedAmountToKrw(
    holding.quantity * holding.current_price,
    holding.currency_code,
    snapshotExchangeRate,
  );
  const profitAmount = valuationAmount - purchaseAmount;
  const profitRate = purchaseAmount === 0
    ? 0
    : (profitAmount / purchaseAmount) * 100;

  return {
    assetId: holding.asset_id,
    assetClientId: asset.client_id,
    assetTitle,
    holdingId: holding.id,
    holdingClientId: holding.client_id,
    holdingName: holding.name,
    holdingSymbol: holding.symbol,
    currencyCode: holding.currency_code,
    quantity: holding.quantity,
    totalPurchaseAmount: purchaseAmount,
    totalValuationAmount: valuationAmount,
    profitAmount,
    profitRate,
  };
}

function buildCashAccountSummary(
  account: CashAccountRow,
  asset: AssetRow,
  assetTitle: string,
): SnapshotCashAccountSummary {
  return {
    assetId: account.asset_id,
    assetClientId: asset.client_id,
    assetTitle,
    cashAccountId: account.id,
    cashAccountClientId: account.client_id,
    cashAccountName: account.name,
    currencyCode: account.currency_code,
    balance: account.balance,
    note: account.note,
  };
}

async function deleteExistingSnapshot(
  supabase: SupabaseClient<any>,
  userId: string,
  snapshotDate: string,
) {
  const existingResponse = ensureSupabaseResponse(
    await supabase
      .from("daily_portfolio_snapshots")
      .select("id")
      .eq("user_id", userId)
      .eq("snapshot_date", snapshotDate),
    "deleteExistingSnapshot.loadExisting",
  );
  const { data: existing, error: existingError } = existingResponse;

  if (existingError) {
    throw new Error(
      `Failed to load existing snapshots: ${existingError.message}`,
    );
  }

  const snapshotIds = (existing ?? []).map((row) => Number(row.id)).filter(
    Number.isFinite,
  );
  if (snapshotIds.length === 0) return;

  const childTables = [
    "daily_portfolio_snapshot_cash_accounts",
    "daily_portfolio_snapshot_holding_items",
    "daily_portfolio_snapshot_items",
  ] as const;

  for (const table of childTables) {
    const deleteResponse = ensureSupabaseResponse(
      await supabase.from(table).delete().in("snapshot_id", snapshotIds),
      `deleteExistingSnapshot.${table}`,
    );
    const { error } = deleteResponse;
    if (error) {
      throw new Error(`Failed to delete ${table}: ${error.message}`);
    }
  }

  const snapshotDeleteResponse = ensureSupabaseResponse(
    await supabase
      .from("daily_portfolio_snapshots")
      .delete()
      .in("id", snapshotIds),
    "deleteExistingSnapshot.snapshots",
  );
  const { error: snapshotDeleteError } = snapshotDeleteResponse;

  if (snapshotDeleteError) {
    throw new Error(
      `Failed to delete snapshots: ${snapshotDeleteError.message}`,
    );
  }
}

async function createSnapshotForUser(
  supabase: SupabaseClient<any>,
  userId: string,
  snapshotDate: string,
  usdKrwRate: number,
) {
  const [assets, holdings, cashAccounts] = await Promise.all([
    loadAssets(supabase, userId),
    loadHoldings(supabase, userId),
    loadCashAccounts(supabase, userId),
  ]);

  if (assets.length === 0) {
    return {
      user_id: userId,
      snapshot_date: snapshotDate,
      created: false,
      reason: "no_assets",
    };
  }

  await deleteExistingSnapshot(supabase, userId, snapshotDate);

  const holdingsByAssetId = new Map<number, HoldingRow[]>();
  for (const holding of holdings) {
    const list = holdingsByAssetId.get(holding.asset_id) ?? [];
    list.push(holding);
    holdingsByAssetId.set(holding.asset_id, list);
  }

  const cashAccountsByAssetId = new Map<number, CashAccountRow[]>();
  for (const account of cashAccounts) {
    const list = cashAccountsByAssetId.get(account.asset_id) ?? [];
    list.push(account);
    cashAccountsByAssetId.set(account.asset_id, list);
  }

  const assetSummaries = assets.map((asset) => {
    const assetTitle = asset.alias.trim() ? asset.alias : asset.title;
    const allAssetHoldings = holdingsByAssetId.get(asset.id) ?? [];
    const allAssetCashAccounts = cashAccountsByAssetId.get(asset.id) ?? [];
    const assetHoldingSummaries = allAssetHoldings
      .filter((holding) => !holding.hidden && holding.quantity > 0)
      .map((holding) =>
        buildHoldingSummary(holding, asset, assetTitle, usdKrwRate)
      );
    const assetCashAccountSummaries = allAssetCashAccounts
      .filter((account) => !account.hidden)
      .map((account) => buildCashAccountSummary(account, asset, assetTitle));

    let purchaseAmount = 0;
    let valuationAmount = 0;
    const hasAnyChildRows = allAssetHoldings.length > 0 ||
      allAssetCashAccounts.length > 0;

    if (
      assetHoldingSummaries.length > 0 || assetCashAccountSummaries.length > 0
    ) {
      purchaseAmount += assetHoldingSummaries.reduce(
        (sum, item) => sum + item.totalPurchaseAmount,
        0,
      );
      valuationAmount += assetHoldingSummaries.reduce(
        (sum, item) => sum + item.totalValuationAmount,
        0,
      );

      for (const account of assetCashAccountSummaries) {
        const accountValue = convertQuotedAmountToKrw(
          account.balance,
          account.currencyCode,
          usdKrwRate,
        );
        purchaseAmount += accountValue;
        valuationAmount += accountValue;
      }
    } else if (hasAnyChildRows) {
      purchaseAmount = 0;
      valuationAmount = 0;
    } else {
      const fallbackValue = parseDisplayAmount(asset.value);
      purchaseAmount = fallbackValue;
      valuationAmount = fallbackValue;
    }

    const profitAmount = valuationAmount - purchaseAmount;
    const profitRate = purchaseAmount === 0
      ? 0
      : (profitAmount / purchaseAmount) * 100;

    return {
      asset,
      assetTitle,
      holdingCount: assetHoldingSummaries.length +
        assetCashAccountSummaries.length,
      purchaseAmount,
      valuationAmount,
      profitAmount,
      profitRate,
      holdingItems: assetHoldingSummaries,
      cashAccountItems: assetCashAccountSummaries,
    };
  });

  const totalPurchaseAmount = assetSummaries.reduce(
    (sum, item) => sum + item.purchaseAmount,
    0,
  );
  const totalValuationAmount = assetSummaries.reduce(
    (sum, item) => sum + item.valuationAmount,
    0,
  );
  const totalProfitAmount = totalValuationAmount - totalPurchaseAmount;
  const totalProfitRate = totalPurchaseAmount === 0
    ? 0
    : (totalProfitAmount / totalPurchaseAmount) * 100;

  const snapshotInsertResponse = ensureSupabaseResponse(
    await supabase
      .from("daily_portfolio_snapshots")
      .insert({
        snapshot_date: snapshotDate,
        total_purchase_amount: totalPurchaseAmount,
        total_valuation_amount: totalValuationAmount,
        profit_amount: totalProfitAmount,
        profit_rate: totalProfitRate,
        exchange_rate: usdKrwRate,
        created_at: new Date().toISOString(),
        user_id: userId,
      })
      .select("id")
      .single(),
    "createSnapshotForUser.insertSnapshot",
  );
  const { data: snapshotInsert, error: snapshotInsertError } =
    snapshotInsertResponse;

  if (snapshotInsertError) {
    throw new Error(
      `Failed to insert snapshot: ${snapshotInsertError.message}`,
    );
  }
  if (!snapshotInsert) {
    throw new Error("Failed to insert snapshot: empty response");
  }

  const snapshotId = Number(snapshotInsert.id);

  const snapshotItems = assetSummaries.map((summary) => ({
    snapshot_id: snapshotId,
    asset_id: summary.asset.id,
    asset_client_id: summary.asset.client_id,
    asset_title: summary.assetTitle,
    total_purchase_amount: summary.purchaseAmount,
    total_valuation_amount: summary.valuationAmount,
    profit_amount: summary.profitAmount,
    profit_rate: summary.profitRate,
    holding_count: summary.holdingCount,
    user_id: userId,
  }));

  if (snapshotItems.length > 0) {
    const snapshotItemsResponse = ensureSupabaseResponse(
      await supabase.from("daily_portfolio_snapshot_items").insert(
        snapshotItems,
      ),
      "createSnapshotForUser.insertSnapshotItems",
    );
    const { error } = snapshotItemsResponse;
    if (error) {
      throw new Error(`Failed to insert snapshot items: ${error.message}`);
    }
  }

  const holdingItems = assetSummaries.flatMap((summary) =>
    summary.holdingItems.map((holding) => ({
      snapshot_id: snapshotId,
      asset_id: holding.assetId,
      asset_client_id: holding.assetClientId,
      asset_title: holding.assetTitle,
      holding_id: holding.holdingId,
      holding_client_id: holding.holdingClientId,
      holding_name: holding.holdingName,
      holding_symbol: holding.holdingSymbol,
      currency_code: holding.currencyCode,
      quantity: holding.quantity,
      total_purchase_amount: holding.totalPurchaseAmount,
      total_valuation_amount: holding.totalValuationAmount,
      profit_amount: holding.profitAmount,
      profit_rate: holding.profitRate,
      user_id: userId,
    }))
  );

  if (holdingItems.length > 0) {
    const holdingItemsResponse = ensureSupabaseResponse(
      await supabase
        .from("daily_portfolio_snapshot_holding_items")
        .insert(holdingItems),
      "createSnapshotForUser.insertHoldingItems",
    );
    const { error } = holdingItemsResponse;
    if (error) {
      throw new Error(
        `Failed to insert snapshot holding items: ${error.message}`,
      );
    }
  }

  const cashAccountItems = assetSummaries.flatMap((summary) =>
    summary.cashAccountItems.map((account) => ({
      snapshot_id: snapshotId,
      asset_id: account.assetId,
      asset_client_id: account.assetClientId,
      asset_title: account.assetTitle,
      cash_account_id: account.cashAccountId,
      cash_account_client_id: account.cashAccountClientId,
      cash_account_name: account.cashAccountName,
      currency_code: account.currencyCode,
      balance: account.balance,
      note: account.note,
      user_id: userId,
    }))
  );

  if (cashAccountItems.length > 0) {
    const cashAccountItemsResponse = ensureSupabaseResponse(
      await supabase
        .from("daily_portfolio_snapshot_cash_accounts")
        .insert(cashAccountItems),
      "createSnapshotForUser.insertCashAccountItems",
    );
    const { error } = cashAccountItemsResponse;
    if (error) {
      throw new Error(
        `Failed to insert snapshot cash accounts: ${error.message}`,
      );
    }
  }

  return {
    user_id: userId,
    snapshot_date: snapshotDate,
    created: true,
    snapshot_id: snapshotId,
    asset_count: assets.length,
    holding_item_count: holdingItems.length,
    cash_account_count: cashAccountItems.length,
    total_purchase_amount: totalPurchaseAmount,
    total_valuation_amount: totalValuationAmount,
    exchange_rate: usdKrwRate,
  };
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
    const targetUserId =
      typeof body?.user_id === "string" && body.user_id.trim()
        ? body.user_id.trim()
        : null;
    const snapshotDate =
      typeof body?.snapshot_date === "string" && body.snapshot_date.trim()
        ? body.snapshot_date.trim()
        : defaultSnapshotDate();

    logStep("Request received", {
      method: req.method,
      snapshot_date: snapshotDate,
      target_user_id: targetUserId,
      auth_user_id: auth.userId,
    });

    if (targetUserId && targetUserId !== auth.userId) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Forbidden",
          step: "user_scope",
        }),
        { status: 403, headers: jsonHeaders },
      );
    }

    const userIds = resolveTargetUserIds(auth.userId);
    const usdKrwRate = await fetchLatestExchangeRate(supabase);

    logStep("Resolved snapshot targets", {
      user_count: userIds.length,
      usd_krw_rate: usdKrwRate,
    });

    const results = [];
    for (const userId of userIds) {
      logStep("Creating snapshot", {
        user_id: userId,
        snapshot_date: snapshotDate,
      });
      results.push(
        await createSnapshotForUser(supabase, userId, snapshotDate, usdKrwRate),
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        snapshot_date: snapshotDate,
        processed_user_count: userIds.length,
        results,
      }),
      {
        status: 200,
        headers: jsonHeaders,
      },
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
      {
        status: 500,
        headers: jsonHeaders,
      },
    );
  }
});
