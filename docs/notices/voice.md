# Voice typing: third-party notices (Wave 3-D)

Everything below ships with the app or is staged for the orchestrator to sign as voice packs. Nothing here
is downloaded by the app. Voice typing works in English only: the one voice pack is Parakeet (section 2).

## 1. sherpa-onnx native library and Kotlin API

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

### Build from source (for Wave 5's reproducible builds; not yet run)

1. Get the sources of the same tag: `https://github.com/k2-fsa/sherpa-onnx/archive/refs/tags/v2.0.1.tar.gz`.
2. Get onnxruntime 1.28.0 for Android from Maven (`onnxruntime-android-1.28.0.aar`) and unzip it. Its `headers/`
   folder is the include dir, and `jni/<abi>/libonnxruntime.so` is the lib dir for each ABI.
3. Install the Android NDK matching `flutter.ndkVersion` and set `ANDROID_NDK`.
4. From the source root run, for each ABI, for example:
   `SHERPA_ONNXRUNTIME_LIB_DIR=<aar>/jni/arm64-v8a SHERPA_ONNXRUNTIME_INCLUDE_DIR=<aar>/headers ./build-android-arm64-v8a.sh`
   (`build-android-armv7-eabi.sh` and `build-android-x86-64.sh` for the others). The scripts use CMake and build
   the shared library, which links the AAR's `libonnxruntime.so`.
5. Take `libsherpa-onnx-jni.so` from the build output and compare its SHA-256 with the table above.

## 2. Parakeet TDT 0.6B v2 (English speech recognition, int8)

| Item | Value |
|---|---|
| Model | NVIDIA Parakeet TDT 0.6B v2 (English), int8 ONNX export by the sherpa-onnx project |
| Licence | CC BY 4.0 (weights, NVIDIA: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2); the export scripts are Apache-2.0 (sherpa-onnx). NVIDIA does not endorse BooBoard or this pack. |
| Attribution | "parakeet-tdt-0.6b-v2" by NVIDIA, licensed under CC BY 4.0. Converted to int8 ONNX by sherpa-onnx; BooBoard renames no files and adds Silero VAD (section 3). |
| Source | sherpa-onnx release `asr-models`: `sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2` (asset dated 2026-11-07) |
| Archive SHA-256 | `6fc4426b54aa549a0019b8a75b8dea59164e71790a37ac56a045ad57f915f714` (482,440,461 bytes) |
| Files in a pack | `encoder.int8.onnx` (652,282,309), `decoder.int8.onnx` (7,257,753), `joiner.int8.onnx` (1,739,080), `tokens.txt` (9,384), `silero_vad.onnx` |
| Languages | en only. Pack id `voice-parakeet-en`, engine `sherpa-onnx-nemo-transducer` (the only voice pack; voice typing works in English only) |

## 3. Silero VAD (voice activity detection)

| Item | Value |
|---|---|
| Model | Silero VAD (`silero_vad.onnx`, the sherpa-onnx release file of that name) |
| Licence | MIT (snakers4/silero-vad; confirm on the model card) |
| Source | sherpa-onnx release `asr-models`, `silero_vad.onnx` (2025-07-11) |
| SHA-256 | `9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6` (643,854 bytes; matches the API digest) |

## 4. Later packs (assessed, not built)

- **Dolphin** (Apache-2.0 per the brief; verify on the model card): sherpa-onnx has an offline Dolphin config (`OfflineDolphinModelConfig`). Hindi, Urdu and Arabic coverage to be checked
  on the model card before a pack is staged. Not built in Wave 3.
- **Moonshine** (licence to verify on the model card, believed MIT): English-only. sherpa-onnx has an offline Moonshine config (`OfflineMoonshineModelConfig`). Useful as a small English pack. Not built in Wave 3.
