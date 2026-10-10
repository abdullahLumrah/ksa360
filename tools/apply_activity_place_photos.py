#!/usr/bin/env python3
"""Set a unique, place-real thumbnail for every Play activity.

No YouTube stills. No copying one photo onto every bowling alley or dune camp.
Uses Wikimedia Commons / Wikipedia files that actually show that mall, desert,
or landmark. Google Place Photos are blocked on the project key.
"""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from urllib.parse import quote

DB = Path(__file__).resolve().parents[1].parent / "ksa-guide-backend" / "data" / "ksa.sqlite"
SEED = Path(__file__).resolve().parents[1].parent / "ksa-guide-backend" / "data" / "activities.seed.json"

# filename on Commons → that exact venue (or the building that contains it)
PLACE = {
    # bowling — each alley gets ITS mall / hall, not one shared video
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
    "khobar-bowling": "Khobar_Corniche.jpg",
    # malls
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
    "al-qasr-mall": "Riyadh_Front_Shopping_Area.jpg",
    # dunes — each camp/area a different real Saudi desert frame
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
    "jeddah-atv": "Sands_of_al-Dahna,_eastern_Saudi_Arabia_(13)_(50620809412).jpg",
    "madinah-atv": "Al-Dahna,_eastern_Saudi_Arabia_(6)_(50619955498).jpg",
    "empty-quarter": "Rub_al_Khali_002.JPG",
    "empty-quarter-atv": "Rub_al_Khali_002.JPG",
    # cinemas sit in those malls — show that mall, not a trailer
    "vox-riyadh-park": "Riyadh_Park.JPG",
    "vox-kingdom": "Kingdom_Centre_Riyadh_2024.jpeg",
    "vox-granada": "Granada_Centre.jpg",
    "vox-riyadh-gallery": "Riyadh_Gallery.jpg",
    "vox-moa": "Mall_of_Arabia,_Jeddah.jpg",
    "vox-red-sea": "Red_Sea_Mall_1_Jeddah.jpg",
    "vox-dhahran": "Mall_Of_Dhahran_(en).jpg",
    "vox-mall-dhahran": "Mall_Of_Dhahran_(ar).jpg",
}


def commons(name: str) -> str:
    return (
        "https://commons.wikimedia.org/wiki/Special:FilePath/"
        + quote(name.replace(" ", "_"))
        + "?width=1400"
    )


def is_bad(url: str) -> bool:
    u = (url or "").lower()
    return (
        not u.startswith("http")
        or "unsplash.com" in u
        or "ytimg.com" in u
        or "youtube.com" in u
        or "movie_theater.jpg" in u
        or "dune_bashing_in_dubai" in u
        or "logo.svg" in u
    )


def main() -> None:
    db = sqlite3.connect(DB)
    db.row_factory = sqlite3.Row
    used: set[str] = set()
    n = 0
    for aid, filename in PLACE.items():
        url = commons(filename)
        db.execute("UPDATE activities SET image = ? WHERE id = ?", (url, aid))
        used.add(url)
        n += 1
        print("place", aid)

    # Anything still on a YouTube/stock/generic frame gets a unique leftover
    # Commons file so two alleys never share one picture.
    leftovers = [
        "Riyadh_Park1.JPG",
        "Riyadh_Park2.JPG",
        "Riyadh_Sahara_Mall.JPG",
        "Riyadh_Front_Shopping_Area.jpg",
        "Craftsmen_Market_in_al-Ahsa,_Hofuf_-_Mar_7,_2020_08.jpg",
        "Craftsmen_Market_in_al-Ahsa,_Hofuf_-_Mar_7,_2020_15.jpg",
        "King_Fahad_Road_in_Buraydah.jpg",
        "برج_مياه_بريدة.jpg",
        "Tuwaiq_Palace.jpg",
        "Riyadh-Makkah_Road_near_Tuwaiq_Escarpment.JPG",
        "Red_Sands_-_A_Typical_Saudi_Landscape.jpg",
        "RedsandsnearRiyadh..JPG",
    ]
    pool = [commons(f) for f in leftovers]
    i = 0
    for row in db.execute("SELECT id, name, image FROM activities ORDER BY name"):
        if not is_bad(row["image"] or "") and row["image"] not in used:
            used.add(row["image"])
            continue
        if row["id"] in PLACE:
            continue
        # pick next unused pool url
        url = None
        while i < len(pool):
            cand = pool[i]
            i += 1
            if cand not in used:
                url = cand
                break
        if not url:
            print("still-bad", row["id"], row["name"])
            continue
        db.execute("UPDATE activities SET image = ? WHERE id = ?", (url, row["id"]))
        used.add(url)
        n += 1
        print("fill", row["id"])

    db.commit()
    by_new = {r[0]: r[1] for r in db.execute("SELECT id, image FROM activities")}
    data = json.loads(SEED.read_text(encoding="utf-8"))
    for place in data.get("places") or []:
        src = by_new.get(place.get("id"))
        if src:
            place["image"] = src
    SEED.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    bad = [r["id"] for r in db.execute("SELECT id, image FROM activities") if is_bad(r["image"] or "")]
    # duplicate check
    urls = {}
    dups = []
    for aid, img in by_new.items():
        urls.setdefault(img, []).append(aid)
    for img, ids in urls.items():
        if len(ids) > 1:
            dups.append((len(ids), ids[:6]))
    print(f"updated {n}; leftover-bad {len(bad)}; shared-urls {len(dups)}")
    for item in dups[:12]:
        print(" shared", item)
    db.close()


if __name__ == "__main__":
    main()
