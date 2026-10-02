"""Keep a YouTube clip only when the title is about that exact place."""

import json
import re
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

UA = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
CATALOG = 'lib/data/ksa_activities.dart'
OUT = 'tools/activity_clip_review.json'

# Each activity maps to alternative groups. Every word in a group must appear
# in the title. Missing key means the listing is a category, not one place.
RULES = {
    'six-flags-qiddiya': [['six flags'], ['سكس فلاج'], ['القدية', 'flag']],
    'snow-city-riyadh': [['snow city'], ['سنو سيتي']],
    'red-sands-safari': [['red sand'], ['الرمال الحمراء']],
    'edge-of-world': [['edge of the world'], ['حافة العالم']],
    'speedzone-riyadh': [['speedzone'], ['speed zone']],
    'kartdrome-riyadh': [['kartdrome']],
    'vox-riyadh-park': [['vox', 'riyadh park']],
    'vox-kingdom': [['vox', 'kingdom']],
    'vox-via-riyadh': [['vox', 'via']],
    'muvi-the-view': [['muvi', 'the view'], ['the view', 'cinema']],
    'amc-riyadh-front': [['amc', 'riyadh front'], ['amc', 'front']],
    'fun-city-bowling-rp': [['fun city', 'riyadh park']],
    'ubc-bowling': [['ubc', 'bowl'], ['universal bowling']],
    'ubc-billiards': [['ubc', 'billiard'], ['ubc', 'pool'], ['universal bowling', 'billiard']],
    'ubc-arcade': [['ubc', 'arcade'], ['ubc', 'playstation'], ['universal bowling', 'arcade']],
    'mall-u-walk': [['u walk'], ['uwalk'], ['يو ووك']],
    'mall-avenues-riyadh': [['avenues', 'riyadh'], ['الافنيوز']],
    'timezone-granada': [['timezone', 'granada']],
    'magic-planet-rp': [['magic planet', 'riyadh']],
    'kingdom-skybridge': [['sky bridge', 'kingdom'], ['skybridge', 'kingdom']],
    'bowling-nakheel': [['fun city', 'nakheel']],
    'sparkys-granada': [['sparky', 'granada']],
    'kidzania-riyadh': [['kidzania', 'riyadh'], ['كيدزانيا', 'رياض']],
    'bounce-riyadh': [['bounce', 'riyadh'], ['bounce', 'الرياض']],
    'ice-rink-riyadh': [['granada', 'ice'], ['granada', 'skat']],
    'vr-park-riyadh': [['vr park', 'riyadh']],
    'thumamah-dunes': [['thumamah'], ['الثمامة']],
    'diriyah-horses': [['diriyah', 'horse'], ['الدرعية', 'خيل'], ['diriyah', 'equestrian'], ['diriyah', 'riding']],
    'wadi-hanifah': [['hanifah'], ['hanifa'], ['حنيفة']],
    'boulevard-city': [['boulevard', 'riyadh'], ['riyadh season'], ['بوليفارد']],
    'winter-wonderland': [['winter wonderland', 'riyadh'], ['winter wonderland', 'saudi']],
    'hokair-water-riyadh': [['hokair']],
    'sky-zone-riyadh': [['sky zone'], ['skyzone']],
    'angry-birds-riyadh': [['angry birds']],
    'national-museum': [['national museum', 'riyadh'], ['national museum', 'saudi'], ['المتحف الوطني']],
    'vox-red-sea': [['vox', 'red sea']],
    'vox-moa': [['vox', 'arabia']],
    'kidzania-jeddah': [['kidzania', 'jeddah'], ['كيدزانيا', 'جدة']],
    'shallal-jeddah': [['shallal'], ['الشلال']],
    'fakieh-aquarium': [['fakieh'], ['فقيه']],
    'obhur-jetski': [['obhur'], ['أبحر']],
    'bowling-red-sea': [['red sea', 'bowl']],
    'jeddah-corniche-night': [['jeddah corniche'], ['كورنيش جدة'], ['corniche', 'jeddah']],
    'vox-dhahran': [['vox', 'dhahran']],
    'vox-ajdan': [['vox', 'ajdan']],
    'muvi-khobar': [['muvi', 'khobar']],
    'ithra': [['ithra'], ['إثراء'], ['اثراء']],
    'scitech': [['scitech'], ['سايتك']],
    'half-moon-water': [['half moon'], ['نصف القمر']],
    'alula-balloon': [['alula', 'balloon'], ['al ula', 'balloon'], ['العلا', 'منطاد']],
    'hegra-tour': [['hegra'], ['الحجر'], ['mada in'], ['madain'], ['salih']],
    'elephant-rock': [['elephant rock'], ['جبل الفيل']],
    'maraya': [['maraya'], ['مرايا']],
    'abha-cable': [['soudah'], ['souda'], ['السودة'], ['abha', 'cable']],
    'rijal-almaa': [['rijal'], ['رجال ألمع'], ['رجال المع']],
    'taif-cable': [['hada', 'cable'], ['hada', 'taif'], ['الحدا'], ['hada', 'telefer']],
    'yanbu-beach': [['yanbu', 'beach'], ['ينبع', 'شاط']],
    'tabuk-desert': [['neom'], ['نيوم'], ['tabuk', 'desert']],
    'umluj-boat': [['umluj'], ['amlaj'], ['أملج']],
    'jazan-island': [['farasan'], ['فرسان']],
    'najran-park': [['najran', 'dam'], ['نجران', 'سد']],
    'hofuf-bowling': [['ahsa', 'bowl'], ['hasa', 'bowl'], ['ahsa', 'cinema']],
    'jubail-corniche': [['jubail', 'corniche'], ['jubail', 'marina'], ['كورنيش الجبيل']],
    'empty-quarter': [['empty quarter'], ['rub al khali'], ['الربع الخالي']],
    'khobar-corniche': [['khobar corniche'], ['corniche', 'khobar'], ['كورنيش الخبر']],
    'vox-riyadh-gallery': [['vox', 'riyadh gallery'], ['vox', 'gallery']],
    'vox-granada': [['vox', 'granada']],
    'muvi-olaya': [['muvi', 'olaya']],
    'vox-jeddah-park': [['vox', 'jeddah park']],
    'amc-jeddah': [['amc', 'jeddah']],
    'vox-mall-dhahran': [['vox', 'mall of dhahran'], ['vox', 'dhahran']],
    'bowling-riyadh-gallery': [['fun city', 'gallery'], ['fun city', 'riyadh gallery']],
    'bowling-granada': [['granada', 'bowl']],
    'bowling-moa': [['mall of arabia', 'bowl'], ['arabia', 'bowl']],
    'bowling-dhahran': [['dhahran', 'bowl']],
    'sparkys-jeddah': [['sparky', 'jeddah']],
    'sparkys-khobar': [['sparky', 'khobar']],
    'ice-jeddah': [['mall of arabia', 'ice'], ['arabia', 'ice rink'], ['arabia', 'skating']],
    'vr-jeddah': [['vr park', 'jeddah']],
    'bounce-jeddah': [['bounce', 'jeddah']],
    'red-sands-atv': [['red sand', 'atv'], ['red sand', 'quad'], ['الرمال الحمراء']],
    'red-sands-sandboard': [['red sand', 'sand'], ['red sand', 'board'], ['الرمال الحمراء']],
    'red-sands-camp': [['red sand', 'camp'], ['الرمال الحمراء']],
    'thumamah-atv': [['thumamah', 'atv'], ['thumamah', 'quad'], ['الثمامة']],
    'thumamah-kids-atv': [['thumamah']],
    'thumamah-bashing': [['thumamah']],
    'dirab-atv': [['dirab'], ['ديراب']],
    'ahsa-atv': [['ahsa', 'atv'], ['ahsa', 'quad'], ['ahsa', 'dune'], ['hasa', 'dune']],
    'empty-quarter-atv': [['empty quarter'], ['rub al khali'], ['الربع الخالي']],
    'ula-atv': [['alula', 'atv'], ['al ula', 'atv'], ['alula', 'quad'], ['العلا', 'دباب']],
    'mall-riyadh-park': [['riyadh park']],
    'mall-granada': [['granada mall'], ['granada', 'mall', 'riyadh'], ['غرناطة', 'الرياض']],
    'mall-riyadh-gallery': [['riyadh gallery']],
    'mall-nakheel': [['nakheel', 'mall'], ['النخيل', 'مول']],
    'mall-panorama': [['panorama mall'], ['بانوراما مول']],
    'mall-kingdom': [['kingdom centre'], ['kingdom center'], ['المملكة', 'مول']],
    'mall-via': [['via riyadh'], ['فيا الرياض']],
    'mall-front': [['riyadh front']],
    'mall-arabia-jeddah': [['mall of arabia']],
    'mall-red-sea': [['red sea mall']],
    'mall-jeddah-park': [['jeddah park']],
    'mall-dhahran': [['dhahran mall']],
    'mall-of-dhahran': [['mall of dhahran']],
    'mall-rashid': [['rashid mall'], ['الراشد مول']],
    'mall-ajdan': [['ajdan']],
    'mall-ahsa': [['ahsa mall'], ['al ahsa mall'], ['الأحساء مول'], ['الاحساء مول']],
    'mall-stars-avenue': [['stars avenue']],
    'mall-salam': [['salam mall', 'jeddah'], ['مول السلام', 'جدة']],
}


def field(block, name):
    m = re.search(rf"{name}:\s*'((?:[^'\\]|\\.)*)'", block)
    return m.group(1).replace("\\'", "'") if m else ''


def catalog():
    src = open(CATALOG, encoding='utf-8').read()
    venues = []
    for block in re.findall(r'_a\((.*?)\n  \),', src, re.S):
        vid = field(block, 'id')
        name = field(block, 'name')
        if vid and name:
            venues.append({'activityId': vid, 'name': name, 'city': field(block, 'city')})
    return venues


def norm(text):
    text = text.lower().replace('’', "'").replace('‘', "'").replace('·', ' ')
    text = re.sub(r'[^a-z0-9\u0600-\u06ff]+', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()


def get(url, timeout=20):
    req = urllib.request.Request(url, headers=UA)
    return urllib.request.urlopen(req, timeout=timeout).read().decode('utf-8', 'ignore')


def results(query):
    url = 'https://www.youtube.com/results?search_query=' + urllib.parse.quote(query)
    try:
        html = get(url)
    except Exception:
        return []
    m = re.search(r'ytInitialData\s*=\s*(\{.*?\});\s*</script>', html)
    if not m:
        return []
    try:
        data = json.loads(m.group(1))
    except Exception:
        return []
    found = []
    seen = set()

    def walk(node):
        if isinstance(node, dict):
            vid = node.get('videoId')
            title = node.get('title')
            if isinstance(vid, str) and len(vid) == 11 and isinstance(title, dict):
                if 'runs' in title:
                    text = ''.join(part.get('text', '') for part in title['runs'])
                else:
                    text = title.get('simpleText', '')
                if text and vid not in seen:
                    seen.add(vid)
                    found.append((vid, text))
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(data)
    return found[:12]


def matches(title, groups):
    folded = norm(title)
    for group in groups:
        if all(norm(part) in folded for part in group):
            return True
    return False


def playable(vid):
    try:
        html = get('https://www.youtube.com/watch?v=' + vid)
    except Exception:
        return False
    return '"playableInEmbed":true' in html and '"status":"UNPLAYABLE"' not in html


def resolve(venue):
    groups = RULES.get(venue['activityId'])
    if not groups:
        return None
    query = f"{venue['name']} {venue['city']}"
    for vid, title in results(query):
        if not matches(title, groups):
            continue
        if not playable(vid):
            continue
        return {
            'activityId': venue['activityId'],
            'name': venue['name'],
            'city': venue['city'],
            'youtubeId': vid,
            'title': title,
        }
    return {'activityId': venue['activityId'], 'name': venue['name'], 'youtubeId': None, 'title': None}


def main():
    venues = [v for v in catalog() if v['activityId'] in RULES]
    print(f'checking {len(venues)} named places', flush=True)
    with ThreadPoolExecutor(max_workers=6) as pool:
        rows = list(pool.map(resolve, venues))
    kept = [row for row in rows if row and row.get('youtubeId')]
    missed = [row['activityId'] for row in rows if row and not row.get('youtubeId')]
    json.dump({'kept': kept, 'missed': missed}, open(OUT, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
    print(f'kept {len(kept)} missed {len(missed)}', flush=True)
    for row in kept:
        print(f"OK  {row['activityId']} | {row['title'][:90]}", flush=True)


if __name__ == '__main__':
    main()
