"""Refresh the bundled stock directory from Korea Investment's five master files.

Run python3 scripts/update_market_catalog.py or pass --archive-dir for saved ZIPs.
File layouts: https://github.com/koreainvestment/open-trading-api/tree/main/stocks_info
"""
import argparse
import io
import json
from pathlib import Path
import re
from urllib.request import urlopen
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
BASE = "https://new.real.download.dws.co.kr/common/master/"
MARKETS = {
    "KOSPI": "kospi_code.mst", "KOSDAQ": "kosdaq_code.mst",
    "NAS": "nasmst.cod", "NYS": "nysmst.cod", "AMS": "amsmst.cod",
}


def instruments(market, lines):
    for line in lines:
        if market in ("KOSPI", "KOSDAQ"):
            # Domestic names occupy 40 CP949 bytes after the short code and ISIN.
            symbol = line[:9].decode("ascii").strip()
            group = line[61:63].decode("ascii")
            if group not in {"ST", "DR", "FS", "RT", "IF", "MF", "PF", "EF"}:
                continue
            if not re.fullmatch(r"[A-Z0-9]{6}", symbol):
                continue
            name = line[21:61].decode("cp949").strip()
            yield [market, symbol, name, "", "펀드" if group == "EF" else "주식"]
        else:
            fields = line.decode("cp949").split("\t")
            if fields[0] != "US" or fields[2] != market or fields[9] != "USD":
                raise ValueError(f"Unexpected market or currency in {market}")
            # US-listed funds use the same overseas exchange quote path as stocks.
            symbol, korean, english = (fields[i].strip() for i in (4, 6, 7))
            yield [market, symbol, korean or english, english, "주식"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive-dir", type=Path)
    args = parser.parse_args()
    catalog = []
    seen = set()
    for market, filename in MARKETS.items():
        archive_name = filename + ".zip"
        if args.archive_dir:
            data = (args.archive_dir / archive_name).read_bytes()
        else:
            with urlopen(BASE + archive_name, timeout=45) as response:
                data = response.read()
        with ZipFile(io.BytesIO(data)) as archive:
            member, = [name for name in archive.namelist() if name.lower() == filename]
            rows = list(instruments(market, archive.read(member).splitlines()))
        if not rows:
            raise ValueError(f"Empty source for {market}")
        for row in rows:
            key = tuple(row[:2])
            if key in seen or not row[1] or not row[2]:
                raise ValueError(f"Invalid or duplicate listing: {key}")
            seen.add(key)
        catalog.extend(sorted(rows))
        print(f"{market}: {len(rows)}")
    output = ROOT / "assets" / "market_catalog.json"
    temp = output.with_suffix(".tmp")
    temp.write_text("[\n" + ",\n".join(
        json.dumps(row, ensure_ascii=False, separators=(",", ":")) for row in catalog
    ) + "\n]\n", encoding="utf-8")
    temp.replace(output)


if __name__ == "__main__":
    main()
