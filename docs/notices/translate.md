# Notices: offline translation (Wave 3-T)

BooBoard's translation runs OPUS-MT neural models on the phone with ONNX Runtime. The app never bundles
a model: each direction is a signed model pack that the user imports (see `tool/packs/translate/`).

## Engine

| Component | Version | Licence | Use |
|---|---|---|---|
| ONNX Runtime (`com.microsoft.onnxruntime:onnxruntime-android`, JVM tests: `onnxruntime`) | 1.28.0 | MIT | Runs the encoder and decoder |
| OPUS-MT model architecture (Marian) | - | MIT (Marian NMT) | Model graph |

The SentencePiece model file (`source.spm`) is read by our own minimal reader
(`SentencePieceModel.kt`); no SentencePiece library is used.

## Models

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

## Tokeniser

Each model's `source.spm` and shared `vocab.json` come unchanged from the same upstream repository.
Tokenisation is checked against the sentencepiece library on 102 test sentences (0 mismatches).
