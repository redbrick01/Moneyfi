type MarketDetailMode =
  | "daily_closes"
  | "fund_nav"
  | "fund_details"
  | "stock_details";

type QuoteEndpoint = { path: string; trId: string };
type QuoteEndpoints = {
  domestic: QuoteEndpoint;
  overseas: QuoteEndpoint;
  fund: QuoteEndpoint;
  componentScreenCode: string;
};

type KisRead = (
  path: string,
  trId: string,
  query: Record<string, string>,
  allowNoDailyData?: boolean,
) => Promise<Record<string, unknown>>;

export function isMarketDetailMode(value: unknown): value is MarketDetailMode {
  return value === "daily_closes" || value === "fund_nav" ||
    value === "fund_details" || value === "stock_details";
}

function marketDate(value: unknown): Date | null {
  if (typeof value !== "string" || !/^\d{8}$/.test(value)) return null;
  const iso = `${value.slice(0, 4)}-${value.slice(4, 6)}-${value.slice(6, 8)}`;
  const date = new Date(iso);
  return !Number.isNaN(date.valueOf()) &&
      date.toISOString().slice(0, 10) === iso
    ? date
    : null;
}

function selectFields(value: unknown, fields: string[]) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  const record = value as Record<string, unknown>;
  return Object.fromEntries(
    fields.flatMap((field) =>
      typeof record[field] === "string" || typeof record[field] === "number"
        ? [[field, record[field]]]
        : []
    ),
  );
}

export async function readMarketDetail(
  mode: MarketDetailMode,
  body: Record<string, unknown>,
  kisRead: KisRead,
  endpoints: QuoteEndpoints,
) {
  const symbol = typeof body.symbol === "string"
    ? body.symbol.trim().toUpperCase()
    : "";
  const exchange = typeof body.exchange === "string"
    ? body.exchange.trim().toUpperCase()
    : "";
  const overseas = (mode === "daily_closes" || mode === "stock_details") &&
    exchange !== "";
  if (
    overseas
      ? !["NAS", "NYS", "AMS"].includes(exchange) ||
        !/^[A-Z0-9][A-Z0-9./-]{0,14}$/.test(symbol)
      : !/^[A-Z0-9]{6}$/.test(symbol)
  ) {
    return Response.json({ ok: false, error: "invalid_instrument" }, {
      status: 400,
    });
  }

  if (mode === "daily_closes") {
    const from = marketDate(body.from);
    const through = marketDate(body.through);
    if (
      !from || !through || through < from ||
      // The chart offers a ten-year period and requests one KIS page at a time.
      through.valueOf() - from.valueOf() > 3_660 * 86_400_000 ||
      through.valueOf() > Date.now() + 86_400_000
    ) {
      return Response.json({ ok: false, error: "invalid_date_range" }, {
        status: 400,
      });
    }
    const quote = await kisRead(
      overseas
        ? "/uapi/overseas-price/v1/quotations/dailyprice"
        : "/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice",
      overseas ? "HHDFS76240000" : "FHKST03010100",
      overseas
        ? {
          AUTH: "",
          EXCD: exchange,
          SYMB: symbol,
          GUBN: "0",
          BYMD: String(body.through),
          MODP: "0",
        }
        : {
          FID_COND_MRKT_DIV_CODE: "J",
          FID_INPUT_ISCD: symbol,
          FID_INPUT_DATE_1: String(body.from),
          FID_INPUT_DATE_2: String(body.through),
          FID_PERIOD_DIV_CODE: "D",
          FID_ORG_ADJ_PRC: "1",
        },
      true,
    );
    if (!Array.isArray(quote.output2)) {
      throw new Error("Unexpected KIS daily close response");
    }
    const fields = overseas
      ? ["xymd", "clos"]
      : ["stck_bsop_date", "stck_clpr"];
    return Response.json({
      ok: true,
      output2: quote.output2.map((row) => selectFields(row, fields)),
    });
  }

  const domesticQuery = { FID_COND_MRKT_DIV_CODE: "J", FID_INPUT_ISCD: symbol };
  if (mode === "stock_details") {
    const endpoint = overseas ? endpoints.overseas : endpoints.domestic;
    const quote = await kisRead(
      endpoint.path,
      endpoint.trId,
      overseas ? { AUTH: "", EXCD: exchange, SYMB: symbol } : domesticQuery,
    );
    return Response.json({
      ok: true,
      output: selectFields(
        quote.output,
        overseas
          ? [
            "rsym",
            "last",
            "base",
            "open",
            "high",
            "low",
            "tvol",
            "pvol",
            "tamt",
            "pamt",
            "perx",
            "pbrx",
            "epsx",
            "bpsx",
            "h52p",
            "l52p",
          ]
          : [
            "stck_prpr",
            "rprs_mrkt_kor_name",
            "bstp_kor_isnm",
            "prdy_vrss",
            "prdy_vrss_sign",
            "prdy_ctrt",
            "stck_prdy_clpr",
            "stck_oprc",
            "stck_hgpr",
            "stck_lwpr",
            "acml_vol",
            "acml_tr_pbmn",
            "per",
            "pbr",
            "eps",
            "bps",
            "w52_hgpr",
            "w52_lwpr",
            "hts_frgn_ehrt",
          ],
      ),
    });
  }

  if (mode === "fund_nav") {
    const quote = await kisRead(
      endpoints.fund.path,
      endpoints.fund.trId,
      domesticQuery,
    );
    // ETF current-price data includes calendar-year extrema. The domestic quote
    // supplies the separate rolling 52-week range.
    const market = await kisRead(
      endpoints.domestic.path,
      endpoints.domestic.trId,
      domesticQuery,
    ).catch(() => null);
    return Response.json({
      ok: true,
      output: {
        ...selectFields(quote.output, [
          "nav",
          "nav_prdy_ctrt",
          "nav_prdy_vrss_sign",
          "trc_errt",
          "dprt",
          "etf_ntas_ttam",
          "frgn_hldn_qty_rate",
          "etf_dvdn_cycl",
          "etf_div_name",
          "stck_lstn_date",
          "crcd",
          "bstp_kor_isnm",
          "prdy_vrss",
          "prdy_vrss_sign",
          "prdy_ctrt",
          "stck_prdy_clpr",
          "stck_oprc",
          "stck_hgpr",
          "stck_lwpr",
          "acml_vol",
        ]),
        ...selectFields(market?.output, [
          "w52_hgpr",
          "w52_lwpr",
          "acml_tr_pbmn",
        ]),
      },
    });
  }

  const quote = await kisRead(
    "/uapi/etfetn/v1/quotations/inquire-component-stock-price",
    "FHKST121600C0",
    { ...domesticQuery, FID_COND_SCR_DIV_CODE: endpoints.componentScreenCode },
  );
  return Response.json({
    ok: true,
    output1: selectFields(quote.output1, [
      "etf_cnfg_issu_cnt",
      "etf_cnfg_issu_avls",
      "etf_ntas_ttam",
      "etf_cu_unit_scrt_cnt",
      "oprc_nav",
      "hprc_nav",
      "lprc_nav",
    ]),
    output2: Array.isArray(quote.output2)
      ? quote.output2.slice(0, 10).map((row) =>
        selectFields(row, [
          "stck_shrn_iscd",
          "hts_kor_isnm",
          "stck_prpr",
          "prdy_ctrt",
          "prdy_vrss_sign",
          "etf_cnfg_issu_rlim",
          "etf_vltn_amt",
        ])
      )
      : [],
  });
}
