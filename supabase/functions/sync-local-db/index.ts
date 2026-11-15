import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.110.7";
import { authenticateUser } from "../_shared/auth.ts";

type JsonRow = Record<string, unknown>;

type RelationFailure = {
  table: string;
  client_id: string | null;
  reason: string;
};

type FxExchangeDiagnostic = {
  event_client_id: string | null;
  line_client_ids: Array<string | null>;
  reasons: string[];
};

type ConflictRow = {
  table: string;
  client_id: string;
  reason: "server_newer";
  client_last_modified_at: string | null;
  server_last_modified_at: string | null;
};

type UpsertResult = {
  acceptedClientIds: string[];
  conflicts: ConflictRow[];
};

type PreserveSummary = {
  table: "holdings";
  client_id: string;
  fields: string[];
};

type SyncTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";
type AcceptedSyncKey = SyncTable | "snapshot_notes";
type MappedTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function asRows(value: unknown): JsonRow[] {
  if (!Array.isArray(value)) return [];
  return value.filter((row): row is JsonRow =>
    !!row && typeof row === "object"
  );
}

function asClientId(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function asTimestamp(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  const millis = Date.parse(trimmed);
  return Number.isFinite(millis) ? new Date(millis).toISOString() : null;
}

function asFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function shouldPreservePositiveServerValue(
  incoming: unknown,
  current: unknown,
): boolean {
  const currentNumber = asFiniteNumber(current);
  if (currentNumber == null || currentNumber <= 0) return false;
  const incomingNumber = asFiniteNumber(incoming);
  return incoming == null || incomingNumber == null || incomingNumber <= 0;
}

function isActiveRow(row: JsonRow): boolean {
  return row["deleted_at"] == null;
}

function validateFxExchangePayload(
  eventRows: JsonRow[],
  lineRows: JsonRow[],
): FxExchangeDiagnostic[] {
  const activeLines = lineRows.filter(isActiveRow);
  const diagnostics: FxExchangeDiagnostic[] = [];

  for (
    const event of eventRows.filter((row) =>
      isActiveRow(row) && row["kind"] === "fx_exchange"
    )
  ) {
    const eventClientId = asClientId(event["client_id"]);
    const matchingLines = eventClientId == null
      ? []
      : activeLines.filter((line) =>
        asClientId(line["event_client_id"]) === eventClientId
      );
    const reasons: string[] = [];

    if (eventClientId == null) {
      reasons.push("event_client_id_empty");
    }
    if (matchingLines.length !== 2) {
      reasons.push(`active_line_count:${matchingLines.length}`);
    }

    for (const [index, line] of matchingLines.entries()) {
      if (asClientId(line["client_id"]) == null) {
        reasons.push(`line_client_id_empty:${index}`);
      }
      if (asClientId(line["event_client_id"]) == null) {
        reasons.push(`line_event_client_id_empty:${index}`);
      }
      if (asClientId(line["asset_client_id"]) == null) {
        reasons.push(`line_asset_client_id_empty:${index}`);
      }
      if (asClientId(line["cash_account_client_id"]) == null) {
        reasons.push(`line_cash_account_client_id_empty:${index}`);
      }
    }

    const outLines = matchingLines.filter((line) =>
      line["action"] === "fx_out"
    );
    const inLines = matchingLines.filter((line) =>
      line["action"] === "fx_in"
    );
    if (outLines.length !== 1 || inLines.length !== 1) {
      reasons.push("actions_must_be_fx_out_and_fx_in");
    }

    const outLine = outLines[0];
    const inLine = inLines[0];
    if (outLine && inLine) {
      const outCurrency = outLine["currency_code"];
      const inCurrency = inLine["currency_code"];
      const currenciesAreOppositePair =
        (outCurrency === "KRW" && inCurrency === "USD") ||
        (outCurrency === "USD" && inCurrency === "KRW");
      if (!currenciesAreOppositePair) {
        reasons.push("currencies_must_be_krw_usd_pair");
      }

      const outDelta = asFiniteNumber(outLine["cash_delta"]);
      const inDelta = asFiniteNumber(inLine["cash_delta"]);
      if (outDelta == null || outDelta >= 0) {
        reasons.push("fx_out_cash_delta_must_be_negative");
      }
      if (inDelta == null || inDelta <= 0) {
        reasons.push("fx_in_cash_delta_must_be_positive");
      }

      const outRate = asFiniteNumber(outLine["fx_rate"]);
      const inRate = asFiniteNumber(inLine["fx_rate"]);
      if (
        outRate == null || inRate == null || outRate <= 0 || inRate <= 0 ||
        outRate !== inRate
      ) {
        reasons.push("fx_rate_must_match_and_be_positive");
      } else if (outDelta != null && inDelta != null && outDelta < 0) {
        const sourceAmount = Math.abs(outDelta);
        const expectedTargetAmount = outCurrency === "KRW"
          ? sourceAmount / outRate
          : sourceAmount * outRate;
        const tolerance = Math.max(
          0.00000001,
          Math.abs(expectedTargetAmount) * 0.000000001,
        );
        if (Math.abs(inDelta - expectedTargetAmount) > tolerance) {
          reasons.push("fx_in_cash_delta_must_match_conversion");
        }
      }
    }

    if (reasons.length > 0) {
      diagnostics.push({
        event_client_id: eventClientId,
        line_client_ids: matchingLines.map((line) =>
          asClientId(line["client_id"])
        ),
        reasons,
      });
    }
  }

  return diagnostics;
}

function compareTimestamps(
  incoming: string | null,
  current: string | null,
): number {
  if (!incoming && !current) return 0;
  if (incoming && !current) return 1;
  if (!incoming && current) return -1;
  const incomingMillis = Date.parse(incoming ?? "");
  const currentMillis = Date.parse(current ?? "");
  if (!Number.isFinite(incomingMillis) && !Number.isFinite(currentMillis)) {
    return 0;
  }
  if (Number.isFinite(incomingMillis) && !Number.isFinite(currentMillis)) {
    return 1;
  }
  if (!Number.isFinite(incomingMillis) && Number.isFinite(currentMillis)) {
    return -1;
  }
  return incomingMillis - currentMillis;
}

function attachUserId(rows: JsonRow[], userId: string): JsonRow[] {
  return rows.map((row) => ({
    ...row,
    user_id: userId,
    last_modified_at: asTimestamp(row["last_modified_at"]) ??
      new Date().toISOString(),
  }));
}

function pickColumns(row: JsonRow, allowed: string[]): JsonRow {
  const picked: JsonRow = {};
  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(row, key)) {
      picked[key] = row[key];
    }
  }
  return picked;
}

function compactClientIds(rows: JsonRow[]): string[] {
  const unique = new Set<string>();
  for (const row of rows) {
    const clientId = asClientId(row["client_id"]);
    if (clientId) {
      unique.add(clientId);
    }
  }
  return [...unique];
}

function collectReferencedClientIds(rows: JsonRow[], key: string): string[] {
  const unique = new Set<string>();
  for (const row of rows) {
    const clientId = asClientId(row[key]);
    if (clientId) {
      unique.add(clientId);
    }
  }
  return [...unique];
}

async function loadIdMap(
  adminClient: SupabaseClient,
  table: MappedTable,
  userId: string,
  clientIds: string[],
): Promise<Map<string, number>> {
  if (clientIds.length === 0) {
    return new Map<string, number>();
  }

  const { data, error } = await adminClient
    .from(table)
    .select("id, client_id")
    .eq("user_id", userId)
    .in("client_id", clientIds);

  if (error) {
    throw new Error(`Failed to load ${table} id map: ${error.message}`);
  }

  const map = new Map<string, number>();
  for (const row of data ?? []) {
    const clientId = asClientId(row.client_id);
    const rawId = row.id;
    const id = typeof rawId === "number" ? rawId : Number(rawId);
    if (clientId && Number.isFinite(id)) {
      map.set(clientId, id);
    }
  }
  return map;
}

async function preserveUsdHoldingCurrencyBasis(
  adminClient: SupabaseClient,
  rows: JsonRow[],
  userId: string,
): Promise<{ rows: JsonRow[]; preserved: PreserveSummary[] }> {
  const clientIds = compactClientIds(rows);
  if (clientIds.length === 0) {
    return { rows, preserved: [] };
  }

  const { data, error } = await adminClient
    .from("holdings")
    .select(
      "client_id, currency_code, average_price_source, average_price_krw, average_purchase_fx_rate, cost_basis_krw",
    )
    .eq("user_id", userId)
    .in("client_id", clientIds);

  if (error) {
    throw new Error(
      `holdings currency-basis preload failed: ${error.message}`,
    );
  }

  const currentByClientId = new Map<string, JsonRow>();
  for (const row of data ?? []) {
    const clientId = asClientId(row.client_id);
    if (!clientId) continue;
    currentByClientId.set(clientId, row as JsonRow);
  }

  const preserved: PreserveSummary[] = [];
  const mergedRows = rows.map((row) => {
    const clientId = asClientId(row["client_id"]);
    if (!clientId) return row;
    const current = currentByClientId.get(clientId);
    if (!current) return row;
    const incomingCurrency = String(row["currency_code"] ?? "");
    const currentCurrency = String(current["currency_code"] ?? "");
    if (incomingCurrency !== "USD" && currentCurrency !== "USD") return row;

    const merged = { ...row };
    const fields: string[] = [];
    for (
      const field of [
        "average_price_source",
        "average_price_krw",
        "average_purchase_fx_rate",
        "cost_basis_krw",
      ]
    ) {
      if (shouldPreservePositiveServerValue(merged[field], current[field])) {
        merged[field] = current[field];
        fields.push(field);
      }
    }

    if (fields.length > 0) {
      preserved.push({
        table: "holdings",
        client_id: clientId,
        fields,
      });
    }
    return merged;
  });

  return { rows: mergedRows, preserved };
}

async function validatePayloadRelationsBeforeMutation(
  adminClient: SupabaseClient,
  userId: string,
  assetRows: JsonRow[],
  holdingRows: JsonRow[],
  cashAccountRows: JsonRow[],
  transactionEventRows: JsonRow[],
  transactionLineRows: JsonRow[],
): Promise<RelationFailure[]> {
  const failures: RelationFailure[] = [];

  async function availableClientIds(
    table: MappedTable,
    incomingRows: JsonRow[],
    referencedClientIds: string[],
  ): Promise<Set<string>> {
    const incomingClientIds = compactClientIds(incomingRows);
    const requestedClientIds = [
      ...new Set([...incomingClientIds, ...referencedClientIds]),
    ];
    const existing = await loadIdMap(
      adminClient,
      table,
      userId,
      requestedClientIds,
    );
    return new Set([...incomingClientIds, ...existing.keys()]);
  }

  const referencedAssetClientIds = [
    ...collectReferencedClientIds(holdingRows, "asset_client_id"),
    ...collectReferencedClientIds(cashAccountRows, "asset_client_id"),
    ...collectReferencedClientIds(transactionLineRows, "asset_client_id"),
  ];
  const availableAssets = await availableClientIds(
    "assets",
    assetRows,
    referencedAssetClientIds,
  );
  for (const row of [...holdingRows, ...cashAccountRows]) {
    const assetClientId = asClientId(row["asset_client_id"]);
    if (assetClientId == null || !availableAssets.has(assetClientId)) {
      failures.push({
        table: holdingRows.includes(row) ? "holdings" : "cash_accounts",
        client_id: asClientId(row["client_id"]),
        reason: `missing_asset:${assetClientId ?? "null"}`,
      });
    }
  }

  const availableHoldings = await availableClientIds(
    "holdings",
    holdingRows,
    collectReferencedClientIds(transactionLineRows, "holding_client_id"),
  );
  const availableCashAccounts = await availableClientIds(
    "cash_accounts",
    cashAccountRows,
    collectReferencedClientIds(transactionLineRows, "cash_account_client_id"),
  );
  const availableEvents = await availableClientIds(
    "transaction_events",
    transactionEventRows,
    collectReferencedClientIds(transactionLineRows, "event_client_id"),
  );

  for (const row of transactionLineRows) {
    const clientId = asClientId(row["client_id"]);
    const eventClientId = asClientId(row["event_client_id"]);
    const assetClientId = asClientId(row["asset_client_id"]);
    const holdingClientId = asClientId(row["holding_client_id"]);
    const cashAccountClientId = asClientId(row["cash_account_client_id"]);
    if (eventClientId == null || !availableEvents.has(eventClientId)) {
      failures.push({
        table: "transaction_lines",
        client_id: clientId,
        reason: `missing_event:${eventClientId ?? "null"}`,
      });
    }
    if (assetClientId != null && !availableAssets.has(assetClientId)) {
      failures.push({
        table: "transaction_lines",
        client_id: clientId,
        reason: `missing_asset:${assetClientId}`,
      });
    }
    if (holdingClientId != null && !availableHoldings.has(holdingClientId)) {
      failures.push({
        table: "transaction_lines",
        client_id: clientId,
        reason: `missing_holding:${holdingClientId}`,
      });
    }
    if (
      cashAccountClientId != null &&
      !availableCashAccounts.has(cashAccountClientId)
    ) {
      failures.push({
        table: "transaction_lines",
        client_id: clientId,
        reason: `missing_cash_account:${cashAccountClientId}`,
      });
    }
  }

  return failures;
}

async function validateFxExchangeAccountMetadata(
  adminClient: SupabaseClient,
  userId: string,
  cashAccountRows: JsonRow[],
  transactionEventRows: JsonRow[],
  transactionLineRows: JsonRow[],
): Promise<FxExchangeDiagnostic[]> {
  const fxEventClientIds = new Set(
    transactionEventRows
      .filter((row) => isActiveRow(row) && row["kind"] === "fx_exchange")
      .map((row) => asClientId(row["client_id"]))
      .filter((value): value is string => value != null),
  );
  const fxLines = transactionLineRows.filter((row) => {
    const eventClientId = asClientId(row["event_client_id"]);
    return isActiveRow(row) && eventClientId != null &&
      fxEventClientIds.has(eventClientId);
  });
  const referencedCashAccountClientIds = collectReferencedClientIds(
    fxLines,
    "cash_account_client_id",
  );
  if (referencedCashAccountClientIds.length === 0) return [];

  type CashMetadata = { currencyCode: string; assetKey: string };
  const metadataByClientId = new Map<string, CashMetadata>();
  for (const row of cashAccountRows) {
    const clientId = asClientId(row["client_id"]);
    const assetClientId = asClientId(row["asset_client_id"]);
    const currencyCode = String(row["currency_code"] ?? "").toUpperCase();
    if (clientId && assetClientId && currencyCode) {
      metadataByClientId.set(clientId, {
        currencyCode,
        assetKey: `client:${assetClientId}`,
      });
    }
  }

  const missingClientIds = referencedCashAccountClientIds.filter((clientId) =>
    !metadataByClientId.has(clientId)
  );
  if (missingClientIds.length > 0) {
    const { data: cashData, error: cashError } = await adminClient
      .from("cash_accounts")
      .select("client_id, currency_code, asset_id")
      .eq("user_id", userId)
      .in("client_id", missingClientIds);
    if (cashError) {
      throw new Error(
        `cash account metadata preload failed: ${cashError.message}`,
      );
    }
    const assetIds = [
      ...new Set(
        (cashData ?? [])
          .map((row) => Number(row.asset_id))
          .filter((id) => Number.isFinite(id)),
      ),
    ];
    const assetClientIdById = new Map<number, string>();
    if (assetIds.length > 0) {
      const { data: assetData, error: assetError } = await adminClient
        .from("assets")
        .select("id, client_id")
        .eq("user_id", userId)
        .in("id", assetIds);
      if (assetError) {
        throw new Error(`asset metadata preload failed: ${assetError.message}`);
      }
      for (const row of assetData ?? []) {
        const id = Number(row.id);
        const clientId = asClientId(row.client_id);
        if (Number.isFinite(id) && clientId) {
          assetClientIdById.set(id, clientId);
        }
      }
    }
    for (const row of cashData ?? []) {
      const clientId = asClientId(row.client_id);
      const assetId = Number(row.asset_id);
      const assetClientId = assetClientIdById.get(assetId);
      const currencyCode = String(row.currency_code ?? "").toUpperCase();
      if (clientId && assetClientId && currencyCode) {
        metadataByClientId.set(clientId, {
          currencyCode,
          assetKey: `client:${assetClientId}`,
        });
      }
    }
  }

  const diagnostics: FxExchangeDiagnostic[] = [];
  for (const eventClientId of fxEventClientIds) {
    const matchingLines = fxLines.filter((line) =>
      asClientId(line["event_client_id"]) === eventClientId
    );
    const outLine = matchingLines.find((line) => line["action"] === "fx_out");
    const inLine = matchingLines.find((line) => line["action"] === "fx_in");
    if (!outLine || !inLine) continue;
    const outCashClientId = asClientId(outLine["cash_account_client_id"]);
    const inCashClientId = asClientId(inLine["cash_account_client_id"]);
    const outMetadata = outCashClientId
      ? metadataByClientId.get(outCashClientId)
      : null;
    const inMetadata = inCashClientId
      ? metadataByClientId.get(inCashClientId)
      : null;
    const reasons: string[] = [];
    if (outCashClientId == null || outCashClientId === inCashClientId) {
      reasons.push("fx_cash_accounts_must_be_distinct");
    }
    if (
      !outMetadata ||
      outMetadata.currencyCode !==
        String(outLine["currency_code"] ?? "").toUpperCase()
    ) {
      reasons.push("fx_out_currency_must_match_cash_account");
    }
    if (
      !inMetadata ||
      inMetadata.currencyCode !==
        String(inLine["currency_code"] ?? "").toUpperCase()
    ) {
      reasons.push("fx_in_currency_must_match_cash_account");
    }
    if (
      outMetadata && inMetadata &&
      outMetadata.assetKey !== inMetadata.assetKey
    ) {
      reasons.push("fx_cash_accounts_must_share_asset");
    }
    if (reasons.length > 0) {
      diagnostics.push({
        event_client_id: eventClientId,
        line_client_ids: matchingLines.map((line) =>
          asClientId(line["client_id"])
        ),
        reasons,
      });
    }
  }
  return diagnostics;
}

async function upsertRows(
  adminClient: SupabaseClient,
  table: SyncTable,
  rows: JsonRow[],
): Promise<UpsertResult> {
  if (rows.length === 0) {
    return { acceptedClientIds: [], conflicts: [] };
  }

  const clientIds = compactClientIds(rows);
  const { data: currentRows, error: currentError } = await adminClient
    .from(table)
    .select("client_id, last_modified_at")
    .in("client_id", clientIds)
    .eq("user_id", String(rows[0].user_id ?? ""));

  if (currentError) {
    throw new Error(
      `${table} conflict preload failed: ${currentError.message}`,
    );
  }

  const currentLastModifiedByClientId = new Map<string, string | null>();
  for (const row of currentRows ?? []) {
    const clientId = asClientId(row.client_id);
    if (!clientId) continue;
    currentLastModifiedByClientId.set(
      clientId,
      asTimestamp(row.last_modified_at),
    );
  }

  const acceptedRows: JsonRow[] = [];
  const conflicts: ConflictRow[] = [];
  for (const row of rows) {
    const clientId = asClientId(row["client_id"]);
    if (!clientId) continue;
    const clientLastModifiedAt = asTimestamp(row["last_modified_at"]);
    const serverLastModifiedAt = currentLastModifiedByClientId.get(clientId) ??
      null;
    if (
      currentLastModifiedByClientId.has(clientId) &&
      compareTimestamps(clientLastModifiedAt, serverLastModifiedAt) < 0
    ) {
      conflicts.push({
        table,
        client_id: clientId,
        reason: "server_newer",
        client_last_modified_at: clientLastModifiedAt,
        server_last_modified_at: serverLastModifiedAt,
      });
      continue;
    }
    acceptedRows.push(row);
  }

  if (acceptedRows.length === 0) {
    return { acceptedClientIds: [], conflicts };
  }

  const { error } = await adminClient
    .from(table)
    .upsert(acceptedRows, { onConflict: "user_id,client_id" });

  if (error) {
    throw new Error(`${table} upsert failed: ${error.message}`);
  }

  return {
    acceptedClientIds: compactClientIds(acceptedRows),
    conflicts,
  };
}

async function upsertSnapshotNotes(
  adminClient: SupabaseClient,
  rows: JsonRow[],
): Promise<UpsertResult> {
  if (rows.length === 0) {
    return { acceptedClientIds: [], conflicts: [] };
  }

  const userId = String(rows[0].user_id ?? "");
  const snapshotDates = rows
    .map((row) => String(row.snapshot_date ?? "").trim())
    .filter((date) => date.length > 0);
  if (snapshotDates.length === 0) {
    return { acceptedClientIds: [], conflicts: [] };
  }

  const { data: currentRows, error: currentError } = await adminClient
    .from("snapshot_notes")
    .select("snapshot_date, updated_at")
    .eq("user_id", userId)
    .in("snapshot_date", snapshotDates);

  if (currentError) {
    throw new Error(
      `snapshot_notes conflict preload failed: ${currentError.message}`,
    );
  }

  const currentUpdatedAtByDate = new Map<string, string | null>();
  for (const row of currentRows ?? []) {
    const snapshotDate = String(row.snapshot_date ?? "").trim();
    if (snapshotDate.length === 0) continue;
    currentUpdatedAtByDate.set(snapshotDate, asTimestamp(row.updated_at));
  }

  const acceptedRows: JsonRow[] = [];
  const conflicts: ConflictRow[] = [];
  for (const row of rows) {
    const snapshotDate = String(row.snapshot_date ?? "").trim();
    if (snapshotDate.length === 0) continue;
    const clientLastModifiedAt = asTimestamp(row.updated_at);
    const serverLastModifiedAt = currentUpdatedAtByDate.get(snapshotDate) ??
      null;
    if (
      currentUpdatedAtByDate.has(snapshotDate) &&
      compareTimestamps(clientLastModifiedAt, serverLastModifiedAt) < 0
    ) {
      conflicts.push({
        table: "snapshot_notes",
        client_id: snapshotDate,
        reason: "server_newer",
        client_last_modified_at: clientLastModifiedAt,
        server_last_modified_at: serverLastModifiedAt,
      });
      continue;
    }
    acceptedRows.push(row);
  }

  if (acceptedRows.length === 0) {
    return { acceptedClientIds: [], conflicts };
  }

  const { error } = await adminClient
    .from("snapshot_notes")
    .upsert(acceptedRows, { onConflict: "user_id,snapshot_date" });

  if (error) {
    throw new Error(`snapshot_notes upsert failed: ${error.message}`);
  }

  return {
    acceptedClientIds: acceptedRows
      .map((row) => String(row.snapshot_date ?? "").trim())
      .filter((date) => date.length > 0),
    conflicts,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const auth = await authenticateUser(
      req.headers.get("Authorization"),
      supabaseUrl,
      supabaseAnonKey,
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

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        {
          ok: false,
          step: "env_check",
          supabase_url_exists: !!supabaseUrl,
          anon_key_exists: !!supabaseAnonKey,
          service_role_exists: !!serviceRoleKey,
        },
        500,
      );
    }

    const adminClient = createClient<any>(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const body = await req.json().catch(() => ({}));
    const userId = auth.userId;
    const relationFailures: RelationFailure[] = [];

    if (
      body.payload_version !== 4 ||
      body.schema_mode !== "ledger_only_delta"
    ) {
      return jsonResponse(
        {
          ok: false,
          step: "unsupported_payload",
          expected_payload_version: 4,
          expected_schema_mode: "ledger_only_delta",
          payload_version: body.payload_version ?? null,
          schema_mode: body.schema_mode ?? null,
        },
        409,
      );
    }

    const rawHoldingRows = asRows(body.holdings);
    const rawCashAccountRows = asRows(body.cash_accounts);
    const rawTransactionEventRows = asRows(body.transaction_events);
    const rawTransactionLineRows = asRows(body.transaction_lines);
    const rawSnapshotNoteRows = asRows(body.snapshot_notes);
    const fxExchangeDiagnostics = validateFxExchangePayload(
      rawTransactionEventRows,
      rawTransactionLineRows,
    );
    if (fxExchangeDiagnostics.length > 0) {
      return jsonResponse(
        {
          ok: false,
          step: "invalid_fx_exchange",
          diagnostics: fxExchangeDiagnostics,
        },
        422,
      );
    }
    const preflightRelationFailures =
      await validatePayloadRelationsBeforeMutation(
        adminClient,
        userId,
        asRows(body.assets),
        rawHoldingRows,
        rawCashAccountRows,
        rawTransactionEventRows,
        rawTransactionLineRows,
      );
    if (preflightRelationFailures.length > 0) {
      return jsonResponse(
        {
          ok: false,
          step: "relation_preflight",
          relation_failures: preflightRelationFailures,
        },
        422,
      );
    }
    const fxAccountDiagnostics = await validateFxExchangeAccountMetadata(
      adminClient,
      userId,
      rawCashAccountRows,
      rawTransactionEventRows,
      rawTransactionLineRows,
    );
    if (fxAccountDiagnostics.length > 0) {
      return jsonResponse(
        {
          ok: false,
          step: "invalid_fx_exchange_accounts",
          diagnostics: fxAccountDiagnostics,
        },
        422,
      );
    }
    const acceptedClientIds: Record<AcceptedSyncKey, string[]> = {
      assets: [],
      holdings: [],
      cash_accounts: [],
      transaction_events: [],
      transaction_lines: [],
      snapshot_notes: [],
    };
    const conflicts: ConflictRow[] = [];

    const assetRows = attachUserId(asRows(body.assets), userId).map((row) =>
      pickColumns(row, [
        "client_id",
        "last_modified_at",
        "deleted_at",
        "asset_type",
        "title",
        "alias",
        "currency_code",
        "value",
        "change",
        "icon_code_point",
        "quantity_label",
        "quantity_value",
        "average_label",
        "average_value",
        "note",
        "sort_order",
        "user_id",
      ])
    );

    const assetUpsert = await upsertRows(adminClient, "assets", assetRows);
    acceptedClientIds.assets = assetUpsert.acceptedClientIds;
    conflicts.push(...assetUpsert.conflicts);

    const referencedAssetClientIds = new Set<string>(
      compactClientIds(assetRows),
    );
    for (
      const clientId of collectReferencedClientIds(
        rawHoldingRows,
        "asset_client_id",
      )
    ) {
      referencedAssetClientIds.add(clientId);
    }
    for (
      const clientId of collectReferencedClientIds(
        rawCashAccountRows,
        "asset_client_id",
      )
    ) {
      referencedAssetClientIds.add(clientId);
    }
    for (
      const clientId of collectReferencedClientIds(
        rawTransactionLineRows,
        "asset_client_id",
      )
    ) {
      referencedAssetClientIds.add(clientId);
    }

    const assetIdMap = await loadIdMap(
      adminClient,
      "assets",
      userId,
      [...referencedAssetClientIds],
    );

    const holdingRows = attachUserId(rawHoldingRows, userId)
      .map((row) => {
        const assetClientId = asClientId(row["asset_client_id"]);
        const assetId = assetClientId ? assetIdMap.get(assetClientId) : null;
        if (assetId == null) {
          relationFailures.push({
            table: "holdings",
            client_id: asClientId(row["client_id"]),
            reason: `missing_asset:${assetClientId ?? "null"}`,
          });
          return null;
        }

        return pickColumns(
          {
            ...row,
            asset_id: assetId,
          },
          [
            "client_id",
            "last_modified_at",
            "asset_id",
            "deleted_at",
            "currency_code",
            "market_updated_at",
            "exchange_code",
            "name",
            "symbol",
            "quantity",
            "average_price",
            "average_price_source",
            "average_price_krw",
            "average_purchase_fx_rate",
            "cost_basis_krw",
            "current_price",
            "note",
            "sort_order",
            "user_id",
          ],
        );
      })
      .filter((row): row is JsonRow => row != null);

    const cashAccountRows = attachUserId(rawCashAccountRows, userId)
      .map((row) => {
        const assetClientId = asClientId(row["asset_client_id"]);
        const assetId = assetClientId ? assetIdMap.get(assetClientId) : null;
        if (assetId == null) {
          relationFailures.push({
            table: "cash_accounts",
            client_id: asClientId(row["client_id"]),
            reason: `missing_asset:${assetClientId ?? "null"}`,
          });
          return null;
        }

        return pickColumns(
          {
            ...row,
            asset_id: assetId,
          },
          [
            "client_id",
            "last_modified_at",
            "asset_id",
            "deleted_at",
            "currency_code",
            "name",
            "base_balance",
            "balance",
            "note",
            "sort_order",
            "user_id",
          ],
        );
      })
      .filter((row): row is JsonRow => row != null);

    const transactionEventRows = attachUserId(rawTransactionEventRows, userId)
      .map((row) =>
        pickColumns(row, [
          "client_id",
          "last_modified_at",
          "deleted_at",
          "occurred_at",
          "kind",
          "title",
          "memo",
          "source",
          "flow_category",
          "legacy_source_table",
          "legacy_source_id",
          "sort_order",
          "user_id",
        ])
      );

    if (conflicts.length > 0) {
      return jsonResponse(
        {
          ok: false,
          step: "pre_ledger_conflict",
          conflict_count: conflicts.length,
          conflicts,
        },
        409,
      );
    }

    const holdingPreserveResult = await preserveUsdHoldingCurrencyBasis(
      adminClient,
      holdingRows,
      userId,
    );

    const { data: ledgerResultData, error: ledgerError } = await adminClient.rpc(
      "sync_portfolio_state_atomic",
      {
        p_user_id: userId,
        p_holdings: holdingPreserveResult.rows,
        p_cash_accounts: cashAccountRows,
        p_events: transactionEventRows,
        p_lines: rawTransactionLineRows,
      },
    );
    if (ledgerError) {
      const status = ledgerError.code === "22023" || ledgerError.code === "23503"
        ? 422
        : 500;
      return jsonResponse(
        {
          ok: false,
          step: "portfolio_state_atomic_rpc",
          error_code: ledgerError.code ?? null,
          error: ledgerError.message,
        },
        status,
      );
    }
    const ledgerResult = ledgerResultData && typeof ledgerResultData === "object"
      ? ledgerResultData as JsonRow
      : null;
    if (!ledgerResult || ledgerResult["ok"] !== true) {
      const ledgerConflicts = Array.isArray(ledgerResult?.["conflicts"])
        ? ledgerResult["conflicts"]
        : [];
      return jsonResponse(
        {
          ok: false,
          step: "portfolio_state_atomic_conflict",
          conflict_count: ledgerConflicts.length,
          conflicts: ledgerConflicts,
        },
        409,
      );
    }
    acceptedClientIds.transaction_events = Array.isArray(
        ledgerResult["accepted_event_client_ids"],
      )
      ? ledgerResult["accepted_event_client_ids"] as string[]
      : [];
    acceptedClientIds.transaction_lines = Array.isArray(
        ledgerResult["accepted_line_client_ids"],
      )
      ? ledgerResult["accepted_line_client_ids"] as string[]
      : [];
    acceptedClientIds.cash_accounts = Array.isArray(
        ledgerResult["accepted_cash_account_client_ids"],
      )
      ? ledgerResult["accepted_cash_account_client_ids"] as string[]
      : [];
    acceptedClientIds.holdings = Array.isArray(
        ledgerResult["accepted_holding_client_ids"],
      )
      ? ledgerResult["accepted_holding_client_ids"] as string[]
      : [];

    const snapshotNoteRows = attachUserId(rawSnapshotNoteRows, userId)
      .map((row) =>
        pickColumns(
          {
            ...row,
            updated_at: asTimestamp(row["last_modified_at"]) ??
              asTimestamp(row["updated_at"]) ??
              new Date().toISOString(),
          },
          [
            "snapshot_date",
            "note",
            "user_id",
            "updated_at",
          ],
        )
      );
    const snapshotNotesUpsert = await upsertSnapshotNotes(
      adminClient,
      snapshotNoteRows,
    );
    acceptedClientIds.snapshot_notes =
      snapshotNotesUpsert.acceptedClientIds;
    conflicts.push(...snapshotNotesUpsert.conflicts);

    return jsonResponse({
      ok: true,
      step: "done",
      payload_version: 4,
      schema_mode: "ledger_only_delta",
      user_id: userId,
      counts: {
        assets: assetRows.length,
        holdings: holdingRows.length,
        cash_accounts: cashAccountRows.length,
        transaction_events: transactionEventRows.length,
        transaction_lines: acceptedClientIds.transaction_lines.length,
        snapshot_notes: snapshotNoteRows.length,
      },
      accepted_client_ids: acceptedClientIds,
      conflict_count: conflicts.length,
      conflicts,
      preserved_rows: holdingPreserveResult.preserved,
      relation_failures: relationFailures,
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
