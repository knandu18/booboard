#!/usr/bin/env python3
"""Renders the BooBoard brand: SVG sources, Android vector drawables, launcher PNGs and store art.

The brand is Boo, the black ghost with lime eyes on a lime tile (see "the ghost" below, since 2026-11-26): the
launcher icons, the themed icon, the legacy PNGs, the splash, the mascot poses, the Play icon, the feature
graphic and the screenshot frame use it (the chest geometry below is kept for reference).
Shapes live on a 108 x 108 grid (the adaptive-icon canvas; the safe zone is the inner 66 x 66 square).
Every output is generated from these shapes:

  assets/brand/*.svg                             SVG sources (icon, monochrome, poses)
  android/app/src/main/res/drawable/ic_launcher_foreground.xml
  android/app/src/main/res/drawable/ic_launcher_monochrome.xml
  android/app/src/main/res/drawable/splash_ghost.xml
  android/app/src/main/res/mipmap-*dpi/ic_launcher.png  legacy launcher icons
  docs/brand/play_icon_512.png                   Play Store icon (opaque)
  docs/brand/feature_graphic_1024x500.png        Play feature graphic
  docs/brand/screenshot_frame.svg                store screenshot template with caption space
  docs/brand/icon-masks.png                      preview: masks, themed icon, 48 px

The Dart poses in lib/src/app/onboarding/booboard_mascot.dart are a hand port of the same layout
(BooShape there; it also waves the hem). Keep the two in step when the geometry changes.

Run from anywhere:  python tool/brand/render.py
Needs Pillow on the dev machine only. The app has no dependency on it.
"""

import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SS = 4  # supersampling factor for anti-aliased rasters

# Palette. Gold is the seed colour of the brand scheme (booboardYellow); brown is booboardBrown.
GOLD = '#EFB33A'
GOLD_LIGHT = '#FFE3A1'
GOLD_GLOW = '#FFF1C7'
BROWN = '#3E2723'
MUTE = '#B9A98F'
MUTE_LIGHT = '#E3D8C8'
MUTE_DARK = '#6B5B52'
CREAM = '#FFF6E3'
NIGHT = '#211714'
TONAL_LIGHT = '#E8DEF8'
TONAL_INK = '#4A4458'
WALL_LIGHT = '#F4F1EA'
WALL_DARK = '#1C1B1F'


# ---------------------------------------------------------------- geometry

def rrect(x, y, w, h, r, seg=12):
    """Rounded rectangle as a closed polygon (clockwise on screen)."""
    r = min(r, w / 2, h / 2)
    corners = [
        (x + w - r, y + r, -90, 0),
        (x + w - r, y + h - r, 0, 90),
        (x + r, y + h - r, 90, 180),
        (x + r, y + r, 180, 270),
    ]
    pts = []
    for cx, cy, a0, a1 in corners:
        for i in range(seg + 1):
            a = math.radians(a0 + (a1 - a0) * i / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rect(x, y, w, h):
    return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]


def circle(cx, cy, r, n=120):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def sparkle(cx, cy, r):
    """Four-point star with straight sides."""
    pts = []
    for i in range(8):
        a = math.radians(-90 + 45 * i)
        rad = r if i % 2 == 0 else r * 0.22
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return pts


def rotate(pts, cx, cy, deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]


# The chest. Lid and body are separated by a 4-unit gap; the keycap is the lock.
LID = rrect(24, 30, 60, 20, 10)
BODY = rrect(24, 54, 60, 24, 4)
SHINE = rrect(34, 34, 40, 3, 1.5)
STRAPS = [rect(36, 30, 5, 48), rect(67, 30, 5, 48)]
KEY_OUTER = rrect(44, 59, 20, 15, 4)
KEY_FACE = rrect(47.5, 62, 13, 9, 2.5)


def layer(color, *subs, alpha=1.0):
    return {'color': color, 'subs': list(subs), 'alpha': alpha}


def closed_chest(body, shine, detail, key_face):
    return [
        layer(body, LID),
        layer(body, BODY),
        layer(shine, SHINE),
        layer(detail, *STRAPS),
        layer(detail, KEY_OUTER),
        layer(key_face, KEY_FACE),
    ]


FULL = dict(body=GOLD, shine=GOLD_LIGHT, detail=BROWN, key_face=GOLD_LIGHT)


def background_layers():
    return [layer(BROWN, rect(0, 0, 108, 108))]


def foreground_layers():
    """The chest alone, on a transparent canvas: the adaptive foreground and the splash icon."""
    return closed_chest(**FULL)


def monochrome_layers(color='#000000'):
    """Silhouette for themed icons. The keycap is negative space (a hole with its face filled back in)."""
    return [layer(color, LID, BODY, KEY_OUTER, KEY_FACE)]


def icon_layers():
    return background_layers() + foreground_layers()


def open_layers():
    hinge = (24, 50)
    lid = rotate(LID, *hinge, -24)
    lid_shine = rotate(SHINE, *hinge, -24)
    lid_straps = [rotate(rect(36, 30, 5, 20), *hinge, -24), rotate(rect(67, 30, 5, 20), *hinge, -24)]
    return [
        layer(GOLD, BODY),
        layer(BROWN, rect(26, 54, 56, 6)),
        layer(BROWN, rect(36, 54, 5, 24), rect(67, 54, 5, 24)),
        layer(GOLD, lid),
        layer(GOLD_LIGHT, lid_shine),
        layer(BROWN, *lid_straps),
        layer(GOLD_LIGHT, sparkle(90, 14, 5), sparkle(98, 36, 3.6)),
    ]


def glowing_layers():
    return [
        layer(GOLD, circle(54, 54, 46), alpha=0.16),
        layer(GOLD, circle(54, 54, 38), alpha=0.22),
        *closed_chest(body=GOLD, shine=GOLD_GLOW, detail=BROWN, key_face=GOLD_GLOW),
        layer(GOLD_GLOW, sparkle(14, 26, 5), sparkle(94, 22, 4.5), sparkle(96, 80, 3.5)),
    ]


def quiet_layers():
    return [
        *closed_chest(body=MUTE, shine=MUTE_LIGHT, detail=MUTE_DARK, key_face=MUTE_LIGHT),
        layer(MUTE_DARK, circle(44, 20, 2.8), circle(54, 20, 2.8), circle(64, 20, 2.8)),
    ]


# ---------------------------------------------------------------- the ghost (Boo, since 2026-11-26)
#
# Boo: a black ghost with lime eyes on a flat lime tile (#E3F794), the look of first-run setup
# (prototype .design/onboarding_v2.html, "middle" height, approved 2026-11-26). The body is a dome, long
# sides and a small wavy hem of three lobes; a diagonal sheen (lighter top left) gives it some depth and
# each eye has a small white shine. lib/src/app/onboarding/booboard_mascot.dart (BooShape) draws the same
# shape in Dart, with the hem waving; this is its still pose. Launchers show the inner 72 x 72 of the 108
# canvas, so a 180-unit tile maps onto that visible square; the poses use a larger placement.

LIME = '#E3F794'
INK = '#161015'
BOO_SHEEN, BOO_BODY, BOO_EDGE = '#4A4247', '#211B20', '#0E0A0D'
GHOST_TILE = LIME
GHOST_WHITE = '#FFFFFF'
GHOST_INK = INK
BOO = [(0.0, BOO_SHEEN), (0.45, BOO_BODY), (1.0, BOO_EDGE)]

_BOO_PATH = ('M6 116C8 92 13 73 14 50C14 22 30 4 50 4C70 4 86 22 86 50C87 73 92 92 94 116'
             'C94 121 88 125 79 125C72 125 71.5 114 64.5 114C57.5 114 57 125 50 125'
             'C43 125 42.5 114 35.5 114C28.5 114 28 125 21 125C12 125 6 121 6 116Z')
_BOO_EYES = ((36.0, 50.0), (64.0, 50.0))
_BOO_EYE_R = (9.0, 12.5)
_BOO_SHINE = (-3.0, -5.0, 2.6, 3.4)  # offset from each eye's centre, radii
_BOO_BOX = (6.0, 4.0, 94.0, 125.0)    # x0, y0, x1, y1 of the body


def _cubic_path(d, steps=24):
    """Flattens an absolute M/C/Z path to one polygon."""
    import re
    toks = re.findall(r'[MCZ]|-?\d+(?:\.\d+)?', d)
    pts, i, cur = [], 0, (0.0, 0.0)
    while i < len(toks):
        t = toks[i]
        if t == 'M':
            cur = (float(toks[i + 1]), float(toks[i + 2]))
            pts.append(cur)
            i += 3
        elif t == 'C':
            i += 1
            while i < len(toks) and toks[i] not in ('M', 'C', 'Z'):
                c1 = (float(toks[i]), float(toks[i + 1]))
                c2 = (float(toks[i + 2]), float(toks[i + 3]))
                p = (float(toks[i + 4]), float(toks[i + 5]))
                for s in range(1, steps + 1):
                    u = s / steps
                    a, b, c, e = (1 - u) ** 3, 3 * (1 - u) ** 2 * u, 3 * (1 - u) * u * u, u ** 3
                    pts.append((a * cur[0] + b * c1[0] + c * c2[0] + e * p[0],
                                a * cur[1] + b * c1[1] + c * c2[1] + e * p[1]))
                cur = p
                i += 6
        else:
            i += 1
    if pts and pts[0] == pts[-1]:
        pts.pop()
    return pts


def _ellipse(cx, cy, rx, ry, n=72):
    return [(cx + rx * math.cos(2 * math.pi * i / n), cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n)]


def _boo_mapper(tile_x, tile_y, tile_size):
    """Maps Boo's body frame onto the 108 canvas, centred on a 180-unit tile filling [tile_size] units."""
    k = tile_size / 180.0
    s = 0.95
    cx, cy = (_BOO_BOX[0] + _BOO_BOX[2]) / 2, (_BOO_BOX[1] + _BOO_BOX[3]) / 2
    return lambda x, y: (tile_x + (90 + s * (x - cx)) * k, tile_y + (90 + s * (y - cy)) * k)


ICON_MAP = _boo_mapper(18, 18, 72)   # the launcher's visible square
POSE_MAP = _boo_mapper(-6, -6, 120)  # bigger, for the mascot poses


def _mapped(f, pts):
    return [f(x, y) for x, y in pts]


def _eyes(f):
    return [_mapped(f, _ellipse(cx, cy, *_BOO_EYE_R)) for cx, cy in _BOO_EYES]


def boo_layers(f=ICON_MAP, eyes=True):
    body = _mapped(f, _cubic_path(_BOO_PATH))
    (x0, y0), (x1, y1) = f(_BOO_BOX[0], _BOO_BOX[1]), f(_BOO_BOX[2], _BOO_BOX[3])
    out = [dict(layer(BOO_BODY, body), gradient={'x1': x0, 'y1': y0, 'x2': x1, 'y2': y1, 'stops': BOO})]
    if eyes:
        dx, dy, rx, ry = _BOO_SHINE
        out.append(layer(LIME, *_eyes(f)))
        out.append(layer(GHOST_WHITE, *[_mapped(f, _ellipse(cx + dx, cy + dy, rx, ry, n=36)) for cx, cy in _BOO_EYES],
                         alpha=0.7))
    return out


def ghost_foreground_layers():
    """The adaptive-icon foreground and the splash icon: Boo on a transparent canvas."""
    return boo_layers()


def ghost_background_layers():
    return [layer(LIME, rect(0, 0, 108, 108))]


def ghost_monochrome_layers(color='#000000'):
    """Themed icon: Boo's silhouette with the eyes as holes (even-odd)."""
    f = ICON_MAP
    return [layer(color, _mapped(f, _cubic_path(_BOO_PATH)), *_eyes(f))]


def ghost_icon_layers():
    return ghost_background_layers() + ghost_foreground_layers()


# ---------------------------------------------------------------- ghost poses (mascot)
#
# The in-app mascot (lib/src/app/onboarding/booboard_mascot.dart) draws the same poses in Dart.

GHOST_MUTE_BODY = '#6E686C'
GHOST_MUTE_INK = '#CFD8A6'


def _arc_band(cx, cy, r, w, a0, a1, n=24):
    """A curved stroke: the ring between radius r - w/2 and r + w/2, from angle a0 to a1 (degrees, y down)."""
    outer = [(cx + (r + w / 2) * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
              cy + (r + w / 2) * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
    inner = [(cx + (r - w / 2) * math.cos(math.radians(a1 - (a1 - a0) * i / n)),
              cy + (r - w / 2) * math.sin(math.radians(a1 - (a1 - a0) * i / n))) for i in range(n + 1)]
    return outer + inner


def ghost_pose_open():
    """Welcome: Boo with two ink sparkles."""
    return boo_layers(POSE_MAP) + [layer(INK, sparkle(92, 16, 6)), layer(INK, sparkle(100, 34, 4))]


def ghost_pose_locked():
    """Privacy and app lock: Boo with a padlock badge (ink circle, lime padlock)."""
    f = _boo_mapper(-10, -10, 110)
    bx, by = 82, 84
    shackle = _arc_band(bx, by - 3.5, 4.6, 2.4, 180, 360)
    return boo_layers(f) + [
        layer(LIME, circle(bx, by, 15)),
        layer(INK, circle(bx, by, 13)),
        layer(LIME, shackle, rect(bx - 5.8, by - 3.6, 1.2, 3.2), rect(bx + 4.6, by - 3.6, 1.2, 3.2)),
        layer(LIME, rrect(bx - 7, by - 1, 14, 10, 2.2)),
        layer(INK, circle(bx, by + 3.5, 1.6, n=24)),
    ]


def ghost_pose_glowing():
    """Voice, translation, work in progress: a soft white glow behind Boo and ink sparkles."""
    return [
        layer(GHOST_WHITE, circle(54, 54, 52), alpha=0.35),
        layer(GHOST_WHITE, circle(54, 54, 44), alpha=0.35),
    ] + boo_layers(POSE_MAP) + [
        layer(INK, sparkle(12, 24, 5)),
        layer(INK, sparkle(98, 18, 4.5)),
        layer(INK, sparkle(98, 86, 3.5)),
    ]


def ghost_pose_quiet():
    """Incognito and empty states: a muted Boo with closed eyes."""
    f = POSE_MAP
    closed = [_mapped(f, _arc_band(cx, cy - 2, 8.0, 3.6, 20, 160)) for cx, cy in _BOO_EYES]
    return [
        layer(GHOST_MUTE_BODY, _mapped(f, _cubic_path(_BOO_PATH))),
        layer(GHOST_MUTE_INK, *closed),
    ]


POSES = {
    'pose_open': ghost_pose_open,
    'pose_locked': ghost_pose_locked,
    'pose_glowing': ghost_pose_glowing,
    'pose_quiet': ghost_pose_quiet,
}


# ---------------------------------------------------------------- output formats

def fmt(v):
    s = f'{v:.2f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def path_d(subs):
    return ''.join('M' + 'L'.join(f'{fmt(x)},{fmt(y)}' for x, y in pts) + 'Z' for pts in subs)


def to_svg(layers, comment):
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<!-- {comment}. Generated by tool/brand/render.py; edit the geometry there. -->',
        '<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">',
    ]
    for n, lay in enumerate(layers):
        opacity = '' if lay['alpha'] >= 1 else f' fill-opacity="{fmt(lay["alpha"])}"'
        fill = lay['color']
        g = lay.get('gradient')
        if g:
            gid = f'g{n}'
            lines.append(
                f'  <defs><linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{fmt(g["x1"])}" '
                f'y1="{fmt(g["y1"])}" x2="{fmt(g["x2"])}" y2="{fmt(g["y2"])}">'
                + ''.join(f'<stop offset="{fmt(o)}" stop-color="{c}"/>' for o, c in g['stops'])
                + '</linearGradient></defs>'
            )
            fill = f'url(#{gid})'
        lines.append(
            f'  <path fill="{fill}"{opacity} fill-rule="evenodd" d="{path_d(lay["subs"])}"/>'
        )
    lines.append('</svg>')
    return '\n'.join(lines) + '\n'


def to_vector_drawable(layers, comment):
    gradients = any(lay.get('gradient') for lay in layers)
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        f'<!-- {comment}. Generated by tool/brand/render.py; edit the geometry there. -->',
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"',
        *(['    xmlns:aapt="http://schemas.android.com/aapt"'] if gradients else []),
        '    android:width="108dp"',
        '    android:height="108dp"',
        '    android:viewportWidth="108"',
        '    android:viewportHeight="108">',
    ]
    for lay in layers:
        alpha = '' if lay['alpha'] >= 1 else f'\n        android:fillAlpha="{fmt(lay["alpha"])}"'
        g = lay.get('gradient')
        lines.append('    <path')
        if not g:
            lines.append(f'        android:fillColor="{lay["color"]}"{alpha}')
        elif alpha:
            lines.append(f'       {alpha.strip()}')
        lines.append('        android:fillType="evenOdd"')
        if not g:
            lines.append(f'        android:pathData="{path_d(lay["subs"])}" />')
            continue
        # Gradient fills (API 24+; the adaptive icon needs 26) go in an aapt:attr block.
        lines.append(f'        android:pathData="{path_d(lay["subs"])}">')
        lines.append('        <aapt:attr name="android:fillColor">')
        lines.append(
            f'            <gradient android:type="linear" android:startX="{fmt(g["x1"])}" '
            f'android:startY="{fmt(g["y1"])}" android:endX="{fmt(g["x2"])}" android:endY="{fmt(g["y2"])}">'
        )
        for o, c in g['stops']:
            lines.append(f'                <item android:offset="{fmt(o)}" android:color="{c}" />')
        lines.append('            </gradient>')
        lines.append('        </aapt:attr>')
        lines.append('    </path>')
    lines.append('</vector>')
    return '\n'.join(lines) + '\n'


def hex_rgba(h):
    h = h.lstrip('#')
    if len(h) == 6:
        h = 'FF' + h
    return tuple(int(h[i:i + 2], 16) for i in (2, 4, 6, 0))


def linear_gradient(big, scale, g):
    """A big x big RGBA image of the layer gradient [g] (coordinates on the 108 grid, clamped at the ends)."""
    small = 216
    k = small / 108.0
    x1, y1, x2, y2 = g['x1'] * k, g['y1'] * k, g['x2'] * k, g['y2'] * k
    dx, dy = x2 - x1, y2 - y1
    length2 = dx * dx + dy * dy or 1.0
    stops = [(o, hex_rgba(c)) for o, c in g['stops']]
    img = Image.new('RGBA', (small, small))
    px = img.load()
    for y in range(small):
        for x in range(small):
            t = min(max(((x - x1) * dx + (y - y1) * dy) / length2, 0.0), 1.0)
            for i in range(len(stops) - 1):
                (o0, c0), (o1, c1) = stops[i], stops[i + 1]
                if o0 <= t <= o1:
                    f = (t - o0) / (o1 - o0) if o1 > o0 else 0.0
                    px[x, y] = tuple(int(round(c0[j] + (c1[j] - c0[j]) * f)) for j in range(4))
                    break
    return img.resize((big, big), Image.BILINEAR)


def raster(layers, px, supersample=SS):
    """Rasterises layers (painter's order) onto a transparent px x px RGBA image."""
    big = px * supersample
    scale = big / 108.0
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    for lay in layers:
        mask = Image.new('L', (big, big), 0)
        for pts in lay['subs']:
            m = Image.new('L', (big, big), 0)
            ImageDraw.Draw(m).polygon([(x * scale, y * scale) for x, y in pts], fill=255)
            mask = ImageChops.difference(mask, m)  # even-odd: overlapping subpaths cancel
        if lay['alpha'] < 1:
            mask = mask.point(lambda v, a=lay['alpha']: int(round(v * a)))
        g = lay.get('gradient')
        colour = linear_gradient(big, scale, g) if g else Image.new('RGBA', (big, big), hex_rgba(lay['color']))
        colour.putalpha(mask)
        img = Image.alpha_composite(img, colour)
    return img.resize((px, px), Image.LANCZOS)


def raster_visible(layers, px):
    """Rasterises the launcher's visible square (the inner 72 x 72 of the 108 canvas) at px x px."""
    full = raster(layers, round(px * 1.5))
    off = (full.width - px) // 2
    return full.crop((off, off, off + px, off + px))


def write_text(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def save_png(img, path):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img.save(full, optimize=True)


# ---------------------------------------------------------------- store art

def screenshot_frame_svg():
    # The ghost mark: its SVG body (gradient defs included), without the XML header and outer <svg>.
    mark = to_svg(ghost_foreground_layers(), 'mark').splitlines()[3:-1]
    body_paths = ['    ' + line.strip() for line in mark]
    return '\n'.join([
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<!-- Store screenshot frame (1080 x 1920). Generated by tool/brand/render.py. -->',
        '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">',
        f'  <rect width="1080" height="1920" fill="{GHOST_TILE}"/>',
        '  <!-- Ghost mark, top left. Keep it small: it is a sign-off, not the hero. -->',
        '  <g transform="translate(60,60) scale(1.8)">',
        *body_paths,
        '  </g>',
        '  <!-- Caption: one short line, large. Replace the placeholder text. -->',
        f'  <text x="80" y="420" font-family="Google Sans Flex, Roboto, sans-serif" font-size="96" '
        f'font-weight="600" fill="{INK}">Your caption goes here</text>',
        f'  <text x="80" y="500" font-family="Google Sans Flex, Roboto, sans-serif" font-size="48" '
        f'fill="{INK}">One supporting line, if needed</text>',
        '  <!-- Screenshot slot: 920 x 1200 at 3:4, rounded. Place the device capture here. -->',
        f'  <rect x="80" y="620" width="920" height="1200" rx="56" fill="#0E0C14" stroke="{INK}" '
        'stroke-width="6" stroke-dasharray="24 16"/>',
        f'  <text x="540" y="1230" text-anchor="middle" font-family="Google Sans Flex, Roboto, sans-serif" '
        f'font-size="44" fill="{GHOST_MUTE_INK}">Screenshot</text>',
        '</svg>',
        '',
    ])


def feature_graphic():
    img = Image.new('RGBA', (1024, 500), hex_rgba(GHOST_TILE))
    mark = raster(ghost_foreground_layers(), 380)
    img.alpha_composite(mark, (60, 60))
    font_path = os.path.join(ROOT, 'assets', 'fonts', 'GoogleSansFlex.ttf')
    sub = ImageFont.truetype(font_path, 44)
    small = ImageFont.truetype(font_path, 28)
    draw = ImageDraw.Draw(img)
    # The largest title that fits between the mark and the right edge.
    size = 168
    while size > 40:
        title = ImageFont.truetype(font_path, size)
        title.set_variation_by_axes([144, 100, 600, 0, 0])
        if draw.textlength('BooBoard', font=title) <= 1024 - 446 - 48:
            break
        size -= 4
    title.set_variation_by_axes([144, 100, 600, 0, 0])  # optical size, width, weight 600, roundness, slant
    draw.text((440, 278 - int(size * 1.25)), 'BooBoard', font=title, fill=hex_rgba(INK))
    draw.text((446, 300), 'Your words, kept with you.', font=sub, fill=hex_rgba(INK))
    draw.text((446, 362), 'Works offline. Nothing leaves your phone.', font=small, fill=hex_rgba(GHOST_MUTE_INK))
    return img.convert('RGB').convert('RGBA')


def mask_points(kind, tile):
    """Polygon for a launcher mask filling a tile (in tile pixels)."""
    c = tile / 2
    if kind == 'circle':
        return circle(c, c, c * 0.999, n=240)
    if kind == 'squircle':
        n = 5.0
        r = c * 0.999
        pts = []
        for i in range(360):
            t = 2 * math.pi * i / 360
            cs, sn = math.cos(t), math.sin(t)
            x = r * math.copysign(abs(cs) ** (2 / n), cs)
            y = r * math.copysign(abs(sn) ** (2 / n), sn)
            pts.append((c + x, c + y))
        return pts
    # Approximate 4-lobed "cookie" mask.
    base = c * 0.88
    pts = []
    for i in range(360):
        t = 2 * math.pi * i / 360
        rr = base * (1 - 0.07 * math.cos(4 * t))
        pts.append((c + rr * math.cos(t), c + rr * math.sin(t)))
    return pts


def masked_tile(icon_img, kind, tile, fill):
    """Composites an icon (or a flat colour when icon_img is None) through a launcher mask."""
    big = tile * SS
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).polygon([(x * SS, y * SS) for x, y in mask_points(kind, tile)], fill=255)
    mask = mask.resize((tile, tile), Image.LANCZOS)
    base = Image.new('RGBA', (tile, tile), hex_rgba(fill))
    if icon_img is not None:
        base.alpha_composite(icon_img.resize((tile, tile), Image.LANCZOS))
    out = Image.new('RGBA', (tile, tile), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out


def masks_sheet():
    tile = 216
    small = 48
    gap = 40
    cols = ['circle', 'squircle', 'cookie', 'themed']
    width = gap + len(cols) * (tile + gap)
    height = gap + 2 * (tile + gap) + (small + gap) * 2 + 40
    sheet = Image.new('RGBA', (width, height), hex_rgba(WALL_LIGHT))
    big_icon = raster_visible(ghost_icon_layers(), tile)
    mono_dark = raster_visible(ghost_monochrome_layers(TONAL_INK), tile)
    mono_light = raster_visible(ghost_monochrome_layers(TONAL_LIGHT), tile)
    rows = [
        (gap, WALL_LIGHT, big_icon, mono_dark, TONAL_LIGHT, tile),
        (gap * 2 + tile, WALL_DARK, big_icon, mono_light, TONAL_INK, tile),
    ]
    for kind_idx, kind in enumerate(cols):
        x = gap + kind_idx * (tile + gap)
        for y, wall, icon, mono, tonal, _ in rows[:2]:
            if kind == 'themed':
                tile_img = masked_tile(mono, 'circle', tile, tonal)
            else:
                tile_img = masked_tile(icon, kind, tile, wall)
            sheet.alpha_composite(tile_img, (x, y))
    # 48 px actual size, each mask on the light and dark wallpaper.
    y48 = gap * 3 + 2 * tile
    icon48 = raster_visible(ghost_icon_layers(), small)
    for kind_idx, kind in enumerate(cols[:3]):
        x = gap + kind_idx * (tile + gap)
        sheet.alpha_composite(masked_tile(icon48, kind, small, WALL_LIGHT), (x, y48))
        sheet.alpha_composite(masked_tile(icon48, kind, small, WALL_DARK), (x, y48 + small + gap))
    sheet.alpha_composite(masked_tile(raster_visible(ghost_monochrome_layers(TONAL_INK), small), 'circle', small, TONAL_LIGHT),
                          (gap + 3 * (tile + gap), y48))
    return sheet.convert('RGB')


def main():
    # SVG sources.
    write_text('assets/brand/icon_background.svg', to_svg(ghost_background_layers(), 'BooBoard icon background'))
    write_text('assets/brand/icon_foreground.svg', to_svg(ghost_foreground_layers(), 'BooBoard icon foreground (ghost)'))
    write_text('assets/brand/icon_monochrome.svg', to_svg(ghost_monochrome_layers(), 'BooBoard themed (monochrome) icon'))
    write_text('assets/brand/booboard_icon.svg', to_svg(ghost_icon_layers(), 'BooBoard icon, full colour (ghost)'))
    for name, make in POSES.items():
        write_text(f'assets/brand/{name}.svg', to_svg(make(), f'BooBoard ghost pose: {name[5:]}'))
    if '--store-art' in sys.argv:
        write_text('docs/brand/screenshot_frame.svg', screenshot_frame_svg())

    # Android vector drawables.
    res = 'android/app/src/main/res/drawable'
    write_text(f'{res}/ic_launcher_foreground.xml',
               to_vector_drawable(ghost_foreground_layers(), 'BooBoard adaptive icon foreground (ghost)'))
    write_text(f'{res}/ic_launcher_monochrome.xml',
               to_vector_drawable(ghost_monochrome_layers(), 'BooBoard themed icon (Android 13+), eyes as negative space'))
    write_text(f'{res}/ic_launcher_background.xml',
               to_vector_drawable(ghost_background_layers(), 'BooBoard adaptive icon background (lime tile)'))
    write_text(f'{res}/splash_ghost.xml',
               to_vector_drawable(ghost_foreground_layers(), 'BooBoard splash ghost (SplashScreen API and launch background)'))

    # Legacy launcher PNGs (pre-Android 8 and fallback).
    for density, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)):
        save_png(raster_visible(ghost_icon_layers(), px),
                 f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')

    # Store art.
    save_png(raster_visible(ghost_icon_layers(), 512).convert('RGB').convert('RGBA'), 'docs/brand/play_icon_512.png')
    if '--store-art' in sys.argv:  # needs the brand fonts; see feature_graphic()
        save_png(feature_graphic().convert('RGB'), 'docs/brand/feature_graphic_1024x500.png')
    save_png(masks_sheet(), 'docs/brand/icon-masks.png')


if __name__ == '__main__':
    main()
