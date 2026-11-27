# SPDX-License-Identifier: GPL-3.0-or-later
"""Builds the README showcase images from raw emulator screenshots.

    python tool/brand/showcase.py

Input:  docs/showcase/raw/<name>.png   (1080 x 2400 screenshots, `adb shell screencap`)
Output: docs/showcase/<card>.png        (720 x 1280 cards: caption + framed screenshot)
        docs/showcase/hero.png          (1600 x 760 banner for the top of the README)

Colours and font follow the brand (docs/brand, the Aurora ghost): ghost tile #17141F, aurora violet #B57BFF
and blue #6E8BFF, white and lavender text, Google Sans Flex. "keyboard" crops keep the message box and the keyboard; "screen" crops drop the
status bar.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'docs' / 'showcase' / 'raw'
OUT = ROOT / 'docs' / 'showcase'
FONT = ROOT / 'assets' / 'fonts' / 'GoogleSansFlex.ttf'
ICON = ROOT / 'docs' / 'brand' / 'play_icon_512.png'

TILE = (23, 20, 31)          # #17141F, the icon tile
TILE_LIGHT = (40, 35, 54)
VIOLET = (181, 123, 255)     # aurora
BLUE = (110, 139, 255)
WHITE = (255, 255, 255)
LAVENDER = (232, 222, 248)

STATUS_BAR = 96       # px at the top of a 1080 x 2400 capture
KEYBOARD_TOP = 1360   # message box + keyboard


def font(size, weight=600):
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([weight if axis['name'] == b'Weight' else axis['default']
                                 for axis in f.get_variation_axes()])
    except (OSError, AttributeError):
        pass
    return f


def crop(name, kind):
    im = Image.open(RAW / f'{name}.png').convert('RGB')
    w, h = im.size
    if kind == 'keyboard':
        return im.crop((0, KEYBOARD_TOP, w, h))
    return im.crop((0, STATUS_BAR, w, h))


def rounded(im, radius):
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius, fill=255)
    out = im.convert('RGBA')
    out.putalpha(mask)
    return out


def paste_with_shadow(canvas, im, xy, radius):
    shadow = Image.new('RGBA', (im.width + 60, im.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((30, 36, im.width + 30, im.height + 36), radius, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(shadow, (xy[0] - 30, xy[1] - 30))
    canvas.alpha_composite(rounded(im, radius), xy)


def wrap(draw, text, fnt, width):
    lines, line = [], ''
    for word in text.split():
        trial = f'{line} {word}'.strip()
        if draw.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines


def card(out_name, raw_name, kind, title, subtitle):
    W, H = 720, (940 if kind == 'keyboard' else 1280)
    canvas = Image.new('RGBA', (W, H), TILE + (255,))
    draw = ImageDraw.Draw(canvas)
    ft, fs = font(50, 650), font(28, 420)
    y = 56
    for line in wrap(draw, title, ft, W - 96):
        draw.text((48, y), line, font=ft, fill=WHITE)
        y += 62
    y += 6
    for line in wrap(draw, subtitle, fs, W - 96):
        draw.text((48, y), line, font=fs, fill=LAVENDER)
        y += 38
    y += 30
    shot = crop(raw_name, kind)
    box_w, box_h = W - 96, H - y - 48
    scale = min(box_w / shot.width, box_h / shot.height)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    x = (W - shot.width) // 2
    paste_with_shadow(canvas, shot, (x, y), 28)
    canvas.convert('RGB').save(OUT / f'{out_name}.png', optimize=True)


def hero(raw_names):
    W, H = 1600, 760
    canvas = Image.new('RGBA', (W, H), TILE + (255,))
    draw = ImageDraw.Draw(canvas)
    # soft aurora glow behind the phones
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((860, 80, 1560, 820), fill=VIOLET + (70,))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))
    icon = Image.open(ICON).convert('RGBA').resize((120, 120), Image.LANCZOS)
    canvas.alpha_composite(rounded(icon, 28), (80, 110))
    draw.text((80, 250), 'BooBoard', font=font(100, 700), fill=WHITE)
    y = 384
    for line in ('The keyboard that cannot phone home.', 'No internet permission.', 'Everything stays on your phone.'):
        draw.text((84, y), line, font=font(36, 430), fill=LAVENDER)
        y += 48
    chips = ['18 languages', 'Swipe', 'Offline voice', 'Offline translate', 'Encrypted', 'GPL-3.0']
    x, y = 84, 572
    fc = font(28, 560)
    for c in chips:
        tw = draw.textlength(c, font=fc)
        if x + tw + 40 > 820:
            x, y = 84, y + 62
        draw.rounded_rectangle((x, y, x + tw + 40, y + 48), 24, fill=TILE_LIGHT, outline=BLUE, width=2)
        draw.text((x + 20, y + 8), c, font=fc, fill=WHITE)
        x += tw + 56
    # three phones, the middle one raised
    xs, ys = (960, 1170, 1380), (140, 60, 140)
    for i, name in enumerate(raw_names):
        shot = crop(name, 'screen')
        shot = shot.resize((200, int(200 * shot.height / shot.width)), Image.LANCZOS)
        paste_with_shadow(canvas, shot, (xs[i] - 20, ys[i]), 22)
    canvas.convert('RGB').save(OUT / 'hero.png', optimize=True)


CARDS = [
    # out name, raw name, crop, title, subtitle
    ('01-no-internet', 'onboarding-3', 'screen', 'It cannot phone home',
     'No internet permission at all. CI fails the build if one ever appears.'),
    ('02-swipe', 'kb-suggest', 'keyboard', 'Type, swipe, predict',
     'Autocorrect, next-word prediction and gesture typing, all on the device.'),
    ('03-toolbar', 'kb-gold-dark', 'keyboard', 'Everything one tap away',
     'Emoji, clipboard, text editing, one-handed, voice, translate, themes.'),
    ('04-hindi', 'lang-hindi', 'keyboard', 'Type Hindi in English letters',
     'Type "namaste", get the Devanagari word. Marathi, Bengali, Tamil and Telugu too.'),
    ('05-chinese', 'lang-chinese', 'keyboard', 'Chinese pinyin',
     'Type "nihao", pick the characters. Offline dictionary pack.'),
    ('06-japanese', 'lang-japanese', 'keyboard', 'Japanese flick input',
     '12-key flick with kana-kanji conversion, fully offline.'),
    ('07-arabic', 'lang-arabic', 'keyboard', 'Right-to-left done right',
     'Arabic and Urdu layouts with their own suggestions.'),
    ('08-russian', 'lang-russian', 'keyboard', '18 languages',
     'English, Spanish, French, German, Portuguese, Indonesian, Filipino, Russian and more.'),
    ('09-voice', 'voice', 'keyboard', 'Voice typing, on-device',
     'Whisper runs on your phone. Audio is never saved and never sent.'),
    ('10-translate', 'translate', 'keyboard', 'Translate as you type',
     'Offline translation packs. Nothing leaves the phone.'),
    ('11-emoji', 'panel-emoji-search', 'keyboard', 'Emoji search',
     'Keywords in all 18 languages.'),
    ('12-clipboard', 'panel-clipboard', 'keyboard', 'Clipboard history',
     'Encrypted, with pins. Turn it off any time.'),
    ('13-editing', 'panel-editing', 'keyboard', 'Text editing pad',
     'Select, cut, copy, paste, undo and move the cursor.'),
    ('14-one-handed', 'mode-onehanded', 'keyboard', 'One-handed mode',
     'Left, right or floating. Resize the height too.'),
    ('15-themes', 'theme-editor', 'screen', 'Material You themes',
     'Follow your wallpaper, or build your own theme.'),
    ('16-languages', 'languages', 'screen', 'Pick your languages',
     'Several at once. Switch with one key.'),
    ('17-privacy', 'privacy', 'screen', 'See what is stored',
     'Sizes only, never contents. Encrypted with a key in Android Keystore.'),
    ('18-incognito', 'privacy-2', 'screen', 'Incognito and hidden',
     'Learns nothing in incognito, blocks screenshots of the keyboard.'),
    ('19-packs', 'packs', 'screen', 'Signed data packs',
     'Voice, translation and dictionaries are checked before install. Data only, never code.'),
    ('20-app-lock', 'privacy-3', 'screen', 'App lock and shortcuts',
     'Fingerprint or PIN for settings, personal shortcuts, learned-word review.'),
]

if __name__ == '__main__':
    for args in CARDS:
        card(*args)
    hero(['onboarding-3', 'lang-hindi', 'lang-japanese'])
    print(f'{len(CARDS)} cards and hero.png written to {OUT}')
