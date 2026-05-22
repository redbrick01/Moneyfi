import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = "gpt-5-mini";
const OPENAI_MAX_OUTPUT_TOKENS = 3500;

// 선택: 외부 cron/webhook 보호용 시크릿
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

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

function asNumber(value: unknown, fallback: number): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object"
    ? value as Record<string, unknown>
    : {};
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

function asImportance(value: unknown): 1 | 2 | 3 {
  const n = asNumber(value, 2);
  if (n === 1 || n === 2 || n === 3) return n;
  return 2;
}

function asCategory(value: unknown): "general" | "forex" | "crypto" | "merger" {
  const normalized = typeof value === "string"
    ? value.trim().toLowerCase()
    : "";
  if (normalized === "general") return "general";
  if (normalized === "forex") return "forex";
  if (normalized === "crypto") return "crypto";
  if (normalized === "merger") return "merger";
  return "general";
}

function cleanMarketSummary(value: unknown): string {
  return asString(value).trim();
}

function sanitizeTitle(value: unknown, index: number): string {
  let text = asString(value).trim();
  text = text.replace(/\s+/g, " ").trim();

  // 빈 값 방지
  if (!text) {
    text = `이슈 ${index + 1}`;
  }

  return text;
}

function sanitizeSummary(value: unknown): string {
  let text = asString(value).trim();
  text = text.replace(/\s+/g, " ").trim();

  // 빈 값 방지
  if (!text) {
    return "내용 요약 없음";
  }

  return text;
}

function sanitizeNarrative(value: unknown, fallback: string): string {
  let text = asString(value).trim();

  // 공백 정리
  text = text.replace(/\s+/g, " ").trim();

  // 빈 값 방지
  if (!text) {
    return fallback;
  }

  return text;
}

type MarketNewsRow = {
  headline: string | null;
  summary: string | null;
  news_datetime: string | null;
};

type MarketImpact = {
  stocks: string | null;
  bonds_rates: string | null;
  fx: string | null;
  crypto: string | null;
};

type Issue = {
  id: string;
  title: string;
  summary: string;
  importance: 1 | 2 | 3;
  market_impact: MarketImpact;
  uncertainty: boolean;
};

type NewsDigest = {
  market_summary: string;
  issues: Issue[];
  overall_assessment: {
    key_risk: string;
    risk_assets: string;
    safe_assets: string;
  };
};

async function persistSummary({
  supabase,
  category,
  model,
  newsCount,
  summary,
}: {
  supabase: SupabaseClient<any>;
  category: string;
  model: string;
  newsCount: number;
  summary: NewsDigest;
}) {
  const nowIso = new Date().toISOString();
  const summaryDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());

  const { error } = await supabase
    .from("market_news_summaries")
    .upsert(
      {
        category,
        summary_date: summaryDate,
        model,
        news_count: newsCount,
        summary_json: summary,
        updated_at: nowIso,
      },
      { onConflict: "category,summary_date" },
    );

  if (error) {
    throw new Error(`Failed to persist market news summary: ${error.message}`);
  }
}

function normalizeNewsRows(newsRows: MarketNewsRow[]) {
  return newsRows.map((row) => ({
    title: asString(row.headline).trim() || "제목 없음",
    summary: asString(row.summary).trim() || "요약 없음",
    news_datetime: asString(row.news_datetime).trim() || null,
  }));
}

function toPrompt(newsRows: MarketNewsRow[]) {
  const inputData = normalizeNewsRows(newsRows);

  return [
    "목표: 입력 뉴스만 근거로 마켓 이슈를 구조화해 JSON 객체 1개를 생성한다.",
    "핵심 규칙:",
    "1. 반드시 한국어로 작성한다.",
    "2. 출력은 JSON 객체 1개만 허용한다. 설명, 머리말, 코드블록은 금지한다.",
    "3. 입력 뉴스에 없는 내용은 쓰지 않는다.",
    "4. 근거가 약하면 uncertainty=true로 표시한다.",
    "5. 같은 사건이나 같은 흐름의 뉴스는 하나의 issue로 통합한다.",
    "6. 시장 영향 경로가 다르면 별도 issue로 분리한다.",
    "7. issues는 2~4개를 우선한다.",
    "8. JSON 유효성과 스키마 준수를 최우선으로 한다.",
    "",
    "작성 규칙:",
    "- market_summary는 2~3문장으로 작성하고, 원인·시장 반응·단기 관전 포인트를 모두 포함한다.",
    "- issue.summary는 사건 내용과 시장 영향을 함께 담아 충분히 설명한다.",
    "- overall_assessment 각 항목은 한 문장 이상으로 구체적으로 작성한다.",
    "- importance는 시장 파급력 기준으로 1, 2, 3 중 하나를 사용한다.",
    "- market_impact에서 관련 없는 자산군은 null로 둔다.",
    "- 문장은 간결하게 쓰되, 정보가 부족할 정도로 짧게 줄이지 않는다.",
    "- 가능하면 명사형 또는 짧은 명사구 중심으로 작성한다.",
    "출력 스키마:",
    "{",
    '  "market_summary": "string",',
    '  "issues": [',
    "    {",
    '      "id": "issue_1",',
    '      "title": "string",',
    '      "summary": "string",',
    '      "importance": 1,',
    '      "market_impact": {',
    '        "stocks": "string or null",',
    '        "bonds_rates": "string or null",',
    '        "fx": "string or null",',
    '        "crypto": "string or null"',
    "      },",
    '      "uncertainty": false',
    "    }",
    "  ],",
    '  "overall_assessment": {',
    '    "key_risk": "string",',
    '    "risk_assets": "string",',
    '    "safe_assets": "string"',
    "  }",
    "}",
    "",
    "입력 뉴스 데이터:",
    JSON.stringify(inputData),
  ].join("\n");
}

function extractOutputText(payload: any): string {
  if (!payload || typeof payload !== "object") {
    return "";
  }

  if (
    typeof payload.output_text === "string" &&
    payload.output_text.trim().length > 0
  ) {
    return payload.output_text.trim();
  }

  if (!Array.isArray(payload.output)) {
    return "";
  }

  const texts: string[] = [];

  for (const item of payload.output) {
    if (!item || typeof item !== "object") continue;

    if (item.type === "output_text" && typeof item.text === "string") {
      texts.push(item.text);
    }

    const contentList = Array.isArray(item.content) ? item.content : [];
    for (const content of contentList) {
      if (content?.type === "output_text" && typeof content.text === "string") {
        texts.push(content.text);
      }
    }
  }

  return texts.join("").trim();
}

function parseLikelyJsonObject(text: string): unknown {
  const trimmed = asString(text).trim();
  if (!trimmed) {
    throw new Error("OpenAI output_text is empty");
  }

  try {
    return JSON.parse(trimmed);
  } catch {
    const firstBrace = trimmed.indexOf("{");
    const lastBrace = trimmed.lastIndexOf("}");
    if (firstBrace < 0 || lastBrace <= firstBrace) {
      throw new Error("No JSON object boundaries found in output_text");
    }

    const candidate = trimmed.slice(firstBrace, lastBrace + 1);
    try {
      return JSON.parse(candidate);
    } catch (error) {
      throw new Error(
        `Failed to parse sanitized OpenAI JSON output: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }
}

function validateDigestShape(value: any): NewsDigest {
  if (!value || typeof value !== "object") {
    throw new Error("Invalid digest: root is not an object");
  }

  if (typeof value.market_summary !== "string") {
    throw new Error("Invalid digest: market_summary must be string");
  }

  if (!Array.isArray(value.issues)) {
    throw new Error("Invalid digest: issues must be array");
  }

  if (value.issues.length < 1 || value.issues.length > 5) {
    throw new Error("Invalid digest: issues length must be between 1 and 5");
  }

  if (
    !value.overall_assessment ||
    typeof value.overall_assessment !== "object" ||
    typeof value.overall_assessment.key_risk !== "string" ||
    typeof value.overall_assessment.risk_assets !== "string" ||
    typeof value.overall_assessment.safe_assets !== "string"
  ) {
    throw new Error("Invalid digest: overall_assessment shape mismatch");
  }

  const issues: Issue[] = value.issues.map((issue: any, index: number) => {
    if (!issue || typeof issue !== "object") {
      throw new Error(`Invalid digest: issues[${index}] is not object`);
    }

    const marketImpact = issue.market_impact;
    if (
      !marketImpact ||
      typeof marketImpact !== "object" ||
      !("stocks" in marketImpact) ||
      !("bonds_rates" in marketImpact) ||
      !("fx" in marketImpact) ||
      !("crypto" in marketImpact)
    ) {
      throw new Error(
        `Invalid digest: issues[${index}].market_impact shape mismatch`,
      );
    }

    const id = asString(issue.id).trim() || `issue_${index + 1}`;
    const title = sanitizeTitle(issue.title, index);
    const summary = sanitizeSummary(issue.summary);

    return {
      id,
      title,
      summary,
      importance: asImportance(issue.importance),
      market_impact: {
        stocks: marketImpact.stocks == null
          ? null
          : asString(marketImpact.stocks).trim(),
        bonds_rates: marketImpact.bonds_rates == null
          ? null
          : asString(marketImpact.bonds_rates).trim(),
        fx: marketImpact.fx == null ? null : asString(marketImpact.fx).trim(),
        crypto: marketImpact.crypto == null
          ? null
          : asString(marketImpact.crypto).trim(),
      },
      uncertainty: Boolean(issue.uncertainty),
    };
  });

  return {
    market_summary: sanitizeNarrative(
      cleanMarketSummary(value.market_summary),
      "핵심 이슈 요약이 충분하지 않아 시장 방향성 판단 근거가 제한적이다.",
    ),
    issues,
    overall_assessment: {
      key_risk: sanitizeNarrative(
        value.overall_assessment.key_risk,
        "핵심 리스크 정보가 부족해 단기 변동성 확대 가능성만 확인된다.",
      ),
      risk_assets: sanitizeNarrative(
        value.overall_assessment.risk_assets,
        "위험자산 영향 정보가 부족해 자산군별 민감도 판단이 제한적이다.",
      ),
      safe_assets: sanitizeNarrative(
        value.overall_assessment.safe_assets,
        "안전자산 선호 배경 정보가 부족해 방어 전략 가시성이 낮다.",
      ),
    },
  };
}

async function summarizeNews(
  newsRows: MarketNewsRow[],
  model: string,
): Promise<NewsDigest> {
  let lastError: unknown = null;
  for (let attempt = 1; attempt <= 2; attempt += 1) {
    try {
      return await summarizeNewsOnce(newsRows, model);
    } catch (error) {
      lastError = error;
      if (attempt === 2) {
        break;
      }
      console.warn(
        `[summarize-market-news] summarize attempt ${attempt} failed, retrying once: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  throw new Error(
    `Failed to summarize market news after retry: ${
      lastError instanceof Error ? lastError.message : String(lastError)
    }`,
  );
}

async function summarizeNewsOnce(
  newsRows: MarketNewsRow[],
  model: string,
): Promise<NewsDigest> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                "You are a precise financial-news structuring engine for gpt-5-mini. Output must be exactly one Korean JSON object that matches the provided schema.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: toPrompt(newsRows),
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "market_news_digest",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              market_summary: {
                type: "string",
              },
              issues: {
                type: "array",
                minItems: 1,
                maxItems: 5,
                items: {
                  type: "object",
                  additionalProperties: false,
                  properties: {
                    id: { type: "string" },
                    title: {
                      type: "string",
                    },
                    summary: {
                      type: "string",
                    },
                    importance: {
                      type: "integer",
                      enum: [1, 2, 3],
                    },
                    market_impact: {
                      type: "object",
                      additionalProperties: false,
                      properties: {
                        stocks: { type: ["string", "null"] },
                        bonds_rates: { type: ["string", "null"] },
                        fx: { type: ["string", "null"] },
                        crypto: { type: ["string", "null"] },
                      },
                      required: ["stocks", "bonds_rates", "fx", "crypto"],
                    },
                    uncertainty: { type: "boolean" },
                  },
                  required: [
                    "id",
                    "title",
                    "summary",
                    "importance",
                    "market_impact",
                    "uncertainty",
                  ],
                },
              },
              overall_assessment: {
                type: "object",
                additionalProperties: false,
                properties: {
                  key_risk: { type: "string" },
                  risk_assets: { type: "string" },
                  safe_assets: { type: "string" },
                },
                required: ["key_risk", "risk_assets", "safe_assets"],
              },
            },
            required: ["market_summary", "issues", "overall_assessment"],
          },
        },
      },
      max_output_tokens: OPENAI_MAX_OUTPUT_TOKENS,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI request failed: ${response.status} ${errorText}`);
  }

  const payload = await response.json();
  const payloadError = asRecord(payload).error;
  if (payloadError && typeof payloadError === "object") {
    const message = asString(asRecord(payloadError).message).trim() ||
      "unknown_error";
    throw new Error(`OpenAI response contained error: ${message}`);
  }

  const outputText = extractOutputText(payload);

  if (!outputText) {
    throw new Error("OpenAI response did not include output_text content");
  }

  const parsed = parseLikelyJsonObject(outputText);

  return validateDigestShape(parsed);
}

Deno.serve(async (req) => {
  try {
    requireEnv("SUPABASE_URL", SUPABASE_URL);
    requireEnv("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY);
    requireEnv("OPENAI_API_KEY", OPENAI_API_KEY);

    // 선택: cron/webhook 보호
    if (CRON_SECRET) {
      const authHeader = req.headers.get("authorization") ?? "";
      const expected = `Bearer ${CRON_SECRET}`;
      if (authHeader !== expected) {
        return jsonResponse({ ok: false, error: "Unauthorized" }, 401);
      }
    }

    const rawBody = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const body = asRecord(rawBody);
    const url = new URL(req.url);

    const category = asCategory(
      body.category ?? url.searchParams.get("category"),
    );
    const model = OPENAI_MODEL;

    const supabase = createClient<any>(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );

    const newsResponse = await supabase
      .from("market_news")
      .select("headline, summary, news_datetime")
      .eq("category", category)
      .order("news_datetime", { ascending: false });

    const loadErrorMessage = extractSupabaseErrorMessage(newsResponse);
    if (loadErrorMessage) {
      throw new Error(`Failed to load market news: ${loadErrorMessage}`);
    }

    const newsRows = Array.isArray(asRecord(newsResponse).data)
      ? (asRecord(newsResponse).data as MarketNewsRow[])
      : [];

    if (newsRows.length === 0) {
      const summary: NewsDigest = {
        market_summary: "요약할 마켓 뉴스가 없습니다.",
        issues: [],
        overall_assessment: {
          key_risk: "없음",
          risk_assets: "없음",
          safe_assets: "없음",
        },
      };

      await persistSummary({
        supabase,
        category,
        model,
        newsCount: 0,
        summary,
      });

      return jsonResponse({
        ok: true,
        category,
        model,
        news_count: 0,
        saved_to_db: true,
        summary,
      });
    }

    const summary = await summarizeNews(newsRows, model);

    await persistSummary({
      supabase,
      category,
      model,
      newsCount: newsRows.length,
      summary,
    });

    return jsonResponse({
      ok: true,
      category,
      model,
      news_count: newsRows.length,
      saved_to_db: true,
      summary,
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
