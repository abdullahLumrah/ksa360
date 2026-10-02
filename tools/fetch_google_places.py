#!/usr/bin/env python3
"""Dump Google Places restaurants into server/data/restaurants.seed.json.

Requires Places API (New) + billing on the Maps key.
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / "ksa-guide-backend" / "data" / "restaurants.seed.json"
KEY = "AIzaSyAUjMG0glAvJsfUZJ-D0KPU_JC_foYbJqM"
URL = "https://places.googleapis.com/v1/places:searchNearby"
FIELDS = (
    "places.id,places.displayName,places.formattedAddress,places.location,"
    "places.types,places.primaryType,places.nationalPhoneNumber,"
    "places.websiteUri,places.photos,places.rating,places.userRatingCount"
)

# Dense neighborhood grid around major KSA cities (lat, lng).
CITIES = [
    ("Riyadh", 24.7136, 46.6753, 0.035, 5),
    ("Jeddah", 21.5433, 39.1728, 0.03, 4),
    ("Dammam", 26.4207, 50.0888, 0.025, 3),
    ("Khobar", 26.2172, 50.1971, 0.02, 3),
    ("Makkah", 21.3891, 39.8579, 0.02, 3),
    ("Madinah", 24.5247, 39.5692, 0.02, 3),
]


def classify(raw: str, name: str) -> str:
    blob = f"{raw}_{name}".lower().replace("-", "_").replace(" ", "_")
    table = [
        ("desi", ("indian", "pakistani", "bangladeshi", "biryani")),
        ("chinese", ("chinese", "wok")),
        ("japanese", ("japanese", "sushi", "ramen")),
        ("korean", ("korean",)),
        ("thai", ("thai", "vietnamese")),
        ("italian", ("italian", "pizza")),
        ("turkish", ("turkish", "kebab")),
        ("american", ("american", "burger", "chicken", "kfc", "mcdonald", "herfy", "kudu", "baik")),
        ("seafood", ("seafood", "fish")),
        ("cafe", ("cafe", "coffee", "bakery", "coffee_shop")),
        ("arab", ("arab", "saudi", "lebanese", "yemeni", "shawarma", "mandi", "middle_eastern")),
    ]
    for cat, keys in table:
        if any(k in blob for k in keys):
            return cat
    return "arab"


def nearby(lat: float, lng: float) -> list[dict]:
    body = json.dumps(
        {
            "includedTypes": ["restaurant", "cafe", "fast_food_restaurant"],
            "maxResultCount": 20,
            "rankPreference": "DISTANCE",
            "locationRestriction": {
                "circle": {
                    "center": {"latitude": lat, "longitude": lng},
                    "radius": 1800,
                }
            },
        }
    ).encode()
    req = urllib.request.Request(
        URL,
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": KEY,
            "X-Goog-FieldMask": FIELDS,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=25) as res:
        data = json.loads(res.read().decode())
    out = []
    for place in data.get("places") or []:
        loc = place.get("location") or {}
        plat, plng = loc.get("latitude"), loc.get("longitude")
        if plat is None or plng is None:
            continue
        name = ((place.get("displayName") or {}).get("text") or "Restaurant").strip()
        primary = place.get("primaryType") or "restaurant"
        types = " ".join(place.get("types") or [])
        photos = place.get("photos") or []
        image = ""
        if photos and photos[0].get("name"):
            image = (
                "https://places.googleapis.com/v1/"
                f"{photos[0]['name']}/media?maxWidthPx=900&key={KEY}"
            )
        pid = place.get("id") or f"{plat},{plng}"
        out.append(
            {
                "id": f"g-{pid}",
                "name": name,
                "lat": round(float(plat), 6),
                "lng": round(float(plng), 6),
                "kind": classify(f"{primary} {types}", name),
                "cuisine": primary.replace("_", " "),
                "city": "",
                "phone": place.get("nationalPhoneNumber") or "",
                "hours": "",
                "web": place.get("websiteUri") or "",
                "amenity": primary,
                "image": image,
                "rating": place.get("rating") or 0,
                "ratings": place.get("userRatingCount") or 0,
            }
        )
    return out


def main() -> None:
    existing: dict[str, dict] = {}
    if OUT.exists():
        prev = json.loads(OUT.read_text(encoding="utf-8"))
        for p in prev.get("places") or []:
            existing[p["id"]] = p
    print(f"starting {len(existing)}", flush=True)
    for name, lat, lng, step, span in CITIES:
        added = 0
        for di in range(-span, span + 1):
            for dj in range(-span, span + 1):
                try:
                    found = nearby(lat + di * step, lng + dj * step)
                except urllib.error.HTTPError as err:
                    body = err.read().decode("utf-8", "ignore")
                    print(f"FAIL {name} {err.code} {body[:180]}", flush=True)
                    if err.code in {403, 401}:
                        print(
                            "Enable billing + Places API (New) on this key, then rerun.",
                            flush=True,
                        )
                        return
                    time.sleep(1.5)
                    continue
                for row in found:
                    if row["id"] not in existing:
                        existing[row["id"]] = row
                        added += 1
                time.sleep(0.12)
        print(f"{name} +{added} total {len(existing)}", flush=True)
        places = sorted(existing.values(), key=lambda p: p["name"].lower())
        kinds: dict[str, int] = {}
        for p in places:
            kinds[p["kind"]] = kinds.get(p["kind"], 0) + 1
        OUT.write_text(
            json.dumps(
                {"count": len(places), "kinds": kinds, "places": places},
                ensure_ascii=False,
                separators=(",", ":"),
            ),
            encoding="utf-8",
        )
    print(f"wrote {len(existing)} -> {OUT}")


if __name__ == "__main__":
    main()
