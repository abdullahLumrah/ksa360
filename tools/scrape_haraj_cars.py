#!/usr/bin/env python3
"""Pull public Haraj car listings (last 14 days) with photo URLs.

Uses Haraj's public GraphQL `posts` query (same as haraj.com.sa).
Does not collect phone numbers. Respects a short delay between pages.
"""

from __future__ import annotations

import html
import json
import re
import time
import urllib.error
import urllib.request
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "data" / "haraj_cars.json"
CHECKPOINT = ROOT / "tools" / ".haraj_scrape_checkpoint.json"

GQL = "https://graphql.haraj.com.sa/?queryName=FetchAds"
DAYS = 14
DELAY = 0.12
MAX_PAGES_PER_TAG = 450
MAX_PER_TAG_PER_DAY = 90
MAX_IMAGES = 4
BODY_CHARS = 280

CDN_PREFIXES = (
    "https://imgcdn.haraj.com.sa/",
    "https://img1cdn.haraj.com.sa/",
    "https://mimgcdn.haraj.com.sa/",
    "https://mimg1cdn.haraj.com.sa/",
    "https://img4cdn.haraj.com.sa/",
    "https://mimg6cdn.haraj.com.sa/",
    "https://s3-eu-west-1.amazonaws.com/mimg1.haraj.com.sa/",
)

BRANDS = [
    ("تويوتا", "Toyota"),
    ("هيونداي", "Hyundai"),
    ("نيسان", "Nissan"),
    ("فورد", "Ford"),
    ("لكزس", "Lexus"),
    ("كيا", "Kia"),
    ("شفروليه", "Chevrolet"),
    ("مرسيدس", "Mercedes"),
    ("بي ام دبليو", "BMW"),
    ("جي ام سي", "GMC"),
    ("هوندا", "Honda"),
    ("مازدا", "Mazda"),
    ("جيب", "Jeep"),
    ("دودج", "Dodge"),
    ("ايسوزو", "Isuzu"),
    ("فولكس واجن", "Volkswagen"),
    ("ميتسوبيشي", "Mitsubishi"),
    ("رنج روفر", "Land Rover"),
    ("لاند روفر", "Land Rover"),
    ("بورشه", "Porsche"),
    ("اودي", "Audi"),
    ("هافال", "Haval"),
    ("شيري", "Chery"),
    ("ام جي", "MG"),
    ("جينيسيس", "Genesis"),
    ("كاديلاك", "Cadillac"),
    ("انفينيتي", "Infiniti"),
    ("بي واي دي", "BYD"),
]

QUERY = """
query FetchAds($tag: String = null, $page: Int = null, $limit: Int = null, $onlyWithImage: Boolean = null) {
  posts(tag: $tag, page: $page, limit: $limit, onlyWithImage: $onlyWithImage) {
    items {
      id
      title
      postDate
      authorUsername
      URL
      bodyTEXT
      thumbURL
      hasImage
      city
      geoCity
      tags
      imagesList
      price { formattedPrice inputPrice }
      carInfo {
        sellOrWaiver
        is4DW
        model
        mileage
        fuel
        gear
        condition
        carOrRelated
      }
    }
    pageInfo { hasNextPage }
  }
}
"""

HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Origin": "https://haraj.com.sa",
    "Referer": "https://haraj.com.sa/tags/%D8%B3%D9%8A%D8%A7%D8%B1%D8%A7%D8%AA/",
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
}


def display_image(url: str | None) -> str | None:
    if not url:
        return None
    for prefix in CDN_PREFIXES:
        if url.startswith(prefix):
            rest = url[len(prefix) :]
            return f"https://postcdn.haraj.com.sa/{rest}-700.webp"
    if url.startswith("http"):
        return url
    return f"https://thumbcdn.haraj.com.sa/{url}"


def thumb_image(thumb: str | None) -> str | None:
    if not thumb:
        return None
    if thumb.startswith("http"):
        return display_image(thumb)
    return f"https://thumbcdn.haraj.com.sa/{thumb}-140x140.webp"


def clean_body(raw: str | None) -> str:
    if not raw:
        return ""
    text = html.unescape(raw)
    text = re.sub(r"<[^>]+>", " ", text)
    text = text.replace("&bull;", "•")
    text = re.sub(r"\s+", " ", text).strip()
    return text[:BODY_CHARS]


def fetch_page(tag: str, page: int, retries: int = 4) -> tuple[list, bool]:
    payload = json.dumps(
        {
            "query": QUERY,
            "variables": {
                "tag": tag,
                "page": page,
                "limit": 40,
                "onlyWithImage": True,
            },
        }
    ).encode()
    last_err = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(GQL, data=payload, headers=HEADERS, method="POST")
            with urllib.request.urlopen(req, timeout=40) as resp:
                data = json.loads(resp.read().decode())
            if data.get("errors"):
                last_err = data["errors"]
                time.sleep(0.8 * (attempt + 1))
                continue
            posts = (data.get("data") or {}).get("posts") or {}
            items = posts.get("items") or []
            nxt = bool((posts.get("pageInfo") or {}).get("hasNextPage"))
            return items, nxt
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            last_err = e
            time.sleep(1.2 * (attempt + 1))
    print(f"  failed {tag} page {page}: {last_err}")
    return [], False


def compact(item: dict, brand_en: str) -> dict | None:
    if not item.get("id") or not item.get("hasImage"):
        return None
    images = []
    seen: set[str] = set()
    for raw in item.get("imagesList") or []:
        url = display_image(raw)
        if url and url not in seen:
            seen.add(url)
            images.append(url)
        if len(images) >= MAX_IMAGES:
            break
    thumb = thumb_image(item.get("thumbURL"))
    if not images and thumb:
        images = [thumb]
    if not images:
        return None

    price_obj = item.get("price") or {}
    car = item.get("carInfo") or {}
    url = item.get("URL") or ""
    if url and not url.startswith("http"):
        url = "https://haraj.com.sa/" + url.lstrip("/")

    return {
        "id": item["id"],
        "title": item.get("title") or "",
        "postDate": item.get("postDate"),
        "city": item.get("geoCity") or item.get("city") or "",
        "Brand": brand_en,
        "Year": car.get("model"),
        "mileage": car.get("mileage"),
        "fuel": car.get("fuel"),
        "gear": car.get("gear"),
        "condition": car.get("condition"),
        "price": price_obj.get("inputPrice"),
        "priceText": price_obj.get("formattedPrice"),
        "images": images,
        "thumb": thumb,
        "url": url,
        "author": item.get("authorUsername"),
        "tags": (item.get("tags") or [])[:8],
        "body": clean_body(item.get("bodyTEXT")),
        "hasImage": True,
    }


def main() -> None:
    cutoff = int((datetime.now(timezone.utc) - timedelta(days=DAYS)).timestamp())
    listings: dict[int, dict] = {}
    if CHECKPOINT.exists():
        try:
            prev = json.loads(CHECKPOINT.read_text())
            for rec in prev.get("listings", []):
                listings[int(rec["id"])] = rec
            print(f"resumed {len(listings)} from checkpoint")
        except Exception:
            pass

    started = datetime.now(timezone.utc).isoformat()
    for tag, brand in BRANDS:
        per_day: dict[str, int] = defaultdict(int)
        print(f"{brand} ({tag})", flush=True)
        page = 1
        while page <= MAX_PAGES_PER_TAG:
            items, has_next = fetch_page(tag, page)
            time.sleep(DELAY)
            if not items:
                break
            stop = False
            added = 0
            for item in items:
                ts = int(item.get("postDate") or 0)
                if ts and ts < cutoff:
                    stop = True
                    break
                rec = compact(item, brand)
                if rec is None:
                    continue
                day = (
                    datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%d")
                    if ts
                    else "unknown"
                )
                if per_day[day] >= MAX_PER_TAG_PER_DAY:
                    continue
                iid = int(rec["id"])
                if iid not in listings:
                    per_day[day] += 1
                    added += 1
                listings[iid] = rec
            print(
                f"  p{page} got={len(items)} added={added} total={len(listings)} next={has_next}",
                flush=True,
            )
            if stop or not has_next:
                break
            if added == 0:
                page += 18
            else:
                page += 1
            if page % 20 < 10:
                CHECKPOINT.write_text(
                    json.dumps({"listings": list(listings.values())}, ensure_ascii=False)
                )
        CHECKPOINT.write_text(
            json.dumps({"listings": list(listings.values())}, ensure_ascii=False)
        )

    rows = sorted(listings.values(), key=lambda r: int(r.get("postDate") or 0), reverse=True)
    dates = [int(r["postDate"]) for r in rows if r.get("postDate")]
    payload = {
        "source": "haraj.com.sa",
        "scraped_at": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "scraped_at_iso": datetime.now(timezone.utc).isoformat(),
        "window_days": DAYS,
        "note": (
            f"Public Haraj car ads with photos, last {DAYS} days, via GraphQL posts() "
            f"on brand tags. Started {started}. Phone numbers were not collected. "
            f"Up to {MAX_PER_TAG_PER_DAY} ads per brand per day so the 2-week window is covered."
        ),
        "count": len(rows),
        "oldest": datetime.fromtimestamp(min(dates), timezone.utc).isoformat() if dates else None,
        "newest": datetime.fromtimestamp(max(dates), timezone.utc).isoformat() if dates else None,
        "listings": rows,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"wrote {OUT} listings={len(rows)} bytes={OUT.stat().st_size} oldest={payload['oldest']}")
    if CHECKPOINT.exists():
        CHECKPOINT.unlink()


if __name__ == "__main__":
    main()
