import assert from "node:assert/strict";
import { readMarketDetail } from "./kis_market_details.ts";

const endpoints = {
  domestic: {
    path: "/uapi/domestic-stock/v1/quotations/inquire-price",
    trId: "FHKST01010100",
  },
  overseas: {
    path: "/uapi/overseas-price/v1/quotations/price-detail",
    trId: "HHDFS76200200",
  },
  fund: {
    path: "/uapi/etfetn/v1/quotations/inquire-price",
    trId: "FHPST02400000",
  },
  componentScreenCode: "11216",
};

Deno.test("daily closes use the specified exchange and return only date and close", async () => {
  const response = await readMarketDetail(
    "daily_closes",
    { symbol: "aapl", exchange: "nas", from: "20260101", through: "20260110" },
    (path, trId, query, allowNoDailyData) => {
      assert.equal(path, "/uapi/overseas-price/v1/quotations/dailyprice");
      assert.equal(trId, "HHDFS76240000");
      assert.equal(allowNoDailyData, true);
      assert.equal(query.EXCD, "NAS");
      assert.equal(query.SYMB, "AAPL");
      assert.equal(query.BYMD, "20260110");
      return Promise.resolve({
        output2: [{ xymd: "20260109", clos: "250.50", other: "omitted" }],
      });
    },
    endpoints,
  );
  assert.deepEqual(await response.json(), {
    ok: true,
    output2: [{ xymd: "20260109", clos: "250.50" }],
  });
});

Deno.test("invalid dates are rejected before fetching KIS", async () => {
  const response = await readMarketDetail(
    "daily_closes",
    { symbol: "005930", from: "20260230", through: "20260303" },
    () => {
      throw new Error("Unexpected KIS request");
    },
    endpoints,
  );
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, "invalid_date_range");
});

Deno.test("domestic daily closes accept the ten-year chart period", async () => {
  const response = await readMarketDetail(
    "daily_closes",
    { symbol: "005930", from: "20160110", through: "20260110" },
    (_path, trId, query) => {
      assert.equal(trId, "FHKST03010100");
      assert.equal(query.FID_INPUT_DATE_1, "20160110");
      return Promise.resolve({ output2: [] });
    },
    endpoints,
  );
  assert.equal(response.status, 200);
});

Deno.test("fund NAV and component queries only return their allowed fields", async () => {
  const nav = await readMarketDetail(
    "fund_nav",
    { symbol: "069500" },
    (path, trId, query) => {
      assert.equal(query.FID_INPUT_ISCD, "069500");
      if (path === endpoints.fund.path) {
        assert.equal(trId, endpoints.fund.trId);
        return Promise.resolve({
          output: { nav: "100", stck_prpr: "105", stck_dryy_hgpr: "500" },
        });
      }
      assert.equal(path, endpoints.domestic.path);
      assert.equal(trId, endpoints.domestic.trId);
      return Promise.resolve({ output: { w52_hgpr: "200", w52_lwpr: "50" } });
    },
    endpoints,
  );
  assert.deepEqual(await nav.json(), {
    ok: true,
    output: { nav: "100", w52_hgpr: "200", w52_lwpr: "50" },
  });

  const details = await readMarketDetail(
    "fund_details",
    { symbol: "069500" },
    (_path, trId, query) => {
      assert.equal(trId, "FHKST121600C0");
      assert.equal(query.FID_COND_SCR_DIV_CODE, "11216");
      return Promise.resolve({
        output1: { oprc_nav: "99", secret_like_field: "ignored" },
        output2: Array.from(
          { length: 15 },
          () => ({ stck_shrn_iscd: "005930" }),
        ),
      });
    },
    endpoints,
  );
  const data = await details.json();
  assert.deepEqual(data.output1, { oprc_nav: "99" });
  assert.equal(data.output2.length, 10);
});

Deno.test("stock details expose market, valuation, and 52-week fields for both exchanges", async () => {
  const domestic = await readMarketDetail(
    "stock_details",
    { symbol: "005930" },
    (path, trId, query) => {
      assert.equal(path, endpoints.domestic.path);
      assert.equal(trId, endpoints.domestic.trId);
      assert.equal(query.FID_INPUT_ISCD, "005930");
      return Promise.resolve({
        output: {
          stck_oprc: "152000",
          w52_hgpr: "200000",
          per: "25",
          other: "discarded",
        },
      });
    },
    endpoints,
  );
  assert.deepEqual(await domestic.json(), {
    ok: true,
    output: { stck_oprc: "152000", w52_hgpr: "200000", per: "25" },
  });

  const overseas = await readMarketDetail(
    "stock_details",
    { symbol: "aapl", exchange: "nas" },
    (path, trId, query) => {
      assert.equal(path, endpoints.overseas.path);
      assert.equal(trId, endpoints.overseas.trId);
      assert.equal(query.EXCD, "NAS");
      assert.equal(query.SYMB, "AAPL");
      return Promise.resolve({
        output: { open: "250", h52p: "350", perx: "30", other: "discarded" },
      });
    },
    endpoints,
  );
  assert.deepEqual(await overseas.json(), {
    ok: true,
    output: { open: "250", h52p: "350", perx: "30" },
  });
});
