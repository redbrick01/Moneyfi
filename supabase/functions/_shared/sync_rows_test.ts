import { deepStrictEqual, equal, rejects } from "node:assert/strict";
import { createClient } from "npm:@supabase/supabase-js@2";
import { loadSyncRows } from "./sync_rows.ts";

function fixture(
  pages: Array<Array<{ id: number; client_id: string | null }>>,
) {
  const requests: string[] = [];
  const db = createClient("https://example.invalid", "test-key", {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      fetch: async (input, init) => {
        const url = new URL(String(input));
        requests.push(`${init?.method} ${url.pathname.split("/").pop()}`);
        if (init?.method === "PATCH") {
          equal(url.searchParams.get("user_id"), "eq.owner");
          equal(url.searchParams.get("id"), "eq.7");
          equal(url.searchParams.get("client_id"), "is.null");
          equal(url.searchParams.get("deleted_at"), "is.null");
          return new Response(null, { status: 204 });
        }
        const page = pages.shift();
        if (!page) throw new Error("Unexpected extra read");
        return Response.json(page, {
          headers: { "content-range": `0-0/${page.length}` },
        });
      },
    },
  });
  return { db, requests };
}

Deno.test("common path makes one read per table and no identity checks", async () => {
  const tables = [
    "assets",
    "holdings",
    "cash_accounts",
    "transaction_events",
    "transaction_lines",
  ] as const;
  const { db, requests } = fixture(
    tables.map(() => [{ id: 7, client_id: "existing" }]),
  );
  await Promise.all(
    tables.map((table) =>
      loadSyncRows(
        db,
        table,
        "owner",
        () => db.from(table).select("id,client_id", { count: "exact" }),
      )
    ),
  );
  equal(requests.length, 5);
  equal(requests.every((request) => request.startsWith("GET ")), true);
});

Deno.test("repair writes to holdings and reads back the concurrent winner from the view", async () => {
  const { db, requests } = fixture([[{ id: 7, client_id: null }], [{
    id: 7,
    client_id: "winner",
  }]]);
  const result = await loadSyncRows(
    db,
    "holdings",
    "owner",
    () =>
      db.from("holdings_with_quote_checks").select("id,client_id", {
        count: "exact",
      }),
  );
  equal(result.data[0].client_id, "winner");
  deepStrictEqual(requests, [
    "GET holdings_with_quote_checks",
    "PATCH holdings",
    "GET holdings_with_quote_checks",
  ]);
});

Deno.test("a deletion during repair fails the pull instead of returning partial state", async () => {
  const { db } = fixture([[{ id: 7, client_id: null }], []]);
  await rejects(
    loadSyncRows(
      db,
      "assets",
      "owner",
      () => db.from("assets").select("id,client_id", { count: "exact" }),
    ),
    /changed during client_id repair/,
  );
});
