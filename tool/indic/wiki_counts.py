# SPDX-License-Identifier: GPL-3.0-or-later
#
# Word frequencies for the Indic dictionaries, from a Wikipedia articles dump (CC BY-SA 4.0).
#
#   python tool/indic/wiki_counts.py --dump hiwiki-latest-pages-articles.xml.bz2 --lang hi \
#       --out <scratch>/hi.counts.tsv [--top 200000] [--min-count 3]
#
# Streams the bz2 dump (stdlib only), keeps main-namespace articles (no redirects), strips the
# wiki markup roughly, and counts runs of the language's script. Writes "word<TAB>count", most
# frequent first. Digits, punctuation and Latin text are not counted.
#
# Run it once per language; the outputs feed tool/indic/build_indic.dart.
import argparse
import bz2
import collections
import re
import sys

# Script ranges (inclusive code points) per language.
SCRIPTS = {
    "hi": [(0x0900, 0x097F)],
    "mr": [(0x0900, 0x097F)],
    "bn": [(0x0980, 0x09FF)],
    "ta": [(0x0B80, 0x0BFF)],
    "te": [(0x0C00, 0x0C7F)],
}

# Digits and punctuation inside the script blocks; they never end or form a word.
EXCLUDE = {
    "hi": set(range(0x0966, 0x0970)) | {0x0964, 0x0965, 0x0970, 0x093D},
    "mr": set(range(0x0966, 0x0970)) | {0x0964, 0x0965, 0x0970, 0x093D},
    "bn": set(range(0x09E6, 0x09F0)) | {0x0964, 0x0965, 0x09FD, 0x09F2, 0x09F3, 0x09FA, 0x09FB},
    "ta": set(range(0x0BE6, 0x0BF3)) | {0x0BF3, 0x0BF4, 0x0BF5, 0x0BF6, 0x0BF7, 0x0BF8, 0x0BFA},
    "te": set(range(0x0C66, 0x0C70)) | {0x0C77, 0x0C78, 0x0C79, 0x0C7A, 0x0C7B, 0x0C7C, 0x0C7D, 0x0C7E, 0x0C7F},
}

# Vowel signs and viramas can not start a word; a word must start with a letter.
ZWJ_ZWNJ = {0x200C, 0x200D}

TEMPLATE = re.compile(r"\{\{[^{}]*\}\}")
REF = re.compile(r"<ref[^>]*?(/>|>.*?</ref>)", re.S)
COMMENT = re.compile(r"<!--.*?-->", re.S)
FILE_LINK = re.compile(r"\[\[(?:File|Image|Category|वर्ग|चित्र|फ़ाइल|वर्ग:|ਫ਼ਾਈਲ):[^\]]*\]\]", re.I)
LINK_ALIAS = re.compile(r"\[\[(?:[^\[\]|]*\|)?([^\[\]]*)\]\]")
EXT_LINK = re.compile(r"\[https?://[^\s\]]*\s?([^\]]*)\]")
HTML_TAG = re.compile(r"</?[a-zA-Z][^>]*>")
MARKUP = re.compile(r"'{2,}|={2,}|\{\||\|\}|^\s*[*#:;|!].*$", re.M)


def strip_markup(text):
    text = COMMENT.sub(" ", text)
    text = REF.sub(" ", text)
    for _ in range(4):  # templates nest; strip inside-out
        new = TEMPLATE.sub(" ", text)
        if new == text:
            break
        text = new
    text = FILE_LINK.sub(" ", text)
    text = LINK_ALIAS.sub(r"\1", text)
    text = EXT_LINK.sub(r"\1", text)
    text = HTML_TAG.sub(" ", text)
    text = MARKUP.sub(" ", text)
    return text


def script_tokens(text, lang):
    ranges = SCRIPTS[lang]
    exclude = EXCLUDE[lang]
    buf = []
    for ch in text:
        cp = ord(ch)
        ok = any(lo <= cp <= hi for lo, hi in ranges) and cp not in exclude
        if ok or (cp in ZWJ_ZWNJ and buf):
            buf.append(ch)
        else:
            if buf:
                yield "".join(buf)
                buf = []
    if buf:
        yield "".join(buf)


def clean_word(token):
    # Trim joiners and marks at the edges; a word starts with a letter, not a sign.
    word = token.strip("‌‍")
    if not word:
        return None
    lo, hi = SCRIPTS[LANG_FOR_CLEAN][0]
    if not (lo <= ord(word[0]) <= hi):
        return None
    return word


LANG_FOR_CLEAN = "hi"


def pages(stream):
    """Yields (namespace, text) for each <page> in a MediaWiki XML dump."""
    ns = None
    in_text = False
    parts = []
    for line in stream:
        if not in_text:
            if "<ns>" in line:
                m = re.search(r"<ns>(\d+)</ns>", line)
                if m:
                    ns = m.group(1)
            if "<text" in line:
                in_text = True
                head = line.split("<text", 1)[1]
                head = head.split(">", 1)[1] if ">" in head else ""
                parts = [head]
                if "</text>" in head:
                    in_text = False
                    yield ns, parts[0].rsplit("</text>", 1)[0]
                    parts = []
        else:
            if "</text>" in line:
                parts.append(line.split("</text>", 1)[0])
                in_text = False
                yield ns, "".join(parts)
                parts = []
            else:
                parts.append(line)


def main():
    global LANG_FOR_CLEAN
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dump", required=True)
    ap.add_argument("--lang", required=True, choices=sorted(SCRIPTS))
    ap.add_argument("--out", required=True)
    ap.add_argument("--top", type=int, default=200000)
    ap.add_argument("--min-count", type=int, default=3)
    args = ap.parse_args()
    LANG_FOR_CLEAN = args.lang

    counts = collections.Counter()
    articles = 0
    with bz2.open(args.dump, "rt", encoding="utf-8", errors="replace") as f:
        for ns, text in pages(f):
            if ns != "0" or text.lstrip().upper().startswith("#REDIRECT"):
                continue
            articles += 1
            for token in script_tokens(strip_markup(text), args.lang):
                word = clean_word(token)
                if word is not None and len(word) <= 40:
                    counts[word] += 1
    kept = [(w, c) for w, c in counts.most_common(args.top) if c >= args.min_count]
    with open(args.out, "w", encoding="utf-8", newline="\n") as out:
        for w, c in kept:
            out.write(f"{w}\t{c}\n")
    print(f"{args.lang}: {articles} articles, {len(counts)} distinct tokens, wrote {len(kept)} words to {args.out}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
