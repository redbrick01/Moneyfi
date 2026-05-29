#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const { mkdirSync, rmSync, writeFileSync } = require("node:fs");
const { basename, join, resolve } = require("node:path");

const dbPath = resolve(process.argv[2] || "Moneyfy_Reddit/data/reddit.sqlite");
const outputDir = resolve(process.argv[3] || "/private/tmp/reddit_import_sql");
const batchSize = Number(process.argv[4] || 500);

const dollarTag = "$reddit_import$";

const tables = [
  {
    name: "reddit_posts",
    conflict: "reddit_id",
    columns: ["id", "reddit_id", "subreddit", "title", "body", "url", "author", "score", "comment_count", "posted_at", "scraped_at"],
    jsonbColumns: [],
    updateColumns: ["subreddit", "title", "body", "url", "author", "score", "comment_count", "posted_at", "scraped_at"],
  },
  {
    name: "reddit_comments",
    conflict: "reddit_id",
    columns: ["id", "reddit_id", "post_reddit_id", "parent_reddit_id", "author", "body", "score", "posted_at", "scraped_at"],
    jsonbColumns: [],
    updateColumns: ["post_reddit_id", "parent_reddit_id", "author", "body", "score", "posted_at", "scraped_at"],
  },
  {
    name: "reddit_post_analysis",
    conflict: "post_reddit_id",
    columns: ["id", "post_reddit_id", "model", "is_valuable", "quality_label", "confidence", "tickers_json", "post_summary_ko", "comments_summary_ko", "reasons_ko", "raw_json", "analyzed_at", "title_ko"],
    jsonbColumns: ["tickers_json", "raw_json"],
    updateColumns: ["model", "is_valuable", "quality_label", "confidence", "tickers_json", "post_summary_ko", "comments_summary_ko", "reasons_ko", "raw_json", "analyzed_at", "title_ko"],
  },
  {
    name: "reddit_post_importance",
    conflict: "post_reddit_id",
    columns: ["id", "post_reddit_id", "model", "importance_label", "importance_score", "reasons_ko", "raw_json", "judged_at", "category_label"],
    jsonbColumns: ["raw_json"],
    updateColumns: ["model", "importance_label", "importance_score", "reasons_ko", "raw_json", "judged_at", "category_label"],
  },
  {
    name: "reddit_post_insight",
    conflict: "post_reddit_id",
    columns: ["id", "post_reddit_id", "model", "insight_ko", "raw_json", "generated_at"],
    jsonbColumns: ["raw_json"],
    updateColumns: ["model", "insight_ko", "raw_json", "generated_at"],
  },
  {
    name: "reddit_daily_report",
    conflict: "report_date",
    columns: ["id", "report_date", "model", "post_count", "report_ko", "raw_json", "generated_at"],
    jsonbColumns: ["raw_json"],
    updateColumns: ["model", "post_count", "report_ko", "raw_json", "generated_at"],
  },
  {
    name: "rag_summary_embeddings",
    conflict: "source_type, source_id, chunk_index, embedding_model",
    columns: ["id", "source_type", "source_id", "chunk_index", "text", "text_hash", "embedding_model", "embedding_dim", "embedding_json", "created_at", "updated_at"],
    jsonbColumns: ["embedding_json"],
    updateColumns: ["text", "text_hash", "embedding_dim", "embedding_json", "updated_at"],
  },
];

function sqliteJson(query) {
  const output = execFileSync("sqlite3", [
    "-json",
    `file:${dbPath}?mode=ro&cache=shared`,
    query,
  ], { encoding: "utf8", maxBuffer: 256 * 1024 * 1024 });
  return JSON.parse(output || "[]");
}

function parseJsonColumn(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function rowType(table) {
  return table.columns.map((column) => {
    if (table.jsonbColumns.includes(column)) return `${column} jsonb`;
    if (column === "id") return "id bigint";
    if (column.endsWith("_count") || column.endsWith("_score") || column === "score" || column === "is_valuable" || column === "chunk_index" || column === "embedding_dim") {
      return `${column} integer`;
    }
    if (column === "confidence") return "confidence double precision";
    if (column === "report_date") return "report_date date";
    if (column.endsWith("_at")) return `${column} timestamptz`;
    return `${column} text`;
  }).join(", ");
}

function makeSql(table, rows) {
  const normalized = rows.map((row) => {
    const next = {};
    for (const column of table.columns) {
      if (table.jsonbColumns.includes(column)) {
        const fallback = column === "tickers_json" || column === "embedding_json" ? [] : {};
        next[column] = parseJsonColumn(row[column], fallback);
      } else {
        next[column] = row[column];
      }
    }
    return next;
  });

  const json = JSON.stringify(normalized);
  const updates = table.updateColumns
    .map((column) => `${column} = excluded.${column}`)
    .join(",\n  ");

  return `insert into public.${table.name} (${table.columns.join(", ")})
select ${table.columns.join(", ")}
from jsonb_to_recordset(${dollarTag}${json}${dollarTag}::jsonb)
as r(${rowType(table)})
on conflict (${table.conflict}) do update set
  ${updates};
`;
}

rmSync(outputDir, { recursive: true, force: true });
mkdirSync(outputDir, { recursive: true });

const manifest = [];
let fileIndex = 0;

for (const table of tables) {
  const [{ count }] = sqliteJson(`select count(*) as count from ${table.name};`);
  for (let offset = 0; offset < count; offset += batchSize) {
    const rows = sqliteJson(`select ${table.columns.join(", ")} from ${table.name} order by id limit ${batchSize} offset ${offset};`);
    const filename = `${String(fileIndex).padStart(4, "0")}_${table.name}_${offset}.sql`;
    const path = join(outputDir, filename);
    writeFileSync(path, makeSql(table, rows));
    manifest.push({ table: table.name, rows: rows.length, path });
    fileIndex += 1;
  }
}

const sequenceSql = tables
  .filter((table) => table.name !== "rag_summary_embeddings" || true)
  .map((table) => `select setval(pg_get_serial_sequence('public.${table.name}', 'id'), coalesce((select max(id) from public.${table.name}), 1), true);`)
  .join("\n");
const sequencePath = join(outputDir, `${String(fileIndex).padStart(4, "0")}_reset_sequences.sql`);
writeFileSync(sequencePath, sequenceSql);
manifest.push({ table: "_sequences", rows: 0, path: sequencePath });

writeFileSync(join(outputDir, "manifest.json"), JSON.stringify(manifest, null, 2));

console.log(`Generated ${manifest.length} SQL files in ${outputDir}`);
console.log(`Source DB: ${basename(dbPath)}`);
