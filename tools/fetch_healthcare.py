#!/usr/bin/env python3
"""Dump OSM hospitals, clinics, and health centres around KSA cities."""

from __future__ import annotations

import json
import re
import ssl
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / "ksa-guide-backend" / "data" / "healthcare.seed.json"
DART = ROOT / "lib" / "data" / "saudi_cities.dart"
UA = "KSAGuide/1.0 (KSA expat guide; healthcare dump)"
CTX = ssl.create_default_context()
HOSTS = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass-api.de/api/interpreter",
]


def cities() -> list[tuple[str, float, float, int]]:
    text = DART.read_text(encoding="utf-8")
    found = [("Riyadh", 24.7136, 46.6753, 28000)]
    for m in re.finditer(
        r"name:\s*'([^']+)'.*?lat:\s*([0-9.]+),\s*lng:\s*([0-9.]+)",
        text,
        re.S,
    ):
        name, lat, lng = m.group(1), float(m.group(2)), float(m.group(3))
        radius = 28000 if name in {"Riyadh", "Jeddah"} else 18000 if name in {
            "Dammam",
            "Khobar",
            "Makkah",
            "Madinah",
            "Taif",
            "Hofuf (Al Ahsa)",
        } else 14000
        found.append((name, lat, lng, radius))
    uniq = {}
    for row in found:
        uniq[(round(row[1], 3), round(row[2], 3))] = row
    return list(uniq.values())


def classify(tags: dict, name: str) -> str:
    amenity = (tags.get("amenity") or "").lower()
    health = (tags.get("healthcare") or "").lower()
    blob = f"{amenity} {health} {name}".lower()
    if amenity == "hospital" or health == "hospital" or "hospital" in blob:
        return "hospital"
    if amenity in {"clinic", "doctors"} or health in {"clinic", "doctor", "yes"}:
        if "poly" in blob or "polyclinic" in blob:
            return "clinic"
        if amenity == "doctors" or health == "doctor":
            return "doctors"
        return "clinic"
    if health in {"centre", "center"} or "health centre" in blob or "health center" in blob:
        return "health_centre"
    if amenity == "pharmacy" or health == "pharmacy":
        return "pharmacy"
    if amenity == "dentist" or health == "dentist":
        return "clinic"
    return "clinic"


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
            with urllib.request.urlopen(req, timeout=80, context=CTX) as res:
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


def services_of(tags: dict) -> str:
    parts = []
    for key in ("healthcare:speciality", "healthcare:specialty", "speciality"):
        raw = tags.get(key) or ""
        if raw:
            parts.extend(p.strip() for p in raw.replace(";", ",").split(",") if p.strip())
    if tags.get("emergency") in {"yes", "all"}:
        parts.append("emergency")
    if tags.get("emergency") == "yes":
        parts.append("ER")
    seen = []
    for part in parts:
        low = part.lower()
        if low not in seen:
            seen.append(low)
    return ", ".join(seen)


def place_from(el: dict, city_hint: str) -> dict | None:
    tags = el.get("tags") or {}
    xy = coords(el)
    if xy is None:
        return None
    lat, lng = xy
    if not (16.0 <= lat <= 32.6 and 34.4 <= lng <= 55.8):
        return None
    title = (
        tags.get("name:en") or tags.get("name") or tags.get("name:ar") or tags.get("brand") or ""
    ).strip()
    if not title:
        return None
    amenity = tags.get("amenity") or tags.get("healthcare") or "clinic"
    emergency = tags.get("emergency") in {"yes", "all"} or classify(tags, title) == "hospital"
    return {
        "id": f"{el.get('type', 'n')}-{el.get('id')}",
        "name": title,
        "lat": round(lat, 6),
        "lng": round(lng, 6),
        "kind": classify(tags, title),
        "city": tags.get("addr:city") or city_hint,
        "phone": tags.get("phone") or tags.get("contact:phone") or "",
        "hours": tags.get("opening_hours") or "",
        "web": tags.get("website") or tags.get("contact:website") or "",
        "amenity": amenity,
        "emergency": emergency,
        "services": services_of(tags),
        "source": "osm",
    }


def save(existing: dict[str, dict]) -> None:
    places = sorted(existing.values(), key=lambda p: p["name"].lower())
    counts: dict[str, int] = {}
    for p in places:
        counts[p["kind"]] = counts.get(p["kind"], 0) + 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
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
        q = f"""[out:json][timeout:60];
(
  nwr["amenity"="hospital"](around:{radius},{lat},{lng});
  nwr["amenity"="clinic"](around:{radius},{lat},{lng});
  nwr["amenity"="doctors"](around:{radius},{lat},{lng});
  nwr["healthcare"="hospital"](around:{radius},{lat},{lng});
  nwr["healthcare"="clinic"](around:{radius},{lat},{lng});
  nwr["healthcare"="centre"](around:{radius},{lat},{lng});
  nwr["healthcare"="center"](around:{radius},{lat},{lng});
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
            row = place_from(el, name)
            if row and row["id"] not in existing:
                existing[row["id"]] = row
                added += 1
        print(f"{i}/{len(rows)} {name} +{added} total {len(existing)}", flush=True)
        if i % 4 == 0:
            save(existing)
        time.sleep(0.8)
    save(existing)
    print(f"wrote {len(existing)} -> {OUT}")


if __name__ == "__main__":
    main()
