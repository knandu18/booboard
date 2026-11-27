# Release checklist

Each step is marked **user** (a person does it: accounts, keys, consoles, decisions) or **orchestrator** (the
merge agent does it, in the repository or on the device). Order matters within each group.

## A. Accounts and decisions (user)

1. **Choose the developer name and the public contact.** Done 2026-11-24: the contact is the GitHub issues page
   (`privacy-policy.md`, `store-listing.md`). Play still asks for a developer email in the Console. (user)
2. **Create the GitHub account or choose the username.** It is needed for `io.github.<username>.booboard`, the
   repository URL, the About source link and the F-Droid recipe. (user)
3. **Choose the Android developer account type**: Android Developer Console (GitHub, own F-Droid repo), Play
   Console (Play), or a limited distribution account for up to 20 devices. Read `developer-verification.md` first.
   (user)
4. **Create the Play Console account** if the Play flavour is to ship, and pay the fee the Console asks for.
   Do not enter the card details in chat or in a file. (user)
5. **Create the Android Developer Console account** (fee to be confirmed on the official page). (user)
6. **Decide the pack key storage**: the pack private key is unencrypted (see section C). Accept it, or ask for a
   passphrase option in `tool/make_pack.dart` first. (user)
7. **Decide the keystore in CI**: upload the keystore as a GitHub secret (convenient, the key leaves the
   machine), or keep it offline and build release APKs locally only. (user)
8. **Decide the F-Droid route**: wait for the reproducible build and the source rebuild of the two binaries, or
   use the GitHub APK and an own F-Droid repository now. See `fdroid.md`. (user)
9. **Decide the lint policy**: release builds skip vital lint because the lint tool crashes. Accept, or fix the
   tool first. (user)
10. **Decide the store texts**: the translations are machine drafts. Ask a native speaker for each of es, fr, de,
    pt-BR, id and hi (see section F). (user)

## B. Keys (user, once, on the release machine)

11. **Run `tool\release\make_release_keys.ps1`** (default folder `%USERPROFILE%\.booboard\release`). Do not use a
    folder in the repository. Never run it against a folder that already holds keys (it refuses; keep it so). (user)
12. **Back up the folder to two offline places** (for example two encrypted USB drives). Keep the keystore
    password in a password manager too. A lost keystore means no update can reach installed copies. (user)
13. **Write down the SHA-256 fingerprints** the script prints (keystore and pack key). They go into the Console and
    the release notes. (user)
14. **Set the local signing**: copy `key.properties` to `android\key.properties` (git-ignored), or set the four
    `BOOBOARD_*` variables for the session. (user)
15. **For GitHub, set the release environment secrets and variables** listed in `RELEASING.md`, section
    "Secrets for GitHub": `BOOBOARD_KEYSTORE_BASE64`, `BOOBOARD_KEYSTORE_PASSWORD`, `BOOBOARD_KEY_PASSWORD`,
    `BOOBOARD_KEY_ALIAS`, the variables `BOOBOARD_SOURCE_URL` and `BOOBOARD_RELEASE_CERT_SHA256`. (user)
16. **Put the release pack public key into the app**: the content of `pack-release.pub.b64` goes into
    `PackKeys.kt`, and the development key stays debug-only. Re-sign the packs with `make_pack.dart --key`. (orchestrator)

## C. Repository and app changes (orchestrator)

17. **Merge the Wave 5 branches in order A, C, B** (B last). Resolve the `build.gradle.kts` lines that C adds for
    the asset packs. (orchestrator)
18. **Apply the requested patches** listed in section G. (orchestrator)
19. **Set the applicationId** when the username is known: `tool\release\set_application_id.ps1 io.github.<username>.booboard`
    (run `-DryRun` first). Then rebuild both flavours. (orchestrator, after step 2)
20. **Set `BOOBOARD_SOURCE_URL`** (the About link) in the build call (`build_release.ps1 -SourceUrl`), or in the
    `release` environment variables. (orchestrator)
21. **Bump the version** with `bump_version.ps1` and add the changelog for each locale that has a listing. (orchestrator)
22. **Run the full gates**: `build_release.ps1` (format, analyze, `flutter test`, JVM tests, both flavours with all
    ABIs, the permission gate, sums). Read `build\release-report\summary.txt`. (orchestrator)
23. **Run the reproducibility check** `verify_reproducible.ps1` and record the result in `RELEASING.md`. (orchestrator)
24. **Run the device checks** before any publication: emulator smoke test, performance budgets, TalkBack. The
    orchestrator drives the device; agents never run adb. (orchestrator)

## D. Store consoles and F-Droid (user)

25. **Enrol the app in Play App Signing** and upload the first AAB for the play flavour. The AAB has to be
    built first (the bundle task is not yet part of the tooling). (user, after C lands)
26. **Enter the store listing**: title, short description, full description, categories, content rating
    (`data-safety.md`, section 5), the Data safety answers (`data-safety.md`, section 1), the permission
    declarations (section 2), the keyboard declaration (section 3), the review notes (section 4), the privacy
    policy URL (see section E). (user)
27. **Register the package name and the signing key fingerprints** in the Android Developer Console or Play Console
    (`developer-verification.md`, "Steps for the user"). (user)
28. **Create the F-Droid merge request** in fdroiddata with `metadata/<id>.yml` once the first tag exists and the
    recipe is tested with `fdroid lint` and `fdroid build`. (user, with the orchestrator's test run)
29. **Answer the F-Droid reviewers** about the prebuilt binaries and the data licences. (user)

## E. Publishing (user)

30. **Host the privacy policy** on GitHub Pages (enable Pages for the repository, serve the policy from a folder
    the user picks). The URL goes into Play Console. (user)
31. **Tag the release**: `git tag v<name>` on the verified commit and push the tag. `release.yml` builds both
    flavours and creates a **draft** release. (user)
32. **Review the draft release** (the APKs, `SHA256SUMS.txt`, `permission-report.txt`, `sizes.txt`), and publish
    it yourself. Nothing is published by the workflow. (user)
33. **Upload the AAB to Play** (internal testing first, then closed, then production). (user)
34. **Keep a record**: the tag, the commit hash, the SHA-256 sums, the fingerprints and the report, next to the
    key backups. (user)

## F. Translation and content review (user)

35. **Native review of the store texts** for es-ES, fr-FR, de-DE, pt-BR, id and hi-IN (titles and short
    descriptions were written as machine drafts). (user)
36. **Native review of the app's `x-review` strings** (the in-app translations are machine drafts; see the Wave 4
    open items in `docs/waves/HANDOFF.md`). (user)
37. **Check that the full description matches the app** before each release (it is in English only). (user)

## G. Requested changes to orchestrator files (exact patches; not applied by Wave 5-B)

These need the owner of each file. None of them is needed to build the release APKs.

1. **Onboarding disclosure** (`lib/l10n/app_en.arb`, key `onboardingWarningBody`, and its translations). Play's
   keyboard policy expects the disclosure to say that a keyboard can collect everything you type. Proposed English:
   "A keyboard can collect everything you type, including passwords. BooBoard has no internet access, so it cannot
   send anything you type anywhere." Then re-run the x-review marking for the translations.
2. **Flavour visible to Dart** (only when the About screen should show it): a Pigeon method on `PlatformHostApi`
   (`String getDistribution()`), implemented in `PlatformHostApiImpl.kt` by reading the resource
   `R.string.booboard_distribution`. Not done: it changes the Pigeon contract.
3. **Pack keys** (`android/app/src/main/kotlin/app/booboard/keyboard/packs/PackKeys.kt`, orchestrator-owned): trust the
   release public key (`pack-release.pub.b64`) and keep the development key only for debug builds. Exact change:
   `listOf(PackStore.publicKey(RELEASE_KEY))` in release, the development key added only through a debug source
   set. Wave 5-C implements the mechanism; this is the key value.
4. **Browser incognito** (`docs/release/privacy-policy.md`, section 7 says it is not automatic). The Wave 1 plan says
   it turns on in browser private tabs. The code only has the manual switch and the per-app list
   (`input_controller.dart`, `isIncognito`). Either implement the detection (not possible for every browser; a
   per-browser list needs the package names) or drop it from the plan. Orchestrator decision.
5. **Open-source registration** (only if F-Droid re-signs): `assets/adi-registration.properties` is published with a
   release when the repository asks for it. Not created. (orchestrator, later)
6. **CI release build needs a flavour** (`.github/workflows/ci.yml`, Agent A's file): the step
   `flutter build apk --release --split-per-abi` must become `flutter build apk --release --flavor foss --split-per-abi`.
   Builds without `--flavor` fail with the Flutter tool error tested for debug (see `RELEASING.md`). The release
   permission gate path `build/app/outputs/flutter-apk/*-release.apk` still matches. (orchestrator)
7. **Format gate on main.** `dart format --line-length 120 --set-exit-if-changed lib test pigeons` fails on the
   eight generated files `lib/l10n/app_localizations*.dart` (tracked; Flutter 3.50 gen-l10n output is not formatted).
   CI's format step fails for the same reason. Fix: run `dart format --line-length 120 lib/l10n` once, or exclude
   the generated files in `ci.yml` (Agent A's file). `build_release.ps1` excludes them meanwhile. (orchestrator)

## H. Claims in the privacy policy not confirmed by reading the code

Checked and confirmed: no network code or permission; AES-256-GCM with a Keystore key (`SecureStore.kt`,
`setIsStrongBoxBacked`, `setUnlockedDeviceRequired`); atomic writes; sensitive clips never stored
(`clipboard_controller.dart`); clipboard defaults (60 minutes, 30 items); PBKDF2-HMAC-SHA256 with 600,000
iterations for backups (`BackupCrypto.kt`); backups through the system file picker; cloud and device-transfer
backup excluded (`data_extraction_rules.xml`, `allowBackup=false`); `FLAG_SECURE` set on the keyboard window for
sensitive fields (`ImeHostApiImpl.kt`); photos for themes read through the picker and copied into the theme store.

Not confirmed (check before publication):
1. **Sensitive fields get no key pop-ups and no voice input.** Suggestions and learning are switched off in code
   (`allowsLearning`, `isSensitive`). Pop-ups and voice in those fields were not traced.
2. **Release logs contain no typed text, words, app names or paths.** Dart logging is a no-op in release
   (`BooBoardLog`). Kotlin `Log.w` and `Log.e` calls (about 19 `Log.*` calls outside the debug code, the `d/v/i`
   levels stripped by R8) were not each read.
3. **The voice session ends after silence and the audio is never written to disk.** The recording path was read
   (`AudioRecord` into memory). The silence limit is documented in `HANDOFF.md`. The absence of any file write
   during recording is by search, not by a full read.
4. **Settings are a plain file** in the app's private storage (`settings.json` under `noBackupFilesDir/data`).
   The privacy policy says so; confirm it is not encrypted anywhere else.
5. **Seen apps are encrypted through `SecureBlobStore`** (documented in `seen_apps.dart`; the write path was not read).
6. **The app lock timeout and the biometric prompt** (`app_auth.dart`) were not tested on a device.
7. **Uninstall removes all data** (standard Android behaviour for app-private storage; not tested here).

## I. Known gaps in this release tooling

- The AAB bundle task is not run and not scripted.
- `verify_reproducible.ps1` compares content, not bytes; the signing block and `META-INF/` are ignored by design.
- The foss APK is reproducible at a fixed build path, not across paths: the Dart AOT snapshot (`libapp.so`) and a
  plugin's build-id carry the build folder (`RELEASING.md`, "Verification results"). F-Droid builds at a fixed path,
  so this matters for the developer's own verification only. The `play` flavour is not checked.
- The F-Droid recipe is a draft; no `fdroid` command was run.
- Store screenshots are not taken.
- The `play` flavour equals `foss` until Wave 5-C merges its asset-pack modules.
- Vital lint is off for release builds (tool crash).
- Gradle dependency locking is off (reason in `RELEASING.md`, "Reproducible builds"). Gradle dependency
  verification (`verification-metadata.xml`) is not added either; it is in the Wave 5-A audit scope.
