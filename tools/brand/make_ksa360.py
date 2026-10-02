"""Builds the KSA 360 brand assets from one set of geometry.

Outputs:
  assets/brand/ksa360_splash.json  Lottie intro (emblem only, wordmark is Flutter text)
  assets/brand/ksa360_logo.svg     emblem + wordmark, for docs and sharing
  tools/brand/ksa360_icon.svg      full-bleed launcher icon source
  tools/brand/ksa360_icon_foreground.svg  adaptive icon foreground (transparent)

Concept: a brass jewel traces a full 360 degree orbit around the green roundel,
drawing the ring as it goes. When it lands, the Najdi eight-point star blooms
in the centre and the degree ticks sweep in around the edge.
"""

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIZE = 512
FPS = 60
END = 124

GREEN_CORE = '#1F6E4A'
GREEN_MID = '#174D36'
GREEN_EDGE = '#0E3122'
BRASS = '#A8793F'
BRASS_DEEP = '#8A5E2E'
BRASS_BRIGHT = '#E4C48A'
IVORY = '#F7F2E8'
NAVY = '#1B1916'

R_ORBIT = 226
R_ROUNDEL = 196
R_TICK_OUT = 182
R_TICK_IN = 172
R_TICK_LONG = 162
R_HAIRLINE = 150
R_STAR = 118
R_CORE_STAR = 54
R_CORE_DOT = 12
R_JEWEL = 13


def rgb(hex_color, alpha=1.0):
    h = hex_color.lstrip('#')
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)] + [alpha]


def static(value):
    return {'a': 0, 'k': value}


EASE_OUT = ({'x': 0.16, 'y': 1}, {'x': 0.3, 'y': 0})
EASE_IN_OUT = ({'x': 0.3, 'y': 1}, {'x': 0.6, 'y': 0})


def anim(*frames, ease=EASE_OUT):
    """frames: (t, value) pairs. value is a number or list."""
    keys = []
    for index, (t, value) in enumerate(frames):
        s = value if isinstance(value, list) else [value]
        key = {'t': t, 's': s}
        if index < len(frames) - 1:
            key['i'] = ease[0]
            key['o'] = ease[1]
        keys.append(key)
    return {'a': 1, 'k': keys}


def transform(p=(0, 0), s=100, r=0, o=100):
    return {
        'ty': 'tr',
        'p': static(list(p)),
        'a': static([0, 0]),
        's': s if isinstance(s, dict) else static([s, s]),
        'r': r if isinstance(r, dict) else static(r),
        'o': o if isinstance(o, dict) else static(o),
        'sk': static(0),
        'sa': static(0),
    }


def ellipse(radius):
    return {'ty': 'el', 'p': static([0, 0]), 's': static([radius * 2, radius * 2]), 'd': 1}


def path(points, closed=True):
    return {
        'ty': 'sh',
        'ks': static({
            'i': [[0, 0] for _ in points],
            'o': [[0, 0] for _ in points],
            'v': [list(p) for p in points],
            'c': closed,
        }),
    }


def stroke(color, width, opacity=100, cap=2, join=2):
    return {
        'ty': 'st',
        'c': static(rgb(color)),
        'o': opacity if isinstance(opacity, dict) else static(opacity),
        'w': static(width),
        'lc': cap,
        'lj': join,
        'ml': 4,
    }


def fill(color, opacity=100):
    return {
        'ty': 'fl',
        'c': static(rgb(color)),
        'o': opacity if isinstance(opacity, dict) else static(opacity),
        'r': 1,
    }


def radial_fill(stops, start, end):
    flat = []
    for offset, color in stops:
        flat += [offset] + rgb(color)[:3]
    return {
        'ty': 'gf',
        'o': static(100),
        'r': 1,
        't': 2,
        's': static(list(start)),
        'e': static(list(end)),
        'h': static(0),
        'a': static(0),
        'g': {'p': len(stops), 'k': static(flat)},
    }


def trim(start=0, end=100, offset=0, mode=1):
    wrap = lambda v: v if isinstance(v, dict) else static(v)
    return {'ty': 'tm', 's': wrap(start), 'e': wrap(end), 'o': wrap(offset), 'm': mode}


def group(name, items, **tr):
    return {'ty': 'gr', 'nm': name, 'it': items + [transform(**tr)]}


def layer(index, name, shapes, *, s=100, r=0, o=100, ip=0):
    return {
        'ddd': 0,
        'ind': index,
        'ty': 4,
        'nm': name,
        'sr': 1,
        'ks': {
            'o': o if isinstance(o, dict) else static(o),
            'r': r if isinstance(r, dict) else static(r),
            'p': static([SIZE / 2, SIZE / 2, 0]),
            'a': static([0, 0, 0]),
            's': s if isinstance(s, dict) else static([s, s, 100]),
        },
        'ao': 0,
        'shapes': shapes,
        'ip': ip,
        'op': END,
        'st': 0,
        'bm': 0,
    }


def star_points(outer, rotation=0.0):
    inner = outer * math.cos(math.radians(45)) / math.cos(math.radians(22.5))
    points = []
    for i in range(16):
        radius = outer if i % 2 == 0 else inner
        angle = math.radians(-90 + rotation + i * 22.5)
        points.append((round(radius * math.cos(angle), 3), round(radius * math.sin(angle), 3)))
    return points


def tick_segments():
    segments = []
    for i in range(36):
        angle = math.radians(-90 + i * 10)
        inner = R_TICK_LONG if i % 9 == 0 else R_TICK_IN
        c, s = math.cos(angle), math.sin(angle)
        segments.append((
            (round(inner * c, 3), round(inner * s, 3)),
            (round(R_TICK_OUT * c, 3), round(R_TICK_OUT * s, 3)),
            i % 9 == 0,
        ))
    return segments


def scale3(*frames, ease=EASE_OUT):
    return anim(*[(t, [v, v, 100]) for t, v in frames], ease=ease)


def build_lottie():
    orbit_start, orbit_end = 14, 72
    landed = orbit_end

    jewel = layer(
        1,
        'jewel',
        [
            group('comet-soft', [
                ellipse(R_ORBIT),
                trim(start=80, end=100),
                stroke(BRASS_BRIGHT, 9, opacity=anim((orbit_start, 0), (orbit_start + 8, 55), (landed - 8, 55), (landed + 6, 0))),
            ]),
            group('comet', [
                ellipse(R_ORBIT),
                trim(start=93, end=100),
                stroke(BRASS, 8, opacity=anim((orbit_start, 0), (orbit_start + 6, 100), (landed - 6, 100), (landed + 8, 0))),
            ]),
            group('jewel-glow', [
                ellipse(R_JEWEL + 14),
                fill(BRASS_BRIGHT, opacity=anim((landed, 0), (landed + 8, 45), (landed + 34, 0))),
            ], p=(0, -R_ORBIT), s=anim((landed, [60, 60]), (landed + 34, [190, 190]))),
            group('jewel-core', [
                ellipse(5),
                fill(IVORY),
            ], p=(0, -R_ORBIT)),
            group('jewel-body', [
                ellipse(R_JEWEL),
                radial_fill([(0, BRASS_BRIGHT), (1, BRASS_DEEP)], (-4, -5), (R_JEWEL, R_JEWEL)),
            ], p=(0, -R_ORBIT), s=anim(
                (orbit_start - 4, [0, 0]),
                (orbit_start + 6, [100, 100]),
                (landed, [100, 100]),
                (landed + 8, [150, 150]),
                (landed + 22, [100, 100]),
            )),
        ],
        r=anim((orbit_start, 0), (orbit_end, 360), ease=EASE_IN_OUT),
    )

    ripple = layer(
        2,
        'ripple',
        [group('ripple', [
            ellipse(R_ORBIT),
            stroke(BRASS, 2.5, opacity=anim((landed, 0), (landed + 4, 70), (landed + 40, 0))),
        ])],
        s=scale3((landed, 100), (landed + 40, 116)),
    )

    orbit = layer(
        3,
        'orbit',
        [group('orbit', [
            ellipse(R_ORBIT),
            trim(end=anim((orbit_start, 0), (orbit_end, 100), ease=EASE_IN_OUT)),
            stroke(BRASS, 6),
        ])],
    )

    core = layer(
        4,
        'core-star',
        [
            group('core-dot', [ellipse(R_CORE_DOT), fill(GREEN_EDGE)]),
            group('core-star', [path(star_points(R_CORE_STAR)), fill(BRASS_BRIGHT)]),
        ],
        s=scale3((58, 0), (80, 112), (94, 100)),
        r=anim((58, 45), (96, 0)),
    )

    star = layer(
        5,
        'star',
        [
            group('star-echo', [
                path(star_points(R_STAR, rotation=22.5)),
                trim(end=anim((40, 0), (84, 100))),
                stroke(BRASS_BRIGHT, 2, opacity=32, join=1),
            ]),
            group('star', [
                path(star_points(R_STAR)),
                trim(end=anim((30, 0), (74, 100))),
                stroke(BRASS_BRIGHT, 5, join=1),
            ]),
        ],
        r=anim((30, -90), (92, 0)),
    )

    ticks = layer(
        6,
        'ticks',
        [
            group('ticks-long', [
                *[path([a, b], closed=False) for a, b, long in tick_segments() if long],
                trim(end=anim((44, 0), (90, 100)), mode=2),
                stroke(BRASS_BRIGHT, 3.5, opacity=90),
            ]),
            group('ticks', [
                *[path([a, b], closed=False) for a, b, long in tick_segments() if not long],
                trim(end=anim((44, 0), (90, 100)), mode=2),
                stroke(BRASS_BRIGHT, 2, opacity=55),
            ]),
        ],
    )

    hairline = layer(
        7,
        'hairline',
        [group('hairline', [ellipse(R_HAIRLINE), stroke(BRASS_BRIGHT, 1.5, opacity=38)])],
        o=anim((28, 0), (56, 100)),
    )

    roundel = layer(
        8,
        'roundel',
        [
            group('rim', [ellipse(R_ROUNDEL - 1.5), stroke(BRASS_BRIGHT, 1.5, opacity=45)]),
            group('disc', [
                ellipse(R_ROUNDEL),
                radial_fill(
                    [(0, GREEN_CORE), (0.62, GREEN_MID), (1, GREEN_EDGE)],
                    (-54, -70),
                    (R_ROUNDEL + 40, R_ROUNDEL + 40),
                ),
            ]),
        ],
        s=scale3((0, 0), (22, 104), (34, 100)),
        o=anim((0, 0), (10, 100)),
    )

    shadow = layer(
        9,
        'shadow',
        [group('shadow', [ellipse(R_ROUNDEL + 4), fill(GREEN_EDGE, opacity=12)], p=(0, 12))],
        s=scale3((0, 0), (22, 104), (34, 100)),
        o=anim((6, 0), (30, 100)),
    )

    return {
        'v': '5.7.4',
        'fr': FPS,
        'ip': 0,
        'op': END,
        'w': SIZE,
        'h': SIZE,
        'nm': 'KSA 360 intro',
        'ddd': 0,
        'assets': [],
        'layers': [jewel, ripple, orbit, core, star, ticks, hairline, roundel, shadow],
    }


def svg_points(points, cx, cy):
    return ' '.join(f'{cx + x:.2f},{cy + y:.2f}' for x, y in points)


def svg_emblem(cx, cy, scale=1.0, *, on_green=False):
    def k(value):
        return value * scale

    ticks = []
    for a, b, long in tick_segments():
        ticks.append(
            f'<line x1="{cx + k(a[0]):.2f}" y1="{cy + k(a[1]):.2f}" '
            f'x2="{cx + k(b[0]):.2f}" y2="{cy + k(b[1]):.2f}" '
            f'stroke="{BRASS_BRIGHT}" stroke-width="{k(3.5 if long else 2):.2f}" '
            f'stroke-opacity="{0.9 if long else 0.55}" stroke-linecap="round"/>'
        )
    ring_color = BRASS_BRIGHT if on_green else BRASS
    star = [(k(x), k(y)) for x, y in star_points(R_STAR)]
    echo = [(k(x), k(y)) for x, y in star_points(R_STAR, rotation=22.5)]
    core = [(k(x), k(y)) for x, y in star_points(R_CORE_STAR)]
    return f'''
  <circle cx="{cx}" cy="{cy + k(12)}" r="{k(R_ROUNDEL + 4)}" fill="{GREEN_EDGE}" fill-opacity="{0 if on_green else 0.12}"/>
  <circle cx="{cx}" cy="{cy}" r="{k(R_ROUNDEL)}" fill="url(#disc)"/>
  <circle cx="{cx}" cy="{cy}" r="{k(R_ROUNDEL - 1.5)}" fill="none" stroke="{BRASS_BRIGHT}" stroke-opacity="0.45" stroke-width="{k(1.5)}"/>
  <circle cx="{cx}" cy="{cy}" r="{k(R_HAIRLINE)}" fill="none" stroke="{BRASS_BRIGHT}" stroke-opacity="0.38" stroke-width="{k(1.5)}"/>
  {''.join(ticks)}
  <polygon points="{svg_points(echo, cx, cy)}" fill="none" stroke="{BRASS_BRIGHT}" stroke-opacity="0.32" stroke-width="{k(2)}"/>
  <polygon points="{svg_points(star, cx, cy)}" fill="none" stroke="{BRASS_BRIGHT}" stroke-width="{k(5)}" stroke-linejoin="miter"/>
  <polygon points="{svg_points(core, cx, cy)}" fill="{BRASS_BRIGHT}"/>
  <circle cx="{cx}" cy="{cy}" r="{k(R_CORE_DOT)}" fill="{GREEN_EDGE}"/>
  <circle cx="{cx}" cy="{cy}" r="{k(R_ORBIT)}" fill="none" stroke="{ring_color}" stroke-width="{k(6)}"/>
  <circle cx="{cx}" cy="{cy - k(R_ORBIT)}" r="{k(R_JEWEL)}" fill="url(#jewel)"/>
  <circle cx="{cx}" cy="{cy - k(R_ORBIT)}" r="{k(5)}" fill="{IVORY}"/>'''


def svg_defs(cx, cy, scale=1.0):
    return f'''
  <defs>
    <radialGradient id="disc" gradientUnits="userSpaceOnUse" cx="{cx - 54 * scale}" cy="{cy - 70 * scale}" r="{(R_ROUNDEL + 40) * 1.414 * scale}">
      <stop offset="0" stop-color="{GREEN_CORE}"/>
      <stop offset="0.62" stop-color="{GREEN_MID}"/>
      <stop offset="1" stop-color="{GREEN_EDGE}"/>
    </radialGradient>
    <radialGradient id="jewel" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="{BRASS_BRIGHT}"/>
      <stop offset="1" stop-color="{BRASS_DEEP}"/>
    </radialGradient>
  </defs>'''


def build_logo_svg():
    width, height = 1340, 520
    cx, cy, scale = 260, 260, 0.96
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
  {svg_defs(cx, cy, scale)}
  {svg_emblem(cx, cy, scale)}
  <text x="540" y="300" font-family="Plus Jakarta Sans, Avenir Next, Helvetica Neue, Arial, sans-serif" font-size="150" font-weight="800" letter-spacing="-3" fill="{NAVY}">KSA<tspan dx="28" fill="{BRASS_DEEP}">360</tspan></text>
  <text x="546" y="360" font-family="Plus Jakarta Sans, Avenir Next, Helvetica Neue, Arial, sans-serif" font-size="30" font-weight="600" letter-spacing="9" fill="#6E665C">SAUDI ARABIA · ALL AROUND YOU</text>
</svg>
'''


def build_icon_svg():
    size = 1024
    cx = cy = size / 2
    scale = 1.78
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  {svg_defs(cx, cy, scale)}
  <rect width="{size}" height="{size}" fill="{GREEN_EDGE}"/>
  {svg_emblem(cx, cy, scale, on_green=True)}
</svg>
'''


def build_icon_foreground_svg():
    """Adaptive icon foreground: emblem inside the 66dp safe circle of a 108dp canvas."""
    size = 1024
    cx = cy = size / 2
    scale = (size * 0.62 / 2) / (R_ORBIT + R_JEWEL)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  {svg_defs(cx, cy, scale)}
  {svg_emblem(cx, cy, scale, on_green=True)}
</svg>
'''


def main():
    brand = ROOT / 'assets' / 'brand'
    brand.mkdir(parents=True, exist_ok=True)
    (brand / 'ksa360_splash.json').write_text(json.dumps(build_lottie(), separators=(',', ':')))
    (brand / 'ksa360_logo.svg').write_text(build_logo_svg())
    (ROOT / 'tools' / 'brand' / 'ksa360_icon.svg').write_text(build_icon_svg())
    (ROOT / 'tools' / 'brand' / 'ksa360_icon_foreground.svg').write_text(build_icon_foreground_svg())
    print('wrote', brand / 'ksa360_splash.json')


if __name__ == '__main__':
    main()
