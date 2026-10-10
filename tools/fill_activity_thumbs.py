#!/usr/bin/env python3
"""Give each Play activity a real venue thumbnail.

Sources, in order:
  1) Curated Wikipedia / Wikidata pages for known KSA places
  2) Wikipedia search for "Name, City, Saudi Arabia" (accepted only if the
     page title actually mentions the venue)
  3) Official website Open Graph image
  4) YouTube maxres/hq still from the venue's matched reel
  5) Wikimedia Commons search

Never changes lat/lng. Writes both ksa.sqlite and activities.seed.json.
"""

from __future__ import annotations

import json
import re
import sqlite3
import time
import urllib.error
import urllib.parse
import urllib.request
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT.parent / "ksa-guide-backend"
DB = BACKEND / "data" / "ksa.sqlite"
SEED = BACKEND / "data" / "activities.seed.json"
BOT = "KSA360PlayThumbs/1.0 (activity catalog enrichment; local)"

WIKI_TITLES = {
    "abha-cable": "Al-Soudah",
    "alula-balloon": "AlUla",
    "aquarabia-qiddiya": "Qiddiya",
    "at-turaif": "At-Turaif_District",
    "boulevard-city": "Boulevard_Riyadh_City",
    "boulevard-world": "Boulevard_World",
    "bujairi-terrace": "Bujairi_Terrace",
    "edge-of-world": "Edge_of_the_World_(Saudi_Arabia)",
    "elephant-rock": "Elephant_Rock_(Al-Ula)",
    "empty-quarter": "Rub'_al_Khali",
    "empty-quarter-atv": "Rub'_al_Khali",
    "faisaliah-tower": "Al_Faisaliyah_Center",
    "fakieh-aquarium": "Fakieh_Aquarium",
    "half-moon-water": "Half_Moon_Bay_(Saudi_Arabia)",
    "hegra-tour": "Hegra_(Mada'in_Salih)",
    "hokair-water-riyadh": "Al-Hokair_Land",
    "ithra": "King_Abdulaziz_Center_for_World_Culture",
    "jax-diriyah": "JAX_District",
    "jeddah-corniche-night": "Jeddah_Corniche",
    "jubail-corniche": "Jubail",
    "kafd": "King_Abdullah_Financial_District",
    "khobar-corniche": "Khobar",
    "kidzania-jeddah": "KidZania",
    "kidzania-riyadh": "KidZania",
    "king-abdullah-park": "King_Abdullah_Park",
    "kingdom-skybridge": "Kingdom_Centre",
    "mall-ajdan": "Ajdan_Walk",
    "mall-arabia-jeddah": "Mall_of_Arabia_(Jeddah)",
    "mall-avenues-riyadh": "The_Avenues_(Riyadh)",
    "mall-dhahran": "Dhahran_Mall",
    "mall-granada": "Granada_Mall",
    "mall-jeddah-park": "Jeddah_Park",
    "mall-kingdom": "Kingdom_Centre",
    "mall-of-dhahran": "Mall_of_Dhahran",
    "mall-rashid": "Al_Rashid_Mall",
    "mall-red-sea": "Red_Sea_Mall",
    "mall-riyadh-gallery": "Riyadh_Gallery",
    "mall-riyadh-park": "Riyadh_Park",
    "mall-u-walk": "U_Walk",
    "mall-via": "VIA_Riyadh",
    "maraya": "Maraya_(concert_hall)",
    "masmak": "Masmak_Fort",
    "murabba-palace": "Murabba_Palace",
    "national-museum": "National_Museum_of_Saudi_Arabia",
    "rijal-almaa": "Rijal_Almaa",
    "riyadh-zoo": "Riyadh_Zoo",
    "salam-park": "Salam_Park_(Riyadh)",
    "scitech": "SciTech",
    "shallal-jeddah": "Al-Shallal_Theme_Park",
    "six-flags-qiddiya": "Six_Flags_Qiddiya_City",
    "snow-city-riyadh": "Snow_City_(Riyadh)",
    "souq-al-zal": "Souq_Al_Zal",
    "taif-cable": "Al-Hada",
    "the-groves": "The_Groves_(Riyadh)",
    "wadi-hanifah": "Wadi_Hanifa",
    "wadi-namar": "Wadi_Namar",
    "winter-wonderland": "Winter_Wonderland_(Riyadh)",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def real_photo(url: str) -> bool:
    u = (url or "").strip().lower()
    if not u.startswith("http"):
        return False
    if any(bad in u for bad in ("unsplash.com", "ytimg.com", "youtube.com")):
        return False
    return True


def http_get(url: str, timeout: int = 22) -> bytes | None:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": BOT,
            "Accept": "*/*",
            "Accept-Language": "en",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return res.read()
    except Exception:  # noqa: BLE001
        return None


def http_ok(url: str) -> bool:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": BOT})
    try:
        with urllib.request.urlopen(req, timeout=12) as res:
            return 200 <= res.status < 300
    except Exception:  # noqa: BLE001
        raw = http_get(url, timeout=12)
        return bool(raw and len(raw) > 2000)


def wiki_summary_image(title: str) -> str:
    slug = title.replace(" ", "_")
    raw = http_get(
        "https://en.wikipedia.org/api/rest_v1/page/summary/"
        + urllib.parse.quote(slug, safe="%")
    )
    if not raw:
        return ""
    try:
        data = json.loads(raw.decode())
    except json.JSONDecodeError:
        return ""
    for key in ("originalimage", "thumbnail"):
        src = (data.get(key) or {}).get("source") or ""
        if real_photo(src):
            return src.split("?")[0]
    return ""


def wiki_search_image(query: str, hint: str) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "format": "json",
            "srlimit": 5,
        }
    )
    raw = http_get(f"https://en.wikipedia.org/w/api.php?{qs}")
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("query", {}).get("search") or []
    except json.JSONDecodeError:
        return ""
    tokens = {t for t in re.findall(r"[a-z0-9]{4,}", hint.lower())}
    skip = {
        "saudi",
        "arabia",
        "mall",
        "park",
        "city",
        "centre",
        "center",
        "room",
        "walk",
    }
    tokens -= skip
    for hit in hits:
        title = hit.get("title") or ""
        low = title.lower()
        if tokens and not any(tok in low for tok in tokens):
            continue
        img = wiki_summary_image(title)
        if img:
            return img
    return ""


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
    raw = http_get(f"https://www.wikidata.org/w/api.php?{qs}")
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
    ent_raw = http_get(f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json")
    if not ent_raw:
        return ""
    try:
        ent = json.loads(ent_raw.decode())["entities"][qid]
    except (json.JSONDecodeError, KeyError):
        return ""
    claims = ent.get("claims") or {}
    for prop in ("P18", "P154"):
        block = claims.get(prop) or []
        if not block:
            continue
        val = ((block[0].get("mainsnak") or {}).get("datavalue") or {}).get("value")
        if isinstance(val, str) and val.strip():
            file = urllib.parse.quote(val.strip().replace(" ", "_"))
            return f"https://commons.wikimedia.org/wiki/Special:FilePath/{file}?width=1200"
    return ""


def commons_search_image(query: str) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "srnamespace": 6,
            "srlimit": 6,
            "format": "json",
        }
    )
    raw = http_get(f"https://commons.wikimedia.org/w/api.php?{qs}")
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("query", {}).get("search") or []
    except json.JSONDecodeError:
        return ""
    for hit in hits:
        title = hit.get("title") or ""
        if not title.lower().startswith("file:"):
            continue
        name = title.split(":", 1)[-1].strip()
        if not name:
            continue
        low = name.lower()
        if any(bad in low for bad in ("logo", "icon", "flag", "map", "svg")):
            continue
        file = urllib.parse.quote(name.replace(" ", "_"))
        return f"https://commons.wikimedia.org/wiki/Special:FilePath/{file}?width=1200"
    return ""


def og_image(url: str) -> str:
    if not url.startswith("http"):
        return ""
    raw = http_get(url)
    if not raw:
        return ""
    html = raw.decode("utf-8", "ignore")
    patterns = [
        r'property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']',
        r'name=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\']',
    ]
    for pat in patterns:
        m = re.search(pat, html, flags=re.I)
        if not m:
            continue
        src = unescape(m.group(1).strip())
        if src.startswith("//"):
            src = "https:" + src
        elif src.startswith("/"):
            src = urllib.parse.urljoin(url, src)
        if real_photo(src) and "svg" not in src.lower():
            return src
    return ""


def youtube_thumb(video_id: str) -> str:
    vid = (video_id or "").strip()
    if not vid or len(vid) < 6:
        return ""
    for name in ("maxresdefault", "sddefault", "hqdefault"):
        url = f"https://i.ytimg.com/vi/{vid}/{name}.jpg"
        if http_ok(url):
            return url
    return f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"


def find_photo(row: sqlite3.Row) -> tuple[str, str]:
    name = row["name"]
    city = row["city"] or ""
    hint = f"{name} {city}"
    wiki_title = WIKI_TITLES.get(row["id"])
    if wiki_title:
        img = wiki_summary_image(wiki_title)
        time.sleep(0.25)
        if img:
            return img, "wiki-map"
        img = wikidata_image(wiki_title.replace("_", " "))
        time.sleep(0.25)
        if img:
            return img, "wikidata-map"

    query = f"{name} {city} Saudi Arabia".strip()
    img = wiki_search_image(query, hint)
    time.sleep(0.25)
    if img:
        return img, "wiki-search"

    web = (row["web"] or "").strip()
    if web:
        img = og_image(web)
        time.sleep(0.2)
        if img:
            return img, "website"

    img = commons_search_image(f"{name} {city} Saudi Arabia")
    time.sleep(0.25)
    if img:
        return img, "commons"
    return "", ""


def open_db() -> sqlite3.Connection:
    db = sqlite3.connect(DB, timeout=60)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=60000")
    return db


def write_seed(updates: dict[str, str]) -> None:
    data = json.loads(SEED.read_text(encoding="utf-8"))
    places = data.get("places") or []
    for place in places:
        src = updates.get(place.get("id") or "")
        if src:
            place["image"] = src
    data["places"] = places
    SEED.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    db = open_db()
    rows = db.execute(
        "SELECT id, name, kind, city, image, web, youtube_id FROM activities ORDER BY name"
    ).fetchall()
    already = sum(1 for row in rows if real_photo(row["image"] or ""))
    log(f"activities {len(rows)}; already real {already}")
    updates: dict[str, str] = {}
    sources: dict[str, int] = {}
    for i, row in enumerate(rows, 1):
        if real_photo(row["image"] or ""):
            continue
        img, src = find_photo(row)
        if not img:
            log(f"  miss {row['id']} · {row['name']}")
            continue
        db.execute("UPDATE activities SET image = ? WHERE id = ?", (img, row["id"]))
        updates[row["id"]] = img
        sources[src] = sources.get(src, 0) + 1
        log(f"  {i}/{len(rows)} {src:12} {row['name']}")
        if i % 20 == 0:
            db.commit()
    db.commit()
    if updates:
        write_seed(updates)
    real = db.execute(
        "SELECT COUNT(*) FROM activities WHERE image NOT LIKE '%unsplash%' AND trim(image) != ''"
    ).fetchone()[0]
    log(f"updated {len(updates)} {sources}; real thumbs now {real}/{len(rows)}")
    db.close()


if __name__ == "__main__":
    main()
