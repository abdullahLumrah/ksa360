"""Builds lib/data/embassy_directory.dart from the embassies.net Riyadh and Jeddah tables.

Run: python3 tools/build_embassies.py
Sources (downloaded HTML):
  https://embassies.net/saudi-arabia/riyadh
  https://embassies.net/saudi-arabia/jeddah
Overrides come from Google Maps listings (via fastbase.com) where the two disagreed,
or fill countries missing from the tables. Rows with obvious copy errors are dropped.
"""

import html
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'lib' / 'data' / 'embassy_directory.dart'

IDS = {
    'United Kingdom': 'uk',
    'United States': 'usa',
    'United Arab Emirates': 'uae',
}

FLAGS = {
    'Afghanistan': 'AF', 'Albania': 'AL', 'Algeria': 'DZ', 'Argentina': 'AR', 'Australia': 'AU',
    'Austria': 'AT', 'Azerbaijan': 'AZ', 'Bahrain': 'BH', 'Bangladesh': 'BD', 'Belgium': 'BE',
    'Benin': 'BJ', 'Bosnia and Herzegovina': 'BA', 'Brazil': 'BR', 'Brunei': 'BN', 'Bulgaria': 'BG',
    'Burkina Faso': 'BF', 'Cameroon': 'CM', 'Canada': 'CA', 'Chad': 'TD', 'China': 'CN',
    'Comoros': 'KM', "Côte d'Ivoire": 'CI', 'Cuba': 'CU', 'Cyprus': 'CY', 'Czech Republic': 'CZ',
    'Denmark': 'DK', 'Djibouti': 'DJ', 'Egypt': 'EG', 'Eritrea': 'ER', 'Ethiopia': 'ET',
    'Finland': 'FI', 'France': 'FR', 'Gabon': 'GA', 'Gambia': 'GM', 'Georgia': 'GE',
    'Germany': 'DE', 'Ghana': 'GH', 'Greece': 'GR', 'Guinea': 'GN', 'Hungary': 'HU',
    'India': 'IN', 'Indonesia': 'ID', 'Iraq': 'IQ', 'Ireland': 'IE', 'Italy': 'IT',
    'Japan': 'JP', 'Jordan': 'JO', 'Kazakhstan': 'KZ', 'Kenya': 'KE', 'Kosovo': 'XK',
    'Kuwait': 'KW', 'Kyrgyzstan': 'KG', 'Lebanon': 'LB', 'Liberia': 'LR', 'Libya': 'LY',
    'Madagascar': 'MG', 'Malaysia': 'MY', 'Maldives': 'MV', 'Mali': 'ML', 'Malta': 'MT',
    'Mauritania': 'MR', 'Mauritius': 'MU', 'Mexico': 'MX', 'Mongolia': 'MN', 'Morocco': 'MA',
    'Mozambique': 'MZ', 'Myanmar': 'MM', 'Nepal': 'NP', 'Netherlands': 'NL', 'New Zealand': 'NZ',
    'Nigeria': 'NG', 'Oman': 'OM', 'Pakistan': 'PK', 'Palestine': 'PS', 'Peru': 'PE',
    'Philippines': 'PH', 'Poland': 'PL', 'Portugal': 'PT', 'Qatar': 'QA', 'Romania': 'RO',
    'Russia': 'RU', 'Serbia': 'RS', 'Sierra Leone': 'SL', 'Singapore': 'SG', 'Slovenia': 'SI',
    'South Korea': 'KR', 'Spain': 'ES', 'Sri Lanka': 'LK', 'Sudan': 'SD', 'Sweden': 'SE',
    'Switzerland': 'CH', 'Tanzania': 'TZ', 'Thailand': 'TH', 'Tunisia': 'TN', 'Turkey': 'TR',
    'Turkmenistan': 'TM', 'Uganda': 'UG', 'Ukraine': 'UA', 'United Arab Emirates': 'AE',
    'United Kingdom': 'GB', 'United States': 'US', 'Uruguay': 'UY', 'Uzbekistan': 'UZ',
    'Venezuela': 'VE', 'Vietnam': 'VN', 'Yemen': 'YE',
}

# Google Maps listings where they disagree with or add to the tables.
OVERRIDES = {
    ('Canada', 'Riyadh'): ['0112023288'],
    ('Malaysia', 'Riyadh'): ['0114887100'],
    ('Bangladesh', 'Riyadh'): ['0114195300'],
}
EXTRA = [
    ('Palestine', 'Riyadh', 'Embassy', ['0114880744']),
    ('Tunisia', 'Riyadh', 'Embassy', ['0549468141']),
    ('Yemen', 'Riyadh', 'Embassy', ['0114881769']),
    ('Sudan', 'Riyadh', 'Embassy', ['0114545151']),
]
# Rows whose numbers belong to another mission or are malformed at the source.
DROP = {
    ('Burundi', 'Riyadh'),
    ('United Kingdom', 'Jeddah'),
    ('Jordan', 'Jeddah'),
    ('Mauritius', 'Jeddah'),
    ('Guinea', 'Jeddah'),
    ('Malta', 'Jeddah'),
}


def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    return urllib.request.urlopen(request, timeout=30).read().decode('utf-8', 'replace')


def rows(page):
    found = []
    for row in re.findall(r'<tr[^>]*>(.*?)</tr>', page, re.S):
        cells = [
            re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', c))).strip()
            for c in re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>', row, re.S)
        ]
        if len(cells) >= 3 and cells[0] != 'Country':
            found.append(cells[:3])
    return found


def normalize(raw, area):
    digits = re.sub(r'\D', '', raw)
    digits = re.sub(r'^(00)?9[69]6', '', digits)
    digits = digits.lstrip('0')
    if len(digits) == 9:
        return '0' + digits
    if len(digits) == 8 and digits[0] in '12':
        return '01' + digits
    if len(digits) == 7:
        return area + digits
    return None


def numbers(text, area):
    parts = re.split(r'\band\b|/|;|,|ext\.', text)
    out = []
    for part in parts:
        number = normalize(part, area)
        if number and number not in out and not number.startswith('0' + '9'):
            out.append(number)
    return out[:2]


def mission_label(kind, city):
    kind = kind.strip()
    if city == 'Jeddah' and kind == 'Embassy':
        return 'Consulate'
    return kind


def build():
    missions = []
    for city, area in (('Riyadh', '011'), ('Jeddah', '012')):
        for country, kind, phone in rows(fetch(f'https://embassies.net/saudi-arabia/{city.lower()}')):
            if (country, city) in DROP:
                continue
            phones = OVERRIDES.get((country, city)) or numbers(phone, area)
            if not phones:
                continue
            missions.append((country, city, mission_label(kind, city), phones))
    known = {(m[0], m[1]) for m in missions}
    for extra in EXTRA:
        if (extra[0], extra[1]) not in known:
            missions.append(extra)

    seen = set()
    unique = []
    for mission in missions:
        key = (mission[0], mission[1], mission[3][0])
        if key not in seen:
            seen.add(key)
            unique.append(mission)
    unique.sort(key=lambda m: (m[0], m[1] != 'Riyadh', m[2]))

    lines = [
        '// Generated by tools/build_embassies.py. Do not edit by hand.',
        '// Sources: embassies.net Riyadh and Jeddah tables, checked against Google Maps listings.',
        "import 'emergencies.dart';",
        '',
        'const embassyDirectory = <Embassy>[',
    ]
    for country, city, kind, phones in unique:
        nation = IDS.get(country) or re.sub(r'[^a-z]+', '_', country.lower()).strip('_')
        flag = FLAGS.get(country, '')
        note = '' if kind == 'Embassy' else f", note: '{kind}'"
        alt = f", altPhone: '{phones[1]}'" if len(phones) > 1 else ''
        name = country.replace("'", "\\'")
        lines.append(
            f"  Embassy(nationalityId: '{nation}', country: '{name}', flag: '{flag}', "
            f"city: '{city}', phone: '{phones[0]}'{alt}{note}),"
        )
    lines.append('];')
    OUT.write_text('\n'.join(lines) + '\n')
    countries = {m[0] for m in unique}
    print(f'{len(unique)} missions, {len(countries)} countries -> {OUT}')
    missing_flag = sorted(c for c in countries if c not in FLAGS)
    if missing_flag:
        print('no flag:', missing_flag)


if __name__ == '__main__':
    build()
