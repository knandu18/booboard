# Extra data packs: Indic languages and more translation pairs

Owner: Wave 5-C. Status as of 2026-11-23: **nothing in this file is built or shipped.** The Indic pack was not
started, because the Wave 5 brief puts it after the core work and no data source has been checked yet. The
translation pairs have staging scripts already (`tool/packs/translate/`), and I did not build them.

## Indic languages (gu, kn, ml, pa, or)

Status: **planned, not built, no language finished.** Plan for the first one (Gujarati, `gu`, suggested because
the Wave 3 registry has a template for it):

1. Confirm the licence of the source before any download. Candidate sources named in the brief:
   - Aksharantar (AI4Bharat) transliteration pairs, which cover these languages. The brief says CC0 or CC-BY.
     **Not verified in this run.** Read the dataset card before use.
   - Wikipedia word-frequency lists, CC BY-SA 4.0. Share-alike: a pack built from them carries the share-alike
     obligation, which must be stated in this file and in the pack's `license` field.
2. Stage with a script `tool/packs/indic_extra/stage_gu.ps1`, on the same pattern as `tool/packs/chinese/`.
   The script prints the `make_pack.dart` command with `--key <signing key .pem>`.
3. Record the exact source URL, revision and checksum here before the pack is built.
4. Check the pack with `tool/make_pack.dart --verify` and on the Model packs screen.

Plan for the rest: the same steps for kn, ml, pa and or, one language at a time. Do not ship a half-checked
dataset.

## More translation pairs (Opus-MT, staging only)

The pairs below already have entries in `tool/packs/translate/models.json`, so `stage.ps1` can build them.
Nothing is built. Sizes are the sums of the pinned files' declared sizes in `models.json`. Licences were
checked against the upstream Helsinki-NLP model cards on 2026-11-23 (`license:` tag on the Hugging Face model
page). The Xenova ONNX files are re-exports of those models.

| Pair | Source model (`repo`) | Upstream licence | Declared size (bytes) | Size (MB) |
|---|---|---|---|---|
| en-fr | `Xenova/opus-mt-en-fr` | Apache-2.0 | 109,708,501 | 110 |
| fr-en | `Xenova/opus-mt-fr-en` | Apache-2.0 | 109,732,503 | 110 |
| en-de | `Xenova/opus-mt-en-de` | **CC-BY-4.0** (attribution required) | 108,177,271 | 108 |
| de-en | `Xenova/opus-mt-de-en` | Apache-2.0 | 108,205,627 | 108 |
| en-pt | `Xenova/opus-mt-en-ROMANCE` (multi-target model, needs a target token) | Apache-2.0 | 115,479,065 | 115 |
| pt-en | `Xenova/opus-mt-ROMANCE-en` | Apache-2.0 | 115,502,939 | 116 |
| en-hi | `Xenova/opus-mt-en-hi` | Apache-2.0 | 113,010,096 | 113 |
| hi-en | `Xenova/opus-mt-hi-en` | Apache-2.0 | 112,367,473 | 112 |
| en-ru | `Xenova/opus-mt-en-ru` | Apache-2.0 | 114,089,599 | 114 |
| ru-en | `Xenova/opus-mt-ru-en` | **CC-BY-4.0** (attribution required) | 114,366,987 | 114 |

Notes for building any of them:

- The CC-BY-4.0 pairs (en-de and ru-en) need attribution in the pack's `license` field and in
  `THIRD_PARTY_NOTICES.md`. `models.json` already gives `CC-BY-4.0` for `translate-en-de` and `translate-ru-en`.
  Attribution is still to be written.
- `en-pt` uses a multi-target model. The engine must send the target token, which `models.json` describes as
  `target_token`. The engine's support for that is not tested.
- These are about 110 MB each. Each one added to the `play` flavour is another asset pack (see
  `docs/release/asset-packs.md`). Sum before adding them: the on-demand total limit is 30 GB, so this is
  not a limit problem, but the download size and the download-time dialog are.

## Checked in this file

- Nothing is built, so there are no pack sizes beyond the declared ones.
- No pack from this file is in the release.
