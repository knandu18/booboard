# ONNX Runtime: licence, version, build and status

Owner: Wave 4-D. BooBoard runs ONNX models through sherpa-onnx (voice) and the `ai.onnxruntime` Java API
(translation). The runtime is pinned to 1.28.0; 1.29 and later ship HTTP telemetry and the INTERNET
permission, so they are not used.

## Licence and source

- Project: ONNX Runtime (Microsoft), https://github.com/microsoft/onnxruntime
- Licence: MIT (`LICENSE` in the repository). Attribution: Copyright (c) Microsoft Corporation.
- Version: 1.28.0, tag `v1.28.0`.
- Distributed binary today: Maven `com.microsoft.onnxruntime:onnxruntime-android:1.28.0` (stock AAR).

## Reduced build (plan Part 1): status

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

## Stock 1.28.0 AAR (baseline, measured)

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

## Build flags (target)

The planned reduced build uses `--config MinSizeRel --android --android_api 26 --build_java
--include_ops_by_config <ops.config> --skip_tests`. None of these adds telemetry or network code. No
`--minimal_build`: the packs ship `.onnx` files that sherpa-onnx loads through the ONNX loader.
The `check_aar.ps1` run is the gate for telemetry and permissions.

## Reduced build: results

Not yet produced. When it exists, record here per ABI: the byte size and SHA-256 of `libonnxruntime.so`, the
size before (above) and after, the `check_aar.ps1` output, and the APK size (arm64 target <= 60 MB, down from
79.0 MB).
