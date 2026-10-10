#!/usr/bin/env python3
"""Assign each Play activity a unique real-place thumbnail.

No YouTube stills. No one bowling / dune / mall photo copied onto siblings
in a different building. Same mall + its bowling + its cinema may share
that mall's photo.
"""

from __future__ import annotations

import json
import sqlite3
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT.parent / "ksa-guide-backend"
DB = BACKEND / "data" / "ksa.sqlite"
SEED = BACKEND / "data" / "activities.seed.json"
BOT = "KSA360PlayThumbs/1.1 (venue catalog; local enrichment)"

# Exact Commons files for bowling halls / host malls / dune fields.
PLACE_FILE = {
    "ubc-bowling": "Bowling_alley.jpg",
    "fun-city-bowling-rp": "Riyadh_Park.JPG",
    "bowling-nakheel": "Nakheel-Mall3.jpg",
    "bowling-riyadh-gallery": "Riyadh_Gallery.jpg",
    "bowling-granada": "Granada_Centre_from_inside.jpg",
    "hofuf-bowling": "Craftsmen_Market_in_al-Ahsa,_Hofuf_-_Mar_7,_2020_11.jpg",
    "bowling-dhahran": "Mall_Of_Dhahran_(en).jpg",
    "bowling-red-sea": "Red_Sea_Mall_1_Jeddah.jpg",
    "bowling-moa": "Mall_of_Arabia,_Jeddah.jpg",
    "bowling-buraidah": "Buraidah.jpg",
    "khobar-bowling": "Khobar_water_tower.jpg",
    "mall-riyadh-park": "Riyadh_Park.JPG",
    "mall-nakheel": "Nakheel-Mall3.jpg",
    "mall-riyadh-gallery": "Riyadh_Gallery.jpg",
    "mall-granada": "Granada_Centre.jpg",
    "sahara-mall": "Riyadh_Sahara_Mall.JPG",
    "mall-front": "Riyadh_Front_Shopping_Area.jpg",
    "mall-kingdom": "Kingdom_Centre_Riyadh_2024.jpeg",
    "mall-red-sea": "Red_Sea_Mall_1_Jeddah.jpg",
    "mall-arabia-jeddah": "Mall_of_Arabia,_Jeddah.jpg",
    "mall-of-dhahran": "Mall_Of_Dhahran_(en).jpg",
    "mall-dhahran": "Mall_Of_Dhahran_(ar).jpg",
    "mall-qassim": "Date_City_in_Buraidah_8.JPG",
    "mall-panorama": "Riyadh_Park1.JPG",
    "centria-mall": "Riyadh_Park2.JPG",
    "al-qasr-mall": "Riyadh_Front,_2023.jpg",
    "mall-ahsa": "Craftsmen_Market_in_al-Ahsa,_Hofuf_-_Mar_7,_2020_08.jpg",
    "red-sands-safari": "Red_Sands_-_A_Typical_Saudi_Landscape.jpg",
    "red-sands-atv": "RedsandsnearRiyadh..JPG",
    "red-sands-sandboard": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(4)_(50620707316).jpg",
    "red-sands-private-4x4": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(10)_(50619961483).jpg",
    "red-sands-camp": "Al-Dahna,_eastern_Saudi_Arabia_(1)_(50620816167).jpg",
    "thumamah-atv": "Tuwaiq_Escarpment-14h38m25s-k.jpg",
    "thumamah-bashing": "Tuwaiq_Escarpment_(2981960802).jpg",
    "thumamah-dunes": "Riyadh-Makkah_Road_near_Tuwaiq_Escarpment.JPG",
    "thumamah-kids-atv": "Saudi_Arabia_(6374669841).jpg",
    "dirab-atv": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(3)_(50620814557).jpg",
    "ahsa-atv": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(14)_(50619959528).jpg",
    "qassim-atv": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(13)_(50620809412).jpg",
    "qassim-desert": "Al-Dahna,_eastern_Saudi_Arabia_(6)_(50619955498).jpg",
    "dammam-atv": "Al-Dahna,_eastern_Saudi_Arabia_(10)_(50619966953).jpg",
    "jeddah-atv": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(2)_(50619963308).jpg",
    "madinah-atv": "Al-Dahna,_eastern_Saudi_Arabia_(5)_(50620815337).jpg",
    "empty-quarter": "Rub_al_Khali_002.JPG",
    "empty-quarter-atv": "Rub'_al-Khali_(5071500944).jpg",
}

# Same building may share. Different buildings must not.
SHARE = {
    "ubc-arcade": "ubc-bowling",
    "ubc-billiards": "ubc-bowling",
    "vox-riyadh-park": "mall-riyadh-park",
    "magic-planet-rp": "mall-riyadh-park",
    "vox-riyadh-gallery": "mall-riyadh-gallery",
    "vox-granada": "mall-granada",
    "sparkys-granada": "mall-granada",
    "timezone-granada": "mall-granada",
    "vox-red-sea": "mall-red-sea",
    "vox-moa": "mall-arabia-jeddah",
    "ice-jeddah": "mall-arabia-jeddah",
    "vox-dhahran": "mall-of-dhahran",
    "vox-mall-dhahran": "mall-dhahran",
    "vox-kingdom": "mall-kingdom",
    "kingdom-skybridge": "mall-kingdom",
}

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
    "king-abdullah-park": "King_Abdullah_Park",
    "mall-ajdan": "Ajdan_Walk",
    "mall-avenues-riyadh": "The_Avenues_(Riyadh)",
    "mall-jeddah-park": "Jeddah_Park",
    "mall-rashid": "Al_Rashid_Mall",
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
    "taif-cable": "Al_Hada",
    "the-groves": "The_Groves_(Riyadh)",
    "wadi-hanifah": "Wadi_Hanifa",
    "wadi-namar": "Wadi_Namar",
    "winter-wonderland": "Winter_Wonderland_(Riyadh)",
    "mall-salam": "Salam_Mall",
    "diriyah-horses": "Diriyah",
    "ula-atv": "AlUla",
    "tabuk-desert": "Tabuk,_Saudi_Arabia",
    "tabuk-atv": "Harrat_Rahat",
    "yanbu-sandboard": "Yanbu",
    "yanbu-beach": "Yanbu",
    "jazan-island": "Jazan",
    "najran-park": "Najran",
    "camel-club-riyadh": "Janadriyah",
    "madinah-mall-cinema": "Medina",
    "mall-madinah": "Medina",
    "makkah-mall-kids": "Mecca",
    "mall-abha": "Abha",
    "mall-tabuk": "Tabuk,_Saudi_Arabia",
    "mall-stars-avenue": "Jeddah",
    "esplanade-riyadh": "Riyadh",
    "hafr-mall": "Hafar_al-Batin",
    "buraidah-cinema": "Buraidah",
    "alula-balloon": "AlUla",
    "vox-jeddah-park": "Jeddah_Park",
    "vox-ajdan": "Ajdan_Walk",
    "vox-via-riyadh": "VIA_Riyadh",
    "amc-jeddah": "Jeddah",
    "amc-riyadh-front": "Riyadh_Front",
    "snow-jeddah": "Mall_of_Arabia_(Jeddah)",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def is_bad(url: str) -> bool:
    u = (url or "").lower()
    return (
        not u.startswith("http")
        or "unsplash.com" in u
        or "ytimg.com" in u
        or "youtube.com" in u
        or "logo.svg" in u
        or ".pdf" in u
        or ".svg" in u
    )


def http_get(url: str, timeout: int = 22) -> bytes | None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": BOT, "Accept": "*/*", "Accept-Language": "en"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            return res.read()
    except Exception:  # noqa: BLE001
        return None


def commons_urls(names: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for i in range(0, len(names), 40):
        chunk = names[i : i + 40]
        titles = "|".join("File:" + n.replace(" ", "_") for n in chunk)
        qs = urllib.parse.urlencode(
            {
                "action": "query",
                "titles": titles,
                "prop": "imageinfo",
                "iiprop": "url",
                "iiurlwidth": 1400,
                "format": "json",
            }
        )
        raw = http_get(f"https://commons.wikimedia.org/w/api.php?{qs}")
        time.sleep(0.4)
        if not raw:
            continue
        try:
            pages = json.loads(raw.decode()).get("query", {}).get("pages", {})
        except json.JSONDecodeError:
            continue
        for page in pages.values():
            title = (page.get("title") or "").split(":", 1)[-1]
            info = (page.get("imageinfo") or [{}])[0]
            url = info.get("thumburl") or info.get("url") or ""
            if url and "ytimg" not in url:
                out[title.replace(" ", "_")] = url
                out[title] = url
    return out


def wiki_image(title: str) -> str:
    slug = title.replace(" ", "_")
    raw = http_get(
        "https://en.wikipedia.org/api/rest_v1/page/summary/"
        + urllib.parse.quote(slug, safe="%")
    )
    time.sleep(0.55)
    if not raw:
        return ""
    try:
        data = json.loads(raw.decode())
    except json.JSONDecodeError:
        return ""
    for key in ("originalimage", "thumbnail"):
        src = (data.get(key) or {}).get("source") or ""
        if src.startswith("http") and "ytimg" not in src and ".svg" not in src.lower():
            return src
    return ""


def commons_search(query: str, used: set[str], limit: int = 8) -> str:
    qs = urllib.parse.urlencode(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "srnamespace": 6,
            "srlimit": limit,
            "format": "json",
        }
    )
    raw = http_get(f"https://commons.wikimedia.org/w/api.php?{qs}")
    time.sleep(0.55)
    if not raw:
        return ""
    try:
        hits = json.loads(raw.decode()).get("query", {}).get("search") or []
    except json.JSONDecodeError:
        return ""
    names = []
    for hit in hits:
        title = hit.get("title") or ""
        if not title.lower().startswith("file:"):
            continue
        name = title.split(":", 1)[-1].strip()
        low = name.lower()
        if any(bad in low for bad in ("logo", "icon", "flag", "map", "svg", "pdf")):
            continue
        names.append(name)
    resolved = commons_urls(names)
    for name in names:
        url = resolved.get(name.replace(" ", "_")) or resolved.get(name)
        if url and url not in used:
            return url
    return ""


def og_image(url: str) -> str:
    raw = http_get(url)
    if not raw:
        return ""
    html = raw.decode("utf-8", "ignore")
    import re
    from html import unescape

    for pat in (
        r'property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
        r'content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']',
    ):
        m = re.search(pat, html, flags=re.I)
        if not m:
            continue
        src = unescape(m.group(1).strip())
        if src.startswith("//"):
            src = "https:" + src
        elif src.startswith("/"):
            src = urllib.parse.urljoin(url, src)
        if src.startswith("http") and "ytimg" not in src and ".svg" not in src.lower():
            return src
    return ""


def write_seed(by_id: dict[str, str]) -> None:
    data = json.loads(SEED.read_text(encoding="utf-8"))
    for place in data.get("places") or []:
        src = by_id.get(place.get("id") or "")
        if src:
            place["image"] = src
    SEED.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    db = sqlite3.connect(DB, timeout=60)
    db.row_factory = sqlite3.Row
    rows = list(db.execute("SELECT id, name, kind, city, image, web FROM activities ORDER BY name"))
    assigned: dict[str, str] = {}
    used: set[str] = set()

    files = list(dict.fromkeys(PLACE_FILE.values()))
    resolved = commons_urls(files)
    log(f"resolved {len(resolved)} curated commons files")
    for aid, fname in PLACE_FILE.items():
        url = resolved.get(fname.replace(" ", "_")) or resolved.get(fname)
        if url:
            assigned[aid] = url
            used.add(url)
            log(f"  place {aid}")
        else:
            log(f"  missing file {aid} {fname}")

    # UBC is its own hall, not a mall — prefer the official site photo.
    og = og_image("https://www.ubc-riyadh.com")
    if og:
        assigned["ubc-bowling"] = og
        used.add(og)
        log(f"  ubc website {og[:80]}")

    for aid, title in WIKI_TITLES.items():
        if aid in assigned:
            continue
        img = wiki_image(title)
        if img and img not in used:
            assigned[aid] = img
            used.add(img)
            log(f"  wiki {aid}")
        elif img:
            # same wiki page as another activity — search a unique commons frame
            extra = commons_search(title.replace("_", " ") + " Saudi Arabia", used)
            if extra:
                assigned[aid] = extra
                used.add(extra)
                log(f"  wiki-alt {aid}")

    for row in rows:
        aid = row["id"]
        if aid in assigned or aid in SHARE:
            continue
        query = f"{row['name']} {row['city']} Saudi Arabia"
        img = commons_search(query, used)
        if img:
            assigned[aid] = img
            used.add(img)
            log(f"  search {aid}")
            continue
        kind_q = {
            "bowl": "bowling alley",
            "desert": "sand dunes Saudi Arabia",
            "mall": f"{row['city']} Saudi Arabia shopping mall",
            "speed": "go-kart track",
            "ice": "ice skating rink",
            "cinema": f"{row['city']} Saudi Arabia cinema mall",
            "theme": "theme park",
            "water": "water park",
            "arcade": "arcade games",
            "trampoline": "trampoline park",
            "vr": "virtual reality headset indoor",
            "combat": "paintball field",
            "outdoor": f"{row['city']} Saudi Arabia landscape",
            "night": f"{row['city']} Saudi Arabia night",
            "sport": "sports court indoor",
            "kids": "indoor playground",
            "snow": "indoor ski snow",
            "escape": f"{row['city']} Saudi Arabia building",
        }.get(row["kind"], f"{row['city']} Saudi Arabia")
        img = commons_search(kind_q, used)
        if img:
            assigned[aid] = img
            used.add(img)
            log(f"  kind {aid}")

    for child, parent in SHARE.items():
        if parent in assigned:
            assigned[child] = assigned[parent]
            log(f"  share {child} <- {parent}")

    n = 0
    for aid, url in assigned.items():
        db.execute("UPDATE activities SET image = ? WHERE id = ?", (url, aid))
        n += 1
    db.commit()
    write_seed(assigned)

    leftover = [
        r["id"]
        for r in db.execute("SELECT id, image FROM activities")
        if is_bad(r["image"] or "")
    ]
    by_url: dict[str, list[str]] = {}
    for r in db.execute("SELECT id, image FROM activities"):
        by_url.setdefault(r["image"] or "", []).append(r["id"])
    shared = {k: v for k, v in by_url.items() if len(v) > 1}
    log(f"updated {n}; leftover-bad {leftover}; shared-groups {len(shared)}")
    for ids in shared.values():
        log(f"  shared {ids}")
    log("\nBOWLING")
    for r in db.execute(
        "SELECT id,name,image FROM activities WHERE kind='bowl' OR name LIKE '%Bowling%' ORDER BY name"
    ):
        log(f"  {r['name'][:42]:42} {r['image'].split('/')[-1][:70]}")
    log("\nDUNES")
    for r in db.execute(
        "SELECT id,name,image FROM activities WHERE kind='desert' ORDER BY name"
    ):
        log(f"  {r['name'][:42]:42} {r['image'].split('/')[-1][:70]}")
    db.close()


if __name__ == "__main__":
    main()
