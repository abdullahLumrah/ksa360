#!/usr/bin/env python3
"""Fill restaurant placeholder thumbnails from many sources.

Order of preference per place / brand:
  1) Sibling branch that already has a real cover (incl. brand aliases)
  2) Wikipedia / Wikidata (P154 logo, P18 image)
  3) Open Graph / twitter:image / apple-touch-icon from restaurant website
  4) HungerStation cover (when reachable)
  5) Google s2 favicon for website domain (last resort)

Never changes lat/lng.
"""

from __future__ import annotations

import json
import re
import sqlite3
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT.parent / "ksa-guide-backend" / "data" / "ksa.sqlite"
HS = "https://hungerstation.com/sa-en"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
)
BOT = "KSA360ThumbBot/1.0 (local restaurant catalog enrichment)"

ALIAS_GROUPS = [
    {"albaik", "al baik", "al-baik", "البيك", "al baik restaurant", "albaik restaurant"},
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
    {"applebee s", "applebees", "ابلبيز"},
    {"jollibee", "جولي بي"},
    {"cheesecake factory", "ذا تشيز كيك فاكتوري"},
    {"pizza company", "ذي بيتزا كومباني"},
    {"texas chicken", "تكساس تشيكن"},
    {"paul", "بول"},
    {"pizzahut", "pizza hut"},
]

# Direct Wikipedia titles that often resolve better than free-text search.
WIKI_TITLES = {
    "albaik": "Al_Baik",
    "mcdonald s": "McDonald%27s",
    "pizza hut": "Pizza_Hut",
    "burger king": "Burger_King",
    "dunkin donuts": "Dunkin%27_Donuts",
    "domino s": "Domino%27s",
    "kfc": "KFC",
    "herfy": "Herfy",
    "kudu": "Kudu_(restaurant)",
    "starbucks": "Starbucks",
    "subway": "Subway_(restaurant)",
    "hardee s": "Hardee%27s",
    "baskin robbins": "Baskin-Robbins",
    "krispy kreme": "Krispy_Kreme",
    "shawarmer": "Shawarmer",
    "tim hortons": "Tim_Hortons",
    "costa coffee": "Costa_Coffee",
    "papa john s": "Papa_John%27s",
    "little caesars": "Little_Caesars",
    "five guys": "Five_Guys",
    "wendy s": "Wendy%27s",
    "popeyes": "Popeyes",
    "chili s": "Chili%27s",
    "applebee s": "Applebee%27s",
    "jollibee": "Jollibee",
    "cheesecake factory": "The_Cheesecake_Factory",
    "pizza company": "The_Pizza_Company",
    "texas chicken": "Texas_Chicken",
}


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


def alias_root(name_norm: str) -> str:
    for group in ALIAS_GROUPS:
        if name_norm in group:
            return sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]
    return name_norm


def real_photo(url: str) -> bool:
    u = (url or "").strip()
    if not u or "unsplash.com" in u:
        return False
    # Tiny favicons are allowed only as last resort; still "real".
    return u.startswith("http")


def needs_photo(url: str) -> bool:
    return not real_photo(url)


def http_get(url: str, headers: dict | None = None, timeout: int = 22) -> bytes | None:
    req = urllib.request.Request(
        url,
        headers=headers
        or {
            "User-Agent": UA,
            "Accept": "*/*",
            "Accept-Language": "en",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return res.read()
    except Exception as exc:  # noqa: BLE001
        log(f"  get-fail {url[:90]} :: {exc}")
        return None


def counts(db: sqlite3.Connection) -> tuple[int, int]:
    real = db.execute(
        """
        SELECT COUNT(*) FROM restaurants
        WHERE image NOT LIKE '%unsplash%' AND image IS NOT NULL AND trim(image) != ''
        """
    ).fetchone()[0]
    placeholders = db.execute(
        """
        SELECT COUNT(*) FROM restaurants
        WHERE image LIKE '%unsplash%' OR image IS NULL OR trim(image) = ''
        """
    ).fetchone()[0]
    return real, placeholders


def set_images(db: sqlite3.Connection, updates: list[tuple[str, str]], source: str) -> int:
    if not updates:
        return 0
    db.executemany(
        "UPDATE restaurants SET image = ?, updated_at = datetime('now') WHERE id = ?",
        updates,
    )
    db.commit()
    log(f"  {source}: wrote {len(updates)}")
    return len(updates)


def inherit_siblings(db: sqlite3.Connection) -> int:
    best: dict[str, str] = {}
    rows = list(db.execute("SELECT id, name, image, rating, ratings FROM restaurants"))
    for row in rows:
        key = alias_root(norm(row["name"]))
        if not key or not real_photo(row["image"] or ""):
            continue
        # Prefer non-favicon / non-logo-tiny looking URLs when possible.
        img = row["image"]
        prev = best.get(key)
        if not prev or ("favicon" in prev and "favicon" not in img):
            best[key] = img
    updates = []
    for row in rows:
        if not needs_photo(row["image"] or ""):
            continue
        hit = best.get(alias_root(norm(row["name"])))
        if hit:
            updates.append((hit, row["id"]))
    return set_images(db, updates, "sibling-inherit")


def commons_file_url(filename: str, width: int = 900) -> str:
    name = filename.replace(" ", "_")
    return (
        "https://commons.wikimedia.org/wiki/Special:FilePath/"
        f"{urllib.parse.quote(name)}?width={width}"
    )


def wiki_summary_image(title: str) -> str:
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
    raw = http_get(url, headers={"User-Agent": BOT, "Accept": "application/json"})
    if not raw:
        return ""
    try:
        data = json.loads(raw.decode("utf-8", "replace"))
    except json.JSONDecodeError:
        return ""
    for key in ("originalimage", "thumbnail"):
        src = ((data.get(key) or {}).get("source") or "").strip()
        if src and real_photo(src):
            return src
    return ""


def wiki_search_image(query: str) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "format": "json",
            "srlimit": 1,
        }
    )
    raw = http_get(
        f"https://en.wikipedia.org/w/api.php?{qs}",
        headers={"User-Agent": BOT, "Accept": "application/json"},
    )
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("query", {}).get("search") or []
    except json.JSONDecodeError:
        return ""
    if not hits:
        return ""
    title = hits[0].get("title") or ""
    if not title:
        return ""
    return wiki_summary_image(urllib.parse.quote(title.replace(" ", "_"), safe="%"))


def wikidata_image(query: str) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "wbsearchentities",
            "search": query,
            "language": "en",
            "format": "json",
            "limit": 1,
        }
    )
    raw = http_get(
        f"https://www.wikidata.org/w/api.php?{qs}",
        headers={"User-Agent": BOT, "Accept": "application/json"},
    )
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("search") or []
    except json.JSONDecodeError:
        return ""
    if not hits:
        return ""
    qid = hits[0].get("id")
    if not qid:
        return ""
    ent_raw = http_get(
        f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json",
        headers={"User-Agent": BOT, "Accept": "application/json"},
    )
    if not ent_raw:
        return ""
    try:
        ent = json.loads(ent_raw.decode())["entities"][qid]
    except (json.JSONDecodeError, KeyError):
        return ""
    claims = ent.get("claims") or {}
    for prop in ("P154", "P18", "P41"):
        block = claims.get(prop) or []
        if not block:
            continue
        val = (
            ((block[0].get("mainsnak") or {}).get("datavalue") or {}).get("value")
        )
        if isinstance(val, str) and val.strip():
            return commons_file_url(val.strip())
    return ""


def brand_wiki_covers(wanted: set[str]) -> dict[str, str]:
    """Only known chains — free-text wiki search invents wrong images & gets 429s."""
    found: dict[str, str] = {}
    keys = sorted(k for k in wanted if k in WIKI_TITLES)
    log(f"  wiki known chains: {len(keys)}")
    for key in keys:
        img = wiki_summary_image(WIKI_TITLES[key])
        time.sleep(0.55)
        title = WIKI_TITLES[key].replace("_", " ").replace("%27", "'")
        if not img:
            img = wiki_search_image(title)
            time.sleep(0.55)
        if not img:
            img = wikidata_image(title)
            time.sleep(0.55)
        if img:
            found[key] = img
            log(f"  wiki/wd {key}")
        else:
            log(f"  wiki-miss {key}")
    return found


def extract_meta_images(html: str, base: str) -> list[str]:
    patterns = [
        r'property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']',
        r'name=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'content=["\']([^"\']+)["\'][^>]*name=["\']twitter:image["\']',
        r'rel=["\']apple-touch-icon[^"\']*["\'][^>]*href=["\']([^"\']+)["\']',
        r'href=["\']([^"\']+)["\'][^>]*rel=["\']apple-touch-icon[^"\']*["\']',
        r'rel=["\']icon["\'][^>]*href=["\']([^"\']+)["\']',
    ]
    out = []
    for pat in patterns:
        for m in re.finditer(pat, html, flags=re.I):
            url = unescape(m.group(1).strip())
            if url.startswith("//"):
                url = "https:" + url
            elif url.startswith("/"):
                url = urllib.parse.urljoin(base, url)
            if url.startswith("http") and url not in out:
                out.append(url)
    return out


def website_images(db: sqlite3.Connection, limit: int = 400) -> int:
    rows = list(
        db.execute(
            """
            SELECT id, name, web, image FROM restaurants
            WHERE (image LIKE '%unsplash%' OR image IS NULL OR trim(image)='')
              AND web IS NOT NULL AND trim(web) != ''
            ORDER BY length(web) DESC
            LIMIT ?
            """,
            (limit,),
        )
    )
    # Deduplicate by domain so we don't hammer the same host.
    by_domain: dict[str, list[sqlite3.Row]] = defaultdict(list)
    for row in rows:
        host = urllib.parse.urlparse(row["web"]).netloc.lower().removeprefix("www.")
        if host:
            by_domain[host].append(row)

    domain_image: dict[str, str] = {}
    for host, group in by_domain.items():
        web = group[0]["web"]
        if not web.startswith("http"):
            web = "https://" + web
        raw = http_get(web, timeout=12)
        time.sleep(0.2)
        img = ""
        if raw:
            html = raw.decode("utf-8", "replace")[:250000]
            metas = extract_meta_images(html, web)
            img = next((u for u in metas if real_photo(u) and "svg" not in u.lower()), "")
            if not img and metas:
                img = metas[0]
        if not img:
            img = f"https://www.google.com/s2/favicons?domain={host}&sz=256"
        domain_image[host] = img
        log(f"  web {host}")

    updates = []
    for host, group in by_domain.items():
        img = domain_image.get(host)
        if not img:
            continue
        for row in group:
            updates.append((img, row["id"]))
    return set_images(db, updates, "website-og/favicon")


def hs_next_data(url: str) -> dict | None:
    raw = http_get(url)
    if not raw:
        return None
    m = re.search(rb'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', raw)
    if not m:
        return None
    try:
        return json.loads(m.group(1)).get("props", {}).get("pageProps") or {}
    except json.JSONDecodeError:
        return None


def hungerstation_brand_covers(wanted: set[str], city_slugs: list[str]) -> dict[str, str]:
    found: dict[str, str] = {}
    for slug in city_slugs:
        if len(found) >= min(40, len(wanted)):
            break
        page = hs_next_data(f"{HS}/restaurants/regions/{slug}")
        time.sleep(0.3)
        if not page:
            continue
        districts = page.get("districts") or []
        log(f"  hs {slug}: {len(districts)} districts")
        for district in districts[:25]:
            if len(found) >= min(40, len(wanted)):
                break
            dslug = district.get("slug")
            if not dslug:
                continue
            data = hs_next_data(f"{HS}/restaurants/regions/{slug}/{dslug}")
            time.sleep(0.3)
            if not data:
                continue
            for vendor in ((data.get("vendorList") or {}).get("data") or []):
                key = alias_root(norm(vendor.get("chainName") or vendor.get("chain_name") or ""))
                if key not in wanted or key in found:
                    continue
                cover = vendor.get("coverPhoto") or vendor.get("cover_photo") or vendor.get("logo") or ""
                if real_photo(cover):
                    found[key] = cover
                    log(f"  hs-cover {key}")
    return found


def apply_brand_map(db: sqlite3.Connection, covers: dict[str, str], label: str) -> int:
    rows = list(db.execute("SELECT id, name, image FROM restaurants"))
    updates = []
    for row in rows:
        if not needs_photo(row["image"] or ""):
            continue
        img = covers.get(alias_root(norm(row["name"])))
        if img:
            updates.append((img, row["id"]))
    return set_images(db, updates, label)


def missing_brand_roots(db: sqlite3.Connection, min_count: int = 2) -> set[str]:
    need: dict[str, int] = defaultdict(int)
    for name, image in db.execute("SELECT name, image FROM restaurants"):
        key = alias_root(norm(name))
        if not key or len(key) < 3:
            continue
        if needs_photo(image or ""):
            need[key] += 1
    wanted = {k for k, n in need.items() if n >= min_count}
    for group in ALIAS_GROUPS:
        wanted.add(sorted(group, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0])
    return wanted


def main() -> None:
    db = open_db()
    before = counts(db)
    log(f"before real={before[0]} placeholders={before[1]}")

    inherit_siblings(db)
    log(f"after inherit {counts(db)}")

    # Website assets first (many unique places have a site; no rate-limit wall).
    log("website og/favicon pass")
    website_images(db, limit=800)
    inherit_siblings(db)
    log(f"after websites {counts(db)}")

    wanted = {alias_root(k) for k in WIKI_TITLES} | {
        sorted(g, key=lambda s: (0 if re.search(r"[a-z]", s) else 1, len(s)))[0]
        for g in ALIAS_GROUPS
    }
    # Only fill known chains still missing on some branches.
    still_need = missing_brand_roots(db, min_count=1)
    wanted &= still_need
    log(f"wiki/wd hunt for {len(wanted)} known chains")
    wiki_covers = brand_wiki_covers(wanted)
    apply_brand_map(db, wiki_covers, "wikipedia/wikidata")
    inherit_siblings(db)
    log(f"after wiki {counts(db)}")

    still = missing_brand_roots(db, min_count=5)
    still = {k for k in still if k in WIKI_TITLES or any(k in g for g in ALIAS_GROUPS)}
    if still:
        log(f"hungerstation fallback for {len(still)} known brands")
        hs = hungerstation_brand_covers(
            still,
            ["riyadh", "jeddah", "dammam", "makkah", "madinah"],
        )
        apply_brand_map(db, hs, "hungerstation")
        inherit_siblings(db)

    after = counts(db)
    log(f"DONE real={after[0]} placeholders={after[1]} (+{after[0] - before[0]})")


if __name__ == "__main__":
    main()
