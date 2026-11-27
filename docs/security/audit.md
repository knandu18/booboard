# Security audit of BooBoard (Wave 5-A)

Date: 2026-11-23. Scope: the whole tree at `main` plus Wave 5 branches as of the Wave 5 briefs (`c514981`). Method: code reading of the high-risk files, parser fuzzing and corrupt-input tests, licence and dependency audit, network audit of a release APK, and CI hardening. The `security-review` skill was **not** run; the review is manual. See "Gaps".

Companion documents: `threat-model.md`, `licences.md`, `../brand/trademark-check.md`, `../../SECURITY.md`.

## Summary

- **Release blocker:** the release build is signed with the debug key (SEC-02, Agent B's file).
- **No finding in the core privacy promises checked:** no INTERNET permission in the release manifest or APK (verified on the Wave 4 APK), no network or telemetry class in the dex, `allowBackup` and cloud backup off, no typed text in logs, voice and translation write nothing to disk, the backup format and crypto are sound, and the Keystore key is unlocked-device only.
- **Findings:** 20 in total. 1 High (release blocker), 4 Medium, 10 Low, 4 Info. Each has an owner and, where needed, an exact patch below. **No code file outside my ownership was changed.** Three findings are pinned by skipped tests.

## Status of the patches (2026-11-24)

User decisions: D1 wider sensitive-field rule, D2 confirm before a restore changes privacy settings, SEC-03 AAD now.

- **Fixed:** SEC-01 (P1), SEC-03 (P3: name bound as AAD, format version 2, version 1 unreadable), SEC-04 (P4), SEC-05 (a file path that is a folder of another file is rejected), SEC-07 (P5), SEC-09, SEC-10 (inflate capped at 64 MiB, section lengths checked), SEC-11 (header tables checked at open), SEC-12 (P2: `isSensitive` also covers no-personalised-learning and no-suggestions fields), SEC-13 (P6: wrapper scripts tracked, `distributionSha256Sum` pinned to the -all zip checksum published on gradle.org and equal to the zip on this PC; the wrapper jar is not pinned), SEC-15 (only `content://` URIs), SEC-17 (D2: `lib/src/security/backup/privacy_changes.dart` and a confirmation dialog in `backup_screen.dart`; the dialog itself has no widget test).
- **Not done:** SEC-06 (making a locked device throw instead of reading as empty changes every caller of `SecureBlobStore.read`; needs its own design), SEC-08 (export overwrites the chosen file; a UI warning), SEC-14, SEC-16, SEC-18, SEC-19, SEC-20 (Info, accepted or later). D3 is done (release pack key). D4 unchanged (R8 strips v, d, i only).

## Findings (highest first)

Owner key: O = orchestrator (`lib/src/core`, `lib/src/security`, `lib/src/engine`, `lib/src/keyboard`, `android/**` except what a brief names); B = release engineering; C = data packs. "Test" names the test that pins it (`skip` = currently fails).

| ID | Severity | File:line | Finding | Patch or fixed in | Owner | Test |
|---|---|---|---|---|---|---|
| SEC-02 | High (release blocker) | `android/app/build.gradle.kts:36` | Release build signed with the debug key (`signingConfig = signingConfigs.getByName("debug")`). Any APK users install can be re-signed by anyone who has the debug key (it is public). | Agent B's release signing config (keystore from env or a path outside the repo). | B | none (release gate) |
| SEC-01 | Medium | `lib/src/security/backup/backup_restore.dart:146-241` | Restore writes learned, shortcuts, clipboard, emoji and themes **before** `BooBoardSettings.fromJson` validates the settings section (line 241). A malformed settings section leaves a half-applied restore; in Replace mode the learned blobs are deleted first. | Parse first, then write. See patch P1. | O | none yet (add a restore test) |
| SEC-12 | Medium | `lib/src/core/input_field_info.dart:288` | `isSensitive` is `isPassword` only. The plan says no-personalised-learning and no-suggestions fields also get no popups, no voice and FLAG_SECURE. Today these fields get suggestions and learning turned off, but FLAG_SECURE (`input_controller.dart:94`), voice (`voice_feature.dart:23`) and translation (`selection_translate.dart:61`) still run. | See patch P2, or the user decides to keep the narrower rule (decision D1). | O | `test/security/sensitive_field_test.dart` (skip) |
| SEC-13 | Medium | `android/.gitignore:4-5` | `gradlew` and `gradlew.bat` are gitignored, and `gradle-wrapper.jar` is not tracked. A fresh clone cannot run `./gradlew` until a Flutter build injects the wrapper (Flutter does this). The wrapper distribution has no `distributionSha256Sum`, so the download is not verified. | Track the wrapper scripts and jar, add `distributionSha256Sum` to `gradle/wrapper/gradle-wrapper.properties`. CI now runs `flutter build apk --config-only` first. | B (or O) | none |
| SEC-17 | Medium (decision) | `lib/src/security/backup/backup_restore.dart:241-243` | Restoring the settings section replaces every section (`SettingsSection.all`), including app lock, incognito lists and the learning switch, with no confirmation of those specific changes. A backup can silently turn protections off. | Decision D2. Patch: the preview lists these settings and asks for confirmation. | O (UI in `lib/src/app/privacy`) | none |
| SEC-03 | Low | `android/app/src/main/kotlin/app/booboard/keyboard/security/SecureStore.kt:171, 196` | The ciphertext is not bound to its blob name (no AAD). A process with write access to `noBackupFilesDir` (root, or a debuggable build) can copy `learned_en.bin` over `clipboard.bin` and it decrypts. Requires the attacker to already have file access. | Pass the name as AAD in `sealOnce` and `decryptOrThrow`, and bump the format version to 2. No shipped data exists yet, so do it before release. See patch P3. | O | none |
| SEC-04 | Low | `android/.../packs/PackStore.kt:90-91` | `manifest.files.sumOf { it.size }` can overflow `Long`, so the 2 GiB cap is bypassed (a total that wraps to a negative value passes both checks). Writes are still limited by the bytes actually read, and only a signed pack can carry such a manifest. | Use `Math.addExact` and a per-file `size <= maxBytes` check. See patch P4. | C | none (Kotlin test needed) |
| SEC-05 | Low | `android/.../packs/PackStore.kt:100-103` | A manifest with a file `a` and another file `a/b` makes the second `outputStream` throw `FileNotFoundException`, which is not a `PackException`, so the import fails with an uncaught type. Exact duplicate names are rejected; this prefix collision is not. | Reject any path that is a prefix of another path (`path + "/"`). | C | none |
| SEC-06 | Low | `lib/src/security/backup/backup_restore.dart:139-141`; `lib/src/core/secure_blob_store.dart:28-34`; `SecureStore.kt:105-112` | A corrupt learned blob reads as null, the same as a locked device, so a merge restore throws `RestoreLockedException` ("phone is locked") forever. `PlatformSecureBlobStore.read` swallows every error. | Make `SecureStore.read` throw LOCKED when the key is unavailable, and let `PlatformSecureBlobStore.read` rethrow only that code. | O | none |
| SEC-07 | Low | `android/.../security/backup/BackupCrypto.kt:50` | `MAX_ITERATIONS = 10_000_000` from an unauthenticated header. A crafted `.koshabackup` takes minutes of PBKDF2 before it is rejected. The user chooses the file, so the impact is a stalled import. | Lower the cap to 2,000,000 (the default 600,000 stays; existing files still open). | O | none |
| SEC-08 | Low | `android/.../security/backup/BackupDocuments.kt:48` | Export uses mode `"wt"` on the chosen document: the old file is truncated before the write. A failed write loses the previous backup the user chose to overwrite. | Warn in the UI when the target exists, or write a new document name. | O | none |
| SEC-09 | Low | `lib/src/engine/lang/indic/translit_table.dart:44-47` | The entry count from the header is trusted: `Uint8List(count)` allocates before any bounds check. A corrupt bundled file asks for up to 4 GiB. In a test run on this Windows PC the allocation succeeded (lazy commit), and the parse then failed with `RangeError`. On a phone the allocation can fail. Truncated input throws `RangeError`, not `FormatException`. | Check `count <= (length - 9) ~/ 3` first, and bounds-check each read. | O | `corrupt_input_test.dart` (2 skipped) |
| SEC-10 | Low | `lib/src/engine/dictionary/mdict_lexicon.dart:60, 62-80` | Truncated mdict throws `RangeError` (`sublistView`) instead of `FormatException`. `ZLibCodec().decode` has no output-size cap (zlib bomb). Bundled assets only, and callers catch `Object`. | Validate section lengths against the file length before `take()`; cap the inflated size. | O | `corrupt_input_test.dart` (1 skipped) |
| SEC-11 | Low | `lib/src/engine/lang/chinese/zh_dictionary.dart:70-77` | Header fields (key count, offsets, blob starts) are not checked against the file size at open. Only the total length is checked. A pack with matching length and bad offsets opens, and each lookup throws `RangeError`. Callers catch it, so the feature silently degrades. | Check every field offset and count against `bytes.length` in `fromBytes`. | O | `corrupt_input_test.dart` (1 skipped) |
| SEC-15 | Low | `android/.../security/backup/BackupDocuments.kt:48, 59` | `openOutputStream` and `openInputStream` accept any URI scheme the Dart side passes back (for example `file://`). | Accept only `content://` URIs. | O | none |
| SEC-20 | Info | `android/.../packs/PackStore.kt:44-57` | `open()` checks only the signed manifest, not each installed file's hash. A process that can write the pack folder can swap a model file after install. | Re-hash on open, or accept the risk (needs root). | C | none |
| SEC-14 | Info | `android/app/proguard-rules.pro:4-14` | The plan says R8 strips `Log.*`. The rule strips `v`, `d` and `i` only; `w` and `e` remain. Kotlin `w`/`e` calls log exception class names only, so nothing typed leaks. | Keep the rule and correct the plan, or add `w` and `e` if the owner prefers. | O | none |
| SEC-16 | Info | `lib/src/security/backup/backup_collect.dart`, `BackupCrypto.kt:141-149` | The passphrase is a Dart/Kotlin `String`, which cannot be zeroed. Only the derived key and the `char[]` copy are cleared. Residual memory exposure. | None practical; document. | — | none |
| SEC-18 | Info | `lib/src/features/emoji/emoji_data.dart:111,137`; `japanese_dictionary.dart:102-103`; `translit_table.dart:37` | `gzip.decode` has no output cap. The inputs are bundled or signed packs, so the attacker would need the signing key. | Cap inflated size with a streaming decoder if packs ever come from outside. | O | none |
| SEC-19 | Info | `lib/src/engine/gesture/isolate_gesture_decoder.dart:331` | Debug and profile builds print the decoder's error text (`${message[2]}`). Release builds print nothing (`BooBoardLog` is a no-op). The text is decoder error data, not typed text, as far as read. | Keep errors to exception class names, like the rest of the app. | O | none |

Patches for the orchestrator (exact text, not applied):

- **P1 (SEC-01):** in `backup_restore.dart`, move `final parsed = BooBoardSettings.fromJson(incomingSettings);` (line 241) to the top of `apply()`, guarded by `include.contains(BackupSection.settings) && contents.settings != null`. Then replace the later `settings.update` block with `if (parsed != null) { await settings.update((_) => parsed, sections: SettingsSection.all); settingsApplied = true; }`. Any `FormatException` from `fromJson` now throws before the first write.
- **P2 (SEC-12):** `lib/src/core/input_field_info.dart:288`: `bool get isSensitive => isPassword || noPersonalizedLearning || noSuggestionsFlag;`. Then un-skip `test/security/sensitive_field_test.dart`. Check the keyboard's popups and voice tests still pass.
- **P3 (SEC-03):** `SecureStore.kt`: change `seal(data)` to `seal(name, data)` and `sealOnce(data)` to `sealOnce(name, data)`; add `cipher.updateAAD(name.toByteArray(Charsets.US_ASCII))` right after each `cipher.init` (lines 171 and 196 region); bump `FORMAT_VERSION` to 2 and treat version 1 as unreadable (no shipped data).
- **P4 (SEC-04):** `PackStore.kt:90`: `val total = manifest.files.fold(0L) { acc, f -> Math.addExact(acc, f.size) }` inside a `try` that maps `ArithmeticException` to `PackException("too_large", ...)`; add `if (f.size > maxBytes) throw PackException("too_large", "file too large")` in the manifest loop.
- **P5 (SEC-07):** `BackupCrypto.kt:50`: `private const val MAX_ITERATIONS = 2_000_000`.
- **P6 (SEC-13):** `android/.gitignore`: delete lines 4-5. Commit `gradlew`, `gradlew.bat` and `gradle/wrapper/gradle-wrapper.jar`, and add `distributionSha256Sum=<sha of gradle-9.5.0-all.zip>` to `gradle/wrapper/gradle-wrapper.properties` (take the value from the official Gradle checksum file, not from this PC).

## Decisions for the user

- **D1 (SEC-12):** align the sensitive-field rule with the plan (P2), or keep password-only.
- **D2 (SEC-17):** require a confirmation that names the privacy settings a restore would change.
- **D3:** the trusted pack key (`PackKeys.kt`) is the dev key. Rotation is Agent C's work and must happen before any public build.
- **D4 (SEC-14):** keep the R8 rule and correct the plan text, or add `w` and `e`.

## Coverage

| Area | Result |
|---|---|
| Manifest (exported components, `allowBackup`, `fullBackupContent`, `dataExtractionRules`, `usesCleartextTraffic`, `debuggable`, intent filters) | No finding. The release manifest removes INTERNET, ACCESS_NETWORK_STATE and ACCESS_WIFI_STATE. The IME service is protected by `BIND_INPUT_METHOD`. `MicPermissionActivity` is not exported. The testbed is only in `src/debug`. |
| Release APK (Wave 4 arm64 build, read-only) | `tool/audit/network_audit.sh`: pass. Permissions: RECORD_AUDIO, USE_BIOMETRIC, USE_FINGERPRINT, VIBRATE and the app-private receiver permission. Zero `java.net` references in the dex. Dex scan confirmed working on a positive control. |
| R8 and ProGuard | SEC-14 (Info). Keep rules for the bridge, the IME service and the native engines are reasonable. |
| Build (`testOnly`, debug code in release, `BuildConfig` secrets) | No `testOnly`, no BuildConfig secrets. SEC-02 (signing). |
| `PackStore.kt` (signature, traversal, trailing data, size limits, 64-file limit, symlinks) | Signature is verified before any file is read; hashes are checked; trailing bytes rejected; path regex rejects `..` and absolute names. Temporary folders are created by the app, so no symlink is followed. SEC-04, SEC-05, SEC-20. |
| `BackupCrypto.kt` (PBKDF2, GCM, nonce, header AAD, downgrade, magic) | Sound: 16-byte random salt and 12-byte random IV per seal, header authenticated as AAD, version and KDF checked before use. SEC-07, SEC-16. |
| `BackupDocuments.kt` (SAF) | Read is capped (`TOO_LARGE`). Write is not atomic (SEC-08). Scheme not restricted (SEC-15). |
| `SecureStore.kt` and `AndroidKeystoreKeyProvider.kt` | Keystore key is non-exportable, AES-GCM, randomised encryption, unlocked-device only, StrongBox when available. Writes are atomic with a `.bak` of the last good copy. Names are checked against a regex (no traversal). Invalidation wipes blobs by design. SEC-03, SEC-06. |
| Voice (`voice/`) | Audio stays in RAM; no file writes in `voice/` (checked). Microphone released on stop (device smoke test in the Wave 3 handoff). |
| Translation (`translate/`) | No file writes. The SentencePiece parser was not fuzzed (gap). |
| Clipboard | Sensitive copies are not stored (`clipboard_controller.dart:41`). Text only. |
| Logging (Kotlin and Dart) | No typed text. Kotlin logs exception class names. Dart is a no-op in release. SEC-14, SEC-19. |
| `lib/src/security/backup/*` (payload, restore) | Payload decoder is strict and fuzzed (`corrupt_input_test.dart`). Restore ordering and locked handling: SEC-01, SEC-06, SEC-17. |
| `lib/src/core/secure_blob_store.dart` | Swallows errors on read (SEC-06). Otherwise a thin wrapper. |
| `LearnedData.decode` | Wrapped in a catch-all; never throws (fuzzed). |
| Dictionary and data parsers (mdict, translit, zh, Japanese, emoji) | Fuzzed for truncation, mutation and random input (`corrupt_input_test.dart`). SEC-09, SEC-10, SEC-11, SEC-18. Japanese: header and size checks are strict. Not checked: `lid`/`rid` range against the connection matrix (no test). |
| `InputFieldInfo` sensitive rules | SEC-12. Suggestions and learning are gated correctly. |
| Themes and photos | Byte and pixel caps (`custom_theme_files.dart`, `background_image.dart`). Not fuzzed. |
| Shortcuts (`shortcuts_store.dart`) | Not reviewed in depth (gap). |
| Dependencies | `tool/audit/osv_check.dart`: 153 components, no advisories. Licences: `licences.md`. |
| CI | Rewritten with pinned SHAs and least privilege; hygiene gate; licence and network audit jobs. See `.github/workflows/ci.yml`. |

## Verification run on 2026-11-23

- **Corrupt-input and sensitive-field tests:** 23 pass, 5 skipped (SEC-09 x2, SEC-10, SEC-11, SEC-12). `flutter test --run-skipped` on those tests confirms the skipped cases fail as described: mdict truncation and translit truncation throw `RangeError`; the zh header with bad offsets opens; the sensitive-field test returns `false`.
- **`flutter analyze`:** 0 issues.
- **Full `flutter test`:** 1375 pass, 5 skipped (the audit-pinned ones), 0 failing on the second run. The first run had one failure, `privacy_center_test.dart` "shows the no-internet proof..." (`pumpAndSettle timed out`); it passes when run alone and on the rerun, so it is a timing flake under full-suite load. The orchestrator should keep an eye on it. No Dart app code changed in Wave 5-A.
- **Licence audit:** 158 components (pub and Gradle release runtime). 157 ok, 1 review (`sky_engine`, a multi-licence bundle that includes GPL-2.0 and CC-BY text; check it by hand), 0 unknown or failing.
- **OSV advisory check:** 153 components, no advisories. Control: `log4j-core 2.14.1` returned advisories, so the query path works.
- **Repository hygiene:** 611 tracked files: no key material, no BooBoard backup or pack files, nothing over 5 MB.
- **Network audit of the Wave 4 arm64 release APK:** pass.
- **Offline Gradle resolve** of `releaseRuntimeClasspath` worked with the cached dependencies.

## Gaps and what was not done

- The `security-review` skill was not run. This review is manual, on the code listed above.
- CI has not run on GitHub (no push). The new steps (`flutter build apk --config-only`, the JVM tests step, the licence job) are unverified on a runner.
- The trademark registers were not queried directly (see `../brand/trademark-check.md`).
- Not reviewed in depth: `shortcuts_store.dart`, the SentencePiece parser, the sherpa JNI wrapper, the clipboard watcher internals, `app_auth.dart` (the lock timeout logic).
- Not produced: an SBOM, an `fdroid scanner` run, a reproducible-build check. Those belong to Agent B.
- The licence audit is keyword based and the native libraries (sherpa-onnx, onnxruntime, Flutter engine) are listed by hand in `licences.md`.
