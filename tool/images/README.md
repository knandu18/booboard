# Images test pack (dev-signed)

`make_image_pack.ps1` builds `images-lcm-dreamshaper-v7.boopack` from local files only (no downloads) and signs it
with the **dev** pack key (`%USERPROFILE%\.booboard\keys\pack-dev.pem`; keys from a `release` folder are refused).
For debug builds and tests; a release pack needs the release key, the real licence text and the use rules.

```
powershell -ExecutionPolicy Bypass -File tool\images\make_image_pack.ps1 [-LicenseFile ..] [-UseRulesFile ..]
```

Defaults sit under `%USERPROFILE%\.booboard\` (weights in `packs\download\images`, engine in
`tools\sdcpp\build-win\bin\sd-cli.exe`, output in `packs\signed\dev-signed`); every path is a parameter.

## Pinned inputs

- stable-diffusion.cpp `master-1133-52491bd` (ggml `eeda9ec`), built for Windows.
- LCM-Dreamshaper v7 `SimianLuo/LCM_Dreamshaper_v7` at `a85df6a` (diffusers weights, no safety checker).
- TAESD `madebyollin/taesd` at `614f768` (MIT). Hashes: `PINNED-images.json` next to the weights.

## Recipe

1. Hard-link a temporary diffusers folder **without `vae/`** (unet, text_encoder, tokenizer, scheduler,
   `model_index.json`). The converter treats the VAE as optional.
2. `sd-cli -M convert -m <folder> --type f16`, then `sd-cli -M convert -m <f16 gguf> --type q8_0`. Go to f16 first:
   straight from f32 the convolutions stay f32. The engine never quantizes convolutions, so they stay f16.
3. `gguf_list_tensors.py` (standard library only) checks that no `first_stage_model.*` or `vae.*` tensor is left.
4. Stage `model/model.gguf`, `model/taesd.safetensors`, `LICENSE.txt`, `USE-RULES.txt`, then
   `tool/make_pack.dart` signs (kind `image`, engine `sdcpp-gguf`, licence `CreativeML-OpenRAIL-M`) and verifies it.

Without `LICENSE.txt` and `USE-RULES.txt` inputs the script writes clearly marked placeholders.

## Why no full VAE

TAESD decodes the picture (about half the time of the full VAE, nearly the same look), so the 0.17 GB full VAE
inside the GGUF is never used. Run with `--taesd model/taesd.safetensors --sampling-method lcm --steps 4
--cfg-scale 1 -W 512 -H 512`. The no-VAE q8_0 file gives a pixel-identical picture to the old file with the VAE.
