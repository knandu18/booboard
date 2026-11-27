# SPDX-License-Identifier: GPL-3.0-or-later
#
# Writes the Indic keyboard layouts: assets/layouts/{translit,phonetic}_<lang>.json.
# The InScript layouts come from tool/indic/make_inscript.dart (BIS key tables) since Wave 4.
#
#   python tool/indic/make_layouts.py [--out assets/layouts]
#
# * translit_<lang>: QWERTY (from assets/layouts/qwerty.json, ASCII popups only), for English-letter typing.
# * phonetic_<lang>: native letters placed by sound (k near क, s near स), vowel signs on the top row.
# * inscript_<lang>: the InScript (BIS) letter order: the same letters as Devanagari InScript, mapped
#   to each script by role (the "common layout for all Indian scripts" of InScript). Letters a script
#   lacks are left out; letters that do not fit on the keys go into the popups.
#
# Every letter key uses "output" (unshifted) and "shiftedOutput" (shift layer = the second letter set).
# Long-press on the virama key gives ZWNJ and ZWJ. The danda and double danda are on the period key
# for Hindi, Marathi and Bengali. Digits are not built in (the orchestrator's native-digits variant).
import argparse
import copy
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# role -> glyph, per script. Roles are shared; a missing role means the script has no such letter.
ROLES = {
    "Deva": {
        "a_i": "अ", "aa_i": "आ", "i_i": "इ", "ii_i": "ई", "u_i": "उ", "uu_i": "ऊ", "ri_i": "ऋ",
        "e_i": "ए", "ai_i": "ऐ", "o_i": "ओ", "au_i": "औ",
        "aa_m": "ा", "i_m": "ि", "ii_m": "ी", "u_m": "ु", "uu_m": "ू", "e_m": "े", "ai_m": "ै",
        "o_m": "ो", "au_m": "ौ", "cand_o": "ॉ", "cand_e": "ॅ",
        "ka": "क", "kha": "ख", "ga": "ग", "gha": "घ", "nga": "ङ", "ca": "च", "cha": "छ", "ja": "ज",
        "jha": "झ", "nya": "ञ", "tta": "ट", "ttha": "ठ", "dda": "ड", "ddha": "ढ", "nna": "ण", "ta": "त",
        "tha": "थ", "da": "द", "dha": "ध", "na": "न", "pa": "प", "pha": "फ", "ba": "ब", "bha": "भ",
        "ma": "म", "ya": "य", "ra": "र", "rra": "ड़", "la": "ल", "lla": "ळ", "va": "व", "sha": "श",
        "ssa": "ष", "sa": "स", "ha": "ह", "fa": "फ़", "ksha": "क्ष", "jna": "ज्ञ", "zha": None,
        "nra": None,
        "virama": "्", "anusvara": "ं", "candrabindu": "ँ", "visarga": "ः", "nukta": "़",
        "avagraha": "ऽ", "danda": "।", "double_danda": "॥",
    },
    "Beng": {
        "a_i": "অ", "aa_i": "আ", "i_i": "ই", "ii_i": "ঈ", "u_i": "উ", "uu_i": "ঊ", "ri_i": "ঋ",
        "e_i": "এ", "ai_i": "ঐ", "o_i": "ও", "au_i": "ঔ",
        "aa_m": "া", "i_m": "ি", "ii_m": "ী", "u_m": "ু", "uu_m": "ূ", "e_m": "ে", "ai_m": "ৈ",
        "o_m": "ো", "au_m": "ৌ",
        "ka": "ক", "kha": "খ", "ga": "গ", "gha": "ঘ", "nga": "ঙ", "ca": "চ", "cha": "ছ", "ja": "জ",
        "jha": "ঝ", "nya": "ঞ", "tta": "ট", "ttha": "ঠ", "dda": "ড", "ddha": "ঢ", "nna": "ণ", "ta": "ত",
        "tha": "থ", "da": "দ", "dha": "ধ", "na": "ন", "pa": "প", "pha": "ফ", "ba": "ব", "bha": "ভ",
        "ma": "ম", "ya": "য", "ra": "র", "rra": "ড়", "la": "ল", "va": "ভ", "sha": "শ", "ssa": "ষ",
        "sa": "স", "ha": "হ", "fa": "ফ", "ksha": "ক্ষ", "jna": "জ্ঞ", "yya": "য়", "zha": None,
        "nra": None,
        "virama": "্", "anusvara": "ং", "candrabindu": "ঁ", "visarga": "ঃ", "nukta": "়",
        "avagraha": "ঽ", "danda": "।", "double_danda": "॥",
    },
    "Taml": {
        "a_i": "அ", "aa_i": "ஆ", "i_i": "இ", "ii_i": "ஈ", "u_i": "உ", "uu_i": "ஊ",
        "e_i": "எ", "ee_i": "ஏ", "ai_i": "ஐ", "o_i": "ஒ", "oo_i": "ஓ", "au_i": "ஔ",
        "aa_m": "ா", "i_m": "ி", "ii_m": "ீ", "u_m": "ு", "uu_m": "ூ", "e_m": "ெ", "ee_m": "ே",
        "ai_m": "ை", "o_m": "ொ", "oo_m": "ோ", "au_m": "ௌ",
        "ka": "க", "nga": "ங", "ca": "ச", "cha": "ச", "ja": "ஜ", "nya": "ஞ", "tta": "ட", "nna": "ண",
        "ta": "த", "da": "த", "na": "ந", "pa": "ப", "ba": "ப", "ma": "ம", "ya": "ய", "ra": "ர",
        "rra": "ற", "la": "ல", "lla": "ள", "zha": "ழ", "nra": "ன", "va": "வ", "sha": "ஷ", "sa": "ஸ",
        "ha": "ஹ", "fa": "ப", "ksha": "க்ஷ",
        "virama": "்", "anusvara": "ஂ", "danda": None, "double_danda": None,
    },
    "Telu": {
        "a_i": "అ", "aa_i": "ఆ", "i_i": "ఇ", "ii_i": "ఈ", "u_i": "ఉ", "uu_i": "ఊ", "ri_i": "ఋ",
        "e_i": "ఎ", "ee_i": "ఏ", "ai_i": "ఐ", "o_i": "ఒ", "oo_i": "ఓ", "au_i": "ఔ",
        "aa_m": "ా", "i_m": "ి", "ii_m": "ీ", "u_m": "ు", "uu_m": "ూ", "ri_m": "ృ", "e_m": "ె",
        "ee_m": "ే", "ai_m": "ై", "o_m": "ొ", "oo_m": "ో", "au_m": "ౌ",
        "ka": "క", "kha": "ఖ", "ga": "గ", "gha": "ఘ", "nga": "ఙ", "ca": "చ", "cha": "ఛ", "ja": "జ",
        "jha": "ఝ", "nya": "ఞ", "tta": "ట", "ttha": "ఠ", "dda": "డ", "ddha": "ఢ", "nna": "ణ", "ta": "త",
        "tha": "థ", "da": "ద", "dha": "ధ", "na": "న", "pa": "ప", "pha": "ఫ", "ba": "బ", "bha": "భ",
        "ma": "మ", "ya": "య", "ra": "ర", "rra": "ఱ", "la": "ల", "lla": "ళ", "va": "వ", "sha": "శ",
        "ssa": "ష", "sa": "స", "ha": "హ", "fa": "ఫ", "ksha": "క్ష", "jna": "జ్ఞ",
        "virama": "్", "anusvara": "ం", "candrabindu": "ఁ", "visarga": "ః", "avagraha": "ఽ",
        "danda": "।", "double_danda": "॥",
    },
}

# Which script and role table each language uses.
LANGS = {"hi": "Deva", "mr": "Deva", "bn": "Beng", "ta": "Taml", "te": "Telu"}
# Hindi, Marathi and Bengali use the danda on the period key.
DANDA_LANGS = {"hi", "mr", "bn"}

# The letter keys, in rows. Each entry: key -> (base role, shifted role).
INSCRIPT_ROWS = [
    [("Q", "au_m", "au_i"), ("W", "ai_m", "ai_i"), ("E", "aa_m", "aa_i"), ("R", "ii_m", "ii_i"),
     ("T", "uu_m", "uu_i"), ("Y", "ba", "bha"), ("U", "ha", "nga"), ("I", "ga", "gha"),
     ("O", "da", "dha"), ("P", "ja", "jha")],
    [("A", "o_m", "o_i"), ("S", "e_m", "e_i"), ("D", "virama", "avagraha"), ("F", "i_m", "i_i"),
     ("G", "u_m", "u_i"), ("H", "pa", "pha"), ("J", "ra", "rra"), ("K", "ka", "kha"), ("L", "ta", "tha")],
    [("Z", "anusvara", "candrabindu"), ("X", "visarga", "ri_i"), ("C", "ma", "ksha"), ("V", "va", "jna"),
     ("B", "la", "lla"), ("N", "na", "nna"), ("M", "sa", "ssa")],
]

PHONETIC_ROWS = [
    [("q", "au_m", "au_i"), ("w", "ai_m", "ai_i"), ("e", "aa_m", "aa_i"), ("r", "ra", "rra"),
     ("t", "ta", "tta"), ("y", "ya", "nya"), ("u", "u_m", "u_i"), ("i", "i_m", "i_i"), ("o", "o_m", "o_i"),
     ("p", "pa", "pha")],
    [("a", "anusvara", "candrabindu"), ("s", "sa", "sha"), ("d", "da", "dda"), ("f", "fa", None),
     ("g", "ga", "gha"), ("h", "ha", "visarga"), ("j", "ja", "jha"), ("k", "ka", "kha"), ("l", "la", "lla")],
    [("z", "nukta", "avagraha"), ("x", "virama", None), ("c", "ca", "cha"), ("v", "va", "nga"),
     ("b", "ba", "bha"), ("n", "na", "nna"), ("m", "ma", "ksha")],
]

# Popups that always carry the mark keys on the phonetic and InScript layouts.
ZWNJ, ZWJ = "‌", "‍"


def glyph(table, role):
    return table.get(role) if role else None


def build_native(kind, lang, script, rows, base_json):
    """A native-script layout: letter rows from [(key, base role, shifted role)], then the QWERTY
    bottom row. The virama key's long-press gives ZWNJ and ZWJ; unplaced glyphs go into popups."""
    table = ROLES[script]
    placed = set()
    key_popups = {}
    virama_key = None
    order = []
    base_of = {}
    for row in rows:
        for key_name, base_role, shift_role in row:
            order.append(key_name)
            base_of[key_name] = base_role
            key_popups[key_name] = []
            if glyph(table, base_role):
                placed.add(base_role)
            if glyph(table, shift_role):
                placed.add(shift_role)
            if base_role == "virama":
                virama_key = key_name

    # Glyphs the script has that do not fit on a key yet go round-robin into the popups.
    extras = [r for r, g in table.items() if g and r not in placed and r not in ("danda", "double_danda")]
    # Only keys that type something can carry popups: a script without the letter leaves its key out.
    spread = [k for k in order if k != virama_key and glyph(table, base_of[k])]
    for i, role in enumerate(extras):
        key_popups[spread[i % len(spread)]].append(table[role])
    if virama_key:
        key_popups[virama_key] = [ZWNJ, ZWJ] + key_popups[virama_key]

    def letter(key_name, base_role, shift_role):
        base = glyph(table, base_role)
        shifted = glyph(table, shift_role)
        if base is None:
            # The script has no base letter here: the shifted letter takes the key.
            if shifted is None:
                return None
            base, shifted = shifted, None
        key = {"output": base}
        if shifted:
            key["shiftedOutput"] = shifted
        if key_popups[key_name]:
            key["popup"] = list(key_popups[key_name])
        return key

    rows_json = []
    for idx, row in enumerate(rows):
        keys = [k for k in (letter(*entry) for entry in row) if k is not None]
        if idx == len(rows) - 1:
            # The last letter row carries shift and backspace, as in QWERTY.
            keys = [{"type": "shift", "width": 1.5}, *keys, {"type": "backspace", "width": 1.5}]
        row_json = {"keys": keys}
        if idx == 1:
            row_json["padding"] = 0.5
        rows_json.append(row_json)
    rows_json.append(copy.deepcopy(base_json["rows"][-1]))

    if lang in DANDA_LANGS and table.get("danda"):
        period = rows_json[-1]["keys"][4]
        marks = [table["danda"]] + ([table["double_danda"]] if table.get("double_danda") else [])
        period["popup"] = marks + period.get("popup", [])
    return {
        "id": f"{kind}_{lang}",
        "name": kind_name(kind),
        "script": script,
        "direction": "ltr",
        "rows": rows_json,
    }


def kind_name(kind):
    return {"phonetic": "Phonetic", "inscript": "InScript", "translit": "English letters"}[kind]


def qwerty_base():
    with open(os.path.join(ROOT, "assets", "layouts", "qwerty.json"), encoding="utf-8") as f:
        return json.load(f)


def build_translit(lang, base):
    out = copy.deepcopy(base)
    out["id"] = f"translit_{lang}"
    out["name"] = "English letters"
    out["script"] = "Latn"
    for row in out["rows"]:
        for key in row["keys"]:
            if isinstance(key, dict) and "popup" in key:
                key["popup"] = [p for p in key["popup"] if p.isascii()]
                if not key["popup"]:
                    del key["popup"]
    # The period popup gets the native danda for the Hindi-type languages.
    if lang in DANDA_LANGS:
        period = out["rows"][-1]["keys"][4]
        period["popup"] = ["।", "॥"] + [p for p in period.get("popup", []) if p.isascii()]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "layouts"))
    args = ap.parse_args()
    base = qwerty_base()
    os.makedirs(args.out, exist_ok=True)
    for lang, script in LANGS.items():
        layouts = {
            f"translit_{lang}": build_translit(lang, base),
            f"phonetic_{lang}": build_native("phonetic", lang, script, PHONETIC_ROWS, base),
        }
        for name, layout in layouts.items():
            path = os.path.join(args.out, name + ".json")
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                json.dump(layout, f, ensure_ascii=False, indent=1)
                f.write("\n")
            print("wrote", path)


if __name__ == "__main__":
    main()
