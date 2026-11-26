import assert from "node:assert/strict";
import {
  defaultCoinoneTickerTemplate,
  readCoinMarket,
} from "./coinone_market_data.ts";

const day = 86_400_000;

Deno.test("Coinone details return ticker and only the best bid and ask", async () => {
  const response = await readCoinMarket(
    "coin_details",
    { quote: "krw", symbol: "btc" },
    defaultCoinoneTickerTemplate,
    (url) => {
      assert.equal(url.hostname, "api.coinone.co.kr");
      assert.equal(url.pathname, "/public/v2/ticker_utc_new/KRW/BTC");
      assert.equal(url.searchParams.get("additional_data"), "true");
      return Promise.resolve({
        tickers: [{
          last: "100",
          yesterday_last: "95",
          target_volume: "0.102402",
          best_asks: [{ price: "102", qty: "0.25" }, { price: "103" }],
          best_bids: [{ price: "98", qty: "0.15", ignored: "value" }],
          ignored: true,
        }],
      });
    },
  );
  assert.deepEqual(await response.json(), {
    ok: true,
    tickers: [{
      last: "100",
      yesterday_last: "95",
      target_volume: "0.102402",
      best_asks: [{ price: "102", qty: "0.25" }],
      best_bids: [{ price: "98", qty: "0.15" }],
    }],
  });
});

Deno.test("Coinone daily closes page backwards across weekend UTC dates", async () => {
  const start = Date.UTC(2026, 11 - 1, 20);
  const through = start + 3 * day;
  let requests = 0;
  const response = await readCoinMarket(
    "coin_daily_closes",
    {
      quote: "KRW",
      symbol: "BTC",
      from: String(start),
      through: String(through),
    },
    defaultCoinoneTickerTemplate,
    (url) => {
      assert.equal(url.pathname, "/public/v2/chart/KRW/BTC");
      assert.equal(url.searchParams.get("interval"), "1d");
      if (++requests === 1) {
        assert.equal(url.searchParams.get("size"), "4");
        assert.equal(
          url.searchParams.get("timestamp"),
          String(through + day - 1),
        );
        return Promise.resolve({
          result: "success",
          is_last: false,
          chart: [
            { timestamp: through + day, close: "999" },
            { timestamp: through, close: "104" },
            { timestamp: start + 2 * day, close: "103" },
          ],
        });
      }
      assert.equal(url.searchParams.get("size"), "2");
      assert.equal(
        url.searchParams.get("timestamp"),
        String(start + 2 * day - 1),
      );
      return Promise.resolve({
        result: "success",
        is_last: true,
        chart: [
          { timestamp: start + day, close: "102" },
          { timestamp: start, close: "101" },
          { timestamp: start - day, close: "100" },
        ],
      });
    },
  );
  assert.equal(requests, 2);
  assert.deepEqual(await response.json(), {
    ok: true,
    closes: [101, 102, 103, 104].map((close, offset) => ({
      timestamp: start + offset * day,
      close,
    })),
  });
});

Deno.test("Coinone chart rejects the ongoing UTC day without an upstream request", async () => {
  const today = Math.floor(Date.now() / day) * day;
  const response = await readCoinMarket(
    "coin_daily_closes",
    {
      quote: "KRW",
      symbol: "BTC",
      from: String(today - day),
      through: String(today),
    },
    defaultCoinoneTickerTemplate,
    () => {
      throw new Error("Unexpected upstream request");
    },
  );
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, "invalid_date_range");
});
