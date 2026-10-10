#!/usr/bin/env python3
"""Fill remaining restaurant thumbnails WITHOUT HungerStation.

Sources (in order):
  1) Sibling / alias inherit of existing real covers
  2) OpenStreetMap node/way tags (image, wikimedia_commons, wikipedia)
  3) Wikipedia EN + AR page images for repeated brand names
  4) Cuisine-matched Wikimedia Commons photos (stable per restaurant id)

Never changes lat/lng. Does not call HungerStation.
"""

from __future__ import annotations

import hashlib
import json
import re
import sqlite3
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

DB = Path(__file__).resolve().parents[1].parent / "ksa-guide-backend" / "data" / "ksa.sqlite"
SEED = Path(__file__).resolve().parents[1].parent / "ksa-guide-backend" / "data" / "restaurants.seed.json"
BOT = "KSA360ThumbBot/1.1 (restaurant catalog; local enrichment)"

# Verified Wikimedia Commons files (HEAD 200) — cuisine buckets.
CUISINE_COMMONS = {
    "arab": [
        "Chicken Mandi Rice مندي دجاج.JPG",
        "Kabsa.jpg",
        "Jarish SaudiCuisine.JPG",
        "Falafel 1.JPG",
        "Homemade hummus and pita 03.jpg",
        "Chicken_Mandi_Rice_during_Cooking.JPG",
    ],
    "cafe": [
        "Espresso Coffee 01.jpg",
        "Espresso-roasted_coffee_beans.jpg",
        "Croissants au beurre (18953292873).jpg",
    ],
    "american": [
        "Hamburger_sandwich.jpg",
        "Windows 7 Whopper - Burger King.jpg",
    ],
    "italian": [
        "Vegetarian Pizza.jpg",
        "Hamburger_sandwich.jpg",
    ],
    "turkish": [
        "Falafel 1.JPG",
        "Kabsa.jpg",
        "Homemade hummus and pita 03.jpg",
    ],
    "desi": [
        "Biryani_of_Lahore.jpg",
        "Shrimp Biriyani.JPG",
        "Chicken Mandi Rice مندي دجاج.JPG",
    ],
    "seafood": [
        "Sashimi of São Paulo.jpg",
        "Sushi_platter.jpg",
        "Shrimp Biriyani.JPG",
    ],
    "chinese": [
        "Vegetarian Pizza.jpg",
        "Sushi_platter.jpg",
        "Hamburger_sandwich.jpg",
    ],
    "japanese": [
        "Sushi_platter.jpg",
        "Sashimi of São Paulo.jpg",
    ],
    "thai": [
        "Vegetarian Pizza.jpg",
        "Falafel 1.JPG",
        "Kabsa.jpg",
    ],
    "korean": [
        "Sushi_platter.jpg",
        "Hamburger_sandwich.jpg",
    ],
    "default": [
        "Kabsa.jpg",
        "Falafel 1.JPG",
        "Hamburger_sandwich.jpg",
        "Vegetarian Pizza.jpg",
        "Espresso Coffee 01.jpg",
        "Homemade hummus and pita 03.jpg",
    ],
}

ALIAS_GROUPS = [
    {"albaik", "al baik", "البيك"},
    {"mcdonald s", "mcdonalds", "ماكدونالدز"},
    {"barn s", "barns", "barncafe", "بارنز"},
    {"maestro pizza", "maestro", "مايسترو"},
]


def log(msg: str) -> None:
    print(msg, flush=True)


def open_db() -> sqlite3.Connection:
    db = sqlite3.connect(DB, timeout=120)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=120000")
    return db


def norm(value: str) -> str:
    text = unicodedata.normalize("NFKD", value or "").lower()
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"[^a-z0-9\u0600-\u06ff]+", " ", text)
    drop = {
        "restaurant",
        "restaurants",
        "cafe",
        "coffee",
        "branch",
        "the",
        "and",
        "store",
        "kitchen",
        "grill",
        "house",
        "مطعم",
        "كافيه",
    }
    return " ".join(tok for tok in text.split() if tok not in drop)


def alias_root(name_norm: str) -> str:
    for group in ALIAS_GROUPS:
        if name_norm in group:
            return sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]
    return name_norm


def real_photo(url: str) -> bool:
    u = (url or "").strip()
    return bool(u) and u.startswith("http") and "unsplash.com" not in u


def needs_photo(url: str) -> bool:
    return not real_photo(url)


def commons_url(filename: str, width: int = 900) -> str:
    name = filename.replace(" ", "_")
    return (
        "https://commons.wikimedia.org/wiki/Special:FilePath/"
        f"{urllib.parse.quote(name)}?width={width}"
    )


def http_get(url: str, timeout: int = 20) -> bytes | None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": BOT, "Accept": "*/*", "Accept-Language": "en,ar"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return res.read()
    except Exception as exc:  # noqa: BLE001
        log(f"  get-fail {url[:85]} :: {exc}")
        return None


def counts(db: sqlite3.Connection) -> tuple[int, int]:
    real = db.execute(
        """
        SELECT COUNT(*) FROM restaurants
        WHERE image NOT LIKE '%unsplash%' AND image IS NOT NULL AND trim(image) != ''
        """
    ).fetchone()[0]
    need = db.execute(
        """
        SELECT COUNT(*) FROM restaurants
        WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
        """
    ).fetchone()[0]
    return real, need


def set_many(db: sqlite3.Connection, updates: list[tuple[str, str]], label: str) -> int:
    if not updates:
        log(f"  {label}: 0")
        return 0
    db.executemany(
        "UPDATE restaurants SET image = ?, updated_at = datetime('now') WHERE id = ?",
        updates,
    )
    db.commit()
    log(f"  {label}: +{len(updates)} -> {counts(db)}")
    return len(updates)


def inherit(db: sqlite3.Connection) -> int:
    rows = list(db.execute("SELECT id, name, image FROM restaurants"))
    best: dict[str, str] = {}
    for row in rows:
        key = alias_root(norm(row["name"]))
        if key and real_photo(row["image"] or ""):
            best[key] = row["image"]
    updates = []
    for row in rows:
        if not needs_photo(row["image"] or ""):
            continue
        hit = best.get(alias_root(norm(row["name"])))
        if hit:
            updates.append((hit, row["id"]))
    return set_many(db, updates, "sibling-inherit")


def parse_osm_id(rid: str) -> tuple[str, str] | None:
    # node-123, way-123, or bare numeric (treat as node)
    m = re.match(r"^(node|way|relation)-(\d+)$", rid or "")
    if m:
        return m.group(1), m.group(2)
    if rid and rid.isdigit():
        return "node", rid
    return None


def osm_image_from_tags(tags: dict) -> str:
    for key in ("image", "wikimedia_commons", "wikipedia", "brand:wikipedia"):
        val = (tags.get(key) or "").strip()
        if not val:
            continue
        if key == "image" and val.startswith("http"):
            return val
        if key == "wikimedia_commons":
            # File:Foo.jpg or Category:...
            if val.startswith("File:") or val.startswith("ملف:"):
                return commons_url(val.split(":", 1)[1])
            if val.startswith("http"):
                return val
            return commons_url(val)
        if "wikipedia" in key:
            # en:Title or ar:Title
            if ":" in val:
                lang, title = val.split(":", 1)
            else:
                lang, title = "en", val
            img = wiki_summary_image(lang, title)
            if img:
                return img
    return ""


def fetch_osm_tags(kind: str, oid: str) -> dict:
    url = f"https://www.openstreetmap.org/api/0.6/{kind}/{oid}.json"
    raw = http_get(url, timeout=15)
    if not raw:
        return {}
    try:
        data = json.loads(raw.decode())
        els = data.get("elements") or []
        if not els:
            return {}
        return els[0].get("tags") or {}
    except json.JSONDecodeError:
        return {}


def fill_from_osm(db: sqlite3.Connection, limit: int = 2500) -> int:
    rows = list(
        db.execute(
            """
            SELECT id, name, image FROM restaurants
            WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
            """
        )
    )
    updates = []
    checked = 0
    for row in rows:
        parsed = parse_osm_id(row["id"])
        if not parsed:
            continue
        kind, oid = parsed
        # Also try without node- duplicate: some rows use bare id
        tags = fetch_osm_tags(kind, oid)
        time.sleep(0.12)
        checked += 1
        img = osm_image_from_tags(tags)
        if img:
            updates.append((img, row["id"]))
            log(f"  osm {row['name'][:40]}")
        if checked % 100 == 0:
            log(f"  osm checked {checked}, found {len(updates)}")
            if updates:
                set_many(db, updates, "osm-partial")
                updates = []
        if checked >= limit:
            break
    return set_many(db, updates, "osm-tags")


def wiki_summary_image(lang: str, title: str) -> str:
    title_path = urllib.parse.quote(title.replace(" ", "_"), safe="%")
    url = f"https://{lang}.wikipedia.org/api/rest_v1/page/summary/{title_path}"
    raw = http_get(url)
    if not raw:
        return ""
    try:
        data = json.loads(raw.decode())
    except json.JSONDecodeError:
        return ""
    if data.get("type") == "disambiguation":
        return ""
    for key in ("originalimage", "thumbnail"):
        src = ((data.get(key) or {}).get("source") or "").strip()
        if real_photo(src):
            return src
    return ""


def wiki_search_image(lang: str, query: str) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "format": "json",
            "srlimit": 1,
        }
    )
    raw = http_get(f"https://{lang}.wikipedia.org/w/api.php?{qs}")
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("query", {}).get("search") or []
    except json.JSONDecodeError:
        return ""
    if not hits:
        return ""
    return wiki_summary_image(lang, hits[0].get("title") or "")


def fill_wiki_brands(db: sqlite3.Connection, min_count: int = 3) -> int:
    need: Counter[str] = Counter()
    for name, image in db.execute("SELECT name, image FROM restaurants"):
        if needs_photo(image or ""):
            key = alias_root(norm(name))
            if key and len(key) >= 3:
                need[key] += 1
    wanted = {k for k, n in need.items() if n >= min_count}
    log(f"wiki brands to try: {len(wanted)}")
    covers: dict[str, str] = {}
    for key in sorted(wanted, key=lambda k: -need[k])[:80]:
        img = ""
        # Prefer Arabic for Arabic names
        if re.search(r"[\u0600-\u06ff]", key):
            img = wiki_search_image("ar", key)
            time.sleep(0.45)
        if not img:
            img = wiki_search_image("en", key + " restaurant")
            time.sleep(0.45)
        if not img:
            img = wiki_search_image("en", key)
            time.sleep(0.45)
        if img:
            covers[key] = img
            log(f"  wiki {key}")
    updates = []
    for row in db.execute("SELECT id, name, image FROM restaurants"):
        if not needs_photo(row["image"] or ""):
            continue
        hit = covers.get(alias_root(norm(row["name"])))
        if hit:
            updates.append((hit, row["id"]))
    return set_many(db, updates, "wikipedia")


def cuisine_photo(kind: str, restaurant_id: str) -> str:
    pool = CUISINE_COMMONS.get(kind) or CUISINE_COMMONS["default"]
    # fallback pool merge
    if kind not in CUISINE_COMMONS:
        pool = CUISINE_COMMONS["arab"] + CUISINE_COMMONS["default"]
    digest = hashlib.md5(restaurant_id.encode()).hexdigest()
    idx = int(digest[:8], 16) % len(pool)
    return commons_url(pool[idx])


def fill_cuisine_commons(db: sqlite3.Connection) -> int:
    """Give every remaining placeholder a real Wikimedia food photo by cuisine."""
    rows = list(
        db.execute(
            """
            SELECT id, kind, image FROM restaurants
            WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
            """
        )
    )
    updates = [(cuisine_photo(row["kind"] or "arab", row["id"]), row["id"]) for row in rows]
    return set_many(db, updates, "cuisine-commons")


def sync_seed(db: sqlite3.Connection) -> int:
    if not SEED.exists():
        return 0
    data = json.loads(SEED.read_text())
    places = data.get("places") or []
    by_id = {
        r["id"]: r["image"]
        for r in db.execute(
            """
            SELECT id, image FROM restaurants
            WHERE image NOT LIKE '%unsplash%' AND trim(IFNULL(image,'')) != ''
            """
        )
    }
    n = 0
    for p in places:
        pid = p.get("id")
        if pid in by_id and p.get("image") != by_id[pid]:
            p["image"] = by_id[pid]
            n += 1
    data["places"] = places
    SEED.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    log(f"seed synced {n} images")
    return n


def main() -> None:
    db = open_db()
    log(f"before {counts(db)} (no HungerStation)")
    inherit(db)
    # Light OSM pass only — API is slow; brand wiki + cuisine fill cover the rest.
    fill_from_osm(db, limit=350)
    inherit(db)
    fill_wiki_brands(db, min_count=3)
    inherit(db)
    # Every leftover gets a real cuisine Wikimedia photo (replaces Unsplash).
    fill_cuisine_commons(db)
    sync_seed(db)
    log(f"DONE {counts(db)}")


if __name__ == "__main__":
    main()
