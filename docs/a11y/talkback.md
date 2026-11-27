# TalkBack on BooBoard

How to test the keyboard and the settings app with TalkBack, and what to try first. The keyboard is an
input method, so TalkBack users explore it with one finger and type by lifting the finger (TalkBack's
default IME typing mode) or by double-tapping.

## Setup on the phone

1. Enable TalkBack: Settings, Accessibility, TalkBack.
2. Select BooBoard as the keyboard: Settings, System, Keyboard, On-screen keyboard, BooBoard.
3. Open any text field (Messages, Notes). Turn on the keyboard with one finger: explore by moving a finger
   across the keys. Each key is announced when touched.
4. Typing: lift the finger on a key to type it (TalkBack's IME typing mode). Double-tap types a focused key too.

## What to check

### Keys

- Explore the QWERTY layout row by row, left to right. Every key says what it is: "q", "Shift, off",
  "Delete", "Space", "Enter", "Symbols".
- Shift: "Shift, off", then "Shift, on" after one tap, then "Shift, caps lock on" after a double tap.
- Long-press alternatives: swipe to a letter with accents (e in French or Spanish), open the actions menu
  (TalkBack's global context menu, or the "Actions" item on the key) and choose "Type é". No long press.
- 12-key Japanese (when it lands): each flick key has one action per direction: "Type い", "Type う", ...
  The centre is the tap.
- Page keys: on the symbols page, "Symbols" is marked selected.

### Announcements (polite; TalkBack reads them after the current speech)

- Switching to symbols says "Symbols"; back to letters says "Letters".
- Switching language says the language's own name ("Deutsch").
- Caps lock says "Caps lock on" and "Caps lock off".
- A swipe-typed word says "Swipe typed". The word itself is never announced.
- Emoji, clipboard, voice and translate panels say "<name> open" and "<name> closed".

No announcement ever carries typed text. The announcer only receives events.

### Candidates and suggestions

- Suggestions: "Suggestion the". A tap types it.
- Candidates (Chinese, Japanese): "Candidate 你好, 1 of 12". The label gives the position in the list.
- "Loading the dictionary" is a live region: TalkBack reads it when it appears.

### Spoken names

- Symbols and currency: "Euro", "Copyright", "Ellipsis".
- Indic marks as separate keys or popup items: "halant" (virama), "nukta", "anusvara", "visarga".
- Arabic harakat: "fatha", "kasra", "damma", "sukun", "shadda".
- CJK punctuation: "Comma" (、), "Full stop" (。), "Long vowel mark" (ー).
- A combining mark without a name is spoken as "combining mark", never as a bare glyph.

### Settings app

- Settings in Hindi and German: switch the phone's language, then open BooBoard settings. Check that headings,
  switches and descriptions are read in the right language and that no screen has text cut off at font
  scale 1.3 (Settings, Display, Font size).

## What the orchestrator should try

1. Wire the key layer (see "Wiring requested from the orchestrator" below). Without it, TalkBack gets the fallback key
   nodes: labels and taps work, but the custom actions ("Type é") are missing.
2. Explore QWERTY and the 12-key layout with TalkBack on. Confirm the row order on a split layout and in
   one-handed mode.
3. Type "été" with an accent action only: lift on e, open the actions menu, choose "Type é".
4. Switch pages with the Symbols key and confirm "Symbols" is announced once, not twice.
5. Switch language with the globe key and confirm the language name is announced.
6. Turn on caps lock with a double tap on shift. Confirm "Caps lock on".
7. Open the emoji panel and confirm "Emoji open". Close it and confirm "Emoji closed".
8. Check TalkBack's reading of a password field: nothing is learned or announced.

## Touch targets under 48 dp

Sizes as written in the code. The proposed fixes grow the hit area and keep the visual design.

| Element | Where | Now | Proposed fix |
|---|---|---|---|
| Strip toggle (leading button) | `lib/src/keyboard/view/suggestion_strip.dart`, `toggleWidth` | 40 dp wide, strip 44 dp tall | 48 dp wide; strip 48 dp tall (`KeyboardMetrics.stripHeight` is orchestrator-owned) |
| Suggestion slots | `suggestion_strip.dart` | 44 dp tall (strip) | Same strip height change |
| Candidate chips | `lib/src/keyboard/candidates/candidate_strip.dart` | `minWidth` 44 dp, strip 44 dp | `minWidth` 48 dp; strip 48 dp |
| Show all candidates button | `candidate_strip.dart`, `gridButtonWidth` | 44 dp wide | 48 dp wide |
| Modes bar buttons | `lib/src/keyboard/modes/modes_bar.dart` | 40 dp tall, 22 dp icon | 48 dp tall |
| Panel buttons (`PanelButton`) | `lib/src/features/shared/panel_style.dart`, used by clipboard, editing, voice | 36 dp tall | 48 dp tall (`height` is already a parameter) |
| Letter keys | `lib/src/keyboard/layout/layout_engine.dart` | About 36 dp wide on a 360 dp phone (10 keys per row); rows 56 dp at scale 1.0 | Key size is the keyboard's design, so no change here. Cells tile the keyboard, so exploration has no dead zones. The QA matrix should check this |

## Wiring requested from the orchestrator

These files are orchestrator-owned, so the wiring is described here and not made.

1. `lib/src/keyboard/view/keyboard_view.dart`, in `_KeyboardKeysAreaState.build`:
   - In the `KeysPainter(...)` call, add `overlayProvidesSemantics: true,`.
   - Add a sibling of the keys `Positioned.fill`:

     ```dart
     Positioned.fill(
       child: KeySemanticsLayer(
         laid: laid,
         shift: widget.session.input.shift.value,
         page: widget.page,
         field: widget.field,
         typing: widget.settings.typing,
         spaceLabel: widget.page == KeyboardPage.letters
             ? widget.session.spaceLabelOverride.value ?? widget.session.spaceLabel.value
             : null,
         onActivate: v.activateKey,
       ),
     ),
     ```

     Import `../a11y/key_semantics.dart`. The layer has no hit-test area, so it does not block touches.

   Without this wiring the painter's fallback nodes are used: labels, the selected page and taps work;
   the custom actions do not.

2. `lib/src/keyboard/keyboard_session.dart` or `keyboard_app.dart`: create one announcer and bind it:

   ```dart
   final announcer = KeyboardAnnouncer.forView(() => View.of(context));
   announcer.bind(page: input.page, shift: input.shift, language: session.spaceLabel);
   ```

   Call `panelOpened(name)` and `panelClosed(name)` where panels open and close, and `swipeTyped()` when a
   swipe commits a word. Dispose it with the session.

3. `android/app/src/main/AndroidManifest.xml`: add `android:localeConfig="@xml/locales_config"` to
   `<application>` (Android 13+ per-app language). The XML file is `res/xml/locales_config.xml`.

## Known gaps

- Announcements need the wiring above; until then only the keys' own labels are spoken.
- Automated tests cover the semantics tree and the announcer; only a phone can confirm the spoken output.
- Automated tests cover the semantics tree and the announcer; only a phone can confirm how TalkBack
  speaks them.
