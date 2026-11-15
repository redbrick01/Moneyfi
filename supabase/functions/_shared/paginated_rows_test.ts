import { fetchAllRows } from "./paginated_rows.ts";

Deno.test("loads all rows across the default 1000-row API limit", async () => {
  const source = Array.from({ length: 1001 }, (_, index) => ({ id: index + 1 }));
  const pages: number[] = [];
  const result = await fetchAllRows(() => ({
    range: async (from: number, to: number) => {
      pages.push(from);
      return { data: source.slice(from, to + 1), error: null, count: source.length };
    },
  }));
  if (result.data.length !== 1001 || pages.join(",") !== "0,1000") {
    throw new Error("Core pull did not load every page");
  }
});

Deno.test("rejects a truncated result instead of applying partial core data", async () => {
  let rejected = false;
  try {
    await fetchAllRows(() => ({
      range: async () => ({ data: [{ id: 1 }], error: null, count: 2 }),
    }));
  } catch {
    rejected = true;
  }
  if (!rejected) throw new Error("Incomplete result was accepted");
});
