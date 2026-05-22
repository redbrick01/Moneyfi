import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = "gpt-5-mini";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function requireEnv(name: string, value: string) {
  if (!value) {
    throw new Error(`Missing env: ${name}`);
  }
}

function asString(value: unknown, fallback = ""): string {
  if (typeof value === "string") return value;
  if (value == null) return fallback;
  return String(value);
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => asString(item).trim())
    .filter((item) => item.length > 0);
}

function asBoolean(value: unknown): boolean {
  return value === true;
}

function extractSupabaseErrorMessage(result: unknown): string | null {
  if (!result || typeof result !== "object") return null;
  const errorValue = (result as Record<string, unknown>).error;
  if (!errorValue || typeof errorValue !== "object") return null;
  const message = (errorValue as Record<string, unknown>).message;
  if (typeof message === "string" && message.trim().length > 0) {
    return message.trim();
  }
  return "Unknown Supabase error";
}

function extractSupabaseData(result: unknown): unknown[] {
  if (!result || typeof result !== "object") return [];
  const data = (result as Record<string, unknown>).data;
  return Array.isArray(data) ? data : [];
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object"
    ? value as Record<string, unknown>
    : {};
}

function asImportance(value: unknown): 1 | 2 | 3 {
  if (value === 1 || value === 2 || value === 3) return value;
  if (value === "1" || value === "2" || value === "3") {
    return Number(value) as 1 | 2 | 3;
  }
  return 2;
}

function asSentiment(value: unknown): "positive" | "neutral" | "negative" {
  const normalized = asString(value).trim().toLowerCase();
  if (normalized === "positive") return "positive";
  if (normalized === "negative") return "negative";
  return "neutral";
}

function normalizeEnding(text: string): string {
  let t = text.trim();

  t = t.replace(
    /(고조됨|상승함|하락함|확대됨|축소됨|지속됨|강화됨|완화됨|부각됨|심화됨|둔화됨|악화됨|개선됨)$/g,
    (m) => m.replace(/됨|함$/, ""),
  );
  t = t.replace(/(추세임|상태임|국면임)$/g, "");
  t = t.replace(/(거론됨|언급됨|제기됨|관측됨)$/g, (m) => m.replace(/됨$/, ""));
  t = t.replace(/(증가함|감소함|확인됨)$/g, (m) => m.replace(/함|됨$/, ""));
  t = t.replace(/(진행중|진행 중)$/g, "진행");
  t = t.replace(/(논의중|논의 중)$/g, "논의");
  t = t.replace(/(검토중|검토 중)$/g, "검토");

  t = t.replace(/수 있음$/g, "");
  t = t.replace(/가능성 있음$/g, "가능성");
  t = t.replace(/우려됨$/g, "우려");
  t = t.replace(/기대됨$/g, "기대");

  t = t.replace(/됨$/g, "");
  t = t.replace(/임$/g, "");
  t = t.replace(/중$/g, "");
  t = t.replace(/것$/g, "");

  t = t.replace(/\s+/g, " ").trim();
  return t;
}

function cleanCompanySummary(value: unknown): string {
  let text = asString(value).trim();

  text = text.replace(/^이번\s*뉴스\s*/u, "");
  text = text.replace(/^뉴스\s*묶음\s*/u, "");
  text = text.replace(/^공통\s*주제는\s*/u, "");
  text = text.replace(/^요약하면\s*/u, "");
  text = text.replace(/^전체적으로\s*/u, "");
  text = text.replace(/^해당\s*기업은\s*/u, "");

  text = text.replace(/\s+/g, " ").trim();
  return text;
}

function sanitizeTitle(value: unknown, index: number): string {
  let text = asString(value).trim();

  text = text.replace(/[\(\)\[\]\{\}]/g, "");
  text = normalizeEnding(text);
  text = text.replace(/\s+/g, " ").trim();

  if (text.length > 22) {
    text = text.slice(0, 22);
  }

  if (!text) {
    text = `이슈 ${index + 1}`;
  }

  return text;
}

function sanitizeIssueSummary(value: unknown): string {
  let text = asString(value).trim();

  text = normalizeEnding(text);
  text = text.replace(/\s+/g, " ").trim();

  if (text.length > 180) {
    text = `${text.slice(0, 177)}...`;
  }

  if (!text) {
    return "내용 요약 없음";
  }

  return text;
}

function sanitizeCompanySummaryText(value: unknown): string {
  let text = asString(value).trim();
  text = text.replace(/\s+/g, " ").trim();
  if (text.length > 220) {
    text = `${text.slice(0, 217)}...`;
  }
  if (!text) {
    return "핵심 요약 없음";
  }
  return text;
}

function sanitizeOutlookText(value: unknown, fallbackLabel: string): string {
  let text = asString(value).trim();
  text = text.replace(/\s+/g, " ").trim();
  if (text.length > 260) {
    text = `${text.slice(0, 257)}...`;
  }
  if (text.length < 16) {
    return `근거 부족: ${fallbackLabel} 관련 기사 근거가 제한적입니다.`;
  }
  return text;
}

type CompanyNewsRow = {
  headline: string;
  summary: string;
  news_datetime: string | null;
};

type CompanyIssue = {
  id: string;
  title: string;
  summary: string;
  importance: 1 | 2 | 3;
  sentiment: "positive" | "neutral" | "negative";
  uncertainty: boolean;
};

type CompanyNewsDigest = {
  company_summary: string;
  issues: CompanyIssue[];
  outlook: {
    business_impact: string;
    market_view: string;
    watchpoint: string;
  };
};

async function persistSummary({
  supabase,
  symbol,
  newsCount,
  summary,
}: {
  supabase: SupabaseClient<any>;
  symbol: string;
  newsCount: number;
  summary: CompanyNewsDigest;
}) {
  const nowIso = new Date().toISOString();
  const summaryDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());

  const response = (await supabase
    .from("company_news_summaries")
    .upsert(
      {
        symbol,
        summary_date: summaryDate,
        model: OPENAI_MODEL,
        news_count: newsCount,
        summary_json: summary,
        updated_at: nowIso,
      },
      { onConflict: "symbol,summary_date" },
    )) ?? {};

  const persistErrorMessage = extractSupabaseErrorMessage(response);
  if (persistErrorMessage) {
    throw new Error(
      `Failed to persist company news summary: ${persistErrorMessage}`,
    );
  }
}

function normalizeNewsRows(rows: CompanyNewsRow[]) {
  return rows.map((row) => ({
    headline: asString(row.headline).trim() || "제목 없음",
    summary: asString(row.summary).trim() || "요약 없음",
    news_datetime: row.news_datetime
      ? asString(row.news_datetime).trim()
      : null,
  }));
}

function extractOutputText(payload: any): string {
  if (!payload || !Array.isArray(payload.output)) {
    return "";
  }

  const texts: string[] = [];
  for (const item of payload.output) {
    if (!item || !Array.isArray(item.content)) continue;
    for (const content of item.content) {
      if (content?.type === "output_text" && typeof content.text === "string") {
        texts.push(content.text);
      }
    }
  }

  return texts.join("").trim();
}

function validateDigestShape(value: any): CompanyNewsDigest {
  if (!value || typeof value !== "object") {
    throw new Error("Invalid digest: root is not an object");
  }

  if (typeof value.company_summary !== "string") {
    throw new Error("Invalid digest: company_summary must be string");
  }

  if (!Array.isArray(value.issues)) {
    throw new Error("Invalid digest: issues must be array");
  }

  if (
    !value.outlook ||
    typeof value.outlook !== "object" ||
    typeof value.outlook.business_impact !== "string" ||
    typeof value.outlook.market_view !== "string" ||
    typeof value.outlook.watchpoint !== "string"
  ) {
    throw new Error("Invalid digest: outlook shape mismatch");
  }

  const issues = value.issues.map((issue: any, index: number) => {
    if (!issue || typeof issue !== "object") {
      throw new Error(`Invalid digest: issues[${index}] is not object`);
    }

    return {
      id: asString(issue.id).trim() || `issue_${index + 1}`,
      title: sanitizeTitle(issue.title, index),
      summary: sanitizeIssueSummary(issue.summary),
      importance: asImportance(issue.importance),
      sentiment: asSentiment(issue.sentiment),
      uncertainty: asBoolean(issue.uncertainty),
    };
  });

  return {
    company_summary: sanitizeCompanySummaryText(
      cleanCompanySummary(value.company_summary),
    ),
    issues,
    outlook: {
      business_impact: sanitizeOutlookText(
        value.outlook.business_impact,
        "사업 영향",
      ),
      market_view: sanitizeOutlookText(value.outlook.market_view, "시장 시각"),
      watchpoint: sanitizeOutlookText(value.outlook.watchpoint, "체크포인트"),
    },
  };
}

type SymbolNewsBundle = {
  symbol: string;
  newsRows: CompanyNewsRow[];
};

function toBatchPrompt(symbolNewsList: SymbolNewsBundle[]) {
  const inputData = symbolNewsList.map((bundle) => ({
    symbol: bundle.symbol,
    news: normalizeNewsRows(bundle.newsRows),
  }));

  return [
    "너는 다중 종목 기업 뉴스 분석 시스템이다.",
    "",
    "역할:",
    "- 입력된 종목별 뉴스(headline, summary, news_datetime)만 기반으로 기업 이슈를 요약한다.",
    "- 모든 종목을 한 번에 읽고 symbol별로 분리된 결과를 생성한다.",
    "- JSON 객체 1개만 출력한다.",
    "",
    "핵심 규칙:",
    "1. 입력 뉴스에 없는 내용은 쓰지 않는다.",
    "2. 각 symbol은 자신의 뉴스만 사용한다.",
    "3. 같은 사건은 하나의 issue로 통합한다.",
    "4. 뉴스가 적으면 issue 수를 억지로 늘리지 않는다.",
    "5. 반드시 한국어로 작성한다.",
    "6. JSON 형식과 스키마를 유지한다.",
    "",
    "작성 규칙:",
    "- company_summary는 핵심 결론 중심으로 1~2문장 작성한다.",
    "- issue.summary는 사건 내용과 영향이 함께 드러나도록 작성한다.",
    "- title은 짧고 압축적으로 작성한다.",
    "- 문장은 간결하게 작성하고 불필요한 설명을 줄인다.",
    "- 가능하면 명사형 또는 짧은 명사구 중심으로 작성한다.",
    "",
    "- business_impact는 사업 지표와 방향(개선/악화)을 포함한다.",
    "- market_view는 투자자 반응 또는 변동성/밸류 변화 근거를 포함한다.",
    "- watchpoint는 향후 확인할 이벤트를 구체적으로 작성한다.",
    "",
    "- sentiment는 positive, neutral, negative 중 하나를 사용한다.",
    "- importance는 1, 2, 3 중 하나를 사용한다.",
    "- uncertainty는 근거 부족 시 true로 설정한다.",
    "",
    "출력 스키마:",
    "{",
    '  "summaries": [',
    "    {",
    '      "symbol": "string",',
    '      "company_summary": "string",',
    '      "issues": [',
    "        {",
    '          "id": "issue_1",',
    '          "title": "string",',
    '          "summary": "string",',
    '          "importance": 1,',
    '          "sentiment": "positive | neutral | negative",',
    '          "uncertainty": false',
    "        }",
    "      ],",
    '      "outlook": {',
    '        "business_impact": "string",',
    '        "market_view": "string",',
    '        "watchpoint": "string"',
    "      }",
    "    }",
    "  ]",
    "}",
    "",
    "입력 뉴스 데이터:",
    JSON.stringify(inputData),
  ].join("\n");
}

function validateBatchDigestShape(
  value: any,
  requestedSymbols: string[],
): Map<string, CompanyNewsDigest> {
  if (!value || typeof value !== "object") {
    throw new Error("Invalid batch digest: root is not an object");
  }

  if (!Array.isArray(value.summaries)) {
    throw new Error("Invalid batch digest: summaries must be array");
  }

  const allowed = new Set(requestedSymbols);
  const bySymbol = new Map<string, CompanyNewsDigest>();

  for (const entry of value.summaries) {
    const row = asRecord(entry);
    const symbol = asString(row.symbol).trim();
    if (!symbol || !allowed.has(symbol) || bySymbol.has(symbol)) {
      continue;
    }

    const digest = validateDigestShape({
      company_summary: row.company_summary,
      issues: row.issues,
      outlook: row.outlook,
    });
    bySymbol.set(symbol, digest);
  }

  return bySymbol;
}

async function summarizeCompanyNewsBatch(
  symbolNewsList: SymbolNewsBundle[],
): Promise<Map<string, CompanyNewsDigest>> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                "너는 다중 종목 기업 뉴스 분석 시스템이다. 입력 뉴스에만 근거해 한국어 JSON 객체 1개만 생성한다. 설명 문장, 마크다운, 코드블록, 서론 없이 지정된 스키마만 출력한다.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: toBatchPrompt(symbolNewsList),
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "company_news_digest_batch",
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              summaries: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  properties: {
                    symbol: { type: "string", minLength: 1, maxLength: 30 },
                    company_summary: {
                      type: "string",
                      minLength: 20,
                      maxLength: 220,
                    },
                    issues: {
                      type: "array",
                      items: {
                        type: "object",
                        additionalProperties: false,
                        properties: {
                          id: { type: "string" },
                          title: { type: "string", maxLength: 22 },
                          summary: { type: "string", maxLength: 180 },
                          importance: { type: "integer", enum: [1, 2, 3] },
                          sentiment: {
                            type: "string",
                            enum: ["positive", "neutral", "negative"],
                          },
                          uncertainty: { type: "boolean" },
                        },
                        required: [
                          "id",
                          "title",
                          "summary",
                          "importance",
                          "sentiment",
                          "uncertainty",
                        ],
                      },
                    },
                    outlook: {
                      type: "object",
                      additionalProperties: false,
                      properties: {
                        business_impact: {
                          type: "string",
                          minLength: 20,
                          maxLength: 260,
                        },
                        market_view: {
                          type: "string",
                          minLength: 20,
                          maxLength: 260,
                        },
                        watchpoint: {
                          type: "string",
                          minLength: 20,
                          maxLength: 260,
                        },
                      },
                      required: [
                        "business_impact",
                        "market_view",
                        "watchpoint",
                      ],
                    },
                  },
                  required: ["symbol", "company_summary", "issues", "outlook"],
                },
              },
            },
            required: ["summaries"],
          },
        },
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI request failed: ${response.status} ${errorText}`);
  }

  const payload = await response.json();
  const outputText = extractOutputText(payload);

  if (!outputText) {
    throw new Error("OpenAI response did not include output_text content");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(outputText);
  } catch (error) {
    throw new Error(
      `Failed to parse OpenAI JSON output: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  const bySymbol = validateBatchDigestShape(
    parsed,
    symbolNewsList.map((item) => item.symbol),
  );

  if (bySymbol.size === 0) {
    throw new Error(
      "OpenAI batch output did not include usable symbol summaries",
    );
  }

  return bySymbol;
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);
    requireEnv("OPENAI_API_KEY", OPENAI_API_KEY);

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const url = new URL(req.url);
    const requestedSymbols = asStringList(body?.symbols);
    const querySymbol = asString(url.searchParams.get("symbol")).trim();
    if (querySymbol.length > 0) requestedSymbols.push(querySymbol);
    const limitPerSymbol = Math.max(
      1,
      Math.min(
        50,
        Number(
          asString(
            body?.limit_per_symbol ?? url.searchParams.get("limit_per_symbol"),
            "20",
          ),
        ) || 20,
      ),
    );

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    const symbolResponse = (await supabase
      .from("company_news")
      .select("symbol")
      .order("symbol", { ascending: true })) ?? {};

    const symbolErrorMessage = extractSupabaseErrorMessage(symbolResponse);
    if (symbolErrorMessage) {
      throw new Error(
        `Failed to load company news symbols: ${symbolErrorMessage}`,
      );
    }

    const allSymbols = Array.from(
      new Set(
        extractSupabaseData(symbolResponse)
          .map((row) => asString(asRecord(row).symbol).trim())
          .filter((value) => value.length > 0),
      ),
    );

    const symbolsToProcess = requestedSymbols.length > 0
      ? allSymbols.filter((symbol) => requestedSymbols.includes(symbol))
      : allSymbols;

    if (symbolsToProcess.length === 0) {
      return jsonResponse(
        {
          ok: false,
          error: "company_news 테이블에 처리할 symbol이 없습니다.",
        },
        400,
      );
    }

    const results: Array<Record<string, unknown>> = [];
    const newsBundles: SymbolNewsBundle[] = [];

    for (const symbol of symbolsToProcess) {
      const newsResponse = (await supabase
        .from("company_news")
        .select("symbol, headline, summary, news_datetime")
        .eq("symbol", symbol)
        .order("news_datetime", { ascending: false })
        .limit(limitPerSymbol)) ?? {};

      const newsErrorMessage = extractSupabaseErrorMessage(newsResponse);
      if (newsErrorMessage) {
        results.push({
          symbol,
          ok: false,
          error: `Failed to load company news: ${newsErrorMessage}`,
        });
        continue;
      }

      const rows = extractSupabaseData(newsResponse);
      const resolvedSymbol = symbol ||
        asString(asRecord(rows[0]).symbol).trim();

      const newsRows = rows
        .map((row) => ({
          headline: asString(asRecord(row).headline).trim(),
          summary: asString(asRecord(row).summary).trim(),
          news_datetime: asString(asRecord(row).news_datetime).trim() || null,
        }))
        .filter((row) => row.headline || row.summary);

      if (newsRows.length === 0) {
        results.push({
          symbol: resolvedSymbol,
          ok: false,
          error: "요약할 회사 뉴스가 없습니다.",
        });
        continue;
      }

      newsBundles.push({
        symbol: resolvedSymbol,
        newsRows,
      });
    }

    if (newsBundles.length > 0) {
      try {
        const summariesBySymbol = await summarizeCompanyNewsBatch(newsBundles);
        for (const bundle of newsBundles) {
          const summary = summariesBySymbol.get(bundle.symbol);
          if (!summary) {
            results.push({
              symbol: bundle.symbol,
              ok: false,
              error: "배치 요약 결과에 해당 종목이 누락되었습니다.",
            });
            continue;
          }

          await persistSummary({
            supabase,
            symbol: bundle.symbol,
            newsCount: bundle.newsRows.length,
            summary,
          });

          results.push({
            symbol: bundle.symbol,
            ok: true,
            news_count: bundle.newsRows.length,
            saved_to_db: true,
          });
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        for (const bundle of newsBundles) {
          results.push({
            symbol: bundle.symbol,
            ok: false,
            error: message,
          });
        }
      }
    }

    const successCount = results.filter((row) => row["ok"] === true).length;
    const failureCount = results.length - successCount;

    return jsonResponse({
      ok: failureCount == 0,
      processed_symbols: results.length,
      success_count: successCount,
      failure_count: failureCount,
      model: OPENAI_MODEL,
      results,
    });
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
