# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds the Indic data for one or more languages from:
#   * Aksharantar word pairs (AI4Bharat; CC0 and CC BY 4.0; see docs/notices/indic.md):
#       <data>/<iso3>/<iso3>_train.json, _valid.json, _test.json   (JSON lines; hin, mar, ben, tam, tel)
#   * Word counts from wiki_counts.py (Wikipedia, CC BY-SA 4.0): <counts>/<lang>.counts.tsv
#
# Outputs, per language:
#   <out-translit>/<lang>.bin   romanised -> native table, gzip-compressed (format below)
#   <out-combined>/<lang>.combined   word list for tool/indic/build_indic_dict.dart
#
#   python tool/indic/build_data.py --data <scratch>/aksharantar --counts <scratch>/counts \
#       --out-translit assets/translit --out-combined <scratch>/combined --langs hi,mr,bn,ta,te
#
# Transliteration table format (before gzip), little-endian:
#   magic "MYTL", u8 version (1), u32 entry count, then entries sorted by roman then score (desc):
#   u8 roman length, roman bytes (ASCII a-z), u8 native UTF-8 length, native UTF-8 bytes,
#   u8 score (0..255, log2 frequency of the native word times 12; 0 when unknown).
# Read by lib/src/engine/lang/indic/translit_table.dart.
#
# Frequency byte for words: f = min(255, round(log2(count) * 12)); build_indic_dict.dart maps it
# to a log-probability exactly as tool/build_dictionary.dart does.
import argparse
import gzip
import json
import math
import os
import re
import struct
import unicodedata

SCRIPTS = {
    "hi": (0x0900, 0x097F),
    "mr": (0x0900, 0x097F),
    "bn": (0x0980, 0x09FF),
    "ta": (0x0B80, 0x0BFF),
    "te": (0x0C00, 0x0C7F),
}
ROMAN = re.compile(r"^[a-z]+$")
# Aksharantar folders and file prefixes use ISO 639-2 codes (hin_train.json).
ISO3 = {"hi": "hin", "mr": "mar", "bn": "ben", "ta": "tam", "te": "tel"}

DICT_WORDS = 50000  # per language; keeps each .mdict under 1.5 MB
TABLE_ENTRIES = 100000  # per language; keeps each translit .bin.gz well under 1.5 MB
MIN_DICT_COUNT = 3


def is_native(word, lang):
    """A word of the language's script that starts with a letter (not a vowel sign or a digit)."""
    lo, hi = SCRIPTS[lang]
    if not word or len(word) > 40:
        return False
    for c in word:
        cp = ord(c)
        if lo <= cp <= hi:
            continue
        if cp in (0x200C, 0x200D):
            continue
        return False
    return unicodedata.category(word[0]) == "Lo"


# Roman keys that only ever spell a letter in the Latin alphabet ("c" for k, "f" for ph, ...). The
# inverse map prefers the first key in the scheme's order that is not one of these.
ALIAS_KEYS = {"c", "f", "w", "q", "z", "x"}
NUKTA = "\u093c"
ANUSVARA_ALT = "\u0901"
VISARGA = "\u0903"


def invert(scheme):
    """Canonical roman spelling for each native letter, from the scheme tables (the same letters as
    lib/src/engine/lang/indic/scheme.dart, exported by tool/indic/export_schemes.dart)."""
    cons_r = {}
    for roman, native in scheme["consonants"].items():
        if roman in ALIAS_KEYS and native in cons_r:
            continue
        cons_r.setdefault(native, roman)
    indep_r, sign_r = {}, {}
    for roman, (indep, sign) in scheme["vowels"].items():
        indep_r.setdefault(indep, roman)
        if sign:
            sign_r.setdefault(sign, roman)
    return cons_r, indep_r, sign_r


def to_roman(word, scheme, inverse):
    """Roman spelling of a native word. A bare word-final consonant drops its inherent vowel."""
    cons_r, indep_r, sign_r = inverse
    virama = scheme["virama"]
    out = []
    i = 0
    n = len(word)
    while i < n:
        c = word[i]
        if c in cons_r:
            roman = cons_r[c]
            i += 1
            while i < n and word[i] == NUKTA:
                i += 1
            nxt = word[i] if i < n else None
            if nxt == virama:
                out.append(roman)
                i += 1
            elif nxt is None:
                out.append(roman)
            elif nxt in sign_r:
                out.append(roman + sign_r[nxt])
                i += 1
            else:
                out.append(roman + "a")
        elif c in indep_r:
            out.append(indep_r[c])
            i += 1
        elif c in sign_r:
            out.append(sign_r[c])
            i += 1
        elif c == scheme.get("anusvara") or c == ANUSVARA_ALT:
            out.append("n")
            i += 1
        elif c == VISARGA:
            out.append("h")
            i += 1
        else:
            i += 1
    return "".join(out)


def load_counts(path):
    counts = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            word, _, n = line.rstrip("\n").partition("\t")
            if word and n.isdigit():
                counts[unicodedata.normalize("NFC", word)] = int(n)
    return counts


def freq_byte(count):
    if count <= 0:
        return 0
    return min(255, round(math.log2(count) * 12))


def load_pairs(data_dir, lang):
    pairs = []
    for split in ("train", "valid", "test"):
        code = ISO3[lang]
        path = os.path.join(data_dir, code, f"{code}_{split}.json")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                row = json.loads(line)
                native = unicodedata.normalize("NFC", row.get("native word", ""))
                roman = (row.get("english word") or "").strip().lower()
                if ROMAN.match(roman) and len(roman) <= 40:
                    pairs.append((roman, native))
    return pairs


def write_table(path, entries):
    """entries: list of (roman, native, score)."""
    buf = bytearray(b"MYTL")
    buf += bytes([1])
    buf += struct.pack("<I", len(entries))
    for roman, native, score in entries:
        r = roman.encode("ascii")
        n = native.encode("utf-8")
        buf += bytes([len(r)]) + r + bytes([len(n)]) + n + bytes([score])
    with gzip.open(path, "wb", compresslevel=9) as f:
        f.write(bytes(buf))


def write_combined(path, words):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for word, count in words:
            f.write(f"word={word},f={freq_byte(count)}\n")


def build(lang, data_dir, counts_dir, out_translit, out_combined, schemes):
    counts = load_counts(os.path.join(counts_dir, f"{lang}.counts.tsv"))
    pairs = load_pairs(data_dir, lang)
    scheme = schemes.get(lang)
    inverse = invert(scheme) if scheme else None

    best = {}
    for roman, native in pairs:
        if not is_native(native, lang):
            continue
        key = (roman, native)
        if key not in best:
            best[key] = counts.get(native, 0)
    # Canonical spellings of the frequent words (the inverse of the scheme), so common words such as
    # namaste or kya are in the table even when Aksharantar has no pair for them.
    if inverse:
        for native, c in counts.items():
            if c < MIN_DICT_COUNT or not is_native(native, lang):
                continue
            roman = to_roman(native, scheme, inverse)
            if ROMAN.match(roman) and len(roman) <= 40:
                best.setdefault((roman, native), c)
    # Keep the pairs whose native word is attested in Wikipedia; the rest are too rare to help.
    attested = [(k, c) for k, c in best.items() if c > 0]
    if len(attested) < TABLE_ENTRIES // 2:
        attested = list(best.items())
    attested.sort(key=lambda kc: (-kc[1], kc[0][0], kc[0][1]))
    chosen = attested[:TABLE_ENTRIES]
    entries = sorted(
        ((roman, native, freq_byte(c)) for (roman, native), c in chosen),
        key=lambda e: (e[0], -e[2], e[1]),
    )
    os.makedirs(out_translit, exist_ok=True)
    write_table(os.path.join(out_translit, f"{lang}.bin"), entries)

    words = [(w, c) for w, c in counts.items() if c >= MIN_DICT_COUNT and is_native(w, lang)]
    words.sort(key=lambda wc: (-wc[1], wc[0]))
    words = words[:DICT_WORDS]
    os.makedirs(out_combined, exist_ok=True)
    write_combined(os.path.join(out_combined, f"{lang}.combined"), words)

    size = os.path.getsize(os.path.join(out_translit, f"{lang}.bin"))
    print(
        f"{lang}: pairs {len(pairs)}, table {len(entries)} entries ({size} bytes gz), "
        f"dictionary {len(words)} words",
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", required=True)
    ap.add_argument("--counts", required=True)
    ap.add_argument("--out-translit", default="assets/translit")
    ap.add_argument("--out-combined", required=True)
    ap.add_argument("--langs", default="hi,mr,bn,ta,te")
    ap.add_argument("--schemes", required=True, help="JSON from tool/indic/export_schemes.dart")
    args = ap.parse_args()
    with open(args.schemes, encoding="utf-8") as f:
        schemes = json.load(f)
    for lang in args.langs.split(","):
        build(lang, args.data, args.counts, args.out_translit, args.out_combined, schemes)


if __name__ == "__main__":
    main()
