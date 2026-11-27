# BooBoard threat model

Status: Wave 5-A, 2026-11-23. Companion documents: `audit.md` (findings and coverage), `licences.md`, `../brand/trademark-check.md`, and `SECURITY.md` at the repository root. The plan section "Privacy and security" is the design; this file checks the code against it.

BooBoard is a private, offline, multilingual Android keyboard. The app has no network permission in the release build and no analytics. Everything it learns stays on the phone.

## 1. Assets

| Asset | Where it lives | Protected by |
|---|---|---|
| Typed text (what the user types in fields) | Not stored, except as learned data below | No logging (`lib/src/core/log.dart`, Kotlin logs carry exception class names only); sensitive fields are not learned |
| Learned words, bigrams, blocked words | `noBackupFilesDir/secure/*.bin` (`SecureStore`), Dart `LearnedData` blobs `learned_<lang>` | AES-256-GCM, Keystore key `kosha.secure_store.v1`, unlocked-device only (`AndroidKeystoreKeyProvider.kt`) |
| Clipboard history | Blob `clipboard`, pinned items only in backups | Same store; sensitive clips (`EXTRA_IS_SENSITIVE`) never stored; 30 items and 1-hour expiry (plan) |
| Personal shortcuts | `ShortcutsStore` (`lib/src/security/shortcuts_store.dart`) | Same store |
| Backups (`.koshabackup`) | User-chosen SAF file | PBKDF2-HMAC-SHA256 (600k iterations, random salt), AES-256-GCM, header as AAD (`BackupCrypto.kt`) |
| Voice audio | RAM only (`AudioRecordMicrophone`, `SherpaVoiceService`) | No disk writes in `voice/` (checked); microphone released when the session ends |
| App list (seen apps, per-app incognito list) | `seen_apps.dart`, settings | Settings store; no `QUERY_ALL_PACKAGES` permission |
| Themes and photos | `custom_theme_files.dart`, `background_image.dart` | Pixel and size caps; photo picker, no storage permission |
| Keyboard settings | `SettingsStore` | Plain, non-sensitive, excluded from cloud backup (`data_extraction_rules.xml`) |

## 2. Actors and defences

Each row gives the defence, what remains, and the residual risk (low, medium or high, for a user who keeps the release build).

### 2.1 Other apps on the phone

- **Defence:** the app is sandboxed by Android. The IME receives text only through `InputConnection` for the field that is focused. The IME service is `exported=true` but protected by `BIND_INPUT_METHOD` (`AndroidManifest.xml`). No other component is exported except the launcher activity (`SettingsActivity`) and the mic activity is `exported=false`. BooBoard holds no network permission (release manifest removes INTERNET, ACCESS_NETWORK_STATE and ACCESS_WIFI_STATE; `tool/check_release_permissions.sh` and `tool/audit/network_audit.sh` enforce it).
- **Remains:** an installed IME necessarily sees everything typed in every field it is allowed in. Password fields and fields with TYPE_TEXT_FLAG_NO_SUGGESTIONS or IME_FLAG_NO_PERSONALIZED_LEARNING get no suggestions and no learning, but see finding SEC-12 for FLAG_SECURE, voice and translation in those fields.
- **Residual:** medium (inherent to any keyboard; mitigated by offline operation and the absence of any sender).

### 2.2 A person holding an unlocked phone

- **Defence:** `FLAG_SECURE` on the keyboard window for password fields and for the "Hide from screenshots" toggle (`ImeHostApiImpl.kt`, `AppHostApiImpl.kt`); "Private field" chip; app lock with BiometricPrompt guarding settings, learned-word list, clipboard history and backup (`lib/src/security/app_auth.dart`); per-app incognito (`EditorInfo.packageName`).
- **Remains:** the app lock is a UI gate. The Keystore key is available to any code running as the app while the phone is unlocked, so a person with an unlocked phone can open the privacy center and export a backup if they know the passphrase (they still need the passphrase for the file).
- **Residual:** medium. Wipe is available (`data_wiper.dart`), and it destroys the key.

### 2.3 A person with a stolen locked phone

- **Defence:** the Keystore key is created with `setUnlockedDeviceRequired(true)` and StrongBox where present (`AndroidKeystoreKeyProvider.kt`, lines 58-62). While the device is locked, `SecureStore.read` returns null and writes throw LOCKED; the keyboard still works without the learned data. Files are in `noBackupFilesDir`, so they are not in cloud backup.
- **Remains:** a device unlocked by the thief (PIN, pattern or biometric) is the unlocked case above.
- **Residual:** low on a locked phone with a current OS; a locked device without Android file-based encryption support would be weaker, but minSdk 26 is file-based encrypted.

### 2.4 A malicious `.koshapack` or `.koshabackup` file

- **Packs (`.koshapack`):** the install path verifies the ECDSA P-256 signature over the manifest before reading any file (`PackStore.install`), checks each file's SHA-256 from the signed manifest, rejects trailing data and oversized manifests, and refuses path traversal and reserved names (`PackManifest.validate`, `PATH_RE`). Packs are data only; nothing is executed.
  - **Remains:** a pack signed by a trusted key is accepted. Only one dev key is trusted today; the release key rotation is Wave 5 agent C's work. Integer overflow in the total size check (SEC-04) and the path-prefix IOException (SEC-05) are open. `open()` does not re-hash the installed files (SEC-20).
  - **Residual:** low, provided the trusted key stays private.
- **Backups (`.koshabackup`):** a backup needs the passphrase to decrypt (`BackupCrypto.open`). The header is authenticated as GCM AAD, so a changed header or salt fails. The plain payload is then checked by a strict decoder (`BackupPayload.decode`): size caps, count caps, name patterns, shortcut and clipboard limits, base64 limits, settings size limit, and the restore rules. Corrupt plain text is rejected and the parser is covered by `test/security/corrupt_input_test.dart`.
  - **Remains:** someone who has the passphrase can send a backup file with valid content that restores bad settings. SEC-01 means a bad settings section can leave a half-applied restore; SEC-07 (up to 10 million PBKDF2 iterations from an unauthenticated header) makes a crafted file slow to reject; SEC-08 means an export over an existing document is not atomic.
  - **Residual:** low.

### 2.5 A malicious dictionary or model file

- **Defence:** bundled dictionaries and data are part of the signed APK. Imported model and dictionary packs are checked as in 2.4. The parsers are Dart or Kotlin, so memory safety holds, and the keyboard reads only fixed formats.
- **Remains:** header counts and offsets are not always validated before allocation or use (SEC-09 translit, SEC-10 mdict truncation and zlib size, SEC-11 zh.kdict offsets). These are bundled or signed, so the attacker needs the signing key; the consequence is a slow or failed load, caught by callers (`on Object`).
- **Residual:** low.

### 2.6 A malicious IME client (a text field trying to read the keyboard's state)

- **Defence:** the keyboard only reads the field it is attached to. It does not read other windows or the notification or accessibility trees. The clipboard watcher (`ClipboardWatcher.kt`) records copies made while the keyboard is in use, text only; copies flagged `EXTRA_IS_SENSITIVE` are not stored (`clipboard_controller.dart`). InputFieldInfo state for password fields and no-learning fields is respected for suggestions and learning.
- **Remains:** an app can read what the keyboard commits into its own field (inherent). A field that sets FLAG_SECURE itself is respected for screenshots. An app can ask the keyboard for suggestions about its field only through the normal IME path.
- **Residual:** medium (inherent to IMEs).

### 2.7 Supply-chain compromise (a dependency, a pack, a CI action)

- **Defence:** pinned dependencies (`onnxruntime-android` 1.28.0, Flutter 3.50.0, pinned lockfile); the licence and dependency audit (`tool/audit/licences.dart`, `tool/audit/osv_check.dart`); the network audit of release APKs (`tool/audit/network_audit.sh`); CI with every action pinned to a commit SHA, `permissions: contents: read`, `persist-credentials: false`, and no secrets (`.github/workflows/ci.yml`); Dependabot for Actions, Gradle and pub with the onnxruntime pin ignored above 1.28 (`.github/dependabot.yml`); the repository hygiene gate (no key material, no BooBoard data files, nothing over 5 MB).
- **Remains:** the Gradle wrapper is not tracked (android/.gitignore excludes `gradlew` and `gradlew.bat`), so a fresh clone cannot build until Flutter writes the wrapper (SEC-13). The release build is still signed with the debug key (SEC-02, Agent B). No reproducible-build check or SBOM exists yet. Only the release APK is audited; AAR manifests are not.
- **Residual:** medium until SEC-02 and SEC-13 are fixed.

### 2.8 Ourselves (an accidental log, an accidental permission)

- **Defence:**
  - Permissions: the release allowlist is VIBRATE, RECORD_AUDIO, USE_BIOMETRIC, USE_FINGERPRINT and the app-private receiver permission. The gate fails on INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE or telemetry classes (`tool/check_release_permissions.sh`). `tool/audit/network_audit.sh` fails on any permission outside the allowlist and on the network or telemetry SDK families.
  - Logs: Dart `BooBoardLog` is a no-op in release (`kReleaseMode`). Kotlin logs at `w` and `e` carry exception class names, and `d` logs only timings (`PackTranslationService`, `SherpaVoiceService`). R8 removes `v`, `d` and `i` calls (`proguard-rules.pro`).
  - Backups: `allowBackup=false`, `fullBackupContent=false` and `dataExtractionRules` exclude every domain from cloud backup and device transfer. `debuggable` is absent in the release manifest. The testbed activity exists only in the debug source set.
- **Remains:** R8 keeps `Log.w` and `Log.e` (the plan says `Log.*` is stripped; SEC-14). Debug and profile builds print the gesture decoder's error text (`isolate_gesture_decoder.dart:331`); these builds are not released.
- **Residual:** low.

## 3. Data flows, in short

- Typed text goes from the IME to the Dart engine over the Pigeon channel. Learned data is written to `SecureStore` through `PlatformSecureBlobStore`.
- Settings and packs stay on the phone. Backups leave the phone only when the user saves them through SAF, and then only encrypted.
- Voice audio and translation stay in RAM and in the bundled ONNX runtime.
- No component opens a socket (no INTERNET). The OS enforces this: without the permission, socket creation fails for the app.

## 4. Coverage of this model

Reviewed by reading the code: the files in `audit.md` section "Coverage". Fuzzed or tested: the backup payload decoder, the learned-data and clipboard codecs, the mdict, translit, zh and Japanese dictionary headers, and the emoji decoder (`test/security/corrupt_input_test.dart`). Not reviewed in depth: `shortcuts_store.dart`, the SentencePiece model parser used by the translation engine, the sherpa JNI wrapper, and the clipboard watcher internals.

## 5. Decisions the user must make

1. **SEC-12:** do the no-personalised-learning and no-suggestions fields get FLAG_SECURE, no voice and no translation (the plan), or only the current behaviour (password only)?
2. **SEC-17:** should a restored settings section that turns off app lock or incognito lists require an explicit confirmation? Restoring settings can silently weaken privacy protections today.
3. **Trusted pack key:** rotation to the release pack key (Agent C) and the retirement of the dev key before any public build.
