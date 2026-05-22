import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-5-mini";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

const OPENAI_MAX_RETRIES = 1;
const MAX_TOP_HOLDINGS = 8;
const MAX_ASSET_CLASSES = 6;
const HISTORY_CACHE_WINDOW_MS = 48 * 60 * 60 * 1000;

type RiskLevel = "낮음" | "보통" | "높음";
type OverallStatus = "양호" | "주의" | "점검 필요";
type Severity = "low" | "medium" | "high";
type AnalysisSource = "openai_model";

type PortfolioDiagnosis = {
  summary: string;
  score: number;
  risk_level: RiskLevel;
  strengths: string[];
  weaknesses: string[];
  suggestions: string[];
  uncertainty: boolean;

  headline: string;
  overall_status: OverallStatus;
  diagnosis_scores: {
    diversification: number;
    cash_buffer: number;
    allocation_alignment: number;
    concentration: number;
  };
  top_findings: Array<{
    title: string;
    severity: Severity;
    detail: string;
  }>;
  actions: string[];
  tags: string[];
  analysis_source: AnalysisSource;
};

type OpenAIUsage = {
  input_tokens: number | null;
  output_tokens: number | null;
  total_tokens: number | null;
  reasoning_tokens: number | null;
  cached_input_tokens: number | null;
  usage_json: Record<string, unknown> | null;
};

type HistoryDiagnosisHit = {
  diagnosis: PortfolioDiagnosis;
  usage: OpenAIUsage;
  openai_request_id: string | null;
  openai_response_id: string | null;
  model: string;
  generated_at: string;
};

type NormalizedPortfolio = {
  base_currency: string;
  total_asset_value: number;
  total_return_rate: number;
  cash_weight: number;
  holding_count: number;
  asset_class_allocation: Array<{
    asset_class: string;
    weight: number;
  }>;
  top_holdings: Array<{
    symbol: string;
    name?: string;
    asset_type: string;
    market?: string;
    weight: number;
    return_rate: number;
    market_value?: number;
  }>;
  concentration_metrics: {
    top_1_weight: number;
    top_3_weight: number;
  };
  risk_flags: {
    high_crypto_weight: boolean;
    single_asset_concentration: boolean;
    low_cash_buffer: boolean;
    few_holdings: boolean;
  };
  performance_summary?: {
    best_holding?: {
      symbol: string;
      return_rate: number;
    };
    worst_holding?: {
      symbol: string;
      return_rate: number;
    };
  };
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...extraHeaders,
    },
  });
}

function asString(value: unknown, fallback = ""): string {
  if (typeof value === "string") return value;
  if (value == null) return fallback;
  return String(value);
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function asBoolean(value: unknown, fallback = false): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const v = value.trim().toLowerCase();
    if (v === "true") return true;
    if (v === "false") return false;
  }
  return fallback;
}

function asIntOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.round(value);
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return Math.round(parsed);
  }
  return null;
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

function clamp(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

function sanitizeShortText(
  value: unknown,
  fallback: string,
  maxLength: number,
): string {
  let text = asString(value).replace(/\s+/g, " ").trim();
  if (!text) return fallback;
  if (text.length > maxLength) {
    text = `${text.slice(0, Math.max(maxLength - 1, 1))}…`;
  }
  return text;
}

function sanitizeScore(value: unknown): number {
  return clamp(Math.round(asNumber(value, 60)), 0, 100);
}

function sanitizeTwoSentenceSummary(value: unknown): string {
  const text = sanitizeShortText(
    value,
    "포트폴리오 요약 정보를 충분히 생성하지 못했습니다.",
    240,
  );

  const parts = text
    .split(/(?<=[.!?。！？])\s+/)
    .map((item) => item.trim())
    .filter((item) => item.length > 0);

  if (parts.length <= 2) return text;
  return `${parts[0]} ${parts[1]}`.trim();
}

function asRiskLevel(value: unknown): RiskLevel {
  const normalized = asString(value).trim();
  if (normalized === "낮음") return "낮음";
  if (normalized === "높음") return "높음";
  return "보통";
}

function parseBearerToken(authHeader: string | null): string | null {
  if (!authHeader) return null;
  const matched = authHeader.match(/^Bearer\s+(.+)$/i);
  return matched?.[1]?.trim() || null;
}

function uniqueStrings(items: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const item of items) {
    const key = item.trim();
    if (!key) continue;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(key);
  }
  return result;
}

function looksLikeTickerOnly(text: string): boolean {
  const trimmed = text.trim();
  if (!trimmed) return false;
  return /^[A-Z0-9._-]{2,12}$/.test(trimmed);
}

function cleanUserFacingText(
  value: unknown,
  fallback = "",
  maxLength = 120,
): string {
  let text = sanitizeShortText(value, fallback, maxLength);

  text = text
    .replace(/\((?:리스크 플래그|risk flag|flag)[^)]*\)/gi, "")
    .replace(/\blow_cash_buffer\b/gi, "")
    .replace(/\bhigh_crypto_weight\b/gi, "")
    .replace(/\bsingle_asset_concentration\b/gi, "")
    .replace(/\bfew_holdings\b/gi, "")
    .replace(/\btrue\b/gi, "")
    .replace(/\bfalse\b/gi, "")
    .replace(/\s{2,}/g, " ")
    .trim();

  if (looksLikeTickerOnly(text)) {
    return fallback || "세부 자산 설명이 충분하지 않습니다.";
  }

  return text || fallback;
}

function sanitizeStringArray(
  value: unknown,
  fallback: string[],
  minItems = 2,
  maxItems = 3,
  itemMaxLength = 120,
): string[] {
  if (!Array.isArray(value)) return fallback.slice(0, maxItems);

  const items = uniqueStrings(
    value
      .map((item) => cleanUserFacingText(item, "", itemMaxLength))
      .filter((item) => item.length > 0),
  ).slice(0, maxItems);

  if (items.length < minItems) {
    return uniqueStrings(
      fallback
        .map((item) => cleanUserFacingText(item, "", itemMaxLength))
        .filter((item) => item.length > 0),
    ).slice(0, maxItems);
  }

  return items;
}

function headlineFromSummary(summary: string): string {
  const firstSentence = summary
    .split(/(?<=[.!?。！？])\s+/)
    .map((item) => item.trim())
    .find((item) => item.length > 0) ?? summary;

  return sanitizeShortText(firstSentence, "포트폴리오 점검 결과", 90);
}

async function authenticateUser(req: Request): Promise<{ userId: string }> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    throw new Error("Missing Supabase env for auth verification");
  }

  const token = parseBearerToken(req.headers.get("Authorization"));
  if (!token) {
    throw new Response(
      JSON.stringify({ ok: false, error: "Unauthorized" }),
      {
        status: 401,
        headers: { "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }

  const supabase = createClient<any>(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    throw new Response(
      JSON.stringify({ ok: false, error: "Unauthorized" }),
      {
        status: 401,
        headers: { "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }

  return { userId: data.user.id };
}

function createAdminClient() {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return null;
  }

  return createClient<any>(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

function normalizePortfolio(
  input: Record<string, unknown>,
): NormalizedPortfolio {
  const root = input.portfolio && typeof input.portfolio === "object"
    ? input.portfolio as Record<string, unknown>
    : input;

  const baseCurrency = sanitizeShortText(root.base_currency, "KRW", 10)
    .toUpperCase();

  const totalAssetValue = round2(asNumber(root.total_asset_value, 0));
  const totalReturnRate = round2(asNumber(root.total_return_rate, 0));
  const cashWeight = clamp(round2(asNumber(root.cash_weight, 0)), 0, 100);
  const holdingCount = Math.max(0, Math.round(asNumber(root.holding_count, 0)));

  const assetClassAllocationRaw = Array.isArray(root.asset_class_allocation)
    ? root.asset_class_allocation
    : [];

  const assetClassAllocation = assetClassAllocationRaw
    .filter((row) => row && typeof row === "object")
    .map((row) => {
      const item = row as Record<string, unknown>;
      return {
        asset_class: sanitizeShortText(item.asset_class, "unknown", 32),
        weight: clamp(round2(asNumber(item.weight, 0)), 0, 100),
      };
    })
    .filter((row) => row.asset_class.length > 0 && row.weight > 0)
    .sort((a, b) => b.weight - a.weight)
    .slice(0, MAX_ASSET_CLASSES);

  const topHoldingsRaw = Array.isArray(root.top_holdings)
    ? root.top_holdings
    : [];

  const topHoldings = topHoldingsRaw
    .filter((row) => row && typeof row === "object")
    .map((row) => {
      const item = row as Record<string, unknown>;
      return {
        symbol: sanitizeShortText(item.symbol, "UNKNOWN", 24),
        name: sanitizeShortText(item.name, "", 60) || undefined,
        asset_type: sanitizeShortText(item.asset_type, "unknown", 24),
        market: sanitizeShortText(item.market, "", 24) || undefined,
        weight: clamp(round2(asNumber(item.weight, 0)), 0, 100),
        return_rate: round2(asNumber(item.return_rate, 0)),
        market_value: round2(asNumber(item.market_value, 0)) || undefined,
      };
    })
    .filter((row) => row.symbol.length > 0)
    .sort((a, b) => b.weight - a.weight)
    .slice(0, MAX_TOP_HOLDINGS);

  const concentrationRaw = root.concentration_metrics &&
      typeof root.concentration_metrics === "object"
    ? root.concentration_metrics as Record<string, unknown>
    : {};

  const derivedTop1 = topHoldings[0]?.weight ?? 0;
  const derivedTop3 = round2(
    topHoldings.slice(0, 3).reduce((sum, item) => sum + item.weight, 0),
  );

  const concentrationMetrics = {
    top_1_weight: clamp(
      round2(asNumber(concentrationRaw.top_1_weight, derivedTop1)),
      0,
      100,
    ),
    top_3_weight: clamp(
      round2(asNumber(concentrationRaw.top_3_weight, derivedTop3)),
      0,
      100,
    ),
  };

  const riskFlagsRaw = root.risk_flags && typeof root.risk_flags === "object"
    ? root.risk_flags as Record<string, unknown>
    : {};

  const cryptoWeight = assetClassAllocation
    .filter((row) => row.asset_class.toLowerCase().includes("crypto"))
    .reduce((sum, row) => sum + row.weight, 0);

  const riskFlags = {
    high_crypto_weight: asBoolean(
      riskFlagsRaw.high_crypto_weight,
      cryptoWeight >= 20,
    ),
    single_asset_concentration: asBoolean(
      riskFlagsRaw.single_asset_concentration,
      concentrationMetrics.top_1_weight >= 35,
    ),
    low_cash_buffer: asBoolean(riskFlagsRaw.low_cash_buffer, cashWeight < 10),
    few_holdings: asBoolean(
      riskFlagsRaw.few_holdings,
      holdingCount > 0 && holdingCount < 5,
    ),
  };

  const performanceSummaryRaw = root.performance_summary &&
      typeof root.performance_summary === "object"
    ? root.performance_summary as Record<string, unknown>
    : {};

  const bestHoldingRaw = performanceSummaryRaw.best_holding &&
      typeof performanceSummaryRaw.best_holding === "object"
    ? performanceSummaryRaw.best_holding as Record<string, unknown>
    : null;

  const worstHoldingRaw = performanceSummaryRaw.worst_holding &&
      typeof performanceSummaryRaw.worst_holding === "object"
    ? performanceSummaryRaw.worst_holding as Record<string, unknown>
    : null;

  const performance_summary = (bestHoldingRaw || worstHoldingRaw)
    ? {
      best_holding: bestHoldingRaw
        ? {
          symbol: sanitizeShortText(bestHoldingRaw.symbol, "UNKNOWN", 24),
          return_rate: round2(asNumber(bestHoldingRaw.return_rate, 0)),
        }
        : undefined,
      worst_holding: worstHoldingRaw
        ? {
          symbol: sanitizeShortText(worstHoldingRaw.symbol, "UNKNOWN", 24),
          return_rate: round2(asNumber(worstHoldingRaw.return_rate, 0)),
        }
        : undefined,
    }
    : undefined;

  return {
    base_currency: baseCurrency,
    total_asset_value: totalAssetValue,
    total_return_rate: totalReturnRate,
    cash_weight: cashWeight,
    holding_count: holdingCount,
    asset_class_allocation: assetClassAllocation,
    top_holdings: topHoldings,
    concentration_metrics: concentrationMetrics,
    risk_flags: riskFlags,
    performance_summary,
  };
}

function buildPrompt(portfolio: NormalizedPortfolio): string {
  return [
    "한국어 JSON만 출력. 입력 데이터 밖의 추측 금지.",
    "summary는 2문장 이하.",
    "strengths/weaknesses/suggestions는 각 2~3개, 각 항목은 1문장으로 짧게 작성.",
    "과장/투자권유/디버그성 문구 금지.",
    "[portfolio]",
    JSON.stringify(portfolio),
  ].join("\n");
}

function computeRuleScores(portfolio: NormalizedPortfolio) {
  const diversificationBase = (() => {
    const count =
      portfolio.asset_class_allocation.filter((x) => x.weight > 0).length;
    if (count >= 4) return 86;
    if (count === 3) return 74;
    if (count === 2) return 58;
    if (count === 1) return 38;
    return 50;
  })();

  const cashBufferBase = (() => {
    const cash = portfolio.cash_weight;
    if (cash >= 10 && cash <= 30) return 84;
    if (cash > 30 && cash <= 45) return 72;
    if (cash >= 5 && cash < 10) return 58;
    if (cash > 45) return 55;
    return 40;
  })();

  const concentrationBase = (() => {
    const top1 = portfolio.concentration_metrics.top_1_weight;
    const top3 = portfolio.concentration_metrics.top_3_weight;

    let score = 88;

    if (top1 >= 35) score -= 22;
    else if (top1 >= 25) score -= 10;

    if (top3 >= 70) score -= 16;
    else if (top3 >= 55) score -= 8;
    else if (top3 >= 45) score -= 4;

    return clamp(score, 0, 100);
  })();

  const allocationAlignmentBase = (() => {
    let score = 78;
    if (portfolio.risk_flags.high_crypto_weight) score -= 14;
    if (portfolio.risk_flags.low_cash_buffer) score -= 10;
    if (portfolio.risk_flags.few_holdings) score -= 8;
    if (portfolio.total_return_rate < 0) score -= 6;
    return clamp(score, 0, 100);
  })();

  return {
    diversification: diversificationBase,
    cash_buffer: cashBufferBase,
    concentration: concentrationBase,
    allocation_alignment: allocationAlignmentBase,
  };
}

function deriveOverallStatus(riskLevel: RiskLevel): OverallStatus {
  if (riskLevel === "낮음") return "양호";
  if (riskLevel === "높음") return "점검 필요";
  return "주의";
}

function deriveSeverity(riskLevel: RiskLevel): Severity {
  if (riskLevel === "낮음") return "low";
  if (riskLevel === "높음") return "high";
  return "medium";
}

function deriveUncertainty(
  portfolio: NormalizedPortfolio,
  proposed: boolean,
): boolean {
  const insufficient = portfolio.holding_count < 3 ||
    portfolio.asset_class_allocation.length < 2 ||
    portfolio.top_holdings.length < 2 ||
    portfolio.total_asset_value <= 0;

  if (insufficient) return true;
  return proposed;
}

function buildTopFindings(
  weaknesses: string[],
  riskLevel: RiskLevel,
): Array<{ title: string; severity: Severity; detail: string }> {
  const severity = deriveSeverity(riskLevel);
  return weaknesses.slice(0, 3).map((item, index) => ({
    title: `점검 포인트 ${index + 1}`,
    severity,
    detail: cleanUserFacingText(item, "세부 설명이 없습니다.", 220),
  }));
}

function buildTags(
  riskLevel: RiskLevel,
  uncertainty: boolean,
  analysisSource: AnalysisSource,
): string[] {
  return uniqueStrings([
    riskLevel,
    ...(uncertainty ? ["불확실성 주의"] : []),
    analysisSource === "openai_model" ? "AI 분석" : "기본 분석",
    "포트폴리오 진단",
  ]).slice(0, 5);
}

function validateDiagnosisShape(
  value: unknown,
  portfolio: NormalizedPortfolio,
  analysisSource: AnalysisSource,
): PortfolioDiagnosis {
  if (!value || typeof value !== "object") {
    throw new Error("Invalid diagnosis: root object required");
  }

  const root = value as Record<string, unknown>;
  const summary = sanitizeTwoSentenceSummary(root.summary);
  const score = sanitizeScore(root.score);
  const riskLevel = asRiskLevel(root.risk_level);

  const strengths = sanitizeStringArray(root.strengths, [
    "자산군이 완전히 한쪽으로만 몰려 있지는 않습니다.",
    "현재 보유 구조를 기준으로 핵심 점검 포인트를 비교적 명확하게 확인할 수 있습니다.",
  ]);

  const weaknesses = sanitizeStringArray(root.weaknesses, [
    "상위 자산 비중이 높으면 특정 자산 변동의 영향이 커질 수 있습니다.",
    "현금 비중과 자산군 배분을 함께 점검할 필요가 있습니다.",
  ]);

  const suggestions = sanitizeStringArray(root.suggestions, [
    "상위 자산 비중과 목표 비중의 차이를 정기적으로 점검하세요.",
    "변동성이 큰 자산 비중을 유지할 때는 현금 완충 여력도 함께 관리하세요.",
  ]);

  const proposedUncertainty = typeof root.uncertainty === "boolean"
    ? root.uncertainty
    : false;
  const uncertainty = deriveUncertainty(portfolio, proposedUncertainty);

  const overallStatus = deriveOverallStatus(riskLevel);
  const diagnosisScores = computeRuleScores(portfolio);

  return {
    summary,
    score,
    risk_level: riskLevel,
    strengths,
    weaknesses,
    suggestions,
    uncertainty,
    headline: headlineFromSummary(summary),
    overall_status: overallStatus,
    diagnosis_scores: diagnosisScores,
    top_findings: buildTopFindings(weaknesses, riskLevel),
    actions: suggestions.slice(0, 3),
    tags: buildTags(riskLevel, uncertainty, analysisSource),
    analysis_source: analysisSource,
  };
}

async function callOpenAIWithRetry(
  body: Record<string, unknown>,
): Promise<any> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= OPENAI_MAX_RETRIES; attempt++) {
    try {
      const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify(body),
      });

      if (response.ok) {
        const data = await response.json();
        const requestId = response.headers.get("x-request-id") ??
          response.headers.get("openai-request-id") ??
          "";
        if (data && typeof data === "object") {
          (data as Record<string, unknown>)._debug_openai_request_id =
            requestId;
        }
        return data;
      }

      const errorText = await response.text();
      const compactErrorText = errorText.replace(/\s+/g, " ").trim();
      const requestId = response.headers.get("x-request-id") ??
        response.headers.get("openai-request-id") ??
        "";

      if (
        attempt < OPENAI_MAX_RETRIES &&
        [408, 409, 429, 500, 502, 503, 504].includes(response.status)
      ) {
        await new Promise((resolve) =>
          setTimeout(resolve, 700 * (attempt + 1))
        );
        continue;
      }

      throw new Error(
        `OpenAI request failed: ${response.status} ${compactErrorText} (openai_request_id=${requestId})`,
      );
    } catch (error) {
      const base = error instanceof Error ? error : new Error(String(error));
      lastError = new Error(`OpenAI network/runtime error: ${base.message}`);

      if (attempt < OPENAI_MAX_RETRIES) {
        await new Promise((resolve) =>
          setTimeout(resolve, 700 * (attempt + 1))
        );
        continue;
      }

      throw lastError;
    }
  }

  throw lastError ?? new Error("Unknown OpenAI error");
}

function tryParseJson(text: string): unknown | null {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function stripCodeFence(text: string): string {
  return text
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();
}

function extractStructuredOutput(payload: any): unknown {
  if (payload?.output_parsed && typeof payload.output_parsed === "object") {
    return payload.output_parsed;
  }

  const candidates: string[] = [];

  if (typeof payload?.output_text === "string" && payload.output_text.trim()) {
    candidates.push(payload.output_text.trim());
  }

  if (Array.isArray(payload?.output)) {
    for (const item of payload.output) {
      if (!item || typeof item !== "object") continue;

      if (typeof item.text === "string" && item.text.trim()) {
        candidates.push(item.text.trim());
      }

      if (Array.isArray(item.content)) {
        for (const contentItem of item.content) {
          if (!contentItem || typeof contentItem !== "object") continue;

          if (typeof contentItem.text === "string" && contentItem.text.trim()) {
            candidates.push(contentItem.text.trim());
          } else if (
            contentItem.text &&
            typeof contentItem.text === "object" &&
            typeof contentItem.text.value === "string" &&
            contentItem.text.value.trim()
          ) {
            candidates.push(contentItem.text.value.trim());
          }
        }
      }
    }
  }

  for (const text of candidates) {
    const direct = tryParseJson(text);
    if (direct && typeof direct === "object") return direct;

    const stripped = stripCodeFence(text);
    const fromCodeFence = tryParseJson(stripped);
    if (fromCodeFence && typeof fromCodeFence === "object") {
      return fromCodeFence;
    }
  }

  const outputItems = Array.isArray(payload?.output)
    ? payload.output.length
    : 0;
  const firstOutput =
    Array.isArray(payload?.output) && payload.output.length > 0
      ? payload.output[0]
      : null;
  const firstContentType =
    Array.isArray(firstOutput?.content) && firstOutput.content.length > 0
      ? String(firstOutput.content[0]?.type ?? "")
      : "";
  const status = String(payload?.status ?? "");
  const incompleteReason = String(payload?.incomplete_details?.reason ?? "");
  const refusal = typeof firstOutput?.refusal === "string"
    ? firstOutput.refusal
    : "";

  throw new Error(
    `OpenAI response did not include parseable structured output (status=${status}, output_items=${outputItems}, first_content_type=${firstContentType}, incomplete_reason=${incompleteReason}, refusal=${refusal})`,
  );
}

function extractUsage(payload: any): OpenAIUsage {
  const usageRaw = payload?.usage && typeof payload.usage === "object"
    ? payload.usage as Record<string, unknown>
    : null;

  if (!usageRaw) {
    return {
      input_tokens: null,
      output_tokens: null,
      total_tokens: null,
      reasoning_tokens: null,
      cached_input_tokens: null,
      usage_json: null,
    };
  }

  const inputTokens = asIntOrNull(usageRaw.input_tokens);
  const outputTokens = asIntOrNull(usageRaw.output_tokens);
  const totalTokens = asIntOrNull(usageRaw.total_tokens);

  const outputDetails = usageRaw.output_tokens_details &&
      typeof usageRaw.output_tokens_details === "object"
    ? usageRaw.output_tokens_details as Record<string, unknown>
    : null;

  const inputDetails = usageRaw.input_tokens_details &&
      typeof usageRaw.input_tokens_details === "object"
    ? usageRaw.input_tokens_details as Record<string, unknown>
    : null;

  const reasoningTokens = outputDetails
    ? asIntOrNull(outputDetails.reasoning_tokens)
    : null;

  const cachedInputTokens = inputDetails
    ? asIntOrNull(inputDetails.cached_tokens)
    : null;

  return {
    input_tokens: inputTokens,
    output_tokens: outputTokens,
    total_tokens: totalTokens,
    reasoning_tokens: reasoningTokens,
    cached_input_tokens: cachedInputTokens,
    usage_json: usageRaw,
  };
}

async function generateDiagnosis(
  portfolio: NormalizedPortfolio,
): Promise<{
  diagnosis: PortfolioDiagnosis;
  usage: OpenAIUsage;
  openai_request_id: string | null;
  openai_response_id: string | null;
}> {
  if (!OPENAI_API_KEY) {
    throw new Error("Missing env: OPENAI_API_KEY");
  }

  const payload = await callOpenAIWithRetry({
    model: OPENAI_MODEL,
    store: false,
    reasoning: { effort: "low" },
    max_output_tokens: 3200,
    input: buildPrompt(portfolio),
    text: {
      format: {
        type: "json_schema",
        name: "portfolio_diagnosis",
        strict: true,
        schema: {
          type: "object",
          additionalProperties: false,
          properties: {
            summary: { type: "string", minLength: 10, maxLength: 240 },
            score: { type: "integer", minimum: 0, maximum: 100 },
            risk_level: {
              type: "string",
              enum: ["낮음", "보통", "높음"],
            },
            strengths: {
              type: "array",
              minItems: 2,
              maxItems: 3,
              items: { type: "string", minLength: 8, maxLength: 120 },
            },
            weaknesses: {
              type: "array",
              minItems: 2,
              maxItems: 3,
              items: { type: "string", minLength: 8, maxLength: 120 },
            },
            suggestions: {
              type: "array",
              minItems: 2,
              maxItems: 3,
              items: { type: "string", minLength: 8, maxLength: 120 },
            },
            uncertainty: { type: "boolean" },
          },
          required: [
            "summary",
            "score",
            "risk_level",
            "strengths",
            "weaknesses",
            "suggestions",
            "uncertainty",
          ],
        },
      },
    },
  });

  const parsed = extractStructuredOutput(payload);
  const usage = extractUsage(payload);

  const openaiRequestId =
    typeof payload?._debug_openai_request_id === "string" &&
      payload._debug_openai_request_id.trim()
      ? payload._debug_openai_request_id.trim()
      : null;

  const openaiResponseId = typeof payload?.id === "string" && payload.id.trim()
    ? payload.id.trim()
    : null;

  return {
    diagnosis: validateDiagnosisShape(parsed, portfolio, "openai_model"),
    usage,
    openai_request_id: openaiRequestId,
    openai_response_id: openaiResponseId,
  };
}

async function persistDiagnosisHistory(params: {
  userId: string;
  model: string;
  normalizedPortfolio: NormalizedPortfolio;
  diagnosis: PortfolioDiagnosis;
  usage: OpenAIUsage;
  openaiRequestId: string | null;
  openaiResponseId: string | null;
  usedFallback: boolean;
  aiError: string | null;
}) {
  const admin = createAdminClient();
  if (!admin) {
    console.warn("[persistDiagnosisHistory] skipped: missing service-role env");
    return;
  }

  const { error } = await admin.from("portfolio_diagnosis_history").upsert(
    {
      user_id: params.userId,
      model: params.model,
      analysis_source: params.diagnosis.analysis_source,
      used_fallback: params.usedFallback,
      ai_error: params.aiError,
      score: params.diagnosis.score,
      risk_level: params.diagnosis.risk_level,
      summary: params.diagnosis.summary,
      input_tokens: params.usage.input_tokens,
      output_tokens: params.usage.output_tokens,
      total_tokens: params.usage.total_tokens,
      reasoning_tokens: params.usage.reasoning_tokens,
      cached_input_tokens: params.usage.cached_input_tokens,
      usage_json: params.usage.usage_json,
      openai_request_id: params.openaiRequestId,
      openai_response_id: params.openaiResponseId,
      normalized_portfolio: params.normalizedPortfolio,
      diagnosis_json: params.diagnosis,
      created_at: new Date().toISOString(),
    },
    {
      onConflict: "user_id",
    },
  );

  if (error) {
    throw new Error(`Failed to persist diagnosis history: ${error.message}`);
  }
}

async function fetchRecentDiagnosisHistory(params: {
  userId: string;
  normalizedPortfolio: NormalizedPortfolio;
}): Promise<HistoryDiagnosisHit | null> {
  const admin = createAdminClient();
  if (!admin) return null;

  const fromIso = new Date(Date.now() - HISTORY_CACHE_WINDOW_MS).toISOString();

  const { data, error } = await admin
    .from("portfolio_diagnosis_history")
    .select(
      "model, created_at, diagnosis_json, input_tokens, output_tokens, total_tokens, reasoning_tokens, cached_input_tokens, usage_json, openai_request_id, openai_response_id",
    )
    .eq("user_id", params.userId)
    .gte("created_at", fromIso)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to fetch diagnosis history: ${error.message}`);
  }
  if (!data || typeof data !== "object") return null;
  if (!data.diagnosis_json || typeof data.diagnosis_json !== "object") {
    return null;
  }

  const diagnosis = validateDiagnosisShape(
    data.diagnosis_json,
    params.normalizedPortfolio,
    "openai_model",
  );

  const usage: OpenAIUsage = {
    input_tokens: asIntOrNull(data.input_tokens),
    output_tokens: asIntOrNull(data.output_tokens),
    total_tokens: asIntOrNull(data.total_tokens),
    reasoning_tokens: asIntOrNull(data.reasoning_tokens),
    cached_input_tokens: asIntOrNull(data.cached_input_tokens),
    usage_json: data.usage_json && typeof data.usage_json === "object"
      ? data.usage_json as Record<string, unknown>
      : null,
  };

  return {
    diagnosis,
    usage,
    openai_request_id: typeof data.openai_request_id === "string" &&
        data.openai_request_id.trim()
      ? data.openai_request_id
      : null,
    openai_response_id: typeof data.openai_response_id === "string" &&
        data.openai_response_id.trim()
      ? data.openai_response_id
      : null,
    model: typeof data.model === "string" && data.model.trim()
      ? data.model
      : OPENAI_MODEL,
    generated_at: typeof data.created_at === "string" && data.created_at.trim()
      ? data.created_at
      : new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse({ ok: false, error: "Method not allowed" }, 405);
    }

    let userId = "";
    try {
      const auth = await authenticateUser(req);
      userId = auth.userId;
    } catch (error) {
      if (error instanceof Response) return error;
      console.error("[auth] unexpected error:", error);
      return jsonResponse({ ok: false, error: "Unauthorized" }, 401);
    }

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return jsonResponse({ ok: false, error: "Invalid JSON body" }, 400);
    }

    const root = body as Record<string, unknown>;
    if (!root.portfolio || typeof root.portfolio !== "object") {
      return jsonResponse(
        { ok: false, error: "Missing required body: portfolio(object)" },
        400,
      );
    }

    const normalizedPortfolio = normalizePortfolio(
      root.portfolio as Record<string, unknown>,
    );

    const hasSufficientData = normalizedPortfolio.total_asset_value > 0 &&
      normalizedPortfolio.holding_count > 0 &&
      normalizedPortfolio.top_holdings.length > 0;

    if (!hasSufficientData) {
      return jsonResponse({
        ok: false,
        error: "Portfolio data is insufficient for model analysis",
        meta: {
          total_asset_value: normalizedPortfolio.total_asset_value,
          holding_count: normalizedPortfolio.holding_count,
          top_holdings_count: normalizedPortfolio.top_holdings.length,
        },
      }, 400);
    }

    try {
      const historyHit = await fetchRecentDiagnosisHistory({
        userId,
        normalizedPortfolio,
      });
      if (historyHit) {
        return jsonResponse({
          ok: true,
          model: historyHit.model,
          diagnosis: historyHit.diagnosis,
          generated_at: historyHit.generated_at,
          meta: {
            user_id: userId,
            analysis_source: historyHit.diagnosis.analysis_source,
            usage: historyHit.usage,
            openai_request_id: historyHit.openai_request_id,
            openai_response_id: historyHit.openai_response_id,
            used_fallback: false,
            cache_hit: true,
            cache_window_hours: 48,
          },
        });
      }
    } catch (historyError) {
      console.error("[fetchRecentDiagnosisHistory] failed:", historyError);
    }

    let diagnosis: PortfolioDiagnosis;
    let usage: OpenAIUsage;
    let openaiRequestId: string | null;
    let openaiResponseId: string | null;

    try {
      const generated = await generateDiagnosis(normalizedPortfolio);
      diagnosis = generated.diagnosis;
      usage = generated.usage;
      openaiRequestId = generated.openai_request_id;
      openaiResponseId = generated.openai_response_id;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const isMissingKey = message.includes("Missing env: OPENAI_API_KEY");
      const isOpenAIHttp = message.includes("OpenAI request failed:");
      const isOpenAINetwork = message.includes("OpenAI network/runtime error:");
      const failureStage = isMissingKey
        ? "preflight_env"
        : isOpenAIHttp
        ? "openai_http"
        : isOpenAINetwork
        ? "openai_network"
        : "postprocess_or_unknown";
      console.error("[generateDiagnosis] failed", {
        model: OPENAI_MODEL,
        failure_stage: failureStage,
        openai_key_present: OPENAI_API_KEY.length > 0,
        openai_key_length: OPENAI_API_KEY.length,
        ai_error: message,
      });
      return jsonResponse(
        {
          ok: false,
          error: "AI diagnosis generation failed",
          meta: {
            ai_error: message,
            model: OPENAI_MODEL,
            openai_key_present: OPENAI_API_KEY.length > 0,
            openai_key_length: OPENAI_API_KEY.length,
            failure_stage: failureStage,
          },
        },
        502,
        {
          "x-diagnosis-failure-stage": failureStage,
          "x-openai-key-present": OPENAI_API_KEY.length > 0 ? "true" : "false",
          "x-openai-model": OPENAI_MODEL,
        },
      );
    }

    try {
      await persistDiagnosisHistory({
        userId,
        model: OPENAI_MODEL,
        normalizedPortfolio,
        diagnosis,
        usage,
        openaiRequestId,
        openaiResponseId,
        usedFallback: false,
        aiError: null,
      });
    } catch (persistError) {
      console.error("[persistDiagnosisHistory] failed:", persistError);
    }

    return jsonResponse({
      ok: true,
      model: OPENAI_MODEL,
      diagnosis,
      generated_at: new Date().toISOString(),
      meta: {
        user_id: userId,
        analysis_source: diagnosis.analysis_source,
        usage,
        openai_request_id: openaiRequestId,
        openai_response_id: openaiResponseId,
        used_fallback: false,
        cache_hit: false,
        cache_window_hours: 48,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("[fatal]", message);
    return jsonResponse({ ok: false, error: "Internal server error" }, 500);
  }
});
