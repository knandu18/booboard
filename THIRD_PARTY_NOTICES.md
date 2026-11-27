# Third-party notices

BooBoard is GPL-3.0-or-later. It includes or builds on the following. Every bundled data source must be listed here with its license and attribution, and also shown in the app's About → Licenses screen.

## Code

| Component | License | Use |
|---|---|---|
| Flutter engine and framework | BSD-3-Clause | UI runtime |
| material_ui | BSD-3-Clause | Material widgets (settings app) |
| flutter_riverpod | MIT | State management |
| path_provider | BSD-3-Clause | App directories |
| collection, meta, characters | BSD-3-Clause | Dart utilities |
| pigeon (build-time only) | BSD-3-Clause | Kotlin and Dart bridge generation |
| androidx.autofill:autofill 1.3.0 | Apache-2.0 | Styles the inline autofill chips from password managers (Android 11+). UI helpers only: no network code, no permissions, no native code. Source: https://maven.google.com, code at https://android.googlesource.com/platform/frameworks/support/+/refs/heads/androidx-main/autofill/ |
| kotlinx-coroutines-android 1.9.0 | Apache-2.0 | Runs Pigeon's async Kotlin handlers. Copyright JetBrains s.r.o. (https://github.com/Kotlin/kotlinx.coroutines) |
| image_picker | BSD-3-Clause | Android Photo Picker for theme backgrounds (no storage permission) |
| local_auth | BSD-3-Clause | BiometricPrompt app lock |
| junit:junit 4.13.2 (tests only, not in the APK) | EPL-1.0 | JVM unit tests under `android/app/src/test` |
| onnxruntime-android 1.28.0 | MIT | Inference runtime shared by voice and translation. Copyright Microsoft Corporation (https://github.com/microsoft/onnxruntime). No network code. |
| sherpa-onnx v2.0.1 (`libsherpa-onnx-jni.so` and Kotlin API sources) | Apache-2.0 | Offline speech recognition (Wave 3-D). Copyright Xiaomi Corporation and the k2-fsa authors (https://github.com/k2-fsa/sherpa-onnx). Details in the voice section. |
| org.json 20240303 (tests only, not in the APK) | Public domain (JSON License text) | JVM tests of the pack store |
| onnxruntime 1.28.0 desktop (tests only, not in the APK) | MIT | JVM tests of the translation engine |

## Data

| Data | License | Attribution |
|---|---|---|
| English dictionary (`assets/dict/en.mdict`) | Apache-2.0 | Copyright (c) 2008, The Android Open Source Project (Wave 1-B, details below) |
| Latin accent-fold table in `lib/src/engine/dictionary/text_fold.dart` | Unicode License v3 | Generated from the Unicode Character Database, Unicode, Inc. (https://www.unicode.org/license.txt). No Unicode data files are shipped. |
| Google Sans Flex font (`assets/fonts/GoogleSansFlex.ttf`) | SIL OFL 1.1 | Copyright 2015 Google LLC / The Google Sans Flex Authors (Wave 1-D, details below) |
| Fraunces font (`assets/fonts/Fraunces.ttf`) | SIL OFL 1.1 | Copyright 2018 The Fraunces Project Authors (details below) |
| Emoji list and CLDR annotations (`assets/emoji/`) | Unicode License v3 | (c) Unicode, Inc. (Wave 2-D, details below) |

### English dictionary

- Built by `tool/build_dictionary.dart` into BooBoard's own `MDICT` format: about 147k words with frequencies, flags for possibly offensive words, apostrophe corrections and about 344k next-word pairs.
- Original list: AOSP LatinIME `dictionaries/en_US_wordlist.combined.gz` (https://android.googlesource.com/platform/packages/inputmethods/LatinIME/, branch `main`, commit `127336e9f29d69607eab55982324b210279ae8c5` checked 2026-11-21). That file has no next-word pairs.
- Build input actually used: `wordlists/main_en_US.combined` from https://codeberg.org/Helium314/aosp-dictionaries (branch `main`, downloaded 2026-11-21). It comes from OpenBoard v1.4.5 `en_wordlist.combined.gz` (https://github.com/openboard-team/openboard/blob/v1.4.5/dictionaries/en_wordlist.combined.gz), which is the same AOSP word set (160,715 words) plus the next-word pairs.
- License: Apache License 2.0 (LatinIME `NOTICE`), compatible with GPL-3.0-or-later.
- Modifications: NFC-normalised and cleaned (URLs, digits and stray punctuation removed), capped to 150k words by frequency, accent-folded keys merged, frequencies converted to log probabilities, and common English contractions added.

### Google Sans Flex

- Files: `assets/fonts/GoogleSansFlex.ttf` (variable font, axes `opsz`, `wdth`, `wght` 1-1000, `ROND` 0-100, `slnt`) and its licence `assets/fonts/OFL.txt`.
- Version 5.000 (upstream commit `cedf1e9`, 2026-10-09), from https://github.com/google/fonts/tree/main/ofl/googlesansflex (file `GoogleSansFlex[ROND,opsz,slnt,wdth,wght].ttf`). Upstream project: https://github.com/googlefonts/googlesans-flex.
- Integrity: git blob SHA-1 `1d8d8ae5a7c6d0e48312d2a0a478bad92caee73a` (TTF) and `3e50f6cb72e58f01997d1e608195e8fdbc0eb8b4` (`OFL.txt`), identical to google/fonts.
- Bundled unmodified under its own name, so the Reserved Font Name clause is respected. Declared in `pubspec.yaml` as family `GoogleSansFlex`; never downloaded at runtime.
- Non-Latin scripts fall back to the device's Noto fonts.

### Fraunces

- Files: `assets/fonts/Fraunces.ttf` (variable font, axes `SOFT`, `WONK`, `opsz`, `wght`) and its licence `assets/notices/ofl-1.1-fraunces.txt`. Used for the headlines of first-run setup.
- From https://github.com/google/fonts/tree/main/ofl/fraunces (file `Fraunces[SOFT,WONK,opsz,wght].ttf`, downloaded 2026-11-25). Upstream project: https://github.com/undercasetype/Fraunces.
- Integrity: git blob SHA-1 `8210f9488d3c732359a9292dd09aca3f2bae830e` (TTF) and `22fa7ce5733434d0c634f6e55116f410858e938c` (licence).
- Bundled unmodified under its own name, so the Reserved Font Name clause is respected. Declared in `pubspec.yaml` as family `Fraunces`; never downloaded at runtime.

### Emoji data

- Built offline by `tool/build_emoji.dart` into `assets/emoji/`: `emoji.dat` (2,338 base emoji with English names, Unicode versions and skin-tone variants) and `keywords_<lang>.dat` (keyword index and CLDR short names) for 17 languages: en, es, fr, de, pt, id, hi, mr, bn, ta, te, ar, ur, ru, uk, zh, ja. About 1.8 MB in total.
- Sources: Unicode Emoji 18.0 `emoji-test.txt` (https://unicode.org/Public/emoji/latest/emoji-test.txt, file dated 2026-04-30) and CLDR release-49 `common/annotations` and `annotationsDerived` (https://github.com/unicode-org/cldr/tree/release-49, published 2026-10-21).
- License: Unicode License v3 (https://www.unicode.org/license.txt). Unicode, CLDR and their data are (c) Unicode, Inc.
- Modifications: reshaped only (skin-tone variants grouped under their base emoji, keywords indexed). Never downloaded at runtime.

## Wave 3: languages, voice and translation

Model packs (voice and translation) are not part of the APK; each pack carries its own licence in its signed manifest, and the Model packs screen shows it. The sources below are what the packs and bundled dictionaries are built from.

### Third-party notices: European languages (Wave 3-A)

The dictionaries in `assets/dict/{es,fr,de,pt-BR,pt-PT,id,ru,uk}.mdict` are built from word lists by
`tool/build_dictionary.dart`, using `tool/european/prepare_wordlist.py` and `tool/european/build_dictionaries.py`.
The layouts `assets/layouts/{qwerty_es,azerty,qwertz,qwertz_umlaut,jcuken_ru,jcuken_uk}.json` are written by
`tool/european/make_layouts.py` from the shared rows of `qwerty.json`. No network code is involved.

#### Source of the word lists

- **Project:** HeliBoard dictionaries (`aosp-dictionaries`, maintained by Helium314), the `wordlists/*.combined`
  files and their `.source` descriptions.
- **URL:** https://codeberg.org/Helium314/aosp-dictionaries (raw files under `wordlists/`)
- **Retrieved:** 22 November 2026 (the repository's README lists its last update per language).
- **Attribution:** word lists by the Leipzig Corpora Collection (Wortschatz Leipzig), as credited by the
  aosp-dictionaries project.

#### Per language

| Language | Source file | Licence | Words | Bigrams | Size (bytes) |
|---|---|---|---|---|---|
| Spanish (`es`) | `wordlists/main_es__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 70,000 | 70,000 | 1,430,689 |
| French (`fr`) | `wordlists/main_fr__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 62,000 | 60,000 | 1,400,411 |
| German (`de`) | `wordlists/main_de.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 56,000 | 46,000 | 1,438,489 |
| Portuguese, Brazil (`pt-BR`) | `wordlists/main_pt_BR.combined` | See the note below | 70,000 | 0 | 1,296,162 |
| Portuguese, Portugal (`pt-PT`) | `wordlists/main_pt_PT__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 66,000 | 62,000 | 1,432,261 |
| Indonesian (`id`) | `wordlists/main_id__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 58,000 | 38,000 | 1,442,903 |
| Filipino (`fil`) | `wordlists/main_tl__experimental.combined` | CC BY-SA 4.0 (FrequencyWords, see below) | 10,564 | 0 | 260,682 |
| Russian (`ru`) | `wordlists/main_ru__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 78,000 | 0 | 1,431,798 |
| Ukrainian (`uk`) | `wordlists/main_uk__experimental.combined` | CC BY 4.0 (Wortschatz Leipzig lists) | 85,000 | 0 | 1,459,689 |

Every file is under the 1.5 MB budget. Word counts are the words kept after cleaning; the builder drops
junk tokens (for example 436 in Spanish, 12,434 in French). Only the most frequent words are kept, and the
experimental lists also carry next-word (bigram) data, which is kept where it fits the size budget.

##### Filipino: source and licence

`main_tl__experimental.combined` (HeliBoard, downloaded 2026-11-24, SHA-256
`78239349374d24a7214e26ec08b3a937abbec7ecb25842b597d9f403c67a0675`) is the Tagalog list "created from github
hermitdave Frequencywords repo" (https://github.com/hermitdave/FrequencyWords, word frequencies from the
OpenSubtitles 2018 corpus). The FrequencyWords content is licensed CC BY-SA 4.0 (Hermit Dave); the dictionary built
from it (`assets/dict/fil.mdict`) is shared under the same licence. Attribution is this notice. The list has no
next-word data and includes the English words people mix into Filipino (Taglish). Filipino emoji keywords come from
the CLDR `fil` annotations (Unicode License v3, see the emoji section).

##### Portuguese, Brazil: licence to confirm

`main_pt_BR` is the AOSP pt_BR list (2014) as patched by joaohcopetti in
https://github.com/joaohcopetti/aosp-dict-pt-br-patched (grammar corrections with Hunspell). The HeliBoard
`.source` file only says "AOSP dictionary modified". The AOSP project is Apache-2.0, but the repository
states no licence for the patched list, and we did not verify the licence of the underlying word data.
**Before release the orchestrator must confirm this file's licence**, or replace it with a CC BY or CC0 Brazilian
Portuguese list. The build removes 36 words that are Portugal-only from it (for example *autocarro*, *equipa*)
and `pt-PT` removes 29 Brazil-only words (for example *ônibus*, *trem*), so each variant keeps its own vocabulary.

#### Licence summary

- CC BY 4.0: Wortschatz Leipzig word lists, as credited by the HeliBoard project. Attribution is this notice.
- Apache-2.0 / unconfirmed: the pt-BR list (see above).
- CC BY-SA 4.0: the Filipino list (FrequencyWords by Hermit Dave, from OpenSubtitles), see above.
- GPL-3.0-or-later: the tools in `tool/` and the Dart code in this area.

### Indic data notices (Wave 3-B)

Languages: Hindi (hi), Marathi (mr), Bengali (bn), Tamil (ta), Telugu (te). The data below is built by
`tool/indic/` and shipped in `assets/translit/`, `assets/dict/` and `assets/layouts/`. No model or network code
is involved: everything is a static file in the app.

#### Sources

##### 1. Aksharantar: romanised word pairs

- Project: Aksharantar, AI4Bharat (Madhani et al., 2022, arXiv:2205.03018).
- Source: https://huggingface.co/datasets/ai4bharat/Aksharantar (per-language archives `hin.zip`,
  `mar.zip`, `ben.zip`, `tam.zip`, `tel.zip`; dataset revision `e418c1fc928d9f5393af33268472cf20c1891be8`,
  last modified 2023-08-31). Downloaded 2026-11-22.
- Used: the train, validation and test JSON lines of each language, English (romanised) word and native word.
- Licence: the dataset card states CC0 for the mined data and existing sources, and CC BY 4.0 for the manually
  collected data. Both are accepted by the project's data rules. AI4Bharat is credited.
- Derived: `assets/translit/<lang>.bin` (romanised -> native table; the pairs are reduced to the most frequent
  100,000 entries per language, see `tool/indic/build_data.py`).

##### 2. Wikipedia word frequencies

- Source: Wikipedia "pages-articles" dumps (latest), for hi, mr, bn, ta and te, downloaded 2026-11-22 from
  https://dumps.wikimedia.org/. Articles in the main namespace only; redirects skipped.
- Licence: CC BY-SA 4.0. Only word counts are kept (no text). The derived word lists are therefore shared
  under CC BY-SA 4.0, with attribution to "Wikipedia contributors" and a link to the licence:
  https://creativecommons.org/licenses/by-sa/4.0/
- Derived: `assets/dict/<lang>.mdict` (the 50,000 most frequent words, count at least 3, one dictionary per
  language), and the frequency ranking of the translit table.

##### 3. Inverse romanisation (generated)

Canonical romanised spellings of the frequent Wikipedia words, produced by inverting the rule-based scheme in
`lib/src/engine/lang/indic/scheme.dart` (an original work, GPL-3.0-or-later). No external data.

##### 4. Keyboard layouts (generated)

`assets/layouts/{translit,phonetic}_<lang>.json` are generated by `tool/indic/make_layouts.py` from the
QWERTY layout and from the letter roles listed in the script. `assets/layouts/inscript_<lang>.json` are generated by
`tool/indic/make_inscript.dart` from the InScript key tables of the BIS standard (IS 13194), as transcribed in
xkeyboard-config `symbols/in` (layouts `deva`, `ben_inscript`, `tam`, `tel`; https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config,
MIT licence, copyright the xkeyboard-config authors). Only the key-to-character assignments are used; no file is
copied. The layouts contain no third-party artwork.

#### Sizes (this build)

Measured with `ls -l` after the final build (see the report of Wave 3-B for the full table).

| File | Size |
|---|---|
| `assets/translit/<lang>.bin` (gzip) | about 0.8 MB each |
| `assets/dict/<lang>.mdict` | about 1.0 to 1.1 MB each |

Budget: 1.5 MB per file.

#### Tools

- `tool/indic/wiki_counts.py`: word counts from a Wikipedia dump (stdlib only).
- `tool/indic/export_schemes.dart`: prints the romanisation schemes as JSON.
- `tool/indic/build_data.py`: translit tables and `.combined` word lists (needs the Aksharantar JSON and the counts).
- `tool/indic/build_indic_dict.dart`: `.combined` -> `.mdict`. Written instead of `tool/build_dictionary.dart`
  because that tool drops every word of three characters or fewer that "is upper case"; Indic scripts have no
  case, so it would drop common words such as है, और and में.
- `tool/indic/make_layouts.py`: the Indic layouts.

### Arabic and Urdu data notices (Wave 3-C)

Data shipped in `assets/dict/ar.mdict` and `assets/dict/ur.mdict`, and the layouts
`assets/layouts/arabic.json` and `assets/layouts/urdu_phonetic.json` (written by us, no third-party data).

#### ar: Arabic word list

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

#### ur: Urdu word list

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

#### Layouts

`arabic.json` and `urdu_phonetic.json` are original work, under the project licence.

### Voice typing: third-party notices (Wave 3-D)

Everything below ships with the app or is staged for the orchestrator to sign as voice packs. Nothing here
is downloaded by the app. Voice typing works in English only: the one voice pack is Parakeet (section 2).

#### 1. sherpa-onnx native library and Kotlin API

| Item | Value |
|---|---|
| Project | sherpa-onnx, https://github.com/k2-fsa/sherpa-onnx |
| Release | **v2.0.1** (published 2026-10-26), asset `sherpa-onnx-v2.0.1-android.tar.bz2` |
| Licence | Apache-2.0 (`LICENSE` in the release source, `sherpa-onnx-2.0.1/LICENSE`) |
| Copyright | Copyright (c) the sherpa-onnx authors, including Xiaomi Corporation (Kotlin API headers) |
| Built against | onnxruntime 1.28.2 (`libonnxruntime.so` inside that bundle, NOT shipped; see section 3). Modified, see below |
| SHA-256 of the bundle | `39003753ec293425ed56723ea9b972b98841a490af3311670c3060548d654330` |

Shipped native libraries (only `libsherpa-onnx-jni.so`; the `c-api`/`cxx-api` libraries and the bundled
`libonnxruntime.so` are not copied):

| ABI | File | Bytes | SHA-256 as shipped (modified) | SHA-256 in the release (original) |
|---|---|---|---|---|
| arm64-v8a | `app/src/main/jniLibs/arm64-v8a/libsherpa-onnx-jni.so` | 4,609,320 | `e3a7bea4e718f15d22806c6a871fcd981e9bbe1f1f98c7d18bdbdb783fa14e32` | `5db8f89f12b2c900a98c9e01e00c475c59db35e9437a62e36e27839ec48b5575` |
| armeabi-v7a | `app/src/main/jniLibs/armeabi-v7a/libsherpa-onnx-jni.so` | 3,381,796 | `10a70ad0e2f5896c4e3a3f812de8471606eaa76cfa8bf554885ba8d26374353c` | `d45f377249d5c3191b91de6ba6edffcd83e4cf7e109bc523b212db341581c2a8` |
| x86_64 (emulator) | `app/src/main/jniLibs/x86_64/libsherpa-onnx-jni.so` | 5,053,592 | `d1614526d6f4682e10be2feaae90f866c4736b46dfef8d12de213ed2ca29ce34` | `878d61116f244131263eec24297ef05bf508d02bccdede2a4e3ad3202bbdaa48` |

`libsherpa-onnx-jni.so` has one dependency, `libonnxruntime.so`. It is provided by the Maven artifact
`com.microsoft.onnxruntime:onnxruntime-android:1.28.0` (MIT); 1.28.2 is not published for Android, and 1.29+ adds telemetry.

**Modification (Apache-2.0 section 4b):** the release libraries ask for `OrtGetApiBase@VERS_1.28.2`, and Android's linker
enforces symbol versions, so they did not load against 1.28.0 ("cannot locate symbol OrtGetApiBase"). BooBoard changes one
entry of each library's ELF version-needs table from `VERS_1.28.2` to `VERS_1.28.0` and updates its hash: 2 bytes per file,
done by `tool/patch_sherpa_ort_version.dart` and checked by `test/tool/patch_sherpa_ort_version_test.dart`. OrtGetApiBase
is the only onnxruntime symbol sherpa imports, and the OrtApi level (28) is the same in 1.28.0 and 1.28.2. Checked on the
emulator (API 37, x86_64) on 2026-11-22: the library loads and a voice pack runs.

Kotlin API files copied unmodified (apart from a two-line provenance comment at the top) into
`app/src/main/kotlin/app/booboard/keyboard/voice/sherpa/`, from `android/SherpaOnnxAar/sherpa_onnx/src/main/java/com/k2fsa/sherpa/onnx/`
of the same tag: `FeatureConfig.kt`, `HomophoneReplacerConfig.kt`, `QnnConfig.kt`, `OfflineRecognizer.kt`,
`OfflineStream.kt`, `Vad.kt`. Their package stays `com.k2fsa.sherpa.onnx` because the JNI symbols bind to it.

##### Build from source (for Wave 5's reproducible builds; not yet run)

1. Get the sources of the same tag: `https://github.com/k2-fsa/sherpa-onnx/archive/refs/tags/v2.0.1.tar.gz`.
2. Get onnxruntime 1.28.0 for Android from Maven (`onnxruntime-android-1.28.0.aar`) and unzip it. Its `headers/`
   folder is the include dir, and `jni/<abi>/libonnxruntime.so` is the lib dir for each ABI.
3. Install the Android NDK matching `flutter.ndkVersion` and set `ANDROID_NDK`.
4. From the source root run, for each ABI, for example:
   `SHERPA_ONNXRUNTIME_LIB_DIR=<aar>/jni/arm64-v8a SHERPA_ONNXRUNTIME_INCLUDE_DIR=<aar>/headers ./build-android-arm64-v8a.sh`
   (`build-android-armv7-eabi.sh` and `build-android-x86-64.sh` for the others). The scripts use CMake and build
   the shared library, which links the AAR's `libonnxruntime.so`.
5. Take `libsherpa-onnx-jni.so` from the build output and compare its SHA-256 with the table above.

#### 2. Parakeet TDT 0.6B v2 (English speech recognition, int8)

| Item | Value |
|---|---|
| Model | NVIDIA Parakeet TDT 0.6B v2 (English), int8 ONNX export by the sherpa-onnx project |
| Licence | CC BY 4.0 (weights, NVIDIA: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2); the export scripts are Apache-2.0 (sherpa-onnx). NVIDIA does not endorse BooBoard or this pack. |
| Attribution | "parakeet-tdt-0.6b-v2" by NVIDIA, licensed under CC BY 4.0. Converted to int8 ONNX by sherpa-onnx; BooBoard renames no files and adds Silero VAD (section 3). |
| Source | sherpa-onnx release `asr-models`: `sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2` (asset dated 2026-11-07) |
| Archive SHA-256 | `6fc4426b54aa549a0019b8a75b8dea59164e71790a37ac56a045ad57f915f714` (482,440,461 bytes) |
| Files in a pack | `encoder.int8.onnx` (652,282,309), `decoder.int8.onnx` (7,257,753), `joiner.int8.onnx` (1,739,080), `tokens.txt` (9,384), `silero_vad.onnx` |
| Languages | en only. Pack id `voice-parakeet-en`, engine `sherpa-onnx-nemo-transducer` (the only voice pack; voice typing works in English only) |

#### 3. Silero VAD (voice activity detection)

| Item | Value |
|---|---|
| Model | Silero VAD (`silero_vad.onnx`, the sherpa-onnx release file of that name) |
| Licence | MIT (snakers4/silero-vad; confirm on the model card) |
| Source | sherpa-onnx release `asr-models`, `silero_vad.onnx` (2025-07-11) |
| SHA-256 | `9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6` (643,854 bytes; matches the API digest) |

#### 4. Later packs (assessed, not built)

- **Dolphin** (Apache-2.0 per the brief; verify on the model card): sherpa-onnx has an offline Dolphin config (`OfflineDolphinModelConfig`). Hindi, Urdu and Arabic coverage to be checked
  on the model card before a pack is staged. Not built in Wave 3.
- **Moonshine** (licence to verify on the model card, believed MIT): English-only. sherpa-onnx has an offline Moonshine config (`OfflineMoonshineModelConfig`). Useful as a small English pack. Not built in Wave 3.

### Notices: offline translation (Wave 3-T)

BooBoard's translation runs OPUS-MT neural models on the phone with ONNX Runtime. The app never bundles
a model: each direction is a signed model pack that the user imports (see `tool/packs/translate/`).

#### Engine

| Component | Version | Licence | Use |
|---|---|---|---|
| ONNX Runtime (`com.microsoft.onnxruntime:onnxruntime-android`, JVM tests: `onnxruntime`) | 1.28.0 | MIT | Runs the encoder and decoder |
| OPUS-MT model architecture (Marian) | - | MIT (Marian NMT) | Model graph |

The SentencePiece model file (`source.spm`) is read by our own minimal reader
(`SentencePieceModel.kt`); no SentencePiece library is used.

#### Models

All 12 directions come from the ONNX exports by Xenova (Hugging Face, Transformers.js project), which
convert the Helsinki-NLP OPUS-MT models. The int8 "quantized" graphs are used
(`encoder_model_quantized.onnx`, `decoder_model_merged_quantized.onnx`). Upstream models are trained on
OPUS corpora (Tiedemann, 2012, "Parallel Data, Tools and Interfaces in OPUS", LREC).

Citation for OPUS-MT: Tiedemann, J. and Thottingal, S. (2020), "OPUS-MT - Building open translation
services for the World", EAMT.

| Pack | Upstream model (Helsinki-NLP) | Exported by | Revision (commit) | Licence | Staged size |
|---|---|---|---|---|---|
| translate-en-es | opus-mt-en-es | Xenova/opus-mt-en-es | 4b002a4c7edd54a7ced58877258b87f7efd3f892 | Apache-2.0 | 110.3 MB |
| translate-es-en | opus-mt-es-en | Xenova/opus-mt-es-en | eadfd7c658a9d8929ac3b8e996b68a68e2c7d480 | Apache-2.0 | 110.3 MB |
| translate-en-fr | opus-mt-en-fr | Xenova/opus-mt-en-fr | 28726206f80896b90035bd99cccd5cc1e151f916 | Apache-2.0 | 104.6 MB |
| translate-fr-en | opus-mt-fr-en | Xenova/opus-mt-fr-en | 6b166a182780e118c997879d0ad5be4b53671644 | Apache-2.0 | 104.6 MB |
| translate-en-de | opus-mt-en-de | Xenova/opus-mt-en-de | 1ca130c44c4c5441ef16d48aae521a424ab644f7 | CC-BY-4.0 | 103.2 MB |
| translate-de-en | opus-mt-de-en | Xenova/opus-mt-de-en | 399dfd68706739fffd503f876093e455ae268a06 | Apache-2.0 | 103.2 MB |
| translate-en-pt | opus-mt-en-ROMANCE (multi-target, `>>pt<<`) | Xenova/opus-mt-en-ROMANCE | 9d2ba69ac80c8e8453c3d9a1e2323a0e7b8ca3cd | Apache-2.0 | 110.1 MB |
| translate-pt-en | opus-mt-ROMANCE-en | Xenova/opus-mt-ROMANCE-en | f60feaabe8bb435a5871e7702b25f53a01e770f8 | Apache-2.0 | 110.2 MB |
| translate-en-hi | opus-mt-en-hi | Xenova/opus-mt-en-hi | 7aad72006a1588a9c3485ed6203aed99eebbc872 | Apache-2.0 | 107.8 MB |
| translate-hi-en | opus-mt-hi-en | Xenova/opus-mt-hi-en | 99853100ed9d932987a6816e8cf7b1b6742a6116 | Apache-2.0 | 107.2 MB |
| translate-en-ru | opus-mt-en-ru | Xenova/opus-mt-en-ru | e050376e960175e8ddc5cff85025dc8436cddd68 | Apache-2.0 | 108.8 MB |
| translate-ru-en | opus-mt-ru-en | Xenova/opus-mt-ru-en | afe8c6c738ec81b6d033fd8f44f9678a639a7c67 | CC-BY-4.0 | 109.1 MB |

Licences are the ones stated on the upstream Helsinki-NLP model cards (checked on 2026-11-22). Apache-2.0
and CC-BY-4.0 are both allowed. The Portuguese pack uses the multilingual ROMANCE models with the target
token `>>pt<<`, which both Portuguese variants (pt-BR, pt-PT) share.

Every file's SHA-256 is pinned in `tool/packs/translate/models.json` and checked by `stage.ps1`.
The pack manifest carries the licence of each pack; the orchestrator signs the packs.

Thanks and attribution: the Helsinki-NLP team (OPUS-MT), Jörg Tiedemann and the OPUS project, and Xenova
for the ONNX conversions.

#### Tokeniser

Each model's `source.spm` and shared `vocab.json` come unchanged from the same upstream repository.
Tokenisation is checked against the sentencepiece library on 102 test sentences (0 mismatches).

## Wave 4: Chinese, Japanese and the ONNX runtime

The Chinese and Japanese dictionaries are signed packs, not part of the APK; each pack carries its own licence texts in a NOTICE.txt.

### Chinese data notices (Wave 4-A)

The Chinese dictionary pack `dict-zh-rime-ice` is built from the sources below by
`tool/packs/chinese/stage_rime_ice.ps1` and `tool/chinese/build_zh_dict.dart`. The app never bundles
or downloads the data; the pack is signed and installed like the other model packs.

#### rime-ice (雾凇拼音)

- Source: https://github.com/iDvel/rime-ice, commit `927e1cf1d3eeb9bf4be85e3f684dba4dd485b6f6`
  (2026-11-11), files `cn_dicts/base.dict.yaml`, `cn_dicts/ext.dict.yaml`, `cn_dicts/8105.dict.yaml`.
- Licence: GPL-3.0 (compatible with BooBoard's GPL-3.0-or-later).
- Its own base words come from the 华宇野风 system dictionary, THUOCL (Tsinghua), a modern Chinese
  common word list, and the Tencent word vectors; rime-ice credits these in its header.
- Used: the word rows of base (weight 1000 and above) and ext (flat weight 100), and the 8105
  character readings. Derived: the pinyin index, per-source log probabilities, initials.
- Not used: `tencent.dict.yaml` (no pinyin column, flat weights, and the budget for the pack is
  600k words), `others.dict.yaml`, and the professional or sentence dictionaries.

#### OpenCC (Simplified to Traditional, Taiwan standard)

- Source: https://github.com/BYVoid/OpenCC, commit `fae2a0a911c30764e669a7d8b0591cd8e852934a`,
  `data/dictionary/STPhrases.txt`, `STCharacters.txt`, `TWPhrases.txt`, `TWVariants.txt`.
- Licence: Apache-2.0 (Copyright BYVoid and contributors). The pack does not ship the upstream
  files: it ships `s2twp.tsv`, a derived table holding the first target of each line in the four
  files, in the order s2twp uses.

#### Attribution

Chinese word data from rime-ice (GPL-3.0), which carries the 华宇野风, THUOCL, 现代汉语常用词表 and
Tencent word vector sources; OpenCC conversion tables (Apache-2.0), BYVoid and contributors.

#### Files shipped in the pack

- `zh.kdict` (about 35 MB; 587,641 entries: 578,943 words and 8,698 characters).
- `s2twp.tsv` (about 0.5 MB).

#### Layout

- `assets/layouts/pinyin_zh.json`: QWERTY letters with Chinese punctuation (no data).
- Test corpus `test/engine/lang/chinese/golden_zh.txt`: 300 common words (base weight 100000 and
  above) drawn from rime-ice base by `tool/chinese/build_zh_dict.dart --golden`.

### Japanese notices (Wave 4-B)

#### dict-ja-mozc: the Japanese dictionary pack

- **Source:** Mozc open-source dictionary, `src/data/dictionary_oss/` (dictionary00.txt to dictionary09.txt,
  connection_single_column.txt, id.def, README.txt), https://github.com/google/mozc
- **Commit:** `1527a4cd1217cec4611cd4bc8d46f8c66ea79e6a` (master on 2026-11-20). `tool/packs/japanese/stage_mozc.ps1`
  downloads exactly this commit.
- **Licence:** BSD-3-Clause for the Mozc code and data (full text below). The dictionary README also carries the
  IPAdic terms (mecab-ipadic-2.7.0-20070801, NAIST and ICOT; full text below) and the Okinawa dictionary, which
  is public domain.
- **Changes made:** the entries are converted into `japanese.lex.gz` (reading trie-like index, surfaces, word ids and
  costs) and `japanese.conn.gz` (the connection matrix), by `tool/japanese/build_mozc_lexicon.dart`. Readings are
  folded to hiragana, and entries whose reading has any other character are dropped (3,550 of 1,289,076 lines
  skipped, including malformed ones). Costs are stored as 16-bit values.
- **Attribution:** "Japanese dictionary: Mozc open-source dictionary (Google), IPAdic 2.7.0 (NAIST, ICOT), Okinawa dictionary."

#### Romaji table

`lib/src/engine/lang/japanese/romaji.dart` is written for this project from the common Hepburn and Kunrei spellings.
No table from Mozc or any other source is copied.

#### Golden corpus (test data only)

`test/engine/lang/japanese/golden_ja.tsv` (300 items) is built by `tool/japanese/build_golden_tatoeba.py` from the
Tatoeba Japanese furigana transcriptions (https://downloads.tatoeba.org/exports/transcriptions.tar.bz2, export of
2026-11-21), licence CC BY 2.0 FR (https://creativecommons.org/licenses/by/2.0/fr/), © Tatoeba contributors. Each
row keeps its sentence id (`tatoeba:<id>`, https://tatoeba.org/en/sentences/show/<id>). Rows are cut from the
sentences at punctuation and keep only hiragana and annotated kanji. The corpus is not shipped in the app.

The first corpus (Aozora Bunko ruby texts by 岡本かの子, built by a since-removed `build_golden.dart`) was replaced in the Wave 4
merge: its pre-war spellings were mostly missing from Mozc, and the ruby transcriptions have no licence from the
COMMON.md list.

#### Licence texts

##### Mozc LICENSE (BSD-3-Clause)

```text
Copyright 2010-2018, Google Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following disclaimer
    in the documentation and/or other materials provided with the
    distribution.
  * Neither the name of Google Inc. nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

Files: src/data/dictionary*

Copyright 2000, 2001, 2002, 2003 Nara Institute of Science
and Technology.  All Rights Reserved.

Use, reproduction, and distribution of this software is permitted.
Any copy of this software, whether in its original form or modified,
must include both the above copyright notice and the following
paragraphs.

Nara Institute of Science and Technology (NAIST),
the copyright holders, disclaims all warranties with regard to this
software, including all implied warranties of merchantability and
fitness, in no event shall NAIST be liable for
any special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an
action of contract, negligence or other tortuous action, arising out
of or in connection with the use or performance of this software.

A large portion of the dictionary entries
originate from ICOT Free Software.  The following conditions for ICOT
Free Software applies to the current dictionary as well.

Each User may also freely distribute the Program, whether in its
original form or modified, to any third party or parties, PROVIDED
that the provisions of Section 3 ("NO WARRANTY") will ALWAYS appear
on, or be attached to, the Program, which is distributed substantially
in the same form as set out herein and that such intended
distribution, if actually made, will neither violate or otherwise
contravene any of the laws and regulations of the countries having
jurisdiction over the User or the intended distribution itself.

NO WARRANTY

The program was produced on an experimental basis in the course of the
research and development conducted during the project and is provided
to users as so produced on an experimental basis.  Accordingly, the
program is provided without any warranty whatsoever, whether express,
implied, statutory or otherwise.  The term "warranty" used herein
includes, but is not limited to, any warranty of the quality,
performance, merchantability and fitness for a particular purpose of
the program and the nonexistence of any infringement or violation of
any right of any third party.

Each user of the program will agree and understand, and be deemed to
have agreed and understood, that there is no warranty whatsoever for
the program and, accordingly, the entire risk arising from or
otherwise connected with the program is assumed by the user.

Therefore, neither ICOT, the copyright holder, or any other
organization that participated in or was otherwise related to the
development of the program and their respective officials, directors,
officers and other employees shall be held liable for any and all
damages, including, without limitation, general, special, incidental
and consequential damages, arising out of or otherwise in connection
with the use or inability to use the program or any product, material
or result produced or otherwise obtained by using the program,
regardless of whether they have been advised of, or otherwise had
knowledge of, the possibility of such damages at any time during the
project or thereafter.  Each user will be deemed to have agreed to the
foregoing by his or her commencement of use of the program.  The term
"use" as used herein includes, but is not limited to, the use,
modification, copying and distribution of the program and the
production of secondary products from the program.

In the case where the program, whether in its original form or
modified, was distributed or delivered to or received by a user from
any person, organization or entity other than ICOT, unless it makes or
grants independently of ICOT any specific warranty to the user in
writing, such person, organization or entity, will also be exempted
from and not be held liable to the user for any such damages as noted
above as far as the program is concerned.

---

Files: src/data/dictionary*

Public Domain Dataです。使用・変更・配布に関しては一切の制限をつけません。
商品などに組み込むことも自由に行なってください。すでにいくつかの辞書には沖縄辞書が採用されています。
勝手ながら、沖縄辞書に寄贈された辞書も in the Public Domain' 扱いとさせていただきます。
```

##### dictionary_oss README (IPAdic and Okinawa dictionary terms)

```text
Open source mozc dictionary is different from the dictionary
used for Google Japanese Input. The differences are as follows:

- Large vocabulary set generated from the Web corpus is not included.
- The vocabulary set is basically the same as that of IPAdic.
  The licenses of IPAdic is found below.
  Here's the version of IPAdic Mozc uses.
  * mecab-ipadic-2.7.0-20070801 (ipadic-2.7.0)
- Okinawa Dictionary is used to enrich named entities.
  http://sourceforge.jp/projects/o-dic/
  The license of Okinawa dictionary is found below.
- Google manually added some extra adjective/verbs which are not in IPAdic.
- Many Katakana words are included in the dictionary. They are collected as unknown words
  during the text processing over the Web data.
- To improve the conversion quality of Mozc, several compound words
  (like 社員証, 再起動) are added. We basically collected these compounds from the Web
  by using MeCab and IPAdic.
- Open source version doesn't include Japanese postal code dictionary.

You can add zip code dictionary by follows:
1. Download zip code data from http://www.post.japanpost.jp/zipcode/download.html
2. Extract them
3. Update zip_code_seed.tsv by
  PYTHONPATH="${PYTHONPATH}:../../"  \
    python ../../dictionary/gen_zip_code_seed.py \
    --zip_code=KEN_ALL.CSV --jigyosyo=JIGYOSYO.CSV >> dictionary09.txt


-------------------------------------------------------------------------------
IPAdic is licensed as follows:

Copyright 2000, 2001, 2002, 2003 Nara Institute of Science
and Technology.  All Rights Reserved.

Use, reproduction, and distribution of this software is permitted.
Any copy of this software, whether in its original form or modified,
must include both the above copyright notice and the following
paragraphs.

Nara Institute of Science and Technology (NAIST),
the copyright holders, disclaims all warranties with regard to this
software, including all implied warranties of merchantability and
fitness, in no event shall NAIST be liable for
any special, indirect or consequential damages or any damages
whatsoever resulting from loss of use, data or profits, whether in an
action of contract, negligence or other tortuous action, arising out
of or in connection with the use or performance of this software.

A large portion of the dictionary entries
originate from ICOT Free Software.  The following conditions for ICOT
Free Software applies to the current dictionary as well.

Each User may also freely distribute the Program, whether in its
original form or modified, to any third party or parties, PROVIDED
that the provisions of Section 3 ("NO WARRANTY") will ALWAYS appear
on, or be attached to, the Program, which is distributed substantially
in the same form as set out herein and that such intended
distribution, if actually made, will neither violate or otherwise
contravene any of the laws and regulations of the countries having
jurisdiction over the User or the intended distribution itself.

NO WARRANTY

The program was produced on an experimental basis in the course of the
research and development conducted during the project and is provided
to users as so produced on an experimental basis.  Accordingly, the
program is provided without any warranty whatsoever, whether express,
implied, statutory or otherwise.  The term "warranty" used herein
includes, but is not limited to, any warranty of the quality,
performance, merchantability and fitness for a particular purpose of
the program and the nonexistence of any infringement or violation of
any right of any third party.

Each user of the program will agree and understand, and be deemed to
have agreed and understood, that there is no warranty whatsoever for
the program and, accordingly, the entire risk arising from or
otherwise connected with the program is assumed by the user.

Therefore, neither ICOT, the copyright holder, or any other
organization that participated in or was otherwise related to the
development of the program and their respective officials, directors,
officers and other employees shall be held liable for any and all
damages, including, without limitation, general, special, incidental
and consequential damages, arising out of or otherwise in connection
with the use or inability to use the program or any product, material
or result produced or otherwise obtained by using the program,
regardless of whether they have been advised of, or otherwise had
knowledge of, the possibility of such damages at any time during the
project or thereafter.  Each user will be deemed to have agreed to the
foregoing by his or her commencement of use of the program.  The term
"use" as used herein includes, but is not limited to, the use,
modification, copying and distribution of the program and the
production of secondary products from the program.

In the case where the program, whether in its original form or
modified, was distributed or delivered to or received by a user from
any person, organization or entity other than ICOT, unless it makes or
grants independently of ICOT any specific warranty to the user in
writing, such person, organization or entity, will also be exempted
from and not be held liable to the user for any such damages as noted
above as far as the program is concerned.

-------------------------------------------------------------------------------
Okinawa dictionary is licensed as follows

Public Domain Dataです。使用・変更・配布に関しては一切の制限をつけません。
商品などに組み込むことも自由に行なってください。すでにいくつかの辞書には沖縄辞書が採用されています。
勝手ながら、沖縄辞書に寄贈された辞書も in the Public Domain' 扱いとさせていただきます。
```

### ONNX Runtime: licence, version, build and status

Owner: Wave 4-D. BooBoard runs ONNX models through sherpa-onnx (voice) and the `ai.onnxruntime` Java API
(translation). The runtime is pinned to 1.28.0; 1.29 and later ship HTTP telemetry and the INTERNET
permission, so they are not used.

#### Licence and source

- Project: ONNX Runtime (Microsoft), https://github.com/microsoft/onnxruntime
- Licence: MIT (`LICENSE` in the repository). Attribution: Copyright (c) Microsoft Corporation.
- Version: 1.28.0, tag `v1.28.0`.
- Distributed binary today: Maven `com.microsoft.onnxruntime:onnxruntime-android:1.28.0` (stock AAR).

#### Reduced build (plan Part 1): status

**Not built.** The reduced AAR needs the onnxruntime source at tag v1.28.0. On 2026-11-22 this PC
could not get it:

- `git clone https://github.com/microsoft/onnxruntime` (tag `v1.28.0`): "fatal: could not read Username ... terminal prompts disabled";
- `https://github.com/microsoft/onnxruntime` and its release, tag, archive and `codeload` URLs, and the GitHub API
  (`api.github.com/repos/microsoft/onnxruntime`): all HTTP 404, while other GitHub repositories
  (for example `flutter/flutter`, `k2-fsa/sherpa-onnx`) answer 200.

So the source is not reachable from here (repository unavailable or blocked). What is ready:

- `tool/onnxruntime/model_ops.py`: lists the 39 operators used by the 30 staged models
  (`tool/onnxruntime/model_ops.txt`). Read only.
- `tool/onnxruntime/check_aar.ps1`: the three checks (symbol version per ABI, no telemetry classes and no
  permissions, every model operator in the config). It passes checks 1 and 2 on the stock 1.28.0 AAR
  and fails check 3 (no `ops.config` yet).
- `tool/onnxruntime/build_android.ps1`: a draft of the build (MinSizeRel, arm64-v8a, armeabi-v7a, x86_64,
  NDK 28.2, `--build_java`, `--include_ops_by_config`, `--skip_tests`). **Not run, not tested.** Check the flags
  against `build.bat --help` on the real checkout.
- `tool/onnxruntime/ops.config`: not generated. It must come from `tools/python/create_reduced_build_config.py`
  in the 1.28.0 source, over the staged models. The staged folder is read only.

Toolchain on this PC, for the next attempt: NDK 28.2.13676358 installed, CMake 3.22.1 in the Android SDK,
Ninja (Python 3.10 Scripts), Python 3.13 with `onnx` 1.23.2 installed, JDK 17. The source must be
obtained first (a mirror or the GitHub download from a machine that can reach it).

Until the reduced build passes `check_aar.ps1`, `android/app/build.gradle.kts` keeps the stock dependency.

#### Stock 1.28.0 AAR (baseline, measured)

From the Gradle cache (`onnxruntime-android-1.28.0.aar`, 45,634,470 bytes):

| ABI | `libonnxruntime.so` bytes | SHA-256 |
|---|---|---|
| arm64-v8a | 28,637,280 | F826D8EFB03ADF0A84F10E7BA408F9D4CD11B0A2CCD8D08AEB0F7451FB50CACC |
| armeabi-v7a | 20,388,560 | 19E4AB7B9C374D9A3900A6382B2E4978267B8D4B874596C64C8BF49BB7560B47 |
| x86 | 34,557,568 | F089A53F1A02F26CB85FC52626C6A652B04D4A9ABE319AF64AD8623F2C00739E |
| x86_64 | 34,640,104 | 8A31FEB45126D981FFAC430BD10BC66CFA1036E0864A9FBD80A94121F3085800 |

The stock AAR exports `OrtGetApiBase@@VERS_1.28.0` (checked with `llvm-readelf --dyn-syms` on arm64), has no
`ai/onnxruntime/telemetry` classes and declares no `<uses-permission>`. The `libonnxruntime4j_jni.so` files
are not part of the reduced build and are not listed here.

#### Build flags (target)

The planned reduced build uses `--config MinSizeRel --android --android_api 26 --build_java
--include_ops_by_config <ops.config> --skip_tests`. None of these adds telemetry or network code. No
`--minimal_build`: the packs ship `.onnx` files that sherpa-onnx loads through the ONNX loader.
The `check_aar.ps1` run is the gate for telemetry and permissions.

#### Reduced build: results

Not yet produced. When it exists, record here per ABI: the byte size and SHA-256 of `libonnxruntime.so`, the
size before (above) and after, the `check_aar.ps1` output, and the APK size (arm64 target <= 60 MB, down from
79.0 MB).

## Algorithm references (no code copied)

The swipe decoder in `lib/src/engine/gesture/` is an original implementation of ideas from:
- **SHARK²**: P.-O. Kristensson and S. Zhai, "SHARK2: A Large Vocabulary Shorthand Writing System for Pen-Based Computers", ACM UIST 2004. Template matching through key centres, equal arc-length resampling, location and shape channels.
- **FlorisBoard `StatisticalGlideTypingClassifier`** (https://github.com/florisboard/florisboard, Apache-2.0): Gaussian channel likelihoods with a language-model prior, and pruning by first and last key. If any of its code is ever ported, keep the Apache-2.0 notice and attribute it here.

## Test-only data (not shipped in the app)

- `test/engine/gesture/fixtures/en_words.tsv.gz`: the 50,000 most frequent plain entries of AOSP LatinIME `en_US_wordlist.combined` (Apache-2.0, The Android Open Source Project), stored as `word<TAB>frequency` and gzip-compressed. Used only by the gesture accuracy and latency tests.

Rules for adding data:
- Only CC0, CC-BY, Apache-2.0, BSD, MIT, OFL, Unicode or GPL-3-compatible sources.
- "GPLv2-only" and anything non-commercial (NC) are not allowed.
- Record the exact source URL, version and license here before committing the data.
- Each wave's agents write `docs/notices/<area>.md`; the orchestrator folds them into this file after merging and deletes them.
