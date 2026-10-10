#!/usr/bin/env python3
"""Fill placeholder restaurant thumbnails from better sources.

1) Copy a real HungerStation cover already on one branch onto every
   same-name placeholder (and known brand aliases).
2) Pull missing major-brand covers from HungerStation city pages and stamp
   them nationally.

Never changes lat/lng.
"""

from __future__ import annotations

import json
import re
import sqlite3
import time
import unicodedata
import urllib.request
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT.parent / "ksa-guide-backend" / "data" / "ksa.sqlite"
BASE = "https://hungerstation.com/sa-en"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
)
SLEEP = 0.28

ALIAS_GROUPS = [
    {"albaik", "al baik", "al-baik", "البيك", "al baik restaurant"},
    {"mcdonald s", "mcdonalds", "mc donalds", "mcdonalds s", "ماكدونالدز", "مكدونالدز"},
    {"pizza hut", "بيتزا هت", "pizzahut"},
    {"burger king", "برجر كنج", "burgerking", "burger king drive thru"},
    {"dunkin donuts", "dunkin", "دانكن", "دانكن دوناتس"},
    {"domino s", "domino s pizza", "dominos", "dominos pizza", "دومينوز"},
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
    {"canton", "كانتون"},
    {"tim hortons", "تيم هورتنز"},
    {"costa coffee", "كوستا"},
    {"dr cafe", "dr cafe coffee", "دي ار كافيه", "d cafe"},
    {"papa john s", "بابا جونز", "papa johns"},
    {"little caesars", "ليتل سيزرز"},
    {"five guys", "فايف جايز"},
    {"wendy s", "ويندز"},
    {"popeyes", "بوبايز"},
    {"chili s", "تشليز"},
    {"al tazaj", "al-tazaj", "altazaj", "الطازج"},
    {"jan burger", "جان برجر"},
    {"applebee s", "applebees", "ابلبيز"},
    {"jollibee", "جوليبي"},
    {"maestro pizza", "مايسترو بيتزا", "مايسترو"},
    {"burgerfuel", "برجر فيول"},
    {"cheesecake factory", "تشيز كيك فاكتوري"},
]


def log(msg: str) -> None:
    print(msg, flush=True)


def open_db() -> sqlite3.Connection:
    db = sqlite3.connect(DB, timeout=60)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=60000")
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


def real_photo(url: str) -> bool:
    u = url or ""
    return bool(u) and "unsplash.com" not in u


def needs_photo(url: str) -> bool:
    return not real_photo(url)


def _canonical(group: set[str]) -> str:
    return sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]


def alias_root(name_norm: str) -> str:
    """Map a restaurant name onto a brand family.

    Exact match first, then prefix/token match so
    "burger king makkah mall" still maps to Burger King.
    """
    if not name_norm:
        return name_norm
    for group in ALIAS_GROUPS:
        if name_norm in group:
            return _canonical(group)
    # Longest alias first to avoid short false positives.
    for group in ALIAS_GROUPS:
        for alias in sorted(group, key=len, reverse=True):
            if len(alias) < 4:
                continue
            if name_norm == alias or name_norm.startswith(alias + " ") or name_norm.startswith(alias + "-"):
                return _canonical(group)
            # Arabic / short brand as a whole token
            tokens = set(name_norm.split())
            if " " not in alias and alias in tokens:
                return _canonical(group)
    return name_norm


def fetch(url: str) -> dict | None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept": "text/html", "Accept-Language": "en"},
    )
    try:
        with urllib.request.urlopen(req, timeout=25) as res:
            html = res.read().decode("utf-8", "replace")
    except Exception as exc:  # noqa: BLE001
        log(f"fail {url} {exc}")
        return None
    m = re.search(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html)
    if not m:
        return None
    return json.loads(m.group(1)).get("props", {}).get("pageProps") or {}


def vendor_image(vendor: dict) -> str:
    cover = vendor.get("coverPhoto") or vendor.get("cover_photo") or ""
    logo = vendor.get("logo") or ""
    image = cover or logo
    return image if real_photo(image) else ""


def counts(db: sqlite3.Connection) -> tuple[int, int]:
    real = db.execute(
        """
        SELECT COUNT(*) FROM restaurants
        WHERE image NOT LIKE '%unsplash%' AND image IS NOT NULL AND trim(image) != ''
        """
    ).fetchone()[0]
    placeholders = db.execute(
        "SELECT COUNT(*) FROM restaurants WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image)=''"
    ).fetchone()[0]
    return real, placeholders


def inherit_from_siblings(db: sqlite3.Connection) -> int:
    """Any real cover on a brand fills every placeholder of that brand/aliases."""
    best: dict[str, tuple[str, float, int]] = {}
    rows = list(db.execute("SELECT id, name, image, rating, ratings FROM restaurants"))
    for row in rows:
        key = alias_root(norm(row["name"]))
        if not key or not real_photo(row["image"] or ""):
            continue
        score = (float(row["rating"] or 0), int(row["ratings"] or 0))
        cur = best.get(key)
        if not cur or score > (cur[1], cur[2]):
            best[key] = (row["image"], float(row["rating"] or 0), int(row["ratings"] or 0))

    updates: list[tuple] = []
    for row in rows:
        if not needs_photo(row["image"] or ""):
            continue
        hit = best.get(alias_root(norm(row["name"])))
        if not hit:
            continue
        image, rating, ratings = hit
        updates.append((image, rating, rating, ratings, ratings, row["id"]))

    if not updates:
        return 0
    db.executemany(
        """
        UPDATE restaurants
        SET image = ?,
            rating = CASE WHEN ? > rating THEN ? ELSE rating END,
            ratings = CASE WHEN ? > ratings THEN ? ELSE ratings END,
            updated_at = datetime('now')
        WHERE id = ?
        """,
        updates,
    )
    db.commit()
    return len(updates)


def apply_covers(db: sqlite3.Connection, covers: dict[str, str]) -> int:
    if not covers:
        return 0
    rows = list(db.execute("SELECT id, name, image FROM restaurants"))
    updates = []
    for row in rows:
        if not needs_photo(row["image"] or ""):
            continue
        image = covers.get(alias_root(norm(row["name"])))
        if not image:
            continue
        updates.append((image, row["id"]))
    if not updates:
        return 0
    db.executemany(
        "UPDATE restaurants SET image = ?, updated_at = datetime('now') WHERE id = ?",
        updates,
    )
    db.commit()
    return len(updates)


def missing_brand_roots(db: sqlite3.Connection) -> set[str]:
    need: dict[str, int] = defaultdict(int)
    have: set[str] = set()
    for name, image in db.execute("SELECT name, image FROM restaurants"):
        key = alias_root(norm(name))
        if not key or len(key) < 3:
            continue
        if real_photo(image or ""):
            have.add(key)
        else:
            need[key] += 1
    # Big chains only — avoid hunting obscure 3-branch names forever.
    wanted = {k for k, n in need.items() if n >= 12}
    for group in ALIAS_GROUPS:
        root = sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]
        if need.get(root, 0) > 0 or any(need.get(alias, 0) > 0 for alias in group):
            wanted.add(root)
    return wanted


def crawl_brand_covers(
    db: sqlite3.Connection,
    wanted: set[str],
    city_slugs: list[str],
    max_districts_per_city: int = 18,
) -> dict[str, str]:
    """Crawl HS listings; apply each new cover to DB immediately."""
    found: dict[str, str] = {}
    for slug in city_slugs:
        remaining = wanted - found.keys()
        if not remaining:
            break
        page = fetch(f"{BASE}/restaurants/regions/{slug}")
        time.sleep(SLEEP)
        if not page:
            log(f"skip city {slug} (fetch failed)")
            continue
        districts = (page.get("districts") or [])[:max_districts_per_city]
        log(f"brand crawl {slug}: trying {len(districts)} districts, need {len(remaining)}")
        fails = 0
        for district in districts:
            remaining = wanted - found.keys()
            if not remaining:
                break
            dslug = district.get("slug")
            if not dslug:
                continue
            data = fetch(f"{BASE}/restaurants/regions/{slug}/{dslug}")
            time.sleep(SLEEP)
            if not data:
                fails += 1
                if fails >= 5:
                    log(f"  too many fails in {slug}, moving on")
                    break
                continue
            fails = 0
            vendor_list = data.get("vendorList") or {}
            new_covers: dict[str, str] = {}
            for vendor in vendor_list.get("data") or []:
                key = alias_root(norm(vendor.get("chainName") or vendor.get("chain_name") or ""))
                if key not in remaining or key in found:
                    continue
                image = vendor_image(vendor)
                if image:
                    found[key] = image
                    new_covers[key] = image
                    log(f"  cover {key}")
            if new_covers:
                n = apply_covers(db, new_covers)
                log(f"  applied +{n} (real={counts(db)[0]})")
            # Only first page per district — enough to discover major chains.
    return found


def main() -> None:
    db = open_db()
    before = counts(db)
    log(f"before real={before[0]} placeholders={before[1]}")

    n = inherit_from_siblings(db)
    mid = counts(db)
    log(f"sibling/alias inherit +{n} -> real={mid[0]} placeholders={mid[1]}")

    wanted = missing_brand_roots(db)
    log(f"hunting covers for {len(wanted)} brands: {sorted(wanted)[:40]}")
    covers = crawl_brand_covers(
        db,
        wanted,
        city_slugs=[
            "riyadh",
            "jeddah",
            "dammam",
            "al-khobar",
            "makkah",
            "madinah",
            "taif",
            "buraydah",
            "jubail",
        ],
    )
    log(f"got {len(covers)} brand covers from HungerStation")
    n2 = apply_covers(db, covers)
    n3 = inherit_from_siblings(db)
    after = counts(db)
    log(f"final apply +{n2} re-inherit +{n3} -> real={after[0]} placeholders={after[1]}")


if __name__ == "__main__":
    main()
