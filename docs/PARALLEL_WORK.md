# How parallel agents work on Kosha

Kosha is built in waves. In each wave, several agents work at the same time, each in its own git worktree and branch. The orchestrator merges the branches in a fixed order and runs the full test suite plus an emulator smoke test before the next wave starts.

## Golden rules

1. **Edit only the paths you own** (see the wave table below). If you need a change elsewhere, describe it in your final report instead.
2. **Contracts are read-only for agents.** Only the orchestrator edits these:
   - `pigeons/messages.dart` and the generated `*.g.dart` / `*.g.kt`
   - `lib/src/engine/contracts.dart`
   - `lib/src/core/` (except files your brief names)
   - `lib/src/bridge/`
   - `lib/src/settings/kosha_settings.dart` and `settings_store.dart`
   - `lib/src/keyboard/layout/layout_model.dart` (the JSON format)
   - `lib/src/theme/keyboard_theme_data.dart`
   - `lib/src/keyboard/gesture_layer/gesture_trail.dart` (signatures only; Wave 1-C owns the body)
   - `lib/main.dart`, `lib/keyboard_main.dart`
   - `pubspec.yaml`, `analysis_options.yaml`
   - Since Wave 2:
     - the integration seams: `lib/src/keyboard/panels/keyboard_panel.dart`, `keyboard_app.dart`, `keyboard_session.dart`, `view/**`, `input/**`
     - the settings app's `lib/src/app/app_services.dart` and `routes.dart`
     - `lib/src/core/data_sections.dart` and `seen_apps.dart`
     - `SettingsActivity.kt` and everything in `android/` not named in a brief
   - `android/app/src/*/AndroidManifest.xml` (Wave 1-E may edit the main manifest's IME service block)
3. **Settings sections are per-feature.** You may add optional fields, with defaults, to *your* section file in `lib/src/settings/sections/`.
4. **Privacy is non-negotiable:**
   - No network code and no new permissions.
   - Never log typed text. Use `KoshaLog` with events, sizes and timings only.
   - Anything learned from typing is stored only via `SecureBlobStore`.
   - Respect `InputFieldInfo.isSensitive` and `allowsLearning`.
5. **Dependencies:** none beyond `pubspec.yaml`. If you truly need one, request it in your report with its license and a confirmation that it has no network code.
   - **Exception:** Wave 1-D may add *only* the `fonts:` block under `flutter:` in `pubspec.yaml`.
   - **Exception:** Wave 1-E may edit `android/app/build.gradle.kts`, `proguard-rules.pro` and `res/xml/method.xml`.
   - **Third-party code or data:** write source URL, version, license and attribution to `docs/notices/<your-area>.md`. The orchestrator merges these into `THIRD_PARTY_NOTICES.md`.
6. **Quality bar before you report done:**
   - `dart format --line-length 120 <your paths>`
   - `flutter analyze` (zero issues)
   - `flutter test` (your new tests pass, and existing tests still pass)
   - If you touched `android/`, `cd android && ./gradlew :app:assembleDebug` passes.
7. **Commit on your branch** with a clear message. Don't merge, and don't push.
8. **Report:** what you built, the files you touched, test results, known gaps and any requested contract changes.

## Testing helpers

- `test/support/fake_editor.dart`: an in-memory EditText with Android InputConnection semantics. Use it to test keyboard logic.
- `InMemoryLexicon` / `InMemoryLexiconSource` in `lib/src/engine/in_memory_lexicon.dart`: test word lists.
- `InMemorySecureBlobStore` and `SettingsStore.memory()`: storage fakes.
- `tool/adb_ime.ps1`: emulator helpers. Only the orchestrator drives the emulator.

## Wave 1 ownership

| Agent | Owns | Delivers |
|---|---|---|
| A, keyboard view and input | `lib/src/keyboard/**` (except `gesture_layer/`), `assets/layouts/**`, `test/keyboard/**` | Layout engine and real layouts, key rendering, touch handling, popups, shift and caps, field-aware pages, suggestion bar, InputController |
| B, text engine | `lib/src/engine/dictionary/**`, `lib/src/engine/suggest/**`, `lib/src/engine/learn/**`, `tool/build_dictionary.dart`, `assets/dict/**`, `test/engine/text/**` | English dictionary format and build tool, autocorrect, completion, prediction, encrypted learning |
| C, gesture typing | `lib/src/engine/gesture/**`, `lib/src/keyboard/gesture_layer/**`, `test/engine/gesture/**` | Swipe decoder in an isolate, trail painter, accuracy tests |
| D, design and themes | `lib/src/design/**`, `lib/src/theme/**` (except `keyboard_theme_data.dart`), `assets/themes/**`, `assets/fonts/**`, `test/theme/**` | M3 Expressive tokens, presets, Material You, `resolveKeyboardTheme`, fonts |
| E, Android platform | `android/**` (except manifests, beyond the IME service block), `test/android/**` | InputConnection completeness, clipboard watcher, Keystore hardening, feedback, insets and floating mode, inline autofill, trim memory |

## Wave 2 ownership

Briefs: `docs/waves/wave2/*.md`. Everything not listed belongs to the orchestrator.

| Agent | Owns | Settings section files (add optional fields only) | Delivers |
|---|---|---|---|
| A, settings app | `lib/src/app/**` except `app_services.dart`, `routes.dart`, `privacy/`, `themes/`; `assets/notices/**`; `test/app/**` except `privacy/`, `themes/` | typing, feedback, swipe, language, voice | Shell, routes, onboarding, Languages/Typing/Feel/Panels/Voice/About screens, shared settings widgets (stable API) |
| B, privacy and security | `lib/src/app/privacy/**`, `lib/src/security/**`, `lib/src/features/shortcuts/**`, `android/.../security/backup/**`, the backup section of `AppHostApiImpl.kt`, `test/app/privacy/**`, `test/security/**`, `test/features/shortcuts/**`, `android/app/src/test/.../security/backup/**` | privacy | Privacy center, app lock, `.koshabackup`, wipe, learned-words editor, incognito apps, personal shortcuts |
| C, themes | `lib/src/app/themes/**`, `lib/src/theme/**` (except `keyboard_theme_data.dart`), `lib/src/keyboard/preview/**`, `assets/themes/**`, `test/theme/**`, `test/app/themes/**`, `test/keyboard/preview/**` | appearance | Theme gallery (carousel), editor with live preview, photo backgrounds, custom themes by id |
| D, panels | `lib/src/features/**` except `shortcuts/`, `tool/build_emoji.dart`, `assets/emoji/**`, `test/features/**` except `shortcuts/`, `test/tool/build_emoji_test.dart` | clipboard | Emoji (data, panel, search, suggestions), clipboard history and chips, editing panel, selection chips |
| E, modes | `lib/src/keyboard/modes/**`, `lib/src/keyboard/layout/layout_engine.dart`, `assets/layouts/**`, `test/keyboard/modes/**`, `test/keyboard/layout_test.dart` | modes | One-handed, floating, height handle, modes bar, space cursor drag, backspace swipe-delete, emoji key, split and compact layouts |

Writing another section's *values* through `SettingsStore.update` is fine (for example the theme editor writes `swipe.trailWidth`); only adding fields is restricted to the owner.

## Wave 3 ownership

Briefs: `docs/waves/wave3/*.md`. Everything not listed belongs to the orchestrator. Setup commit: `92ead05`.

| Agent | Owns | Settings section files (add optional fields only) | Delivers |
|---|---|---|---|
| A, European languages | `lib/src/engine/lang/european.dart` (+ `european/`), `lib/src/engine/dictionary|suggest|learn/**`, `tool/build_dictionary.dart`, `tool/european/**`, layouts `qwerty_es`, `azerty`, `qwertz`, `jcuken_*` (+ popups in `qwerty.json`), `assets/dict/{es,fr,de,pt-BR,pt-PT,id,ru,uk}.mdict`, `lib/src/features/languages/**`, `lib/src/app/screens/languages_screen.dart`, `lib/src/app/shell/language_catalog.dart`, `lib/src/app/onboarding/**` (language step), `docs/notices/european.md`, tests named in the brief | languages | Dictionaries, layouts and rules for 8 languages; blending fixes; space-bar language picker; Languages screen |
| B, Indic | `lib/src/engine/lang/indic.dart` (+ `indic/`), `lib/src/features/indic/**`, layouts `translit_*`, `phonetic_*`, `inscript_*`, `assets/translit/**`, `assets/dict/{hi,mr,bn,ta,te}.mdict`, `tool/indic/**`, `docs/notices/indic.md`, tests named in the brief | none | English-letter typing (transliteration transform, Hinglish), native layouts, swipe mapping, rules |
| C, Arabic and Urdu | `lib/src/engine/lang/arabic.dart` (+ `arabic/`), layouts `arabic*`, `urdu*`, `assets/dict/{ar,ur}.mdict`, `tool/arabic/**`, RTL-only fixes in `lib/src/features/{emoji,clipboard,editing,shared}/**`, `docs/notices/arabic.md`, tests named in the brief | none | Layouts with harakat, dictionaries, rules, RTL checks of strip and panels, swipe accuracy |
| D, voice | `android/.../voice/**`, `android/app/src/main/jniLibs/**`, the `packaging {}` block of `build.gradle.kts`, `lib/src/features/voice/**`, `lib/src/app/screens/voice_screen.dart`, `tool/packs/voice/**`, `docs/notices/voice.md`, tests named in the brief | voice | sherpa-onnx + Whisper service, mic permission activity, mic panel, voice settings, pack staging |
| T, translator | `android/.../translate/**`, one `testImplementation` line in `build.gradle.kts`, `lib/src/features/translate/**`, `lib/src/app/translate/**`, `lib/src/app/packs/**`, one tile in `privacy_center_screen.dart`, `tool/packs/translate/**`, `docs/notices/translate.md`, tests named in the brief | translate | OPUS-MT ONNX translation service, translate panel and selection chips, Model packs screen, Translation screen |

Layouts and dictionaries share folders, but each agent owns distinct file names.

## Wave 4 ownership

Briefs: `docs/waves/wave4/*.md`. Everything not listed belongs to the orchestrator. Setup commit: `f2fd99a`.

| Agent | Owns | Settings section files (add optional fields only) | Delivers |
|---|---|---|---|
| A, Chinese | `lib/src/engine/lang/chinese.dart` (+ `chinese/`), `lib/src/features/chinese/**`, `lib/src/app/chinese/**`, layout `pinyin_zh`, `tool/chinese/**`, `tool/packs/chinese/**`, `docs/notices/chinese.md`, tests named in the brief | chinese | Pinyin `TextComposer` (segmentation, abbreviations, fuzzy, predictions, Traditional), `dict-zh-rime-ice` pack staging, Chinese screen |
| B, Japanese | `lib/src/engine/lang/japanese.dart` (+ `japanese/`), `lib/src/features/japanese/**`, `lib/src/app/japanese/**`, layouts `kana12_ja`, `romaji_ja` (+ `symbols_ja`), `tool/japanese/**`, `tool/packs/japanese/**`, `docs/notices/japanese.md`, tests named in the brief | japanese | Romaji and 12-key `TextComposer`, kana-kanji conversion, `dict-ja-mozc` pack staging, Japanese screen |
| C, accessibility and localisation | `lib/src/keyboard/view/keys_painter.dart`, `key_visuals.dart`, `lib/src/keyboard/a11y/**`; labels only in the strip, `candidates/`, `modes/` and the Wave 2-3 feature panels; `lib/l10n/*.arb`; strings in `lib/src/app/**` except `chinese/`, `japanese/`, `kosha_mascot.dart`; `res/xml/locales_config.xml`; `docs/a11y/**`; tests named in the brief | none | TalkBack on the keyboard (nodes, actions, announcements), settings app in en/es/fr/de/pt/id/hi |
| D, performance and QA | onnxruntime lines of `build.gradle.kts`, `android/app/libs/**`, `tool/onnxruntime/**`, `tool/bench/**`, `docs/perf/**`, `docs/notices/onnxruntime.md`, `test/perf/**`, `test/fuzz/**` | none | Reduced onnxruntime 1.28.0 AAR, budget benchmarks, device bench script, InputController fuzzing, OEM matrix |
| E, brand | launcher and splash resources in `android/app/src/main/res/` (`mipmap-*`, `mipmap-anydpi-v26`, splash drawables and styles, `values-v31`), `lib/src/app/onboarding/kosha_mascot.dart`, brand colours in `lib/src/theme/presets.dart` and `lib/src/app/shell/kosha_theme.dart`, `assets/brand/**`, `docs/brand/**`, `tool/brand/**`, tests named in the brief | none | Treasure-chest adaptive and themed icon, splash, chest poses, store graphics |

Merge order: E, D, A, B, C.

## Wave 5 ownership

Briefs: `docs/waves/wave5/*.md`. Everything not listed belongs to the orchestrator. Merge order: A, C, B.

| Agent | Owns | Delivers |
|---|---|---|
| A, security audit | `docs/security/**`, `SECURITY.md`, `.github/workflows/**` except `release.yml`, `.github/dependabot.yml`, `tool/audit/**`, `tool/check_release_permissions.sh`, `docs/brand/trademark-check.md`, `test/security/**` | Threat model, code review findings (patches for files it does not own), licence and dependency audit, hardened CI, trademark check of "Kosha" |
| B, release engineering | `android/app/build.gradle.kts`, `android/gradle.properties`, repository lines of `android/settings.gradle.kts`, `android/app/src/play/**` and `src/foss/**` (C adds files only where its brief says), `.github/workflows/release.yml`, `tool/release/**`, `fastlane/**`, `metadata/**`, `docs/release/**` (except `asset-packs.md`), `.gitignore` signing entries, `test/release/**` | `play` and `foss` flavours, signing config, key generation script, reproducible build check, privacy policy, Data safety answers, store texts, F-Droid recipe, developer-verification notes |
| C, data packs | `android/.../packs/**`, `android/asset_packs/**`, `lib/src/packs/**`, `lib/src/app/packs/**` (plus its new ARB keys), `tool/make_pack.dart`, `tool/packs/**`, `docs/packs/**`, `docs/release/asset-packs.md`, `docs/notices/indic_extra.md`, `test/packs/**` | Pack key rotation, FOSS import experience, Play on-demand asset packs (patches for B's Gradle files), extra data packs |
