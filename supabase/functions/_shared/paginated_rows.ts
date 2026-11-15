const pageSize = 1000;

export async function fetchAllRows(buildQuery: () => any) {
  const rows: any[] = [];
  const seenIds = new Set<number>();
  let expectedCount: number | null = null;
  for (let from = 0;; from += pageSize) {
    const { data, error, count } = await buildQuery().range(
      from,
      from + pageSize - 1,
    );
    if (error) throw new Error(error.message);
    if (typeof count !== "number" ||
        (expectedCount != null && count !== expectedCount)) {
      throw new Error("Row count changed during paginated core pull");
    }
    expectedCount = count;
    const page = data ?? [];
    for (const row of page) {
      const id = Number(row.id);
      if (!Number.isSafeInteger(id) || id < 0 || seenIds.has(id)) {
        throw new Error("Missing or duplicate row during paginated core pull");
      }
      seenIds.add(id);
      rows.push(row);
    }
    if (page.length < pageSize) break;
  }
  if (rows.length !== expectedCount) {
    throw new Error("Incomplete paginated core pull");
  }
  return { data: rows, error: null };
}
