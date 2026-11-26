const day = 86_400_000;
const chartPageSize = 500;

type CoinMarketMode = "coin_details" | "coin_daily_closes";
type CoinRead = (url: URL) => Promise<Record<string, unknown>>;

export const defaultCoinoneTickerTemplate =
  "https://api.coinone.co.kr/public/v2/ticker_utc_new/{quote}/{symbol}?additional_data=true";

export function isCoinMarketMode(value: unknown): value is CoinMarketMode {
  return value === "coin_details" || value === "coin_daily_closes";
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function fields(row: Record<string, unknown>, names: string[]) {
  return Object.fromEntries(
    names.filter((name) =>
      typeof row[name] === "string" || typeof row[name] === "number"
    ).map((name) => [name, row[name]]),
  );
}

async function readCoinone(url: URL) {
  const response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  if (!response.ok) throw new Error(`Coinone returned HTTP ${response.status}`);
  const data = record(await response.json());
  if (!data) throw new Error("Invalid Coinone response");
  return data;
}

export async function fetchCoinoneTicker(
  template: string,
  quote: string,
  symbol: string,
  read: CoinRead = readCoinone,
) {
  if (!/^[A-Z0-9]{2,10}$/.test(quote) || !/^[A-Z0-9]{1,20}$/.test(symbol)) {
    return null;
  }
  const url = new URL(
    template.replaceAll("{quote}", quote).replaceAll("{symbol}", symbol),
  );
  const response = await read(url);
  return Array.isArray(response.tickers) ? record(response.tickers[0]) : null;
}

function utcDate(value: unknown): number | null {
  if (typeof value !== "string" || !/^\d{1,13}$/.test(value)) return null;
  const timestamp = Number(value);
  return timestamp % day === 0 ? timestamp : null;
}

async function fetchCoinoneDailyCloses(
  quote: string,
  symbol: string,
  from: number,
  through: number,
  read: CoinRead,
) {
  const closes = new Map<number, number>();
  const url = new URL(
    `https://api.coinone.co.kr/public/v2/chart/${quote}/${symbol}`,
  );
  url.searchParams.set("interval", "1d");

  let cursor = through;
  for (let page = 0; cursor >= from; page++) {
    if (page >= 12) throw new Error("Coinone chart pagination did not finish");
    url.searchParams.set("timestamp", String(cursor + day - 1));
    url.searchParams.set(
      "size",
      String(Math.min(chartPageSize, (cursor - from) / day + 1)),
    );
    const data = await read(url);
    if (data.result !== "success" || !Array.isArray(data.chart)) {
      throw new Error("Coinone chart is unavailable");
    }
    if (data.chart.length === 0) break;

    let oldest = Number.POSITIVE_INFINITY;
    for (const candle of data.chart) {
      const row = record(candle);
      const timestamp = row?.timestamp;
      if (
        typeof timestamp !== "number" || !Number.isSafeInteger(timestamp) ||
        timestamp < 0 || timestamp % day !== 0 || timestamp > cursor
      ) {
        continue;
      }
      oldest = Math.min(oldest, timestamp);
      const close = row?.close;
      const price = typeof close === "string" || typeof close === "number"
        ? Number(close)
        : NaN;
      if (timestamp >= from && Number.isFinite(price) && price > 0) {
        closes.set(timestamp, price);
      }
    }
    if (!Number.isFinite(oldest)) {
      throw new Error("Coinone chart did not advance");
    }
    if (data.is_last === true) break;
    cursor = oldest - day;
  }
  return [...closes].sort(([a], [b]) => a - b).map(([timestamp, close]) => ({
    timestamp,
    close,
  }));
}

export async function readCoinMarket(
  mode: CoinMarketMode,
  body: Record<string, unknown>,
  template: string,
  read: CoinRead = readCoinone,
) {
  const symbol = typeof body.symbol === "string"
    ? body.symbol.trim().toUpperCase()
    : "";
  const quote = typeof body.quote === "string"
    ? body.quote.trim().toUpperCase()
    : "";
  if (
    !/^[A-Z0-9]{2,10}$/.test(quote) || !/^[A-Z0-9]{1,20}$/.test(symbol) ||
    quote === symbol
  ) {
    return Response.json({ ok: false, error: "invalid_instrument" }, {
      status: 400,
    });
  }

  if (mode === "coin_daily_closes") {
    const from = utcDate(body.from);
    const through = utcDate(body.through);
    const today = Math.floor(Date.now() / day) * day;
    if (
      from === null || through === null || through < from ||
      through - from > 3_660 * day || through >= today
    ) {
      return Response.json({ ok: false, error: "invalid_date_range" }, {
        status: 400,
      });
    }
    const closes = await fetchCoinoneDailyCloses(
      quote,
      symbol,
      from,
      through,
      read,
    );
    return Response.json({ ok: true, closes });
  }

  const ticker = await fetchCoinoneTicker(template, quote, symbol, read);
  if (!ticker) return Response.json({ ok: true, tickers: [] });
  const bestOrder = (value: unknown) => {
    const order = Array.isArray(value) ? record(value[0]) : null;
    return order ? [fields(order, ["price", "qty"])] : [];
  };
  return Response.json({
    ok: true,
    tickers: [{
      ...fields(ticker, [
        "last",
        "first",
        "high",
        "low",
        "yesterday_last",
        "quote_currency",
        "target_currency",
        "quote_volume",
        "target_volume",
      ]),
      best_asks: bestOrder(ticker.best_asks),
      best_bids: bestOrder(ticker.best_bids),
    }],
  });
}
