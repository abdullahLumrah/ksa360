#!/usr/bin/env python3
"""Riyadh car listings from expatriates.com (last 14 days).

Public category pages (allowed by robots.txt), not /scripts/ search:
  https://www.expatriates.com/classifieds/riyadh/vehicles-cars-trucks/
  pagination: index100.html, index200.html, ...
  ads: /cls/{id}.html  photos: /img/{id}.N.jpg

The site is behind Cloudflare, so this script is a parser/packer for JSON
already collected through a browser session. Phone numbers are not stored.
"""

from __future__ import annotations

import gzip
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "assets" / "data" / "expat_cars.json"
OUT_GZ = ROOT / "assets" / "data" / "expat_cars.json.gz"


def pack(ads: list[dict]) -> None:
    epochs = [a["postDate"] for a in ads if a.get("postDate")]
    payload = {
        "source": "expatriates.com",
        "city": "Riyadh",
        "scraped_at": datetime.now(timezone.utc).date().isoformat(),
        "count": len(ads),
        "oldest": datetime.fromtimestamp(min(epochs), timezone.utc).isoformat()
        if epochs
        else None,
        "newest": datetime.fromtimestamp(max(epochs), timezone.utc).isoformat()
        if epochs
        else None,
        "note": "Public Riyadh car ads with photos, last 14 days. Phones not collected. Full listings in expat_cars.json.gz.",
        "listings": [],
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2))
    compact = {
        "source": "expatriates.com",
        "city": "Riyadh",
        "listings": ads,
    }
    raw = json.dumps(compact, ensure_ascii=False, separators=(",", ":")).encode()
    OUT_GZ.write_bytes(gzip.compress(raw, compresslevel=9))
    print("wrote", len(ads), "ads", OUT_GZ, "bytes", OUT_GZ.stat().st_size)


if __name__ == "__main__":
    print(__doc__)
