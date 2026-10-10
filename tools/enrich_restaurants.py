#!/usr/bin/env python3
"""Match OSM restaurants to HungerStation covers, ratings, and menus.

Coordinates on our restaurants are never changed.

Default is photos-first: crawl HungerStation covers/logos and stamp them onto
placeholder (Unsplash) thumbnails by geo match + exact chain name. Pass
--menus to also pull vendor menus (much slower).
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sqlite3
import time
import unicodedata
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
SLEEP = 0.35
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

# HS city slug -> our city name keys that should share covers.
METRO = {
    "riyadh": {"riyadh", "diriyah"},
    "jeddah": {"jeddah"},
    "dammam": {"dammam", "khobar", "alkhobar", "dhahran", "qatif"},
    "al-khobar": {"khobar", "alkhobar", "dammam", "dhahran"},
    "khobar": {"khobar", "alkhobar", "dammam", "dhahran"},
    "mecca": {"makkah", "mecca"},
    "makkah": {"makkah", "mecca"},
    "madinah": {"madinah", "medina"},
    "medina": {"madinah", "medina"},
    "taif": {"taif"},
    "buraydah": {"buraidah", "buraydah"},
    "hofuf": {"hofufalahsa", "hofuf", "alahsa"},
    "jubail": {"jubail"},
    "yanbu": {"yanbu"},
    "tabuk": {"tabuk"},
    "abha": {"abha", "khamismushait"},
    "khamis-mushait": {"khamismushait", "abha"},
    "jazan": {"jazan", "jizan"},
}


def log(msg: str) -> None:
    print(msg, flush=True)


def open_db() -> sqlite3.Connection:
    db = sqlite3.connect(DB, timeout=60)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=60000")
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


def city_key(value: str) -> str:
    return re.sub(r"[^a-z]+", "", (value or "").lower())


def km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    p = math.pi / 180
    a = (
        0.5
        - math.cos((lat2 - lat1) * p) / 2
        + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2
    )
    return 12742 * math.asin(math.sqrt(max(0, min(1, a))))


def real_photo(url: str) -> bool:
    return bool(url) and "unsplash.com" not in (url or "")


def needs_photo(url: str) -> bool:
    return (not url) or "unsplash.com" in url


def vendor_image(vendor: dict) -> str:
    cover = vendor.get("coverPhoto") or vendor.get("cover_photo") or ""
    logo = vendor.get("logo") or ""
    image = cover or logo
    return image if real_photo(image) else ""


def vendor_rating(vendor: dict) -> tuple[float, int]:
    try:
        rating = float(vendor.get("averageRating") or vendor.get("average_rating") or 0)
    except (TypeError, ValueError):
        rating = 0.0
    try:
        ratings = int(float(vendor.get("rateCount") or vendor.get("rate_count") or 0))
    except (TypeError, ValueError):
        ratings = 0
    return rating, ratings


def cities(db: sqlite3.Connection) -> list[dict]:
    ours = {city_key(row["city"]) for row in db.execute("SELECT DISTINCT city FROM restaurants")}
    page = fetch(f"{BASE}/restaurants/regions")
    rows = (page or {}).get("cities") or []
    ranked = []
    for city in rows:
        slug = city.get("slug") or ""
        key = city_key(slug.replace("-", ""))
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
    # Exact chain name: allow metro-scale distance (covers wrong-district pages).
    if left == right:
        if dist > 35:
            return 0
        return 0.88 + max(0.0, 1 - dist / 35) * 0.12
    if dist > 3.2:
        return 0
    if left in right or right in left:
        name = 0.86
    else:
        a, b = set(left.split()), set(right.split())
        name = len(a & b) / max(1, len(a | b))
        if name < 0.55:
            return 0
        if min(len(a), len(b)) == 1 and min(len(tok) for tok in a | b) < 5:
            return 0
    boost = 0.08 if needs_photo(place["image"] or "") else 0
    return name * 0.72 + max(0, 1 - dist / 3.2) * 0.28 + boost


def best_match(ours: list[sqlite3.Row], vendor: dict) -> sqlite3.Row | None:
    best = None
    best_score = 0.62
    for place in ours:
        s = score_match(place, vendor)
        if s > best_score:
            best, best_score = place, s
    return best


def set_image(
    db: sqlite3.Connection,
    restaurant_id: str,
    image: str,
    rating: float = 0,
    ratings: int = 0,
) -> bool:
    row = db.execute("SELECT image FROM restaurants WHERE id = ?", (restaurant_id,)).fetchone()
    if not row:
        return False
    current = row["image"] or ""
    if not image or not real_photo(image):
        return False
    # Only replace Unsplash / empty placeholders. Keep real covers as-is.
    if needs_photo(current):
        db.execute(
            """
            UPDATE restaurants
            SET image = ?,
                rating = CASE WHEN ? > rating THEN ? ELSE rating END,
                ratings = CASE WHEN ? > ratings THEN ? ELSE ratings END,
                updated_at = datetime('now')
            WHERE id = ?
            """,
            (image, rating, rating, ratings, ratings, restaurant_id),
        )
        return True
    if rating > 0 or ratings > 0:
        db.execute(
            """
            UPDATE restaurants
            SET rating = CASE WHEN ? > rating THEN ? ELSE rating END,
                ratings = CASE WHEN ? > ratings THEN ? ELSE ratings END,
                updated_at = datetime('now')
            WHERE id = ?
            """,
            (rating, rating, ratings, ratings, restaurant_id),
        )
    return False


def apply_vendor(db: sqlite3.Connection, place: sqlite3.Row, vendor: dict) -> bool:
    image = vendor_image(vendor)
    rating, ratings = vendor_rating(vendor)
    if not image:
        return False
    return set_image(db, place["id"], image, rating, ratings)


# Same-brand spellings share one HungerStation cover nationwide.
_ALIAS_GROUPS = [
    {"albaik", "al baik", "al-baik", "البيك"},
    {"mcdonald s", "mcdonalds", "mc donalds", "ماكدونالدز", "مكدونالدز"},
    {"pizza hut", "بيتزا هت", "pizzahut"},
    {"burger king", "برجر كنج", "burgerking"},
    {"dunkin donuts", "dunkin", "دانكن", "دانكن دوناتس"},
    {"domino s", "domino s pizza", "dominos", "دومينوز"},
    {"kfc", "kentucky", "كنتاكي"},
    {"herfy", "هرفي"},
    {"kudu", "كودو"},
    {"starbucks", "ستاربكس"},
    {"subway", "صب واي", "صبواي"},
    {"hardee s", "هارديز", "hardees"},
    {"baskin robbins", "باسكن روبنز"},
    {"krispy kreme", "كريسبي كريم"},
    {"shawarmer", "شاورمر"},
    {"barn s", "barns", "بارنز"},
    {"tim hortons", "تيم هورتنز"},
    {"papa john s", "بابا جونز", "papa johns"},
]


def _alias_root(name_norm: str) -> str:
    for group in _ALIAS_GROUPS:
        if name_norm in group:
            return sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]
    return name_norm


def apply_chain_name(
    db: sqlite3.Connection,
    vendor: dict,
    metro_keys: set[str] | None = None,
) -> int:
    """Stamp this vendor cover onto every placeholder with the same chain name.

    Applies nationwide (not only the current metro) so a Riyadh Herfy cover
    also fills Jeddah / Khobar branches still on Unsplash.
    """
    image = vendor_image(vendor)
    if not image:
        return 0
    right = _alias_root(norm(vendor.get("chainName") or vendor.get("chain_name") or ""))
    if not right or len(right) < 3:
        return 0
    rating, ratings = vendor_rating(vendor)
    updated = 0
    rows = db.execute(
        """
        SELECT id, name, city, image FROM restaurants
        WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
        """
    ).fetchall()
    for row in rows:
        left = _alias_root(norm(row["name"]))
        if left != right:
            continue
        if set_image(db, row["id"], image, rating, ratings):
            updated += 1
    return updated


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


def placeholder_count(db: sqlite3.Connection) -> int:
    return db.execute(
        """
        SELECT COUNT(*) AS n FROM restaurants
        WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
        """
    ).fetchone()["n"]


def real_count(db: sqlite3.Connection) -> int:
    return db.execute(
        """
        SELECT COUNT(*) AS n FROM restaurants
        WHERE image NOT LIKE '%unsplash%' AND image IS NOT NULL AND trim(image) != ''
        """
    ).fetchone()["n"]


def run(photos_only: bool = True, reset_districts: bool = False) -> None:
    db = open_db()
    state = load_progress()
    if reset_districts:
        state["districts"] = []
        log("district progress reset (menus kept); re-crawling for photos")
    done_districts = set(state.get("districts") or [])
    done_menus = set(state.get("menus") or [])
    ours_all = load_ours(db)
    by_city: dict[str, list[sqlite3.Row]] = {}
    for row in ours_all:
        by_city.setdefault(city_key(row["city"]), []).append(row)

    city_rows = cities(db)
    log(
        f"HungerStation cities {len(city_rows)}; our restaurants {len(ours_all)}; "
        f"real photos {real_count(db)}; placeholders {placeholder_count(db)}; "
        f"mode={'photos' if photos_only else 'photos+menus'}"
    )
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
        metro = METRO.get(slug) or {city_key(slug.replace("-", ""))}
        nearby: list[sqlite3.Row] = []
        for key in metro:
            nearby.extend(by_city.get(key) or [])
        if not nearby:
            nearby = ours_all

        for district in districts:
            dslug = district.get("slug")
            if not dslug:
                continue
            dkey = f"{slug}/{dslug}"
            if dkey in done_districts:
                continue
            page_no = 1
            page_count = 1
            district_photos = 0
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
                    if place and apply_vendor(db, place, vendor):
                        photos += 1
                        district_photos += 1
                        matched += 1
                    # Chain-name backfill: one HS cover fills every branch still on Unsplash.
                    n = apply_chain_name(db, vendor, metro)
                    if n:
                        photos += n
                        district_photos += n
                        matched += n
                    if photos_only:
                        continue
                    vid = str(vendor.get("id"))
                    if not place or vid in done_menus:
                        continue
                    menu = fetch_menu(slug, dslug, vendor)
                    if menu:
                        save_menu(db, place["id"], vid, menu)
                    done_menus.add(vid)
                page_no += 1
            db.commit()
            # Reload city slices so later districts see already-updated images.
            ours_all = load_ours(db)
            by_city = {}
            for row in ours_all:
                by_city.setdefault(city_key(row["city"]), []).append(row)
            nearby = []
            for key in metro:
                nearby.extend(by_city.get(key) or [])
            if not nearby:
                nearby = ours_all

            done_districts.add(dkey)
            state = {
                "districts": sorted(done_districts),
                "menus": sorted(done_menus),
                "matched": matched,
                "photos": photos,
            }
            save_progress(state)
            log(
                f"done {dkey} +{district_photos} "
                f"photos_total={photos} real={real_count(db)} "
                f"placeholders={placeholder_count(db)} menus={len(done_menus)}"
            )

    db.commit()
    save_progress(state)
    log(
        f"finished matched={matched} photos={photos} "
        f"real={real_count(db)} placeholders={placeholder_count(db)} menus={len(done_menus)}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--menus",
        action="store_true",
        help="Also fetch HungerStation menus (slow).",
    )
    parser.add_argument(
        "--reset-districts",
        action="store_true",
        help="Re-crawl districts for photos (keeps saved menus).",
    )
    args = parser.parse_args()
    run(photos_only=not args.menus, reset_districts=args.reset_districts)


if __name__ == "__main__":
    main()
