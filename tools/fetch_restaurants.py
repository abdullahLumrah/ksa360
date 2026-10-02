#!/usr/bin/env python3
"""Dump OSM restaurants around every KSA city (complete local sets, not search top-50)."""

from __future__ import annotations

import json
import re
import ssl
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / "ksa-guide-backend" / "data" / "restaurants.seed.json"
DART = ROOT / "lib" / "data" / "saudi_cities.dart"
UA = "KSAGuide/1.0 (KSA expat guide; restaurant dump)"
CTX = ssl.create_default_context()
HOSTS = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass-api.de/api/interpreter",
]


def cities() -> list[tuple[str, float, float, int]]:
    text = DART.read_text(encoding="utf-8")
    found = [("Riyadh", 24.7136, 46.6753, 32000)]
    for m in re.finditer(
        r"name:\s*'([^']+)'.*?lat:\s*([0-9.]+),\s*lng:\s*([0-9.]+)",
        text,
        re.S,
    ):
        name, lat, lng = m.group(1), float(m.group(2)), float(m.group(3))
        radius = 32000 if name in {"Riyadh", "Jeddah"} else 20000 if name in {
            "Dammam",
            "Khobar",
            "Makkah",
            "Madinah",
            "Taif",
            "Hofuf (Al Ahsa)",
        } else 16000
        found.append((name, lat, lng, radius))
    # unique by rounded coord
    uniq = {}
    for row in found:
        uniq[(round(row[1], 3), round(row[2], 3))] = row
    return list(uniq.values())


def classify(raw: str, name: str) -> str:
    blob = f"{raw} {name}".lower().replace("-", "_").replace(" ", "_")
    table = [
        ("desi", ("indian", "pakistani", "bangladeshi", "punjabi", "biryani", "karachi", "lahore")),
        ("chinese", ("chinese", "wok", "dim_sum", "szechuan")),
        ("japanese", ("japanese", "sushi", "ramen")),
        ("korean", ("korean",)),
        ("thai", ("thai", "vietnamese")),
        ("italian", ("italian", "pizza", "pasta")),
        ("turkish", ("turkish", "kebab")),
        ("american", ("american", "burger", "chicken", "kfc", "mcdonald", "herfy", "kudu", "baik")),
        ("seafood", ("seafood", "fish", "shrimp")),
        ("cafe", ("cafe", "coffee", "bakery", "starbucks", "dunkin")),
        ("arab", ("arab", "saudi", "lebanese", "yemeni", "egyptian", "shawarma", "mandi", "kabsa")),
    ]
    for cat, keys in table:
        if any(k in blob for k in keys):
            return cat
    return "arab"


def overpass(query: str) -> dict:
    body = query.encode("utf-8")
    last = None
    for host in HOSTS:
        req = urllib.request.Request(
            host,
            data=body,
            headers={"User-Agent": UA, "Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=70, context=CTX) as res:
                return json.loads(res.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.2)
    raise RuntimeError(last)


def coords(el: dict) -> tuple[float, float] | None:
    if "lat" in el and "lon" in el:
        return float(el["lat"]), float(el["lon"])
    c = el.get("center") or {}
    if "lat" in c and "lon" in c:
        return float(c["lat"]), float(c["lon"])
    return None


def place_from(el: dict) -> dict | None:
    tags = el.get("tags") or {}
    xy = coords(el)
    if xy is None:
        return None
    lat, lng = xy
    if not (16.0 <= lat <= 32.6 and 34.4 <= lng <= 55.8):
        return None
    amenity = tags.get("amenity") or "restaurant"
    title = (
        tags.get("name:en") or tags.get("name") or tags.get("name:ar") or tags.get("brand") or ""
    ).strip() or {"fast_food": "Fast food", "cafe": "Cafe", "food_court": "Food court"}.get(
        amenity, "Restaurant"
    )
    cuisine_raw = (tags.get("cuisine") or "").replace(";", ", ")
    return {
        "id": f"{el.get('type', 'n')}-{el.get('id')}",
        "name": title,
        "lat": round(lat, 6),
        "lng": round(lng, 6),
        "kind": classify(cuisine_raw, title),
        "cuisine": cuisine_raw,
        "city": tags.get("addr:city") or "",
        "phone": tags.get("phone") or tags.get("contact:phone") or "",
        "hours": tags.get("opening_hours") or "",
        "web": tags.get("website") or tags.get("contact:website") or "",
        "amenity": amenity,
    }


def save(existing: dict[str, dict]) -> None:
    places = sorted(existing.values(), key=lambda p: p["name"].lower())
    counts: dict[str, int] = {}
    for p in places:
        counts[p["kind"]] = counts.get(p["kind"], 0) + 1
    OUT.write_text(
        json.dumps({"count": len(places), "kinds": counts, "places": places}, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def main() -> None:
    existing: dict[str, dict] = {}
    if OUT.exists():
        prev = json.loads(OUT.read_text(encoding="utf-8"))
        for p in prev.get("places") or []:
            existing[p["id"]] = p
    rows = cities()
    print(f"{len(rows)} cities, starting {len(existing)}", flush=True)
    for i, (name, lat, lng, radius) in enumerate(rows, 1):
        q = f"""[out:json][timeout:55];
(
  nwr["amenity"="restaurant"](around:{radius},{lat},{lng});
  nwr["amenity"="fast_food"](around:{radius},{lat},{lng});
  nwr["amenity"="cafe"](around:{radius},{lat},{lng});
  nwr["amenity"="food_court"](around:{radius},{lat},{lng});
);
out center tags;
"""
        try:
            data = overpass(q)
        except Exception as err:
            print(f"{i}/{len(rows)} {name} FAIL {err}", flush=True)
            time.sleep(2)
            continue
        added = 0
        for el in data.get("elements") or []:
            row = place_from(el)
            if row and row["id"] not in existing:
                existing[row["id"]] = row
                added += 1
        print(f"{i}/{len(rows)} {name} +{added} total {len(existing)}", flush=True)
        if i % 5 == 0:
            save(existing)
        time.sleep(0.7)
    save(existing)
    print(f"wrote {len(existing)} -> {OUT}")


if __name__ == "__main__":
    main()
