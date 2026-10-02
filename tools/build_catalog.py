#!/usr/bin/env python3
"""Merge lifeinsaudiarabia + saudiexpatriate scrapes into app catalog assets."""

from __future__ import annotations

import csv
import html
import json
import os
import re
from collections import defaultdict

LISA = os.path.expanduser("~/Documents/lifeinsaudiarabia-scrape")
SE = os.path.expanduser("~/Documents/saudiexpatriate-scrape")
OUT = os.path.expanduser("~/Desktop/ksa-guide-backend/data")

# Map saudiexpatriate slugs onto existing LISA category slugs.
SE_MERGE_SLUG = {
    "absher": "moi-account-abshir-services",
    "arab-fashion": "fashion-in-saudi-arabia",
    "banking": "banks-in-saudi-arabia",
    "driving-saudi": "driving-in-saudi-arabia",
    "entertainment": "entertainment",
    "food": "food-issues",
    "hadith": "islamic-information",
    "hajj-umrah": "hajj-umrah",
    "health": "health-issues",
    "health-wellness": "health-issues",
    "huroob": "labor-disputes-and-huroob",
    "iqama-muqeem": "iqama",
    "islamic": "islamic-information",
    "mobile": "mobile-phones",
    "najm": "accidents-and-insurance",
    "saudi-arabia-news": "latest-news",
    "sponsorship-transfer": "transfer-of-sponsorship-naqal-kafala",
    "traffic-laws": "traffic-violations",
    "travel": "travelling-from-ksa",
    "visa": "visas",
}

# Distinct SE topics become children under the closest LISA parent slug.
SE_NEW_CHILD = {
    "blog": ("latest-news", "Blog", "blog"),
    "deals-offers": ("online-shopping", "Deals & Offers", "deals-offers"),
    "offers": ("online-shopping", "Deals & Offers", "deals-offers"),
    "employee-benefits": ("career", "Employee Benefits", "employee-benefits"),
    "expat-community": ("social-issues", "Expat Community", "expat-community"),
    "jawazat": ("jawazat-and-moi", "Jawazat", "jawazat"),
    "nitaqat": ("career", "Nitaqat", "nitaqat"),
    "saudi-arabia-covid-19-laws": (
        "saudi-laws",
        "Covid-19 Laws",
        "saudi-arabia-covid-19-laws",
    ),
    "sports": ("social-issues", "Sports", "sports"),
    "top-10": ("general-information", "Top 10", "top-10"),
    "top-android-apps": ("technology", "Top Android Apps", "top-android-apps"),
}


def clean_text(s):
    if not s:
        return ""
    s = html.unescape(str(s))
    s = s.replace("\xa0", " ")
    s = re.sub(r"\r\n|\r", "\n", s)
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def https(url):
    if not url:
        return None
    url = str(url).strip()
    if url.startswith("http://"):
        url = "https://" + url[len("http://") :]
    return url or None


def load_categories(path, id_prefix=""):
    cats = []
    with open(path, encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            cid = f"{id_prefix}{row['id']}" if id_prefix else row["id"]
            parent = row["parent"]
            if parent and parent != "0":
                parent = f"{id_prefix}{parent}" if id_prefix else parent
            cats.append(
                {
                    "id": cid,
                    "name": html.unescape(row["name"]),
                    "slug": row["slug"],
                    "parentId": parent,
                    "directCount": int(row["post_count"] or 0),
                    "childIds": [],
                    "totalCount": 0,
                }
            )
    return cats


def compact_post(raw, prefix, source, source_label, category_names):
    body = clean_text(raw.get("content_text") or "")
    if len(body) < 80:
        return None, None
    excerpt = clean_text(raw.get("excerpt") or raw.get("meta_description") or "")
    preview_src = excerpt if len(excerpt) > 180 else body
    preview = re.sub(r"\s+", " ", preview_src)[:720].strip()
    image = https(raw.get("featured_image") or "")
    if not image:
        imgs = raw.get("image_urls") or []
        if imgs:
            first = imgs[0]
            image = https(first.get("url") if isinstance(first, dict) else first)
    pid = f"{prefix}{raw['id']}"
    tags = [html.unescape(t) for t in (raw.get("tags") or []) if t]
    post = {
        "id": pid,
        "title": clean_text(raw.get("title")),
        "slug": raw.get("slug") or "",
        "date": (raw.get("date_published") or "")[:19],
        "excerpt": excerpt[:400],
        "preview": preview,
        "image": image,
        "categories": category_names,
        "tags": tags[:20],
        "wordCount": int(raw.get("word_count") or 0),
        "source": source,
        "sourceLabel": source_label,
    }
    return post, body


def descendants(cid, by_id):
    out = [cid]
    for ch in by_id[cid]["childIds"]:
        out.extend(descendants(ch, by_id))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)

    lisa_cats = load_categories(os.path.join(LISA, "categories.csv"))
    se_cats_raw = load_categories(os.path.join(SE, "categories.csv"), id_prefix="se-")

    by_id = {c["id"]: c for c in lisa_cats}
    by_slug = {c["slug"]: c for c in lisa_cats}

    extra = []
    extra_by_slug = {}
    for spec in SE_NEW_CHILD.values():
        parent_slug, name, slug = spec
        if slug in extra_by_slug or slug in by_slug:
            continue
        parent = by_slug[parent_slug]
        child = {
            "id": f"se-{slug}",
            "name": name,
            "slug": slug,
            "parentId": parent["id"],
            "directCount": 0,
            "childIds": [],
            "totalCount": 0,
        }
        extra.append(child)
        extra_by_slug[slug] = child
        parent["childIds"].append(child["id"])

    cats = lisa_cats + extra
    by_id = {c["id"]: c for c in cats}
    by_slug = {c["slug"]: c for c in cats}

    for c in cats:
        pid = c["parentId"]
        if pid in by_id and c["id"] not in by_id[pid]["childIds"]:
            by_id[pid]["childIds"].append(c["id"])

    se_id_to_target_name = {}
    for se in se_cats_raw:
        orig_slug = se["slug"]
        if orig_slug in SE_MERGE_SLUG:
            se_id_to_target_name[se["id"]] = by_slug[SE_MERGE_SLUG[orig_slug]]["name"]
        elif orig_slug in SE_NEW_CHILD:
            _, name, slug = SE_NEW_CHILD[orig_slug]
            se_id_to_target_name[se["id"]] = extra_by_slug[slug]["name"] if slug in extra_by_slug else name
        else:
            se_id_to_target_name[se["id"]] = None

    se_name_to_target = {}
    for se in se_cats_raw:
        target = se_id_to_target_name.get(se["id"])
        se_name_to_target[se["name"]] = target

    posts = []
    bodies = {}
    skipped = 0

    with open(os.path.join(LISA, "posts.json"), encoding="utf-8") as f:
        raw_lisa = json.load(f)
    for raw in raw_lisa:
        names = [html.unescape(n) for n in (raw.get("categories") or [])]
        post, body = compact_post(
            raw, "lisa-", "lisa", "Life in Saudi Arabia", names
        )
        if post is None:
            skipped += 1
            continue
        posts.append(post)
        bodies[post["id"]] = body

    with open(os.path.join(SE, "posts.json"), encoding="utf-8") as f:
        raw_se = json.load(f)
    unmapped = defaultdict(int)
    for raw in raw_se:
        mapped = []
        seen = set()
        for n in raw.get("categories") or []:
            name = html.unescape(n)
            target = se_name_to_target.get(name)
            if not target:
                unmapped[name] += 1
                continue
            if target not in seen:
                seen.add(target)
                mapped.append(target)
        if not mapped:
            mapped = ["Latest News"]
        post, body = compact_post(
            raw, "se-", "se", "Saudi Expatriate", mapped
        )
        if post is None:
            skipped += 1
            continue
        posts.append(post)
        bodies[post["id"]] = body

    name_to_ids = defaultdict(list)
    for post in posts:
        for n in post["categories"]:
            name_to_ids[n].append(post["id"])

    for c in cats:
        names = {by_id[i]["name"] for i in descendants(c["id"], by_id)}
        seen = set()
        count = 0
        for n in names:
            for pid in name_to_ids.get(n, []):
                if pid not in seen:
                    seen.add(pid)
                    count += 1
        c["totalCount"] = count
        c["directCount"] = len(set(name_to_ids.get(c["name"], [])))

    catalog = {
        "site": "merged",
        "sources": [
            "https://lifeinsaudiarabia.net",
            "https://saudiexpatriate.com",
        ],
        "postCount": len(posts),
        "categoryCount": len(cats),
        "categories": cats,
        "posts": posts,
    }

    cat_path = os.path.join(OUT, "catalog.seed.json")
    body_path = os.path.join(OUT, "bodies.seed.json")
    with open(cat_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, separators=(",", ":"))
    with open(body_path, "w", encoding="utf-8") as f:
        json.dump(bodies, f, ensure_ascii=False, separators=(",", ":"))

    print("posts", len(posts), "skipped", skipped)
    print("lisa", sum(1 for p in posts if p["source"] == "lisa"))
    print("se", sum(1 for p in posts if p["source"] == "se"))
    print("catalog MB", os.path.getsize(cat_path) / 1e6)
    print("bodies MB", os.path.getsize(body_path) / 1e6)
    if unmapped:
        print("unmapped SE cats", dict(unmapped))
    print("top-level totals:")
    for c in cats:
        if c["parentId"] == "0":
            print(f"  {c['name']}: {c['totalCount']} posts, {len(c['childIds'])} children")


if __name__ == "__main__":
    main()
