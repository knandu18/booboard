# Chinese data notices (Wave 4-A)

The Chinese dictionary pack `dict-zh-rime-ice` is built from the sources below by
`tool/packs/chinese/stage_rime_ice.ps1` and `tool/chinese/build_zh_dict.dart`. The app never bundles
or downloads the data; the pack is signed and installed like the other model packs.

## rime-ice (雾凇拼音)

- Source: https://github.com/iDvel/rime-ice, commit `927e1cf1d3eeb9bf4be85e3f684dba4dd485b6f6`
  (2026-11-11), files `cn_dicts/base.dict.yaml`, `cn_dicts/ext.dict.yaml`, `cn_dicts/8105.dict.yaml`.
- Licence: GPL-3.0 (compatible with BooBoard's GPL-3.0-or-later).
- Its own base words come from the 华宇野风 system dictionary, THUOCL (Tsinghua), a modern Chinese
  common word list, and the Tencent word vectors; rime-ice credits these in its header.
- Used: the word rows of base (weight 1000 and above) and ext (flat weight 100), and the 8105
  character readings. Derived: the pinyin index, per-source log probabilities, initials.
- Not used: `tencent.dict.yaml` (no pinyin column, flat weights, and the budget for the pack is
  600k words), `others.dict.yaml`, and the professional or sentence dictionaries.

## OpenCC (Simplified to Traditional, Taiwan standard)

- Source: https://github.com/BYVoid/OpenCC, commit `fae2a0a911c30764e669a7d8b0591cd8e852934a`,
  `data/dictionary/STPhrases.txt`, `STCharacters.txt`, `TWPhrases.txt`, `TWVariants.txt`.
- Licence: Apache-2.0 (Copyright BYVoid and contributors). The pack does not ship the upstream
  files: it ships `s2twp.tsv`, a derived table holding the first target of each line in the four
  files, in the order s2twp uses.

## Attribution

Chinese word data from rime-ice (GPL-3.0), which carries the 华宇野风, THUOCL, 现代汉语常用词表 and
Tencent word vector sources; OpenCC conversion tables (Apache-2.0), BYVoid and contributors.

## Files shipped in the pack

- `zh.kdict` (about 35 MB; 587,641 entries: 578,943 words and 8,698 characters).
- `s2twp.tsv` (about 0.5 MB).

## Layout

- `assets/layouts/pinyin_zh.json`: QWERTY letters with Chinese punctuation (no data).
- Test corpus `test/engine/lang/chinese/golden_zh.txt`: 300 common words (base weight 100000 and
  above) drawn from rime-ice base by `tool/chinese/build_zh_dict.dart --golden`.
