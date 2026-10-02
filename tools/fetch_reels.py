"""Harvest YouTube clip ids for Play reels and keep only embeddable ones.

Reads the venue catalog out of lib/data/ksa_activities.dart, searches YouTube
for each venue, then verifies every candidate can actually play inside an
embed. Writes tools/reels_candidates.json for wiring into play_reels.dart.
"""

import json
import re
import sys
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

UA = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
CATALOG = 'lib/data/ksa_activities.dart'
OUT = 'tools/reels_candidates.json'

VIDEO_ID = re.compile(r'"videoId":"([a-zA-Z0-9_-]{11})"')
BLOCK = re.compile(r'_a\((.*?)\n  \),', re.S)

BANNED = {'dQw4w9WgXcQ', 'oHg5SJYRHA0', 'xvFZjo5PgG0'}


def field(block, name):
    m = re.search(rf"{name}:\s*'((?:[^'\\]|\\.)*)'", block)
    return m.group(1).replace("\\'", "'") if m else ''


def catalog():
    src = open(CATALOG, encoding='utf-8').read()
    venues = []
    for block in BLOCK.findall(src):
        vid = field(block, 'id')
        name = field(block, 'name')
        if not vid or not name:
            continue
        venues.append({
            'activityId': vid,
            'name': name,
            'city': field(block, 'city'),
            'kind': field(block, 'kind'),
            'area': field(block, 'area'),
        })
    return venues


def get(url, timeout=20):
    req = urllib.request.Request(url, headers=UA)
    return urllib.request.urlopen(req, timeout=timeout).read().decode(
        'utf-8', 'ignore')


def search(venue):
    """Return up to 4 candidate ids, Shorts-biased, for one venue."""
    name = re.sub(r'\s*[·•]\s*', ' ', venue['name'])
    queries = [
        f"{name} {venue['city']} shorts",
        f"{name} {venue['city']}",
    ]
    found = []
    for q in queries:
        url = ('https://www.youtube.com/results?search_query='
               + urllib.parse.quote(q))
        try:
            html = get(url)
        except Exception:
            continue
        for m in VIDEO_ID.finditer(html):
            vid = m.group(1)
            if vid in BANNED or vid in found:
                continue
            found.append(vid)
            if len(found) >= 4:
                return found
    return found


def playable(vid):
    """True when YouTube allows this id to play inside an embed."""
    try:
        html = get('https://www.youtube.com/watch?v=' + vid)
    except Exception:
        return False
    if '"status":"UNPLAYABLE"' in html or '"status":"ERROR"' in html:
        return False
    if '"playableInEmbed":true' not in html:
        return False
    return True


def main():
    venues = catalog()
    print(f'catalog venues: {len(venues)}', flush=True)

    with ThreadPoolExecutor(max_workers=8) as pool:
        hits = list(pool.map(search, venues))

    pairs = []
    for venue, ids in zip(venues, hits):
        for vid in ids:
            pairs.append((venue, vid))
    print(f'search candidates: {len(pairs)}', flush=True)

    with ThreadPoolExecutor(max_workers=8) as pool:
        verdicts = list(pool.map(lambda p: playable(p[1]), pairs))

    used = set()
    kept = []
    dropped = 0
    for (venue, vid), ok in zip(pairs, verdicts):
        if not ok:
            dropped += 1
            continue
        if vid in used:
            continue
        if any(k['activityId'] == venue['activityId'] for k in kept):
            continue  # one reel per venue keeps the feed varied
        used.add(vid)
        kept.append({**venue, 'youtubeId': vid})

    json.dump(kept, open(OUT, 'w', encoding='utf-8'), indent=2,
              ensure_ascii=False)
    print(f'kept {len(kept)} reels, dropped {dropped} unplayable', flush=True)
    by_kind = {}
    for k in kept:
        by_kind[k['kind']] = by_kind.get(k['kind'], 0) + 1
    print('by kind:', dict(sorted(by_kind.items())), flush=True)
    print('wrote', OUT, flush=True)


if __name__ == '__main__':
    sys.exit(main())
