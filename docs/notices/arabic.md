# Arabic and Urdu data notices (Wave 3-C)

Data shipped in `assets/dict/ar.mdict` and `assets/dict/ur.mdict`, and the layouts
`assets/layouts/arabic.json` and `assets/layouts/urdu_phonetic.json` (written by us, no third-party data).

## ar: Arabic word list

- **Shipped:** `assets/dict/ar.mdict` (80,000 words in the converter, 76,436 after the builder's filter; 46,424 bigrams; 1.40 MB).
- **Source:** HeliBoard's `main_ar__experimental.combined` (next-word data included).
  - URL: https://codeberg.org/Helium314/aosp-dictionaries/raw/branch/main/wordlists/main_ar__experimental.combined
  - Source note: https://codeberg.org/Helium314/aosp-dictionaries/raw/branch/main/wordlists/main_ar__experimental.source
  - Downloaded 2026-11-22.
  - Licence as stated by that source note: "source lists under CC BY 4.0". The lists are derived from the
    Leipzig Corpora Collection (https://wortschatz.uni-leipzig.de/en/download). The Leipzig site could not be
    read from this machine (bot protection), so its licence text was **not checked directly**: verify before release.
- **Not used:** `main_ar.combined` (WikiAndOpenSubtitles). Its OpenSubtitles part has no clear licence.
- **Attribution (CC BY 4.0):** word frequencies and bigrams derived from the Leipzig Corpora Collection, via HeliBoard
  (Helium314 and contributors) aosp-dictionaries.
- **Processing:** `tool/arabic/convert_arabic.dart --source heliboard`. Removes harakat, tatweel and ZWNJ; maps
  Persian yeh and kaf to Arabic ي and ك; keeps only Arabic-script words of 2 to 20 letters; the highest frequency wins
  on duplicates.

## ur: Urdu word list

- **Shipped:** `assets/dict/ur.mdict` (36,042 words after the builder filter; 656 KB).
- **Source:** the Urdu Wikipedia articles dump (`urwiki-latest-pages-articles.xml.bz2`, downloaded 2026-11-22 from
  https://dumps.wikimedia.org/urwiki/latest/).
  - Licence: Wikipedia text, **CC BY-SA 4.0**. Words and frequencies are extracted; no article text is shipped.
  - Attribution: Urdu Wikipedia contributors (https://ur.wikipedia.org).
- **Not used:** `main_ur.combined` in HeliBoard's list, licensed GPLv2 without "or later" (not usable here).
- **Processing:** `bzip2 -dc <dump> | dart run tool/arabic/convert_arabic.dart --lang ur --source wiki`. Counts Arabic-script
  words, normalises harakat, tatweel and ZWNJ, maps Arabic yeh, alef maqsura and kaf to Urdu ی and ک, and keeps words
  of 2 to 20 letters seen at least 3 times. Frequencies are log-scaled to 1..255.
- **No next-word data** for Urdu (the converter does not compute bigrams).

## Layouts

`arabic.json` and `urdu_phonetic.json` are original work, under the project licence.
