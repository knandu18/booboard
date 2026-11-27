#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Writes the European keyboard layouts (assets/layouts/qwerty_es.json, azerty.json, qwertz.json,
# qwertz_umlaut.json, jcuken_ru.json, jcuken_uk.json) from the shared rows of qwerty.json.
#
#   python tool/european/make_layouts.py
#
# Rows keep their physical left-to-right order. Every layout has the digits 1-0 as hints on the
# top row (popups too), like qwerty.json. Output is UTF-8 with LF line endings.
import copy
import json
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
LAYOUTS = os.path.join(ROOT, 'assets', 'layouts')
DIGITS = '1234567890'


def load_qwerty():
    with open(os.path.join(LAYOUTS, 'qwerty.json'), encoding='utf-8') as f:
        return json.load(f)


def letter(ch, popup=None, hint=None, width=None):
    key = {'output': ch}
    if hint is not None:
        key['hint'] = hint
    if popup:
        key['popup'] = list(popup)
    if width is not None and width != 1:
        key['width'] = width
    return key


def top_row(letters, popups=None, width=None):
    """Top letter row: the digits 1-0 as hints and popups, first ten keys only."""
    popups = popups or {}
    keys = []
    for i, ch in enumerate(letters):
        hint = DIGITS[i] if i < len(DIGITS) else None
        extra = list(popups.get(ch, []))
        popup = ([DIGITS[i]] if hint else []) + extra
        keys.append(letter(ch, popup, hint, width))
    return {'keys': keys}


def plain_row(letters, popups=None, padding=0.0, width=None):
    popups = popups or {}
    keys = [letter(ch, popups.get(ch), None, width) for ch in letters]
    row = {'keys': keys}
    if padding:
        row['padding'] = padding
    return row


def bottom_row(period_popup):
    """The bottom row of qwerty.json with its own period popup."""
    q = load_qwerty()
    row = copy.deepcopy(q['rows'][3])
    for key in row['keys']:
        if key.get('type') == 'period':
            key['popup'] = period_popup
    return row


def shift_row(letters, shift_width=1.5, back_width=1.5, popups=None, letter_width=1.0):
    popups = popups or {}
    keys = [{'type': 'shift', 'width': shift_width}]
    keys += [letter(ch, popups.get(ch), None, letter_width if letter_width != 1.0 else None) for ch in letters]
    keys.append({'type': 'backspace', 'width': back_width})
    return {'keys': keys}


def write(layout_id, name, script, rows):
    doc = {'id': layout_id, 'name': name, 'script': script, 'direction': 'ltr', 'rows': rows}
    path = os.path.join(LAYOUTS, layout_id + '.json')
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print('wrote', path)


PUNCT_EN = [',', '?', '!', "'", '"', ':', ';', '-', '(', ')', '@', '#']


def main():
    q = load_qwerty()
    qwerty_bottom = copy.deepcopy(q['rows'][3])

    # Spanish: Ñ after L. Row 2 shrinks to 10 keys of 0.95 (never below 0.9).
    es_rows = copy.deepcopy(q['rows'][:3])
    es_rows[1] = {
        'padding': 0.25,
        'keys': [
            letter('a', ['á', 'à', 'ä', 'â', 'ã', 'å', 'ā'], None, 0.95),
            letter('s', ['ß', 'ś', 'š'], None, 0.95),
            letter('d', None, None, 0.95),
            letter('f', None, None, 0.95),
            letter('g', None, None, 0.95),
            letter('h', None, None, 0.95),
            letter('j', None, None, 0.95),
            letter('k', None, None, 0.95),
            letter('l', None, None, 0.95),
            letter('ñ', None, None, 0.95),
        ],
    }
    es_rows[2] = copy.deepcopy(q['rows'][2])
    for key in es_rows[2]['keys']:
        if isinstance(key, dict) and key.get('output') == 'n':
            key['popup'] = []
    es_rows.append(bottom_row([',', '?', '¿', '!', '¡', "'", '"', ':', ';', '-', '(', ')', '@', '#']))
    write('qwerty_es', 'QWERTY (Ñ)', 'Latn', es_rows)

    # French AZERTY: the accent popups first, the apostrophe as its own key in row 3.
    az_popups = {
        'a': ['à', 'â', 'æ'],
        'e': ['é', 'è', 'ê', 'ë'],
        'i': ['î', 'ï'],
        'o': ['ô', 'œ', 'ö'],
        'u': ['ù', 'û', 'ü'],
        'c': ['ç'],
    }
    az_rows = [
        top_row(list('azertyuiop'), az_popups),
        plain_row(list('qsdfghjklm'), {'s': ['ß']}),
        {
            'keys': [
                {'type': 'shift', 'width': 1.5},
                letter('w'),
                letter('x'),
                letter('c', ['ç']),
                letter('v'),
                letter('b'),
                letter('n'),
                {'output': "'", 'popup': ['’', '‘', '"']},
                {'type': 'backspace', 'width': 1.5},
            ]
        },
        bottom_row([',', '?', '!', ':', ';', "'", '"', '-', '(', ')', '@', '#']),
    ]
    write('azerty', 'AZERTY', 'Latn', az_rows)

    # German QWERTZ: Z and Y swapped; umlauts on the popups of a, o, u and ß on s.
    dz_popups = {
        'a': ['ä', 'á', 'à', 'â', 'å', 'ā', 'æ'],
        'o': ['ö', 'ó', 'ò', 'ô', 'õ', 'ø', 'ō', 'œ'],
        'u': ['ü', 'ú', 'ù', 'û', 'ū'],
        's': ['ß', 'ś', 'š'],
        'z': ['ž', 'ź', 'ż'],
    }
    dz_rows = [
        top_row(list('qwertzuiop'), dz_popups),
        plain_row(list('asdfghjkl'), dz_popups, padding=0.5),
        shift_row(list('yxcvbnm'), popups={'m': []}),
        bottom_row(PUNCT_EN),
    ]
    write('qwertz', 'QWERTZ', 'Latn', dz_rows)

    # QWERTZ with the umlauts as keys: rows of 11 keys at 0.9 units, so the rows still fit the width.
    uz_row1 = top_row(list('qwertzuiop') + ['ü'], dz_popups, width=0.9)
    uz_row1['keys'][10]['popup'] = ['ü', 'ú', 'ù', 'û', 'ū']
    uz_row1['keys'][10]['output'] = 'ü'
    # The engine counts padding on both sides: 11 x 0.9 + 2 x 0.05 = 10.0 units, as wide as the bottom rows.
    uz_row2 = plain_row(list('asdfghjkl') + ['ö', 'ä'], {'a': ['á', 'à', 'â', 'å', 'ā', 'æ'], 's': ['ß', 'ś', 'š']}, padding=0.05, width=0.9)
    uz_rows = [uz_row1, uz_row2, shift_row(list('yxcvbnm'), popups={'m': []}), bottom_row(PUNCT_EN)]
    write('qwertz_umlaut', 'QWERTZ (ÄÖÜ keys)', 'Latn', uz_rows)

    # Russian ЙЦУКЕН: 11 letters per top row, ъ on the popup of ь, ё on the popup of е.
    ru_popups = {'е': ['ё'], 'ь': ['ъ']}
    ru_rows = [
        top_row(list('йцукенгшщзх'), ru_popups),
        plain_row(list('фывапролджэ')),
        shift_row(list('ячсмитьбю'), shift_width=1.25, back_width=1.25, popups=ru_popups, letter_width=0.94),
        bottom_row(['.', ',', '«', '»', '!', '?', ':', ';', '-', '(', ')', '—', '…']),
    ]
    write('jcuken_ru', 'ЙЦУКЕН', 'Cyrl', ru_rows)

    # Ukrainian: і/ї, є and ґ with the apostrophe ʼ on the popup of ь.
    uk_popups = {'і': ['ї'], 'г': ['ґ'], 'ь': ['ʼ']}
    uk_rows = [
        top_row(list('йцукенгшщзх'), uk_popups),
        plain_row(list('фівапролджє'), uk_popups),
        shift_row(list('ячсмитьбю'), shift_width=1.25, back_width=1.25, popups=uk_popups, letter_width=0.94),
        bottom_row(['.', ',', '«', '»', '!', '?', ':', ';', '-', '(', ')', '—', '…', 'ʼ']),
    ]
    write('jcuken_uk', 'ЙЦУКЕН', 'Cyrl', uk_rows)


if __name__ == '__main__':
    main()
