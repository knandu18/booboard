# Accessibility report (Wave 4-C)

TalkBack work is described in `talkback.md`. This file lists what was audited and what is still open.

## Checked

- Keys have semantic nodes with spoken names (`KeyDef.spoken`, accents through the actions menu, shift and layer
  announcements). Covered by `test/keyboard/a11y/`.
- The settings app is localised (en, es, fr, de, pt, id, hi) with `AppLocalizations`; a scanner test
  (`test/app/l10n/no_literals_test.dart`) fails on new hard-coded strings in `lib/src/app/**`.
- Emulator, 2026-11-23: German and Hindi settings via the per-app language list (`locales_config.xml`), font scale 1.3.

## Touch targets under 48 dp

| Where | Now | Proposed fix |
|---|---|---|
| `suggestion_strip.dart`, toggle (`SuggestionStrip.toggleWidth`) | 40 dp wide, in a 44 dp strip | 48 dp wide, icon centred |
| `candidate_strip.dart`, expand-grid button (`gridButtonWidth`) | 44 dp wide | 48 dp wide |
| `modes_bar.dart`, mode buttons | 48 wide x 40 tall | 48 tall |
| `keyboard_metrics.dart`, `stripHeight` | 44 dp | 48 dp (changes the keyboard height; check on a device) |

## Open

- Keyboard-engine labels stay English ("Show suggestions", "Incognito mode on", "Show all candidates",
  "Close all candidates", "Private field"): `lib/keyboard_main.dart` has no Localizations context, so the device
  locale has to be passed to the keyboard engine (contract change).
- Panels (emoji, clipboard, editing, voice, translate) have labels but their touch sizes were not audited.
- Review flags: Hindi is machine-translated and flagged in full (`x-review` in the ARBs). de, es, fr, pt, id have a
  technical-term subset flagged (about 164 strings each), plus the Chinese and Japanese screens (all locales).
  A native speaker should read them before release.
- TalkBack itself was not run on the emulator in this pass (semantics are covered by tests and the accessibility
  tree dump shows the key nodes).
