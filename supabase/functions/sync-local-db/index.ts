import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type JsonRow = Record<string, unknown>;

type RelationFailure = {
  table: string;
  client_id: string | null;
  reason: string;
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

function attachUserId(rows: JsonRow[], userId: string): JsonRow[] {
  return rows.map((row) => ({ ...row, user_id: userId }));
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
): Promise<void> {
  if (rows.length === 0) {
    return;
  }

  const { error } = await adminClient
    .from(table)
    .upsert(rows, { onConflict: "user_id,client_id" });

  if (error) {
    throw new Error(`${table} upsert failed: ${error.message}`);
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

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        {
          ok: false,
          step: "env_check",
          supabase_url_exists: !!supabaseUrl,
          service_role_exists: !!serviceRoleKey,
        },
        500,
      );
    }

    const adminClient = createClient<any>(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const body = await req.json().catch(() => ({}));
    const userId = decoded.userId;
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

    const assetRows = attachUserId(asRows(body.assets), userId).map((row) =>
      pickColumns(row, [
        "client_id",
        "deleted_at",
        "asset_type",
        "title",
        "alias",
        "hidden",
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

    await upsertRows(adminClient, "assets", assetRows);

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
            "asset_id",
            "deleted_at",
            "hidden",
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

    await upsertRows(adminClient, "holdings", holdingRows);

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
            "asset_id",
            "deleted_at",
            "hidden",
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

    await upsertRows(adminClient, "cash_accounts", cashAccountRows);

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

    await upsertRows(adminClient, "transaction_events", transactionEventRows);

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

    await upsertRows(adminClient, "transaction_lines", transactionLineRows);

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
