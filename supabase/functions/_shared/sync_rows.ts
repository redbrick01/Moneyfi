import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { fetchAllRows } from "./paginated_rows.ts";

type SyncTable =
  | "assets"
  | "holdings"
  | "cash_accounts"
  | "transaction_events"
  | "transaction_lines";

export async function loadSyncRows(
  supabase: SupabaseClient<any>,
  table: SyncTable,
  userId: string,
  buildQuery: Parameters<typeof fetchAllRows>[0],
) {
  const result = await fetchAllRows(buildQuery);
  const missing = result.data.filter((row) => row.client_id == null);
  if (missing.length === 0) return result;

  for (const row of missing) {
    const { error } = await supabase.from(table)
      .update({ client_id: crypto.randomUUID() })
      .eq("user_id", userId)
      .eq("id", row.id)
      .is("deleted_at", null)
      .is("client_id", null);
    if (error) {
      throw new Error(`${table} client_id backfill failed: ${error.message}`);
    }
  }

  // A concurrent pull may have assigned a different UUID. Use persisted rows
  // and their current modification timestamps when building the sync payload.
  const repaired = await fetchAllRows(buildQuery);
  const originalIds = new Set(result.data.map((row) => row.id));
  if (
    repaired.data.length !== originalIds.size ||
    repaired.data.some((row) => !originalIds.has(row.id) || !row.client_id)
  ) {
    throw new Error(`${table} changed during client_id repair; retry sync`);
  }
  return repaired;
}
