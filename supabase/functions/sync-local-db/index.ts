import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { authenticateUser } from "../_shared/auth.ts";

type JsonRow = Record<string, unknown>;

type RelationFailure = {
  table: string;
  client_id: string | null;
  reason: string;
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

type SyncTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";
type MappedTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
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

Deno.serve(async (req) => {
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
    const acceptedClientIds: Record<SyncTable, string[]> = {
      assets: [],
      holdings: [],
      cash_accounts: [],
      transaction_events: [],
      transaction_lines: [],
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
            "current_price",
            "note",
            "sort_order",
            "user_id",
          ],
        );
      })
      .filter((row): row is JsonRow => row != null);

    const holdingUpsert = await upsertRows(
      adminClient,
      "holdings",
      holdingRows,
    );
    acceptedClientIds.holdings = holdingUpsert.acceptedClientIds;
    conflicts.push(...holdingUpsert.conflicts);

    const referencedHoldingClientIds = new Set<string>(
      compactClientIds(holdingRows),
    );
    for (
      const clientId of collectReferencedClientIds(
        rawTransactionLineRows,
        "holding_client_id",
      )
    ) {
      referencedHoldingClientIds.add(clientId);
    }

    const holdingIdMap = await loadIdMap(
      adminClient,
      "holdings",
      userId,
      [...referencedHoldingClientIds],
    );

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

    const cashAccountUpsert = await upsertRows(
      adminClient,
      "cash_accounts",
      cashAccountRows,
    );
    acceptedClientIds.cash_accounts = cashAccountUpsert.acceptedClientIds;
    conflicts.push(...cashAccountUpsert.conflicts);

    const referencedCashAccountClientIds = new Set<string>(
      compactClientIds(cashAccountRows),
    );
    for (
      const clientId of collectReferencedClientIds(
        rawTransactionLineRows,
        "cash_account_client_id",
      )
    ) {
      referencedCashAccountClientIds.add(clientId);
    }

    const cashAccountIdMap = await loadIdMap(
      adminClient,
      "cash_accounts",
      userId,
      [...referencedCashAccountClientIds],
    );

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
          "legacy_source_table",
          "legacy_source_id",
          "sort_order",
          "user_id",
        ])
      );

    const transactionEventUpsert = await upsertRows(
      adminClient,
      "transaction_events",
      transactionEventRows,
    );
    acceptedClientIds.transaction_events =
      transactionEventUpsert.acceptedClientIds;
    conflicts.push(...transactionEventUpsert.conflicts);

    const transactionEventIdMap = await loadIdMap(
      adminClient,
      "transaction_events",
      userId,
      [
        ...compactClientIds(transactionEventRows),
        ...collectReferencedClientIds(
          rawTransactionLineRows,
          "event_client_id",
        ),
      ],
    );

    const transactionLineRows = attachUserId(rawTransactionLineRows, userId)
      .map((row) => {
        const eventClientId = asClientId(row["event_client_id"]);
        const assetClientId = asClientId(row["asset_client_id"]);
        const holdingClientId = asClientId(row["holding_client_id"]);
        const cashAccountClientId = asClientId(row["cash_account_client_id"]);
        const eventId = eventClientId
          ? transactionEventIdMap.get(eventClientId) ?? null
          : null;
        const assetId = assetClientId ? assetIdMap.get(assetClientId) : null;
        const holdingId = holdingClientId
          ? holdingIdMap.get(holdingClientId) ?? null
          : null;
        const cashAccountId = cashAccountClientId
          ? cashAccountIdMap.get(cashAccountClientId) ?? null
          : null;

        if (eventId == null) {
          relationFailures.push({
            table: "transaction_lines",
            client_id: asClientId(row["client_id"]),
            reason: `missing_event:${eventClientId ?? "null"}`,
          });
          return null;
        }

        if (assetClientId && assetId == null) {
          relationFailures.push({
            table: "transaction_lines",
            client_id: asClientId(row["client_id"]),
            reason: `missing_asset:${assetClientId}`,
          });
          return null;
        }

        if (holdingClientId && holdingId == null) {
          relationFailures.push({
            table: "transaction_lines",
            client_id: asClientId(row["client_id"]),
            reason: `missing_holding:${holdingClientId}`,
          });
          return null;
        }

        if (cashAccountClientId && cashAccountId == null) {
          relationFailures.push({
            table: "transaction_lines",
            client_id: asClientId(row["client_id"]),
            reason: `missing_cash_account:${cashAccountClientId}`,
          });
          return null;
        }

        return pickColumns(
          {
            ...row,
            event_id: eventId,
            asset_id: assetId,
            holding_id: holdingId,
            cash_account_id: cashAccountId,
          },
          [
            "client_id",
            "last_modified_at",
            "event_id",
            "asset_id",
            "holding_id",
            "cash_account_id",
            "deleted_at",
            "legacy_source_table",
            "legacy_source_id",
            "action",
            "currency_code",
            "quantity_delta",
            "cash_delta",
            "unit_price",
            "gross_amount",
            "fee_amount",
            "tax_amount",
            "cost_basis_delta",
            "realized_pnl",
            "fx_rate",
            "sort_order",
            "user_id",
          ],
        );
      })
      .filter((row): row is JsonRow => row != null);

    const transactionLineUpsert = await upsertRows(
      adminClient,
      "transaction_lines",
      transactionLineRows,
    );
    acceptedClientIds.transaction_lines =
      transactionLineUpsert.acceptedClientIds;
    conflicts.push(...transactionLineUpsert.conflicts);

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
        transaction_lines: transactionLineRows.length,
      },
      accepted_client_ids: acceptedClientIds,
      conflict_count: conflicts.length,
      conflicts,
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
