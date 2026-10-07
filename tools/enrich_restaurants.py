#!/usr/bin/env python3
"""Match OSM restaurants to HungerStation covers, ratings, and menus.

Coordinates on our restaurants are never changed.
"""

from __future__ import annotations

import json
import math
import re
import sqlite3
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT.parent / "ksa-guide-backend" / "data" / "ksa.sqlite"
PROGRESS = ROOT.parent / "ksa-guide-backend" / "data" / "hs_enrich_progress.json"
BASE = "https://hungerstation.com/sa-en"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
)
SLEEP = 0.45
# Ordered: big cities first so Eat shows real photos sooner.
PRIORITY = [
    "riyadh",
    "jeddah",
    "dammam",
    "al-khobar",
    "mecca",
    "madinah",
    "taif",
    "khobar",
    "makkah",
    "medina",
    "buraydah",
    "hofuf",
    "jubail",
    "yanbu",
    "tabuk",
    "abha",
    "jazan",
    "khamis-mushait",
]
PRIORITY_RANK = {slug: i for i, slug in enumerate(PRIORITY)}


def log(msg: str) -> None:
    print(msg, flush=True)


def open_db() -> sqlite3.Connection:
    db = sqlite3.connect(DB)
    db.row_factory = sqlite3.Row
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS restaurant_menu_items (
          id TEXT PRIMARY KEY,
          restaurant_id TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          price TEXT NOT NULL DEFAULT '',
          image TEXT NOT NULL DEFAULT '',
          source TEXT NOT NULL DEFAULT 'hungerstation',
          sort_order INTEGER NOT NULL DEFAULT 0
        )
        """
    )
    db.execute(
        "CREATE INDEX IF NOT EXISTS restaurant_menu_restaurant_idx "
        "ON restaurant_menu_items(restaurant_id, sort_order)"
    )
    return db


def load_progress() -> dict:
    if PROGRESS.exists():
        return json.loads(PROGRESS.read_text())
    return {"districts": [], "menus": [], "matched": 0, "photos": 0}


def save_progress(state: dict) -> None:
    PROGRESS.write_text(json.dumps(state, indent=2))


def fetch(url: str, tries: int = 4) -> dict | None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept": "text/html,application/json", "Accept-Language": "en"},
    )
    last = None
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=25) as res:
                html = res.read().decode("utf-8", "replace")
            m = re.search(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html)
            if not m:
                return None
            return json.loads(m.group(1)).get("props", {}).get("pageProps") or {}
        except Exception as exc:  # noqa: BLE001
            last = exc
            time.sleep(1.2 * (attempt + 1))
    log(f"fail {url} {last}")
    return None


def slugify(value: str) -> str:
    text = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    return text or "restaurant"


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
    tokens = [tok for tok in text.split() if tok not in drop]
    return " ".join(tokens)


def km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    p = math.pi / 180
    a = (
        0.5
        - math.cos((lat2 - lat1) * p) / 2
        + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2
    )
    return 12742 * math.asin(math.sqrt(max(0, min(1, a))))


def real_photo(url: str) -> bool:
    return bool(url) and "unsplash.com" not in url


def cities(db: sqlite3.Connection) -> list[dict]:
    ours = {
        re.sub(r"[^a-z]+", "", (row["city"] or "").lower())
        for row in db.execute("SELECT DISTINCT city FROM restaurants")
    }
    page = fetch(f"{BASE}/restaurants/regions")
    rows = (page or {}).get("cities") or []
    ranked = []
    for city in rows:
        slug = city.get("slug") or ""
        key = re.sub(r"[^a-z]+", "", slug.replace("-", ""))
        hit = key in ours or any(key and key in ours_name for ours_name in ours)
        if slug in PRIORITY_RANK:
            rank = PRIORITY_RANK[slug]
        elif hit:
            rank = 1000
        else:
            rank = 2000
        ranked.append((rank, city.get("name") or "", city))
    ranked.sort(key=lambda item: (item[0], item[1]))
    return [city for _, __, city in ranked]


def load_ours(db: sqlite3.Connection) -> list[sqlite3.Row]:
    return list(db.execute("SELECT id, name, city, lat, lng, image, rating, ratings FROM restaurants"))


def score_match(place: sqlite3.Row, vendor: dict) -> float:
    loc = vendor.get("location") or {}
    try:
        vlat = float(loc.get("latitude"))
        vlng = float(loc.get("longitude"))
    except (TypeError, ValueError):
        return 0
    dist = km(place["lat"], place["lng"], vlat, vlng)
    left = norm(place["name"])
    right = norm(vendor.get("chainName") or vendor.get("chain_name") or "")
    if not left or not right:
        return 0
    if left == right:
        if dist > 6.5:
            return 0
        return 0.88 + max(0.0, 1 - dist / 6.5) * 0.12
    if dist > 1.8:
        return 0
    if left in right or right in left:
        name = 0.86
    else:
        a, b = set(left.split()), set(right.split())
        name = len(a & b) / max(1, len(a | b))
        if name < 0.5:
            return 0
        if min(len(a), len(b)) == 1 and min(len(tok) for tok in a | b) < 5:
            return 0
    return name * 0.72 + max(0, 1 - dist / 1.8) * 0.28


def best_match(ours: list[sqlite3.Row], vendor: dict) -> sqlite3.Row | None:
    best = None
    best_score = 0.62
    for place in ours:
        s = score_match(place, vendor)
        if s > best_score:
            best, best_score = place, s
    return best


def apply_vendor(db: sqlite3.Connection, place: sqlite3.Row, vendor: dict) -> bool:
    cover = vendor.get("coverPhoto") or vendor.get("cover_photo") or ""
    logo = vendor.get("logo") or ""
    image = cover or logo
    try:
        rating = float(vendor.get("averageRating") or vendor.get("average_rating") or 0)
    except (TypeError, ValueError):
        rating = 0
    try:
        ratings = int(float(vendor.get("rateCount") or vendor.get("rate_count") or 0))
    except (TypeError, ValueError):
        ratings = 0
    current = place["image"] or ""
    next_image = image if real_photo(image) and (not real_photo(current) or "unsplash.com" in current or "deliveryhero.io" in image or "hungerstation" in image) else current
    db.execute(
        """
        UPDATE restaurants
        SET image = ?,
            rating = CASE WHEN ? > rating THEN ? ELSE rating END,
            ratings = CASE WHEN ? > ratings THEN ? ELSE ratings END,
            updated_at = datetime('now')
        WHERE id = ?
        """,
        (next_image, rating, rating, ratings, ratings, place["id"]),
    )
    return next_image != current or rating > 0


def save_menu(db: sqlite3.Connection, restaurant_id: str, vendor_id: str, menu: list) -> int:
    db.execute("DELETE FROM restaurant_menu_items WHERE restaurant_id = ?", (restaurant_id,))
    n = 0
    for cat in menu or []:
        category = str(cat.get("name") or "").strip()
        for item in cat.get("items") or []:
            name = str(item.get("name") or "").strip()
            if not name:
                continue
            price = item.get("price")
            price_text = f"{price} SAR" if price not in (None, "") else ""
            db.execute(
                """
                INSERT OR REPLACE INTO restaurant_menu_items
                  (id, restaurant_id, category, name, description, price, image, source, sort_order)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'hungerstation', ?)
                """,
                (
                    f"hs-{item.get('id') or n}-{restaurant_id}",
                    restaurant_id,
                    category,
                    name,
                    str(item.get("description") or "").strip(),
                    price_text,
                    str(item.get("image") or "").strip(),
                    n,
                ),
            )
            n += 1
    return n


def fetch_menu(city: str, district: str, vendor: dict) -> list:
    vid = vendor.get("id")
    name = vendor.get("chainName") or vendor.get("chain_name") or "restaurant"
    url = f"{BASE}/restaurants/regions/{city}/{district}/{slugify(name)}-{vid}"
    page = fetch(url)
    time.sleep(SLEEP)
    if not page:
        return []
    return page.get("vendorMenu") or []


def run() -> None:
    db = open_db()
    state = load_progress()
    done_districts = set(state.get("districts") or [])
    done_menus = set(state.get("menus") or [])
    ours_all = load_ours(db)
    by_city: dict[str, list[sqlite3.Row]] = {}
    for row in ours_all:
        key = re.sub(r"[^a-z]+", "", (row["city"] or "").lower())
        by_city.setdefault(key, []).append(row)
        by_city.setdefault("", []).append(row)

    city_rows = cities(db)
    log(f"HungerStation cities {len(city_rows)}; our restaurants {len(ours_all)}")
    photos = int(state.get("photos") or 0)
    matched = int(state.get("matched") or 0)

    for city in city_rows:
        slug = city.get("slug")
        if not slug:
            continue
        city_page = fetch(f"{BASE}/restaurants/regions/{slug}")
        time.sleep(SLEEP)
        districts = (city_page or {}).get("districts") or []
        log(f"{slug}: {len(districts)} districts")
        city_key = re.sub(r"[^a-z]+", "", slug.replace("-", ""))
        nearby = by_city.get(city_key) or ours_all

        for district in districts:
            dslug = district.get("slug")
            if not dslug:
                continue
            dkey = f"{slug}/{dslug}"
            if dkey in done_districts:
                continue
            page_no = 1
            page_count = 1
            while page_no <= page_count:
                url = f"{BASE}/restaurants/regions/{slug}/{dslug}"
                if page_no > 1:
                    url += f"?page={page_no}"
                page = fetch(url)
                time.sleep(SLEEP)
                if not page:
                    break
                vendor_list = page.get("vendorList") or {}
                pagination = vendor_list.get("pagination") or {}
                page_count = int(pagination.get("pageCount") or page_no)
                vendors = vendor_list.get("data") or []
                for vendor in vendors:
                    place = best_match(nearby, vendor)
                    if not place:
                        continue
                    if apply_vendor(db, place, vendor):
                        photos += 1
                    matched += 1
                    vid = str(vendor.get("id"))
                    if vid in done_menus:
                        continue
                    menu = fetch_menu(slug, dslug, vendor)
                    if menu:
                        save_menu(db, place["id"], vid, menu)
                    done_menus.add(vid)
                page_no += 1
            db.commit()
            done_districts.add(dkey)
            state = {
                "districts": sorted(done_districts),
                "menus": sorted(done_menus),
                "matched": matched,
                "photos": photos,
            }
            save_progress(state)
            log(f"done {dkey} matched={matched} photos={photos} menus={len(done_menus)}")

    db.commit()
    save_progress(state)
    log(f"finished matched={matched} photos={photos} menus={len(done_menus)}")


if __name__ == "__main__":
    run()
