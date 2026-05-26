import { createHash, randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";

const DEFAULT_EMAIL = "moneyfy.test@example.com";

const email = process.env.MONEYFY_TEST_EMAIL ?? DEFAULT_EMAIL;
const password = process.env.MONEYFY_TEST_PASSWORD;

if (!password) {
  throw new Error("MONEYFY_TEST_PASSWORD environment variable is required");
}

function clientId(label) {
  const hex = createHash("sha256").update(`moneyfy-test:${label}`).digest("hex");
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    `4${hex.slice(13, 16)}`,
    `8${hex.slice(17, 20)}`,
    hex.slice(20, 32),
  ].join("-");
}

function nowIso() {
  return new Date().toISOString();
}

async function loadConfig() {
  const candidates = ["assets/config.json", "config.json"];
  for (const path of candidates) {
    try {
      const raw = await readFile(path, "utf8");
      const json = JSON.parse(raw);
      const supabaseUrl = String(json.SUPABASE_URL ?? "").trim();
      const supabaseAnonKey = String(json.SUPABASE_ANON_KEY ?? "").trim();
      if (supabaseUrl && supabaseAnonKey) {
        return { supabaseUrl, supabaseAnonKey };
      }
    } catch {
      // Try the next conventional config location.
    }
  }
  throw new Error("Supabase config not found in assets/config.json or config.json");
}

async function requestJson(url, options) {
  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
  const data = await response.json().catch(() => ({}));
  return { response, data };
}

async function signInOrSignUp({ supabaseUrl, supabaseAnonKey }) {
  const authHeaders = {
    apikey: supabaseAnonKey,
    Authorization: `Bearer ${supabaseAnonKey}`,
  };

  const signIn = await requestJson(
    `${supabaseUrl}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify({ email, password }),
    },
  );
  if (signIn.response.ok && signIn.data.access_token) {
    return {
      accessToken: signIn.data.access_token,
      userId: signIn.data.user?.id ?? null,
      mode: "signed_in_existing",
    };
  }

  const signUp = await requestJson(`${supabaseUrl}/auth/v1/signup`, {
    method: "POST",
    headers: authHeaders,
    body: JSON.stringify({
      email,
      password,
      data: { name: "MONEYFY 테스트 계정" },
    }),
  });
  if (!signUp.response.ok) {
    throw new Error(
      `sign up failed (${signUp.response.status}): ${JSON.stringify(signUp.data)}`,
    );
  }
  if (!signUp.data.access_token) {
    throw new Error(
      "sign up succeeded but no session was returned. Email confirmation may be enabled for this Supabase project.",
    );
  }

  return {
    accessToken: signUp.data.access_token,
    userId: signUp.data.user?.id ?? null,
    mode: "created_new",
  };
}

function assetRow({ id, assetType, title, order, holdingCount }) {
  const total = 1_000_000 + holdingCount * 100_000;
  return {
    client_id: clientId(`asset-${id}`),
    last_modified_at: nowIso(),
    asset_type: assetType,
    title,
    alias: title,
    currency_code: "KRW",
    value: String(total),
    change: "+0.0%",
    icon_code_point: 0xe8e5,
    quantity_label: "항목",
    quantity_value: `${holdingCount}개`,
    average_label: "수익률",
    average_value: "+0.0%",
    note: "테스트 계정 seed 데이터",
    sort_order: order,
  };
}

function holdingRow({ assetId, index, name, symbol, order }) {
  return {
    client_id: clientId(`holding-${index}`),
    asset_client_id: clientId(`asset-${assetId}`),
    last_modified_at: nowIso(),
    currency_code: "KRW",
    market_updated_at: nowIso(),
    exchange_code: "",
    name,
    symbol,
    quantity: 1,
    average_price: 100_000,
    current_price: 100_000,
    note: "평가액 100,000원 테스트 종목",
    sort_order: order,
  };
}

function cashAccountRow({ assetId, name, order }) {
  return {
    client_id: clientId(`cash-${assetId}`),
    asset_client_id: clientId(`asset-${assetId}`),
    last_modified_at: nowIso(),
    currency_code: "KRW",
    name,
    base_balance: 1_000_000,
    balance: 1_000_000,
    note: "테스트 현금 계좌",
    sort_order: order,
  };
}

function openingEvent({ id, title, order }) {
  return {
    client_id: clientId(`event-${id}`),
    last_modified_at: nowIso(),
    occurred_at: "2026.05.26",
    kind: "opening_balance",
    title,
    memo: "테스트 seed 원장",
    source: "ledger",
    flow_category: "internal",
    sort_order: order,
  };
}

function holdingOpeningLine({ index, assetId, eventId }) {
  return {
    client_id: clientId(`line-holding-${index}`),
    event_client_id: clientId(`event-${eventId}`),
    asset_client_id: clientId(`asset-${assetId}`),
    holding_client_id: clientId(`holding-${index}`),
    last_modified_at: nowIso(),
    action: "opening_quantity",
    currency_code: "KRW",
    quantity_delta: 1,
    cash_delta: 0,
    unit_price: 100_000,
    gross_amount: 100_000,
    fee_amount: 0,
    tax_amount: 0,
    cost_basis_delta: 100_000,
    realized_pnl: 0,
    fx_rate: 1,
    sort_order: 0,
  };
}

function buildPayload() {
  const seedAssets = [
    { id: "stocks", assetType: "주식", title: "테스트 주식", holdingCount: 4 },
    { id: "funds", assetType: "ETF/펀드", title: "테스트 ETF/펀드", holdingCount: 3 },
    { id: "coins", assetType: "코인", title: "테스트 코인", holdingCount: 3 },
  ];
  const seedHoldings = [
    ["stocks", "삼성전자", "005930"],
    ["stocks", "현대차", "005380"],
    ["stocks", "NAVER", "035420"],
    ["stocks", "카카오", "035720"],
    ["funds", "KODEX 200", "069500"],
    ["funds", "TIGER 미국S&P500", "360750"],
    ["funds", "ACE 미국나스닥100", "367380"],
    ["coins", "Bitcoin", "BTC"],
    ["coins", "Ethereum", "ETH"],
    ["coins", "Solana", "SOL"],
  ];

  const assets = seedAssets.map((asset, index) =>
    assetRow({ ...asset, order: index })
  );
  const holdings = seedHoldings.map(([assetId, name, symbol], index) =>
    holdingRow({ assetId, index: index + 1, name, symbol, order: index })
  );
  const cash_accounts = seedAssets.map((asset, index) =>
    cashAccountRow({
      assetId: asset.id,
      name: `${asset.title} 현금`,
      order: index,
    })
  );
  const transaction_events = holdings.map((holding, index) =>
    openingEvent({
      id: `holding-${index + 1}`,
      title: `${holding.name} 초기 보유`,
      order: index,
    })
  );
  const transaction_lines = seedHoldings.map(([assetId], index) =>
    holdingOpeningLine({
      index: index + 1,
      assetId,
      eventId: `holding-${index + 1}`,
    })
  );

  return {
    payload_version: 4,
    schema_mode: "ledger_only_delta",
    client_request_id: randomUUID(),
    assets,
    holdings,
    cash_accounts,
    transaction_events,
    transaction_lines,
  };
}

async function syncPayload({ supabaseUrl, supabaseAnonKey, accessToken, payload }) {
  return requestJson(`${supabaseUrl}/functions/v1/sync-local-db`, {
    method: "POST",
    headers: {
      apikey: supabaseAnonKey,
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify(payload),
  });
}

async function main() {
  const config = await loadConfig();
  const auth = await signInOrSignUp(config);
  const payload = buildPayload();
  const sync = await syncPayload({
    ...config,
    accessToken: auth.accessToken,
    payload,
  });
  if (!sync.response.ok || sync.data.ok === false) {
    throw new Error(
      `sync failed (${sync.response.status}): ${JSON.stringify(sync.data)}`,
    );
  }

  console.log(JSON.stringify({
    ok: true,
    email,
    auth_mode: auth.mode,
    user_id: auth.userId,
    sync_counts: sync.data.counts,
    conflict_count: sync.data.conflict_count,
    relation_failures: sync.data.relation_failures,
  }, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
