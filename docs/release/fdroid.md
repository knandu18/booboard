# F-Droid

Status: **draft, not submitted.** The recipe is `metadata/io.github.knandu18.booboard.yml`. The file is named after the
applicationId, and `set_application_id.ps1` renames it when the id changes.

Nothing here has been run through `fdroidserver`. `fdroid lint`, `fdroid readmeta`, `fdroid checkupdates` and
`fdroid build` are still to do, and they need the fdroiddata repository and a Linux or Docker build environment.

## Metadata in this repository

- `fastlane/metadata/android/` uses the F-Droid / Triple-T layout (`title.txt`, `short_description.txt`,
  `full_description.txt`, `changelogs/<versionCode>.txt`, `images/`). `en-US` is complete. `es-ES`, `fr-FR`,
  `de-DE`, `pt-BR`, `id` and `hi-IN` have a title and a short description only; they are machine-made drafts.
- `images/icon.png` is the 512 px store icon and `images/featureGraphic.png` the 1024 × 500 feature graphic,
  both copied from `docs/brand/` (not redrawn).
- Changelog files are named after the pubspec build number (`1.txt` for `1.0.0+1`). F-Droid names the changelog
  after the versionCode of the build; the split-ABI offset (`2001` for arm64 in foss) must be checked when the
  recipe is tested, and the file renamed if F-Droid expects it. Not verified.
- No screenshots yet. Take them on a device or emulator, in the order listed in `store-listing.md`.

## Recipe (what it does)

- Flutter 3.50.0 through a `flutter` srclib (the version in `tool/release/flutter-version.txt`). If fdroiddata
  has no 3.50.0 entry, the srclib file has to be added there first.
- NDK `r28c` (NDK 28.2.13676358, the version pinned in `build.gradle.kts`). Check the letter against the
  fdroiddata NDK list.
- Java 17.
- The build command is exactly the one in `build_release.ps1`:
  `flutter build apk --release --flavor foss --split-per-abi --target-platform android-arm64`. F-Droid builds
  one ABI here; the arm64 APK is the reference for the reproducible check.
- Output: `build/app/outputs/flutter-apk/app-arm64-v8a-foss-release.apk`.
- The `play` flavour is never built for F-Droid.

## The things F-Droid will object to

1. **Committed prebuilt binaries.** `android/app/src/main/jniLibs/*/libsherpa-onnx-jni.so` is a prebuilt sherpa-onnx
   JNI library, patched to link against `VERS_1.28.0` (`tool/patch_sherpa_ort_version.dart`). F-Droid's policy
   requires source for anything shipped, or the binary is removed and the app may no longer work. The rebuild
   notes are in `docs/notices/voice.md`. The onnxruntime build needed to make the reduced operator set is blocked
   from this PC (a GitHub 404), so `libonnxruntime.so` comes from the Maven AAR, which F-Droid accepts as a
   dependency only if it is built from source or allowed by the reviewers. **This may delay inclusion.**
2. **Maven dependency `onnxruntime-android` 1.28.0.** Pinned on purpose (1.29 adds telemetry and INTERNET).
   It is a dependency, not a committed binary. Ask the reviewers.
3. **Dictionary and model data.** Dictionaries, layouts, emoji and translit data are in `assets/`. Their licences
   are in `docs/notices/`. Mozc (Japanese) and IPAdic items, if any ship in the foss build, need a check against
   Agent A's licence audit before the AntiFeatures and the `rm` list are final. Nothing is declared "none" yet.
4. **Chinese and Japanese packs** are downloaded by the user (from the packs screen), not built in. F-Droid
   reviewers may ask where those files come from; the answer is the user's own file import in the foss build.

## Fallback if F-Droid review stalls on the binaries

1. Publish the release APKs on GitHub (signed with the developer's release key, fingerprint in the release notes
   and in `RELEASING.md`). Users verify the SHA-256 sums in `SHA256SUMS.txt`.
2. Host an own F-Droid repository with `fdroidserver`, signed with its own key:

```
fdroid init                       # once: creates config.yml and a keystore (keep it outside the repo)
# copy the signed release APKs into repo/
fdroid update --create-metadata   # builds the index (no build is run)
fdroid deploy                     # needs an rsync target in config.yml; fill in the user's host
```

   `config.yml` and the keystore are secrets: keep them outside the repository and never commit them.
   The fingerprint of the repo signing key is what users add to F-Droid. Source: the fdroidserver documentation
   (not fetched in this run).
3. Register the same release key for Android developer verification (see `developer-verification.md`).

## Build reproducibility

`tool/release/verify_reproducible.ps1` builds the foss arm64 APK twice, from clean clones in different folders, and
compares the APK entry by entry. The result is in `RELEASING.md`, "Verification results". If the result is not
identical, F-Droid cannot keep the developer's signature, and it will sign the build itself.

## What the user does

- Creates the F-Droid merge request in `fdroid/fdroiddata` with the recipe, after the applicationId swap and the
  first tag.
- Answers the reviewers' questions on the binaries and the data licences.
- Decides between waiting for the source rebuild of the two binaries and the fallback above.
